-- Initialise some stuff
local api = CreateFrame("Frame")	-- To register API events
local ScrollingTable = LibStub("ScrollingTable")	-- To refer to the ScrollingTable library
if not C_TradeSkillUI then UIParentLoadAddOn("C_TradeSkillUI") end	-- To refer to the TradeSkillUI
if not Blizzard_ProfessionsCustomerOrders then UIParentLoadAddOn("Blizzard_ProfessionsCustomerOrders") end	-- To refer to the ProfessionsCustomerOrders

-- API Events
api:RegisterEvent("ADDON_LOADED")
api:RegisterEvent("BAG_UPDATE")
api:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
api:RegisterEvent("TRADE_SKILL_SHOW")
api:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
api:RegisterEvent("SPELL_DATA_LOAD_RESULT")
api:RegisterEvent("MERCHANT_SHOW")
api:RegisterEvent("CRAFTINGORDERS_CLAIM_ORDER_RESPONSE")
api:RegisterEvent("CRAFTINGORDERS_RELEASE_ORDER_RESPONSE")
api:RegisterEvent("CRAFTINGORDERS_FULFILL_ORDER_RESPONSE")

-- Might as well keep this in here, it's useful
local function dump(o)
	if type(o) == 'table' then
		local s = '{ '
		for k,v in pairs(o) do
			if type(k) ~= 'number' then k = '"'..k..'"' end
			s = s .. '['..k..'] = ' .. dump(v) .. ','
		end
	return s .. '} '
	else
		return tostring(o)
	end
end

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

-- Create or update the tracking windows
function pslTrackingWindows()
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

-- Get reagents for recipe
function pslGetReagents(reagentVariable, recipeID, recipeQuantity, qualityTier)
	-- Grab all the reagent info from the API
	local reagentsTable = C_TradeSkillUI.GetRecipeSchematic(recipeID, false).reagentSlotSchematics

	-- Check which quality to use
	local reagentQuality = qualityTier or userSettings["reagentQuality"]

	-- For every reagent, do
	for numReagent, reagentInfo in pairs(reagentsTable) do
		-- Only check basic reagents, not optional or finishing reagents
		if reagentInfo.reagentType == 1 then
			-- Get (quality tier 1) info
			local reagentID
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

			-- Add the different reagent tiers into reagentTiers so they can be queried later
			-- No need to check if they already exist, we can just overwrite it
			reagentTiers[reagentID1] = {one = reagentID1, two = reagentID2, three = reagentID3}
			reagentTiers[reagentID2] = {one = reagentID1, two = reagentID2, three = reagentID3}
			reagentTiers[reagentID3] = {one = reagentID1, two = reagentID2, three = reagentID3}

			-- Remove reagentTiers[0]
			if reagentTiers[0] then reagentTiers[0] = nil end

			-- Check which quality reagent to use
			if reagentQuality == 3 and reagentID3 ~= 0 then
				reagentID = reagentID3
			elseif reagentQuality == 2 and reagentID2 ~= 0 then
				reagentID = reagentID2
			else
				reagentID = reagentID1
			end

			-- Add the info to the specified variable
			if reagentVariable[reagentID] == nil then reagentVariable[reagentID] = 0 end
			reagentVariable[reagentID] = reagentVariable[reagentID] + ( reagentAmount * recipeQuantity )
		end
	end
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
		pslGetReagents(reagentsTracked, recipeID, no)
	end

	-- Update reagents tracked
	local data = {}

	for reagentID, amount in pairs(reagentsTracked) do
		local function getInfo()
			-- Get info
			local itemName, itemLink
			itemName, itemLink = GetItemInfo(reagentID)

			-- Try again if error
			if itemName == nil or itemLink == nil then
				RunNextFrame(getInfo)
				do return end
			end

			-- Get needed/owned number of reagents
			local reagentAmountHave1 = 0
			local reagentAmountHave2 = 0
			local reagentAmountHave3 = 0

			reagentAmountHave1 = GetItemCount(reagentTiers[reagentID].one, true, false, true)
			if reagentTiers[reagentID].two ~= 0 then
				local reagentAmountHave2 = GetItemCount(reagentTiers[reagentID].two, true, false, true)
			end
			if reagentTiers[reagentID].three ~= 0 then
				local reagentAmountHave3 = GetItemCount(reagentTiers[reagentID].three, true, false, true)
			end

			-- Calculate owned amount based on user setting for reagent quality
			local reagentAmountHave = 0
			if userSettings["reagentQuality"] == 1 then
				reagentAmountHave = reagentAmountHave1 + reagentAmountHave2 + reagentAmountHave3
			elseif userSettings["reagentQuality"] == 2  then
				reagentAmountHave = reagentAmountHave2 + reagentAmountHave3
			elseif userSettings["reagentQuality"] == 3 then
				reagentAmountHave = reagentAmountHave3
			end
			
			-- Push the info to the windows
			if userSettings["showRemaining"] == false then
				table.insert(data, {itemLink, reagentAmountHave.."/"..amount})
			else
				table.insert(data, {itemLink, math.max(0,amount-reagentAmountHave)})
			end

			table1:SetData(data, true)
		end
		getInfo()
	end
	table1:SetData(data, true)

	-- Check if the Untrack button should be enabled
	if not recipesTracked[pslSelectedRecipeID] or recipesTracked[pslSelectedRecipeID] == 0 then
		untrackProfessionButton:Disable()
		untrackPlaceOrderButton:Disable()
		untrackMakeOrderButton:Disable()
	else
		untrackProfessionButton:Enable()
		untrackPlaceOrderButton:Enable()
		untrackMakeOrderButton:Enable()
	end

	-- Check if the making crafting orders Untrack button should be enabled
	if pslOrderRecipeID ~= 0 then
		if not recipesTracked[pslOrderRecipeID] or recipesTracked[pslOrderRecipeID] == 0 then
			untrackMakeOrderButton:Disable()
		else
			untrackMakeOrderButton:Enable()
		end
	end
