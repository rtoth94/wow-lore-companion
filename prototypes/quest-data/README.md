# Lore Quest Data 0.2.0

A small Python package that downloads original Blizzard quest descriptions and
exports JSON responses, a results manifest, and `QuestData.lua`. It does not
package or deploy the addon. Python 3.9+; no runtime dependencies.

From the repository root:

```sh
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -e prototypes/quest-data
```

Copy `.env.example` to `.env` in this directory if it does not already exist,
then fill in `BLIZZARD_CLIENT_ID` and `BLIZZARD_CLIENT_SECRET`. Existing environment
variables take precedence. Credentials are never included in generated data.
The env parser supports comments on their own lines and optionally quoted values;
it does not perform shell expansion. Missing credentials prompt in a terminal.

```sh
lore-quest-data --map prototypes/quest-data/quest_map.json \
  --env-file prototypes/quest-data/.env --output output
```

Equivalent: `python -m lore_quest_data` with the same arguments. Options include
`--region eu|us`, `--version`, and `--help`. Paths are relative to your current
directory. English locales are en_GB for EU and en_US for US.

The map currently covers chapter 5811 of campaign 270, with 17 candidate quest
IDs observed in-game. Multiple chapters are supported. Shared quest IDs are
fetched once; chapter lists retain map order. Membership completeness and narrative
order remain unverified. Empty descriptions are marked unavailable, not invented.

Each run replaces generated quest JSON, manifest and Lua data in the selected
output directory. README files are preserved. Failed requests are recorded in the
manifest and prevent Lua generation (exit code 1). No retries are automatic.
Do not run generators concurrently. The generator does not manage existing ZIPs;
use the root build command to regenerate the package after changing data.

## Structure

- `src/lore_quest_data/api.py`: credentials and Blizzard HTTP requests.
- `src/lore_quest_data/generate.py`: map export and Lua serialization.
- `src/lore_quest_data/cli.py`: argparse interface.
- `quest_map.json`: selected campaign chapters and quest IDs.
- `pyproject.toml`: package metadata and console entry point.

Version is defined in `src/lore_quest_data/__init__.py`.

## Build and deploy

With the package installed, use the separate root script:

```sh
python manage.py --build
python manage.py --deploy
# Or build, then deploy only if the build succeeds:
python manage.py --build --deploy
```

The build calls this package's CLI, then bundles the generated Lua with addon
source into `output/LoreCompanion.zip`. Credentials, raw responses and Python code
stay outside the ZIP. Full dialogue coverage is not established by descriptions.

References: [Getting started](https://community.developer.battle.net/documentation/guides/getting-started),
[Quest API](https://community.developer.battle.net/documentation/world-of-warcraft/game-data-apis).

Run regression tests from the repository root after installation:

```sh
python -m unittest discover -s prototypes/quest-data/tests
```
