# Lore Companion 0.2.2

A World of Warcraft Retail addon for reading original campaign summaries and
bundled quest descriptions. Open it with `/lore`.

Use `/lore scan` in WoW to show campaign chapter metadata and candidate quest IDs
in a scrollable copy window. Text is selected automatically: press Cmd+C on Mac
or Ctrl+C on Windows, then paste the results outside WoW. Use **Select all** to
select the text again. This reveals chapter names (spoilers). The scan tests each chapter ID as
a questline ID; results do not establish membership, completeness, or story order.
It does not update the bundled quest mapping.

- **Summary:** Blizzard's campaign recap.
- **Quest data:** builds request 233 candidate quests across the 17 scanned Midnight
  campaign chapters. Expansion-wide completeness and narrative order remain unverified.
- **Quests view:** displays bundled quests when the selected heading uniquely
  matches a bundled chapter title. Missing or ambiguous matches show an unavailable
  message. Read one quest at a time using **Prev quest**
  and **Next quest**, with a quest counter and a separate title. Choose chapters
  from the left list. Full dialogue is not included; hover over the Quests tab
  for the source and ordering note.

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
Deployment stages the complete addon and restores the previous folder if installation fails.
After deployment, run `/reload` and test both tabs with `/lore`.
Campaign requests time out after 15 seconds; use `/lore` to retry.

See the [quest-data-fetcher guide](tools/quest-data-fetcher/README.md) for data-only
commands and tests. CI checks Lua syntax, campaign request handling, and Python tests
on pushes and pull requests.
