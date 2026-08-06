---
--- QuestUI.lua - Atlas quest UI frame and component creation
---
--- This file contains the quest UI frame creation and management for Atlas-CFM.
--- It handles quest window interface, quest display components, frame layout,
--- and provides the visual foundation for the Atlas quest browser system.
---
--- Features:
--- - Quest frame creation and styling
--- - Quest display components
--- - UI element initialization
--- - Frame positioning and layout
--- - Quest interface management
---
--- @compatible World of Warcraft 1.12
---

local _G = getfenv()
AtlasCFM = _G.AtlasCFM

local L = (AtlasCFM.Localization and AtlasCFM.Localization.UI) or {}

-- Constants
local FRAME_WIDTH = 220
local FRAME_HEIGHT = 570
--Right edge pinned to the main window's left edge, rather than the old "TOP, -556" which
--was measured from the centre and so drifted into the main frame whenever its width was
--not exactly what that number assumed. Flush by construction now.
local FRAME_POINT = { "TOPRIGHT", "AtlasCFMFrame", "TOPLEFT", -6, -30 }

-- Main Frame
--Named, where it was created with an empty string before. An unnamed frame cannot be
--reached by _G lookup, which is why the styling layer never touched this window and it
--kept the stock Blizzard look while everything around it went dark.
local frame = CreateFrame("Frame", "AtlasCFMQuestFrame", AtlasCFMFrame)
frame:SetWidth(FRAME_WIDTH)
frame:SetHeight(FRAME_HEIGHT)
frame:SetPoint(unpack(FRAME_POINT))
--frame:SetMovable(false)
frame:EnableMouse(true)
frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 5, right = 5, top = 5, bottom = 5 }
})
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function()
    AtlasCFM.StartMoving()
end)
frame:SetScript("OnDragStop", function()
    AtlasCFMFrame:StopMovingOrSizing()
    AtlasCFMFrame.isMoving = false
end)
frame:SetScript("OnMouseUp", function()
    AtlasCFMFrame:StopMovingOrSizing()
    AtlasCFMFrame.isMoving = false
end)
frame:Hide()

-- UI Elements Table
local UI_Main = { Frame = frame }

---
--- Helper function to create UI elements with common properties
--- @param type string The frame type to create (e.g., "Button", "Frame")
--- @param name string The name for the frame (can be empty string)
--- @param parent table The parent frame object
--- @param template string The template to use for the frame (optional)
--- @param width number The width of the element in pixels
--- @param height number The height of the element in pixels
--- @param point table The positioning point as {anchor, x, y} or {anchor, relativeTo, relativeAnchor, x, y}
--- @param text string Optional text to set on the element
--- @return table The created UI element
--- @usage local button = CreateElement("Button", "", parent, "UIPanelButtonTemplate", 100, 30, {"CENTER", 0, 0}, "Click Me")
---
local function CreateElement(type, name, parent, template, width, height, point, text)
    local element = CreateFrame(type, name, parent, template)
    element:SetWidth(width)
    element:SetHeight(height)
    element:SetPoint(unpack(point))
    if text then element:SetText(text) end
    return element
end

---
--- Helper function to create FontString objects with common properties
--- @param name string The name for the FontString (can be empty string)
--- @param parent table The parent frame object
--- @param font string The font template to use (e.g., "GameFontNormal")
--- @param point table The positioning point as {anchor, x, y} or {anchor, relativeTo, relativeAnchor, x, y}
--- @param width number The width of the text area in pixels
--- @param height number The height of the text area in pixels
--- @param justifyH string Horizontal justification ("LEFT", "CENTER", "RIGHT"), defaults to "CENTER"
--- @param justifyV string Vertical justification ("TOP", "MIDDLE", "BOTTOM"), defaults to "MIDDLE"
--- @return table The created FontString object
--- @usage local label = CreateText("", parent, "GameFontNormal", {"TOP", 0, -10}, 200, 20, "LEFT", "TOP")
---
local function CreateText(name, parent, font, point, width, height, justifyH, justifyV)
    local text = parent:CreateFontString(name, "ARTWORK", font)
    text:SetWidth(width)
    text:SetHeight(height)
    text:SetPoint(unpack(point))
    text:SetJustifyH(justifyH or "CENTER")
    text:SetJustifyV(justifyV or "MIDDLE")
    return text
end

---
--- Sets the frame level relative to parent when frame is shown
--- Ensures this frame appears above its parent frame in the UI stack
--- @usage frame:SetScript("OnShow", setFrameLevelOnShow)
---
local function setFrameLevelOnShow()
    this:SetFrameLevel(this:GetParent():GetFrameLevel() + 1)
end

-- Close Button
UI_Main.CloseButton = CreateElement("Button", "", frame, "UIPanelCloseButton", 27, 27, { "TOPLEFT", 10, -10 })
UI_Main.CloseButton:SetScript("OnClick", function() AtlasCFM.Quest.CloseQuestFrame() end)
UI_Main.CloseButton:SetScript("OnShow", setFrameLevelOnShow)

-- Story Button
UI_Main.StoryButton = CreateElement("Button", "", frame, "OptionsButtonTemplate", 70, 20, { "TOP", 0, -13 }, L["Story"])
UI_Main.StoryButton:SetScript("OnClick", function() AtlasCFM.Quest.OnStoryClick() end)
UI_Main.StoryButton:SetScript("OnShow", setFrameLevelOnShow)

