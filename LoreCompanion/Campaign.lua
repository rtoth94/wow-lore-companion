-- WoW passes the same private addon table to each file in manifest order.
local _, addon = ...

addon.Campaign = {}
local campaignID = 270
local waitingForLore = false
local loreFrame = CreateFrame("Frame")
local loreSections = {}
local onUpdate

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
                            title = name,
                            text = "No summary is available for this chapter in the returned campaign recap.",
                            unavailable = true,
                        })
                    end
                end
            end
        else
            table.insert(visibleSections, { title = "Chapter list unavailable", text = "Chapter information API is unavailable." })
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
        item.text = #item.paragraphs > 0 and table.concat(item.paragraphs, "\n\n") or "No summary text was returned for this heading."
    end
    if onUpdate then onUpdate("No campaign text was returned.") end
end)

-- The listener is registered before requesting, because responses can be synchronous.
function addon.Campaign.Request(callback)
    onUpdate = callback
    loreSections = {}
    waitingForLore = false
    if not C_LoreText or type(C_LoreText.RequestLoreTextForCampaignID) ~= "function" then
        callback("Campaign lore API is unavailable.")
        return
    end
    callback("Requesting Midnight campaign text...")
    waitingForLore = true
    C_LoreText.RequestLoreTextForCampaignID(campaignID)
end
