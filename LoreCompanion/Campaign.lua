-- WoW passes the same private addon table to each file in manifest order.
local _, addon = ...

addon.Campaign = {}
local campaignID = 270
local waitingForLore = false
local loreFrame = CreateFrame("Frame")
local loreSections = {}
local onUpdate
local requestNumber = 0

-- Blizzard's CampaignChapterMixin uses chapter IDs as questline IDs.
function addon.Campaign.Scan(writeLine)
    -- Send diagnostics to the copy window, or chat when no receiver is supplied.
    local print = writeLine or print
    if not C_CampaignInfo or type(C_CampaignInfo.GetChapterIDs) ~= "function"
        or type(C_CampaignInfo.GetCampaignChapterInfo) ~= "function" then
        print("Lore Companion: campaign information API is unavailable.")
        return
    end
    local chapterIDs = C_CampaignInfo.GetChapterIDs(campaignID)
    if not chapterIDs or #chapterIDs == 0 then
        print("Lore Companion: no chapters returned for campaign " .. campaignID .. ".")
        return
    end
    print("Lore Companion: campaign " .. campaignID .. ", " .. #chapterIDs .. " chapters (spoilers).")
    if addon.Story then addon.Story.Refresh() end
    print("Client questline lists: narrative order and expansion-wide completeness remain unverified.")
    local canQueryQuests = C_QuestLine and type(C_QuestLine.GetQuestLineQuests) == "function"
    for _, chapterID in ipairs(chapterIDs) do
        local info = C_CampaignInfo.GetCampaignChapterInfo(chapterID)
        print("Chapter " .. chapterID .. ": " .. (info and info.name or "Metadata unavailable"))
        for _, bundled in ipairs(addon.QuestData and addon.QuestData.chapters or {}) do
            if bundled.chapterID == chapterID and addon.Story then
                local checked = addon.Story.CheckChapter(bundled)
                print("  " .. addon.Story.VerificationText(checked))
                print("  Bundled quests: " .. #(bundled.questIDs or {}) .. "; displayed quests: " .. #(checked.questIDs or {}))
            end
        end
        -- Inspect returned fields instead of assuming a questline field exists.
        for key, value in pairs(info or {}) do
            print("  " .. tostring(key) .. " = " .. tostring(value))
        end
        if canQueryQuests then
            -- pcall catches an API error so the remaining chapters can be inspected.
            local ok, quests = pcall(C_QuestLine.GetQuestLineQuests, chapterID)
            if ok and type(quests) == "table" then
                print("  Client questline " .. chapterID .. ": " .. #quests .. " quests")
                -- Short lines keep longer lists readable in the chat window.
                for first = 1, #quests, 10 do
                    local ids = {}
                    for index = first, math.min(first + 9, #quests) do
                        table.insert(ids, tostring(quests[index]))
                    end
                    print("  " .. table.concat(ids, ", "))
                end
                if #quests == 0 then print("  No IDs returned; this does not prove the chapter has no quests.") end
            else
                print("  Questline query failed or returned unavailable data.")
            end
        end
    end
    if not canQueryQuests then print("Questline API unavailable; only chapter metadata was inspected.") end
    print("Lore Companion: scan complete.")
end

function addon.Campaign.GetSections(showUnavailable)
    local visibleSections = {}
    local returnedTitles = {}
    -- Navigate actual lore headings, not guessed chapter IDs. Duplicate headings
    -- remain separate entries and unheaded text is kept as a campaign overview.
    for _, section in ipairs(loreSections) do
        table.insert(visibleSections, section)
        returnedTitles[section.title] = true
    end
    if showUnavailable then
        -- These APIs were verified in the client. Still handle missing APIs/data
        -- so the recap remains readable if chapter metadata cannot be retrieved.
        if C_CampaignInfo and type(C_CampaignInfo.GetChapterIDs) == "function"
            and type(C_CampaignInfo.GetCampaignChapterInfo) == "function" then
            local chapterIDs = C_CampaignInfo.GetChapterIDs(campaignID)
            if chapterIDs then
                for _, chapterID in ipairs(chapterIDs) do
                    local info = C_CampaignInfo.GetCampaignChapterInfo(chapterID)
                    local name = info and info.name
                    if not name or name == "" then
                        name = "Chapter name unavailable"
                    end
                    -- Matching a title only avoids a duplicate navigation label;
                    -- it does not assign lore to an ID or establish completion.
                    if not returnedTitles[name] then
                        table.insert(visibleSections, {
                            chapterID = chapterID,
                            title = name,
                            text = "No summary is available for this chapter in the returned campaign recap.",
                            unavailable = true,
                        })
                    end
                end
            end
        else
            table.insert(visibleSections, { title = "Chapter list unavailable", text = "Chapter information API is unavailable.", unavailable = true })
        end
    end
    return visibleSections
end

loreFrame:RegisterEvent("LORE_TEXT_UPDATED_CAMPAIGN")
loreFrame:SetScript("OnEvent", function(self, event, receivedCampaignID, textEntries)
    if not waitingForLore or receivedCampaignID ~= campaignID then
        return
    end

    waitingForLore = false
    loreSections = {}
    local section
    -- Blizzard explicitly marks headings. Keep every body entry unchanged under
    -- its preceding heading; do not guess boundaries from punctuation or names.
    for _, entry in ipairs(textEntries or {}) do
        if entry.text and entry.text ~= "" then
            if entry.isHeader then
                section = { title = entry.text, paragraphs = {} }
                table.insert(loreSections, section)
            else
                if not section then
                    section = { title = "Campaign overview", paragraphs = {} }
                    table.insert(loreSections, section)
                end
                table.insert(section.paragraphs, entry.text)
            end
        end
    end
    for _, item in ipairs(loreSections) do
        item.summaryUnavailable = #item.paragraphs == 0
        item.text = #item.paragraphs > 0 and table.concat(item.paragraphs, "\n\n") or "No summary text was returned for this heading."
    end
    if onUpdate then onUpdate("No campaign text was returned.") end
end)

-- The listener is registered before requesting, because responses can be synchronous.
function addon.Campaign.Request(callback)
    requestNumber = requestNumber + 1
    local thisRequest = requestNumber
    onUpdate = callback
    loreSections = {}
    waitingForLore = false
    if not C_LoreText or type(C_LoreText.RequestLoreTextForCampaignID) ~= "function" then
        callback("Campaign lore API is unavailable.")
        return
    end
    callback("Requesting Midnight campaign text...")
    waitingForLore = true
    -- Each timer belongs to one request; an older timer must not end a retry.
    C_Timer.After(15, function()
        if waitingForLore and requestNumber == thisRequest then
            waitingForLore = false
            callback("Campaign text request timed out. Type /lore to retry.")
        end
    end)
    C_LoreText.RequestLoreTextForCampaignID(campaignID)
end
