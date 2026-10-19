-- WoW passes the same private addon table to each file in manifest order.
local addonName, addon = ...

-- Blizzard's template supplies the background, title bar, and close button.
local loreWindow = CreateFrame("Frame", "LoreCompanionWindow", UIParent, "BasicFrameTemplate")
loreWindow:SetSize(760, 540)
loreWindow:SetPoint("CENTER")
loreWindow:EnableMouse(true)
-- Keep a readable minimum size while allowing the bottom-right corner to resize.
loreWindow:SetResizable(true)
loreWindow:SetResizeBounds(660, 350)
loreWindow.TitleText:SetText("Lore Companion")
loreWindow:SetMovable(true)
loreWindow:SetClampedToScreen(true)
-- Restrict dragging to the title bar so selecting text/list items never moves it.
local titleDrag = CreateFrame("Frame", nil, loreWindow)
titleDrag:SetPoint("TOPLEFT", 4, 0)
titleDrag:SetPoint("TOPRIGHT", -30, 0)
titleDrag:SetHeight(24)
titleDrag:EnableMouse(true)
titleDrag:RegisterForDrag("LeftButton")
titleDrag:SetScript("OnDragStart", function() loreWindow:StartMoving() end)
titleDrag:SetScript("OnDragStop", function() loreWindow:StopMovingOrSizing() end)
titleDrag:SetScript("OnHide", function() loreWindow:StopMovingOrSizing() end)
loreWindow.CloseButton:SetScript("OnClick", function()
    loreWindow:Hide()
end)
loreWindow:Hide()
-- Blizzard's Escape handler closes named frames registered in this list.
table.insert(UISpecialFrames, "LoreCompanionWindow")

local resizeHandle = CreateFrame("Button", nil, loreWindow)
resizeHandle:SetSize(24, 24)
resizeHandle:SetPoint("BOTTOMRIGHT", -2, 2)
resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
resizeHandle:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        loreWindow:StartSizing("BOTTOMRIGHT")
    end
end)
resizeHandle:SetScript("OnMouseUp", function()
    loreWindow:StopMovingOrSizing()
end)
resizeHandle:SetScript("OnHide", function()
    loreWindow:StopMovingOrSizing()
end)

-- Chapter names may reveal future story. Reveal the full list only by opt-in;
-- this does not unlock future summaries or infer which chapters are completed.
local unfinishedCheckbox = CreateFrame("CheckButton", nil, loreWindow, "UICheckButtonTemplate")
unfinishedCheckbox:SetSize(26, 26)
unfinishedCheckbox:SetPoint("TOPLEFT", 16, -32)
unfinishedCheckbox:SetChecked(false)
local checkboxLabel = loreWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
checkboxLabel:SetPoint("LEFT", unfinishedCheckbox, "RIGHT", 4, 0)
checkboxLabel:SetText("Show chapters without summaries (spoilers)")

-- Keep the explanation in a tooltip so the story has more room.
unfinishedCheckbox:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Additional chapters")
    GameTooltip:AddLine("Reveal names without returned summaries. Names may spoil future story. This does not unlock missing text.", 1, 1, 1, true)
    GameTooltip:Show()
end)
unfinishedCheckbox:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Navigation and story text have independent scroll positions.
local chapterHeading = loreWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
chapterHeading:SetPoint("TOPLEFT", 20, -72)
chapterHeading:SetText("Midnight")
local chapterScroll = CreateFrame("ScrollFrame", nil, loreWindow)
chapterScroll:SetPoint("TOPLEFT", 20, -104)
chapterScroll:SetPoint("BOTTOMLEFT", 20, 35)
chapterScroll:SetWidth(208)
local chapterContent = CreateFrame("Frame", nil, chapterScroll)
chapterContent:SetSize(208, 1)
chapterScroll:SetScrollChild(chapterContent)
chapterScroll:EnableMouseWheel(true)
chapterScroll:SetScript("OnMouseWheel", function(self, delta)
    self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScroll() - delta * 40, self:GetVerticalScrollRange())))
end)
local divider = loreWindow:CreateTexture(nil, "ARTWORK")
divider:SetColorTexture(0.7, 0.6, 0.4, 0.35)
divider:SetPoint("TOPLEFT", 250, -72)
divider:SetPoint("BOTTOMLEFT", 250, 35)
divider:SetWidth(1)
local storyTitle = loreWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
storyTitle:SetPoint("TOPLEFT", 270, -72)
storyTitle:SetPoint("TOPRIGHT", -20, -72)
storyTitle:SetJustifyH("LEFT")

