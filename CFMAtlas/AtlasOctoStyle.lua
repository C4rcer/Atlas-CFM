--[[
	OctoUI styling for Atlas-OctoUI.

	This replaces the pfUI integration layer that upstream shipped. That one was optional
	and detected its host; this fork exists to sit alongside OctoUI, so this is not
	optional and does not pretend to be. It still no-ops cleanly if OctoUI is absent,
	because an addon that raises on load when a dependency is missing is worse than one
	that merely looks plain.

	Every widget here is reachable by name. Where upstream created something with a nil
	name -- the search cluster, the main window's buttons, the options window's buttons --
	the fork gave it a name at the creation site rather than trying to find it from
	outside. That is the whole reason for forking: an external skin cannot reach an
	anonymous frame at all, and the bottom bar stayed Blizzard-grey for exactly that
	reason while it was being attempted from OctoUI.

	Loaded last, so every frame it touches already exists.
]]

--OctoUI's engine table is still called ElvUI internally; see Init.lua in that repo for
--why. OctoUI is aliased to the same table, so either works -- prefer the alias, and fall
--back so this keeps working if the alias is ever dropped.
local engine = OctoUI or ElvUI
local E = engine and engine[1]
local S = E and E.GetModule and E:GetModule("Skins", true)

--No OctoUI: leave every frame exactly as upstream drew it.
if not (E and S) then return end

local _G = _G
local getn = table.getn
local pcall = pcall
local unpack = unpack

--Collected and reported once rather than raising. A widget that cannot be styled should
--cost that widget, not every widget after it in the list.
local failures

local function Apply(names, handler)
	for i = 1, getn(names) do
		local name = names[i]
		local frame = _G[name]

		if frame and frame.GetObjectType then
			if not pcall(handler, frame) then
				failures = failures and (failures..", "..name) or name
			end
		end
	end
end

--A button carrying a texture instead of a label must not be stripped: S:HandleButton
--calls E:StripTextures, which takes the icon with it and leaves an empty box.
local function SkinButton(frame)
	if frame:GetObjectType() ~= "Button" or frame.template or frame.isSkinned then return end

	local text = frame.GetText and frame:GetText()
	if text and text ~= "" then
		S:HandleButton(frame)
		return
	end

	local normal = frame.GetNormalTexture and frame:GetNormalTexture()
	if normal and normal.SetTexCoord then
		normal:SetTexCoord(unpack(E.TexCoords))
	end

	E:CreateBackdrop(frame, "Default", true)
	E:StyleButton(frame)
	frame.isSkinned = true
end

--AtlasCFMFrame is handled separately by StyleMainWindow below, NOT here, and it must never
--go in this list: the handler for these calls E:StripTextures, which does
--`region:SetTexture(nil)` on every texture region of the frame -- and the map is one of
--them. It would erase the map outright.
local windows = {
	"AtlasCFMLootItemsFrame", "AtlasCFMLootPanel", "AtlasCFMOptionsFrame"
}

local edges = {
	"AtlasCFMFrameTop", "AtlasCFMFrameBottom", "AtlasCFMFrameBottom2",
	"AtlasCFMFrameLeft", "AtlasCFMFrameRight"
}

local closeButtons = {
	"AtlasCFMCloseButton", "AtlasCFMLootItemsFrame_CloseButton"
}

local buttons = {
	--main window, named by this fork
	"AtlasCFMSearchButton", "AtlasCFMClearButton", "AtlasCFMOptionsButton",
	"AtlasCFMQuestsToggleButton", "AtlasCFMShowPanelButton",
	--loot search cluster, named by this fork
	"AtlasCFMLootSearchButton", "AtlasCFMLootSearchOptionsButton", "AtlasCFMLootClearButton",
	"AtlasCFMLootLastResultButton", "AtlasCFMLootWishListButton",
	--options window, named by this fork
	"AtlasCFMOptionsResetPositionButton", "AtlasCFMOptionsDefaultSettingsButton",
	"AtlasCFMOptionsDoneButton",
	--already named upstream
	"AtlasCFMSwitchButton", "AtlasCFMLockButton", "AtlasCFMInstanceTypeButton",
	"AtlasCFMCraftCollapseAll", "AtlasCFMLootFilterButton", "AtlasCFMLootQuickLooksButton",
	"AtlasCFMLootItemsFrame_BACK", "AtlasCFMLootItemsFrame_Back",
	"AtlasCFMLootItemsFrame_NEXT", "AtlasCFMLootItemsFrame_PREV",
	"AtlasCFMLootPanel_WorldEvents", "AtlasCFMLootPanel_Sets",
	"AtlasCFMLootPanel_Reputation", "AtlasCFMLootPanel_PvP",
	"AtlasCFMLootPanel_Crafting", "AtlasCFMLootPanel_Dungeons",
	"AtlasCFMLootPanel_Instances"
}

