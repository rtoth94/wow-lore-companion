-- Lore Companion's Lua entry point.

print("Lore Companion loaded.")

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

local availabilityNote = loreWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
availabilityNote:SetPoint("TOPLEFT", 20, -65)
availabilityNote:SetWidth(720)
availabilityNote:SetJustifyH("LEFT")
availabilityNote:SetText("Select a story section on the left. Only returned lore is shown by default.")

-- Navigation and story text have independent scroll positions.
local chapterHeading = loreWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
chapterHeading:SetPoint("TOPLEFT", 20, -100)
chapterHeading:SetText("Midnight")
local chapterScroll = CreateFrame("ScrollFrame", nil, loreWindow)
chapterScroll:SetPoint("TOPLEFT", 20, -132)
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
divider:SetPoint("TOPLEFT", 250, -100)
divider:SetPoint("BOTTOMLEFT", 250, 35)
divider:SetWidth(1)
local storyTitle = loreWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
storyTitle:SetPoint("TOPLEFT", 270, -100)
storyTitle:SetPoint("TOPRIGHT", -20, -100)
storyTitle:SetJustifyH("LEFT")

-- The scroll child grows with the text; the viewport stays inside the window.
local scrollFrame = CreateFrame("ScrollFrame", nil, loreWindow)
scrollFrame:SetPoint("TOPLEFT", 270, -145)
scrollFrame:SetPoint("BOTTOMRIGHT", -38, 35)
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
local scrollHint = loreWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
scrollHint:SetPoint("BOTTOM", 0, 12)
scrollHint:SetText("Mouse wheel / trackpad to scroll")

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
loreWindow:SetScript("OnSizeChanged", function(self, width)
    availabilityNote:SetWidth(width - 40)
end)

local function displayText(text)
    loreText:SetText(text)
    updateTextLayout()
    scrollFrame:SetVerticalScroll(0)
end

local campaignID = 270
local waitingForLore = false
local loreFrame = CreateFrame("Frame")
local campaignText = "Requesting Midnight campaign text..."
local loreSections = {}
local visibleSections = {}
local chapterButtons = {}
local selectedSection

local function selectSection(section)
    selectedSection = section
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

local function refreshContent()
    visibleSections = {}
    local returnedTitles = {}
    -- Navigate actual lore headings, not guessed chapter IDs. Duplicate headings
    -- remain separate entries and unheaded text is kept as a campaign overview.
    for _, section in ipairs(loreSections) do
        table.insert(visibleSections, section)
        returnedTitles[section.title] = true
    end
    if unfinishedCheckbox:GetChecked() then
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
        button.label:SetText(section.title)
        button.label:SetTextColor(section.unavailable and 0.6 or 1, section.unavailable and 0.6 or 0.82, section.unavailable and 0.6 or 0.3)
        button:SetHeight(math.max(36, button.label:GetStringHeight() + 16))
        button:ClearAllPoints()
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
    chapterScroll:SetVerticalScroll(0)
    if #visibleSections > 0 then
        selectSection(selectionStillVisible and selectedSection or visibleSections[1])
    else
        selectedSection = nil
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
    campaignText = "No campaign text was returned."
    refreshContent()
end)

SLASH_LORECOMPANION1 = "/lore"
SlashCmdList["LORECOMPANION"] = function()
    -- Show status in the window, then prepare the listener before requesting text.
    loreWindow:Show()
    loreSections = {}
    selectedSection = nil

    if not C_LoreText or type(C_LoreText.RequestLoreTextForCampaignID) ~= "function" then
        campaignText = "Campaign lore API is unavailable."
        refreshContent()
        return
    end

    campaignText = "Requesting Midnight campaign text..."
    refreshContent()
    waitingForLore = true
    C_LoreText.RequestLoreTextForCampaignID(campaignID)
end
