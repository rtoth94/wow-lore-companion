# Quest Data Fetcher 0.2.2

Fetch original Blizzard quest descriptions and generate JSON responses,
`manifest.json`, and `QuestData.lua`. This package only generates data;
the root `manage.py` builds and deploys the addon.

## Usage

Requires [uv](https://docs.astral.sh/uv/). Copy `.env.example` to `.env` here if
needed, and set your Blizzard API client ID and secret. Environment variables
`BLIZZARD_CLIENT_ID` and `BLIZZARD_CLIENT_SECRET` override the file.

From the repository root:

```sh
uv run --project tools/quest-data-fetcher --locked quest-data-fetcher \
  --map tools/quest-data-fetcher/quest_map.json \
  --env-file tools/quest-data-fetcher/.env --output output
```

Use `--help`, `--version`, or `--region us` (default: `eu`). uv installs the package
and manages Python automatically. No runtime dependencies are required.

The map contains 233 candidate quest entries across all 17 chapters returned by
the in-game scan of Midnight campaign 270. The generator processes every mapped
chapter and includes them all in the generated Lua data. This is scanned campaign
coverage, not verified coverage of the whole expansion or its side quests.
Shared IDs are fetched once; chapter order is preserved but narrative order and
completeness are not verified. Missing descriptions are marked unavailable.
HTTP 404 responses keep the quest ID with unavailable text and allow packaging.
Other failed requests produce a manifest and exit code 1 without generating Lua.
For a successful full-map run, expect `Saved 233/233 quests` and
`Generated 233 quests` (including unavailable placeholders). If a quest returns
404, the saved count is lower and the unavailable count is reported separately.
The addon reader displays mapped chapters through unique matching headings;
missing or ambiguous matches are shown as unavailable.

Each run replaces generated quest data, preserving README files. It does not
modify ZIPs. Do not run concurrent exports. Credentials stay out of output.

## Development

```sh
uv run --project tools/quest-data-fetcher --locked python -m unittest discover \
  -s tools/quest-data-fetcher/tests
```

`src/quest_data_fetcher/` contains `api.py` (HTTP/auth), `generate.py` (JSON/Lua),
and `cli.py` (argparse). Version lives in `__init__.py`; metadata is in
`pyproject.toml`, and `uv.lock` records the project resolution.

[Blizzard setup](https://community.developer.battle.net/documentation/guides/getting-started)
· [Quest API](https://community.developer.battle.net/documentation/world-of-warcraft/game-data-apis)
