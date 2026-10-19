-- Lore Companion's Lua entry point.

print("Lore Companion loaded.")

local campaignID = 270
local waitingForLore = false
local loreFrame = CreateFrame("Frame")

loreFrame:RegisterEvent("LORE_TEXT_UPDATED_CAMPAIGN")
loreFrame:SetScript("OnEvent", function(self, event, receivedCampaignID, textEntries)
    if not waitingForLore or receivedCampaignID ~= campaignID then return end
    waitingForLore = false
    local printedText = false
    for _, entry in ipairs(textEntries or {}) do
        if entry.text and entry.text ~= "" then
            print(entry.text)
            printedText = true
        end
    end
    if not printedText then print("Lore Companion: No campaign text was returned.") end
end)

SLASH_LORECOMPANION1 = "/lore"
SlashCmdList["LORECOMPANION"] = function()
    if not C_LoreText or type(C_LoreText.RequestLoreTextForCampaignID) ~= "function" then
        print("Lore Companion: Campaign lore API is unavailable.")
        return
    end
    waitingForLore = true
    C_LoreText.RequestLoreTextForCampaignID(campaignID)
end
