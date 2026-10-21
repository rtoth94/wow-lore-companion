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
storyTitle:SetPoint("TOPLEFT", 270, -104)
storyTitle:SetPoint("TOPRIGHT", -20, -104)
storyTitle:SetJustifyH("LEFT")
local chapterContext = loreWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
chapterContext:SetPoint("TOPLEFT", 270, -104)
chapterContext:SetPoint("TOPRIGHT", -38, -104)
chapterContext:SetJustifyH("LEFT")
chapterContext:Hide()
local questStatus = loreWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
questStatus:SetPoint("TOPLEFT", storyTitle, "BOTTOMLEFT", 0, -8)
questStatus:SetPoint("TOPRIGHT", storyTitle, "BOTTOMRIGHT", 0, -8)
questStatus:SetJustifyH("LEFT")
questStatus:Hide()

-- The scroll child grows with the text; the viewport stays inside the window.
local scrollFrame = CreateFrame("ScrollFrame", nil, loreWindow)
scrollFrame:SetPoint("TOPLEFT", storyTitle, "BOTTOMLEFT", 0, -16)
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
local previousButton = makeButton("Previous", 90)
previousButton:SetPoint("BOTTOMLEFT", 270, 38)
local nextButton = makeButton("Next", 90)
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
local activeTab = "Summary"
local selectedQuestIndex = 1
local questCount = 0
local restoreReading = false
local tabOffsets = { Summary = 0, Quests = 0 }
local summaryTab = makeButton("Summary", 92)
summaryTab:SetPoint("TOPLEFT", 270, -68)
local questsTab = makeButton("Quests", 82)
questsTab:SetPoint("LEFT", summaryTab, "RIGHT", 4, 0)
questsTab:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Original quest descriptions (English)")
    GameTooltip:AddLine("Full dialogue is not included. Quest order has not been verified as narrative order.", 1, 1, 1, true)
    if selectedSection then
        local chapter = addon.Story.FindChapter(selectedSection, visibleSections)
        if chapter then GameTooltip:AddLine(addon.Story.VerificationText(chapter), 1, 1, 1, true) end
    end
    GameTooltip:Show()
end)
questsTab:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Keep the UI and search on the same chapter matching rules.
local function findQuestChapter(section)
    return addon.Story.FindChapter(section, visibleSections)
end
local questTitle = addon.Story.QuestTitle
local hasDescription = addon.Story.HasDescription

local function questReadingText(chapter, reason)
    if not chapter then return reason end
    local questID = chapter.questIDs[selectedQuestIndex]
    local quest = addon.QuestData.quests and addon.QuestData.quests[questID]
    storyTitle:SetText(questTitle(questID))
    return hasDescription(questID) and quest.description
        or "The original description for quest " .. questID .. " is not included in this release. You can select another quest; no replacement text has been generated."
end

local questSelector = CreateFrame("DropdownButton", nil, loreWindow, "WowStyle1DropdownTemplate")
questSelector:SetPoint("LEFT", questsTab, "RIGHT", 8, 0)
questSelector:SetWidth(140)
questSelector:OverrideText("Choose quest")
questSelector:Hide()

local function saveReading(chapter)
    -- Never persist opt-in spoiler chapters or overwrite a bookmark during loading.
    if not loreWindow:IsShown() or not selectedSection or selectedSection.unavailable
        or type(LoreCompanionCharacter) ~= "table" then return end
    local occurrence = 0
    for index = 1, selectedIndex do
        if visibleSections[index].title == selectedSection.title then occurrence = occurrence + 1 end
    end
    LoreCompanionCharacter.midnight = {
        title = selectedSection.title, occurrence = occurrence, tab = activeTab,
        questID = chapter and chapter.questIDs[selectedQuestIndex] or nil,
    }
end

