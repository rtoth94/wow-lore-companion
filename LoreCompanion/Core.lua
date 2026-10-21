-- WoW passes the same private addon table to each file in manifest order.
local _, addon = ...

-- Startup and slash commands stay separate from layout and campaign data.
SLASH_LORECOMPANION1 = "/lore"
SlashCmdList["LORECOMPANION"] = function(message)
    if message:lower():match("^%s*scan%s*$") then
        local lines = {}
        addon.Campaign.Scan(function(line) table.insert(lines, line) end)
        addon.Window.ShowScan(table.concat(lines, "\n"))
    else
        addon.Window.Open()
    end
end

print("Lore Companion loaded.")
