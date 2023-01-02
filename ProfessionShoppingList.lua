-- Initialise some stuff
local f = CreateFrame("Frame")
local ScrollingTable = LibStub("ScrollingTable")
if not C_TradeSkillUI then UIParentLoadAddOn("C_TradeSkillUI") end -- Load the TradeSkillUI to prevent stuff from being wonky

-- API Events
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("BAG_UPDATE")
f:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
f:RegisterEvent("TRADE_SKILL_SHOW")
f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
f:RegisterEvent("SPELL_DATA_LOAD_RESULT")
f:RegisterEvent("MERCHANT_SHOW")

-- Create SavedVariables
function pslInitialise()
	-- Declare some variables
	if not userSettings then userSettings = {} end
	if not recipesTracked then recipesTracked = {} end
	if not recipeLinks then recipeLinks = {} end
	if not reagentsTracked then reagentsTracked = {} end
	if not recipeLibrary then recipeLibrary = {} end
	if not reagentTiers then reagentTiers = {} end

	-- Enable default user settings
	if userSettings["hide"] == nil then userSettings["hide"] = false end
	if userSettings["removeCraft"] == nil then userSettings["removeCraft"] = true end
	if userSettings["showRemaining"] == nil then userSettings["showRemaining"] = false end
	if userSettings["showTooltip"] == nil then userSettings["showTooltip"] = true end
	if userSettings["recipeRows"] == nil then userSettings["recipeRows"] = 15 end
	if userSettings["reagentRows"] == nil then userSettings["reagentRows"] = 15 end
	if userSettings["recipeWidth"] == nil then userSettings["recipeWidth"] = 150 end
	if userSettings["recipeNoWidth"] == nil then userSettings["recipeNoWidth"] = 30 end
	if userSettings["reagentWidth"] == nil then userSettings["reagentWidth"] = 150 end
	if userSettings["reagentNoWidth"] == nil then userSettings["reagentNoWidth"] = 50 end
	if userSettings["vendorAll"] == nil then userSettings["vendorAll"] = true end
	if userSettings["reagentQuality"] == nil then userSettings["reagentQuality"] = 1 end
	if userSettings["closeWhenDone"] == nil then userSettings["closeWhenDone"] = false end
	if userSettings["showKnowledgeNotPerks"] == nil then userSettings["showKnowledgeNotPerks"] = false end
end

--Create tracking windows
function pslCreateTrackingWindows()
	local cols = {}

	-- Column formatting, Reagents
	cols[1] = {
		["name"] = "Reagents",
		["width"] = userSettings["reagentWidth"],
		["align"] = "LEFT",
		["color"] = {
			["r"] = 1.0,
			["g"] = 1.0,
			["b"] = 1.0,
			["a"] = 1.0
		},
		["colorargs"] = nil,
		["bgcolor"] = {
			["r"] = 0.0,
			["g"] = 0.0,
			["b"] = 0.0,
			["a"] = 0.0
		},
		["defaultsort"] = "dsc",
		["sort"] = "dsc",
		["DoCellUpdate"] = nil,
	}
	
	-- Column formatting, Amount
	cols[2] = {
		["name"] = "#",
		["width"] = userSettings["reagentNoWidth"],
		["align"] = "RIGHT",
		["color"] = {
			["r"] = 1.0,
			["g"] = 1.0,
			["b"] = 1.0,
			["a"] = 1.0
		},
		["bgcolor"] = {
			["r"] = 0.0,
			["g"] = 0.0,
			["b"] = 0.0,
			["a"] = 0.0
		},
		["defaultsort"] = "dsc",
		["sort"] = "dsc",
		["DoCellUpdate"] = nil,
	}

	-- Reagent tracking
	if not pslFrame1 then
		-- Frame
		pslFrame1 = CreateFrame("Frame", "pslTrackingWindow1", UIParent, "BackdropTemplateMixin" and "BackdropTemplate")
		pslFrame1:SetSize(255, 270)
		pslFrame1:SetPoint("CENTER")
		pslFrame1:EnableMouse(true)
		pslFrame1:SetMovable(true)
		pslFrame1:Hide()

		-- Close button
		local close = CreateFrame("Button", "pslCloseButtonName1", pslFrame1, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", pslFrame1, "TOPRIGHT", 1, -2)
		close:SetScript("OnClick", function() pslFrame1:Hide() end)

		-- Create tracking window
		table1 = ScrollingTable:CreateST(cols, 50, nil, nil, pslFrame1)
	end

	table1:SetDisplayRows(userSettings["reagentRows"], 15)
	table1:SetDisplayCols(cols)
	pslFrame1:SetSize(userSettings["reagentWidth"]+userSettings["reagentNoWidth"]+30, userSettings["reagentRows"]*15+45)

	-- Column formatting, Recipes
	local cols = {}
	cols[1] = {
		["name"] = "Recipes",
		["width"] = userSettings["recipeWidth"],
		["align"] = "LEFT",
		["color"] = {
			["r"] = 1.0,
			["g"] = 1.0,
			["b"] = 1.0,
			["a"] = 1.0
		},
		["colorargs"] = nil,
		["bgcolor"] = {
			["r"] = 0.0,
			["g"] = 0.0,
			["b"] = 0.0,
			["a"] = 0.0
		},
		["defaultsort"] = "dsc",
		["sort"] = "dsc",
		["DoCellUpdate"] = nil,
	}
	
	-- Column formatting, Tracked
	cols[2] = {
		["name"] = "#",
		["width"] = userSettings["recipeNoWidth"],
		["align"] = "RIGHT",
		["color"] = {
			["r"] = 1.0,
			["g"] = 1.0,
			["b"] = 1.0,
			["a"] = 1.0
		},
		["bgcolor"] = {
			["r"] = 0.0,
			["g"] = 0.0,
			["b"] = 0.0,
			["a"] = 0.0
		},
		["defaultsort"] = "dsc",
		["sort"] = "dsc",
		["DoCellUpdate"] = nil,
	}

	-- Recipe tracking
	if not pslFrame2 then
		-- Frame
		pslFrame2 = CreateFrame("Frame", "pslTrackingWindow2", UIParent, "BackdropTemplateMixin" and "BackdropTemplate")
		pslFrame2:SetSize(230, 270)
		pslFrame2:SetPoint("CENTER")
		pslFrame2:EnableMouse(true)
		pslFrame2:SetMovable(true)
		pslFrame2:Hide()
		pslFrame2:SetScript("OnDragStart", function(self, button) self:StartMoving() end)
		pslFrame2:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

		-- Close button
		local close = CreateFrame("Button", "pslCloseButtonName2", pslFrame2, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", pslFrame2, "TOPRIGHT", 1, -2)
		close:SetScript("OnClick", function() pslFrame2:Hide() end)

		-- Create tracking window
		table2 = ScrollingTable:CreateST(cols, 50, nil, nil, pslFrame2)
	end

	table2:SetDisplayRows(userSettings["recipeRows"], 15)
	table2:SetDisplayCols(cols)
	pslFrame2:SetSize(userSettings["recipeWidth"]+userSettings["recipeNoWidth"]+30, userSettings["recipeRows"]*15+45)
end

-- Update numbers
function pslReagents()
	-- Update recipes tracked
	local data = {};
	for recipeID, no in pairs(recipesTracked) do
		table.insert(data, {recipeLinks[recipeID], no})
		table2:SetData(data, true)
	end
	table2:SetData(data, true)
	
	-- Recalculate reagents
	reagentsTracked = {}

	for recipeID, no in pairs(recipesTracked) do
		-- Get reagent info
		local reagentsTable = C_TradeSkillUI.GetRecipeSchematic(recipeID, false).reagentSlotSchematics

		-- For every reagent, if not optional or finishing, do
		for numReagent, reagentInfo in pairs(reagentsTable) do
			if reagentInfo.reagentType == 1 then
				-- Get info
				local reagentID1 = reagentInfo.reagents[1].itemID
				local reagentID2 = 0
				local reagentID3 = 0
				local reagentAmount = reagentInfo.quantityRequired

				-- Get quality tier 2 info
				if reagentInfo.reagents[2] then
					reagentID2 = reagentInfo.reagents[2].itemID
				end

				-- Get quality tier 3 info
				if reagentInfo.reagents[3] then
					reagentID3 = reagentInfo.reagents[3].itemID
				end

				-- Slap all different quality items in there
				if reagentsTracked[reagentID1] == nil then reagentsTracked[reagentID1] = {one = 0, two = 0, three = 0, amount = 0} end
				reagentsTracked[reagentID1].one = reagentID1
				reagentsTracked[reagentID1].two = reagentID2
				reagentsTracked[reagentID1].three = reagentID3

				-- Add them to reagentTiers because I can't think of a non-clunky way to get the base tier for subreagent calculations
				-- Might rework the entire tier stuff, but this is what it is for now
				if reagentID2 ~= 0 then reagentTiers[reagentID2] = reagentID1 end
				if reagentID3 ~= 0 then reagentTiers[reagentID3] = reagentID1 end

				-- Do maths
				reagentsTracked[reagentID1].amount = reagentsTracked[reagentID1].amount + reagentAmount * no
			end
		end
	end

	-- Update reagents tracked
	local data = {}

	for reagentBase, reagentInfo in pairs(reagentsTracked) do
		local function getInfo()
			-- Get info
			local itemName, itemLink
			if userSettings["reagentQuality"] == 1 then 
				itemName, itemLink = GetItemInfo(reagentInfo.one)
			elseif userSettings["reagentQuality"] == 2 then
				if reagentInfo.two ~= 0 then
					itemName, itemLink = GetItemInfo(reagentInfo.two)
				else
					itemName, itemLink = GetItemInfo(reagentInfo.one)
				end
			elseif userSettings["reagentQuality"] == 3 then
				if reagentInfo.three ~= 0 then
					itemName, itemLink = GetItemInfo(reagentInfo.three)
				elseif reagentInfo.two ~= 0 then
					itemName, itemLink = GetItemInfo(reagentInfo.two)
				else
					itemName, itemLink = GetItemInfo(reagentInfo.one)
				end
			end

			-- Try again if error
			if itemName == nil or itemLink == nil then
				RunNextFrame(getInfo)
				do return end
			end

			-- Calculate amount based on user setting for reagent quality
			local reagentAmountNeed = reagentInfo.amount
			local reagentAmountHave
			if userSettings["reagentQuality"] == 1 then
				reagentAmountHave = GetItemCount(reagentInfo.three, true, false, true) + GetItemCount(reagentInfo.two, true, false, true) + GetItemCount(reagentInfo.one, true, false, true)
			elseif userSettings["reagentQuality"] == 2 and reagentInfo.two ~= 0 then
				reagentAmountHave = GetItemCount(reagentInfo.three, true, false, true) + GetItemCount(reagentInfo.two, true, false, true)
			elseif userSettings["reagentQuality"] == 2 and reagentInfo.two == 0 then
				reagentAmountHave = GetItemCount(reagentInfo.three, true, false, true) + GetItemCount(reagentInfo.two, true, false, true) + GetItemCount(reagentInfo.one, true, false, true)
			elseif userSettings["reagentQuality"] == 3 and reagentInfo.three ~= 0 then
				reagentAmountHave = GetItemCount(reagentInfo.three, true, false, true)
			elseif userSettings["reagentQuality"] == 3 and reagentInfo.three == 0 then
				reagentAmountHave = GetItemCount(reagentInfo.three, true, false, true) + GetItemCount(reagentInfo.two, true, false, true) + GetItemCount(reagentInfo.one, true, false, true)
			end
			
			-- Push the info to the windows
			if userSettings["showRemaining"] == false then
				table.insert(data, {itemLink, reagentAmountHave.."/"..reagentAmountNeed})
			else
				table.insert(data, {itemLink, math.max(0,reagentAmountNeed-reagentAmountHave)})
			end

			table1:SetData(data, true)
		end
		getInfo()
	end
	table1:SetData(data, true)

	-- Check if the Untrack button should be enabled
	if not recipesTracked[pslSelectedRecipeID] then removeCraftListButton:Disable()
	elseif recipesTracked[pslSelectedRecipeID] == 0 then removeCraftListButton:Disable()
	else removeCraftListButton:Enable()
	end
end

-- Create buttons... and other UI elements, but I'm not renaming this function
function pslCreateButtons()
	-- Hide and disable existing tracking button
	ProfessionsFrame.CraftingPage.SchematicForm.TrackRecipeCheckBox:SetAlpha(0)
	ProfessionsFrame.CraftingPage.SchematicForm.TrackRecipeCheckBox:EnableMouse(false)

	-- Create the "Track" button
	if not addCraftListButton then
		addCraftListButton = CreateFrame("Button", nil, ProfessionsFrame.CraftingPage, "UIPanelButtonTemplate")
		addCraftListButton:SetText("Track")
		addCraftListButton:SetWidth(60)
		addCraftListButton:SetPoint("TOPRIGHT", ProfessionsFrame.CraftingPage.SchematicForm, "TOPRIGHT", -9, -10)
		addCraftListButton:SetFrameStrata("HIGH")
	end

	-- Create the "Untrack" button
	if not removeCraftListButton then
		removeCraftListButton = CreateFrame("Button", nil, ProfessionsFrame.CraftingPage, "UIPanelButtonTemplate")
		removeCraftListButton:SetText("Untrack")
		removeCraftListButton:SetWidth(70)
		removeCraftListButton:SetPoint("TOPRIGHT", addCraftListButton, "TOPLEFT", -4, 0)
		removeCraftListButton:SetFrameStrata("HIGH")
	end

	-- Make the "Track" button actually do the thing
	addCraftListButton:SetScript("OnClick", function()
		-- Get selected recipe ID
		local recipeID = pslSelectedRecipeID
		local recipeType = pslRecipeType

		-- Track recipe
		if not recipesTracked[recipeID] then recipesTracked[recipeID] = 0 end
		recipesTracked[recipeID] = recipesTracked[recipeID] + 1

		-- Add recipe link for crafted items
		if recipeType == 1 then recipeLinks[recipeID] = C_TradeSkillUI.GetRecipeOutputItemData(recipeID).hyperlink
		-- Add recipe "link" for enchants
		elseif recipeType == 3 then recipeLinks[recipeID] = C_TradeSkillUI.GetRecipeSchematic(recipeID,false).name
		end

		-- Show windows
		pslFrame1:Show()
		pslFrame2:Show()

		-- Update numbers
		pslReagents()
	end)

	-- Make the "Untrack" button actually do the thing
	removeCraftListButton:SetScript("OnClick", function()
		-- Get selected recipe ID
		local recipeID = pslSelectedRecipeID

		-- Show windows
		pslFrame1:Show()
		pslFrame2:Show()

		-- Untrack recipe
		if recipesTracked[recipeID] then recipesTracked[recipeID] = recipesTracked[recipeID] - 1 end

		-- Set numbers to nil if it doesn't exist anymore
		if recipesTracked[recipeID] == 0 then
			recipesTracked[recipeID] = nil
			recipeLinks[recipeID] = nil
		end

		-- Update numbers
		pslReagents()
	end)

	-- Create Chef's Hat button
	if not chefsHatButton then
		chefsHatButton = CreateFrame("Button", "ChefsHatButton", ProfessionsFrame, "UIPanelButtonTemplate")
	
		chefsHatButton:SetWidth(40)
		chefsHatButton:SetHeight(40)
		chefsHatButton:SetNormalTexture(236571)
		chefsHatButton:SetPoint("BOTTOMRIGHT", ProfessionsFrame.CraftingPage.SchematicForm, "BOTTOMRIGHT", -5, 4)
		chefsHatButton:SetFrameStrata("HIGH")
		chefsHatButton:SetScript("OnClick", function() UseToyByName("Chef's Hat") end)
	end

	-- Create Knowledge Point tracker
	if not knowledgePointTracker then
		-- Bar wrapper
		knowledgePointTracker = CreateFrame("Frame", "KnowledgePointTracker", ProfessionsFrame.SpecPage, "TooltipBackdropTemplate")
		knowledgePointTracker:SetBackdropBorderColor(0.5, 0.5, 0.5)
		knowledgePointTracker:SetSize(470,25)
		knowledgePointTracker:SetPoint("TOPRIGHT", ProfessionsFrame.SpecPage, "TOPRIGHT", -5, -24)
		knowledgePointTracker:SetFrameStrata("HIGH")
		knowledgePointTracker:SetScript("OnLeave", function() knowledgePointTooltip:Hide() end)

		-- Bar
		knowledgePointTracker.Bar = CreateFrame("StatusBar", nil, knowledgePointTracker)
		knowledgePointTracker.Bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
		knowledgePointTracker.Bar:SetStatusBarColor(1, .5, 0)
		knowledgePointTracker.Bar:SetPoint("TOPLEFT", 5, -5)
		knowledgePointTracker.Bar:SetPoint("BOTTOMRIGHT", -5, 5)
		Mixin(knowledgePointTracker.Bar, SmoothStatusBarMixin)

		-- Text
		knowledgePointTracker.Text = knowledgePointTracker.Bar:CreateFontString("OVERLAY", nil, "GameFontNormal")
		knowledgePointTracker.Text:SetPoint("CENTER", knowledgePointTracker, "CENTER", 0, 0)
		knowledgePointTracker.Text:SetTextColor(1, 1, 1, 1)
		knowledgePointTracker.Text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	end

	-- Create Knowledge Point tracker tooltip
	if not knowledgePointTooltip then
		knowledgePointTooltip = CreateFrame("Frame", nil, knowledgePointTracker, "BackdropTemplate")
		knowledgePointTooltip:SetPoint("CENTER")
		knowledgePointTooltip:SetPoint("TOP", knowledgePointTracker, "BOTTOM", 0, 0)
		knowledgePointTooltip:SetFrameStrata("TOOLTIP")
		knowledgePointTooltip:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})
		knowledgePointTooltip:SetBackdropColor(0, 0, 0, 0.9)
		knowledgePointTooltip:EnableMouse(false)
		knowledgePointTooltip:SetMovable(false)
		knowledgePointTooltip:Hide()

		knowledgePointTooltipText = knowledgePointTooltip:CreateFontString("ARTWORK", nil, "GameFontNormal")
		knowledgePointTooltipText:SetPoint("TOPLEFT", knowledgePointTooltip, "TOPLEFT", 10, -10)
		knowledgePointTooltipText:SetJustifyH("LEFT")
	end