-- Faction Buttons
--[[
	Both faction buttons now flank the Story button instead of sitting at the frame's outer
	corners, which is what pushed the Alliance crest into the close button.

	Three things were stacking up. The button was at TOPLEFT 25 while the close button
	spans 10-37, so they overlapped by twelve units before anything was drawn. Its texture
	was then 50x50 inside a 30x30 button -- ten units of overhang on every side -- and
	offset a further +8 to the right, putting the visible crest well over the close button.

	So: anchored to the Story button so the two crests sit either side of the label, texture
	brought down to 34 so a 30 button is roughly what it looks like, and the offset dropped
	to centre so the thing is where the button says it is.
]]
UI_Main.AllianceButton = CreateElement("Button", "", frame, nil, 30, 30, { "RIGHT", UI_Main.StoryButton, "LEFT", -8, 0 })
UI_Main.AllianceButton:SetNormalTexture("Interface\\TargetingFrame\\UI-PVP-Alliance")
--[[
	The crest is NOT centred inside UI-PVP-Alliance -- it sits in the upper-left of the
	file with a lot of empty space around it, which is why the original code used a 50x50
	texture in a 30x30 button nudged +8,-9: it was dragging the visible art back to the
	middle by brute force. Cropping to the art is the honest version of that, and it is
	what vanilla's own frames do with these two textures.

	isSkinned is set deliberately. AtlasOctoStyle's SkinButton applies E.TexCoords to any
	button it decides is an icon button, and these are children of a frame it now walks --
	so it was overwriting this crop immediately after it was set, which is why centring
	them appeared to do nothing at all. The flag makes it skip them.
]]
UI_Main.AllianceButton:GetNormalTexture():ClearAllPoints()
UI_Main.AllianceButton:GetNormalTexture():SetAllPoints(UI_Main.AllianceButton)
UI_Main.AllianceButton:GetNormalTexture():SetTexCoord(0.08, 0.58, 0.045, 0.55)
UI_Main.AllianceButton.isSkinned = true
UI_Main.AllianceButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
UI_Main.AllianceButton:SetScript("OnClick", function() AtlasCFM.Quest.OnAllianceClick() end)
UI_Main.AllianceButton:SetScript("OnShow", setFrameLevelOnShow)

--Mirror of the Alliance button above, on the other side of Story.
UI_Main.HordeButton = CreateElement("Button", "", frame, nil, 30, 30, { "LEFT", UI_Main.StoryButton, "RIGHT", 8, 0 })
--Mirror of the Alliance crest above, including the crop and the isSkinned flag.
UI_Main.HordeButton:SetNormalTexture("Interface\\TargetingFrame\\UI-PVP-Horde")
UI_Main.HordeButton:GetNormalTexture():ClearAllPoints()
UI_Main.HordeButton:GetNormalTexture():SetAllPoints(UI_Main.HordeButton)
UI_Main.HordeButton:GetNormalTexture():SetTexCoord(0.08, 0.58, 0.045, 0.55)
UI_Main.HordeButton.isSkinned = true
UI_Main.HordeButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
UI_Main.HordeButton:SetScript("OnClick", function() AtlasCFM.Quest.OnHordeClick() end)
UI_Main.HordeButton:SetScript("OnShow", setFrameLevelOnShow)

-- Quest Counter Text
UI_Main.QuestCounter = CreateText("", frame, "GameFontNormal", { "TOP", 0, -25 }, 60, 40)

-- Quest Buttons, Arrows, and Texts
UI_Main.QuestButtons = {}
for i = 1, AtlasCFM.QMAXQUESTS do
    local index = i
    local yOffset = -60 - (i - 1) * 20
    --Centred rather than TOPLEFT 15: the rows are 165 wide in a 220 frame, so a fixed left
    --margin of 15 left 40 on the right and the whole list sat visibly off to one side.
    local button = CreateElement("Button", "", frame, nil, 165, 20, { "TOP", 0, yOffset })
    button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", function() AtlasCFM.Quest.OnQuestClick(this:GetID(), arg1) end)
    button:SetScript("OnShow", setFrameLevelOnShow)

    local arrow = frame:CreateTexture("", "OVERLAY")
    arrow:SetWidth(15)
    arrow:SetHeight(15)
    arrow:SetPoint("TOPLEFT", button, 1, -2.5)
    arrow:SetTexture("Interface\\Glues\\Login\\UI-BackArrow")

    local text = CreateText("", button, "GameFontNormalSmall", { "TOPLEFT", 15, 0 }, 150, 20, "LEFT")

    UI_Main.QuestButtons[i] = { Button = button, Arrow = arrow, Text = text }
end

-- Register Events
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("CHAT_MSG_SYSTEM")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:SetBackdropBorderColor(0.80, 0.60, 0.25, 1)
frame:SetScript("OnEvent", function()
    -- Debug print to verify script handler execution
    -- if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("Atlas-CFM: Frame OnEvent Triggered: " .. (event or "nil")) end
    AtlasCFM.Quest.OnEvent(event, arg1, arg2, arg3)
end)
frame:SetScript("OnShow", function() AtlasCFM.Quest.OnQuestFrameShow() end)

-- Check Completed Quests Button
UI_Main.CheckCompletedQuestsButton = CreateElement("Button", "", frame, "OptionsButtonTemplate", 220, 20,
    { "BOTTOM", 0, 10 }, L["Check Completed Quests"])
UI_Main.CheckCompletedQuestsButton:SetScript("OnClick", function()
    SendChatMessage(".queststatus")
    this:Hide()
end)
UI_Main.CheckCompletedQuestsButton:SetScript("OnShow", setFrameLevelOnShow)

-- Assign UI table to the global namespace
AtlasCFM.Quest.UI_Main = UI_Main