end

-- Track recipe
function pslTrackRecipe(recipeID, recipeQuantity)
	-- Track recipe
	if not recipesTracked[recipeID] then recipesTracked[recipeID] = 0 end
	recipesTracked[recipeID] = recipesTracked[recipeID] + recipeQuantity

	local recipeType = C_TradeSkillUI.GetRecipeSchematic(recipeID,false).recipeType
	-- Add recipe link for crafted items
	if recipeType == 1 then
		local link = string.gsub(C_TradeSkillUI.GetRecipeOutputItemData(recipeID).hyperlink, " |A:Professions%-ChatIcon%-Quality%-Tier1:17:15::1|a", "") --" |A:Professions-ChatIcon-Quality-Tier1:17:15::1|a"
		recipeLinks[recipeID] = link
	-- Add recipe "link" for enchants
	elseif recipeType == 3 then recipeLinks[recipeID] = C_TradeSkillUI.GetRecipeSchematic(recipeID,false).name
	end

	-- Show windows
	pslFrame1:Show()
	pslFrame2:Show()

	-- Update numbers
	pslReagents()
end

-- Untrack recipe
function pslUntrackRecipe(recipeID, recipeQuantity)
	if recipesTracked[recipeID] ~= nil then
		-- Untrack recipe
		recipesTracked[recipeID] = recipesTracked[recipeID] - recipeQuantity
	
		-- Set numbers to nil if it doesn't exist anymore
		if recipesTracked[recipeID] <= 0 then
			recipesTracked[recipeID] = nil
			recipeLinks[recipeID] = nil
		end
	
		-- Update numbers
		pslReagents()
	end
end

