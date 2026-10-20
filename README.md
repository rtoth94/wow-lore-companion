# Lore Companion 0.2.0

A World of Warcraft Retail addon for exploring original campaign summaries and
bundled quest descriptions. Open it with `/lore`.

The Summary tab displays Blizzard's returned campaign recap. The Quests tab
currently includes 17 quest descriptions for **The Light's Summons**. Other
sections show when bundled data is unavailable. Full dialogue and narrative
order are not yet verified; no lore is generated or rewritten.

![Lore Companion campaign summary](docs/images/lore-companion.png)

![Lore Companion Quests tab with bundled descriptions](docs/images/lore-companion-quests.png)

## Development setup

Python 3.9+ and Blizzard API client credentials are needed to build bundled data:

```sh
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -e prototypes/quest-data
```

Fill in the ignored `prototypes/quest-data/.env` using `.env.example` as a template.
See the [quest-data package guide](prototypes/quest-data/README.md) for setup and CLI options.

```sh
python manage.py --build
python manage.py --deploy
# Both operations, sequentially:
python manage.py --build --deploy
```

The build invokes the package CLI and creates `output/LoreCompanion.zip`. Deployment
installs that ZIP into the default macOS Retail AddOns directory. Override it with
`--addons-dir PATH` or `WOW_ADDONS_DIR`. `--region us` selects US English data;
the default is EU English. Run `python manage.py --help` for all options.

Generated data and credentials are ignored by Git. Only the [output README](output/README.md)
is tracked. A failed build removes the old ZIP and does not deploy. Builds should
not run concurrently. Deployment overwrites packaged files and retains unrelated
files in the installed addon directory.

After deploying, run `/reload`, then `/lore`. Check both tabs for The Light's
Summons and confirm other chapters show the unavailable message in Quests.
Lua syntax CI runs on pushes and pull requests; in-game verification is still required.