--AtlasCFMNoticeBox is excluded: it is the "report it at" URL field, and a backdrop on it
--overlaps its own label.
local editBoxes = {
	"AtlasCFMSearchEditBox", "AtlasCFMLootSearchBox",
	"AtlasCFMCraftSearchBox", "AtlasCFMTradeSkillSearchBox"
}

local checkBoxes = {
	"AtlasCFMCraftCategories", "AtlasCFMCraftHaveMaterials", "AtlasCFMCraftImprovesSkill",
	"AtlasCFMCraftShowSkillLevels", "AtlasCFMTradeSkillHaveMaterials",
	"AtlasCFMTradeSkillImprovesSkill", "AtlasCFMTradeSkillShowLevels",
	"AtlasCFMOptionReagent"
}

local sliders = { "AtlasCFMOptionReagentRowsSlider" }

--Icons only. The rows carry their own icon and text and look wrong inside a button
--backdrop, so they get a texcoord trim and nothing else.
local function StyleRows(prefix)
	local i = 1
	while true do
		local icon = _G[prefix..i.."_Icon"]
		if not icon then break end

		if icon.SetTexCoord then icon:SetTexCoord(unpack(E.TexCoords)) end

		i = i + 1
		if i > 100 then break end
	end
end

--Re-run on show: loot rows and the paging buttons are built as tables are browsed. The
--S:Handle* helpers set isSkinned/template, so repeating is free.
function AtlasCFM.OctoStyleDynamic()
	Apply(windows, function(frame)
		if frame:GetObjectType() ~= "Frame" or frame.template then return end

		E:StripTextures(frame)
		E:SetTemplate(frame, "Transparent")
	end)

	Apply(closeButtons, function(frame) S:HandleCloseButton(frame) end)
	Apply(buttons, SkinButton)

	StyleRows("AtlasCFMLootItem")
	StyleRows("AtlasCFMLootMenuItem")
	StyleRows("AtlasCFMLootContainerItem")
end

--The main window, which needs care the others do not.
--
--First attempt stripped the five edge frames and gave the window no backdrop at all, on
--the reasoning that a backdrop on AtlasCFMFrame covers the map. Both halves were true and
--the result was a window with no frame drawn: map, text and buttons floating over the
--game world. Removing the art is only half a job.
--
--So: give AtlasCFMFrame the backdrop, and lift the map out of its way rather than going
--without. The map is created as a BACKGROUND texture and E:SetTemplate's backdrop also
--draws at BACKGROUND -- same layer, so which wins is not defined and the map lost. Moving
--it to ARTWORK puts it unambiguously above.
--
--And no E:StripTextures on this frame: it does region:SetTexture(nil) on every texture
--the frame owns, and the map is one of them.
local function StyleMainWindow()
	local main = _G["AtlasCFMFrame"]
	if not main or main.template then return end

	local map = _G["AtlasCFMMap"]
	if map and map.SetDrawLayer then
		map:SetDrawLayer("ARTWORK")
	end

	E:SetTemplate(main, "Transparent")
end

local function StyleAll()
	--Edges are the window's border art, not containers. Stripping them is what removes
	--the Blizzard frame; the backdrop that replaces it comes from StyleMainWindow.
	Apply(edges, function(frame) E:StripTextures(frame) end)
	StyleMainWindow()

	AtlasCFM.OctoStyleDynamic()

	Apply(editBoxes, function(frame) S:HandleEditBox(frame) end)
	Apply(checkBoxes, function(frame) S:HandleCheckBox(frame) end)
	Apply(sliders, function(frame) S:HandleSliderFrame(frame) end)

	if failures then
		E:Print("|cffff9900Atlas-OctoUI|r could not style: "..failures)
		failures = nil
	end
end

--PLAYER_LOGIN rather than ADDON_LOADED: parts of this UI are built from other addons'
--load events, and by PLAYER_LOGIN everything that exists at startup exists.
local styler = CreateFrame("Frame", "AtlasCFMOctoStyler")
styler:RegisterEvent("PLAYER_LOGIN")
styler:SetScript("OnEvent", function()
	StyleAll()

	local main = _G["AtlasCFMFrame"]
	if main then
		local original = main:GetScript("OnShow")
		main:SetScript("OnShow", function()
			if original then original() end
			AtlasCFM.OctoStyleDynamic()
		end)
	end
end)
