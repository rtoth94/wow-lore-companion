-- Small WoW API stand-ins exercise request ordering without a running client.
local eventHandler
local timers = {}
function CreateFrame()
    return {
        RegisterEvent = function() end,
        SetScript = function(_, _, handler) eventHandler = handler end,
    }
end
C_Timer = { After = function(_, callback) table.insert(timers, callback) end }
C_LoreText = { RequestLoreTextForCampaignID = function() end }
local addon = {}
assert(loadfile("LoreCompanion/Campaign.lua"))("LoreCompanion", addon)
local message
local function update(value) message = value end

addon.Campaign.Request(update)
addon.Campaign.Request(update)
timers[1]()
assert(message == "Requesting Midnight campaign text...", "Old timer ended a newer request")
timers[2]()
assert(message:find("timed out", 1, true), "Missing timeout message")
eventHandler(nil, nil, 270, { { text = "Late response" } })
assert(#addon.Campaign.GetSections(false) == 0, "Accepted response after timeout")

-- A cached response may arrive before the request function returns.
C_LoreText.RequestLoreTextForCampaignID = function(id)
    eventHandler(nil, nil, id, {
        { text = "Heading", isHeader = true }, { text = "Original text" },
    })
end
addon.Campaign.Request(update)
timers[3]()
assert(addon.Campaign.GetSections(false)[1].text == "Original text")
assert(not message:find("timed out", 1, true), "Completed request timed out")
assert(not addon.Campaign.GetSections(false)[1].summaryUnavailable)

C_LoreText.RequestLoreTextForCampaignID = function(id)
    eventHandler(nil, nil, id, { { text = "Heading without body", isHeader = true } })
end
addon.Campaign.Request(update)
assert(addon.Campaign.GetSections(false)[1].summaryUnavailable,
    "Heading without body was marked as having summary text")

C_CampaignInfo = nil
local sections = addon.Campaign.GetSections(true)
assert(sections[#sections].unavailable, "API error can be saved as a bookmark")
print("Campaign request checks passed.")