-- Create assets
function pslCreateAssets()
	-- Hide and disable existing tracking buttons
	ProfessionsFrame.CraftingPage.SchematicForm.TrackRecipeCheckBox:SetAlpha(0)
	ProfessionsFrame.CraftingPage.SchematicForm.TrackRecipeCheckBox:EnableMouse(false)
	ProfessionsCustomerOrdersFrame.Form.TrackRecipeCheckBox:SetAlpha(0)
	ProfessionsCustomerOrdersFrame.Form.TrackRecipeCheckBox:EnableMouse(false)

	-- Create the profession UI track button
	if not trackProfessionButton then
		trackProfessionButton = CreateFrame("Button", nil, ProfessionsFrame.CraftingPage, "UIPanelButtonTemplate")
		trackProfessionButton:SetText("Track")
		trackProfessionButton:SetWidth(60)
		trackProfessionButton:SetPoint("TOPRIGHT", ProfessionsFrame.CraftingPage.SchematicForm, "TOPRIGHT", -9, -10)
		trackProfessionButton:SetFrameStrata("HIGH")
		trackProfessionButton:SetScript("OnClick", function()
			pslTrackRecipe(pslSelectedRecipeID, 1)
		end)
	end

	-- Create the profession UI untrack button
	if not untrackProfessionButton then
		untrackProfessionButton = CreateFrame("Button", nil, ProfessionsFrame.CraftingPage, "UIPanelButtonTemplate")
		untrackProfessionButton:SetText("Untrack")
		untrackProfessionButton:SetWidth(70)
		untrackProfessionButton:SetPoint("TOPRIGHT", trackProfessionButton, "TOPLEFT", -4, 0)
		untrackProfessionButton:SetFrameStrata("HIGH")
		untrackProfessionButton:SetScript("OnClick", function()
			pslUntrackRecipe(pslSelectedRecipeID, 1)
	
			-- Show windows
			pslFrame1:Show()
			pslFrame2:Show()
		end)
	end

	-- Create the place crafting orders UI Track button
	if not trackPlaceOrderButton then
		trackPlaceOrderButton = CreateFrame("Button", nil, ProfessionsCustomerOrdersFrame.Form, "UIPanelButtonTemplate")
		trackPlaceOrderButton:SetText("Track")
		trackPlaceOrderButton:SetWidth(60)
		trackPlaceOrderButton:SetPoint("TOPLEFT", ProfessionsCustomerOrdersFrame.Form, "TOPLEFT", 12, -73)
		trackPlaceOrderButton:SetFrameStrata("HIGH")
		trackPlaceOrderButton:SetScript("OnClick", function()
			pslTrackRecipe(pslSelectedRecipeID, 1)
		end)
	end

	-- Create the place crafting orders UI untrack button
	if not untrackPlaceOrderButton then
		untrackPlaceOrderButton = CreateFrame("Button", nil, ProfessionsCustomerOrdersFrame.Form, "UIPanelButtonTemplate")
		untrackPlaceOrderButton:SetText("Untrack")
		untrackPlaceOrderButton:SetWidth(70)
		untrackPlaceOrderButton:SetPoint("TOPLEFT", trackPlaceOrderButton, "TOPRIGHT", 0, 0)
		untrackPlaceOrderButton:SetFrameStrata("HIGH")
		untrackPlaceOrderButton:SetScript("OnClick", function()
			pslUntrackRecipe(pslSelectedRecipeID, 1)
	
			-- Show windows
			pslFrame1:Show()
			pslFrame2:Show()
		end)
	end

	-- Create the fulfil crafting orders UI Track button
	if not trackMakeOrderButton then
		trackMakeOrderButton = CreateFrame("Button", nil, ProfessionsFrame.OrdersPage.OrderView.OrderDetails, "UIPanelButtonTemplate")
		trackMakeOrderButton:SetText("Track")
		trackMakeOrderButton:SetWidth(60)
		trackMakeOrderButton:SetPoint("TOPRIGHT", ProfessionsFrame.OrdersPage.OrderView.OrderDetails, "TOPRIGHT", -9, -10)
		trackMakeOrderButton:SetFrameStrata("HIGH")
		trackMakeOrderButton:SetScript("OnClick", function()
			if pslOrderRecipeID == 0 then
				pslTrackRecipe(pslSelectedRecipeID, 1)
			else
				pslTrackRecipe(pslOrderRecipeID, 1)
			end

			-- Show windows
			pslFrame1:Show()
			pslFrame2:Show()
		end)
	end

	-- Create the fulfil crafting orders UI untrack button
	if not untrackMakeOrderButton then
		untrackMakeOrderButton = CreateFrame("Button", nil, ProfessionsFrame.OrdersPage.OrderView.OrderDetails, "UIPanelButtonTemplate")
		untrackMakeOrderButton:SetText("Untrack")
		untrackMakeOrderButton:SetWidth(70)
		untrackMakeOrderButton:SetPoint("TOPRIGHT", trackMakeOrderButton, "TOPLEFT", -4, 0)
		untrackMakeOrderButton:SetFrameStrata("HIGH")
		untrackMakeOrderButton:SetScript("OnClick", function()
			if pslOrderRecipeID == 0 then
				pslUntrackRecipe(pslSelectedRecipeID, 1)
			else
				pslUntrackRecipe(pslOrderRecipeID, 1)
			end

			-- Show windows
			pslFrame1:Show()
			pslFrame2:Show()
		end)
	end

	-- Initialise this variable for the MakeOrderButtons
	if not pslOrderRecipeID then pslOrderRecipeID = 0 end

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
		local reagentAmountHave1 = 0
		local reagentAmountHave2 = 0
		local reagentAmountHave3 = 0
	
		-- Get needed/owned number of reagents
		if reagentTiers[itemID] and reagentTiers[itemID].one ~= 0 then
			reagentID1 = reagentTiers[itemID].one
			reagentAmountHave1 = GetItemCount(reagentTiers[itemID].one, true, false, true)
		end
		if reagentTiers[itemID] and reagentTiers[itemID].two ~= 0 then
			reagentID2 = reagentTiers[itemID].two
			reagentAmountHave2 = GetItemCount(reagentTiers[itemID].two, true, false, true)
		end
		if reagentTiers[itemID] and reagentTiers[itemID].three ~= 0 then
			reagentID3 = reagentTiers[itemID].three
			reagentAmountHave3 = GetItemCount(reagentTiers[itemID].three, true, false, true)
		end

		-- Calculate owned amount based on user setting for reagent quality
		local reagentAmountHave = 0
		if userSettings["reagentQuality"] == 1 then
			reagentAmountHave = reagentAmountHave1 + reagentAmountHave2 + reagentAmountHave3
		elseif userSettings["reagentQuality"] == 2  then
			reagentAmountHave = reagentAmountHave2 + reagentAmountHave3
		elseif userSettings["reagentQuality"] == 3 then
			reagentAmountHave = reagentAmountHave3
		end

		local reagentAmountNeed = 0
		if userSettings["reagentQuality"] == 1 then
			reagentAmountNeed = reagentsTracked[reagentID1]
		end
		if userSettings["reagentQuality"] == 2 then
			reagentAmountNeed = reagentsTracked[reagentID2]
		end
		if userSettings["reagentQuality"] == 3 then
			reagentAmountNeed = reagentsTracked[reagentID3]
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

