local addon = { QuestData = {
    campaignID = 270,
    chapters = {
        { chapterID = 1, title = "First Chapter", questIDs = { 10, 20 } },
        { chapterID = 2, title = "Future Chapter", questIDs = { 30 } },
    },
    quests = {
        [10] = { title = "A familiar face", description = "Meet the ranger at Silvermoon." },
        [20] = { title = "Second quest", description = "Search for [clues]." },
        [30] = { title = "Secret quest", description = "A hidden future revelation." },
    },
} }
assert(loadfile("LoreCompanion/Story.lua"))("LoreCompanion", addon)
local Story = addon.Story
local first = { title = "First Chapter", text = "Original recap." }
local future = { title = "Future Chapter", text = "No summary", unavailable = true }
local sections = { first }

assert(Story.QuestStatus(10) == "Unknown")
C_QuestLog = {
    IsQuestFlaggedCompleted = function(id) return id == 10 end,
    IsOnQuest = function(id) return id == 20 end,
}
assert(Story.QuestStatus(10) == "Completed")
assert(Story.QuestStatus(20) == "Active")
assert(Story.QuestStatus(30) == "Not completed")
C_QuestLog.IsOnQuest = function() error("Data unavailable") end
assert(Story.QuestStatus(10) == "Completed")
C_QuestLog.IsQuestFlaggedCompleted = function() return nil end
assert(Story.QuestStatus(10) == "Unknown")

-- No client data: keep bundled text usable but do not claim verification.
Story.Refresh()
assert(not Story.FindChapter(first, sections).clientVerified)
assert(Story.VerificationText(Story.FindChapter(first, sections)):find("unavailable"))

local clientLists = { [1] = { 10, 20 }, [2] = { 30 } }
local current = 1
C_CampaignInfo = {
    GetChapterIDs = function(id) assert(id == 270); return { 1, 2 } end,
    GetCampaignChapterInfo = function(id) return { name = id == 1 and "Localized first" or "Future Chapter" } end,
    GetCurrentChapterID = function() return current end,
}
C_QuestLine = { GetQuestLineQuests = function(id) return clientLists[id] end }
Story.Refresh()
local chapter = Story.FindChapter(first, sections)
assert(chapter.clientVerified and chapter.bundledMembersMatch and chapter.bundledOrderMatches)
assert(Story.VerificationText(chapter):find("Narrative order unverified", 1, true))

-- Client order wins without changing the original bundle or fabricating missing text.
clientLists[1] = { 20, 10, 99 }
Story.Refresh()
chapter = Story.FindChapter(first, sections)
assert(chapter.clientVerified and not chapter.bundledMembersMatch and not chapter.bundledOrderMatches)
assert(chapter.questIDs[1] == 20 and chapter.questIDs[3] == 99)
assert(addon.QuestData.chapters[1].questIDs[1] == 10)
assert(Story.QuestTitle(99) == "Quest 99" and not Story.HasDescription(99))
clientLists[1] = { 20, 10 }
Story.Refresh()
chapter = Story.FindChapter(first, sections)
assert(chapter.bundledMembersMatch and not chapter.bundledOrderMatches)
clientLists[1] = {}
Story.Refresh()
assert(not Story.FindChapter(first, sections).clientVerified)
assert(#Story.FindChapter(first, sections).questIDs == 2)

local localized = { title = "Localized first" }
assert(Story.FindChapter(localized, { localized }).chapterID == 1)
local lower = { title = " first   chapter " }
assert(Story.FindChapter(lower, { lower }).chapterID == 1)
assert(not Story.FindChapter(first, { first, lower }), "Duplicate normalized headings were accepted")

-- Literal matching across titles, summaries, and descriptions; never index hidden chapters.
assert(#Story.Search(sections, "silvermoon") == 1)
assert(Story.Search(sections, "SILVERMOON")[1].questID == 10)
assert(Story.Search(sections, "recap")[1].tab == "Summary")
assert(#Story.Search(sections, "[clues]") == 1)
assert(#Story.Search(sections, ".*") == 0, "Search treated input as a Lua pattern")
assert(#Story.Search(sections, "  ") == 0)
assert(#Story.Search(sections, "secret") == 0)
assert(#Story.Search({ first, future }, "secret") == 1)
assert(#Story.Search({ first, future }, "No summary") == 0, "Placeholder searched as lore")

-- Exactly one active quest can be selected, but only with live membership.
clientLists[1] = { 10, 20 }
C_QuestLog.IsOnQuest = function(id) return id == 20 end
Story.Refresh()
local result = Story.Current(sections)
assert(result.section == first and result.questID == 20 and result.tab == "Quests")
C_QuestLog.IsOnQuest = function() return true end
local message
result, message = Story.Current(sections)
assert(result.tab == "Summary" and not result.questID and message:find("Several quests"))
clientLists[1] = {}
Story.Refresh()
assert(Story.Current(sections).tab == "Summary")
current = 2
result, message = Story.Current(sections)
assert(not result and message:find("spoiler checkbox") and not message:find("Future Chapter"))
assert(Story.Current({ first, future }).questID == 30)
local savedData = addon.QuestData
addon.QuestData = nil
assert(Story.Current({ future }).tab == "Summary", "Current chapter unnecessarily required quest data")
addon.QuestData = savedData
current = nil
assert(not Story.Current(sections))
C_CampaignInfo.GetCurrentChapterID = function() error("Unavailable") end
assert(not Story.Current(sections))
print("Story progress, verification, search, and navigation checks passed.")
