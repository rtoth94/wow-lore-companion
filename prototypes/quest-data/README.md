# Quest data retrieval prototype

Investigate whether Blizzard's web API supplies original quest descriptions
for completed Midnight quests. This prototype runs outside WoW and is not
loaded or deployed with the addon.

## First experiment

1. Follow Blizzard's [getting-started guide](https://community.developer.battle.net/documentation/guides/getting-started)
   to set up API access.
2. Request quest **88719 — A Voice from the Light**.
3. Inspect the returned fields and determine whether the original description
   is present. Record missing dialogue separately; a description does not prove
   that progress or completion dialogue is available.
4. Only after this succeeds, investigate the remaining quests in chapter 5811.

No retrieval code or authenticated request has been implemented yet.

## Evidence from the running client

- Campaign 270 includes chapter 5811, named The Light's Summons.
- Chapter metadata returned an empty description.
- `C_QuestLine.GetQuestLineQuests(5811)` returned 17 candidate quest IDs.
- Questline metadata for quests 91281 and 88719 returned questline ID 5811.
- Quest titles became available after requesting quest data.
- The tested character has completed these quests; none were in its quest log.
- Complete coverage and narrative ordering have not been verified.

## Credentials and output

Keep API credentials and access tokens outside committed files and the addon.
The repository ignores `.env` files. Do not paste credentials into chat.
Use the ignored `output/` directory for experimental responses; inspect them
before choosing any text for distribution. Preserve original text unchanged.

Bundling data is a later decision, after checking coverage and applicable usage
terms. Players should not need API credentials to read bundled addon data.