local function renderTab()
    summaryTab:SetEnabled(activeTab ~= "Summary")
    questsTab:SetEnabled(activeTab ~= "Quests")
    questCount = 0
    local chapter, reason
    if selectedSection then chapter, reason = findQuestChapter(selectedSection) end
    if chapter then
        questCount = #chapter.questIDs
        selectedQuestIndex = math.max(1, math.min(selectedQuestIndex, questCount))
    end
    local isQuests = activeTab == "Quests"
    questStatus:SetShown(isQuests and chapter ~= nil)
    scrollFrame:ClearAllPoints()
    scrollFrame:SetPoint("TOPLEFT", isQuests and chapter and questStatus or storyTitle, "BOTTOMLEFT", 0, -16)
    scrollFrame:SetPoint("BOTTOMRIGHT", -38, 70)
    if chapter then
        local status = addon.Story.QuestStatus(chapter.questIDs[selectedQuestIndex])
        questStatus:SetText(status .. " • " .. (chapter.clientVerified and "Client quest list" or "Bundled list (unverified)"))
    end
    chapterContext:SetShown(isQuests and selectedSection ~= nil)
    chapterContext:SetText(selectedSection and selectedSection.title or "")
    storyTitle:ClearAllPoints()
    if isQuests and selectedSection then
        storyTitle:SetPoint("TOPLEFT", chapterContext, "BOTTOMLEFT", 0, -8)
        storyTitle:SetPoint("TOPRIGHT", chapterContext, "BOTTOMRIGHT", 0, -8)
    else
        storyTitle:SetPoint("TOPLEFT", 270, -104)
        storyTitle:SetPoint("TOPRIGHT", -38, -104)
    end
    storyTitle:SetText(selectedSection and selectedSection.title or "Midnight")
    local text = campaignText
    if selectedSection then
        if isQuests then
            storyTitle:SetText("Quest text unavailable")
            text = questReadingText(chapter, reason)
        else
            text = selectedSection.text
        end
    end
    questSelector:SetShown(isQuests and chapter ~= nil)
    if isQuests and chapter then questSelector:GenerateMenu() end
    -- The chapter list always changes chapters; these buttons page the active view.
    local index = isQuests and selectedQuestIndex or (selectedIndex or 0)
    local count = isQuests and questCount or #visibleSections
    previousButton:SetText(isQuests and "Prev quest" or "Previous")
    nextButton:SetText(isQuests and "Next quest" or "Next")
    previousButton:SetEnabled(count > 0 and index > 1)
    nextButton:SetEnabled(count > 0 and index < count)
    positionLabel:SetText(count > 0 and ((isQuests and "Quest " or "Section ") .. index .. " of " .. count) or "")
    displayText(text)
    scrollFrame:SetVerticalScroll(math.max(0, math.min(tabOffsets[activeTab], scrollFrame:GetVerticalScrollRange())))
    saveReading(chapter)
end

questSelector:SetupMenu(function(_, rootDescription)
    local chapter = selectedSection and findQuestChapter(selectedSection)
    if not chapter then return end
    rootDescription:SetScrollMode(240)
    for index, questID in ipairs(chapter.questIDs) do
        local label = index .. ". " .. questTitle(questID) .. " — " .. addon.Story.QuestStatus(questID)
        if not hasDescription(questID) then label = label .. " (text unavailable)" end
        rootDescription:CreateRadio(label, function(value) return value == selectedQuestIndex end,
            function(value)
                selectedQuestIndex = value
                tabOffsets.Quests = 0
                renderTab()
            end, index)
    end
end)

local function switchTab(tab)
    tabOffsets[activeTab] = scrollFrame:GetVerticalScroll()
    activeTab = tab
    renderTab()
end
summaryTab:SetScript("OnClick", function() switchTab("Summary") end)
questsTab:SetScript("OnClick", function() switchTab("Quests") end)

