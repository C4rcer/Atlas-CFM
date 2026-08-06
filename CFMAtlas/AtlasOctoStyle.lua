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
local ipairs = ipairs
local find = string.find

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

	--Discriminated on whether the button HAS a label, not on whether that label currently
	--says anything.
	--
	--GetText() was the earlier test and it is wrong for anything whose caption is filled in
	--after this runs -- which is most of the loot panel, built when a table is first
	--browsed. Those buttons read as empty at skin time, took the icon branch, and ended up
	--with a backdrop UNDER their original red art instead of having it stripped. That is
	--the "half skinned" look: new backdrop, old texture still on top.
	--
	--GetFontString() answers the question that actually matters, because a labelled button
	--owns its FontString from creation whether or not any text has been set on it yet.
	local fontString = frame.GetFontString and frame:GetFontString()
	if fontString then
		S:HandleButton(frame)
		return
	end

	local normal = frame.GetNormalTexture and frame:GetNormalTexture()
	if normal and normal.SetTexCoord then
		normal:SetTexCoord(unpack(E.TexCoords))
	end

	E:CreateBackdrop(frame, "Default", true)
	E:StyleButton(frame)

	--Only claimed as finished when there was actually an icon to keep. A button with
	--neither a label nor a texture is one this pass could not classify, so it is left
	--unflagged and the next pass -- on the next show -- gets another go at it once the
	--addon has finished building it.
	if normal then frame.isSkinned = true end
end

--AtlasCFMFrame is handled separately by StyleMainWindow below, NOT here, and it must never
--go in this list: the handler for these calls E:StripTextures, which does
--`region:SetTexture(nil)` on every texture region of the frame -- and the map is one of
--them. It would erase the map outright.
local windows = {
	"AtlasCFMLootItemsFrame", "AtlasCFMLootPanel", "AtlasCFMOptionsFrame"
}

--The quest windows, newly named in CFMQuest/QuestUI.lua and QuestUIinAtlas.lua.
--
--Kept apart from `windows` because these get the template WITHOUT E:StripTextures. They
--carry their own artwork -- the faction crest among it -- and stripping would take that
--with the Blizzard border. Whether the crest should stay is a separate question from
--whether the frame matches; this fixes the frame and leaves the art alone.
local plainWindows = {
	"AtlasCFMQuestFrame", "AtlasCFMQuestInAtlasFrame"
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
	"AtlasCFMCraftCollapseAll", "AtlasCFMLootFilterButton",
	"AtlasCFMLootItemsFrame_BACK", "AtlasCFMLootItemsFrame_Back",
	"AtlasCFMLootPanel_WorldEvents", "AtlasCFMLootPanel_Sets",
	"AtlasCFMLootPanel_Reputation", "AtlasCFMLootPanel_PvP",
	"AtlasCFMLootPanel_Crafting", "AtlasCFMLootPanel_Dungeons",
	"AtlasCFMLootPanel_Instances"
}

--[[
	Page-turn arrows, which need their own handler rather than the icon branch of
	SkinButton.

	All of these carry Blizzard's spellbook page art -- UI-SpellbookIcon-NextPage-Up and
	friends, applied by AtlasCFMLoot_ApplyNavigationButtonTemplate in CFMLoot/LootUI.lua.
	Treated as ordinary icon buttons they keep that gold art and merely gain a backdrop
	behind it, which is why they stayed obviously Blizzard while everything around them
	went dark. S:HandleNextPrevButton REPLACES the art with OctoUI's own arrow, which is
	the same treatment TradeSkill.lua gives TradeSkillDecrementButton.

	The names are built as `frame:GetName() .. "_PREV"` / `"_NEXT"` at LootUI.lua:970-988.
]]
local nextPrevButtons = {
	"AtlasCFMLootItemsFrame_PREV", "AtlasCFMLootItemsFrame_NEXT",
	"AtlasCFMLootSearchOptionsButton"
}

