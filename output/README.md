# Generated output

Only this README is tracked. Generated data and ZIPs are ignored by Git.

From the repository root:

```sh
uv run manage.py --build
uv run manage.py --deploy
```

- `quest-ID.json`: original quest responses.
- `manifest.json`: map, retrieval metadata and results.
- `QuestData.lua`: bundled descriptions for the addon.
- `LoreCompanion.zip`: installable addon package.

Builds reuse this folder, preserve this README, and remove the old ZIP before
fetching. Do not run builds concurrently. The current [map](../tools/quest-data-fetcher/quest_map.json)
covers The Light's Summons only; full dialogue and narrative order are unverified.
