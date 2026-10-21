"""Export mapped original quest responses and addon Lua data."""
import json
import time
from datetime import datetime, timezone
from .api import ResourceNotFound, authenticate, fetch_quest

def lua(value):
    """Serialize the small data types we use, with Lua 5.1 string escapes."""
    if value is None:
        return "nil"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, str):
        # Three-digit decimal escapes avoid consuming following digits.
        escaped = "".join(
            "\\" + char if char in ('"', "\\") else
            f"\\{ord(char):03d}" if ord(char) < 32 or ord(char) == 127 else char
            for char in value
        )
        return '"' + escaped + '"'
    if isinstance(value, list):
        return "{ " + ", ".join(lua(item) for item in value) + " }"
    if isinstance(value, dict):
        return "{\n" + "\n".join(
            f"[{lua(key)}] = {lua(item)}," for key, item in value.items()
        ) + "\n}"
    raise ValueError("Unsupported value in generated Lua data.")


def write_lua(export_dir):
    report = json.loads((export_dir / "manifest.json").read_text(encoding="utf-8"))
    if any(item["status"] not in ("ok", "unavailable") for item in report["results"]):
        raise RuntimeError("Export has failed requests; no package was created.")
    unavailable = {item["quest_id"] for item in report["results"] if item["status"] == "unavailable"}
    mapping = report["map"]
    quests = {}
    for chapter in mapping["chapters"]:
        for quest_id in chapter["quest_ids"]:
            if quest_id in unavailable:
                # Preserve membership without inventing a title or original text.
                quests[quest_id] = {"descriptionAvailable": False}
                continue
            quest = json.loads((export_dir / f"quest-{quest_id}.json").read_text(encoding="utf-8"))
            if quest.get("id") != quest_id:
                raise RuntimeError("Exported quest ID mismatch; no package was created.")
            title, description = quest.get("title"), quest.get("description")
            if title is not None and not isinstance(title, str):
                raise RuntimeError("Expected a localized quest title string.")
            if description is not None and not isinstance(description, str):
                raise RuntimeError("Expected a localized quest description string.")
            quests[quest_id] = {"title": title, "description": description,
                                "descriptionAvailable": bool(description and description.strip())}
    data = {"campaignID": mapping["campaign_id"], "locale": report["locale"],
            "region": report["region"], "retrievedAt": report["retrieved_at"],
            "source": "Blizzard Game Data Quest API", "orderVerified": False,
            "chapters": [{"chapterID": c["chapter_id"], "title": c["title"],
                          "questIDs": c["quest_ids"]} for c in mapping["chapters"]],
            "quests": quests}
    generated = "-- Generated original quest text; do not edit manually.\nlocal _, addon = ...\naddon.QuestData = " + lua(data) + "\n"
    (export_dir / "QuestData.lua").write_text(generated, encoding="utf-8")
    print(f"Generated {len(quests)} quests: {export_dir / 'QuestData.lua'}")


def generate(map_path, output, region, env_file):
    mapping = json.loads(map_path.read_text(encoding="utf-8"))
    if not isinstance(mapping, dict) or type(mapping.get("campaign_id")) is not int or mapping["campaign_id"] <= 0:
        raise ValueError("Quest map requires a positive campaign_id.")
    chapters = mapping.get("chapters")
    if not isinstance(chapters, list) or not chapters:
        raise RuntimeError("Quest map must contain a nonempty chapters list.")
    ids = []
    chapter_ids = set()
    for chapter in chapters:
        if not isinstance(chapter, dict) or type(chapter.get("chapter_id")) is not int or chapter["chapter_id"] <= 0 or not isinstance(chapter.get("title"), str):
            raise ValueError("Each chapter requires a positive chapter_id and string title.")
        if chapter["chapter_id"] in chapter_ids:
            raise ValueError("Duplicate chapter_id in map.")
        chapter_ids.add(chapter["chapter_id"])
        quest_ids = chapter.get("quest_ids") if isinstance(chapter, dict) else None
        if not isinstance(quest_ids, list) or not quest_ids:
            raise RuntimeError("Each chapter must contain a nonempty quest_ids list.")
        for quest_id in quest_ids:
            if type(quest_id) is not int or quest_id <= 0:
                raise RuntimeError("Quest IDs must be positive integers.")
            if quest_id not in ids:
                ids.append(quest_id)
    # Clear previous data so failures cannot leave stale Lua for packaging.
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    output.mkdir(parents=True, exist_ok=True)
    for pattern in ("quest-*.json", "manifest.json", "QuestData.lua"):
        for previous in output.glob(pattern):
            previous.unlink()
    token = authenticate(env_file)
    results = []
    for index, quest_id in enumerate(ids, 1):
        try:
            quest = fetch_quest(quest_id, region, token)
            filename = f"quest-{quest_id}.json"
            (output / filename).write_text(json.dumps(quest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            description = quest.get("description")
            available = isinstance(description, str) and bool(description.strip())
            results.append({"quest_id": quest_id, "status": "ok", "file": filename,
                            "has_description": available})
            print(f"[{index}/{len(ids)}] {quest_id}: saved; description {'present' if available else 'unavailable'}")
        except ResourceNotFound as error:
            results.append({"quest_id": quest_id, "status": "unavailable",
                            "has_description": False, "error": str(error)})
            print(f"[{index}/{len(ids)}] {quest_id}: unavailable (HTTP 404); keeping quest ID")
        except RuntimeError as error:
            results.append({"quest_id": quest_id, "status": "failed", "error": str(error)})
            print(f"[{index}/{len(ids)}] {quest_id}: {error}")
        time.sleep(0.2)
    report = {"retrieved_at": stamp, "region": region,
              "locale": "en_GB" if region == "eu" else "en_US",
              "map": mapping, "results": results}
    (output / "manifest.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    failed = sum(item["status"] == "failed" for item in results)
    unavailable = sum(item["status"] == "unavailable" for item in results)
    print(f"Saved {len(results) - failed - unavailable}/{len(ids)} quests; {unavailable} unavailable; {failed} failed. Manifest: {output / 'manifest.json'}")
    if failed:
        raise RuntimeError("Quest requests failed; inspect manifest.json. No Lua data generated.")
    write_lua(output)