--Buttons that open something below them rather than paging sideways, so they get the same
--square-button art pointing DOWN. HandleNextPrevButton's second argument is useVertical;
--the third is inferred from the name and only matters for prev/left/decrement, none of
--which these are, so `true` alone gives a down arrow.
--
--QuickLooks carried a bespoke icon that matched nothing else in the addon. Replacing it
--rather than putting a backdrop behind it is the point: this fork is meant to read as a
--sister addon to OctoUI, and one widget keeping its own art is what makes an interface
--look assembled rather than designed.
local downButtons = {
	"AtlasCFMLootQuickLooksButton"
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

--[[
	Everything a name list cannot reach.

	Most of this UI's buttons are created as CreateFrame("Button", nil, parent, ...) --
	no global name at all -- so _G[name] finds nothing and Apply skips them in silence.
	That is why the bottom bar stayed Blizzard-red while the named buttons above went dark:
	not an error, just a lookup that could never succeed. Walking GetChildren() is the only
	thing that reaches them.

	SkinButton already refuses anything carrying a texture instead of a label, so an icon
	button walked into here keeps its art and gets a backdrop rather than being stripped
	to an empty box.

	Loot rows are excluded by name. They carry their own icon and text and look wrong inside
	a button backdrop -- StyleRows gives them a texcoord trim and nothing else. The pattern
	requires a DIGIT after the prefix so AtlasCFMLootItemsFrame, which shares the first
	sixteen characters with AtlasCFMLootItem1, is still descended into.
]]
local ROW_PATTERNS = {
	"^AtlasCFMLootItem%d", "^AtlasCFMLootMenuItem%d", "^AtlasCFMLootContainerItem%d"
}

local function IsRowWidget(name)
	if not name then return false end
	for i = 1, getn(ROW_PATTERNS) do
		if find(name, ROW_PATTERNS[i]) then return true end
	end
	return false
end

local function SkinChildren(frame, depth)
	if not frame or not frame.GetChildren then return end

	local kids = {frame:GetChildren()}
	for i = 1, getn(kids) do
		local child = kids[i]
		if child and child.GetObjectType then
			local objectType = child:GetObjectType()
			local name = child.GetName and child:GetName()

			if not IsRowWidget(name) then
				if objectType == "Button" then
					pcall(SkinButton, child)
				elseif objectType == "CheckButton" then
					pcall(S.HandleCheckBox, S, child)
				elseif objectType == "EditBox" then
					pcall(S.HandleEditBox, S, child)
				end
			end

			--Three deep covers button rows nested in container frames without walking the
			--whole tree on every show.
			if depth < 3 then SkinChildren(child, depth + 1) end
		end
	end
end

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

	Apply(plainWindows, function(frame)
		if frame:GetObjectType() ~= "Frame" or frame.template then return end
		E:SetTemplate(frame, "Transparent")
	end)

	Apply(closeButtons, function(frame) S:HandleCloseButton(frame) end)

	--Before the generic pass and before the child walk, and flagged afterwards. Both of
	--those would otherwise classify an arrow as an icon button and put E.TexCoords over
	--the art this just replaced -- the same way the quest frame's faction crests were
	--being overwritten immediately after being set.
	Apply(nextPrevButtons, function(frame)
		if frame.isSkinned then return end
		S:HandleNextPrevButton(frame)
		frame.isSkinned = true
	end)

	Apply(downButtons, function(frame)
		if frame.isSkinned then return end
		S:HandleNextPrevButton(frame, true)
		frame.isSkinned = true
	end)

	Apply(buttons, SkinButton)

	--After the name list, not instead of it: the named lookups are exact and cheap, and
	--this only has to catch what they cannot see. Running it second also means anything
	--already skinned short-circuits on its own isSkinned/template flag.
	for _, container in ipairs({"AtlasCFMFrame", "AtlasCFMLootPanel", "AtlasCFMLootItemsFrame", "AtlasCFMOptionsFrame"}) do
		local frame = _G[container]
		if frame then SkinChildren(frame, 1) end
	end

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
