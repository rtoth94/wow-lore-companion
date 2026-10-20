# Generated addon output

This is the single output folder for quest retrieval and addon builds.
Generated files are ignored by Git; this README is tracked.

After installing the quest-data package (see the root README), build and deploy from the repository root with:

```sh
python manage.py --build
python manage.py --deploy
```

The build loads credentials from the prototype's local `.env` and fetches the
quests listed in [quest_map.json](../prototypes/quest-data/quest_map.json).

- `quest-ID.json`: original API response for each mapped quest.
- `manifest.json`: export results, map, region, locale, and retrieval time.
- `QuestData.lua`: generated addon data preserving returned descriptions.
- `LoreCompanion.zip`: installable addon package, including bundled quest data.

Paths have no timestamps. Each data generation replaces previous generated data,
while preserving this README. The root build command removes the old ZIP before generation. A failed
build leaves no previous ZIP available for deployment. Do not run builds and
exports concurrently. Retrieval time remains in metadata for provenance.

The current map covers one chapter. Descriptions are not guaranteed to include
all dialogue, and narrative order is unverified. The Quests tab displays bundled descriptions for The Light's Summons.