-- The scroll child grows with the text; the viewport stays inside the window.
local scrollFrame = CreateFrame("ScrollFrame", nil, loreWindow)
scrollFrame:SetPoint("TOPLEFT", 270, -117)
scrollFrame:SetPoint("BOTTOMRIGHT", -38, 70)
local scrollContent = CreateFrame("Frame", nil, scrollFrame)
scrollContent:SetSize(380, 1)
scrollFrame:SetScrollChild(scrollContent)
local loreText = scrollContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
-- Use the player's existing font with a larger reading size and line spacing.
local fontPath, _, fontFlags = loreText:GetFont()
loreText:SetFont(fontPath, 15, fontFlags)
loreText:SetSpacing(3)
loreText:SetPoint("TOPLEFT")
loreText:SetWidth(380)
loreText:SetJustifyH("LEFT")
loreText:SetJustifyV("TOP")

-- Clamp scrolling so the mouse wheel cannot move beyond either end of the text.
scrollFrame:EnableMouseWheel(true)
scrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local offset = self:GetVerticalScroll() - delta * 40
    self:SetVerticalScroll(math.max(0, math.min(offset, self:GetVerticalScrollRange())))
end)

-- Read the manifest so future releases only need one version value updated.
local version = C_AddOns.GetAddOnMetadata(addonName, "Version")
local versionLabel = loreWindow:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
versionLabel:SetPoint("BOTTOMLEFT", 20, 12)
versionLabel:SetText(version and ("v" .. version) or "Version unavailable")

-- Both panels use the same small scrollbar binding. A guard prevents slider
-- updates and scroll events from calling one another recursively.
local function addScrollbar(viewport)
    local slider = CreateFrame("Slider", nil, loreWindow)
    slider:SetPoint("TOPLEFT", viewport, "TOPRIGHT", 5, -8)
    slider:SetPoint("BOTTOMLEFT", viewport, "BOTTOMRIGHT", 5, 8)
    slider:SetWidth(12)
    slider:SetOrientation("VERTICAL")
    slider:SetMinMaxValues(0, 0)
    slider:SetValue(0)
    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    track:SetColorTexture(0, 0, 0, 0.45)
    slider:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
    slider:GetThumbTexture():SetSize(16, 24)
    local syncing = false
    local function sync()
        if syncing then return end
        syncing = true
        local range = math.max(0, viewport:GetVerticalScrollRange())
        local offset = math.max(0, math.min(viewport:GetVerticalScroll(), range))
        slider:SetMinMaxValues(0, range)
        slider:SetValue(offset)
        slider:SetEnabled(range > 0)
        slider:SetAlpha(range > 0 and 1 or 0.3)
        viewport:SetVerticalScroll(offset)
        syncing = false
    end
    slider:SetScript("OnValueChanged", function(self, value)
        if not syncing then viewport:SetVerticalScroll(value) end
    end)
    viewport:SetScript("OnVerticalScroll", sync)
    viewport:SetScript("OnScrollRangeChanged", sync)
    sync()
end
addScrollbar(chapterScroll)
addScrollbar(scrollFrame)

local function updateTextLayout()
    -- Wrapping changes the text height. Recalculate the scroll child after its
    -- width changes, then clamp the old offset to the new scrollable range.
    local width = math.max(1, scrollFrame:GetWidth())
    scrollContent:SetWidth(width)
    -- Limit line length when the player stretches the window very wide.
    loreText:SetWidth(math.min(width, 620))
    scrollContent:SetHeight(math.max(1, loreText:GetStringHeight() + 8))
    scrollFrame:UpdateScrollChildRect()
    scrollFrame:SetVerticalScroll(math.min(scrollFrame:GetVerticalScroll(), scrollFrame:GetVerticalScrollRange()))
end

scrollFrame:SetScript("OnSizeChanged", updateTextLayout)

local function displayText(text)
    loreText:SetText(text)
    updateTextLayout()
    scrollFrame:SetVerticalScroll(0)
end

local function makeButton(label, width)
    local button = CreateFrame("Button", nil, loreWindow, "UIPanelButtonTemplate")
    button:SetSize(width, 24)
    button:SetText(label)
    return button
