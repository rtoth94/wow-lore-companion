-- Behavioral checks with small UI stand-ins; real layout still needs WoW testing.
local objects = {}
local methods = {}
local function object(kind, parent)
    local value = setmetatable({ kind = kind, parent = parent, scripts = {}, shown = true,
        width = 380, height = 200, offset = 0, enabled = true }, { __index = methods })
    table.insert(objects, value)
    return value
end
for _, name in ipairs({ "SetPoint", "ClearAllPoints", "EnableMouse", "SetResizable",
    "SetResizeBounds", "SetMovable", "SetClampedToScreen", "RegisterForDrag",
    "StartMoving", "StopMovingOrSizing", "StartSizing", "SetNormalTexture",
    "SetHighlightTexture", "SetPushedTexture", "SetColorTexture", "SetAllPoints",
    "SetJustifyH", "SetJustifyV", "SetFont", "SetSpacing", "EnableMouseWheel",
    "SetOrientation", "SetMinMaxValues", "SetAlpha", "SetScrollChild",
    "UpdateScrollChildRect", "UnregisterEvent" }) do
    methods[name] = function() end
end
function methods:SetText(text) self.text = text end
function methods:SetTextColor() end
function methods:SetSize(width, height) self.width, self.height = width, height end
function methods:SetWidth(width) self.width = width end
function methods:SetHeight(height) self.height = height end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:GetStringHeight() return 16 end
function methods:GetFont() return "test-font", 15, "" end
function methods:CreateFontString() return object("FontString", self) end
function methods:CreateTexture() return object("Texture", self) end
function methods:SetThumbTexture() self.thumb = object("Texture", self) end
function methods:GetThumbTexture() return self.thumb end
function methods:SetScript(event, callback) self.scripts[event] = callback end
function methods:GetScript(event) return self.scripts[event] end
function methods:RegisterEvent(event) self[event] = true end
function methods:Show() self.shown = true end
function methods:Hide()
    local wasShown = self.shown
    self.shown = false
    if wasShown and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function methods:SetShown(shown) if shown then self:Show() else self:Hide() end end
function methods:IsShown() return self.shown end
function methods:SetChecked(checked) self.checked = checked end
function methods:GetChecked() return self.checked end
function methods:SetEnabled(enabled) self.enabled = enabled end
function methods:Disable() self.enabled = false end
function methods:SetValue(value) self.value = value end
function methods:SetVerticalScroll(offset) self.offset = offset end
function methods:GetVerticalScroll() return self.offset end
function methods:GetVerticalScrollRange() return 500 end
function methods:OverrideText(text) self.text = text end
function methods:SetupMenu(generator) self.generator = generator end
function methods:GenerateMenu()
    self.items = {}
    local owner = self
    self.generator(self, {
        SetScrollMode = function(_, extent) owner.menuExtent = extent end,
        CreateRadio = function(_, label, isSelected, choose, value)
            table.insert(owner.items, { label = label, isSelected = isSelected, choose = choose, value = value })
        end,
    })
end
function CreateFrame(kind, name, parent, template)
    local frame = object(kind, parent)
    if template == "BasicFrameTemplate" then
        frame.TitleText = object("FontString", frame)
        frame.CloseButton = object("Button", frame)
    end
    if name then _G[name] = frame end
    return frame
end
UIParent = object("Frame")
UISpecialFrames = {}
C_AddOns = { GetAddOnMetadata = function() return "0.2.3" end }
LoreCompanionCharacter = {}
LoreCompanionSettings = {}
local chapters = {
    { title = "Chapter A", text = "Original summary A" },
    { title = "Chapter B", text = "Original summary B" },
    { title = "Unmatched", text = "Original summary C" },
}
local spoiler = { title = "Future chapter", text = "No summary", unavailable = true }
local data = {
    campaignID = 270,
    chapters = {
        { title = "Chapter A", questIDs = { 10, 20, 30 } },
        { title = "Chapter B", questIDs = { 40 } },
        { title = "Future chapter", questIDs = { 50 } },
    },
    quests = {
        [10] = { title = "First quest", description = "Original first text" },
        [20] = { title = "Second quest", description = "Original second text" },
        [30] = {},
        [40] = { title = "Other quest", description = "Original other text" },
        [50] = { title = "Future quest", description = "Original future text" },
    },
}
local ready, callback = false, nil
local addon = { QuestData = data, Campaign = {} }
function addon.Campaign.GetSections(showUnavailable)
    if not ready then return {} end
    local sections = {}
    for _, chapter in ipairs(chapters) do table.insert(sections, chapter) end
    if showUnavailable then table.insert(sections, spoiler) end
    return sections