end

-- Tooltip information
function pslTooltipInfo()
	local function OnTooltipSetItem(tooltip)
		-- Get item info from tooltip
		local _, link = TooltipUtil.GetDisplayedItem(tooltip)

		-- Don't do anything if no item link
		if not link then return end

		-- Get itemID
		local itemID = GetItemInfoFromHyperlink(link)

		-- Try again if error
		if itemID == nil then return end

		-- Get item amounts
		local reagentID1
		local reagentID2
		local reagentID3
		local reagentAmountNeed

		for reagentBase, reagentInfo in pairs(reagentsTracked) do
			if reagentInfo.one == itemID or reagentInfo.two == itemID or reagentInfo.three == itemID then
				reagentID1 = reagentInfo.one
				reagentID2 = reagentInfo.two
				reagentID3 = reagentInfo.three
				reagentAmountNeed = reagentInfo.amount
			end
		end

		local reagentAmountHave
		if userSettings["reagentQuality"] == 1 then
			reagentAmountHave = GetItemCount(reagentID3, true, false, true) + GetItemCount(reagentID2, true, false, true) + GetItemCount(reagentID1, true, false, true)
		elseif userSettings["reagentQuality"] == 2 and reagentID2 ~= 0 then
			reagentAmountHave = GetItemCount(reagentID3, true, false, true) + GetItemCount(reagentID2, true, false, true)
		elseif userSettings["reagentQuality"] == 2 and reagentID2 == 0 then
			reagentAmountHave = GetItemCount(reagentID3, true, false, true) + GetItemCount(reagentID2, true, false, true) + GetItemCount(reagentID1, true, false, true)
		elseif userSettings["reagentQuality"] == 3 and reagentID3 ~= 0 then
			reagentAmountHave = GetItemCount(reagentID3, true, false, true)
		elseif userSettings["reagentQuality"] == 3 and reagentID3 == 0 then
			reagentAmountHave = GetItemCount(reagentID3, true, false, true) + GetItemCount(reagentID2, true, false, true) + GetItemCount(reagentID1, true, false, true)
		end

		-- Tooltip info
		local function pslTooltipLines()
			tooltip:AddLine(" ")
			tooltip:AddLine("PSL: "..reagentAmountHave.."/"..reagentAmountNeed.." ("..math.max(0,reagentAmountNeed-reagentAmountHave).." more needed)")
		end

		-- Add the tooltip info
		if userSettings["showTooltip"] == true then
			if userSettings["reagentQuality"] == 1 and (reagentID1 == itemID or reagentID2 == itemID or reagentID3 == itemID) then
				pslTooltipLines()
			elseif userSettings["reagentQuality"] == 2 and reagentID2 ~= 0 and (reagentID2 == itemID or reagentID3 == itemID) then
				pslTooltipLines()
			elseif userSettings["reagentQuality"] == 2 and reagentID2 == 0 and (reagentID1 == itemID) then
				pslTooltipLines()
			elseif userSettings["reagentQuality"] == 3 and reagentID3 ~= 0 and (reagentID3 == itemID) then
				pslTooltipLines()
			elseif userSettings["reagentQuality"] == 3 and reagentID3 == 0 and (reagentID1 == itemID) then
				pslTooltipLines()
			end
		end
	end

	-- No clue what this does, to be honest
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)
end

-- Open settings
function pslOpenSettings()
	InterfaceOptionsFrame_OpenToCategory("Profession Shopping List")
end