end
local previousButton = makeButton("Previous", 82)
previousButton:SetPoint("BOTTOMLEFT", 270, 38)
local nextButton = makeButton("Next", 70)
nextButton:SetPoint("BOTTOMRIGHT", -38, 38)
local positionLabel = loreWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
positionLabel:SetPoint("LEFT", previousButton, "RIGHT", 8, 0)
positionLabel:SetPoint("RIGHT", nextButton, "LEFT", -8, 0)
local smallerButton = makeButton("A-", 32)
smallerButton:SetPoint("TOPRIGHT", -58, -32)
local largerButton = makeButton("A+", 32)
largerButton:SetPoint("LEFT", smallerButton, "RIGHT", 4, 0)
local fontSize = 15
local function setFontSize(size)
    fontSize = math.max(12, math.min(22, size))
    loreText:SetFont(fontPath, fontSize, fontFlags)
    smallerButton:SetEnabled(fontSize > 12)
    largerButton:SetEnabled(fontSize < 22)
    updateTextLayout()
end
smallerButton:SetScript("OnClick", function() setFontSize(fontSize - 1) end)
largerButton:SetScript("OnClick", function() setFontSize(fontSize + 1) end)

local campaignText = "Requesting Midnight campaign text..."
local chapterButtons = {}
local selectedSection
local visibleSections = {}
local selectedIndex

