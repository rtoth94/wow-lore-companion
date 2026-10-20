# Generated addon output

This is the single output folder for quest retrieval and addon builds.
Generated files are ignored by Git; this README is tracked.

From the repository root, build and deploy with:

```sh
python3 prototypes/quest-data/build_addon.py
python3 deploy.py
```

The build loads credentials from the prototype's local `.env` and fetches the
quests listed in [quest_map.json](../prototypes/quest-data/quest_map.json).

- `quest-ID.json`: original API response for each mapped quest.
- `manifest.json`: export results, map, region, locale, and retrieval time.
- `QuestData.lua`: generated addon data preserving returned descriptions.
- `LoreCompanion.zip`: installable addon package, including bundled quest data.
- `quest-ID-REGION-LOCALE.json`: optional single-quest experiment output.

Paths have no timestamps. Each batch replaces previous generated results,
including single-quest experiments, while preserving this README. A failed
build leaves no previous ZIP available for deployment. Do not run builds and
exports concurrently. Retrieval time remains in metadata for provenance.

The current map covers one chapter. Descriptions are not guaranteed to include
all dialogue, and narrative order is unverified. The reading UI is still pending.