end
function addon.Campaign.Request(update)
    ready, callback = false, update
    update("Loading")
end
assert(loadfile("LoreCompanion/Window.lua"))("LoreCompanion", addon)
local function receive()
    ready = true
    callback("No campaign text")
end
local function find(text, kind)
    for _, value in ipairs(objects) do
        if value.text == text and (not kind or kind == value.kind) then return value end
    end
    error("Missing UI text: " .. text)
end
local function contains(text)
    for _, value in ipairs(objects) do
        if value.text and value.text:find(text, 1, true) then return true end
    end
    return false
end
local function click(text)
    local button = find(text, "Button")
    assert(button.enabled, "Button disabled: " .. text)
    button.scripts.OnClick(button)
end
local function selectChapter(text)
    local label = find(text, "FontString")
    label.parent.scripts.OnClick(label.parent)
end
local selector = find("Choose quest", "DropdownButton")
local checkbox
for _, value in ipairs(objects) do if value.kind == "CheckButton" then checkbox = value end end

addon.Window.Open()
receive()
assert(contains("Summary available\nQuest text: 2/3"))
assert(contains("Quest match unavailable"))
click("Quests")
assert(selector.shown and #selector.items == 3 and selector.menuExtent == 240)
assert(selector.items[3].label:find("text unavailable", 1, true))
assert(find("Chapter A", "FontString").shown, "Chapter context missing")
selector.items[2].choose(selector.items[2].value)
assert(contains("Original second text"))
assert(LoreCompanionCharacter.midnight.questID == 20)
assert(LoreCompanionCharacter.midnight.tab == "Quests")
click("Next quest")
assert(contains("The original description for quest 30 is not included"))
assert(not find("Next quest", "Button").enabled)
click("Prev quest")

-- Reopen restores by ID even when list order changes; loading must not save over it.
LoreCompanionWindow:Hide()
data.chapters[1].questIDs = { 20, 10, 30 }
addon.Window.Open()
assert(LoreCompanionCharacter.midnight.questID == 20)
receive()
assert(not find("Quests", "Button").enabled)
assert(contains("Original second text"))
assert(not find("Prev quest", "Button").enabled)
assert(selector.items[1].isSelected(1))

-- Summary tab preserves the last quest; other chapters start at their first quest.
click("Summary")
LoreCompanionWindow:Hide()
addon.Window.Open()
receive()
assert(not find("Summary", "Button").enabled and not selector.shown)
click("Quests")
assert(LoreCompanionCharacter.midnight.questID == 20)
selectChapter("2. Chapter B")
assert(LoreCompanionCharacter.midnight.questID == 40)
assert(#selector.items == 1)

-- Spoiler-only selection must not replace the safe bookmark or restore consent.
checkbox:SetChecked(true)
checkbox.scripts.OnClick()
assert(contains("No summary\nQuest text: 1/1"))
selectChapter("4. Future chapter")
assert(LoreCompanionCharacter.midnight.title == "Chapter B")
LoreCompanionWindow:Hide()
assert(not checkbox:GetChecked())
addon.Window.Open()
receive()
assert(LoreCompanionCharacter.midnight.title == "Chapter B")
assert(contains("Original other text"))

selectChapter("3. Unmatched")
assert(not selector.shown and contains("No bundled chapter matches this heading"))
addon.QuestData = nil
click("Summary")
click("Quests")
assert(contains("Quest data is not installed"))
addon.QuestData = data
data.campaignID = 99
click("Summary")
click("Quests")
assert(contains("belongs to a different campaign"))
data.campaignID = 270

-- A removed saved quest falls back to the first; older bookmarks still work.
LoreCompanionCharacter.midnight = { title = "Chapter A", occurrence = 1, tab = "Quests", questID = 999 }
addon.Window.Open()
receive()
assert(LoreCompanionCharacter.midnight.questID == 20)
LoreCompanionCharacter.midnight = { title = "Chapter B", occurrence = 1 }
addon.Window.Open()
receive()
assert(LoreCompanionCharacter.midnight.tab == "Summary")

-- Never choose arbitrarily among repeated headings, in either source.
table.insert(data.chapters, { title = "Chapter B", questIDs = { 10 } })
click("Quests")
assert(contains("More than one bundled chapter uses this heading"))
table.remove(data.chapters)
table.insert(chapters, { title = "Chapter B", text = "Repeated summary" })
addon.Window.Open()
receive()
assert(contains("This heading appears more than once"))
table.remove(chapters)
data.chapters[2].questIDs = {}
addon.Window.Open()
receive()
assert(contains("no quest IDs are included"))
print("Window reading checks passed.")
