# Lore Companion 0.3.0

A World of Warcraft Retail addon for reading original campaign summaries and
bundled quest descriptions. Open it with `/lore`.

Use `/lore scan` in WoW to show campaign chapter metadata and client quest IDs
in a scrollable copy window. Text is selected automatically: press Cmd+C on Mac
or Ctrl+C on Windows, then paste the results outside WoW. Use **Select all** to
select the text again. This reveals chapter names (spoilers). It compares bundled
membership and ordering with client questline lists, following Blizzard's own
chapter implementation. It does not establish narrative order or expansion-wide
completeness, and does not rewrite the bundled quest mapping.

- **Summary:** Blizzard's campaign recap.
- **Quest data:** builds request 233 candidate quests across the 17 scanned Midnight
  campaign chapters. Expansion-wide completeness and narrative order remain unverified.
- **Quests view:** displays bundled quests when the selected heading uniquely
  matches a bundled or client chapter title. Missing or ambiguous matches show an unavailable
  message. Read one quest at a time using **Prev quest**
  and **Next quest**, with a quest counter and a separate title. Choose chapters
  from the left list. Full dialogue is not included; hover over the Quests tab
  for the source and ordering note.
- **Quest navigation:** the chapter name stays above the quest title. Use
  **Choose quest** to jump directly to a quest; missing descriptions are labelled
  in the menu. Longer menus scroll.
- **Reading bookmarks:** reopening `/lore` restores the last chapter, tab, and
  quest per character. Quests are remembered by ID, so a reordered list can still
  restore the same quest. A removed quest falls back to the first quest. Chapters
  revealed only through the spoiler checkbox are not saved; spoiler consent is
  reset when the window closes. Scroll position is not saved between openings.
- **Text availability:** chapter rows show summary availability and the number of
  bundled descriptions, for example **Quest text: 16/17**. These are text counts,
  not completion indicators. Unmatched headings, ambiguous matches, missing data,
  and missing individual descriptions have separate explanations. Unique title
  matching ignores case and extra whitespace, and can use localized client chapter
  metadata when available. Bundled quest text remains English.
- **Quest progress:** the selected quest and quest selector show **Completed**,
  **Active**, **Not completed**, or **Unknown** for this character. Updates follow
  quest-log changes. Not completed does not mean the quest is available to accept;
  unavailable APIs produce Unknown. These labels are separate from text counts.
- **Client verification:** the reader uses the live chapter questline when the
  client returns a nonempty list. Otherwise it keeps the bundled list marked
  unverified. Hover over **Quests** for the comparison, or run `/lore scan` for a
  report. Client list order is not a verified narrative sequence; branching and
  parallel quests still require in-game review.
- **Where am I?:** jumps to the client-reported current Midnight chapter, or its
  single active quest when live membership is confirmed. Multiple active quests
  leave the choice to the player. Hidden chapters stay hidden until the spoiler
  checkbox is enabled; unavailable or completed campaigns get an explanation.
- **Search:** searches visible chapter titles/summaries and available quest
  titles/descriptions. Choose a result to open the matching view and quest.
  Search uses literal text, ignores English letter case, and does not inspect
  hidden chapters. Escape in the search box clears the query.

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
commands and tests. CI checks Lua syntax, campaign request handling, reader
navigation/bookmarks, story progress/search, and Python tests on pushes and pull requests.

## Validate 0.3.0 in WoW

After deploying, run `/reload`, then `/lore`:

1. Select a chapter and open **Quests**. Confirm the chapter name remains above
   the quest title. Use **Choose quest** to select a later quest, then try both
   navigation buttons. Verify the title, description, counter, and menu selection
   agree.
2. Close and reopen with `/lore`; repeat after `/reload`. Confirm the same chapter,
   tab, and quest return. Switch to **Summary**, close, and reopen to verify that
   tab is remembered too. Each character has its own bookmark.
3. Check chapter availability labels. A missing description should remain
   selectable, be labelled in the menu, and display an explanation. A heading
   without matching bundled data should explain the mismatch and hide the selector.
4. Enable **Show chapters without summaries**, select one, then close and reopen.
   The checkbox should be off and the last bookmarked non-spoiler chapter restored.
5. Resize to the minimum window size and try larger text with **A+**. Check long
   chapter/quest titles, the scrolling selector, and the reading area for overlap.
6. Compare a known completed quest, an active quest, and an untouched quest with
   their progress labels. Turn in or abandon an active quest while the reader is
   open; labels should refresh without changing the selected quest.
7. Run `/lore scan` and inspect the bundled/client comparison. Check a chapter's
   membership against the in-game campaign questline and its story sequence while
   playing. Do not interpret an exact list match as proof of narrative order.
8. Click **Where am I?** with an active campaign quest. Test multiple active quests
   and a hidden current chapter too; it must not choose arbitrarily or reveal
   hidden names. A finished campaign may have no current chapter.
9. Search for a quest title and a word from a description, then select the result.
   Try a nonexistent phrase and literal punctuation. Search for a hidden chapter
   before/after enabling the spoiler checkbox; disabling it must remove its results.

For errors, enable `/console scriptErrors 1`, reproduce the problem, and record
the Lua error plus the chapter and quest. Automated stand-ins test behavior;
dropdown rendering and layout must be checked in the actual Retail client.

## API references

The live membership check follows Blizzard's
[CampaignChapter implementation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_ObjectAPI/Mainline/CampaignChapter.lua).
Progress uses `C_QuestLog.IsQuestFlaggedCompleted` and `C_QuestLog.IsOnQuest`
([quest-log definitions](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua)).
Current-story navigation uses `C_CampaignInfo.GetCurrentChapterID`
([campaign definitions](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/WarCampaignDocumentation.lua)).
These source checks and mocked tests do not replace validation in the running client.