api:SetScript("OnEvent", function(self, event, arg1, arg2, ...)
	-- When the AddOn is fully loaded, actually run the components
	if event == "ADDON_LOADED" and arg1 == "ProfessionShoppingList" then
		pslInitialise()
		pslTrackingWindows()
		pslCreateAssets()
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
			slReagentQuality.Low:SetText("|A:Professions-ChatIcon-Quality-Tier1:17:15::1|a")
			slReagentQuality.High:SetText("|A:Professions-ChatIcon-Quality-Tier3:17:15::1|a")
			slReagentQuality.Text:SetText("Minimum reagent quality")
			slReagentQuality:SetValue(userSettings["reagentQuality"])
			slReagentQuality.Label = slReagentQuality:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
			slReagentQuality.Label:SetPoint("TOP", slReagentQuality, "BOTTOM", 0, 0)
			slReagentQuality.Label:SetText("|A:Professions-ChatIcon-Quality-Tier"..slReagentQuality:GetValue()..":17:15::1|a")
			slReagentQuality:SetScript("OnValueChanged", function(self, newValue)
				userSettings["reagentQuality"] = newValue
				self:SetValue(userSettings["reagentQuality"])
				self.Label:SetText("|A:Professions-ChatIcon-Quality-Tier"..slReagentQuality:GetValue()..":17:15::1|a")
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
				pslTrackingWindows()
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
				pslTrackingWindows()
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
				pslTrackingWindows()
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
				pslTrackingWindows()
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
				pslTrackingWindows()
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
				pslTrackingWindows()
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
				-- Clear everything except the recipe cache
				recipesTracked = {}
				reagentsTracked = {}
				recipeLinks = {}
				reagentTiers = {}
				pslReagents()

				-- Disable remove button
				untrackProfessionButton:Disable()
				untrackPlaceOrderButton:Disable()
				untrackMakeOrderButton:Disable()

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
					-- Control+click on reagent
					if column == 1 and button == "LeftButton" and IsControlKeyDown() == true and realrow ~= nil then
						-- Get itemIDs
						local itemID = GetItemInfoFromHyperlink(data[realrow][1])
						if reagentTiers[itemID] then itemID = reagentTiers[itemID].one end

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
							pslTrackRecipe(recipeIDs[no], 1)
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
							local reagentsTable = {}
							pslGetReagents(reagentsTable, recipeIDs[1], 1)

							-- Create text #1
							for reagentID, reagentAmount in pairs(reagentsTable) do
								-- Get info
								local function getInfo()
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

							-- Button #1
							pslOptionButton1 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
							pslOptionButton1:SetText(C_TradeSkillUI.GetRecipeSchematic(recipeIDs[1], false).name)
							pslOptionButton1:SetWidth(200)
							pslOptionButton1:SetPoint("BOTTOM", pslOption1, "TOP", 0, 5)
							pslOptionButton1:SetPoint("CENTER", pslOption1, "CENTER", 0, 0)
							pslOptionButton1:SetScript("OnClick", function()
								-- Define the amount of recipes to be tracked
								local quantityMade = C_TradeSkillUI.GetRecipeSchematic(recipeIDs[1], false).quantityMin
								local amount = math.max(0, math.ceil(reagentsTracked[itemID] / quantityMade) - GetItemCount(itemID))

								-- Track the recipe(s)
								pslTrackRecipe(recipeIDs[1], amount)

								-- Hide the subreagents window
								f:Hide()
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
								local reagentsTable = {}
								pslGetReagents(reagentsTable, recipeIDs[2], 1)

								-- Create text #2
								for reagentID, reagentAmount in pairs(reagentsTable) do
									-- Get info
									local function getInfo()
										local itemName, itemLink = GetItemInfo(reagentID)

										-- Try again if error
										if itemName == nil or itemLink == nil then
											RunNextFrame(getInfo)
											do return end
										end

										-- Add text
										oldText = pslOption1:GetText()
										pslOption2:SetText(oldText..reagentAmount.."x "..itemLink.."\n")
									end
									getInfo()
								end

								-- Button #2
								pslOptionButton2 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
								pslOptionButton2:SetText(C_TradeSkillUI.GetRecipeSchematic(recipeIDs[2], false).name)
								pslOptionButton2:SetWidth(200)
								pslOptionButton2:SetPoint("BOTTOM", pslOption2, "TOP", 0, 5)
								pslOptionButton2:SetPoint("CENTER", pslOption2, "CENTER", 0, 0)
								pslOptionButton2:SetScript("OnClick", function()
									-- Define the amount of recipes to be tracked
									local quantityMade = C_TradeSkillUI.GetRecipeSchematic(recipeIDs[2], false).quantityMin
									local amount = math.max(0, math.ceil(reagentsTracked[itemID] / quantityMade) - GetItemCount(itemID))

									-- Track the recipe(s)
									pslTrackRecipe(recipeIDs[2], amount)

									-- Hide the subreagents window
									f:Hide()
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
								local reagentsTable = {}
								pslGetReagents(reagentsTable, recipeIDs[3], 1)

								-- Create text #3
								for reagentID, reagentAmount in pairs(reagentsTable) do
									-- Get info
									local function getInfo()
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

								-- Button #3
								pslOptionButton3 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
								pslOptionButton3:SetText(C_TradeSkillUI.GetRecipeSchematic(recipeIDs[3], false).name)
								pslOptionButton3:SetWidth(200)
								pslOptionButton3:SetPoint("BOTTOM", pslOption3, "TOP", 0, 5)
								pslOptionButton3:SetPoint("CENTER", pslOption3, "CENTER", 0, 0)
								pslOptionButton3:SetScript("OnClick", function()
									-- Define the amount of recipes to be tracked
									local quantityMade = C_TradeSkillUI.GetRecipeSchematic(recipeIDs[3], false).quantityMin
									local amount = math.max(0, math.ceil(reagentsTracked[itemID] / quantityMade) - GetItemCount(itemID))

									-- Track the recipe(s)
									pslTrackRecipe(recipeIDs[3], amount)

									-- Hide the subreagents window
									f:Hide()
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
								local reagentsTable = {}
								pslGetReagents(reagentsTable, recipeIDs[4], 1)

								-- Create text #4
								for reagentID, reagentAmount in pairs(reagentsTable) do
									-- Get info
									local function getInfo()
										local itemName, itemLink = GetItemInfo(reagentID)

										-- Try again if error
										if itemName == nil or itemLink == nil then
											RunNextFrame(getInfo)
											do return end
										end

										-- Add text
										oldText = pslOption1:GetText()
										pslOption4:SetText(oldText..reagentAmount.."x "..itemLink.."\n")
									end
									getInfo()
								end

								-- Button #4
								pslOptionButton4 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
								pslOptionButton4:SetText(C_TradeSkillUI.GetRecipeSchematic(recipeIDs[4], false).name)
								pslOptionButton4:SetWidth(200)
								pslOptionButton4:SetPoint("BOTTOM", pslOption4, "TOP", 0, 5)
								pslOptionButton4:SetPoint("CENTER", pslOption4, "CENTER", 0, 0)
								pslOptionButton4:SetScript("OnClick", function()
									-- Define the amount of recipes to be tracked
									local quantityMade = C_TradeSkillUI.GetRecipeSchematic(recipeIDs[4], false).quantityMin
									local amount = math.max(0, math.ceil(reagentsTracked[itemID] / quantityMade) - GetItemCount(itemID))

									-- Track the recipe(s)
									pslTrackRecipe(recipeIDs[4], amount)

									-- Hide the subreagents window
									f:Hide()
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
								local reagentsTable = {}
								pslGetReagents(reagentsTable, recipeIDs[5], 1)

								-- Create text #5
								for reagentID, reagentAmount in pairs(reagentsTable) do
									-- Get info
									local function getInfo()
										local itemName, itemLink = GetItemInfo(reagentID)

										-- Try again if error
										if itemName == nil or itemLink == nil then
											RunNextFrame(getInfo)
											do return end
										end

										-- Add text
										oldText = pslOption1:GetText()
										pslOption5:SetText(oldText..reagentAmount.."x "..itemLink.."\n")
									end
									getInfo()
								end

								-- Button #5
								pslOptionButton5 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
								pslOptionButton5:SetText(C_TradeSkillUI.GetRecipeSchematic(recipeIDs[5], false).name)
								pslOptionButton5:SetWidth(200)
								pslOptionButton5:SetPoint("BOTTOM", pslOption5, "TOP", 0, 5)
								pslOptionButton5:SetPoint("CENTER", pslOption5, "CENTER", 0, 0)
								pslOptionButton5:SetScript("OnClick", function()
									-- Define the amount of recipes to be tracked
									local quantityMade = C_TradeSkillUI.GetRecipeSchematic(recipeIDs[5], false).quantityMin
									local amount = math.max(0, math.ceil(reagentsTracked[itemID] / quantityMade) - GetItemCount(itemID))

									-- Track the recipe(s)
									pslTrackRecipe(recipeIDs[5], amount)

									-- Hide the subreagents window
									f:Hide()
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
								local reagentsTable = {}
								pslGetReagents(reagentsTable, recipeIDs[6], 1)

								-- Create text #6
								for reagentID, reagentAmount in pairs(reagentsTable) do
									-- Get info
									local function getInfo()
										local itemName, itemLink = GetItemInfo(reagentID)

										-- Try again if error
										if itemName == nil or itemLink == nil then
											RunNextFrame(getInfo)
											do return end
										end

										-- Add text
										oldText = pslOption1:GetText()
										pslOption6:SetText(oldText..reagentAmount.."x "..itemLink.."\n")
									end
									getInfo()
								end

								-- Button #6
								pslOptionButton6 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
								pslOptionButton6:SetText(C_TradeSkillUI.GetRecipeSchematic(recipeIDs[6], false).name)
								pslOptionButton6:SetWidth(200)
								pslOptionButton6:SetPoint("BOTTOM", pslOption6, "TOP", 0, 5)
								pslOptionButton6:SetPoint("CENTER", pslOption6, "CENTER", 0, 0)
								pslOptionButton6:SetScript("OnClick", function()
									-- Define the amount of recipes to be tracked
									local quantityMade = C_TradeSkillUI.GetRecipeSchematic(recipeIDs[6], false).quantityMin
									local amount = math.max(0, math.ceil(reagentsTracked[itemID] / quantityMade) - GetItemCount(itemID))

									-- Track the recipe(s)
									pslTrackRecipe(recipeIDs[6], amount)

									-- Hide the subreagents window
									f:Hide()
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
					-- Right-click on recipe amount
					if column == 2 and button == "RightButton" and row ~= nil and realrow ~= nil then
						-- Get the selected recipe ID
						local selectedRecipe = data[realrow][1]
						local selectedRecipeID

						for recipeID, recipeLink in pairs(recipeLinks) do
							if selectedRecipe == recipeLink then selectedRecipeID = recipeID end
						end

						-- Untrack the recipe
						if IsControlKeyDown() == true then
							pslUntrackRecipe(selectedRecipeID, data[realrow][2])
						else
							pslUntrackRecipe(selectedRecipeID, 1)
						end

						-- Show windows
						pslFrame1:Show()
						pslFrame2:Show()
					-- Left-click on recipe
					elseif column == 1 and button == "LeftButton" and row ~= nil and realrow ~= nil then
						-- If Shift is held also
						if IsShiftKeyDown() == true then
							-- Try write link to chat
							ChatEdit_InsertLink(data[realrow][1])
						-- If Control is held also
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
				trackProfessionButton:Enable()
				trackPlaceOrderButton:Enable()
				trackMakeOrderButton:Enable()
			end

			-- 2 = Salvage | Disable these, cause they shouldn't be tracked
			if pslRecipeType == 2 then
				trackProfessionButton:Disable()
				untrackProfessionButton:Disable()
				trackPlaceOrderButton:Disable()
				untrackPlaceOrderButton:Disable()
				trackMakeOrderButton:Disable()
				untrackMakeOrderButton:Disable()
			end

			-- 3 = Enchant
			if pslRecipeType == 3 then
				trackProfessionButton:Enable()
				trackPlaceOrderButton:Enable()
				trackMakeOrderButton:Enable()
			end

			-- 4 = Recraft
			if pslRecipeType == 4 then
				trackProfessionButton:Disable()
				untrackProfessionButton:Disable()
				trackPlaceOrderButton:Disable()
				untrackPlaceOrderButton:Disable()
				trackMakeOrderButton:Disable()
				untrackMakeOrderButton:Disable()
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
				trackProfessionButton:Disable()
				untrackProfessionButton:Disable()
				trackPlaceOrderButton:Disable()
				untrackPlaceOrderButton:Disable()
				trackMakeOrderButton:Disable()
				untrackMakeOrderButton:Disable()
			end

			-- Check if recipe is tracked
			if not recipesTracked[pslSelectedRecipeID] or recipesTracked[pslSelectedRecipeID] == 0 then
				untrackProfessionButton:Disable()
				untrackPlaceOrderButton:Disable()
				untrackMakeOrderButton:Disable()
			else
				untrackProfessionButton:Enable()
				untrackPlaceOrderButton:Enable()
				untrackMakeOrderButton:Enable()
			end
		end
		checkRemoveButton()

		local function professionFeatures()
			-- Show stuff depending on which profession is opened
			local skillLineID = C_TradeSkillUI.GetProfessionChildSkillLineID()
			local professionID = C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID).profession

			-- Knowledge Point Tracker
			local function setKnowledgePointTracker()
				-- Variables
				local configID = C_ProfSpecs.GetConfigIDForSkillLine(skillLineID)
				local specTabIDs = C_ProfSpecs.GetSpecTabIDsForSkillLine(skillLineID)

				-- Helper functions
				local appendChildPathIDsForRoot -- Declare this one before the function itself, otherwise it can't find the function to refer to within itself apparently
				appendChildPathIDsForRoot = function(t, pathID)
					t[pathID] = 1
					for _, childID in ipairs(C_ProfSpecs.GetChildrenForPath(pathID)) do
						appendChildPathIDsForRoot(t, childID)
					end
				end

				-- Get all profession specialisation paths
				local pathIDs = {}
				for _, specTabID in ipairs(C_ProfSpecs.GetSpecTabIDsForSkillLine(skillLineID)) do
					appendChildPathIDsForRoot(pathIDs, C_ProfSpecs.GetRootPathForTab(specTabID))
				end

				-- Get all perks
				local perkCount = 0
				local perkIDs = {}
				for pathID, _ in pairs (pathIDs) do
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
				for pathID, _ in pairs (pathIDs) do
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
					for _, dropInfo in ipairs (drops) do
						if C_QuestLog.IsQuestFlaggedCompleted(dropInfo.questID) then
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

					if IsModifierKeyDown() == true then
						for _, dropInfo in ipairs (drops) do
							oldText = knowledgePointTooltipText:GetText()
							local derp, itemLink = GetItemInfo(dropInfo.itemID)
		
							-- If links missing, try again
							if itemLink == nil then
								RunNextFrame(kpTooltip)
								do return end
							end
		
							if C_QuestLog.IsQuestFlaggedCompleted(dropInfo.questID) then
								knowledgePointTooltipText:SetText(oldText.."\n   ".."|T"..READY_CHECK_READY_TEXTURE..":0|t "..itemLink)
							else
								knowledgePointTooltipText:SetText(oldText.."\n   ".."|T"..READY_CHECK_NOT_READY_TEXTURE..":0|t "..itemLink)
							end
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
				if IsModifierKeyDown() == false then knowledgePointTooltipText:SetText(oldText.."\n\n|cffFFD000Hold Alt, Ctrl, or Shift to show details.") end

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

			-- Refresh and show the tooltip on mouse-over, and forward keyboard inputs for the modifier
			knowledgePointTracker:SetScript("OnEnter", function()
				kpTooltip()
				knowledgePointTooltip:Show()
				knowledgePointTracker:SetPropagateKeyboardInput(false)
			end)

			-- Hide the tooltip when not mouse-over, and no longer forward keyboard inputs
			knowledgePointTracker:SetScript("OnLeave", function()
				knowledgePointTooltip:Hide()
				knowledgePointTracker:SetPropagateKeyboardInput(true)
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
				craftQuests = {70211, 70233, 70234, 70235}
				hiddenMaster = 70250
				drops = {}
				drops[1] = {questID = 66381, itemID = 192131}
				drops[2] = {questID = 66382, itemID = 192132}
				drops[3] = {questID = 70512, itemID = 198965}
				drops[4] = {questID = 70513, itemID = 198966}
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
				drops[1] = {questID = 66384, itemID = 193910}
				drops[2] = {questID = 66385, itemID = 193913}
				drops[3] = {questID = 70522, itemID = 198975}
				drops[4] = {questID = 70523, itemID = 198976}
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
				drops[1] = {questID = 66373, itemID = 193891}
				drops[2] = {questID = 66374, itemID = 193897}
				drops[3] = {questID = 70504, itemID = 198963}
				drops[4] = {questID = 70511, itemID = 198964}
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
				drops[1] = {questID = 71857, itemID = 200677}
				drops[2] = {questID = 71858, itemID = 200677}
				drops[3] = {questID = 71859, itemID = 200677}
				drops[4] = {questID = 71860, itemID = 200677}
				drops[5] = {questID = 71861, itemID = 200677}
				drops[6] = {questID = 71864, itemID = 200678}
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
				drops[1] = {questID = 72160, itemID = 201300}
				drops[2] = {questID = 72161, itemID = 201300}
				drops[3] = {questID = 72162, itemID = 201300}
				drops[4] = {questID = 72163, itemID = 201300}
				drops[5] = {questID = 72164, itemID = 201300}
				drops[6] = {questID = 72165, itemID = 201301}
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
				drops[1] = {questID = 66386, itemID = 193898}
				drops[2] = {questID = 66387, itemID = 193899}
				drops[3] = {questID = 70524, itemID = 198977}
				drops[4] = {questID = 70525, itemID = 198978}
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
				drops[1] = {questID = 66379, itemID = 193902}
				drops[2] = {questID = 66380, itemID = 193903}
				drops[3] = {questID = 70516, itemID = 198969}
				drops[4] = {questID = 70517, itemID = 198970}
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
				drops[1] = {questID = 66377, itemID = 193900}
				drops[2] = {questID = 66378, itemID = 193901}
				drops[3] = {questID = 70514, itemID = 198967}
				drops[4] = {questID = 70515, itemID = 198968}
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
				drops[1] = {questID = 70381, itemID = 198837}
				drops[2] = {questID = 70383, itemID = 198837}
				drops[3] = {questID = 70384, itemID = 198837}
				drops[4] = {questID = 70385, itemID = 198837}
				drops[5] = {questID = 70386, itemID = 198837}
				drops[6] = {questID = 70389, itemID = 198841}
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
				drops[1] = {questID = 66388, itemID = 193909}
				drops[2] = {questID = 66389, itemID = 193907}
				drops[3] = {questID = 70520, itemID = 198973}
				drops[4] = {questID = 70521, itemID = 198974}
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
				drops[1] = {questID = 66375, itemID = 193904}
				drops[2] = {questID = 66376, itemID = 193905}
				drops[3] = {questID = 70518, itemID = 198971}
				drops[4] = {questID = 70519, itemID = 198972}
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
				-- When not viewing another character's
				if C_TradeSkillUI.IsTradeSkillLinked() == false and C_TradeSkillUI.IsTradeSkillGuild() == false then
					setKnowledgePointTracker()
					kpTooltip()
				end
			else
				knowledgePointTracker:Hide()
			end
		end
		professionFeatures()
	end
	
	-- Do stuff when a profession window is loaded
	if event == "TRADE_SKILL_LIST_UPDATE" then
		-- Register all recipes for this profession
		for _, id in pairs(C_TradeSkillUI.GetAllRecipeIDs()) do
			local itemID = C_TradeSkillUI.GetRecipeOutputItemData(id).itemID
			if itemID ~= nil then recipeLibrary[id] = itemID end
		end
	end

	-- Remove 1 tracked recipe when it has been crafted (if the option is enabled)
	if event == "UNIT_SPELLCAST_SUCCEEDED" and userSettings["removeCraft"] == true then
		local recipeID = ...
		pslUntrackRecipe(recipeID, 1)

		-- Close windows if no recipes are left and the option is enabled
		local next = next
		if next(recipesTracked) == nil and userSettings["closeWhenDone"] == true then
			pslFrame1:Hide()
			pslFrame2:Hide()
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

	-- Save the order recipeID if the order has been started, because SPELL_LOAD_RESULT does not fire for it anymore
	if event == "CRAFTINGORDERS_CLAIM_ORDER_RESPONSE" then
		pslOrderRecipeID = pslSelectedRecipeID
	end

	-- Revert the above if the order is cancelled or fulfilled, since then SPELL_LOAD_RESULT fires again for it
	if event == "CRAFTINGORDERS_RELEASE_ORDER_RESPONSE" or event == "CRAFTINGORDERS_FULFILL_ORDER_RESPONSE" then
		pslOrderRecipeID = 0
	end
end)