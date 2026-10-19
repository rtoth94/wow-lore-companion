-- WoW passes the same private addon table to each file in manifest order.
local _, addon = ...

-- Startup and slash commands stay separate from layout and campaign data.
SLASH_LORECOMPANION1 = "/lore"
SlashCmdList["LORECOMPANION"] = function()
    addon.Window.Open()
end

print("Lore Companion loaded.")