local function selectSection(section)
    selectedSection = section
    for index, item in ipairs(visibleSections) do
        if item == section then selectedIndex = index; break end
    end
    previousButton:SetEnabled(selectedIndex > 1)
    nextButton:SetEnabled(selectedIndex < #visibleSections)
    positionLabel:SetText("Section " .. selectedIndex .. " of " .. #visibleSections)
    -- Bookmark only returned lore, never an opt-in placeholder. Count duplicate
    -- headings so identical titles remain distinct without inventing chapter IDs.
    if not section.unavailable and type(LoreCompanionCharacter) == "table" then
        local occurrence = 0
        for index = 1, selectedIndex do
            if visibleSections[index].title == section.title then occurrence = occurrence + 1 end
        end
        LoreCompanionCharacter.midnight = { title = section.title, occurrence = occurrence }
    end
    -- Scroll only when the selected row lies outside the navigation viewport.
    local row = chapterButtons[selectedIndex]
    local offset = chapterScroll:GetVerticalScroll()
    if row.top < offset then
        offset = row.top
    elseif row.top + row:GetHeight() > offset + chapterScroll:GetHeight() then
        offset = row.top + row:GetHeight() - chapterScroll:GetHeight()
    end
    chapterScroll:SetVerticalScroll(math.max(0, math.min(offset, chapterScroll:GetVerticalScrollRange())))
    storyTitle:SetText(section.title)
    displayText(section.text)
    for _, button in ipairs(chapterButtons) do
        local selected = button.section == section
        button.selection:SetShown(selected)
        button.selectionBar:SetShown(selected)
        if selected then
            button.label:SetTextColor(1, 0.82, 0.3)
        elseif button.section and button.section.unavailable then
            button.label:SetTextColor(0.6, 0.6, 0.6)
        else
            button.label:SetTextColor(0.9, 0.9, 0.9)
        end
    end
end

previousButton:SetScript("OnClick", function()
    if selectedIndex and visibleSections[selectedIndex - 1] then selectSection(visibleSections[selectedIndex - 1]) end
end)
nextButton:SetScript("OnClick", function()
    if selectedIndex and visibleSections[selectedIndex + 1] then selectSection(visibleSections[selectedIndex + 1]) end
end)

local function refreshContent()
    visibleSections = addon.Campaign.GetSections(unfinishedCheckbox:GetChecked())
    local selectionStillVisible = false
    local y = 0
    for index, section in ipairs(visibleSections) do
        local button = chapterButtons[index]
        if not button then
            button = CreateFrame("Button", nil, chapterContent)
            button:SetWidth(204)
            button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            button.label:SetPoint("TOPLEFT", 8, -8)
            button.label:SetWidth(188)
            button.label:SetJustifyH("LEFT")
            button.selection = button:CreateTexture(nil, "BACKGROUND")
            button.selection:SetAllPoints()
            button.selection:SetColorTexture(0.6, 0.45, 0.15, 0.35)
            button.selectionBar = button:CreateTexture(nil, "ARTWORK")
            button.selectionBar:SetPoint("TOPLEFT")
            button.selectionBar:SetPoint("BOTTOMLEFT")
            button.selectionBar:SetWidth(3)
            button.selectionBar:SetColorTexture(1, 0.82, 0.3, 1)
            button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
            button:SetScript("OnClick", function(self) selectSection(self.section) end)
            -- Buttons receive mouse input, so forward wheel movement to the list.
            button:EnableMouseWheel(true)
            button:SetScript("OnMouseWheel", function(self, delta)
                chapterScroll:GetScript("OnMouseWheel")(chapterScroll, delta)
            end)
            chapterButtons[index] = button
        end
        button.section = section
        -- Display order is not a verified chapter number or completion status.
        button.label:SetText(index .. ". " .. section.title .. (section.unavailable and "\nNo summary" or ""))
        button.label:SetTextColor(section.unavailable and 0.6 or 1, section.unavailable and 0.6 or 0.82, section.unavailable and 0.6 or 0.3)
        button:SetHeight(math.max(36, button.label:GetStringHeight() + 16))
        button:ClearAllPoints()
        button.top = y
        button:SetPoint("TOPLEFT", 0, -y)
        button:Show()
        y = y + button:GetHeight() + 2
        if selectedSection == section then selectionStillVisible = true end
    end
    for index = #visibleSections + 1, #chapterButtons do
        chapterButtons[index]:Hide()
        chapterButtons[index].section = nil
    end
    chapterContent:SetHeight(math.max(1, y))
    chapterScroll:UpdateScrollChildRect()
    chapterScroll:SetVerticalScroll(math.min(chapterScroll:GetVerticalScroll(), chapterScroll:GetVerticalScrollRange()))
    if #visibleSections > 0 then
        local restoredSection
        local bookmark = type(LoreCompanionCharacter) == "table" and LoreCompanionCharacter.midnight
        if not selectionStillVisible and type(bookmark) == "table" then
            local occurrence = 0
            for _, section in ipairs(visibleSections) do
                if not section.unavailable and section.title == bookmark.title then
                    occurrence = occurrence + 1
                    if occurrence == bookmark.occurrence then restoredSection = section; break end
                end
            end
        end
        selectSection(selectionStillVisible and selectedSection or restoredSection or visibleSections[1])
    else
        selectedSection = nil
        selectedIndex = nil
        previousButton:Disable()
        nextButton:Disable()
        positionLabel:SetText("")
        storyTitle:SetText("Midnight")
        displayText(campaignText)
    end
end

unfinishedCheckbox:SetScript("OnClick", refreshContent)
loreWindow:SetScript("OnHide", function()
    -- Require fresh consent after closing; another player/character must not
    -- inherit an open spoiler list. No preference is saved between sessions.
    unfinishedCheckbox:SetChecked(false)
    refreshContent()
end)


addon.Window = {}
function addon.Window.Open()
    loreWindow:Show()
    selectedSection = nil
    addon.Campaign.Request(function(message)
        campaignText = message
        refreshContent()
    end)
end

-- SavedVariables are available after ADDON_LOADED, not during file execution.
-- Save geometry and font size only; spoiler consent is never persisted.
local settingsEvents = CreateFrame("Frame")
settingsEvents:RegisterEvent("ADDON_LOADED")
settingsEvents:RegisterEvent("PLAYER_LOGOUT")
settingsEvents:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        if type(LoreCompanionSettings) ~= "table" then LoreCompanionSettings = {} end
        if type(LoreCompanionCharacter) ~= "table" then LoreCompanionCharacter = {} end
        local settings = LoreCompanionSettings
        if type(settings.width) == "number" and type(settings.height) == "number" then
            loreWindow:SetSize(math.max(660, math.min(settings.width, UIParent:GetWidth())), math.max(350, math.min(settings.height, UIParent:GetHeight())))
        end
        if type(settings.x) == "number" and type(settings.y) == "number" then
            loreWindow:ClearAllPoints()
            loreWindow:SetPoint("CENTER", UIParent, "CENTER", settings.x, settings.y)
        end
        if type(settings.fontSize) == "number" then setFontSize(settings.fontSize) end
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGOUT" then
        local x, y = loreWindow:GetCenter()
        local parentX, parentY = UIParent:GetCenter()
        LoreCompanionSettings = {
            width = loreWindow:GetWidth(), height = loreWindow:GetHeight(),
            x = x - parentX, y = y - parentY, fontSize = fontSize,
        }
    end
end)
