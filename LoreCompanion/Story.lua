local _, addon = ...

-- Data helpers shared by the reader, search, and current-story navigation.
addon.Story = {}
local Story = addon.Story
local campaignID = 270
local liveChapters = {}
local liveQuests = {}

local function query(namespace, name, ...)
    if not namespace or type(namespace[name]) ~= "function" then return nil end
    local ok, value = pcall(namespace[name], ...)
    if ok then return value end
end

local function key(text)
    return (text or ""):lower():gsub("%s+", " "):match("^%s*(.-)%s*$")
end

function Story.Refresh()
    liveChapters, liveQuests = {}, {}
    local ids = query(C_CampaignInfo, "GetChapterIDs", campaignID)
    for _, id in ipairs(type(ids) == "table" and ids or {}) do
        liveChapters[id] = query(C_CampaignInfo, "GetCampaignChapterInfo", id) or {}
    end
end

function Story.QuestStatus(questID)
    local completed = query(C_QuestLog, "IsQuestFlaggedCompleted", questID)
    local active = query(C_QuestLog, "IsOnQuest", questID)
    if active == true then return "Active" end
    if completed == true then return "Completed" end
    if completed == false then return "Not completed" end
    return "Unknown"
end

function Story.QuestTitle(questID)
    local data = addon.QuestData
    local quest = data and data.quests and data.quests[questID]
    return quest and quest.title and quest.title ~= "" and quest.title or ("Quest " .. questID)
end

function Story.HasDescription(questID)
    local data = addon.QuestData
    local quest = data and data.quests and data.quests[questID]
    return quest and type(quest.description) == "string" and quest.description:find("%S") ~= nil
end

function Story.CheckChapter(bundled)
    local id = bundled.chapterID
    if not id or not liveChapters[id] then return bundled end
    if liveQuests[id] == nil then
        local quests = query(C_QuestLine, "GetQuestLineQuests", id)
        -- An empty response can mean unavailable data; it must not erase the bundle.
        liveQuests[id] = type(quests) == "table" and #quests > 0 and quests or false
    end
    local quests = liveQuests[id]
    if not quests then return bundled end
    local sameOrder = #quests == #(bundled.questIDs or {})
    local expected = {}
    for _, questID in ipairs(bundled.questIDs or {}) do expected[questID] = true end
    local sameMembers = sameOrder
    for index, questID in ipairs(quests) do
        if not expected[questID] then sameMembers = false end
        expected[questID] = nil
        if questID ~= (bundled.questIDs or {})[index] then sameOrder = false end
    end
    -- Blizzard's CampaignChapterMixin queries this same questline by chapter ID.
    -- Client list order is observable; narrative order is not established by it.
    return { chapterID = id, title = bundled.title, questIDs = quests,
        clientVerified = true, bundledMembersMatch = sameMembers, bundledOrderMatches = sameOrder }
end

function Story.FindChapter(section, sections)
    local data = addon.QuestData
    if not data then
        return nil, "Quest data is not installed. Install LoreCompanion.zip from the GitHub release assets.", "Quest data not installed"
    end
    if data.campaignID ~= campaignID then
        return nil, "The installed quest data belongs to a different campaign. Install the matching addon release.", "Quest data mismatch"
    end
    local title = key(section.title)
    local matches = 0
    for _, candidate in ipairs(sections) do
        if key(candidate.title) == title then matches = matches + 1 end
    end
    if matches ~= 1 then
        return nil, "This heading appears more than once in the chapter list, so its quests cannot be identified safely.", "Quest match ambiguous"
    end
    local chapter
    for _, candidate in ipairs(data.chapters or {}) do
        local live = liveChapters[candidate.chapterID]
        local matchesTitle = key(candidate.title) == title or (live and key(live.name) == title)
        if (section.chapterID and section.chapterID == candidate.chapterID)
            or (not section.chapterID and matchesTitle) then
            if chapter then
                return nil, "More than one bundled chapter uses this heading, so its quests cannot be identified safely.", "Quest match ambiguous"
            end
            chapter = candidate
        end
    end
    if not chapter then
        return nil, "No bundled chapter matches this heading. It may use different wording or have no mapped quests.", "Quest match unavailable"
    end
    chapter = Story.CheckChapter(chapter)
    if not chapter.questIDs or #chapter.questIDs == 0 then
        return nil, "This chapter is mapped, but no quest IDs are included in the installed data.", "No mapped quests"
    end
    return chapter
end

function Story.VerificationText(chapter)
    if not chapter.clientVerified then return "Bundled quest list; client verification unavailable. Narrative order unverified." end
    if chapter.bundledMembersMatch and chapter.bundledOrderMatches then
        return "Quest membership and list order match the client. Narrative order unverified."
    end
    return "Using the client's quest membership and list order; the bundled list differs. Narrative order unverified."
end

-- Only inspect caller-supplied visible sections. Hidden chapters never enter search.
function Story.Search(sections, text)
    local needle = key(text)
    local results = {}
    if needle == "" then return results end
    local function matches(value)
        return type(value) == "string" and value:lower():find(needle, 1, true) ~= nil
    end
    for _, section in ipairs(sections) do
        if matches(section.title) or (not section.unavailable and not section.summaryUnavailable and matches(section.text)) then
            table.insert(results, { section = section, tab = "Summary", label = section.title .. " — Summary" })
        end
        local chapter = Story.FindChapter(section, sections)
        if chapter then
            for _, questID in ipairs(chapter.questIDs) do
                local quest = addon.QuestData.quests and addon.QuestData.quests[questID]
                if matches(quest and quest.title) or matches(quest and quest.description) then
                    table.insert(results, { section = section, tab = "Quests", questID = questID,
                        label = section.title .. " — " .. Story.QuestTitle(questID) })
                end
            end
        end
    end
    return results
end

function Story.Current(sections)
    local id = query(C_CampaignInfo, "GetCurrentChapterID", campaignID)
    if type(id) ~= "number" or id <= 0 or not liveChapters[id] then
        return nil, "The client has not identified a current Midnight chapter. The campaign may be complete or unavailable."
    end
    local target
    for _, section in ipairs(sections) do
        local chapter = Story.FindChapter(section, sections)
        if (chapter and chapter.chapterID == id) or section.chapterID == id
            or (liveChapters[id].name and key(section.title) == key(liveChapters[id].name)) then
            if target then return nil, "The current chapter matches more than one visible heading; navigation is ambiguous." end
            target = { section = section, chapter = chapter }
        end
    end
    if target then
        local section, chapter = target.section, target.chapter
        -- Prefer an active quest only after membership has been confirmed by the client.
        if chapter and chapter.clientVerified then
            local active = {}
            for _, questID in ipairs(chapter.questIDs) do
                if query(C_QuestLog, "IsOnQuest", questID) == true then table.insert(active, questID) end
            end
            if #active == 1 then return { section = section, tab = "Quests", questID = active[1] } end
            if #active > 1 then
                return { section = section, tab = "Summary" }, "Several quests are active in this chapter. Choose one from the Quests tab."
            end
        end
        return { section = section, tab = "Summary" }, "Current chapter reported by the client. No single active quest was identified."
    end
    return nil, "Your current chapter is not in the visible list. You can opt in to additional chapters with the spoiler checkbox."
end