local function selectSection(section, bookmark)
    if selectedSection ~= section then
        tabOffsets = { Summary = 0, Quests = 0 }
        selectedQuestIndex = 1
    else
        tabOffsets[activeTab] = scrollFrame:GetVerticalScroll()
    end
    selectedSection = section
    if bookmark then
        activeTab = bookmark.tab == "Quests" and "Quests" or "Summary"
        local chapter = findQuestChapter(section)
        if chapter then
            for index, questID in ipairs(chapter.questIDs) do
                if questID == bookmark.questID then selectedQuestIndex = index; break end
            end
        end
    end
    for index, item in ipairs(visibleSections) do
        if item == section then selectedIndex = index; break end
    end
    previousButton:SetEnabled(selectedIndex > 1)
    nextButton:SetEnabled(selectedIndex < #visibleSections)
    positionLabel:SetText("Section " .. selectedIndex .. " of " .. #visibleSections)
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
    renderTab()
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

local function navigateTo(result)
    selectSection(result.section)
    activeTab = result.tab
    if result.questID then
        local chapter = findQuestChapter(result.section)
        for index, questID in ipairs(chapter and chapter.questIDs or {}) do
            if questID == result.questID then selectedQuestIndex = index; break end
        end
    end
    tabOffsets = { Summary = 0, Quests = 0 }
    renderTab()
end

local refreshContent
local searchLabel = loreWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
searchLabel:SetPoint("TOPLEFT", 20, -108)
searchLabel:SetText("Search")
local searchBox = CreateFrame("EditBox", nil, loreWindow, "InputBoxTemplate")
searchBox:SetPoint("TOPLEFT", 72, -100)
searchBox:SetSize(156, 26)
searchBox:SetAutoFocus(false)
searchBox:SetMaxLetters(100)
local searchResults = CreateFrame("DropdownButton", nil, loreWindow, "WowStyle1DropdownTemplate")
searchResults:SetPoint("TOPLEFT", 20, -130)
searchResults:SetWidth(208)
searchResults:OverrideText("Search results")
searchResults:Hide()

local function refreshSearch()
    local text = searchBox:GetText() or ""
    local searching = text:find("%S") ~= nil
    local results = addon.Story.Search(visibleSections, text)
    searchResults:SetShown(searching)
    searchResults:SetEnabled(#results > 0)
    searchResults:OverrideText(#results > 0 and ("Results: " .. #results) or "No matches")
    searchResults:GenerateMenu()
    chapterScroll:ClearAllPoints()
    chapterScroll:SetPoint("TOPLEFT", 20, searching and -168 or -138)
    chapterScroll:SetPoint("BOTTOMLEFT", 20, 35)
end
searchResults:SetupMenu(function(_, rootDescription)
    rootDescription:SetScrollMode(240)
    for _, result in ipairs(addon.Story.Search(visibleSections, searchBox:GetText() or "")) do
        rootDescription:CreateButton(result.label, navigateTo, result)
    end
end)
searchBox:SetScript("OnTextChanged", refreshSearch)
searchBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
searchBox:SetScript("OnEscapePressed", function(self)
    self:SetText("")
    self:ClearFocus()
end)

local function refreshStory()
    local oldChapter = selectedSection and findQuestChapter(selectedSection)
    local questID = oldChapter and oldChapter.questIDs[selectedQuestIndex]
    tabOffsets[activeTab] = scrollFrame:GetVerticalScroll()
    addon.Story.Refresh()
    refreshContent()
    local chapter = selectedSection and findQuestChapter(selectedSection)
    if chapter and questID then
        selectedQuestIndex = 1
        for index, id in ipairs(chapter.questIDs) do
            if id == questID then selectedQuestIndex = index; break end
        end
    end
    renderTab()
end

local whereButton = makeButton("Where am I?", 112)
whereButton:SetPoint("TOPLEFT", 116, -68)
whereButton:SetScript("OnClick", function()
    refreshStory()
    local result, message = addon.Story.Current(visibleSections)
    if result then navigateTo(result) end
    if message then print("Lore Companion: " .. message) end
end)

previousButton:SetScript("OnClick", function()
    if activeTab == "Quests" then
        if selectedQuestIndex > 1 then
            selectedQuestIndex = selectedQuestIndex - 1
            tabOffsets.Quests = 0
            renderTab()
        end
        return
    end
    if selectedIndex and visibleSections[selectedIndex - 1] then selectSection(visibleSections[selectedIndex - 1]) end
end)
nextButton:SetScript("OnClick", function()
    if activeTab == "Quests" then
        if selectedQuestIndex < questCount then
            selectedQuestIndex = selectedQuestIndex + 1
            tabOffsets.Quests = 0
            renderTab()
        end
        return
    end
    if selectedIndex and visibleSections[selectedIndex + 1] then selectSection(visibleSections[selectedIndex + 1]) end
end)

refreshContent = function()
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
            button.status = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            button.status:SetPoint("TOPLEFT", button.label, "BOTTOMLEFT", 0, -4)
            button.status:SetWidth(188)
            button.status:SetJustifyH("LEFT")
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
        button.label:SetText(index .. ". " .. section.title)
        local chapter, _, questStatus = findQuestChapter(section)
        if chapter then
            local available = 0
            for _, questID in ipairs(chapter.questIDs) do
                if hasDescription(questID) then available = available + 1 end
            end
            questStatus = "Quest text: " .. available .. "/" .. #chapter.questIDs
        end
        local hasSummary = not section.unavailable and not section.summaryUnavailable
        button.status:SetText((hasSummary and "Summary available" or "No summary") .. "\n" .. questStatus)
        button.label:SetTextColor(section.unavailable and 0.6 or 1, section.unavailable and 0.6 or 0.82, section.unavailable and 0.6 or 0.3)
        button:SetHeight(button.label:GetStringHeight() + button.status:GetStringHeight() + 20)
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
    refreshSearch()
    chapterScroll:UpdateScrollChildRect()
    chapterScroll:SetVerticalScroll(math.min(chapterScroll:GetVerticalScroll(), chapterScroll:GetVerticalScrollRange()))
    if #visibleSections > 0 then
        local restoredSection
        local bookmark = type(LoreCompanionCharacter) == "table" and LoreCompanionCharacter.midnight
        if restoreReading and type(bookmark) == "table" then
            local occurrence = 0
            for _, section in ipairs(visibleSections) do
                if not section.unavailable and section.title == bookmark.title then
                    occurrence = occurrence + 1
                    if occurrence == bookmark.occurrence then restoredSection = section; break end
                end
            end
        end
        restoreReading = false
        selectSection(selectionStillVisible and selectedSection or restoredSection or visibleSections[1],
            restoredSection and bookmark or nil)
    else
        selectedSection = nil
        selectedIndex = nil
        previousButton:Disable()
        nextButton:Disable()
        positionLabel:SetText("")
        storyTitle:SetText("Midnight")
        tabOffsets = { Summary = 0, Quests = 0 }
        renderTab()
    end
end

unfinishedCheckbox:SetScript("OnClick", refreshContent)
loreWindow:SetScript("OnHide", function()
    -- Require fresh consent after closing; another player/character must not
    -- inherit an open spoiler list. No preference is saved between sessions.
    unfinishedCheckbox:SetChecked(false)
    searchBox:SetText("")
    searchBox:ClearFocus()
end)

local progressEvents = CreateFrame("Frame")
progressEvents:RegisterEvent("QUEST_LOG_UPDATE")
local progressUpdatePending = false
progressEvents:SetScript("OnEvent", function()
    if progressUpdatePending or not loreWindow:IsShown() then return end
    progressUpdatePending = true
    C_Timer.After(0.2, function()
        progressUpdatePending = false
        if not loreWindow:IsShown() then return end
        refreshStory()
    end)
end)


addon.Window = {}
local scanWindow
local scanEditBox
local scanScroll
function addon.Window.ShowScan(text)
    -- Create this diagnostic window only when requested, then reuse it.
    if not scanWindow then
        scanWindow = CreateFrame("Frame", "LoreCompanionScanWindow", UIParent, "BasicFrameTemplate")
        scanWindow:SetSize(660, 460)
        scanWindow:SetPoint("CENTER")
        scanWindow:SetFrameStrata("DIALOG")
        scanWindow:SetClampedToScreen(true)
        scanWindow:EnableMouse(true)
        scanWindow.TitleText:SetText("Lore Companion — Scan results")
        table.insert(UISpecialFrames, "LoreCompanionScanWindow")

        local hint = scanWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        hint:SetPoint("TOPLEFT", 16, -34)
        hint:SetText("Text selected: Cmd+C (Mac) / Ctrl+C (Windows) to copy.")
        scanScroll = CreateFrame("ScrollFrame", nil, scanWindow, "UIPanelScrollFrameTemplate")
        scanScroll:SetPoint("TOPLEFT", 16, -60)
        scanScroll:SetPoint("BOTTOMRIGHT", -36, 48)
        scanEditBox = CreateFrame("EditBox", nil, scanScroll)
        scanEditBox:SetMultiLine(true)
        scanEditBox:SetAutoFocus(false)
        scanEditBox:SetFontObject("ChatFontNormal")
        scanEditBox:SetMaxLetters(0)
        scanEditBox:SetSize(608, 1)
        scanScroll:SetScrollChild(scanEditBox)
        scanEditBox:SetScript("OnEscapePressed", function() scanWindow:Hide() end)
        scanWindow:SetScript("OnHide", function() scanEditBox:ClearFocus() end)

        local selectButton = CreateFrame("Button", nil, scanWindow, "UIPanelButtonTemplate")
        selectButton:SetSize(110, 24)
        selectButton:SetPoint("BOTTOMLEFT", 16, 14)
        selectButton:SetText("Select all")
        selectButton:SetScript("OnClick", function()
            scanEditBox:SetFocus()
            scanEditBox:HighlightText()
        end)
    end
    scanWindow:Show()
    scanEditBox:SetText(text)
    scanEditBox:SetCursorPosition(0)
    scanEditBox:SetFocus()
    scanEditBox:HighlightText()
    scanScroll:UpdateScrollChildRect()
    scanScroll:SetVerticalScroll(0)
end

function addon.Window.Open()
    addon.Story.Refresh()
    activeTab = "Summary"
    selectedQuestIndex = 1
    restoreReading = true
    tabOffsets = { Summary = 0, Quests = 0 }
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