f:SetScript("OnEvent", function(self, event, arg1, arg2, ...)
	-- When the AddOn is fully loaded, actually run the components
	if event == "ADDON_LOADED" and arg1 == "ProfessionShoppingList" then
		pslInitialise()
		pslCreateTrackingWindows()
		pslCreateButtons()
		pslTooltipInfo()

		-- Settings and minimap icon
		function pslSettings()
			-- Initialise the Settings page so the Minimap button can go there
			local settings = CreateFrame("Frame")			
			settings.name = "Profession Shopping List"
			InterfaceOptions_AddCategory(settings)

			-- Initialise the minimap button before the settings button is made, so it can toggle it
			local miniButton = LibStub("LibDataBroker-1.1"):NewDataObject("ProfessionShoppingList", {
				type = "data source",
				text = "Profession Shopping List",
				icon = "Interface\\AddOns\\ProfessionShoppingList\\assets\\psl_icon",
				
				OnClick = function(self, button)
					if button == "LeftButton" then
						-- Toggle tracking windows
						if pslFrame1:IsShown() then
							pslFrame1:Hide()
							pslFrame2:Hide()
						else
							pslFrame1:Show()
							pslFrame2:Show()
						end
						-- Only update numbers if numbers exist
						if reagentsTracked then pslReagents() end
					elseif button == "RightButton" then
						pslOpenSettings()
					end
				end,
				
				OnTooltipShow = function(tooltip)
					if not tooltip or not tooltip.AddLine then return end
					tooltip:AddLine("|cffFFFFFFProfession Shopping List|R\n|cff9D9D9DLeft-click:|R Toggle the windows.\n|cff9D9D9DRight-click:|R Show the settings.")
				end,
			})
								
			local icon = LibStub("LibDBIcon-1.0", true)
			icon:Register("ProfessionShoppingList", miniButton, userSettings)

			if userSettings["hide"] == true then 
				icon:Hide("ProfessionShoppingList")
			else
				icon:Show("ProfessionShoppingList")
			end

			-- Settings frame
			local scrollFrame = CreateFrame("ScrollFrame", nil, settings, "UIPanelScrollFrameTemplate")
			scrollFrame:SetPoint("TOPLEFT", 3, -4)
			scrollFrame:SetPoint("BOTTOMRIGHT", -27, 4)

			local scrollChild = CreateFrame("Frame")
			scrollFrame:SetScrollChild(scrollChild)
			scrollChild:SetWidth(SettingsPanel.Container.SettingsCanvas:GetWidth()-18)
			scrollChild:SetHeight(1) 

			-- Settings
			local title = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
			title:SetPoint("TOPLEFT", 10, -8)
			title:SetText("Profession Shopping List")

			-- Column 1
			local cbMinimapButton = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
			cbMinimapButton.Text:SetText("Minimap button")
			cbMinimapButton.Text:SetTextColor(1, 1, 1, 1)
			cbMinimapButton.Text:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
			cbMinimapButton:SetPoint("TOPLEFT", 10, -25)
			cbMinimapButton:SetChecked(not userSettings["hide"])
			cbMinimapButton:SetScript("OnClick", function(self)
				userSettings["hide"] = not self:GetChecked()
				if userSettings["hide"] == true then
					icon:Hide("ProfessionShoppingList")
				else
					icon:Show("ProfessionShoppingList")
				end
			end)

			local cbCloseWhenDoneCheck	-- Declare it here, so we can reference it for all the option dependencies

			local cbRemoveCraft = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
			cbRemoveCraft.Text:SetText("Untrack on crafting")
			cbRemoveCraft.Text:SetTextColor(1, 1, 1, 1)
			cbRemoveCraft.Text:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
			cbRemoveCraft:SetPoint("TOPLEFT", cbMinimapButton, "BOTTOMLEFT", 0, 0)
			cbRemoveCraft:SetChecked(userSettings["removeCraft"])
			cbRemoveCraft:SetScript("OnClick", function(self)
				userSettings["removeCraft"] = cbRemoveCraft:GetChecked()
				cbCloseWhenDoneCheck()
			end)

			local cbCloseWhenDone = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
			cbCloseWhenDone.Text:SetText("Close windows when done")
			cbCloseWhenDone.Text:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
			cbCloseWhenDone:SetPoint("TOPLEFT", cbRemoveCraft, "BOTTOMLEFT", 15, 0)
			cbCloseWhenDone:SetChecked(userSettings["closeWhenDone"])
			cbCloseWhenDone:SetScript("OnClick", function(self)
				userSettings["closeWhenDone"] = cbCloseWhenDone:GetChecked()
			end)

			-- Disable this option when the dependency option is unchecked
			cbCloseWhenDoneCheck = function()
				if userSettings["removeCraft"] == true then
					cbCloseWhenDone:Enable()
					cbCloseWhenDone.Text:SetTextColor(1, 1, 1, 1)
				else
					cbCloseWhenDone:Disable()
					cbCloseWhenDone.Text:SetTextColor(.62, .62, .62, 1)
				end
			end
			cbCloseWhenDoneCheck()

			local cbShowRemaining = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
			cbShowRemaining.Text:SetText("Show remaining reagents, not total")
			cbShowRemaining.Text:SetTextColor(1, 1, 1, 1)
			cbShowRemaining.Text:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
			cbShowRemaining:SetPoint("TOPLEFT", cbCloseWhenDone, "BOTTOMLEFT", -15, 0)
			cbShowRemaining:SetChecked(userSettings["showRemaining"])
			cbShowRemaining:SetScript("OnClick", function(self)
				userSettings["showRemaining"] = cbShowRemaining:GetChecked()
				pslReagents()
			end)

			local cbShowTooltip = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
			cbShowTooltip.Text:SetText("Show tooltip information")
			cbShowTooltip.Text:SetTextColor(1, 1, 1, 1)
			cbShowTooltip.Text:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
			cbShowTooltip:SetPoint("TOPLEFT", cbShowRemaining, "BOTTOMLEFT", 0, 0)
			cbShowTooltip:SetChecked(userSettings["showTooltip"])
			cbShowTooltip:SetScript("OnClick", function(self)
				userSettings["showTooltip"] = cbShowTooltip:GetChecked()
			end)

			local cbShowKnowledgeNotPerks = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
			cbShowKnowledgeNotPerks.Text:SetText("Show knowledge, not perks")
			cbShowKnowledgeNotPerks.Text:SetTextColor(1, 1, 1, 1)
			cbShowKnowledgeNotPerks.Text:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
			cbShowKnowledgeNotPerks:SetPoint("TOPLEFT", cbShowTooltip, "BOTTOMLEFT", 0, 0)
			cbShowKnowledgeNotPerks:SetChecked(userSettings["showKnowledgeNotPerks"])
			cbShowKnowledgeNotPerks:SetScript("OnClick", function(self)
				userSettings["showKnowledgeNotPerks"] = cbShowKnowledgeNotPerks:GetChecked()
			end)

			local cbVendorAll = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
			cbVendorAll.Text:SetText("Always set vendor filter to 'All'")
			cbVendorAll.Text:SetTextColor(1, 1, 1, 1)
			cbVendorAll.Text:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
			cbVendorAll:SetPoint("TOPLEFT", cbShowKnowledgeNotPerks, "BOTTOMLEFT", 0, 0)
			cbVendorAll:SetChecked(userSettings["vendorAll"])
			cbVendorAll:SetScript("OnClick", function(self)
				userSettings["vendorAll"] = cbVendorAll:GetChecked()
			end)

			local slReagentQuality = CreateFrame("Slider", nil, scrollChild, "UISliderTemplateWithLabels")
			slReagentQuality:SetPoint("TOPLEFT", cbVendorAll, "BOTTOMLEFT", 5, -15)
			slReagentQuality:SetOrientation("HORIZONTAL")
			slReagentQuality:SetWidth(150)
			slReagentQuality:SetHeight(17)
			slReagentQuality:SetMinMaxValues(1,3)
			slReagentQuality:SetValueStep(1)
			slReagentQuality:SetObeyStepOnDrag(true)
			slReagentQuality.Low:SetText("Tier 1")
			slReagentQuality.High:SetText("Tier 3")
			slReagentQuality.Text:SetText("Minimum reagent quality")
			slReagentQuality:SetValue(userSettings["reagentQuality"])
			slReagentQuality.Label = slReagentQuality:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
			slReagentQuality.Label:SetPoint("TOP", slReagentQuality, "BOTTOM", 0, 0)
			slReagentQuality.Label:SetText("Tier "..slReagentQuality:GetValue())
			slReagentQuality:SetScript("OnValueChanged", function(self, newValue)
				userSettings["reagentQuality"] = newValue
				self:SetValue(userSettings["reagentQuality"])
				self.Label:SetText("Tier "..slReagentQuality:GetValue())
				pslReagents()
			end)

			-- Column 2
			local slRecipeRows = CreateFrame("Slider", nil, scrollChild, "UISliderTemplateWithLabels")
			slRecipeRows:SetPoint("TOPLEFT", cbMinimapButton, "TOPLEFT", 250, -19)
			slRecipeRows:SetOrientation("HORIZONTAL")
			slRecipeRows:SetWidth(150)
			slRecipeRows:SetHeight(17)
			slRecipeRows:SetMinMaxValues(5,50)
			slRecipeRows:SetValueStep(1)
			slRecipeRows:SetObeyStepOnDrag(true)
			slRecipeRows.Low:SetText("5")
			slRecipeRows.High:SetText("50")
			slRecipeRows.Text:SetText("Recipe rows")
			slRecipeRows:SetValue(userSettings["recipeRows"])
			slRecipeRows.Label = slRecipeRows:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
			slRecipeRows.Label:SetPoint("TOP", slRecipeRows, "BOTTOM", 0, 0)
			slRecipeRows.Label:SetText(slRecipeRows:GetValue())
			slRecipeRows:SetScript("OnValueChanged", function(self, newValue)
				userSettings["recipeRows"] = newValue
				self:SetValue(userSettings["recipeRows"])
				self.Label:SetText(self:GetValue())
				pslCreateTrackingWindows()
			end)

			local slRecipeWidth = CreateFrame("Slider", nil, scrollChild, "UISliderTemplateWithLabels")
			slRecipeWidth:SetPoint("TOPLEFT", slRecipeRows, "BOTTOMLEFT", 0, -30)
			slRecipeWidth:SetOrientation("HORIZONTAL")
			slRecipeWidth:SetWidth(150)
			slRecipeWidth:SetHeight(17)
			slRecipeWidth:SetMinMaxValues(100,300)
			slRecipeWidth:SetValueStep(5)
			slRecipeWidth:SetObeyStepOnDrag(true)
			slRecipeWidth.Low:SetText("100")
			slRecipeWidth.High:SetText("300")
			slRecipeWidth.Text:SetText("Recipe width")
			slRecipeWidth:SetValue(userSettings["recipeWidth"])
			slRecipeWidth.Label = slRecipeWidth:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
			slRecipeWidth.Label:SetPoint("TOP", slRecipeWidth, "BOTTOM", 0, 0)
			slRecipeWidth.Label:SetText(slRecipeWidth:GetValue())
			slRecipeWidth:SetScript("OnValueChanged", function(self, newValue)
				userSettings["recipeWidth"] = newValue
				self:SetValue(userSettings["recipeWidth"])
				self.Label:SetText(self:GetValue())
				pslCreateTrackingWindows()
			end)

			local slRecipeNoWidth = CreateFrame("Slider", nil, scrollChild, "UISliderTemplateWithLabels")
			slRecipeNoWidth:SetPoint("TOPLEFT", slRecipeWidth, "BOTTOMLEFT", 0, -30)
			slRecipeNoWidth:SetOrientation("HORIZONTAL")
			slRecipeNoWidth:SetWidth(150)
			slRecipeNoWidth:SetHeight(17)
			slRecipeNoWidth:SetMinMaxValues(30,100)
			slRecipeNoWidth:SetValueStep(5)
			slRecipeNoWidth:SetObeyStepOnDrag(true)
			slRecipeNoWidth.Low:SetText("30")
			slRecipeNoWidth.High:SetText("100")
			slRecipeNoWidth.Text:SetText("Recipe # width")
			slRecipeNoWidth:SetValue(userSettings["recipeNoWidth"])
			slRecipeNoWidth.Label = slRecipeNoWidth:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
			slRecipeNoWidth.Label:SetPoint("TOP", slRecipeNoWidth, "BOTTOM", 0, 0)
			slRecipeNoWidth.Label:SetText(slRecipeNoWidth:GetValue())
			slRecipeNoWidth:SetScript("OnValueChanged", function(self, newValue)
				userSettings["recipeNoWidth"] = newValue
				self:SetValue(userSettings["recipeNoWidth"])
				self.Label:SetText(self:GetValue())
				pslCreateTrackingWindows()
			end)

			local slReagentRows = CreateFrame("Slider", nil, scrollChild, "UISliderTemplateWithLabels")
			slReagentRows:SetPoint("TOPLEFT", slRecipeRows, "TOPRIGHT", 20, 0)
			slReagentRows:SetOrientation("HORIZONTAL")
			slReagentRows:SetWidth(150)
			slReagentRows:SetHeight(17)
			slReagentRows:SetMinMaxValues(5,50)
			slReagentRows:SetValueStep(1)
			slReagentRows:SetObeyStepOnDrag(true)
			slReagentRows.Low:SetText("5")
			slReagentRows.High:SetText("50")
			slReagentRows.Text:SetText("Reagent rows")
			slReagentRows:SetValue(userSettings["reagentRows"])
			slReagentRows.Label = slReagentRows:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
			slReagentRows.Label:SetPoint("TOP", slReagentRows, "BOTTOM", 0, 0)
			slReagentRows.Label:SetText(slReagentRows:GetValue())
			slReagentRows:SetScript("OnValueChanged", function(self, newValue)
				userSettings["reagentRows"] = newValue
				self:SetValue(userSettings["reagentRows"])
				self.Label:SetText(self:GetValue())
				pslCreateTrackingWindows()
			end)

			local slReagentWidth = CreateFrame("Slider", nil, scrollChild, "UISliderTemplateWithLabels")
			slReagentWidth:SetPoint("TOPLEFT", slReagentRows, "BOTTOMLEFT", 0, -30)
			slReagentWidth:SetOrientation("HORIZONTAL")
			slReagentWidth:SetWidth(150)
			slReagentWidth:SetHeight(17)
			slReagentWidth:SetMinMaxValues(100,300)
			slReagentWidth:SetValueStep(5)
			slReagentWidth:SetObeyStepOnDrag(true)
			slReagentWidth.Low:SetText("100")
			slReagentWidth.High:SetText("300")
			slReagentWidth.Text:SetText("Reagent width")
			slReagentWidth:SetValue(userSettings["reagentWidth"])
			slReagentWidth.Label = slReagentWidth:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
			slReagentWidth.Label:SetPoint("TOP", slReagentWidth, "BOTTOM", 0, 0)
			slReagentWidth.Label:SetText(slReagentWidth:GetValue())
			slReagentWidth:SetScript("OnValueChanged", function(self, newValue)
				userSettings["reagentWidth"] = newValue
				self:SetValue(userSettings["reagentWidth"])
				self.Label:SetText(self:GetValue())
				pslCreateTrackingWindows()
			end)

			local slReagentNoWidth = CreateFrame("Slider", nil, scrollChild, "UISliderTemplateWithLabels")
			slReagentNoWidth:SetPoint("TOPLEFT", slReagentWidth, "BOTTOMLEFT", 0, -30)
			slReagentNoWidth:SetOrientation("HORIZONTAL")
			slReagentNoWidth:SetWidth(150)
			slReagentNoWidth:SetHeight(17)
			slReagentNoWidth:SetMinMaxValues(30,100)
			slReagentNoWidth:SetValueStep(5)
			slReagentNoWidth:SetObeyStepOnDrag(true)
			slReagentNoWidth.Low:SetText("30")
			slReagentNoWidth.High:SetText("100")
			slReagentNoWidth.Text:SetText("Reagent # width")
			slReagentNoWidth:SetValue(userSettings["reagentNoWidth"])
			slReagentNoWidth.Label = slReagentNoWidth:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
			slReagentNoWidth.Label:SetPoint("TOP", slReagentNoWidth, "BOTTOM", 0, 0)
			slReagentNoWidth.Label:SetText(slReagentNoWidth:GetValue())
			slReagentNoWidth:SetScript("OnValueChanged", function(self, newValue)
				userSettings["reagentNoWidth"] = newValue
				self:SetValue(userSettings["reagentNoWidth"])
				self.Label:SetText(self:GetValue())
				pslCreateTrackingWindows()
			end)
   
			-- Extra text
			local pslSettingsText1 = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
			pslSettingsText1:SetPoint("TOPLEFT", slReagentQuality, "BOTTOMLEFT", 3, -40)
			pslSettingsText1:SetJustifyH("LEFT");
			pslSettingsText1:SetText("Chat commands:\n/psl |cffFFFFFF- Toggle the PSL windows.\n|R/psl settings |cffFFFFFF- Open the PSL settings.\n|R/psl clear |cffFFFFFF- Clear all tracked recipes.")

			local pslSettingsText2 = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
			pslSettingsText2:SetPoint("TOPLEFT", pslSettingsText1, "BOTTOMLEFT", 0, -15)
			pslSettingsText2:SetJustifyH("LEFT");
			pslSettingsText2:SetText("Mouse interactions:\nDrag|cffFFFFFF: Move the PSL windows.\n|RShift+click Recipe|cffFFFFFF: Link the recipe.\n|RCtrl+click Recipe|cffFFFFFF: Open the recipe (if known on current character).\n|RRight-click Recipe #|cffFFFFFF: Untrack 1 of the selected recipe.\n|RCtrl+right-click Recipe #|cffFFFFFF: Untrack all of the selected recipe.\n|RShift+click Reagent|cffFFFFFF: Link the reagent.\n|RCtrl+click Reagent|cffFFFFFF: Add recipe for the selected subreagent, if it exists.\n(This only works for professions that have been opened with PSL active.)")

			local pslSettingsText3 = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
			pslSettingsText3:SetPoint("TOPLEFT", pslSettingsText2, "BOTTOMLEFT", 0, -15)
			pslSettingsText3:SetJustifyH("LEFT");
			pslSettingsText3:SetText("Other features:\n|cffFFFFFF- Adds a Chef's Hat button to the Cooking window, if the toy is known.")
		end
		pslSettings()

		-- Slash commands
		SLASH_PSL1 = "/psl";
		function SlashCmdList.PSL(msg, editBox)
			-- Open settings
			if msg == "settings" then
				pslOpenSettings()
			-- Clear list
			elseif msg == "clear" then
				-- Clear recipes and reagents
				recipesTracked = {}
				reagentsTracked = {}
				recipeLinks = {}
				recipeLibrary = {}
				pslReagents()

				-- Disable remove button
				removeCraftListButton:Disable()

				-- Remove old version variables
				reagentNumbers = nil
				reagentLinks = nil
			-- No arguments
			else
				-- Toggle tracking windows
				if pslFrame1:IsShown() then
					pslFrame1:Hide()
					pslFrame2:Hide()
				else
					pslFrame1:Show()
					pslFrame2:Show()
				end
				-- Only update numbers if numbers exist
				if reagentsTracked then pslReagents() end
			end
		end

		-- Window functions
		function pslWindowFunctions()
			-- Reagents window
			table1:RegisterEvents({
				["OnEnter"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
					if row and realrow ~= nil then
						local celldata = data[realrow][1]
						GameTooltip:ClearLines()
						GameTooltip:SetOwner(pslFrame1, "ANCHOR_BOTTOM")
						GameTooltip:SetHyperlink(celldata)
						GameTooltip:Show()
					end
				end
			})
			table1:RegisterEvents({
				["OnLeave"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
					GameTooltip:ClearLines()
					GameTooltip:Hide()
				end
			})
			table1:RegisterEvents({
				["OnMouseDown"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, button, ...)
					if button == "LeftButton" then
						pslFrame1:StartMoving()
						GameTooltip:ClearLines()
						GameTooltip:Hide()
					end
				end
			})
			table1:RegisterEvents({
				["OnMouseUp"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
					pslFrame1:StopMovingOrSizing()

					if realrow ~= nil then
						local celldata = data[realrow][1]
						GameTooltip:ClearLines()
						GameTooltip:SetOwner(pslFrame1, "ANCHOR_BOTTOM")
						GameTooltip:SetHyperlink(celldata)
						GameTooltip:Show()
					end
				end
			})
			table1:RegisterEvents({
				["OnClick"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, button, ...)
					-- Activate if Ctrl+clicking on the reagents column
					if column == 1 and button == "LeftButton" and IsControlKeyDown() == true and realrow ~= nil then
						-- Get itemID
						local itemID = GetItemInfoFromHyperlink(data[realrow][1])
						if reagentTiers[itemID] then itemID = reagentTiers[itemID] end

						-- Get possible recipeIDs
						local recipeIDs = {}
						local no = 0

						for r, i in pairs(recipeLibrary) do
							if i == itemID then
								no = no + 1
								recipeIDs[no] = r
							end
						end

						-- If there is only one possible recipe, use that
						if no == 1 then
							local recipeID = recipeIDs[no]

							-- Track recipe
							local quantityMade = C_TradeSkillUI.GetRecipeSchematic(recipeID, false).quantityMin
							recipesTracked[recipeID] = math.max(0, math.ceil((reagentsTracked[itemID].amount - GetItemCount(itemID)) / quantityMade))

							-- Add recipe link
							recipeLinks[recipeID] = C_TradeSkillUI.GetRecipeOutputItemData(recipeID).hyperlink

							-- Show windows
							pslFrame1:Show()
							pslFrame2:Show()

							-- Update numbers
							pslReagents()

						-- If there is more than one possible recipe, provide options
						elseif no > 1 then
							-- Create popup frame
							local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
							f:SetPoint("CENTER")
							f:SetBackdrop({
								bgFile = "Interface/Tooltips/UI-Tooltip-Background",
								edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
								edgeSize = 16,
								insets = { left = 4, right = 4, top = 4, bottom = 4 },
							})
							f:SetBackdropColor(0, 0, 0, 1)
							f:EnableMouse(true)
							f:SetMovable(true)
							f:RegisterForDrag("LeftButton")
							f:SetScript("OnDragStart", function(self, button) self:StartMoving() end)
							f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)	 
							f:Show()

							-- Close button
							local close = CreateFrame("Button", "pslOptionCloseButton", f, "UIPanelCloseButton")
							close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
							close:SetScript("OnClick", function()
								f:Hide()
							end)

							-- Text
							local pslOptionText = f:CreateFontString("ARTWORK", nil, "GameFontNormal")
							pslOptionText:SetPoint("CENTER", f, "CENTER", 0, 0)
							pslOptionText:SetPoint("TOP", f, "TOP", 0, -10)
							pslOptionText:SetJustifyH("CENTER")
							pslOptionText:SetText("|cffFFFFFFThere are multiple recipes which can create\n"..data[realrow][1]..".\n\nPlease select one of the following:")

							-- Text
							local pslOption1 = f:CreateFontString("ARTWORK", nil, "GameFontNormal")
							pslOption1:SetPoint("LEFT", f, "LEFT", 10, 0)
							pslOption1:SetPoint("TOP", pslOptionText, "BOTTOM", 0, -40)
							pslOption1:SetWidth(200)
							pslOption1:SetJustifyH("LEFT")
							pslOption1:SetText("|cffFFFFFF")

							-- Get reagents #1
							local reagentsTable = C_TradeSkillUI.GetRecipeSchematic(recipeIDs[1], false).reagentSlotSchematics

							-- For every reagent, if not optional or finishing, do
							for numReagent, reagentInfo in pairs(reagentsTable) do
								if reagentInfo.reagentType == 1 then
									-- Get info
									local function getInfo()
										local reagentID = reagentInfo.reagents[1].itemID
										local reagentAmount = reagentInfo.quantityRequired
										local itemName, itemLink = GetItemInfo(reagentID)

										-- Try again if error
										if itemName == nil or itemLink == nil then
											RunNextFrame(getInfo)
											do return end
										end

										-- Add text
										oldText = pslOption1:GetText()
										pslOption1:SetText(oldText..reagentAmount.."x "..itemLink.."\n")
									end
									getInfo()
								end
							end

							-- Button #1
							pslOptionButton1 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
							pslOptionButton1:SetText(C_TradeSkillUI.GetRecipeSchematic(recipeIDs[1], false).name)
							pslOptionButton1:SetWidth(200)
							pslOptionButton1:SetPoint("BOTTOM", pslOption1, "TOP", 0, 5)
							pslOptionButton1:SetPoint("CENTER", pslOption1, "CENTER", 0, 0)
							pslOptionButton1:SetScript("OnClick", function()
								-- Get selected recipe ID
								local recipeID = recipeIDs[1]
						
								-- Track recipe
								local quantityMade = C_TradeSkillUI.GetRecipeSchematic(recipeID, false).quantityMin
								recipesTracked[recipeID] = math.max(0, math.ceil(reagentsTracked[itemID].amount / quantityMade) - GetItemCount(itemID))
						
								-- Add recipe link
								recipeLinks[recipeID] = C_TradeSkillUI.GetRecipeOutputItemData(recipeID).hyperlink
						
								-- Show windows
								pslFrame1:Show()
								pslFrame2:Show()
								f:Hide()
						
								-- Update numbers
								pslReagents()
							end)
							
							-- If two options
							if no >= 2 then
								-- Adjust popup frame
								f:SetSize(430, 205)

								-- Text
								local pslOption2 = f:CreateFontString("ARTWORK", nil, "GameFontNormal")
								pslOption2:SetPoint("LEFT", pslOption1, "RIGHT", 10, 0)
								pslOption2:SetPoint("TOP", pslOption1, "TOP", 0, 0)
								pslOption2:SetWidth(200)
								pslOption2:SetJustifyH("LEFT")
								pslOption2:SetText("|cffFFFFFF")

								-- Get reagents #2
								local reagentsTable = C_TradeSkillUI.GetRecipeSchematic(recipeIDs[2], false).reagentSlotSchematics

								-- For every reagent, if not optional or finishing, do
								for numReagent, reagentInfo in pairs(reagentsTable) do
									if reagentInfo.reagentType == 1 then
										-- Get info
										local function getInfo()
											local reagentID = reagentInfo.reagents[1].itemID
											local reagentAmount = reagentInfo.quantityRequired
											local itemName, itemLink = GetItemInfo(reagentID)

											-- Try again if error
											if itemName == nil or itemLink == nil then
												RunNextFrame(getInfo)
												do return end
											end

											-- Add text
											oldText = pslOption2:GetText()
											pslOption2:SetText(oldText..reagentAmount.."x "..itemLink.."\n")
										end
										getInfo()
									end
								end

								-- Button #2
								pslOptionButton2 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
								pslOptionButton2:SetText(C_TradeSkillUI.GetRecipeSchematic(recipeIDs[2], false).name)
								pslOptionButton2:SetWidth(200)
								pslOptionButton2:SetPoint("BOTTOM", pslOption2, "TOP", 0, 5)
								pslOptionButton2:SetPoint("CENTER", pslOption2, "CENTER", 0, 0)
								pslOptionButton2:SetScript("OnClick", function()
									-- Get selected recipe ID
									local recipeID = recipeIDs[2]
							
									-- Track recipe
									local quantityMade = C_TradeSkillUI.GetRecipeSchematic(recipeID, false).quantityMin
									recipesTracked[recipeID] = math.max(0, math.ceil(reagentsTracked[itemID].amount / quantityMade) - GetItemCount(itemID))
							
									-- Add recipe link
									recipeLinks[recipeID] = C_TradeSkillUI.GetRecipeOutputItemData(recipeID).hyperlink
							
									-- Show windows
									pslFrame1:Show()
									pslFrame2:Show()
									f:Hide()
							
									-- Update numbers
									pslReagents()
								end)
							end

							-- If three options
							if no >= 3 then
								-- Adjust popup frame
								f:SetSize(640, 200)

								-- Text
								local pslOption3 = f:CreateFontString("ARTWORK", nil, "GameFontNormal")
								pslOption3:SetPoint("LEFT", pslOption1, "RIGHT", 220, 0)
								pslOption3:SetPoint("TOP", pslOption1, "TOP", 0, 0)
								pslOption3:SetWidth(200)
								pslOption3:SetJustifyH("LEFT")
								pslOption3:SetText("|cffFFFFFF")

								-- Get reagents #3
								local reagentsTable = C_TradeSkillUI.GetRecipeSchematic(recipeIDs[3], false).reagentSlotSchematics

								-- For every reagent, if not optional or finishing, do
								for numReagent, reagentInfo in pairs(reagentsTable) do
									if reagentInfo.reagentType == 1 then
										-- Get info
										local function getInfo()
											local reagentID = reagentInfo.reagents[1].itemID
											local reagentAmount = reagentInfo.quantityRequired
											local itemName, itemLink = GetItemInfo(reagentID)

											-- Try again if error
											if itemName == nil or itemLink == nil then
												RunNextFrame(getInfo)
												do return end
											end

											-- Add text
											oldText = pslOption3:GetText()
											pslOption3:SetText(oldText..reagentAmount.."x "..itemLink.."\n")
										end
										getInfo()
									end
								end

								-- Button #3
								pslOptionButton3 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
								pslOptionButton3:SetText(C_TradeSkillUI.GetRecipeSchematic(recipeIDs[3], false).name)
								pslOptionButton3:SetWidth(200)
								pslOptionButton3:SetPoint("BOTTOM", pslOption3, "TOP", 0, 5)
								pslOptionButton3:SetPoint("CENTER", pslOption3, "CENTER", 0, 0)
								pslOptionButton3:SetScript("OnClick", function()
									-- Get selected recipe ID
									local recipeID = recipeIDs[3]
							
									-- Track recipe
									local quantityMade = C_TradeSkillUI.GetRecipeSchematic(recipeID, false).quantityMin
									recipesTracked[recipeID] = math.max(0, math.ceil(reagentsTracked[itemID].amount / quantityMade) - GetItemCount(itemID))
							
									-- Add recipe link
									recipeLinks[recipeID] = C_TradeSkillUI.GetRecipeOutputItemData(recipeID).hyperlink
							
									-- Show windows
									pslFrame1:Show()
									pslFrame2:Show()
									f:Hide()
							
									-- Update numbers
									pslReagents()
								end)
							end

							-- If four options
							if no >= 4 then
								-- Adjust popup frame
								f:SetSize(640, 335)

								-- Text
								local pslOption4 = f:CreateFontString("ARTWORK", nil, "GameFontNormal")
								pslOption4:SetPoint("LEFT", pslOption1, "LEFT", 0, 0)
								pslOption4:SetPoint("TOP", pslOption1, "TOP", 0, -130)
								pslOption4:SetWidth(200)
								pslOption4:SetJustifyH("LEFT")
								pslOption4:SetText("|cffFFFFFF")

								-- Get reagents #4
								local reagentsTable = C_TradeSkillUI.GetRecipeSchematic(recipeIDs[4], false).reagentSlotSchematics

								-- For every reagent, if not optional or finishing, do
								for numReagent, reagentInfo in pairs(reagentsTable) do
									if reagentInfo.reagentType == 1 then
										-- Get info
										local function getInfo()
											local reagentID = reagentInfo.reagents[1].itemID
											local reagentAmount = reagentInfo.quantityRequired
											local itemName, itemLink = GetItemInfo(reagentID)

											-- Try again if error
											if itemName == nil or itemLink == nil then
												RunNextFrame(getInfo)
												do return end
											end

											-- Add text
											oldText = pslOption4:GetText()
											pslOption4:SetText(oldText..reagentAmount.."x "..itemLink.."\n")
										end
										getInfo()
									end
								end

								-- Button #4
								pslOptionButton4 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
								pslOptionButton4:SetText(C_TradeSkillUI.GetRecipeSchematic(recipeIDs[4], false).name)
								pslOptionButton4:SetWidth(200)
								pslOptionButton4:SetPoint("BOTTOM", pslOption4, "TOP", 0, 5)
								pslOptionButton4:SetPoint("CENTER", pslOption4, "CENTER", 0, 0)
								pslOptionButton4:SetScript("OnClick", function()
									-- Get selected recipe ID
									local recipeID = recipeIDs[4]
							
									-- Track recipe
									local quantityMade = C_TradeSkillUI.GetRecipeSchematic(recipeID, false).quantityMin
									recipesTracked[recipeID] = math.max(0, math.ceil(reagentsTracked[itemID].amount / quantityMade) - GetItemCount(itemID))
							
									-- Add recipe link
									recipeLinks[recipeID] = C_TradeSkillUI.GetRecipeOutputItemData(recipeID).hyperlink
							
									-- Show windows
									pslFrame1:Show()
									pslFrame2:Show()
									f:Hide()
							
									-- Update numbers
									pslReagents()
								end)
							end

							-- If five options
							if no >= 5 then
								-- Text
								local pslOption5 = f:CreateFontString("ARTWORK", nil, "GameFontNormal")
								pslOption5:SetPoint("LEFT", pslOption1, "RIGHT", 10, 0)
								pslOption5:SetPoint("TOP", pslOption1, "TOP", 0, -130)
								pslOption5:SetWidth(200)
								pslOption5:SetJustifyH("LEFT")
								pslOption5:SetText("|cffFFFFFF")

								-- Get reagents #5
								local reagentsTable = C_TradeSkillUI.GetRecipeSchematic(recipeIDs[5], false).reagentSlotSchematics

								-- For every reagent, if not optional or finishing, do
								for numReagent, reagentInfo in pairs(reagentsTable) do
									if reagentInfo.reagentType == 1 then
										-- Get info
										local function getInfo()
											local reagentID = reagentInfo.reagents[1].itemID
											local reagentAmount = reagentInfo.quantityRequired
											local itemName, itemLink = GetItemInfo(reagentID)

											-- Try again if error
											if itemName == nil or itemLink == nil then
												RunNextFrame(getInfo)
												do return end
											end

											-- Add text
											oldText = pslOption5:GetText()
											pslOption5:SetText(oldText..reagentAmount.."x "..itemLink.."\n")
										end
										getInfo()
									end
								end

								-- Button #5
								pslOptionButton5 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
								pslOptionButton5:SetText(C_TradeSkillUI.GetRecipeSchematic(recipeIDs[5], false).name)
								pslOptionButton5:SetWidth(200)
								pslOptionButton5:SetPoint("BOTTOM", pslOption5, "TOP", 0, 5)
								pslOptionButton5:SetPoint("CENTER", pslOption5, "CENTER", 0, 0)
								pslOptionButton5:SetScript("OnClick", function()
									-- Get selected recipe ID
									local recipeID = recipeIDs[5]
							
									-- Track recipe
									local quantityMade = C_TradeSkillUI.GetRecipeSchematic(recipeID, false).quantityMin
									recipesTracked[recipeID] = math.max(0, math.ceil(reagentsTracked[itemID].amount / quantityMade) - GetItemCount(itemID))
							
									-- Add recipe link
									recipeLinks[recipeID] = C_TradeSkillUI.GetRecipeOutputItemData(recipeID).hyperlink
							
									-- Show windows
									pslFrame1:Show()
									pslFrame2:Show()
									f:Hide()
							
									-- Update numbers
									pslReagents()
								end)
							end

							-- If six options
							if no >= 6 then
								-- Text
								local pslOption6 = f:CreateFontString("ARTWORK", nil, "GameFontNormal")
								pslOption6:SetPoint("LEFT", pslOption1, "RIGHT", 220, 0)
								pslOption6:SetPoint("TOP", pslOption1, "TOP", 0, -130)
								pslOption6:SetWidth(200)
								pslOption6:SetJustifyH("LEFT")
								pslOption6:SetText("|cffFFFFFF")

								-- Get reagents #6
								local reagentsTable = C_TradeSkillUI.GetRecipeSchematic(recipeIDs[6], false).reagentSlotSchematics

								-- For every reagent, if not optional or finishing, do
								for numReagent, reagentInfo in pairs(reagentsTable) do
									if reagentInfo.reagentType == 1 then
										-- Get info
										local function getInfo()
											local reagentID = reagentInfo.reagents[1].itemID
											local reagentAmount = reagentInfo.quantityRequired
											local itemName, itemLink = GetItemInfo(reagentID)

											-- Try again if error
											if itemName == nil or itemLink == nil then
												RunNextFrame(getInfo)
												do return end
											end

											-- Add text
											oldText = pslOption6:GetText()
											pslOption6:SetText(oldText..reagentAmount.."x "..itemLink.."\n")
										end
										getInfo()
									end
								end

								-- Button #6
								pslOptionButton6 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
								pslOptionButton6:SetText(C_TradeSkillUI.GetRecipeSchematic(recipeIDs[6], false).name)
								pslOptionButton6:SetWidth(200)
								pslOptionButton6:SetPoint("BOTTOM", pslOption6, "TOP", 0, 5)
								pslOptionButton6:SetPoint("CENTER", pslOption6, "CENTER", 0, 0)
								pslOptionButton6:SetScript("OnClick", function()
									-- Get selected recipe ID
									local recipeID = recipeIDs[6]
							
									-- Track recipe
									local quantityMade = C_TradeSkillUI.GetRecipeSchematic(recipeID, false).quantityMin
									recipesTracked[recipeID] = math.max(0, math.ceil(reagentsTracked[itemID].amount / quantityMade) - GetItemCount(itemID))
							
									-- Add recipe link
									recipeLinks[recipeID] = C_TradeSkillUI.GetRecipeOutputItemData(recipeID).hyperlink
							
									-- Show windows
									pslFrame1:Show()
									pslFrame2:Show()
									f:Hide()
							
									-- Update numbers
									pslReagents()
								end)
							end
						end
					-- Activate if Shift+clicking on the reagents column
					elseif column == 1 and button == "LeftButton" and IsShiftKeyDown() == true and realrow ~= nil then
						ChatEdit_InsertLink(data[realrow][1])
					end
				end
			})

			-- Recipes window
			table2:RegisterEvents({
				["OnEnter"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
					if row and realrow ~= nil then
						local celldata = data[realrow][1]
						GameTooltip:ClearLines()
						GameTooltip:SetOwner(pslFrame2, "ANCHOR_BOTTOM")
						GameTooltip:SetHyperlink(celldata)
						GameTooltip:Show()
					end
				end
			})
			table2:RegisterEvents({
				["OnLeave"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
					GameTooltip:ClearLines()
					GameTooltip:Hide()
				end
			})
			table2:RegisterEvents({
				["OnClick"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, button, ...)
					-- Activate if right-clicking on the tracked column
					if column == 2 and button == "RightButton" and row ~= nil and realrow ~= nil then
						-- Get the selected recipe ID
						local selectedRecipe = data[realrow][1]
						local selectedRecipeID

						for recipeID, recipeLink in pairs(recipeLinks) do
							if selectedRecipe == recipeLink then selectedRecipeID = recipeID end
						end

						-- Untrack the recipe
						if IsControlKeyDown() == true then
							recipesTracked[selectedRecipeID] = 0
						else
							recipesTracked[selectedRecipeID] = recipesTracked[selectedRecipeID] - 1
						end

						-- Set numbers to nil if it doesn't exist anymore
						if recipesTracked[selectedRecipeID] <= 0 then
							recipesTracked[selectedRecipeID] = nil
							recipeLinks[selectedRecipeID] = nil
						end

						-- Show windows
						pslFrame1:Show()
						pslFrame2:Show()
						
						-- Update numbers
						pslReagents()

					elseif column == 1 and button == "LeftButton" and row ~= nil and realrow ~= nil then
						-- If Shift is held also
						if IsShiftKeyDown() == true then
							-- Try write link to chat
							ChatEdit_InsertLink(data[realrow][1])
						elseif IsControlKeyDown() == true then
							-- Get the selected recipe ID
							local selectedRecipe = data[realrow][1]
							local selectedRecipeID = 0

							for recipeID, recipeLink in pairs(recipeLinks) do
								if selectedRecipe == recipeLink then selectedRecipeID = recipeID end
							end

							-- Open recipe if it is learned
							if selectedRecipeID ~= 0 and C_TradeSkillUI.IsRecipeProfessionLearned(selectedRecipeID) == true then C_TradeSkillUI.OpenRecipe(selectedRecipeID) end
						end
					end
				end
			})
			table2:RegisterEvents({
				["OnMouseDown"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, button, ...)
					if button == "LeftButton" then
						pslFrame2:StartMoving()
						GameTooltip:ClearLines()
						GameTooltip:Hide()
					end
				end
			})
			table2:RegisterEvents({
				["OnMouseUp"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
					pslFrame2:StopMovingOrSizing()

					if realrow ~= nil then
						local celldata = data[realrow][1]
						GameTooltip:ClearLines()
						GameTooltip:SetOwner(pslFrame2, "ANCHOR_BOTTOM")
						GameTooltip:SetHyperlink(celldata)
						GameTooltip:Show()
					end
				end
			})
		end
		pslWindowFunctions()
	end

	-- When a recipe is selected or the profession window is opened
	if event == "SPELL_DATA_LOAD_RESULT" then
		-- Check if the Remove button should be disabled
		local function checkRemoveButton()
			-- Get selected recipe ID
			if pslSelectedRecipeID == nil then pslSelectedRecipeID = 0 end
			pslSelectedRecipeID = arg1

			-- Get recipeType
			pslRecipeType = C_TradeSkillUI.GetRecipeSchematic(pslSelectedRecipeID,false).recipeType
		
			-- 1 = Item | Normal behaviour
			if pslRecipeType == 1 then
				addCraftListButton:Enable()
			end

			-- 2 = Salvage | Disable these, cause they shouldn't be tracked
			if pslRecipeType == 2 then
				addCraftListButton:Disable()
				removeCraftListButton:Disable()
			end

			-- 3 = Enchant
			if pslRecipeType == 3 then
				addCraftListButton:Enable()
			end

			-- 4 = Recraft
			if pslRecipeType == 4 then
				addCraftListButton:Disable()
				removeCraftListButton:Disable()
			end
			
			-- Except that doesn't work, it just returns 1 >,> | Disable these, cause they shouldn't be tracked
			if pslSelectedRecipeID == 389195 -- Leatherworking 
			or pslSelectedRecipeID == 389190 -- Alchemy
			or pslSelectedRecipeID == 389192 -- Engineering
			or pslSelectedRecipeID == 389196 -- Tailoring
			or pslSelectedRecipeID == 389194 -- Jewelcrafting
			or pslSelectedRecipeID == 389193 -- Inscription
			or pslSelectedRecipeID == 385304 -- Blacksmithing
			or pslSelectedRecipeID == 389191 -- Enchanting
			then
				addCraftListButton:Disable()
				removeCraftListButton:Disable()
			end

			-- Check if recipe is tracked
			if not recipesTracked[pslSelectedRecipeID] then removeCraftListButton:Disable()
			elseif recipesTracked[pslSelectedRecipeID] == 0 then removeCraftListButton:Disable()
			else removeCraftListButton:Enable()
			end
		end
		checkRemoveButton()

		-- Show stuff depending on which profession is opened
		local skillLineID = C_TradeSkillUI.GetProfessionChildSkillLineID()
		local professionID = C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID).profession

		-- Knowledge Point Tracker
		local function setKnowledgePointTracker()
			-- Variables
			local configID = C_ProfSpecs.GetConfigIDForSkillLine(skillLineID)
			local specTabIDs = C_ProfSpecs.GetSpecTabIDsForSkillLine(skillLineID)

			-- Get all paths
			local pathCount = 0
			local pathIDs = {}
			for no, specTabID in pairs(specTabIDs) do
				pathCount = pathCount + 1
				local rootPathID = C_ProfSpecs.GetRootPathForTab(specTabID)
				pathIDs[pathCount] = rootPathID
				
				local childIDs = C_ProfSpecs.GetChildrenForPath(rootPathID)
				for no, childID in pairs (childIDs) do
					pathCount = pathCount + 1
					pathIDs[pathCount] = childID
					if C_ProfSpecs.GetChildrenForPath(childID)[1] == nil then else
						local childIDs = C_ProfSpecs.GetChildrenForPath(childID)
						for no, childID in pairs (childIDs) do
							pathCount = pathCount + 1
							pathIDs[pathCount] = childID
						end
					end
				end
			end

			-- Get all perks
			local perkCount = 0
			local perkIDs = {}
			for no, pathID in pairs (pathIDs) do
				local perks = C_ProfSpecs.GetPerksForPath(pathID)
				for no, perk in pairs (perks) do
					perkCount = perkCount + 1
					perkIDs[perkCount] = perk.perkID
				end
			end

			-- Get perk info
			local perksEarned = 0
			for no, perk in pairs (perkIDs) do
				if C_ProfSpecs.GetStateForPerk(perk, configID) == 2 then
					perksEarned = perksEarned + 1
				end
			end

			-- Get knowledge info
			local knowledgeSpent = 0
			local knowledgeMax = 0
			for _, pathID in ipairs(pathIDs) do
				local pathInfo = C_Traits.GetNodeInfo(C_ProfSpecs.GetConfigIDForSkillLine(skillLineID), pathID)
				knowledgeSpent = knowledgeSpent + (pathInfo.activeRank - 1)
				knowledgeMax = knowledgeMax + (pathInfo.maxRanks - 1)
			end

			-- Set text and progress, then show bar
			if userSettings["showKnowledgeNotPerks"] == true then
				knowledgePointTracker.Text:SetText(knowledgeSpent.."/"..knowledgeMax.." knowledge spent")
				knowledgePointTracker.Bar:SetMinMaxSmoothedValue(0, knowledgeMax)
				knowledgePointTracker.Bar:SetSmoothedValue(knowledgeSpent)
			else
				knowledgePointTracker.Text:SetText(perksEarned.."/"..perkCount.." perks unlocked")
				knowledgePointTracker.Bar:SetMinMaxSmoothedValue(0, perkCount)
				knowledgePointTracker.Bar:SetSmoothedValue(perksEarned)
			end
			knowledgePointTracker:Show()
			knowledgePointTracker:SetPropagateKeyboardInput(true) -- So keyboard presses can be done

			-- TODO: Use this recursive function where-ever it is smart to do it.
			-- -- Helper functions
			-- local appendChildPathIDsForRoot -- Declare this one before the function itself, otherwise it can't find the function to refer to within itself apparently
			-- appendChildPathIDsForRoot = function(t, pathID)
			-- 	t[pathID] = 1
			-- 	for _, childID in ipairs(C_ProfSpecs.GetChildrenForPath(pathID)) do
			-- 		appendChildPathIDsForRoot(t, childID)
			-- 	end
			-- 	print(pathID)
			-- end

			-- -- Get all profession specialisation paths
			-- local pathIDs = {}
			-- for _, specTabID in ipairs(C_ProfSpecs.GetSpecTabIDsForSkillLine(skillLineID)) do
			-- 	appendChildPathIDsForRoot(pathIDs, C_ProfSpecs.GetRootPathForTab(specTabID))
			-- end

			-- -- Check if the player has fully learned all profession specialisations
			-- local isProfSpecMax = true
			-- for _, pathID in ipairs(pathIDs) do
			-- 	local pathInfo = C_Traits.GetNodeInfo(C_ProfSpecs.GetConfigIDForSkillLine(skillLineID), pathID)
			-- 	if pathInfo.maxRanks ~= pathInfo.activeRank then isProfSpecMax = false end
			-- end
		end

		-- Knowledge Point Tooltip
		local treatiseItem
		local treatiseQuest
		local orderQuest
		local gatherQuests
		local craftQuests
		local drops
		local hiddenMaster
		local treasures
		local progress = true

		local function kpTooltip()
			-- Treatise
			local treatiseStatus = READY_CHECK_NOT_READY_TEXTURE
			local treatiseNumber = 0
			local derp, treatiseItemLink = GetItemInfo(treatiseItem)	-- TODO: Check if derp can be replaced with _ or not

			if treatiseQuest ~= nil then
				if C_QuestLog.IsQuestFlaggedCompleted(treatiseQuest) then
					treatiseStatus = READY_CHECK_READY_TEXTURE
					treatiseNumber = 1
				end

				if treatiseStatus == READY_CHECK_NOT_READY_TEXTURE then progress = false end
			end

			-- Crafting order quest
			local orderQuestStatus = READY_CHECK_NOT_READY_TEXTURE
			local orderQuestNumber = 0

			if orderQuest ~= nil then 
				if C_QuestLog.IsQuestFlaggedCompleted(orderQuest) then
					orderQuestStatus = READY_CHECK_READY_TEXTURE
					orderQuestNumber = 1
				end

				if orderQuestStatus == READY_CHECK_NOT_READY_TEXTURE then progress = false end
			end

			-- Gather quests
			local gatherQuestStatus = READY_CHECK_NOT_READY_TEXTURE
			local gatherQuestNumber = 0

			if gatherQuests ~= nil then
				for no, questID in pairs (gatherQuests) do
					if C_QuestLog.IsQuestFlaggedCompleted(questID) then
						gatherQuestStatus = READY_CHECK_READY_TEXTURE
						gatherQuestNumber = 1
					end
				end

				if gatherQuestStatus == READY_CHECK_NOT_READY_TEXTURE then progress = false end
			end

			-- Craft quests
			local craftQuestStatus = READY_CHECK_NOT_READY_TEXTURE
			local craftQuestNumber = 0

			if craftQuests ~= nil then
				for no, questID in pairs (craftQuests) do
					if C_QuestLog.IsQuestFlaggedCompleted(questID) then
						craftQuestNumber = 1
						craftQuestStatus = READY_CHECK_READY_TEXTURE
					end
				end

				if craftQuestStatus == READY_CHECK_NOT_READY_TEXTURE then progress = false end
			end

			-- Drops
			local dropsStatus = READY_CHECK_NOT_READY_TEXTURE
			local dropsNoCurrent = 0
			local dropsNoTotal = 0

			if drops ~= nil then
				for questID, itemID in pairs (drops) do
					if C_QuestLog.IsQuestFlaggedCompleted(questID) then
						dropsNoCurrent = dropsNoCurrent + 1
					end
					dropsNoTotal = dropsNoTotal + 1
				end

				if dropsNoCurrent == dropsNoTotal then
					dropsStatus = READY_CHECK_READY_TEXTURE
				end

				if dropsStatus == READY_CHECK_NOT_READY_TEXTURE then progress = false end
			end

			-- Dragon Shards
			local shardQuests = {67295, 69946, 69979, 67298}
			local shardStatus = READY_CHECK_NOT_READY_TEXTURE
			local shardNo = 0

			for no, questID in pairs (shardQuests) do	-- TODO: See if no can be replaced with _
				if C_QuestLog.IsQuestFlaggedCompleted(questID) then
					shardNo = shardNo + 1
				end
			end

			local derp, shardItemLink = GetItemInfo(191784)

			if shardNo == 4 then shardStatus = READY_CHECK_READY_TEXTURE end

			if shardStatus == READY_CHECK_NOT_READY_TEXTURE then progress = false end

			-- Hidden profession master
			local hiddenStatus = READY_CHECK_NOT_READY_TEXTURE
			local hiddenNumber = 0

			if hiddenMaster ~= nil then 
				if C_QuestLog.IsQuestFlaggedCompleted(hiddenMaster) then
					hiddenNumber = 1
					hiddenStatus = READY_CHECK_READY_TEXTURE
				end

				if hiddenStatus == READY_CHECK_NOT_READY_TEXTURE then progress = false end
			end

			-- Treasures
			local treasureStatus = READY_CHECK_NOT_READY_TEXTURE
			local treasureNoCurrent = 0
			local treasureNoTotal = 0

			if treasures ~= nil then
				for questID, itemID in pairs (treasures) do
					if C_QuestLog.IsQuestFlaggedCompleted(questID) then
						treasureNoCurrent = treasureNoCurrent + 1
					end
					treasureNoTotal = treasureNoTotal + 1
				end

				if treasureNoCurrent == treasureNoTotal then treasureStatus = READY_CHECK_READY_TEXTURE end

				if treasureStatus == READY_CHECK_NOT_READY_TEXTURE then progress = false end
			end

			-- If links missing, try again -- Hope this goes well with the new links x.x
			if shardItemLink == nil or treatiseItemLink == nil then
				RunNextFrame(kpTooltip)
				do return end
			end

			-- Set text
			local oldText
			if treatiseQuest ~= nil then
				knowledgePointTooltipText:SetText("Weekly:\n|cffFFFFFF".."|T"..treatiseStatus..":0|t "..treatiseNumber.."/1 "..treatiseItemLink)
			end

			if orderQuest ~= nil then
				oldText = knowledgePointTooltipText:GetText()
				knowledgePointTooltipText:SetText(oldText.."\n".."|T"..orderQuestStatus..":0|t "..orderQuestNumber.."/1 Crafting Orders quest")
			end

			if gatherQuests ~= nil then
				oldText = knowledgePointTooltipText:GetText()
				knowledgePointTooltipText:SetText(oldText.."\n".."|T"..gatherQuestStatus..":0|t "..gatherQuestNumber.."/1 Gather quest")
			end

			if craftQuests ~= nil then
				oldText = knowledgePointTooltipText:GetText()
				knowledgePointTooltipText:SetText(oldText.."\n".."|T"..craftQuestStatus..":0|t "..craftQuestNumber.."/1 Craft quest")
			end

			if drops ~= nil then
				oldText = knowledgePointTooltipText:GetText()
				knowledgePointTooltipText:SetText(oldText.."\n".."|T"..dropsStatus..":0|t "..dropsNoCurrent.."/"..dropsNoTotal.." Drops")
			end

			if IsModifierKeyDown() == true then
				for questID, itemID in pairs (drops) do
					oldText = knowledgePointTooltipText:GetText()
					local derp, itemLink = GetItemInfo(itemID)

					-- If links missing, try again
					if itemLink == nil then
						RunNextFrame(kpTooltip)
						do return end
					end

					if C_QuestLog.IsQuestFlaggedCompleted(questID) then
						knowledgePointTooltipText:SetText(oldText.."\n   ".."|T"..READY_CHECK_READY_TEXTURE..":0|t "..itemLink)
					else
						knowledgePointTooltipText:SetText(oldText.."\n   ".."|T"..READY_CHECK_NOT_READY_TEXTURE..":0|t "..itemLink)
					end
				end
			end

			oldText = knowledgePointTooltipText:GetText()
			knowledgePointTooltipText:SetText(oldText.."\n\n|cffFFD000One-time:\n".."|T"..shardStatus..":0|t ".."|cffFFFFFF"..shardNo.."/4 "..shardItemLink)
			
			if IsModifierKeyDown() == true then
				for no, questID in pairs (shardQuests) do
					oldText = knowledgePointTooltipText:GetText()
					local questTitle = C_QuestLog.GetTitleForQuestID(questID)

					-- If links missing, try again
					if questTitle == nil then
						RunNextFrame(kpTooltip)
						do return end
					end

					if C_QuestLog.IsQuestFlaggedCompleted(questID) then
						knowledgePointTooltipText:SetText(oldText.."\n   ".."|T"..READY_CHECK_READY_TEXTURE..":0|t ".."|cffffff00|Hquest:"..questID.."62|h["..questTitle.."]|h|r")
					else
						knowledgePointTooltipText:SetText(oldText.."\n   ".."|T"..READY_CHECK_NOT_READY_TEXTURE..":0|t ".."|cffffff00|Hquest:"..questID.."62|h["..questTitle.."]|h|r")
					end
				end
			end

			oldText = knowledgePointTooltipText:GetText()
			knowledgePointTooltipText:SetText(oldText.."\n".."|T"..hiddenStatus..":0|t "..hiddenNumber.."/1 Hidden profession master")

			if treasures ~= nil then
				oldText = knowledgePointTooltipText:GetText()
				knowledgePointTooltipText:SetText(oldText.."\n".."|T"..treasureStatus..":0|t "..treasureNoCurrent.."/"..treasureNoTotal.." Treasures")

				if IsModifierKeyDown() == true then
					for questID, itemID in pairs (treasures) do
						oldText = knowledgePointTooltipText:GetText()
						local derp, itemLink = GetItemInfo(itemID)
	
						-- If links missing, try again
						if itemLink == nil then
							RunNextFrame(kpTooltip)
							do return end
						end
	
						if C_QuestLog.IsQuestFlaggedCompleted(questID) then
							knowledgePointTooltipText:SetText(oldText.."\n   ".."|T"..READY_CHECK_READY_TEXTURE..":0|t "..itemLink)
						else
							knowledgePointTooltipText:SetText(oldText.."\n   ".."|T"..READY_CHECK_NOT_READY_TEXTURE..":0|t "..itemLink)
						end
					end
				end
			end

			oldText = knowledgePointTooltipText:GetText()
			if IsModifierKeyDown() == false then knowledgePointTooltipText:SetText(oldText.."\n\n|cffFFD000Press Alt, Ctrl, or Shift to show details.") end

			-- Set the tooltip size to fit its contents
			knowledgePointTooltip:SetHeight(knowledgePointTooltipText:GetStringHeight()+20)
			knowledgePointTooltip:SetWidth(knowledgePointTooltipText:GetStringWidth()+20)

			-- Make progress bar green if everything is done
			if progress == true then
				knowledgePointTracker.Bar:SetStatusBarColor(0, 1, 0)
			else
				knowledgePointTracker.Bar:SetStatusBarColor(1, .5, 0)
			end
		end

		-- Refresh and show the tooltip on mouse-over
		knowledgePointTracker:SetScript("OnEnter", function()
			kpTooltip()
			knowledgePointTooltip:Show()
		end)

		-- Refresh the tooltip on key down (to check for IsModifierKeyDown)
		knowledgePointTracker:SetScript("OnKeyDown", function()
			kpTooltip()
		end)

		-- Refresh the tooltip on key up (to check for IsModifierKeyDown)
		knowledgePointTracker:SetScript("OnKeyUp", function()
			kpTooltip()
		end)

		-- Blacksmithing
		if professionID == 1 then
			treatiseItem = 198454
			treatiseQuest = 74109
			orderQuest = 70589
			gatherQuests = {66517, 66897, 66941, 72398}
			craftQuests = {70211, 70233, 70234, 70235 }
			hiddenMaster = 70250
			drops = {}
			drops[66381] = 192131
			drops[66382] = 192132
			drops[70512] = 198965
			drops[70513] = 198966
			treasures = {}
			treasures[70230] = 198791
			treasures[70246] = 201007
			treasures[70296] = 201008
			treasures[70310] = 201010
			treasures[70311] = 201006
			treasures[70312] = 201005
			treasures[70313] = 201004
			treasures[70314] = 201011
			treasures[70353] = 201009
		end

		-- Leatherworking
		if professionID == 2 then
			treatiseItem = 194700
			treatiseQuest = 74113
			orderQuest = 70594
			gatherQuests = {66363, 66364, 66951, 72407}
			craftQuests = {70567, 70568, 70569, 70571}
			hiddenMaster = 70256
			drops = {}
			drops[66384] = 193910
			drops[66385] = 193913
			drops[70522] = 198975
			drops[70523] = 198976
			treasures = {}
			treasures[70266] = 198658
			treasures[70269] = 201018
			treasures[70280] = 198667
			treasures[70286] = 198683
			treasures[70294] = 198690
			treasures[70300] = 198696
			treasures[70308] = 198711
		end

		-- Alchemy
		if professionID == 3 then
			treatiseItem = 194697
			treatiseQuest = 74108
			orderQuest = nil
			gatherQuests = {66937, 66938, 66940, 72427}
			craftQuests = {70530, 70531, 70532, 70533}
			hiddenMaster = 70247
			drops = {}
			drops[66373] = 193891
			drops[66374] = 193897
			drops[70504] = 198963
			drops[70511] = 198964
			treasures = {}
			treasures[70208] = 198599
			treasures[70274] = 198663
			treasures[70278] = 201003
			treasures[70289] = 198685
			treasures[70301] = 198697
			treasures[70305] = 198710
			treasures[70309] = 198712
		end

		-- Herbalism
		if professionID == 4 then
			treatiseItem = 194704
			treatiseQuest = 74107
			orderQuest = nil
			gatherQuests = {70613, 70614, 70615, 70616}
			craftQuests = nil
			hiddenMaster = 70253
			drops = {}
			drops[71857] = 200677
			drops[71858] = 200677
			drops[71859] = 200677
			drops[71860] = 200677
			drops[71861] = 200677
			drops[71864] = 200678			
			treasures = nil
		end

		-- Cooking
		if professionID == 5 and PlayerHasToy(134020) then
			chefsHatButton:Show()
		else
			chefsHatButton:Hide()
		end

		-- Mining
		if professionID == 6 then
			treatiseItem = 194708
			treatiseQuest = 74106
			orderQuest = nil
			gatherQuests = {70617, 70618, 72156, 72157}
			craftQuests = nil
			hiddenMaster = 70258
			drops = {}
			drops[72160] = 201300
			drops[72161] = 201300
			drops[72162] = 201300
			drops[72163] = 201300
			drops[72164] = 201300
			drops[72165] = 201301
			treasures = nil
		end

		-- Tailoring
		if professionID == 7 then
			treatiseItem = 194698
			treatiseQuest = 74115
			orderQuest = 70595
			gatherQuests = {66899, 66952, 66953, 72410}
			craftQuests = {70572, 70582, 70586, 70587}
			hiddenMaster = 70260
			drops = {}
			drops[66386] = 193898
			drops[66387] = 193899
			drops[70524] = 198977
			drops[70525] = 198978
			treasures = {}
			treasures[70267] = 198662
			treasures[70284] = 198680
			treasures[70288] = 198684
			treasures[70295] = 198692
			treasures[70302] = 198699
			treasures[70303] = 201020
			treasures[70304] = 198702
			treasures[70372] = 201019
		end

		-- Engineering
		if professionID == 8 then
			treatiseItem = 198510
			treatiseQuest = 74111
			orderQuest = 70591
			gatherQuests = {66890, 66891, 66942, 72396}
			craftQuests = {70539, 70540, 70545, 70557}
			hiddenMaster = 70252
			drops = {}
			drops[66379] = 193902
			drops[66380] = 193903
			drops[70516] = 198969
			drops[70517] = 198970
			treasures = {}
			treasures[70270] = 201014
			treasures[70275] = 198789
		end

		-- Enchanting
		if professionID == 9 then
			treatiseItem = 194702
			treatiseQuest = 74110
			orderQuest = nil
			gatherQuests = {66884, 66900, 66935, 72423}
			craftQuests = {72155, 72172, 72173, 72175}
			hiddenMaster = 70251
			drops = {}
			drops[66377] = 193900
			drops[66378] = 193901
			drops[70514] = 198967
			drops[70515] = 198968
			treasures = {}
			treasures[70272] = 201012
			treasures[70283] = 198675
			treasures[70290] = 201013
			treasures[70291] = 198689
			treasures[70298] = 198694
			treasures[70320] = 198798
			treasures[70336] = 198799
			treasures[70342] = 198800
		end

		-- Skinning
		if professionID == 11 then
			treatiseItem = 201023
			treatiseQuest = 74114
			orderQuest = nil
			gatherQuests = {70619, 70620, 72158, 72159}
			craftQuests = nil
			hiddenMaster = 70259
			drops = {}
			drops[70381] = 198837
			drops[70383] = 198837
			drops[70384] = 198837
			drops[70385] = 198837
			drops[70386] = 198837
			drops[70389] = 198841
			treasures = nil
		end

		-- Jewelcrafting
		if professionID == 12 then
			treatiseItem = 194703
			treatiseQuest = 74112
			orderQuest = 70593
			gatherQuests = {66516, 66949, 66950, 72428}
			craftQuests = {70562, 70563, 70564, 70565}
			hiddenMaster = 70255
			drops = {}
			drops[66388] = 193909
			drops[66389] = 193907
			drops[70520] = 198973
			drops[70521] = 198974
			treasures = {}
			treasures[70273] = 201017
			treasures[70292] = 198687
			treasures[70271] = 201016
			treasures[70277] = 198664
			treasures[70282] = 198670
			treasures[70263] = 198660
			treasures[70261] = 198656
			treasures[70285] = 198682
		end

		-- Inscription
		if professionID == 13 then
			treatiseItem = 194699
			treatiseQuest = 74105
			orderQuest = 70592
			gatherQuests = {66943, 66944, 66945}
			craftQuests = {70558, 70559, 70560, 70561}
			hiddenMaster = 70254
			drops = {}
			drops[66375] = 193904
			drops[66376] = 193905
			drops[70518] = 198971
			drops[70519] = 198972
			treasures = {}
			treasures[70248] = 198659
			treasures[70264] = 198659
			treasures[70281] = 198669
			treasures[70287] = 201015
			treasures[70293] = 198686
			treasures[70297] = 198693
			treasures[70306] = 198704
			treasures[70307] = 198703
		end

		-- Professions with Knowledge Points
		if professionID == 1
		or professionID == 2
		or professionID == 3
		or professionID == 4
		or professionID == 6
		or professionID == 7
		or professionID == 8
		or professionID == 9
		or professionID == 11
		or professionID == 12
		or professionID == 13 then
			setKnowledgePointTracker() 
			kpTooltip()
		else
			knowledgePointTracker:Hide()
		end
	end
	
	-- Do stuff when a profession window is loaded
	if event == "TRADE_SKILL_LIST_UPDATE" then
		-- Register all recipes for this profession
		for _, id in pairs(C_TradeSkillUI.GetAllRecipeIDs()) do
			local itemID = C_TradeSkillUI.GetRecipeOutputItemData(id).itemID
			if itemID ~= nil then recipeLibrary[id] = itemID end
		end
	end

	-- Remove 1 tracked recipe when it has been crafted
	if event == "UNIT_SPELLCAST_SUCCEEDED" and userSettings["removeCraft"] == true then
		-- Get selected recipeID
		local recipeID = ...

		if recipesTracked[recipeID] ~= nil then
			-- Untrack recipe
			recipesTracked[recipeID] = recipesTracked[recipeID] - 1
		
			-- Set numbers to nil if it doesn't exist anymore
			if recipesTracked[recipeID] == 0 then recipesTracked[recipeID] = nil end
		
			-- Disable the remove button if the recipe isn't tracked anymore
			if not recipesTracked[recipeID] then removeCraftListButton:Disable() end
		
			-- Update numbers
			pslReagents()

			-- Close windows if no recipes are left and the option is enabled
			local next = next
			if next(recipesTracked) == nil and userSettings["closeWhenDone"] == true then
				pslFrame1:Hide()
				pslFrame2:Hide()
			end
		end
	end

	-- Update the numbers when bag changes occur
	if event == "BAG_UPDATE" then
		pslReagents()
	end

	-- Set the Vendor filter to 'All' if the option is enabled
	if event == "MERCHANT_SHOW" and userSettings["vendorAll"] == true then
		RunNextFrame(function()
			SetMerchantFilter(1)
			MerchantFrame_Update()
		end)
	end
end)