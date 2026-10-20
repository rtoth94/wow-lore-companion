# Lore Companion 0.2.1

A World of Warcraft Retail addon for reading original campaign summaries and
bundled quest descriptions. Open it with `/lore`.

- **Summary:** Blizzard's campaign recap.
- **Quests:** 17 bundled descriptions for **The Light's Summons**. Other chapters
  show an unavailable message. Full dialogue and narrative order remain unverified.

![Campaign summary](docs/images/lore-companion.png)
![Quest descriptions](docs/images/lore-companion-quests.png)

## Build and deploy

Install [uv](https://docs.astral.sh/uv/getting-started/installation/). Create
`tools/quest-data-fetcher/.env` from its `.env.example` and fill in your Blizzard
API client credentials. Keep an existing `.env` if already configured.

```sh
uv run manage.py --build
uv run manage.py --deploy
# Or both:
uv run manage.py --build --deploy
```

uv manages the package environment automatically. The ZIP is written to
`output/LoreCompanion.zip`; credentials and generated data are excluded from Git.
A failed build does not deploy an older ZIP.

Deployment defaults to macOS Retail. Use `--addons-dir PATH` or `WOW_ADDONS_DIR`
to override it, and `--region us` for US English data (default: EU English).
After deployment, run `/reload` and test both tabs with `/lore`.

See the [quest-data-fetcher guide](tools/quest-data-fetcher/README.md) for data-only
commands and tests. Lua syntax CI runs on pushes and pull requests.
