----------------------------------------
-- Profession Shopping List: Core.lua --
----------------------------------------
-- Main AddOn code (once cleaned up and reviewed)

-- Initialisation
local appName, app = ...	-- Returns the AddOn name and a unique table
app.api = {}	-- Create a table to use for our "API"
ProfessionShoppingList = app.api	-- Create a namespace for our "API"
local api = app.api	-- Our "API" prefix

----------------------
-- HELPER FUNCTIONS --
----------------------

-- WoW API Events
local event = CreateFrame("Frame")
event:SetScript("OnEvent", function(self, event, ...)
	if self[event] then
		self[event](self, ...)
	end
end)
event:RegisterEvent("ADDON_LOADED")
event:RegisterEvent("AUCTION_HOUSE_SHOW")
event:RegisterEvent("BAG_UPDATE_DELAYED")
event:RegisterEvent("CRAFTINGORDERS_CLAIM_ORDER_RESPONSE")
event:RegisterEvent("CRAFTINGORDERS_FULFILL_ORDER_RESPONSE")
event:RegisterEvent("CRAFTINGORDERS_HIDE_CUSTOMER")
event:RegisterEvent("CRAFTINGORDERS_ORDER_PLACEMENT_RESPONSE")
event:RegisterEvent("CRAFTINGORDERS_RELEASE_ORDER_RESPONSE")
event:RegisterEvent("CRAFTINGORDERS_SHOW_CUSTOMER")
event:RegisterEvent("LFG_PROPOSAL_SHOW")
event:RegisterEvent("MERCHANT_SHOW")
event:RegisterEvent("PET_BATTLE_QUEUE_PROPOSE_MATCH")
event:RegisterEvent("PLAYER_ENTERING_WORLD")
event:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
event:RegisterEvent("SPELL_DATA_LOAD_RESULT")
event:RegisterEvent("TRACKED_RECIPE_UPDATE")
event:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
event:RegisterEvent("TRADE_SKILL_SHOW")
event:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

-- Table dump
function app.Dump(table)
	local function dumpTable(o)
		if type(o) == 'table' then
			local s = '{ '
			for k,v in pairs(o) do
				if type(k) ~= 'number' then k = '"'..k..'"' end
				s = s .. '['..k..'] = ' .. dumpTable(v) .. ','
			end
		return s .. '} '
		else
			return tostring(o)
		end
	end
	print(dumpTable(table))
end

-- Print with AddOn prefix
function app.Print(...)
	print(app.NameShort..":", ...)
end

-- Pop-up window
function app.Popup(show, text)
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
	if show == true then
		f:Show()
	else
		f:Hide()
	end

	-- Close button
	local close = CreateFrame("Button", "", f, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
	close:SetScript("OnClick", function()
		f:Hide()
	end)

	-- Text
	local string = f:CreateFontString("ARTWORK", nil, "GameFontNormal")
	string:SetPoint("CENTER", f, "CENTER", 0, 0)
	string:SetPoint("TOP", f, "TOP", 0, -25)
	string:SetJustifyH("CENTER")
	string:SetText(text)
	f:SetHeight(string:GetStringHeight()+50)
	f:SetWidth(string:GetStringWidth()+50)

	return f
end

------------------
-- INITIAL LOAD --
------------------

-- Create SavedVariables, default user settings, and session variables
function app.Initialise()
	-- Declare SavedVariables
	if not userSettings then userSettings = {} end
	if not recipesTracked then recipesTracked = {} end
	if not reagentCache then reagentCache = {} end
	if not recipeCooldowns then recipeCooldowns = {} end
	if not reagentTiers then reagentTiers = {} end
	if not recipeLibrary then recipeLibrary = {} end
	if not fakeRecipeLibrary then fakeRecipeLibrary = {} end
	if not pcRecipesTracked then pcRecipesTracked = {} end
	if not personalOrders then personalOrders = {} end

	-- Enable default user settings
	-- TODO: Order by visual settings
	if userSettings["hide"] == nil then userSettings["hide"] = false end
	if userSettings["removeCraft"] == nil then userSettings["removeCraft"] = true end
	if userSettings["showRemaining"] == nil then userSettings["showRemaining"] = false end
	if userSettings["showTooltip"] == nil then userSettings["showTooltip"] = true end
	if userSettings["vendorAll"] == nil then userSettings["vendorAll"] = true end
	if userSettings["reagentQuality"] == nil then userSettings["reagentQuality"] = 1 end
	if userSettings["closeWhenDone"] == nil then userSettings["closeWhenDone"] = false end
	if userSettings["showKnowledgeNotPerks"] == nil then userSettings["showKnowledgeNotPerks"] = false end
	if userSettings["useLocalReagents"] == nil then userSettings["useLocalReagents"] = false end
	if userSettings["knowledgeHideDone"] == nil then userSettings["knowledgeHideDone"] = false end
	if userSettings["knowledgeAlwaysShowDetails"] == nil then userSettings["knowledgeAlwaysShowDetails"] = false end
	if userSettings["pcWindows"] == nil then userSettings["pcWindows"] = false end
	if userSettings["pcRecipesTracked"] == nil then userSettings["pcRecipesTracked"] = false end
	if userSettings["headerTooltip"] == nil then userSettings["headerTooltip"] = true end
	if userSettings["showRecipeCooldowns"] == nil then userSettings["showRecipeCooldowns"] = true end
	if userSettings["backpackCount"] == nil then userSettings["backpackCount"] = true end
	if userSettings["queueSound"] == nil then userSettings["queueSound"] = false end
	if userSettings["backpackCleanup"] == nil then userSettings["backpackCleanup"] = "default" end
	if userSettings["backpackLoot"] == nil then userSettings["backpackLoot"] = "default" end
	if userSettings["windowPosition"] == nil then userSettings["windowPosition"] = { ["left"] = 1295, ["bottom"] = 836, ["width"] = 200, ["height"] = 200, } end
	if userSettings["pcwindowPosition"] == nil then userSettings["pcWindowPosition"] = userSettings["windowPosition"] end
	if userSettings["alvinGUID"] == nil then userSettings["alvinGUID"] = "unknown" end
	if userSettings["onetimeMessages"] == nil then userSettings["onetimeMessages"] = {} end
	if userSettings["onetimeMessages"].vendorItems == nil then userSettings["onetimeMessages"].vendorItems = false end

	-- Load personal recipes, if the setting is enabled
	if userSettings["pcRecipesTracked"] == true then
		recipesTracked = pcRecipesTracked
	end

	-- Initialise some session variables
	app.Hidden = CreateFrame("Frame")
	app.Flag = {}
	app.Flag["changingRecipes"] = false
	app.Flag["craftingOrderAssets"] = false
	app.Flag["merchantAssets"] = false
	app.Flag["quickOrder"] = 0
	app.Flag["recraft"] = false
	app.Flag["tradeskillAssets"] = false
	app.OrderRecipeID = 0
	app.QuickOrderAttempts = 0
	app.QuickOrderErrors = 0
	app.ReagentQuantities = {}
	app.SelectedRecipeID = 0
	app.UpdatedCooldownWidth = 0
	app.UpdatedReagentWidth = 0
end

-- Convert and/or delete older SavedVariables
function app.Legacy()
	-- v10.2.0-007
		-- Convert recipeLinks to recipesTracked
		for key, value in pairs(recipesTracked) do
			if type(value) == "number" then
				recipesTracked[key] = { quantity = value, recraft = false }
			end
		end

		for key, value in pairs(pcRecipesTracked) do
			if type(value) == "number" then
				pcRecipesTracked[key] = { quantity = value, recraft = false }
			end
		end

		if recipeLinks then
			for key, value in pairs(recipeLinks) do
				recipesTracked[key].link = value
			end
		end

		if pcRecipeLinks then
			for key, value in pairs(pcRecipeLinks) do
				pcRecipesTracked[key].link = value
			end
		end

		-- Delete old window position and size
		userSettings["recipeRows"] = nil
		userSettings["reagentRows"] = nil
		userSettings["recipeWidth"] = nil
		userSettings["recipeNoWidth"] = nil
		userSettings["reagentWidth"] = nil
		userSettings["reagentNoWidth"] = nil
	
	-- v10.2.5-002
	local tempCooldowns = recipeCooldowns
	recipeCooldowns = {}
	for k, v in pairs(tempCooldowns) do
		if not v.recipeID then
			tempCooldowns[k].recipeID = k
		end
		recipeCooldowns[#recipeCooldowns+1] = v
	end

	for k, v in pairs(recipeCooldowns) do
		if not v.charges then
			v.charges = 0
			v.maxCharges = 0
		end
	end
end

-- Save the window position and size
function app.SaveWindow()
	-- Stop moving or resizing the window
	app.Window:StopMovingOrSizing()

	-- Get the window properties
	local left = app.Window:GetLeft()
	local bottom = app.Window:GetBottom()
	local width, height = app.Window:GetSize()

	-- Save the window position and size
	userSettings["windowPosition"] = { ["left"] = left, ["bottom"] = bottom, ["width"] = width, ["height"] = height, }
	userSettings["pcWindowPosition"] = userSettings["windowPosition"]
end

-- Create the main window
function app.CreateWindow()
	-- Create popup frame
	app.Window = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	app.Window:SetPoint("CENTER")
	app.Window:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	app.Window:SetBackdropColor(0, 0, 0, 1)
	app.Window:EnableMouse(true)
	app.Window:SetMovable(true)
	app.Window:SetResizable(true)
	app.Window:SetResizeBounds(140, 140, 600, 600)
	app.Window:RegisterForDrag("LeftButton")
	app.Window:SetScript("OnDragStart", function()
		app.Window:StartMoving()
		GameTooltip:ClearLines()
		GameTooltip:Hide()
	end)
	app.Window:SetScript("OnDragStop", function() app.SaveWindow() end)
	app.Window:Hide()

	-- Resize corner
	local corner = CreateFrame("Button", nil, app.Window)
	corner:EnableMouse("true")
	corner:SetPoint("BOTTOMRIGHT")
	corner:SetSize(16,16)
	corner:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	corner:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	corner:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	corner:SetScript("OnMouseDown", function()
		app.Window:StartSizing("BOTTOMRIGHT")
		GameTooltip:ClearLines()
		GameTooltip:Hide()
	end)
	corner:SetScript("OnMouseUp", function() app.SaveWindow() end)
	app.Window.Corner = corner

	-- Close button
	local close = CreateFrame("Button", "pslOptionCloseButton", app.Window, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", app.Window, "TOPRIGHT", -1, -1)
	close:SetScript("OnClick", function()
		app.Window:Hide()
	end)

	-- ScrollFrame inside the popup frame
	local scrollFrame = CreateFrame("ScrollFrame", nil, app.Window, "ScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", app.Window, 7, -6)
	scrollFrame:SetPoint("BOTTOMRIGHT", app.Window, -22, 6)
	scrollFrame:Show()

	scrollFrame.ScrollBar.Back:Hide()
	scrollFrame.ScrollBar.Forward:Hide()
	scrollFrame.ScrollBar:ClearAllPoints()
	scrollFrame.ScrollBar:SetPoint("TOP", scrollFrame, 0, -3)
	scrollFrame.ScrollBar:SetPoint("RIGHT", scrollFrame, 13, 0)
	scrollFrame.ScrollBar:SetPoint("BOTTOM", scrollFrame, 0, -16)
	
	-- ScrollChild inside the ScrollFrame
	local scrollChild = CreateFrame("Frame", nil, scrollFrame)
	scrollFrame:SetScrollChild(scrollChild)
	scrollChild:SetWidth(1)    -- This is automatically defined, so long as the attribute exists at all
	scrollChild:SetHeight(1)    -- This is automatically defined, so long as the attribute exists at all
	scrollChild:SetAllPoints(scrollFrame)
	scrollChild:Show()
	scrollFrame:SetScript("OnVerticalScroll", function() scrollChild:SetPoint("BOTTOMRIGHT", scrollFrame) end)
	app.Window.Child = scrollChild
	app.Window.ScrollFrame = scrollFrame
end

-- Get reagents for recipe
function app.GetReagents(reagentVariable, recipeID, recipeQuantity, recraft, qualityTier)
	-- Grab all the reagent info from the API
	local reagentsTable

	-- Exception for SL legendary crafts
	if app.slLegendaryRecipeIDs[recipeID] then
		reagentsTable = C_TradeSkillUI.GetRecipeSchematic(recipeID, false, app.slLegendaryRecipeIDs[recipeID].rank).reagentSlotSchematics
	else
		reagentsTable = C_TradeSkillUI.GetRecipeSchematic(recipeID, recraft).reagentSlotSchematics
	end

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

			-- Add the reagentID to the reagent cache
			if not reagentCache[reagentID] then
				local item = Item:CreateFromItemID(reagentID)
			
				-- And when the item is cached
				item:ContinueOnItemLoad(function()
					-- Get item info
					_, itemLink, _, _, _, _, _, _, _, fileID = GetItemInfo(reagentID)

					-- Write the info to the cache
					reagentCache[reagentID] = {link = itemLink, icon = fileID}
				end)
			end

			-- Add the info to the specified variable
			if reagentVariable[reagentID] == nil then reagentVariable[reagentID] = 0 end
			reagentVariable[reagentID] = reagentVariable[reagentID] + ( reagentAmount * recipeQuantity )
		end
	end
end

-- Update numbers tracked
function app.UpdateNumbers()
	-- Update reagents tracked
	for reagentID, amount in pairs(app.ReagentQuantities) do
		local itemLink, fileID

		if not reagentCache[reagentID] then
			-- Cache item
			if not C_Item.IsItemDataCachedByID(reagentID) then local item = Item:CreateFromItemID(reagentID) end

			-- Get item info
			_, itemLink, _, _, _, _, _, _, _, fileID = GetItemInfo(reagentID)

			-- Try again if error
			if itemLink == nil then
				RunNextFrame(app.UpdateNumbers)
				do return end
			end

			-- Write the info to the cache
			reagentCache[reagentID] = {link = itemLink, icon = fileID}
		else
			-- Read the info from the cache
			itemLink = reagentCache[reagentID].link
			icon = reagentCache[reagentID].icon
		end

		local itemAmount = ""
		local itemIcon = reagentCache[reagentID].icon

		if type(reagentID) == "number" then
			-- Get needed/owned number of reagents
			local reagentAmountHave1 = 0
			local reagentAmountHave2 = 0
			local reagentAmountHave3 = 0

			reagentAmountHave1 = GetItemCount(reagentTiers[reagentID].one, true, false, true)
			if reagentTiers[reagentID].two ~= 0 then
				reagentAmountHave2 = GetItemCount(reagentTiers[reagentID].two, true, false, true)
			end
			if reagentTiers[reagentID].three ~= 0 then
				reagentAmountHave3 = GetItemCount(reagentTiers[reagentID].three, true, false, true)
			end

			-- Calculate owned amount based on the quality of the item
			local reagentAmountHave = 0
			if reagentID == reagentTiers[reagentID].one then
				reagentAmountHave = reagentAmountHave1 + reagentAmountHave2 + reagentAmountHave3
			elseif reagentID == reagentTiers[reagentID].two then
				reagentAmountHave = reagentAmountHave2 + reagentAmountHave3
			elseif reagentID == reagentTiers[reagentID].three then
				reagentAmountHave = reagentAmountHave3
			end

			-- Make stuff grey and add a checkmark if 0 are needed
			if math.max(0,amount-reagentAmountHave) == 0 then
				itemIcon = app.iconReady
				itemAmount = "|cff9d9d9d"
				itemLink = string.gsub(itemLink, "|cff9d9d9d|", "|cff9d9d9d|") -- Poor
				itemLink = string.gsub(itemLink, "|cffffffff|", "|cff9d9d9d|") -- Common
				itemLink = string.gsub(itemLink, "|cff1eff00|", "|cff9d9d9d|") -- Uncommon
				itemLink = string.gsub(itemLink, "|cff0070dd|", "|cff9d9d9d|") -- Rare
				itemLink = string.gsub(itemLink, "|cffa335ee|", "|cff9d9d9d|") -- Epic
				itemLink = string.gsub(itemLink, "|cffff8000|", "|cff9d9d9d|") -- Legendary
				itemLink = string.gsub(itemLink, "|cffe6cc80|", "|cff9d9d9d|") -- Artifact
			end

			-- Set the displayed amount based on settings
			if userSettings["showRemaining"] == false then
				itemAmount = itemAmount..reagentAmountHave.."/"..amount
			else
				itemAmount = itemAmount..math.max(0,amount-reagentAmountHave)
			end
		elseif reagentID == "gold" then
			-- Set the color of both strings and the icon
			local color = ""
			if math.max(0,amount-GetMoney()) == 0 then
				itemIcon = app.iconReady
				color = "|cff9d9d9d"
				itemLink = color..itemLink
			end

			-- Set the displayed amount based on settings
			if userSettings["showRemaining"] == false then
				itemAmount = color..GetCoinTextureString(amount)
			else
				itemAmount = color..GetCoinTextureString(math.max(0,amount-GetMoney()))
			end
		elseif string.find(reagentID, "currency") then
			local number = string.gsub(reagentID, "currency:", "")
			local quantity = C_CurrencyInfo.GetCurrencyInfo(tonumber(number)).quantity

			-- Set the color of both strings and the icon
			local color = ""
			if math.max(0,amount-quantity) == 0 then
				itemIcon = app.iconReady
				color = "|cff9d9d9d"
				itemLink = color..itemLink
			end

			-- Set the displayed amount based on settings
			if userSettings["showRemaining"] == false then
				itemAmount = color..quantity.."/"..amount
			else
				itemAmount = color..math.max(0,amount-quantity)
			end
		end

		-- Push the info to the windows
		if reagentRow then
			for i, row in pairs(reagentRow) do
				if row:GetID() == reagentID or (reagentID == "gold" and row.text1:GetText() == BONUS_ROLL_REWARD_MONEY) then
					row.icon:SetText("|T"..itemIcon..":0|t")
					row.text1:SetText(itemLink)
					row.text2:SetText(itemAmount)
					app.UpdatedReagentWidth = math.max(row.icon:GetStringWidth()+row.text1:GetStringWidth()+row.text2:GetStringWidth(), app.UpdatedReagentWidth)
				elseif string.find(reagentID, "currency") then
					local number = string.gsub(reagentID, "currency:", "")
					local name = C_CurrencyInfo.GetCurrencyInfo(tonumber(number)).name
					if name == row.text1:GetText() then
						row.icon:SetText("|T"..itemIcon..":0|t")
						row.text1:SetText(itemLink)
						row.text2:SetText(itemAmount)
						app.UpdatedReagentWidth = math.max(row.icon:GetStringWidth()+row.text1:GetStringWidth()+row.text2:GetStringWidth(), app.UpdatedReagentWidth)
					end
				end
			end
		end
	end

	local customSortList = {
		"|cffe6cc80",	-- Artifact
		"|cffff8000",	-- Legendary
		"|cffa335ee",	-- Epic
		"|cff0070dd",	-- Rare
		"|cff1eff00",	-- Uncommon
		"|cffffffff",	-- Common
		"|cff9d9d9d",	-- Poor (quantity 0)
	}

	local function customSort(a, b)
		for _, v in ipairs(customSortList) do
			local indexA = string.find(a.link, v, 1, true)
			local indexB = string.find(b.link, v, 1, true)
	
			if indexA == 1 and indexB ~= 1 then
				return true
			elseif indexA ~= 1 and indexB == 1 then
				return false
			end
		end
	
		-- If custom sort index is the same, compare alphabetically
		return string.gsub(a.link, ".-(:%|h)", "") < string.gsub(b.link, ".-(:%|h)", "")
	end

	if recipeRow then
		if #recipeRow >= 1 then
			for i, row in ipairs(recipeRow) do
				if i == 1 then
					row:SetPoint("TOPLEFT", app.Window.Recipes, "BOTTOMLEFT")
					row:SetPoint("TOPRIGHT", app.Window.Recipes, "BOTTOMRIGHT")
				else
					local offset = -16*(i-1)
					row:SetPoint("TOPLEFT", app.Window.Recipes, "BOTTOMLEFT", 0, offset)
					row:SetPoint("TOPRIGHT", app.Window.Recipes, "BOTTOMRIGHT", 0, offset)
				end
			end
		end
	end

	if reagentRow then
		if #reagentRow >= 1 then
			local reagentsSorted = {}
			for _, row in pairs(reagentRow) do
				table.insert(reagentsSorted, {["row"] = row, ["link"] = row.text1:GetText()})
			end
			table.sort(reagentsSorted, customSort)

			for i, info in ipairs(reagentsSorted) do
				if i == 1 then
					info.row:SetPoint("TOPLEFT", app.Window.Reagents, "BOTTOMLEFT")
					info.row:SetPoint("TOPRIGHT", app.Window.Reagents, "BOTTOMRIGHT")
				else
					local offset = -16*(i-1)
					info.row:SetPoint("TOPLEFT", app.Window.Reagents, "BOTTOMLEFT", 0, offset)
					info.row:SetPoint("TOPRIGHT", app.Window.Reagents, "BOTTOMRIGHT", 0, offset)
				end
			end
		end
	end
end

-- Update cooldown numbers
function app.UpdateCooldowns()
	app.UpdatedCooldownWidth = 0
	if cooldownRow then
		if #cooldownRow >= 1 then
			for i, row in ipairs(cooldownRow) do
				local rowID = row:GetID()
				local cooldownRemaining = recipeCooldowns[rowID].start + recipeCooldowns[rowID].cooldown - GetServerTime()
				local days, hours, minutes

				days = math.floor(cooldownRemaining/(60*60*24))
				hours = math.floor((cooldownRemaining - (days*60*60*24))/(60*60))
				minutes = math.floor((cooldownRemaining - ((days*60*60*24) + (hours*60*60)))/60)

				if cooldownRemaining <= 0 then
					row.text2:SetText("Ready")
				elseif cooldownRemaining < 60*60 then
					row.text2:SetText(minutes.."m")
				elseif cooldownRemaining < 60*60*24 then
					row.text2:SetText(hours.."h "..minutes.."m")
				else
					row.text2:SetText(days.."d "..hours.."h "..minutes.."m")
				end

				app.UpdatedCooldownWidth = math.max(row.icon:GetStringWidth()+row.text1:GetStringWidth()+row.text2:GetStringWidth(), app.UpdatedCooldownWidth)
			end
		end
	end
end

-- Update recipes and reagents tracked
function app.UpdateRecipes()
	-- Set personal recipes to be the same as global recipes
	pcRecipesTracked = recipesTracked

	-- Recalculate reagents tracked
	if app.Flag["changingRecipes"] == false then
		app.ReagentQuantities = {}

		for recipeID, recipeInfo in pairs(recipesTracked) do
			if type(recipeID) == "number" then
				app.GetReagents(app.ReagentQuantities, recipeID, recipeInfo.quantity, recipeInfo.recraft)
			elseif fakeRecipeLibrary[recipeID] then
				-- Add gold costs
				if fakeRecipeLibrary[recipeID].costCopper > 0 then
					if app.ReagentQuantities["gold"] == nil then app.ReagentQuantities["gold"] = 0 end
					app.ReagentQuantities["gold"] = app.ReagentQuantities["gold"] + ( fakeRecipeLibrary[recipeID].costCopper * recipesTracked[recipeID].quantity )
				end
				-- Add item costs
				for reagentID, reagentAmount in pairs(fakeRecipeLibrary[recipeID].costItems) do
					if app.ReagentQuantities[reagentID] == nil then app.ReagentQuantities[reagentID] = 0 end
					app.ReagentQuantities[reagentID] = app.ReagentQuantities[reagentID] + ( reagentAmount * recipesTracked[recipeID].quantity )
				end
				-- Add currency costs
				for currencyID, currencyAmount in pairs(fakeRecipeLibrary[recipeID].costCurrency) do
					local key = "currency:"..currencyID
					if app.ReagentQuantities[key] == nil then app.ReagentQuantities[key] = 0 end
					app.ReagentQuantities[key] = app.ReagentQuantities[key] + ( currencyAmount * recipesTracked[recipeID].quantity )
				end
			end
		end

		-- Update numbers tracked
		app.UpdateNumbers()
	end

	local rowNo = 0
	local showRecipes = true
	local maxLength1 = 0
	local maxLength2 = 0
	local maxLength3 = 0

	if recipeRow then
		for i, row in pairs(recipeRow) do
			row:SetParent(app.Hidden)
			row:Hide()
		end
	end
	if reagentRow then
		for i, row in pairs(reagentRow) do
			row:SetParent(app.Hidden)
			row:Hide()
		end
	end
	if cooldownRow then
		for i, row in pairs(cooldownRow) do
			row:SetParent(app.Hidden)
			row:Hide()
		end
	end

	recipeRow = {}
	reagentRow = {}
	cooldownRow = {}

	if not app.Window.Recipes then
		app.Window.Recipes = CreateFrame("Button", nil, app.Window.Child)
		app.Window.Recipes:SetSize(0,16)
		app.Window.Recipes:SetPoint("TOPLEFT", app.Window.Child, -1, 0)
		app.Window.Recipes:SetPoint("RIGHT", app.Window.Child)
		app.Window.Recipes:RegisterForDrag("LeftButton")
		app.Window.Recipes:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
		app.Window.Recipes:SetScript("OnDragStart", function()
			app.Window:StartMoving()
			GameTooltip:ClearLines()
			GameTooltip:Hide()
		end)
		app.Window.Recipes:SetScript("OnDragStop", function() app.SaveWindow() end)
		app.Window.Recipes:SetScript("OnEnter", function()
			-- Set the tooltip to either the left or right, depending on where the window is placed
			if GetScreenWidth()/2-userSettings["windowPosition"].width/2-app.Window:GetLeft() >= 0 then
				recipeHeaderTooltip:ClearAllPoints()
				recipeHeaderTooltip:SetPoint("LEFT", app.Window, "RIGHT", 0, 0)
			else
				recipeHeaderTooltip:ClearAllPoints()
				recipeHeaderTooltip:SetPoint("RIGHT", app.Window, "LEFT", 0, 0)
			end
			recipeHeaderTooltip:Show()
		end)
		app.Window.Recipes:SetScript("OnLeave", function()
			recipeHeaderTooltip:Hide()
		end)
		
		local recipes1 = app.Window.Recipes:CreateFontString("ARTWORK", nil, "GameFontNormal")
		recipes1:SetPoint("LEFT", app.Window.Recipes)
		recipes1:SetScale(1.1)
		app.RecipeHeader = recipes1
	end

	app.Window.Recipes:SetScript("OnClick", function(self)
		local children = {self:GetChildren()}

		if showRecipes == true then
			for _, child in ipairs(children) do child:Hide() end
			app.Window.Reagents:SetPoint("TOPLEFT", app.Window.Recipes, "BOTTOMLEFT", 0, -2)
			showRecipes = false
		else
			for _, child in ipairs(children) do child:Show() end
			local offset = -2
			if #recipeRow >= 1 then offset = -16*#recipeRow end
			app.Window.Reagents:SetPoint("TOPLEFT", app.Window.Recipes, "BOTTOMLEFT", 0, offset)
			showRecipes = true
		end
	end)

	local customSortList = {
		"|cffe6cc80",	-- Artifact
		"|cffff8000",	-- Legendary
		"|cffa335ee",	-- Epic
		"|cff0070dd",	-- Rare
		"|cff1eff00",	-- Uncommon
		"|cffffffff",	-- Common
		"|cff9d9d9d",	-- Poor (quantity 0)
	}

	-- Custom comparison function based on the beginning of the string (thanks ChatGPT)
	local function customSort(a, b)
		for _, v in ipairs(customSortList) do
			local indexA = string.find(a.link, v, 1, true)
			local indexB = string.find(b.link, v, 1, true)
	
			if indexA == 1 and indexB ~= 1 then
				return true
			elseif indexA ~= 1 and indexB == 1 then
				return false
			end
		end
	
		-- If custom sort index is the same, compare alphabetically
		return string.gsub(a.link, ".-(:%|h)", "") < string.gsub(b.link, ".-(:%|h)", "")
	end

	-- Group and sort recipes and vendor items
	local recipesSorted1 = {}
	local recipesSorted2 = {}
	
	for k, v in pairs(recipesTracked) do
		if type(k) == "number" then
			recipesSorted1[#recipesSorted1+1] = {recipeID = k, recraft = v.recraft, quantity = v.quantity, link = v.link}
		else
			recipesSorted2[#recipesSorted2+1] = {recipeID = k, recraft = v.recraft, quantity = v.quantity, link = v.link}
		end
	end

	table.sort(recipesSorted1, customSort)
	table.sort(recipesSorted2, customSort)

	-- Combine the sorted entries into a combined table
	local recipesSorted = {}

	for _, key in ipairs(recipesSorted1) do
		table.insert(recipesSorted, key)
	end
	for _, key in ipairs(recipesSorted2) do
		table.insert(recipesSorted, key)
	end

	for _i, recipeInfo in ipairs(recipesSorted) do
		rowNo = rowNo + 1

		local row = CreateFrame("Button", nil, app.Window.Recipes)
		row:SetSize(0,16)
		row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
		row:RegisterForDrag("LeftButton")
		row:RegisterForClicks("AnyUp", "AnyDown")
		row:SetScript("OnDragStart", function()
			app.Window:StartMoving()
			GameTooltip:ClearLines()
			GameTooltip:Hide()
		end)
		row:SetScript("OnDragStop", function() app.SaveWindow() end)
		row:SetScript("OnEnter", function()
			-- Show item tooltip if hovering over the actual row
			GameTooltip:ClearLines()

			-- Set the tooltip to either the left or right, depending on where the window is placed
			if GetScreenWidth()/2-userSettings["windowPosition"].width/2-app.Window:GetLeft() >= 0 then
				GameTooltip:SetOwner(app.Window, "ANCHOR_NONE")
				GameTooltip:SetPoint("LEFT", app.Window, "RIGHT")
			else
				GameTooltip:SetOwner(app.Window, "ANCHOR_NONE")
				GameTooltip:SetPoint("RIGHT", app.Window, "LEFT")
			end
			GameTooltip:SetHyperlink(recipeInfo.link)
			GameTooltip:Show()
		end)
		row:SetScript("OnLeave", function()
			GameTooltip:ClearLines()
			GameTooltip:Hide()
		end)
		row:SetScript("OnClick", function(self, button)
			-- Get the selected recipe ID
			local selectedRecipeID = recipeInfo.recipeID

			-- Right-click on recipe amount
			if button == "RightButton" then
				-- Untrack the recipe
				if IsControlKeyDown() == true then
					app.UntrackRecipe(selectedRecipeID, 0)
				else
					app.UntrackRecipe(selectedRecipeID, 1)
				end

				-- Show windows
				app.Show()
			-- Left-click on recipe
			elseif button == "LeftButton" then
				-- If Shift is held also
				if IsShiftKeyDown() == true then
					-- Try write link to chat
					ChatEdit_InsertLink(recipeInfo.link)
				-- If Control is held also
				elseif IsControlKeyDown() == true then
					-- Open recipe if it is learned
					if selectedRecipeID ~= 0 and C_TradeSkillUI.IsRecipeProfessionLearned(selectedRecipeID) == true then C_TradeSkillUI.OpenRecipe(selectedRecipeID) end
				end
			end
		end)

		recipeRow[rowNo] = row

		local tradeskill = 999
		if fakeRecipeLibrary[recipeInfo.recipeID] then
			tradeskill = fakeRecipeLibrary[recipeInfo.recipeID].tradeskillID
		elseif recipeLibrary[recipeInfo.recipeID] then
	   		tradeskill = recipeLibrary[recipeInfo.recipeID].tradeskillID or 999
		end

		local icon1 = row:CreateFontString("ARTWORK", nil, "GameFontNormal")
		icon1:SetPoint("LEFT", row)
		icon1:SetScale(1.2)
		icon1:SetText("|T"..app.iconProfession[tradeskill]..":0|t")

		local text2 = row:CreateFontString("ARTWORK", nil, "GameFontNormal")
		text2:SetPoint("CENTER", icon1)
		text2:SetPoint("RIGHT", app.Window.Child)
		text2:SetJustifyH("RIGHT")
		text2:SetTextColor(1, 1, 1)
		text2:SetText(recipeInfo.quantity)

		local text1 = row:CreateFontString("ARTWORK", nil, "GameFontNormal")
		text1:SetPoint("LEFT", icon1, "RIGHT", 3, 0)
		text1:SetPoint("RIGHT", text2, "LEFT")
		text1:SetTextColor(1, 1, 1)
		text1:SetText(recipeInfo.link)
		text1:SetJustifyH("LEFT")
		text1:SetWordWrap(false)

		maxLength1 = math.max(icon1:GetStringWidth()+text1:GetStringWidth()+text2:GetStringWidth(), maxLength1)
	end

	local rowNo2 = 0
	local showReagents = true

	if not app.Window.Reagents then
		app.Window.Reagents = CreateFrame("Button", nil, app.Window.Child)
		app.Window.Reagents:SetSize(0,16)
		app.Window.Reagents:SetPoint("RIGHT", app.Window.Child)
		app.Window.Reagents:RegisterForDrag("LeftButton")
		app.Window.Reagents:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
		app.Window.Reagents:SetScript("OnDragStart", function()
			app.Window:StartMoving()
			GameTooltip:ClearLines()
			GameTooltip:Hide()
		end)
		app.Window.Reagents:SetScript("OnDragStop", function() app.SaveWindow() end)
		app.Window.Reagents:SetScript("OnEnter", function()
			-- Set the tooltip to either the left or right, depending on where the window is placed
			if GetScreenWidth()/2-userSettings["windowPosition"].width/2-app.Window:GetLeft() >= 0 then
				reagentHeaderTooltip:ClearAllPoints()
				reagentHeaderTooltip:SetPoint("LEFT", app.Window, "RIGHT", 0, 0)
			else
				reagentHeaderTooltip:ClearAllPoints()
				reagentHeaderTooltip:SetPoint("RIGHT", app.Window, "LEFT", 0, 0)
			end
			reagentHeaderTooltip:Show()
		end)
		app.Window.Reagents:SetScript("OnLeave", function()
			reagentHeaderTooltip:Hide()
		end)
		
		local reagents1 = app.Window.Reagents:CreateFontString("ARTWORK", nil, "GameFontNormal")
		reagents1:SetPoint("LEFT", app.Window.Reagents)
		reagents1:SetText(PROFESSIONS_COLUMN_HEADER_REAGENTS)
		reagents1:SetScale(1.1)
		app.ReagentHeader = reagents1
	end
	if rowNo == 0 then
		app.Window.Reagents:SetPoint("TOPLEFT", app.Window.Recipes, "BOTTOMLEFT", 0, -2)
	else
		app.Window.Reagents:SetPoint("TOPLEFT", app.Window.Recipes, "BOTTOMLEFT", 0, rowNo*-16)
	end
	app.Window.Reagents:SetScript("OnClick", function(self)
		local children = {self:GetChildren()}

		if showReagents == true then
			for _, child in ipairs(children) do child:Hide() end
			app.Window.Cooldowns:SetPoint("TOPLEFT", app.Window.Reagents, "BOTTOMLEFT", 0, -2)
			showReagents = false
		else
			for _, child in ipairs(children) do child:Show() end
			local offset = -2
			if #reagentRow >= 1 then offset = -16*#reagentRow end
			app.Window.Cooldowns:SetPoint("TOPLEFT", app.Window.Reagents, "BOTTOMLEFT", 0, offset)
			showReagents = true
		end
	end)

	reagentsSorted = {}
	for k, v in pairs(app.ReagentQuantities) do
		if not reagentCache[k] then
			C_Timer.After(1, function() app.UpdateRecipes() end)
			do return end
		end
		reagentsSorted[#reagentsSorted+1] = {reagentID = k, quantity = v, icon = reagentCache[k].icon, link = reagentCache[k].link}
	end

	for _, reagentInfo in ipairs(reagentsSorted) do
		rowNo2 = rowNo2 + 1

		local row = CreateFrame("Button", nil, app.Window.Reagents, "", reagentInfo.reagentID)
		row:SetSize(0,16)
		row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
		row:RegisterForDrag("LeftButton")
		row:SetScript("OnDragStart", function()
			app.Window:StartMoving()
			GameTooltip:ClearLines()
			GameTooltip:Hide()
		end)
		row:SetScript("OnDragStop", function() app.SaveWindow() end)
		row:SetScript("OnEnter", function()
			-- Show item tooltip if hovering over the actual row
			GameTooltip:ClearLines()
			
			-- Set the tooltip to either the left or right, depending on where the window is placed
			if GetScreenWidth()/2-userSettings["windowPosition"].width/2-app.Window:GetLeft() >= 0 then
				GameTooltip:SetOwner(app.Window, "ANCHOR_NONE")
				GameTooltip:SetPoint("LEFT", app.Window, "RIGHT")
			else
				GameTooltip:SetOwner(app.Window, "ANCHOR_NONE")
				GameTooltip:SetPoint("RIGHT", app.Window, "LEFT")
			end
			GameTooltip:SetHyperlink(reagentInfo.link)
			GameTooltip:Show()
		end)
		row:SetScript("OnLeave", function()
			GameTooltip:ClearLines()
			GameTooltip:Hide()
		end)
		row:SetScript("OnClick", function(self, button)
			local function trackSubreagent(recipeID, itemID)
				-- Define the amount of recipes to be tracked
				local quantityMade = C_TradeSkillUI.GetRecipeSchematic(recipeID, false).quantityMin
				local amount = math.max(0, math.ceil((app.ReagentQuantities[itemID] - GetItemCount(itemID, true, false, true)) / quantityMade))
				if recipesTracked[recipeID] then amount = math.max(0, (amount - recipesTracked[recipeID].quantity)) end

				-- Track the recipe (don't track if 0)
				if amount > 0 then app.TrackRecipe(recipeID, amount) end
			end

			-- Control+click on reagent
			if button == "LeftButton" and IsControlKeyDown() == true then
				-- Get itemIDs
				local itemID = reagentInfo.reagentID
				if reagentTiers[itemID] then itemID = reagentTiers[itemID].one end

				-- Get possible recipeIDs
				local recipeIDs = {}
				local no = 0

				for recipe, recipeInfo in pairs(recipeLibrary) do
					if type(recipeInfo) ~= "number" then	-- Because of old recipeLibrary
						if recipeInfo.itemID == itemID and not app.nyiRecipes[recipe] then
							no = no + 1
							recipeIDs[no] = recipe
						end
					end
				end

				-- If there is only one possible recipe, use that
				if no == 1 then
					trackSubreagent(recipeIDs[1], itemID)
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
					pslOptionText:SetText("|cffFFFFFFThere are multiple recipes which can create\n"..reagentInfo.link..".\n\nPlease select one of the following:")

					-- Text
					local pslOption1 = f:CreateFontString("ARTWORK", nil, "GameFontNormal")
					pslOption1:SetPoint("LEFT", f, "LEFT", 10, 0)
					pslOption1:SetPoint("TOP", pslOptionText, "BOTTOM", 0, -40)
					pslOption1:SetWidth(200)
					pslOption1:SetJustifyH("LEFT")
					pslOption1:SetText("|cffFFFFFF")

					-- Get reagents #1
					local reagentsTable = {}
					app.GetReagents(reagentsTable, recipeIDs[1], 1, false)

					-- Create text #1
					for reagentID, reagentAmount in pairs(reagentsTable) do
						-- Get info
						local function getInfo()
							-- Cache item
							if not C_Item.IsItemDataCachedByID(reagentID) then local item = Item:CreateFromItemID(reagentID) end

							-- Get item info
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
						trackSubreagent(recipeIDs[1], itemID)

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
						app.GetReagents(reagentsTable, recipeIDs[2], 1, false)

						-- Create text #2
						for reagentID, reagentAmount in pairs(reagentsTable) do
							-- Get info
							local function getInfo()
								-- Cache item
								if not C_Item.IsItemDataCachedByID(reagentID) then local item = Item:CreateFromItemID(reagentID) end

								-- Get item info
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

						-- Button #2
						pslOptionButton2 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
						pslOptionButton2:SetText(C_TradeSkillUI.GetRecipeSchematic(recipeIDs[2], false).name)
						pslOptionButton2:SetWidth(200)
						pslOptionButton2:SetPoint("BOTTOM", pslOption2, "TOP", 0, 5)
						pslOptionButton2:SetPoint("CENTER", pslOption2, "CENTER", 0, 0)
						pslOptionButton2:SetScript("OnClick", function()
							trackSubreagent(recipeIDs[2], itemID)

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
						app.GetReagents(reagentsTable, recipeIDs[3], 1, false)

						-- Create text #3
						for reagentID, reagentAmount in pairs(reagentsTable) do
							-- Get info
							local function getInfo()
								-- Cache item
								if not C_Item.IsItemDataCachedByID(reagentID) then local item = Item:CreateFromItemID(reagentID) end
								
								-- Get item info
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
							trackSubreagent(recipeIDs[3], itemID)

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
						app.GetReagents(reagentsTable, recipeIDs[4], 1, false)

						-- Create text #4
						for reagentID, reagentAmount in pairs(reagentsTable) do
							-- Get info
							local function getInfo()
								-- Cache item
								if not C_Item.IsItemDataCachedByID(reagentID) then local item = Item:CreateFromItemID(reagentID) end

								-- Get item info
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

						-- Button #4
						pslOptionButton4 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
						pslOptionButton4:SetText(C_TradeSkillUI.GetRecipeSchematic(recipeIDs[4], false).name)
						pslOptionButton4:SetWidth(200)
						pslOptionButton4:SetPoint("BOTTOM", pslOption4, "TOP", 0, 5)
						pslOptionButton4:SetPoint("CENTER", pslOption4, "CENTER", 0, 0)
						pslOptionButton4:SetScript("OnClick", function()
							trackSubreagent(recipeIDs[4], itemID)

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
						app.GetReagents(reagentsTable, recipeIDs[5], 1, false)

						-- Create text #5
						for reagentID, reagentAmount in pairs(reagentsTable) do
							-- Get info
							local function getInfo()
								-- Cache item
								if not C_Item.IsItemDataCachedByID(reagentID) then local item = Item:CreateFromItemID(reagentID) end

								-- Get item info
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

						-- Button #5
						pslOptionButton5 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
						pslOptionButton5:SetText(C_TradeSkillUI.GetRecipeSchematic(recipeIDs[5], false).name)
						pslOptionButton5:SetWidth(200)
						pslOptionButton5:SetPoint("BOTTOM", pslOption5, "TOP", 0, 5)
						pslOptionButton5:SetPoint("CENTER", pslOption5, "CENTER", 0, 0)
						pslOptionButton5:SetScript("OnClick", function()
							trackSubreagent(recipeIDs[5], itemID)

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
						app.GetReagents(reagentsTable, recipeIDs[6], 1, false)

						-- Create text #6
						for reagentID, reagentAmount in pairs(reagentsTable) do
							-- Get info
							local function getInfo()
								-- Cache item
								if not C_Item.IsItemDataCachedByID(reagentID) then local item = Item:CreateFromItemID(reagentID) end

								-- Get item info
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

						-- Button #6
						pslOptionButton6 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
						pslOptionButton6:SetText(C_TradeSkillUI.GetRecipeSchematic(recipeIDs[6], false).name)
						pslOptionButton6:SetWidth(200)
						pslOptionButton6:SetPoint("BOTTOM", pslOption6, "TOP", 0, 5)
						pslOptionButton6:SetPoint("CENTER", pslOption6, "CENTER", 0, 0)
						pslOptionButton6:SetScript("OnClick", function()
							trackSubreagent(recipeIDs[6], itemID)

							-- Hide the subreagents window
							f:Hide()
						end)
					end
				end
			-- Activate if Shift+clicking on the reagents column
			elseif button == "LeftButton" and IsShiftKeyDown() == true then
				ChatEdit_InsertLink(reagentInfo.link)
			end
		end)

		reagentRow[rowNo2] = row

		local icon1 = row:CreateFontString("ARTWORK", nil, "GameFontNormal")
		icon1:SetPoint("LEFT", row)
		icon1:SetScale(1.2)
		icon1:SetText("|T"..reagentInfo.icon..":0|t")
		row.icon = icon1

		local text2 = row:CreateFontString("ARTWORK", nil, "GameFontNormal")
		text2:SetPoint("CENTER", icon1)
		text2:SetPoint("RIGHT", app.Window.Child)
		text2:SetJustifyH("RIGHT")
		text2:SetTextColor(1, 1, 1)
		text2:SetText(reagentInfo.quantity)
		row.text2 = text2

		local text1 = row:CreateFontString("ARTWORK", nil, "GameFontNormal")
		text1:SetPoint("LEFT", icon1, "RIGHT", 3, 0)
		text1:SetPoint("RIGHT", text2, "LEFT")
		text1:SetTextColor(1, 1, 1)
		text1:SetText(reagentInfo.link)
		text1:SetJustifyH("LEFT")
		text1:SetWordWrap(false)
		row.text1 = text1

		maxLength2 = math.max(icon1:GetStringWidth()+text1:GetStringWidth()+text2:GetStringWidth(), maxLength2)
	end

	-- Check what is being tracked
	local trackRecipes = false
	local trackItems = false
	for k, v in pairs(recipesTracked) do
		if type(k) == "number" then
			trackRecipes = true
		else
			trackItems = true
		end
	end

	-- Set the header title accordingly
	if trackRecipes == true and trackItems == true then
		app.RecipeHeader:SetText(PROFESSIONS_RECIPES_TAB.." & "..ITEMS)
		app.ReagentHeader:SetText(PROFESSIONS_COLUMN_HEADER_REAGENTS.." & Costs")
	elseif trackRecipes == false and trackItems == true then
		app.RecipeHeader:SetText(ITEMS)
		app.ReagentHeader:SetText("Costs")
	else
		app.RecipeHeader:SetText(PROFESSIONS_RECIPES_TAB)
		app.ReagentHeader:SetText(PROFESSIONS_COLUMN_HEADER_REAGENTS)
	end

	local rowNo3 = 0
	local showCooldowns = true

	-- TODO: Use offset like with reagents
	if not app.Window.Cooldowns then
		app.Window.Cooldowns = CreateFrame("Button", nil, app.Window.Child)
		app.Window.Cooldowns:SetSize(0,16)
		app.Window.Cooldowns:SetPoint("RIGHT", app.Window.Child)
		app.Window.Cooldowns:RegisterForDrag("LeftButton")
		app.Window.Cooldowns:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
		app.Window.Cooldowns:SetScript("OnDragStart", function()
			app.Window:StartMoving()
			GameTooltip:ClearLines()
			GameTooltip:Hide()
		end)
		app.Window.Cooldowns:SetScript("OnDragStop", function() app.SaveWindow() end)
		app.Window.Cooldowns:SetScript("OnEnter", function()
			-- Set the tooltip to either the left or right, depending on where the window is placed
			if GetScreenWidth()/2-userSettings["windowPosition"].width/2-app.Window:GetLeft() >= 0 then
				cooldownHeaderTooltip:ClearAllPoints()
				cooldownHeaderTooltip:SetPoint("LEFT", app.Window, "RIGHT", 0, 0)
			else
				cooldownHeaderTooltip:ClearAllPoints()
				cooldownHeaderTooltip:SetPoint("RIGHT", app.Window, "LEFT", 0, 0)
			end
			cooldownHeaderTooltip:Show()
		end)
		app.Window.Cooldowns:SetScript("OnLeave", function()
			cooldownHeaderTooltip:Hide()
		end)
		
		local cooldowns1 = app.Window.Cooldowns:CreateFontString("ARTWORK", nil, "GameFontNormal")
		cooldowns1:SetPoint("LEFT", app.Window.Cooldowns)
		cooldowns1:SetText("Cooldowns")
		cooldowns1:SetScale(1.1)
	end

	local next = next
	if next(recipeCooldowns) == nil or userSettings["showRecipeCooldowns"] == false then
		app.Window.Cooldowns:Hide()
		showCooldowns = false
	else
		app.Window.Cooldowns:Show()
	end

	local offset = -2
	if rowNo2 >= 1 then offset = -16*#reagentRow end
	app.Window.Cooldowns:SetPoint("TOPLEFT", app.Window.Reagents, "BOTTOMLEFT", 0, offset)

	app.Window.Cooldowns:SetScript("OnClick", function(self)
		local children = {self:GetChildren()}

		if showCooldowns == true then
			for i_, child in ipairs(children) do child:Hide() end
			showCooldowns = false
		else
			for i_, child in ipairs(children) do child:Show() end
			showCooldowns = true
		end
	end)

	cooldownsSorted = {}
	for k, v in pairs(recipeCooldowns) do
		local timedone = v.start + v.cooldown
		cooldownsSorted[#cooldownsSorted+1] = {id = k, recipeID = v.recipeID, start = v.start, cooldown = v.cooldown, name = v.name, user = v.user, time = timedone, maxCharges = v.maxCharges, charges = v.charges}
	end
	table.sort(cooldownsSorted, function(a, b) return a.time > b.time end)

	for _, cooldownInfo in pairs(cooldownsSorted) do
		rowNo3 = rowNo3 + 1

		local row = CreateFrame("Button", nil, app.Window.Cooldowns, "", cooldownInfo.id)
		row:SetSize(0,16)
		row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
		row:RegisterForDrag("LeftButton")
		row:RegisterForClicks("AnyDown", "AnyUp")
		row:SetScript("OnDragStart", function()
			app.Window:StartMoving()
			GameTooltip:ClearLines()
			GameTooltip:Hide()
		end)
		row:SetScript("OnDragStop", function() app.SaveWindow() end)
		row:SetScript("OnEnter", function()
			if not cooldownTooltip then
				cooldownTooltip = CreateFrame("Frame", nil, app.Window, "BackdropTemplate")
				cooldownTooltip:SetPoint("CENTER")
				cooldownTooltip:SetFrameStrata("TOOLTIP")
				cooldownTooltip:SetBackdrop({
					bgFile = "Interface/Tooltips/UI-Tooltip-Background",
					edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
					edgeSize = 16,
					insets = { left = 4, right = 4, top = 4, bottom = 4 },
				})
				cooldownTooltip:SetBackdropColor(0, 0, 0, 0.9)
				cooldownTooltip:EnableMouse(false)
				cooldownTooltip:SetMovable(false)
				cooldownTooltip:Hide()

				cooldownTooltipText = cooldownTooltip:CreateFontString("ARTWORK", nil, "GameFontNormal")
				cooldownTooltipText:SetPoint("TOPLEFT", cooldownTooltip, "TOPLEFT", 10, -10)
				cooldownTooltipText:SetJustifyH("LEFT")
			end

			-- Set the tooltip text
			cooldownTooltipText:SetText("|cffFFFFFF"..cooldownInfo.user)

			-- Set the tooltip size to fit its contents
			cooldownTooltip:SetHeight(cooldownTooltipText:GetStringHeight()+20)
			cooldownTooltip:SetWidth(cooldownTooltipText:GetStringWidth()+20)

			-- Set the tooltip to either the left or right, depending on where the window is placed
			if GetScreenWidth()/2-userSettings["windowPosition"].width/2-app.Window:GetLeft() >= 0 then
				cooldownTooltip:ClearAllPoints()
				cooldownTooltip:SetPoint("LEFT", app.Window, "RIGHT", 0, 0)
			else
				cooldownTooltip:ClearAllPoints()
				cooldownTooltip:SetPoint("RIGHT", app.Window, "LEFT", 0, 0)
			end	

			-- Show item tooltip if hovering over the actual row
			cooldownTooltip:Show()
		end)
		row:SetScript("OnLeave", function()
			cooldownTooltip:ClearAllPoints()
			cooldownTooltip:Hide()
		end)
		row:SetScript("OnClick", function(self, button)
			if button == "RightButton" then
				recipeCooldowns[cooldownInfo.id] = nil
				app.UpdateRecipes()
			end
		end)

		cooldownRow[rowNo3] = row
		if rowNo3 == 1 then
			row:SetPoint("TOPLEFT", app.Window.Cooldowns, "BOTTOMLEFT")
			row:SetPoint("TOPRIGHT", app.Window.Cooldowns, "BOTTOMRIGHT")
		else
			row:SetPoint("TOPLEFT", cooldownRow[rowNo3-1], "BOTTOMLEFT")
			row:SetPoint("TOPRIGHT", cooldownRow[rowNo3-1], "BOTTOMRIGHT")
		end

		local tradeskill = recipeLibrary[cooldownInfo.recipeID].tradeskillID or 999

		local icon1 = row:CreateFontString("ARTWORK", nil, "GameFontNormal")
		icon1:SetPoint("LEFT", row)
		icon1:SetScale(1.2)
		icon1:SetText("|T"..app.iconProfession[tradeskill]..":0|t")
		row.icon = icon1

		local cooldownRemaining = cooldownInfo.start + cooldownInfo.cooldown - GetServerTime()
		local days, hours, minutes

		days = math.floor(cooldownRemaining/(60*60*24))
		hours = math.floor((cooldownRemaining - (days*60*60*24))/(60*60))
		minutes = math.floor((cooldownRemaining - ((days*60*60*24) + (hours*60*60)))/60)

		local text2 = row:CreateFontString("ARTWORK", nil, "GameFontNormal")
		text2:SetPoint("CENTER", icon1)
		text2:SetPoint("RIGHT", app.Window.Child)
		text2:SetJustifyH("RIGHT")
		text2:SetTextColor(1, 1, 1)
		if cooldownRemaining <= 0 then
			text2:SetText("Ready")
		elseif cooldownRemaining < 60*60 then
			text2:SetText(minutes.."m")
		elseif cooldownRemaining < 60*60*24 then
			text2:SetText(hours.."h "..minutes.."m")
		else
			text2:SetText(days.."d "..hours.."h "..minutes.."m")
		end
		row.text2 = text2

		local text1 = row:CreateFontString("ARTWORK", nil, "GameFontNormal")
		text1:SetPoint("LEFT", icon1, "RIGHT", 3, 0)
		text1:SetPoint("RIGHT", text2, "LEFT")
		text1:SetTextColor(1, 1, 1)
		if cooldownInfo.maxCharges > 0 then
			text1:SetText(cooldownInfo.name .. " (" .. cooldownInfo.charges .. "/" .. cooldownInfo.maxCharges .. ")")
		else
			text1:SetText(cooldownInfo.name)
		end
		text1:SetJustifyH("LEFT")
		text1:SetWordWrap(false)
		row.text1 = text1

		maxLength3 = math.max(icon1:GetStringWidth()+text1:GetStringWidth()+text2:GetStringWidth(), maxLength3)
	end
	
	app.Window.Corner:SetScript("OnDoubleClick", function (self, button)
		local windowHeight = 62
		local windowWidth = 0
		if userSettings["showRecipeCooldowns"] == false then
			windowHeight = windowHeight - 16
		elseif showCooldowns == true then
			windowHeight = windowHeight + rowNo3 * 16
			windowWidth = math.max(windowWidth, maxLength3, app.UpdatedCooldownWidth)
		end
		if showReagents == true then
			windowHeight = windowHeight + rowNo2 * 16
			windowWidth = math.max(windowWidth, maxLength2, app.UpdatedReagentWidth)
		end
		if showRecipes == true then
			windowHeight = windowHeight + rowNo * 16
			windowWidth = math.max(windowWidth, maxLength1)
		end
		if showRecipes == false or #recipesTracked < 1 then
			windowHeight = windowHeight + 2	-- Not sure why this is needed, but whatever
		end
		if windowHeight > 600 then windowHeight = 600 end
		if windowWidth > 600 then windowWidth = 600 end
		app.Window:SetHeight(math.max(140,windowHeight))
		app.Window:SetWidth(math.max(140,windowWidth+40))
		app.Window.ScrollFrame:SetVerticalScroll(0)
		app.SaveWindow()
	end)
	app.Window.Corner:SetScript("OnEnter", function()
		-- Set the tooltip to either the left or right, depending on where the window is placed
		if GetScreenWidth()/2-userSettings["windowPosition"].width/2-app.Window:GetLeft() >= 0 then
			cornerTooltip:ClearAllPoints()
			cornerTooltip:SetPoint("LEFT", app.Window, "RIGHT", 0, 0)
		else
			cornerTooltip:ClearAllPoints()
			cornerTooltip:SetPoint("RIGHT", app.Window, "LEFT", 0, 0)
		end
		cornerTooltip:Show()
	end)
	app.Window.Corner:SetScript("OnLeave", function()
		cornerTooltip:Hide()
	end)

	-- Check if the Untrack button should be enabled
	if not recipesTracked[app.SelectedRecipeID] or recipesTracked[app.SelectedRecipeID].quantity == 0 then
		if app.Flag["tradeskillAssets"] == true then
			untrackProfessionButton:Disable()
			untrackMakeOrderButton:Disable()
		end
		if app.Flag["craftingOrderAssets"] == true then
			untrackPlaceOrderButton:Disable()
		end
	else
		if app.Flag["tradeskillAssets"] == true then
			untrackProfessionButton:Enable()
			untrackMakeOrderButton:Enable()
		end
		if app.Flag["craftingOrderAssets"] == true then
			untrackPlaceOrderButton:Enable()
		end
	end

	-- Check if the making crafting orders Untrack button should be enabled
	if app.OrderRecipeID ~= 0 and app.Flag["tradeskillAssets"] == true then
		if not recipesTracked[app.OrderRecipeID] or recipesTracked[app.OrderRecipeID].quantity == 0 then
			untrackMakeOrderButton:Disable()
		else
			untrackMakeOrderButton:Enable()
		end
	end

	app.UpdateNumbers()
end

-- Show windows and update numbers
function app.Show()
	-- Set window to its proper position and size
	app.Window:ClearAllPoints()
	if userSettings["pcWindows"] == true then
		app.Window:SetSize(userSettings["pcWindowPosition"].width, userSettings["pcWindowPosition"].height)
		app.Window:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", userSettings["pcWindowPosition"].left, userSettings["pcWindowPosition"].bottom)
	else
		app.Window:SetSize(userSettings["windowPosition"].width, userSettings["windowPosition"].height)
		app.Window:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", userSettings["windowPosition"].left, userSettings["windowPosition"].bottom)
	end

	-- Show the windows
	app.Window:Show()

	-- Update numbers
	app.UpdateRecipes()
end

-- Toggle windows
function app.Toggle()
	-- Toggle tracking windows
	if app.Window:IsShown() then
		app.Window:Hide()
	else
		app.Show()
	end
end

-- Track recipe
function app.TrackRecipe(recipeID, recipeQuantity)
	-- 2 = Salvage, recipes without reagents | Disable these, cause they shouldn't be tracked
	if C_TradeSkillUI.GetRecipeSchematic(recipeID,false).recipeType == 2 or C_TradeSkillUI.GetRecipeSchematic(recipeID,false).reagentSlotSchematics[1] == nil then
		do return end
	end
	
	-- Adjust the recipeID for SL legendary crafts, if a custom rank is entered
	if app.slLegendaryRecipeIDs[recipeID] then
		local rank = math.floor(ebSLrank:GetNumber())
		if rank == 1 then
			recipeID = app.slLegendaryRecipeIDs[recipeID].one
		elseif rank == 2 then
			recipeID = app.slLegendaryRecipeIDs[recipeID].two
		elseif rank == 3 then
			recipeID = app.slLegendaryRecipeIDs[recipeID].three
		elseif rank == 4 then
			recipeID = app.slLegendaryRecipeIDs[recipeID].four
		end
	end

	-- Get some basic info
	local recipeType = C_TradeSkillUI.GetRecipeSchematic(recipeID,false).recipeType
	local recipeMin = C_TradeSkillUI.GetRecipeSchematic(recipeID,false).quantityMin
	local recipeMax = C_TradeSkillUI.GetRecipeSchematic(recipeID,false).quantityMax

	-- Add recipe link for crafted items
	local recipeLink

	if recipeType == 1 then
		local itemID = C_TradeSkillUI.GetRecipeSchematic(recipeID,false).outputItemID
		local _, itemLink
		if itemID ~= nil then
			-- Cache item
			if not C_Item.IsItemDataCachedByID(itemID) then local item = Item:CreateFromItemID(itemID) end

			-- Get item info
			_, itemLink = GetItemInfo(itemID)

			-- Try again if error
			if itemLink == nil then
				RunNextFrame(function() app.TrackRecipe(recipeID, recipeQuantity) end)
				do return end
			end
		-- Exception for stuff like Abominable Stitching
		else
			itemLink = C_TradeSkillUI.GetRecipeSchematic(recipeID,false).name
		end

		-- Exceptions for SL legendary crafts
		if app.slLegendaryRecipeIDs[recipeID] then
			itemLink = itemLink.." (Rank "..app.slLegendaryRecipeIDs[recipeID].rank..")" -- Append the rank
		else
			itemLink = string.gsub(itemLink, " |A:Professions%-ChatIcon%-Quality%-Tier1:17:15::1|a", "") -- Remove the quality from the item string
		end

		-- Add quantity
		if recipeMin == recipeMax and recipeMin ~= 1 then
			itemLink = itemLink.." ×"..recipeMin
		elseif recipeMin ~= 1 then
			itemLink = itemLink.." ×"..recipeMin.."-"..recipeMax
		end

		recipeLink = itemLink

	-- Add recipe "link" for enchants
	elseif recipeType == 3 then recipeLink = C_TradeSkillUI.GetRecipeSchematic(recipeID,false).name
	end

	-- Track recipe
	if not recipesTracked[recipeID] then recipesTracked[recipeID] = { quantity = 0, recraft = app.Flag["recraft"], link = recipeLink } end
	recipesTracked[recipeID].quantity = recipesTracked[recipeID].quantity + recipeQuantity

	-- Show windows
	app.Show()	-- This also triggers the recipe update

	-- Update the editbox
	if app.Flag["tradeskillAssets"] == true then
		ebRecipeQuantityNo = recipesTracked[recipeID].quantity or 0
		ebRecipeQuantity:SetText(ebRecipeQuantityNo)
	end
end

-- Untrack recipe
function app.UntrackRecipe(recipeID, recipeQuantity)
	if recipesTracked[recipeID] ~= nil then
		-- Clear all recipes if quantity was set to 0
		if recipeQuantity == 0 then recipesTracked[recipeID].quantity = 0 end

		-- Untrack recipe
		recipesTracked[recipeID].quantity = recipesTracked[recipeID].quantity - recipeQuantity

		-- Set numbers to nil if it doesn't exist anymore
		if recipesTracked[recipeID].quantity <= 0 then
			recipesTracked[recipeID] = nil
		end
	end

	-- Clear the cache if no recipes are tracked anymore
	local next = next
	if next(recipesTracked) == nil then app.Clear() end

	-- Update numbers
	app.UpdateRecipes()

	-- Update the editbox
	if app.Flag["tradeskillAssets"] == true then
		if recipesTracked[app.SelectedRecipeID] then
			ebRecipeQuantityNo = recipesTracked[app.SelectedRecipeID].quantity
		else
			ebRecipeQuantityNo = 0
		end
		ebRecipeQuantity:SetText(ebRecipeQuantityNo)
	end
end

-- Create assets
function app.CreateGeneralAssets()
	-- Create Recipes header tooltip
	if not recipeHeaderTooltip then
		recipeHeaderTooltip = CreateFrame("Frame", nil, app.Window, "BackdropTemplate")
		recipeHeaderTooltip:SetFrameStrata("TOOLTIP")
		recipeHeaderTooltip:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})
		recipeHeaderTooltip:SetBackdropColor(0, 0, 0, 0.9)
		recipeHeaderTooltip:EnableMouse(false)
		recipeHeaderTooltip:SetMovable(false)
		recipeHeaderTooltip:Hide()

		recipeHeaderTooltipText = recipeHeaderTooltip:CreateFontString("ARTWORK", nil, "GameFontNormal")
		recipeHeaderTooltipText:SetPoint("TOPLEFT", recipeHeaderTooltip, "TOPLEFT", 10, -10)
		recipeHeaderTooltipText:SetJustifyH("LEFT")
		recipeHeaderTooltipText:SetText("Shift+click|cffFFFFFF: Link the recipe.\n|RCtrl+click|cffFFFFFF: Open the recipe (if known on current character).\n|RRight-click|cffFFFFFF: Untrack 1 of the selected recipe.\n|RCtrl+right-click|cffFFFFFF: Untrack all of the selected recipe.")

		-- Set the tooltip size to fit its contents
		recipeHeaderTooltip:SetHeight(recipeHeaderTooltipText:GetStringHeight()+20)
		recipeHeaderTooltip:SetWidth(recipeHeaderTooltipText:GetStringWidth()+20)
	end

	-- Create Reagents header tooltip
	if not reagentHeaderTooltip then
		reagentHeaderTooltip = CreateFrame("Frame", nil, app.Window, "BackdropTemplate")
		reagentHeaderTooltip:SetFrameStrata("TOOLTIP")
		reagentHeaderTooltip:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})
		reagentHeaderTooltip:SetBackdropColor(0, 0, 0, 0.9)
		reagentHeaderTooltip:EnableMouse(false)
		reagentHeaderTooltip:SetMovable(false)
		reagentHeaderTooltip:Hide()

		reagentHeaderTooltipText = reagentHeaderTooltip:CreateFontString("ARTWORK", nil, "GameFontNormal")
		reagentHeaderTooltipText:SetPoint("TOPLEFT", reagentHeaderTooltip, "TOPLEFT", 10, -10)
		reagentHeaderTooltipText:SetJustifyH("LEFT")
		reagentHeaderTooltipText:SetText("Shift+click|cffFFFFFF: Link the reagent.\n|RCtrl+click|cffFFFFFF: Add recipe for the selected subreagent, if it exists.\n(This only works for professions that have been opened with PSL active.)\nThe reagents listed here can also be imported to a new Auctionator shopping list.")

		-- Set the tooltip size to fit its contents
		reagentHeaderTooltip:SetHeight(reagentHeaderTooltipText:GetStringHeight()+20)
		reagentHeaderTooltip:SetWidth(reagentHeaderTooltipText:GetStringWidth()+20)
	end

	-- Create Cooldowns header tooltip
	if not cooldownHeaderTooltip then
		cooldownHeaderTooltip = CreateFrame("Frame", nil, app.Window, "BackdropTemplate")
		cooldownHeaderTooltip:SetFrameStrata("TOOLTIP")
		cooldownHeaderTooltip:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})
		cooldownHeaderTooltip:SetBackdropColor(0, 0, 0, 0.9)
		cooldownHeaderTooltip:EnableMouse(false)
		cooldownHeaderTooltip:SetMovable(false)
		cooldownHeaderTooltip:Hide()

		cooldownHeaderTooltipText = cooldownHeaderTooltip:CreateFontString("ARTWORK", nil, "GameFontNormal")
		cooldownHeaderTooltipText:SetPoint("TOPLEFT", cooldownHeaderTooltip, "TOPLEFT", 10, -10)
		cooldownHeaderTooltipText:SetJustifyH("LEFT")
		cooldownHeaderTooltipText:SetText("Right+click|cffFFFFFF: Remove the cooldown reminder.")

		-- Set the tooltip size to fit its contents
		cooldownHeaderTooltip:SetHeight(cooldownHeaderTooltipText:GetStringHeight()+20)
		cooldownHeaderTooltip:SetWidth(cooldownHeaderTooltipText:GetStringWidth()+20)
	end

	-- Create window corner tooltip
	if not cornerTooltip then
		cornerTooltip = CreateFrame("Frame", nil, app.Window, "BackdropTemplate")
		cornerTooltip:SetFrameStrata("TOOLTIP")
		cornerTooltip:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})
		cornerTooltip:SetBackdropColor(0, 0, 0, 0.9)
		cornerTooltip:EnableMouse(false)
		cornerTooltip:SetMovable(false)
		cornerTooltip:Hide()

		cornerTooltipText = cornerTooltip:CreateFontString("ARTWORK", nil, "GameFontNormal")
		cornerTooltipText:SetPoint("TOPLEFT", cornerTooltip, "TOPLEFT", 10, -10)
		cornerTooltipText:SetJustifyH("LEFT")
		cornerTooltipText:SetText("Double-click|cffFFFFFF: Autosize to fit the window.")

		-- Set the tooltip size to fit its contents
		cornerTooltip:SetHeight(cornerTooltipText:GetStringHeight()+20)
		cornerTooltip:SetWidth(cornerTooltipText:GetStringWidth()+20)
	end
end

function app.CreateTradeskillAssets()
	-- Hide and disable existing tracking buttons
	ProfessionsFrame.CraftingPage.SchematicForm.TrackRecipeCheckBox:SetAlpha(0)
	ProfessionsFrame.CraftingPage.SchematicForm.TrackRecipeCheckBox:EnableMouse(false)

	-- Create the profession UI track button
	if not trackProfessionButton then
		trackProfessionButton = CreateFrame("Button", nil, ProfessionsFrame.CraftingPage, "UIPanelButtonTemplate")
		trackProfessionButton:SetText("Track")
		trackProfessionButton:SetWidth(60)
		trackProfessionButton:SetPoint("TOPRIGHT", ProfessionsFrame.CraftingPage.SchematicForm, "TOPRIGHT", -9, -10)
		trackProfessionButton:SetFrameStrata("HIGH")
		trackProfessionButton:SetScript("OnClick", function()
			app.TrackRecipe(app.SelectedRecipeID, 1)
		end)
	end
	
	-- Create the profession UI quantity editbox
	if not ebRecipeQuantityNo then ebRecipeQuantityNo = 0 end
	local function ebRecipeQuantityUpdate(self, newValue)
		-- Get the entered number cleanly
		newValue = math.floor(self:GetNumber())
		-- If the value is positive, change the number of recipes tracked
		if newValue >= 0 then
			app.UntrackRecipe(app.SelectedRecipeID,0)
			if newValue >0 then
				app.TrackRecipe(app.SelectedRecipeID, newValue)
			end
		end
	end
	if not ebRecipeQuantity then
		ebRecipeQuantity = CreateFrame("EditBox", nil, ProfessionsFrame.CraftingPage, "InputBoxTemplate")
		ebRecipeQuantity:SetSize(25,20)
		ebRecipeQuantity:SetPoint("CENTER", trackProfessionButton, "CENTER", 0, 0)
		ebRecipeQuantity:SetPoint("RIGHT", trackProfessionButton, "LEFT", -4, 0)
		ebRecipeQuantity:SetAutoFocus(false)
		ebRecipeQuantity:SetText(ebRecipeQuantityNo)
		ebRecipeQuantity:SetCursorPosition(0)
		ebRecipeQuantity:SetScript("OnEditFocusLost", function(self, newValue)
			ebRecipeQuantityUpdate(self, newValue)
		end)
		ebRecipeQuantity:SetScript("OnEnterPressed", function(self, newValue)
			ebRecipeQuantityUpdate(self, newValue)
			self:ClearFocus()
		end)
		ebRecipeQuantity:SetScript("OnEscapePressed", function(self, newValue)
			self:SetText(ebRecipeQuantityNo)
		end)
	end

	-- Create the profession UI untrack button
	if not untrackProfessionButton then
		untrackProfessionButton = CreateFrame("Button", nil, ProfessionsFrame.CraftingPage, "UIPanelButtonTemplate")
		untrackProfessionButton:SetText("Untrack")
		untrackProfessionButton:SetWidth(70)
		untrackProfessionButton:SetPoint("TOPRIGHT", trackProfessionButton, "TOPLEFT", -38, 0)
		untrackProfessionButton:SetFrameStrata("HIGH")
		untrackProfessionButton:SetScript("OnClick", function()
			app.UntrackRecipe(app.SelectedRecipeID, 1)
	
			-- Show windows
			app.Show()
		end)
	end

	-- Create the rank editbox for SL legendary recipes
	if not ebSLrank then
		ebSLrank = CreateFrame("EditBox", nil, ProfessionsFrame.CraftingPage, "InputBoxTemplate")
		ebSLrank:SetSize(25,20)
		ebSLrank:SetPoint("CENTER", ebRecipeQuantity, "CENTER", 0, 0)
		ebSLrank:SetPoint("TOP", ebRecipeQuantity, "BOTTOM", 0, -4)
		ebSLrank:SetAutoFocus(false)
		ebSLrank:SetCursorPosition(0)
		ebSLrank:Hide()
	end
	if not ebSLrankText then
		ebSLrankText = ProfessionsFrame.CraftingPage.SchematicForm:CreateFontString("ARTWORK", nil, "GameFontNormal")
		ebSLrankText:SetPoint("RIGHT", ebSLrank, "LEFT", -10, 0)
		ebSLrankText:SetJustifyH("LEFT")
		ebSLrankText:SetText("Rank:")
		ebSLrankText:Hide()
	end

	-- Create Cooking Fire button
	if not cookingFireButton then
		cookingFireButton = CreateFrame("Button", "CookingFireButton", ProfessionsFrame.CraftingPage, "SecureActionButtonTemplate")
		cookingFireButton:SetWidth(40)
		cookingFireButton:SetHeight(40)
		cookingFireButton:SetNormalTexture(135805)
		cookingFireButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
		cookingFireButton:SetPoint("BOTTOMRIGHT", ProfessionsFrame.CraftingPage.SchematicForm, "BOTTOMRIGHT", -5, 4)
		cookingFireButton:SetFrameStrata("HIGH")
		cookingFireButton:RegisterForClicks("AnyDown", "AnyUp")
		cookingFireButton:SetAttribute("type", "spell")
		cookingFireButton:SetAttribute("spell1", 818)
		cookingFireButton:SetAttribute("unit1", "player")
		cookingFireButton:SetAttribute("spell2", 818)

		cookingFireCooldown = CreateFrame("Cooldown", "CookingFireCooldown", cookingFireButton, "CooldownFrameTemplate")
		cookingFireCooldown:SetAllPoints(cookingFireButton)
		cookingFireCooldown:SetSwipeColor(1, 1, 1)
	end

	-- Create Chef's Hat button
	if not chefsHatButton then
		chefsHatButton = CreateFrame("Button", "ChefsHatButton", ProfessionsFrame.CraftingPage, "SecureActionButtonTemplate")
		chefsHatButton:SetWidth(40)
		chefsHatButton:SetHeight(40)
		chefsHatButton:SetNormalTexture(236571)
		chefsHatButton:GetNormalTexture():SetDesaturated(true)
		chefsHatButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
		chefsHatButton:SetPoint("BOTTOMRIGHT", cookingFireButton, "BOTTOMLEFT", -3, 0)
		chefsHatButton:SetFrameStrata("HIGH")
		chefsHatButton:RegisterForClicks("AnyDown", "AnyUp")
		chefsHatButton:SetAttribute("type1", "toy")
		chefsHatButton:SetAttribute("toy", 134020)

		chefsHatCooldown = CreateFrame("Cooldown", "ChefsHatCooldown", chefsHatButton, "CooldownFrameTemplate")
		chefsHatCooldown:SetAllPoints(chefsHatButton)
		chefsHatCooldown:SetSwipeColor(1, 1, 1)
	end

	-- Create Thermal Anvil button
	if not thermalAnvilButton then
		thermalAnvilButton = CreateFrame("Button", "ThermalAnvilButton", ProfessionsFrame.CraftingPage, "SecureActionButtonTemplate")
		thermalAnvilButton:SetWidth(40)
		thermalAnvilButton:SetHeight(40)
		thermalAnvilButton:SetNormalTexture(136241)
		thermalAnvilButton:GetNormalTexture():SetDesaturated(true)
		thermalAnvilButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
		thermalAnvilButton:SetPoint("BOTTOMRIGHT", ProfessionsFrame.CraftingPage.SchematicForm, "BOTTOMRIGHT", -5, 4)
		thermalAnvilButton:SetFrameStrata("HIGH")
		thermalAnvilButton:RegisterForClicks("AnyDown", "AnyUp")
		thermalAnvilButton:SetAttribute("type1", "macro")
		thermalAnvilButton:SetAttribute("macrotext1", "/use item:87216")

		thermalAnvilCooldown = CreateFrame("Cooldown", "ThermalAnvilCooldown", thermalAnvilButton, "CooldownFrameTemplate")
		thermalAnvilCooldown:SetAllPoints(thermalAnvilButton)
		thermalAnvilCooldown:SetSwipeColor(1, 1, 1)

		thermalAnvilCharges = thermalAnvilButton:CreateFontString("ARTWORK", nil, "GameFontNormal")
		thermalAnvilCharges:SetPoint("BOTTOMRIGHT", thermalAnvilButton, "BOTTOMRIGHT", 0, 0)
		thermalAnvilCharges:SetJustifyH("RIGHT")
		if not C_Item.IsItemDataCachedByID(87216) then local item = Item:CreateFromItemID(87216) end
		local anvilCharges = GetItemCount(87216, false, true, false)
		thermalAnvilCharges:SetText(anvilCharges)
	end

	-- Create Alvin the Anvil button
	if not alvinButton then
		alvinButton = CreateFrame("Button", "AlvinButton", ProfessionsFrame.CraftingPage, "SecureActionButtonTemplate")
		alvinButton:SetWidth(40)
		alvinButton:SetHeight(40)
		alvinButton:SetNormalTexture(1020356)
		alvinButton:GetNormalTexture():SetDesaturated(true)
		alvinButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
		alvinButton:SetPoint("BOTTOMRIGHT", thermalAnvilButton, "BOTTOMLEFT", -3, 0)
		alvinButton:SetFrameStrata("HIGH")
		alvinButton:RegisterForClicks("AnyDown", "AnyUp")
		alvinButton:SetAttribute("type1", "macro")

		alvinCooldown = CreateFrame("Cooldown", "AlvinCooldown", alvinButton, "CooldownFrameTemplate")
		alvinCooldown:SetAllPoints(alvinButton)
		alvinCooldown:SetSwipeColor(1, 1, 1)
	end

	-- Create Lightforged Draenei Lightforge button
	if not lightforgeButton then
		lightforgeButton = CreateFrame("Button", "LightforgeButton", ProfessionsFrame.CraftingPage, "SecureActionButtonTemplate")
		lightforgeButton:SetWidth(40)
		lightforgeButton:SetHeight(40)
		lightforgeButton:SetNormalTexture(1723995)
		lightforgeButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
		lightforgeButton:SetPoint("BOTTOMRIGHT", alvinButton, "BOTTOMLEFT", -3, 0)
		lightforgeButton:SetFrameStrata("HIGH")
		lightforgeButton:RegisterForClicks("AnyDown", "AnyUp")
		lightforgeButton:SetAttribute("type", "spell")
		lightforgeButton:SetAttribute("spell", 259930)
		lightforgeButton:Hide()

		lightforgeCooldown = CreateFrame("Cooldown", "LightforgeCooldown", lightforgeButton, "CooldownFrameTemplate")
		lightforgeCooldown:SetAllPoints(lightforgeButton)
		lightforgeCooldown:SetSwipeColor(1, 1, 1)
	end

	-- Create Dragonflight Milling info
	if not millingDragonflight then
		millingDragonflight = ProfessionsFrame.CraftingPage.SchematicForm:CreateFontString("ARTWORK", nil, "GameFontNormal")
		millingDragonflight:SetPoint("BOTTOMLEFT", ProfessionsFrame.CraftingPage.SchematicForm, "BOTTOMLEFT", 30, 30)
		millingDragonflight:SetJustifyH("LEFT")
		millingDragonflight:SetText("|cffFFFFFFFlourishing Pigment: Writhebark\nSerene Pigment: Bubble Poppy\nBlazing Pigment: Saxifrage\nShimmering Pigment: Hochenblume")
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
		knowledgePointTracker.Text = knowledgePointTracker.Bar:CreateFontString("OVERLAY", nil, "GameFontNormalOutline")
		knowledgePointTracker.Text:SetPoint("CENTER", knowledgePointTracker, "CENTER", 0, 0)
		knowledgePointTracker.Text:SetTextColor(1, 1, 1, 1)
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

	-- Create the fulfil crafting orders UI Track button
	if not trackMakeOrderButton then
		trackMakeOrderButton = CreateFrame("Button", nil, ProfessionsFrame.OrdersPage.OrderView.OrderDetails, "UIPanelButtonTemplate")
		trackMakeOrderButton:SetText("Track")
		trackMakeOrderButton:SetWidth(60)
		trackMakeOrderButton:SetPoint("TOPRIGHT", ProfessionsFrame.OrdersPage.OrderView.OrderDetails, "TOPRIGHT", -9, -10)
		trackMakeOrderButton:SetFrameStrata("HIGH")
		trackMakeOrderButton:SetScript("OnClick", function()
			local oldIsRecraft = app.Flag["recraft"]
			if ProfessionsFrame.OrdersPage.OrderView.OrderDetails.SchematicForm.RecraftingOutputText:IsVisible() == true then
				app.Flag["recraft"] = true
			end

			if app.OrderRecipeID == 0 then
				app.TrackRecipe(app.SelectedRecipeID, 1)
			else
				app.TrackRecipe(app.OrderRecipeID, 1)
			end

			if ProfessionsFrame.OrdersPage.OrderView.OrderDetails.SchematicForm.RecraftingOutputText:IsVisible() == true then
				app.Flag["recraft"] = oldIsRecraft
			end

			-- Show windows
			app.Show()
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
			if app.OrderRecipeID == 0 then
				app.UntrackRecipe(app.SelectedRecipeID, 1)
			else
				app.UntrackRecipe(app.OrderRecipeID, 1)
			end

			-- Show windows
			app.Show()
		end)
	end

	-- Set the flag for assets created to true
	app.Flag["tradeskillAssets"] = true
end

function app.CreateCraftingOrdersAssets()
	-- Hide and disable existing tracking buttons
	ProfessionsCustomerOrdersFrame.Form.TrackRecipeCheckBox:SetAlpha(0)
	ProfessionsCustomerOrdersFrame.Form.TrackRecipeCheckBox:EnableMouse(false)

	-- Create the place crafting orders UI Track button
	if not trackPlaceOrderButton then
		trackPlaceOrderButton = CreateFrame("Button", nil, ProfessionsCustomerOrdersFrame.Form, "UIPanelButtonTemplate")
		trackPlaceOrderButton:SetText("Track")
		trackPlaceOrderButton:SetWidth(60)
		trackPlaceOrderButton:SetPoint("TOPLEFT", ProfessionsCustomerOrdersFrame.Form, "TOPLEFT", 12, -73)
		trackPlaceOrderButton:SetFrameStrata("HIGH")
		trackPlaceOrderButton:SetScript("OnClick", function()
			app.TrackRecipe(app.SelectedRecipeID, 1)
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
			app.UntrackRecipe(app.SelectedRecipeID, 1)
	
			-- Show windows
			app.Show()
		end)
	end

	-- Create the place crafting orders UI personal order name field
	if not personalCharname then
		personalCharname = CreateFrame("EditBox", nil, ProfessionsCustomerOrdersFrame.Form, "InputBoxTemplate")
		personalCharname:SetSize(80,20)
		personalCharname:SetPoint("CENTER", trackPlaceOrderButton, "CENTER", 0, 0)
		personalCharname:SetPoint("LEFT", trackPlaceOrderButton, "LEFT", 415, 0)
		personalCharname:SetAutoFocus(false)
		personalCharname:SetCursorPosition(0)
		personalCharname:SetScript("OnEditFocusLost", function(self)
			personalOrders[app.SelectedRecipeID] = tostring(personalCharname:GetText())
			app.UpdateAssets()
		end)
		personalCharname:SetScript("OnEnterPressed", function(self)
			personalOrders[app.SelectedRecipeID] = tostring(personalCharname:GetText())
			self:ClearFocus()
			app.UpdateAssets()
		end)
		personalCharname:SetScript("OnEscapePressed", function(self)
			app.UpdateAssets()
		end)
		personalCharname:SetScript("OnEnter", function()
			personalOrderTooltip:Show()
		end)
		personalCharname:SetScript("OnLeave", function()
			personalOrderTooltip:Hide()
		end)
	end

	local function quickOrder(recipeID)
		-- Create crafting info variables
		local reagentInfo = {}
		local craftingReagentInfo = {}

		-- Signal that PSL is currently working on a quick order
		app.Flag["quickOrder"] = 1

		local function localReagentsOrder()
			-- Cache reagent tier info
			local _ = {}
			app.GetReagents(_, recipeID, 1, false)

			-- Get recipe info
			local recipeInfo = C_TradeSkillUI.GetRecipeSchematic(recipeID, false).reagentSlotSchematics
			
			-- Go through all the reagents for this recipe
			local no1 = 1
			local no2 = 1
			for i, _ in ipairs(recipeInfo) do
				if recipeInfo[i].reagentType == 1 then
					-- Get the required quantity
					local quantityNo = recipeInfo[i].quantityRequired

					-- Get the primary reagent itemID
					local reagentID = recipeInfo[i].reagents[1].itemID

					-- Add the info for tiered reagents to craftingReagentItems
					if reagentTiers[reagentID].three ~= 0 then
						-- Set it to the lowest quality we have enough of for this order
						if GetItemCount(reagentTiers[reagentID].one, true, false, true) >= quantityNo then
							craftingReagentInfo[no1] = {itemID = reagentTiers[reagentID].one, dataSlotIndex = i, quantity = quantityNo}
							no1 = no1 + 1
						elseif GetItemCount(reagentTiers[reagentID].two, true, false, true) >= quantityNo then
							craftingReagentInfo[no1] = {itemID = reagentTiers[reagentID].two, dataSlotIndex = i, quantity = quantityNo}
							no1 = no1 + 1
						elseif GetItemCount(reagentTiers[reagentID].three, true, false, true) >= quantityNo then
							craftingReagentInfo[no1] = {itemID = reagentTiers[reagentID].three, dataSlotIndex = i, quantity = quantityNo}
							no1 = no1 + 1
						end
					-- Add the info for non-tiered reagents to reagentItems
					else
						if GetItemCount(reagentID, true, false, true) >= quantityNo then
							reagentInfo[no2] = {itemID = reagentTiers[reagentID].one, quantity = quantityNo}
							no2 = no2 + 1
						end
					end
				end
			end
		end

		-- Only add the reagentInfo if the option is enabled
		if userSettings["useLocalReagents"] == true then localReagentsOrder() end

		-- Signal that PSL is currently working on a quick order with local reagents, if applicable
		local next = next
		if next(craftingReagentInfo) ~= nil and userSettings["useLocalReagents"] == true then
			app.Flag["quickOrder"] = 2
		end

		-- Place the order
		C_CraftingOrders.PlaceNewOrder({ skillLineAbilityID=recipeLibrary[recipeID].abilityID, orderType=2, orderDuration=0, tipAmount=100, customerNotes="", orderTarget=personalOrders[recipeID], reagentItems=reagentInfo, craftingReagentItems=craftingReagentInfo })
		
		-- If there are tiered reagents and the user wants to use local reagents, adjust the dataSlotIndex and try again in case the first one failed
		local next = next
		if next(craftingReagentInfo) ~= nil and userSettings["useLocalReagents"] == true then
			for i, _ in ipairs(craftingReagentInfo) do
				craftingReagentInfo[i].dataSlotIndex = math.max(craftingReagentInfo[i].dataSlotIndex - 1, 0)
			end

			-- Place the alternative order (only one can succeed, worst case scenario it'll fail again)
			C_CraftingOrders.PlaceNewOrder({ skillLineAbilityID=recipeLibrary[recipeID].abilityID, orderType=2, orderDuration=0, tipAmount=100, customerNotes="", orderTarget=personalOrders[recipeID], reagentItems=reagentInfo, craftingReagentItems=craftingReagentInfo })
		
			for i, _ in ipairs(craftingReagentInfo) do
				craftingReagentInfo[i].dataSlotIndex = math.max(craftingReagentInfo[i].dataSlotIndex - 1, 0)
			end

			-- Place the alternative order (only one can succeed, worst case scenario it'll fail again)
			C_CraftingOrders.PlaceNewOrder({ skillLineAbilityID=recipeLibrary[recipeID].abilityID, orderType=2, orderDuration=0, tipAmount=100, customerNotes="", orderTarget=personalOrders[recipeID], reagentItems=reagentInfo, craftingReagentItems=craftingReagentInfo })
		
			for i, _ in ipairs(craftingReagentInfo) do
				craftingReagentInfo[i].dataSlotIndex = math.max(craftingReagentInfo[i].dataSlotIndex - 1, 0)
			end

			-- Place the alternative order (only one can succeed, worst case scenario it'll fail again)
			C_CraftingOrders.PlaceNewOrder({ skillLineAbilityID=recipeLibrary[recipeID].abilityID, orderType=2, orderDuration=0, tipAmount=100, customerNotes="", orderTarget=personalOrders[recipeID], reagentItems=reagentInfo, craftingReagentItems=craftingReagentInfo })
		end
	end

	-- Create the place crafting orders personal order button
	if not personalOrderButton then
		personalOrderButton = CreateFrame("Button", nil, ProfessionsCustomerOrdersFrame.Form, "UIPanelButtonTemplate")
		personalOrderButton:SetText("Quick Order")
		personalOrderButton:SetWidth(90)
		personalOrderButton:SetPoint("CENTER", personalCharname, "CENTER", 0, 0)
		personalOrderButton:SetPoint("RIGHT", personalCharname, "LEFT", -8, 0)
		personalOrderButton:SetFrameStrata("HIGH")
		personalOrderButton:SetScript("OnClick", function()
			quickOrder(app.SelectedRecipeID)
		end)
	end

	-- Create the place crafting orders personal order button tooltip
	if not personalOrderTooltip then
		personalOrderTooltip = CreateFrame("Frame", nil, personalOrderButton, "BackdropTemplate")
		personalOrderTooltip:SetPoint("CENTER")
		personalOrderTooltip:SetPoint("TOP", personalOrderButton, "BOTTOM", 0, 0)
		personalOrderTooltip:SetFrameStrata("TOOLTIP")
		personalOrderTooltip:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})

		personalOrderTooltip:SetBackdropColor(0, 0, 0, 0.9)
		personalOrderTooltip:EnableMouse(false)
		personalOrderTooltip:SetMovable(false)
		personalOrderTooltip:Hide()

		personalOrderTooltipText = personalOrderTooltip:CreateFontString("ARTWORK", nil, "GameFontNormal")
		personalOrderTooltipText:SetPoint("TOPLEFT", personalOrderTooltip, "TOPLEFT", 10, -10)
		personalOrderTooltipText:SetJustifyH("LEFT")
		personalOrderTooltipText:SetText("|cffFF0000Instantly|r create a personal crafting order\n(12 hours, 1 silver) for the specified character.\n\nCharacter names are saved per recipe.\n\nIf the button is |cff9D9D9Dgreyed|r out, you need to open\nthe profession the recipe is for once to cache it\nand/or enter a character to send the order to.")

		-- Set the tooltip size to fit its contents
		personalOrderTooltip:SetHeight(personalOrderTooltipText:GetStringHeight()+20)
		personalOrderTooltip:SetWidth(personalOrderTooltipText:GetStringWidth()+20)
	end

	-- Create the local reagents checkbox
	if not cbUseLocalReagents then
		cbUseLocalReagents = CreateFrame("CheckButton", nil, ProfessionsCustomerOrdersFrame.Form, "InterfaceOptionsCheckButtonTemplate")
		cbUseLocalReagents.Text:SetText("Use local reagents")
		cbUseLocalReagents.Text:SetTextColor(1, 1, 1, 1)
		cbUseLocalReagents.Text:SetScale(1.2)
		cbUseLocalReagents:SetPoint("BOTTOMLEFT", personalOrderButton, "TOPLEFT", 0, 0)
		cbUseLocalReagents:SetFrameStrata("HIGH")
		cbUseLocalReagents:SetChecked(userSettings["useLocalReagents"])
		cbUseLocalReagents:SetScript("OnClick", function(self)
			userSettings["useLocalReagents"] = self:GetChecked()

			if personalOrders["last"] ~= nil then
				local reagents = "false"
				local recipient = personalOrders[personalOrders["last"]]
				if userSettings["useLocalReagents"] == true then reagents = "true" end
				repeatOrderTooltipText:SetText("Repeat the last Quick Order done on this character.\nRecipient: "..recipient.."\nUse local reagents: "..reagents)
				repeatOrderTooltip:SetHeight(repeatOrderTooltipText:GetStringHeight()+20)
				repeatOrderTooltip:SetWidth(repeatOrderTooltipText:GetStringWidth()+20)
			end
		end)
		cbUseLocalReagents:SetScript("OnEnter", function()
			useLocalReagentsTooltip:Show()
		end)
		cbUseLocalReagents:SetScript("OnLeave", function()
			useLocalReagentsTooltip:Hide()
		end)
	end

	-- Create the local reagents tooltip
	if not useLocalReagentsTooltip then
		useLocalReagentsTooltip = CreateFrame("Frame", nil, cbUseLocalReagents, "BackdropTemplate")
		useLocalReagentsTooltip:SetPoint("CENTER")
		useLocalReagentsTooltip:SetPoint("TOP", cbUseLocalReagents, "BOTTOM", 0, 0)
		useLocalReagentsTooltip:SetFrameStrata("TOOLTIP")
		useLocalReagentsTooltip:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})
		useLocalReagentsTooltip:SetBackdropColor(0, 0, 0, 0.9)
		useLocalReagentsTooltip:EnableMouse(false)
		useLocalReagentsTooltip:SetMovable(false)
		useLocalReagentsTooltip:Hide()

		useLocalReagentsTooltipText = useLocalReagentsTooltip:CreateFontString("ARTWORK", nil, "GameFontNormal")
		useLocalReagentsTooltipText:SetPoint("TOPLEFT", useLocalReagentsTooltip, "TOPLEFT", 10, -10)
		useLocalReagentsTooltipText:SetJustifyH("LEFT")
		useLocalReagentsTooltipText:SetText("Use (the lowest quality) available local reagents.\nWhich reagents are used |cffFF0000cannot|r be customised.")

		-- Set the tooltip size to fit its contents
		useLocalReagentsTooltip:SetHeight(useLocalReagentsTooltipText:GetStringHeight()+20)
		useLocalReagentsTooltip:SetWidth(useLocalReagentsTooltipText:GetStringWidth()+20)
	end

	-- Create the repeat last crafting order button
	if not repeatOrderButton then
		repeatOrderButton = CreateFrame("Button", nil, ProfessionsCustomerOrdersFrame, "UIPanelButtonTemplate")
		repeatOrderButton:SetPoint("BOTTOMLEFT", ProfessionsCustomerOrdersFrame, 170, 5)
		repeatOrderButton:SetFrameStrata("HIGH")
		repeatOrderButton:SetScript("OnClick", function()
			if personalOrders["last"] ~= nil then
				quickOrder(personalOrders["last"])
			else
				app.Print("No last Quick Order found.")
			end
		end)
		repeatOrderButton:SetScript("OnEnter", function()
			repeatOrderTooltip:Show()
		end)
		repeatOrderButton:SetScript("OnLeave", function()
			repeatOrderTooltip:Hide()
		end)

		-- Set the last used recipe name for the repeat order button title
		local recipeName = "No last Quick Order found"
		-- Check for the name if there has been a last order
		if personalOrders["last"] ~= nil then
			recipeName = C_TradeSkillUI.GetRecipeSchematic(personalOrders["last"], false).name
		end
		repeatOrderButton:SetText(recipeName)
		repeatOrderButton:SetWidth(repeatOrderButton:GetTextWidth()+20)
	end

	-- Create the local reagents tooltip
	if not repeatOrderTooltip then
		repeatOrderTooltip = CreateFrame("Frame", nil, repeatOrderButton, "BackdropTemplate")
		repeatOrderTooltip:SetPoint("CENTER")
		repeatOrderTooltip:SetPoint("TOP", repeatOrderButton, "BOTTOM", 0, 0)
		repeatOrderTooltip:SetFrameStrata("TOOLTIP")
		repeatOrderTooltip:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})
		repeatOrderTooltip:SetBackdropColor(0, 0, 0, 0.9)
		repeatOrderTooltip:EnableMouse(false)
		repeatOrderTooltip:SetMovable(false)
		repeatOrderTooltip:Hide()

		repeatOrderTooltipText = repeatOrderTooltip:CreateFontString("ARTWORK", nil, "GameFontNormal")
		repeatOrderTooltipText:SetPoint("TOPLEFT", repeatOrderTooltip, "TOPLEFT", 10, -10)
		repeatOrderTooltipText:SetJustifyH("LEFT")
		if personalOrders["last"] ~= nil then
			local reagents = "false"
			local recipient = personalOrders[personalOrders["last"]]
			if userSettings["useLocalReagents"] == true then reagents = "true" end
			repeatOrderTooltipText:SetText("Repeat the last Quick Order done on this character.\nRecipient: "..recipient.."\nUse local reagents: "..reagents)
		else
			repeatOrderTooltipText:SetText("Repeat the last Quick Order done on this character.")
		end
		
		-- Set the tooltip size to fit its contents
		repeatOrderTooltip:SetHeight(repeatOrderTooltipText:GetStringHeight()+20)
		repeatOrderTooltip:SetWidth(repeatOrderTooltipText:GetStringWidth()+20)
	end

	-- Set the flag for assets created to true
	app.Flag["craftingOrderAssets"] = true
end

-- Update assets
function app.UpdateAssets()
	if app.Flag["tradeskillAssets"] == true then
		-- Enable tracking button for 1 = Item, 3 = Enchant
		if pslRecipeType == 1 or pslRecipeType == 3 then
			trackProfessionButton:Enable()
			ebRecipeQuantity:Enable()
		end

		-- Disable tracking button for 2 = Salvage, recipes without reagents
		if pslRecipeType == 2 or C_TradeSkillUI.GetRecipeSchematic(app.SelectedRecipeID,false).reagentSlotSchematics[1] == nil then
			trackProfessionButton:Disable()
			untrackProfessionButton:Disable()
			ebRecipeQuantity:Disable()
		end

		-- Enable tracking button for tracked recipes
		if not recipesTracked[app.SelectedRecipeID] or recipesTracked[app.SelectedRecipeID].quantity == 0 then
			untrackProfessionButton:Disable()
		else
			untrackProfessionButton:Enable()
		end

		-- Update the quantity textbox
		if ebRecipeQuantityNo ~= nil then
			if recipesTracked[app.SelectedRecipeID] then
				ebRecipeQuantityNo = recipesTracked[app.SelectedRecipeID].quantity
			else
				ebRecipeQuantityNo = 0
			end
			ebRecipeQuantity:SetText(ebRecipeQuantityNo)
		end

		-- Make the Chef's Hat button not desaturated if it can be used
		if PlayerHasToy(134020) and C_TradeSkillUI.GetProfessionInfoBySkillLineID(2546).skillLevel >= 25 then
			chefsHatButton:GetNormalTexture():SetDesaturated(false)
		end

		-- Check how many thermal anvils the player has
		if not C_Item.IsItemDataCachedByID(87216) then local item = Item:CreateFromItemID(87216) end
		local anvilCount = GetItemCount(87216)
		-- (De)saturate based on that
		if anvilCount >= 1 then
			thermalAnvilButton:GetNormalTexture():SetDesaturated(false)
		else
			thermalAnvilButton:GetNormalTexture():SetDesaturated(true)
		end
		-- Update charges
		local anvilCharges = GetItemCount(87216, false, true, false)
		thermalAnvilCharges:SetText(anvilCharges)

		-- Cooking Fire button cooldown
		local start, duration = GetSpellCooldown(818)
		CookingFireCooldown:SetCooldown(start, duration)

		-- Chef's Hat button cooldown
		start, duration = GetItemCooldown(134020)
		ChefsHatCooldown:SetCooldown(start, duration)

		-- Thermal Anvil button cooldown
		start, duration = GetItemCooldown(87216)
		thermalAnvilCooldown:SetCooldown(start, duration)

		-- Make the Alvin the Anvil button not desaturated if it can be used
		if C_PetJournal.PetIsSummonable(userSettings["alvinGUID"]) == true then
			alvinButton:GetNormalTexture():SetDesaturated(false)
		end

		-- Alvin button cooldown
		start, duration = GetSpellCooldown(61304)	-- Global spell cooldown
		alvinCooldown:SetCooldown(start, duration)

		-- Lightforge cooldown
		start, duration = GetSpellCooldown(259930)
		lightforgeCooldown:SetCooldown(start, duration)
	end

	-- Enable tracking button for 1 = Item, 3 = Enchant
	if pslRecipeType == 1 or pslRecipeType == 3 then
		if app.Flag["craftingOrderAssets"] == true then
			trackPlaceOrderButton:Enable()
		end
		if app.Flag["tradeskillAssets"] == true then
			trackMakeOrderButton:Enable()
		end
	end

	-- Disable tracking button for 2 = Salvage, recipes without reagents
	if pslRecipeType == 2 or C_TradeSkillUI.GetRecipeSchematic(app.SelectedRecipeID,false).reagentSlotSchematics[1] == nil then
		if app.Flag["craftingOrderAssets"] == true then
			trackPlaceOrderButton:Disable()
			untrackPlaceOrderButton:Disable()
		end
		if app.Flag["tradeskillAssets"] == true then
			trackMakeOrderButton:Disable()
			untrackMakeOrderButton:Disable()
		end
	end

	-- Enable tracking button for tracked recipes
	if not recipesTracked[app.SelectedRecipeID] or recipesTracked[app.SelectedRecipeID].quantity == 0 then
		if app.Flag["craftingOrderAssets"] == true then
			untrackPlaceOrderButton:Disable()
		end
		if app.Flag["tradeskillAssets"] == true then
			untrackMakeOrderButton:Disable()
		end
	else
		if app.Flag["craftingOrderAssets"] == true then
			untrackPlaceOrderButton:Enable()
		end
		if app.Flag["tradeskillAssets"] == true then
			untrackMakeOrderButton:Enable()
		end
	end

	-- Remove the personal order entry if the value is ""
	if personalOrders[app.SelectedRecipeID] == "" then personalOrders[app.SelectedRecipeID] = nil end

	-- Enable the quick order button if abilityID and target are known
	if app.Flag["craftingOrderAssets"] == true then
		if recipeLibrary[app.SelectedRecipeID] and type(recipeLibrary[app.SelectedRecipeID]) ~= "number" then
			if recipeLibrary[app.SelectedRecipeID].abilityID ~= nil and personalOrders[app.SelectedRecipeID] ~= nil then
				personalOrderButton:Enable()
			else
				personalOrderButton:Disable()
			end
		else
			personalOrderButton:Disable()
		end

		-- Update the personal order name textbox
		if personalOrders[app.SelectedRecipeID] then
			personalCharname:SetText(personalOrders[app.SelectedRecipeID])
		else
			personalCharname:SetText("")
		end
	end
end

-- Tooltip information
function app.TooltipInfo()
	local function OnTooltipSetItem(tooltip)
		-- Only run this if the setting is enabled
		if userSettings["showTooltip"] == true then
			-- Get item info from tooltip
			local _, _, itemID = TooltipUtil.GetDisplayedItem(tooltip)

			-- Stop if error, it will try again on its own REAL soon
			if itemID == nil then return end

			-- Get owned number of reagents
			local reagentID1
			local reagentID2
			local reagentID3
			local reagentAmountHave1 = 0
			local reagentAmountHave2 = 0
			local reagentAmountHave3 = 0

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

			-- Calculate owned amount/needed based on item quality
			local reagentAmountHave = 0
			local reagentAmountNeed = 0
			if itemID == reagentID1 then
				reagentAmountHave = reagentAmountHave1 + reagentAmountHave2 + reagentAmountHave3
				reagentAmountNeed = app.ReagentQuantities[reagentID1]
			elseif itemID == reagentID2 then
				reagentAmountHave = reagentAmountHave2 + reagentAmountHave3
				reagentAmountNeed = app.ReagentQuantities[reagentID2]
			elseif itemID == reagentID3 then
				reagentAmountHave = reagentAmountHave3
				reagentAmountNeed = app.ReagentQuantities[reagentID3]
			end

			-- Add the tooltip info
			if (itemID == reagentID1 or itemID == reagentID2 or itemID == reagentID3) and reagentAmountNeed ~= 0 and reagentAmountNeed ~= nil then
				tooltip:AddLine(" ")
				tooltip:AddLine("PSL: "..reagentAmountHave.."/"..reagentAmountNeed.." ("..math.max(0,reagentAmountNeed-reagentAmountHave).." more needed)")
			end
		end
	end
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)
end

-- Clear everything except the recipe cache
function app.Clear()
	recipesTracked = {}
	reagentTiers = {}
	reagentCache = {}
	fakeRecipeLibrary = {}
	app.UpdateRecipes()
	app.Window.ScrollFrame:SetVerticalScroll(0)

	-- Disable remove button
	if app.Flag["tradeskillAssets"] == true then
		untrackProfessionButton:Disable()
		untrackMakeOrderButton:Disable()
	end
	if app.Flag["craftingOrderAssets"] == true then
		untrackPlaceOrderButton:Disable()
	end
end

-- Open settings
function app.OpenSettings()
	InterfaceOptionsFrame_OpenToCategory("Profession Shopping List")
end

function ProfessionShoppingList_Click(self, button)
	if button == "LeftButton" then
		app.Toggle()
	elseif button == "RightButton" then
		app.OpenSettings()
	end
end

function ProfessionShoppingList_Enter(self, button)
	GameTooltip:ClearLines()
	GameTooltip:SetOwner(type(self) ~= "string" and self or button, "ANCHOR_LEFT")
	GameTooltip:AddLine("|cffFFFFFFProfession Shopping List|R\n|cff9D9D9DLeft-click:|R Toggle the windows.\n|cff9D9D9DRight-click:|R Show the settings.")
	GameTooltip:Show()
end

function ProfessionShoppingList_Leave()
	GameTooltip:Hide()
end

-- Settings and minimap icon
function app.Settings()
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
				app.Toggle()
			elseif button == "RightButton" then
				app.OpenSettings()
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
	local scrollFrame = CreateFrame("ScrollFrame", nil, settings, "ScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", 0, 0)
	scrollFrame:SetPoint("BOTTOMRIGHT", -25, 0)	-- Allow space for the scrollbar

	local scrollChild = CreateFrame("Frame")
	scrollFrame:SetScrollChild(scrollChild)
	scrollChild:SetWidth(1)	-- This is automatically defined, so long as the attribute exists at all
	scrollChild:SetHeight(1)	-- This is automatically defined, so long as the attribute exists at all

	-- -- Subcategory
	-- local scrollFrame2 = CreateFrame("ScrollFrame", nil, self, "ScrollFrameTemplate")
	-- scrollFrame2:Hide()	-- I'm fairly sure this isn't how you're supposed to prevent the subcategories from showing initially, but it works!
	-- scrollFrame2.ScrollBar:ClearPoint("RIGHT")
	-- scrollFrame2.ScrollBar:SetPoint("RIGHT", -36, 0)

	-- local scrollChild2 = CreateFrame("Frame")
	-- scrollFrame2:SetScrollChild(scrollChild2)
	-- scrollChild2:SetWidth(1)    -- This is automatically defined, so long as the attribute exists at all
	-- scrollChild2:SetHeight(1)    -- This is automatically defined, so long as the attribute exists at all

	-- local subcategory1 = scrollFrame2
	-- subcategory1.name = "Hello"
	-- subcategory1.parent = "Profession Shopping List"
	-- InterfaceOptions_AddCategory(subcategory1)

	-- Settings
	-- TODO: functions for checkboxes, sliders, header and include cb:SetHitRectInsets(0,0 - cb.Text:GetWidth(),0,0);
	local title = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 0, 0)
	title:SetText("Profession Shopping List")

	local addonVersion = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
	addonVersion:SetPoint("TOPRIGHT", scrollChild, "TOPLEFT", 638, 0)
	addonVersion:SetText(GetAddOnMetadata("ProfessionShoppingList", "Version"))

	-- General
	local cbMinimapButton = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
	cbMinimapButton.Text:SetText("Minimap button")
	cbMinimapButton.Text:SetTextColor(1, 1, 1, 1)
	cbMinimapButton.Text:SetScale(1.2)
	cbMinimapButton:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
	cbMinimapButton:SetChecked(not userSettings["hide"])
	cbMinimapButton:SetScript("OnClick", function(self)
		userSettings["hide"] = not self:GetChecked()
		if userSettings["hide"] == true then
			icon:Hide("ProfessionShoppingList")
		else
			icon:Show("ProfessionShoppingList")
		end
	end)

	local cbHeaderTooltip = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
	cbHeaderTooltip.Text:SetText("Header tooltip")
	cbHeaderTooltip.Text:SetTextColor(1, 1, 1, 1)
	cbHeaderTooltip.Text:SetScale(1.2)
	cbHeaderTooltip:SetPoint("TOPLEFT", cbMinimapButton, "BOTTOMLEFT", 0, 0)
	cbHeaderTooltip:SetChecked(userSettings["headerTooltip"])
	cbHeaderTooltip:SetScript("OnClick", function(self)
		userSettings["headerTooltip"] = cbHeaderTooltip:GetChecked()
	end)

	local cbPcWindowPosition = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
	cbPcWindowPosition.Text:SetText("Save window positions per character")
	cbPcWindowPosition.Text:SetTextColor(1, 1, 1, 1)
	cbPcWindowPosition.Text:SetScale(1.2)
	cbPcWindowPosition:SetPoint("TOPLEFT", cbMinimapButton, "TOPLEFT", 240, 0)
	cbPcWindowPosition:SetChecked(userSettings["pcWindows"])
	cbPcWindowPosition:SetScript("OnClick", function(self)
		userSettings["pcWindows"] = self:GetChecked()
	end)

	local cbPcRecipesTracked = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
	cbPcRecipesTracked.Text:SetText("Track recipes per character")
	cbPcRecipesTracked.Text:SetTextColor(1, 1, 1, 1)
	cbPcRecipesTracked.Text:SetScale(1.2)
	cbPcRecipesTracked:SetPoint("TOPLEFT", cbPcWindowPosition, "BOTTOMLEFT", 0, 0)
	cbPcRecipesTracked:SetChecked(userSettings["pcRecipesTracked"])
	cbPcRecipesTracked:SetScript("OnClick", function(self)
		userSettings["pcRecipesTracked"] = cbPcRecipesTracked:GetChecked()
		app.UpdateRecipes()
	end)

	-- Category: List and tracking
	local titleListSettings = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
	titleListSettings:SetPoint("TOPLEFT", cbHeaderTooltip, "BOTTOMLEFT", 0, -10)
	titleListSettings:SetJustifyH("LEFT")
	titleListSettings:SetScale(1.2)
	titleListSettings:SetText("List and tracking")

	local cbCloseWhenDoneCheck	-- Declare it here, so we can reference it for all the option dependencies

	local cbRemoveCraft = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
	cbRemoveCraft.Text:SetText("Untrack on crafting")
	cbRemoveCraft.Text:SetTextColor(1, 1, 1, 1)
	cbRemoveCraft.Text:SetScale(1.2)
	cbRemoveCraft:SetPoint("TOPLEFT", titleListSettings, "BOTTOMLEFT", 0, 0)
	cbRemoveCraft:SetChecked(userSettings["removeCraft"])
	cbRemoveCraft:SetScript("OnClick", function(self)
		userSettings["removeCraft"] = cbRemoveCraft:GetChecked()
		cbCloseWhenDoneCheck()
	end)

	local cbCloseWhenDone = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
	cbCloseWhenDone.Text:SetText("Close windows when done")
	cbCloseWhenDone.Text:SetScale(1.2)
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
	cbShowRemaining.Text:SetScale(1.2)
	cbShowRemaining:SetPoint("TOPLEFT", cbCloseWhenDone, "BOTTOMLEFT", -15, 0)
	cbShowRemaining:SetChecked(userSettings["showRemaining"])
	cbShowRemaining:SetScript("OnClick", function(self)
		userSettings["showRemaining"] = cbShowRemaining:GetChecked()
		app.UpdateRecipes()
	end)

	local cbShowTooltip = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
	cbShowTooltip.Text:SetText("Show tooltip information")
	cbShowTooltip.Text:SetTextColor(1, 1, 1, 1)
	cbShowTooltip.Text:SetScale(1.2)
	cbShowTooltip:SetPoint("TOPLEFT", cbShowRemaining, "BOTTOMLEFT", 0, 0)
	cbShowTooltip:SetChecked(userSettings["showTooltip"])
	cbShowTooltip:SetScript("OnClick", function(self)
		userSettings["showTooltip"] = cbShowTooltip:GetChecked()
	end)

	local slReagentQuality = CreateFrame("Slider", nil, scrollChild, "UISliderTemplateWithLabels")
	slReagentQuality:SetPoint("TOPLEFT", cbShowTooltip, "BOTTOMLEFT", 5, -15)
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
	slReagentQuality.Label:SetText("Min: |A:Professions-ChatIcon-Quality-Tier"..slReagentQuality:GetValue()..":17:15::1|a")
	slReagentQuality:SetScript("OnValueChanged", function(self, newValue)
		userSettings["reagentQuality"] = newValue
		self:SetValue(userSettings["reagentQuality"])
		self.Label:SetText("Min: |A:Professions-ChatIcon-Quality-Tier"..slReagentQuality:GetValue()..":17:15::1|a")
		app.UpdateNumbers()
	end)

	-- Category: Knowledge Tracker
	local titleKnowledgeTracker = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
	titleKnowledgeTracker:SetPoint("TOPLEFT", slReagentQuality, "BOTTOMLEFT", -5, -25)
	titleKnowledgeTracker:SetJustifyH("LEFT")
	titleKnowledgeTracker:SetScale(1.2)
	titleKnowledgeTracker:SetText("Knowledge tracker")

	local cbShowKnowledgeNotPerks = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
	cbShowKnowledgeNotPerks.Text:SetText("Show knowledge, not perks")
	cbShowKnowledgeNotPerks.Text:SetTextColor(1, 1, 1, 1)
	cbShowKnowledgeNotPerks.Text:SetScale(1.2)
	cbShowKnowledgeNotPerks:SetPoint("TOPLEFT", titleKnowledgeTracker, "BOTTOMLEFT", 0, 0)
	cbShowKnowledgeNotPerks:SetChecked(userSettings["showKnowledgeNotPerks"])
	cbShowKnowledgeNotPerks:SetScript("OnClick", function(self)
		userSettings["showKnowledgeNotPerks"] = cbShowKnowledgeNotPerks:GetChecked()
	end)

	local cbKnowledgeHideDone = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
	cbKnowledgeHideDone.Text:SetText("Hide one-time knowledge if done")
	cbKnowledgeHideDone.Text:SetTextColor(1, 1, 1, 1)
	cbKnowledgeHideDone.Text:SetScale(1.2)
	cbKnowledgeHideDone:SetPoint("TOPLEFT", cbShowKnowledgeNotPerks, "BOTTOMLEFT", 0, 0)
	cbKnowledgeHideDone:SetChecked(userSettings["knowledgeHideDone"])
	cbKnowledgeHideDone:SetScript("OnClick", function(self)
		userSettings["knowledgeHideDone"] = cbKnowledgeHideDone:GetChecked()
	end)

	local cbKnowledgeAlwaysShowDetails = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
	cbKnowledgeAlwaysShowDetails.Text:SetText("Always show details")
	cbKnowledgeAlwaysShowDetails.Text:SetTextColor(1, 1, 1, 1)
	cbKnowledgeAlwaysShowDetails.Text:SetScale(1.2)
	cbKnowledgeAlwaysShowDetails:SetPoint("TOPLEFT", cbKnowledgeHideDone, "BOTTOMLEFT", 0, 0)
	cbKnowledgeAlwaysShowDetails:SetChecked(userSettings["knowledgeAlwaysShowDetails"])
	cbKnowledgeAlwaysShowDetails:SetScript("OnClick", function(self)
		userSettings["knowledgeAlwaysShowDetails"] = cbKnowledgeAlwaysShowDetails:GetChecked()
	end)

	-- Category: Other features
	local titleOtherFeatures = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
	titleOtherFeatures:SetPoint("TOPLEFT", titleKnowledgeTracker, "TOPLEFT", 240, -0)
	titleOtherFeatures:SetJustifyH("LEFT")
	titleOtherFeatures:SetScale(1.2)
	titleOtherFeatures:SetText("Other features")

	local cbShowRecipeCooldowns = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
	cbShowRecipeCooldowns.Text:SetText("Recipe cooldown reminders")
	cbShowRecipeCooldowns.Text:SetTextColor(1, 1, 1, 1)
	cbShowRecipeCooldowns.Text:SetScale(1.2)
	cbShowRecipeCooldowns:SetPoint("TOPLEFT", titleOtherFeatures, "BOTTOMLEFT", 0, 0)
	cbShowRecipeCooldowns:SetChecked(userSettings["showRecipeCooldowns"])
	cbShowRecipeCooldowns:SetScript("OnClick", function(self)
		userSettings["showRecipeCooldowns"] = cbShowRecipeCooldowns:GetChecked()
	end)

	local cbVendorAll = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
	cbVendorAll.Text:SetText("Always set vendor filter to 'All'")
	cbVendorAll.Text:SetTextColor(1, 1, 1, 1)
	cbVendorAll.Text:SetScale(1.2)
	cbVendorAll:SetPoint("TOPLEFT", cbShowRecipeCooldowns, "BOTTOMLEFT", 0, 0)
	cbVendorAll:SetChecked(userSettings["vendorAll"])
	cbVendorAll:SetScript("OnClick", function(self)
		userSettings["vendorAll"] = cbVendorAll:GetChecked()
	end)

	local cbQueueSounds = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
	cbQueueSounds.Text:SetText("Play sound when any queue pops")
	cbQueueSounds.Text:SetTextColor(1, 1, 1, 1)
	cbQueueSounds.Text:SetScale(1.2)
	cbQueueSounds:SetPoint("TOPLEFT", cbVendorAll, "BOTTOMLEFT", 0, 0)
	cbQueueSounds:SetChecked(userSettings["queueSound"])
	cbQueueSounds:SetScript("OnClick", function(self)
		userSettings["queueSound"] = cbQueueSounds:GetChecked()
	end)

	-- Category: Backpack
	local titleBackpack = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
	titleBackpack:SetPoint("LEFT", titleKnowledgeTracker, "LEFT", 0, 0)
	titleBackpack:SetPoint("TOP", cbKnowledgeAlwaysShowDetails, "BOTTOM", 0, -5)
	titleBackpack:SetJustifyH("LEFT")
	titleBackpack:SetScale(1.2)
	titleBackpack:SetText("Backpack")

	local cbBackpackCount = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
	cbBackpackCount.Text:SetText("Split reagent bag count")
	cbBackpackCount.Text:SetTextColor(1, 1, 1, 1)
	cbBackpackCount.Text:SetScale(1.2)
	cbBackpackCount:SetPoint("TOPLEFT", titleBackpack, "BOTTOMLEFT", 0, 0)
	cbBackpackCount:SetChecked(userSettings["backpackCount"])
	cbBackpackCount:SetScript("OnClick", function(self)
		userSettings["backpackCount"] = cbBackpackCount:GetChecked()

		-- Get number of free bag slots
		local freeSlots1 = C_Container.GetContainerNumFreeSlots(0) + C_Container.GetContainerNumFreeSlots(1) + C_Container.GetContainerNumFreeSlots(2) + C_Container.GetContainerNumFreeSlots(3) + C_Container.GetContainerNumFreeSlots(4)
		local freeSlots2 = C_Container.GetContainerNumFreeSlots(5)

		-- If the setting for split reagent bag count is enabled and the player has a reagent bag
		if userSettings["backpackCount"] == true and C_Container.GetContainerNumSlots(5) ~= 0 then
			-- Replace the bag count text
			MainMenuBarBackpackButtonCount:SetText("(" .. freeSlots1 .. "+" .. freeSlots2 .. ")")
		else
			-- Reset the bag count text
			MainMenuBarBackpackButtonCount:SetText("(" .. freeSlots1 + freeSlots2 .. ")")
		end
	end)

		-- Cleanup and Loot order tooltip
		local orderTooltip = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
		orderTooltip:SetPoint("TOPLEFT", cbBackpackCount, "BOTTOMLEFT", 0, 0)
		orderTooltip:SetFrameStrata("TOOLTIP")
		orderTooltip:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})
		orderTooltip:SetBackdropColor(0, 0, 0, 0.9)
		orderTooltip:EnableMouse(false)
		orderTooltip:SetMovable(false)
		orderTooltip:Hide()

		orderTooltipText = orderTooltip:CreateFontString("ARTWORK", nil, "GameFontNormal")
		orderTooltipText:SetPoint("TOPLEFT", orderTooltip, "TOPLEFT", 10, -10)
		orderTooltipText:SetJustifyH("LEFT")
		orderTooltipText:SetText("Default means PSL will not adjust this hidden game setting.\nThe other options let PSL enforce that particular setting.")

		-- Set the tooltip size to fit its contents
		orderTooltip:SetHeight(orderTooltipText:GetStringHeight()+20)
		orderTooltip:SetWidth(orderTooltipText:GetStringWidth()+20)

	local textCleanUpBags = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
	textCleanUpBags:SetPoint("TOPLEFT", cbBackpackCount, "BOTTOMLEFT", 3, 0)
	textCleanUpBags:SetJustifyH("LEFT")
	textCleanUpBags:SetText("|cffFFFFFFClean Up Bags")
	textCleanUpBags:EnableMouse(true)
	textCleanUpBags:SetScript("OnEnter", function(self)
		orderTooltip:Show()
	end)
	textCleanUpBags:SetScript("OnLeave", function(self)
		orderTooltip:Hide()
	end)

	local cbCleanupDefault = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
	local cbCleanupLtoR = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
	local cbCleanupRtoL = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")

		-- Radio button
		local function cbCleanupToggle(state)
			-- Grab user setting if we're not toggling but just loading
			if not state then state = userSettings["backpackCleanup"] end

			-- Set the user setting (either doesn't change, or gets set to what the user clicked)
			userSettings["backpackCleanup"] = state

			-- Make the checkboxes act like radio buttons
			if state == "default" then
				cbCleanupDefault:SetChecked(true)
				cbCleanupLtoR:SetChecked(false)
				cbCleanupRtoL:SetChecked(false)
			elseif state == "ltor" then
				cbCleanupDefault:SetChecked(false)
				cbCleanupLtoR:SetChecked(true)
				cbCleanupRtoL:SetChecked(false)

				-- Enforce the setting
				C_Container.SetSortBagsRightToLeft(false)
			elseif state == "rtol" then
				cbCleanupDefault:SetChecked(false)
				cbCleanupLtoR:SetChecked(false)
				cbCleanupRtoL:SetChecked(true)

				-- Enforce the setting
				C_Container.SetSortBagsRightToLeft(true)
			end
		end
		cbCleanupToggle()

	cbCleanupDefault.Text:SetText("Default")
	cbCleanupDefault.tooltip = "Test."
	cbCleanupDefault.Text:SetTextColor(1, 1, 1, 1)
	cbCleanupDefault.Text:SetScale(1.2)
	cbCleanupDefault:SetPoint("TOPLEFT", textCleanUpBags, "BOTTOMLEFT", -3, 0)
	cbCleanupDefault:SetScript("OnClick", function(self)
		cbCleanupToggle("default")
	end)

	cbCleanupLtoR.Text:SetText("Left-to-Right")
	cbCleanupLtoR.Text:SetTextColor(1, 1, 1, 1)
	cbCleanupLtoR.Text:SetScale(1.2)
	cbCleanupLtoR:SetPoint("LEFT", cbCleanupDefault.Text, "RIGHT", 3, 0)
	cbCleanupLtoR:SetPoint("TOP", cbCleanupDefault, "TOP", 0, 0)
	cbCleanupLtoR:SetScript("OnClick", function(self)
		cbCleanupToggle("ltor")
	end)

	cbCleanupRtoL.Text:SetText("Right-to-Left")
	cbCleanupRtoL.Text:SetTextColor(1, 1, 1, 1)
	cbCleanupRtoL.Text:SetScale(1.2)
	cbCleanupRtoL:SetPoint("LEFT", cbCleanupLtoR.Text, "RIGHT", 3, 0)
	cbCleanupRtoL:SetPoint("TOP", cbCleanupLtoR, "TOP", 0, 0)
	cbCleanupRtoL:SetScript("OnClick", function(self)
		cbCleanupToggle("rtol")
	end)

	local textLootOrder = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
	textLootOrder:SetPoint("TOPLEFT", cbCleanupDefault, "BOTTOMLEFT", 3, 0)
	textLootOrder:SetJustifyH("LEFT")
	textLootOrder:SetText("|cffFFFFFFLoot Order")
	textLootOrder:EnableMouse(true)
	textLootOrder:SetScript("OnEnter", function(self)
		orderTooltip:Show()
	end)
	textLootOrder:SetScript("OnLeave", function(self)
		orderTooltip:Hide()
	end)

	local cbLootDefault = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
	local cbLootLtoR = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
	local cbLootRtoL = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")

	-- Radio button
	local function cbLootToggle(state)
		-- Grab user setting if we're not toggling but just loading
		if not state then state = userSettings["backpackLoot"] end

		-- Set the user setting (either doesn't change, or gets set to what the user clicked)
		userSettings["backpackLoot"] = state

		-- Make the checkboxes act like radio buttons
		if state == "default" then
			cbLootDefault:SetChecked(true)
			cbLootLtoR:SetChecked(false)
			cbLootRtoL:SetChecked(false)
		elseif state == "ltor" then
			cbLootDefault:SetChecked(false)
			cbLootLtoR:SetChecked(true)
			cbLootRtoL:SetChecked(false)

			-- Enforce the setting
			C_Container.SetInsertItemsLeftToRight(true)
		elseif state == "rtol" then
			cbLootDefault:SetChecked(false)
			cbLootLtoR:SetChecked(false)
			cbLootRtoL:SetChecked(true)

			-- Enforce the setting
			C_Container.SetInsertItemsLeftToRight(false)
		end
	end
	cbLootToggle()

	cbLootDefault.Text:SetText("Default")
	cbLootDefault.Text:SetTextColor(1, 1, 1, 1)
	cbLootDefault.Text:SetScale(1.2)
	cbLootDefault:SetPoint("TOPLEFT", textLootOrder, "BOTTOMLEFT", -3, 0)
	cbLootDefault:SetScript("OnClick", function(self)
		cbLootToggle("default")
	end)

	cbLootLtoR.Text:SetText("Left-to-Right")
	cbLootLtoR.Text:SetTextColor(1, 1, 1, 1)
	cbLootLtoR.Text:SetScale(1.2)
	cbLootLtoR:SetPoint("LEFT", cbLootDefault.Text, "RIGHT", 3, 0)
	cbLootLtoR:SetPoint("TOP", cbLootDefault, "TOP", 0, 0)
	cbLootLtoR:SetScript("OnClick", function(self)
		cbLootToggle("ltor")
	end)

	cbLootRtoL.Text:SetText("Right-to-Left")
	cbLootRtoL.Text:SetTextColor(1, 1, 1, 1)
	cbLootRtoL.Text:SetScale(1.2)
	cbLootRtoL:SetPoint("LEFT", cbLootLtoR.Text, "RIGHT", 3, 0)
	cbLootRtoL:SetPoint("TOP", cbLootLtoR, "TOP", 0, 0)
	cbLootRtoL:SetScript("OnClick", function(self)
		cbLootToggle("rtol")
	end)

	-- Extra text
	local SettingsText1 = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
	SettingsText1:SetPoint("TOPLEFT", cbLootDefault, "BOTTOMLEFT", 3, -15)
	SettingsText1:SetJustifyH("LEFT")
	SettingsText1:SetText("Chat commands:\n/psl |cffFFFFFF- Toggle the PSL windows.\n|R/psl resetpos |cffFFFFFF- Reset the PSL window positions.\n|R/psl settings |cffFFFFFF- Open the PSL settings.\n|R/psl clear |cffFFFFFF- Clear all tracked recipes.\n|R/psl track |cff1B9C85recipeID quantity |R|cffFFFFFF- Track a recipe.\n|R/psl untrack |cff1B9C85recipeID quantity |R|cffFFFFFF- Untrack a recipe.\n|R/psl untrack |cff1B9C85recipeID |Rall |cffFFFFFF- Untrack all of a recipe.\n|R/psl |cff1B9C85[crafting achievement] |R |cffFFFFFF- Track the recipes needed for the linked achievement.")

	local SettingsText2 = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
	SettingsText2:SetPoint("TOPLEFT", SettingsText1, "BOTTOMLEFT", 0, -15)
	SettingsText2:SetJustifyH("LEFT")
	SettingsText2:SetText("Mouse interactions:\nDrag|cffFFFFFF: Move the PSL windows.\n|RShift+click Recipe|cffFFFFFF: Link the recipe.\n|RCtrl+click Recipe|cffFFFFFF: Open the recipe (if known on current character).\n|RRight-click Recipe (# column)|cffFFFFFF: Untrack 1 of the selected recipe.\n|RCtrl+right-click Recipe (# column)|cffFFFFFF: Untrack all of the selected recipe.\n|RShift+click Reagent|cffFFFFFF: Link the reagent.\n|RCtrl+click Reagent|cffFFFFFF: Add recipe for the selected subreagent, if it exists.\n(This only works for professions that have been opened with PSL active.)")

	local SettingsText3 = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
	SettingsText3:SetPoint("TOPLEFT", SettingsText2, "BOTTOMLEFT", 0, -15)
	SettingsText3:SetJustifyH("LEFT")
	SettingsText3:SetText("Other features:\n|cffFFFFFF- Adds buttons for Cooking Fire, Chef's Hat, and Thermal Anvil.\n- Copy tracked reagents to the Auctionator import window.")
end

-- When the AddOn is fully loaded, actually run the components
function event:ADDON_LOADED(addOnName, containsBindings)
	if addOnName == appName then
		app.Initialise()
		app.Legacy()
		app.CreateWindow()
		app.CreateGeneralAssets()
		app.TooltipInfo()		
		app.Settings()

		local function refreshCooldowns()
			app.UpdateCooldowns()
			C_Timer.After(60, refreshCooldowns)
		end
		refreshCooldowns()

		-- Slash commands
		SLASH_PSL1 = "/psl";
		function SlashCmdList.PSL(msg, editBox)
			-- Split message into command and rest
			local command, rest = msg:match("^(%S*)%s*(.-)$")

			-- Open settings
			if command == "settings" then
				app.OpenSettings()
			-- Clear list
			elseif command == "clear" then
				app.Clear()
			-- Reset window positions
			elseif command == "resetpos" then
				-- Set the window size and position back to default
				userSettings["windowPosition"] = { ["left"] = GetScreenWidth()/2-100, ["bottom"] = GetScreenHeight()/2-100, ["width"] = 200, ["height"] = 200, }
				userSettings["pcWindowPosition"] = userSettings["windowPosition"]

				-- Show the window, which will also run setting its size and position
				app.Show()
			-- Track recipe
			elseif command == 'track' then
				-- Split entered recipeID and recipeQuantity and turn them into real numbers
				local part1, part2 = rest:match("^(%S*)%s*(.-)$")
				recipeID = tonumber(part1)
				recipeQuantity = tonumber(part2)

				-- Only run if the recipeID is cached and the quantity is an actual number
				if recipeLibrary[recipeID] then
					if type(recipeQuantity) == "number" and recipeQuantity ~= 0 then
						app.TrackRecipe(recipeID, recipeQuantity)
					else
						app.Print("Invalid parameters. Please enter a valid recipe quantity.")
					end
				else
					app.Print("Invalid parameters. Please enter a cached recipe ID.")
				end
			elseif command == 'untrack' then
				-- Split entered recipeID and recipeQuantity and turn them into real numbers
				local part1, part2 = rest:match("^(%S*)%s*(.-)$")
				recipeID = tonumber(part1)
				recipeQuantity = tonumber(part2)

				-- Only run if the recipeID is tracked and the quantity is an actual number (with a maximum of the amount of recipes tracked)
				if recipesTracked[recipeID] then
					if part2 == "all" then
						app.UntrackRecipe(recipeID, 0)

						-- Show windows
						app.Show()
					elseif type(recipeQuantity) == "number" and recipeQuantity ~= 0 and recipeQuantity <= recipesTracked[recipeID].quantity then
						app.UntrackRecipe(recipeID, recipeQuantity)

						-- Show windows
						app.Show()
					else
						app.Print("Invalid parameters. Please enter a valid recipe quantity.")
					end
				else
					app.Print("Invalid parameters. Please enter a tracked recipe ID.")
				end
			-- No command
			elseif command == "" then
				app.Toggle()
			-- Unlisted command
			else
				-- If achievement string
				local _, check = string.find(command, "\124cffffff00\124Hachievement:")
				if check ~= nil then
					-- Get achievementID, number of criteria, and type of the first criterium
					local achievementID = tonumber(string.match(string.sub(command, 25), "%d+"))
					local numCriteria = GetAchievementNumCriteria(achievementID)
					local _, criteriaType = GetAchievementCriteriaInfo(achievementID, 1)

					-- If the asset type is a (crafting) spell
					if criteriaType == 29 then	
						-- For each criteria, track the SpellID
						for i=1,numCriteria,1 do
							local _, criteriaType, completed, quantity, reqQuantity, _, _, assetID = GetAchievementCriteriaInfo(achievementID, i)
							-- If the criteria has not yet been completed
							if completed == false then
								-- Proper quantity, if the info is provided
								local numTrack = 1
								if quantity ~= nil and reqQuantity ~= nil then
									numTrack = reqQuantity - quantity
								end
								-- Add the recipe
								app.TrackRecipe(assetID, numTrack)
							end
						end
					-- Chromatic Calibration: Cranial Cannons
					elseif achievementID == 18906 then
						for i=1,numCriteria,1 do
							-- Set the update handler to active, to prevent multiple list updates from freezing the game
							app.Flag["changingRecipes"] = true
							-- Until the last one in the series
							if i == numCriteria then app.Flag["changingRecipes"] = false end

							local _, criteriaType, completed, _, _, _, _, assetID = GetAchievementCriteriaInfo(achievementID, i)

							-- Manually edit the spellIDs, because multiple ranks are eligible (use rank 1)
							if i == 1 then assetID = 198991
							elseif i == 2 then assetID = 198965
							elseif i == 3 then assetID = 198966
							elseif i == 4 then assetID = 198967
							elseif i == 5 then assetID = 198968
							elseif i == 6 then assetID = 198969
							elseif i == 7 then assetID = 198970
							elseif i == 8 then assetID = 198971 end

							-- If the criteria has not yet been completed, add the recipe
							if completed == false then app.TrackRecipe(assetID, 1) end
						end
					else
						app.Print("This is not a crafting achievement. No recipes were added.")
					end
				else
					app.Print("Invalid command. See /psl settings for more info.")
				end
			end
		end
	end
end

-- When a tradeskill window is opened
function event:TRADE_SKILL_SHOW()
	if C_AddOns.IsAddOnLoaded("Blizzard_Professions") == true then
		app.CreateTradeskillAssets()
	end
	-- Register all recipes for this profession
	for _, recipeID in pairs(C_TradeSkillUI.GetAllRecipeIDs()) do
	-- If there is an output item
	local item = C_TradeSkillUI.GetRecipeOutputItemData(recipeID).itemID
		local _, _, tradeskill = C_TradeSkillUI.GetTradeSkillLineForRecipe(recipeID)
		local ability = C_TradeSkillUI.GetRecipeInfo(recipeID).skillLineAbilityID
		-- Register the output item, the recipe's abilityID, and the recipe's profession
		if item ~= nil then
			recipeLibrary[recipeID] = {itemID = item, abilityID = ability, tradeskillID = tradeskill}
		else
			recipeLibrary[recipeID] = {itemID = 0, abilityID = ability, tradeskillID = tradeskill}
		end
	end

	-- Get Alvin the Anvil's GUID
	for i=1, 9999 do
		local petID, speciesID = C_PetJournal.GetPetInfoByIndex(i)
		if speciesID == 3274 then
			if petID then userSettings["alvinGUID"] = petID end
			break
		elseif speciesID == nil then
			break
		end
	end

	if app.Flag["tradeskillAssets"] == true then
		if userSettings["alvinGUID"] ~= "unknown" then
			alvinButton:SetAttribute("macrotext1", "/run C_PetJournal.SummonPetByGUID('"..userSettings["alvinGUID"].."')")
		else
			alvinButton:SetAttribute("macrotext1", "")
		end
	end
end

-- When the crafting orders window is opened
function event:CRAFTINGORDERS_SHOW_CUSTOMER()
	app.CreateCraftingOrdersAssets()
end

-- When a recipe is selected (sort of)
function event:SPELL_DATA_LOAD_RESULT(spellID, success)
	if UnitAffectingCombat("player") == false then
		-- Only set this number if it actually is a recipe
		if C_TradeSkillUI.GetRecipeSchematic(spellID,false).reagentSlotSchematics[1] ~= nil then
			app.SelectedRecipeID = spellID
		else
			app.SelectedRecipeID = 0
		end
		
		pslRecipeType = C_TradeSkillUI.GetRecipeSchematic(app.SelectedRecipeID,false).recipeType

		app.UpdateAssets()

		local function professionExtra()
			-- Check if/what Milling info should be displayed
			if spellID == 382981 then
				millingDragonflight:Show()
			else
				millingDragonflight:Hide()
			end

			-- Check if the SL rank editbox should be displayed
			if app.slLegendaryRecipeIDs[app.SelectedRecipeID] then
				ebSLrankText:Show()
				ebSLrank:Show()
				ebSLrank:SetText(app.slLegendaryRecipeIDs[app.SelectedRecipeID].rank)
			else
				ebSLrankText:Hide()
				ebSLrank:Hide()
			end
		end
		if app.Flag["tradeskillAssets"] == true then professionExtra() end

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
				for pathID, _ in pairs(pathIDs) do
					local perks = C_ProfSpecs.GetPerksForPath(pathID)
					for no, perk in pairs(perks) do
						perkCount = perkCount + 1
						perkIDs[perkCount] = perk.perkID
					end
				end

				-- Get perk info
				local perksEarned = 0
				for no, perk in pairs(perkIDs) do
					if C_ProfSpecs.GetStateForPerk(perk, configID) == 2 then
						perksEarned = perksEarned + 1
					end
				end

				-- Get knowledge info
				local knowledgeSpent = 0
				local knowledgeMax = 0
				for pathID, _ in pairs(pathIDs) do
					local pathInfo = C_Traits.GetNodeInfo(C_ProfSpecs.GetConfigIDForSkillLine(skillLineID), pathID)
					knowledgeSpent = knowledgeSpent + math.max(0,(pathInfo.activeRank - 1))
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
			local books
			local progress = true

			local function kpTooltip()
				-- Check if DMF is active
				local dmfActive = false
				C_Calendar.OpenCalendar()
				local date = C_DateAndTime.GetCurrentCalendarTime()
				local numEvents = C_Calendar.GetNumDayEvents(0, date.monthDay)
				for i=1, numEvents do
					local event = C_Calendar.GetHolidayInfo(0, date.monthDay, i)
					if event and (event.texture == 235446 or event.texture == 235447 or event.texture == 235448) then -- Non-localised way to detect specific holiday
						dmfActive = true
					end
				end

				-- Darkmoon Faire
				local dmfStatus = app.iconNotReady
				local dmfNumber = 0

				if dmf ~= nil and dmfActive == true then
					if C_QuestLog.IsQuestFlaggedCompleted(dmf) then
						dmfStatus = app.iconReady
						treatiseNumber = 1
					end

					if dmfStatus == app.iconNotReady then progress = false end
				end

				-- Treatise
				local treatiseStatus = app.iconNotReady
				local treatiseNumber = 0
				
				if treatiseQuest ~= nil then
					if C_QuestLog.IsQuestFlaggedCompleted(treatiseQuest) then
						treatiseStatus = app.iconReady
						treatiseNumber = 1
					end

					if treatiseStatus == app.iconNotReady then progress = false end
				end

				-- Crafting order quest
				local orderQuestStatus = app.iconNotReady
				local orderQuestNumber = 0

				if orderQuest ~= nil then 
					if C_QuestLog.IsQuestFlaggedCompleted(orderQuest) then
						orderQuestStatus = app.iconReady
						orderQuestNumber = 1
					end

					if orderQuestStatus == app.iconNotReady then progress = false end
				end

				-- Gather quests
				local gatherQuestStatus = app.iconNotReady
				local gatherQuestNumber = 0

				if gatherQuests ~= nil then
					for no, questID in pairs(gatherQuests) do
						if C_QuestLog.IsQuestFlaggedCompleted(questID) then
							gatherQuestStatus = app.iconReady
							gatherQuestNumber = 1
						end
					end

					if gatherQuestStatus == app.iconNotReady then progress = false end
				end

				-- Craft quests
				local craftQuestStatus = app.iconNotReady
				local craftQuestNumber = 0

				if craftQuests ~= nil then
					for no, questID in pairs(craftQuests) do
						if C_QuestLog.IsQuestFlaggedCompleted(questID) then
							craftQuestNumber = 1
							craftQuestStatus = app.iconReady
						end
					end

					if craftQuestStatus == app.iconNotReady then progress = false end
				end

				-- Drops
				local dropsStatus = app.iconNotReady
				local dropsNoCurrent = 0
				local dropsNoTotal = 0

				if drops ~= nil then
					for _, dropInfo in ipairs(drops) do
						if C_QuestLog.IsQuestFlaggedCompleted(dropInfo.questID) then
							dropsNoCurrent = dropsNoCurrent + 1
						end
						dropsNoTotal = dropsNoTotal + 1
					end

					if dropsNoCurrent == dropsNoTotal then
						dropsStatus = app.iconReady
					end

					if dropsStatus == app.iconNotReady then progress = false end
				end

				-- Dragon Shards
				local shardQuests = {67295, 69946, 69979, 67298}
				local shardStatus = app.iconNotReady
				local shardNo = 0

				for _, questID in pairs(shardQuests) do
					if C_QuestLog.IsQuestFlaggedCompleted(questID) then
						shardNo = shardNo + 1
					end
				end

				if shardNo == 4 then shardStatus = app.iconReady end

				if shardStatus == app.iconNotReady then progress = false end

				-- Hidden profession master
				local hiddenStatus = app.iconNotReady
				local hiddenNumber = 0

				if hiddenMaster ~= nil then 
					if C_QuestLog.IsQuestFlaggedCompleted(hiddenMaster) then
						hiddenNumber = 1
						hiddenStatus = app.iconReady
					end

					if hiddenStatus == app.iconNotReady then progress = false end
				end

				-- Treasures
				local treasureStatus = app.iconNotReady
				local treasureNoCurrent = 0
				local treasureNoTotal = 0

				if treasures ~= nil then
					for questID, itemID in pairs(treasures) do
						if C_QuestLog.IsQuestFlaggedCompleted(questID) then
							treasureNoCurrent = treasureNoCurrent + 1
						end
						treasureNoTotal = treasureNoTotal + 1
					end

					if treasureNoCurrent == treasureNoTotal then treasureStatus = app.iconReady end

					if treasureStatus == app.iconNotReady then progress = false end
				end

				-- Books
				local bookStatus = app.iconNotReady
				local bookNoCurrent = 0
				local bookNoTotal = 0

				if books ~= nil then
					for _, bookInfo in ipairs(books) do
						if C_QuestLog.IsQuestFlaggedCompleted(bookInfo.questID) then
							bookNoCurrent = bookNoCurrent + 1
						end
						bookNoTotal = bookNoTotal + 1
					end

					if bookNoCurrent == bookNoTotal then bookStatus = app.iconReady end
					if bookStatus == app.iconNotReady then progress = false end
				end
				
				-- Renown
				if renown ~= nil then
					renownStatus = app.iconNotReady

					renownInfo = {}
					local title1 = GetFactionInfoByID(renown[1].factionID)
					local title2 = GetFactionInfoByID(renown[2].factionID)
					renownInfo[1] = { locked = C_MajorFactions.GetRenownLevels(renown[1].factionID)[14].locked, questID = renown[1].questID1, title = title1, level = 14 }
					renownInfo[2] = { locked = C_MajorFactions.GetRenownLevels(renown[1].factionID)[24].locked, questID = renown[1].questID2, title = title1, level = 24 }
					renownInfo[3] = { locked = C_MajorFactions.GetRenownLevels(renown[2].factionID)[14].locked, questID = renown[2].questID1, title = title2, level = 14 }
					renownInfo[4] = { locked = C_MajorFactions.GetRenownLevels(renown[2].factionID)[24].locked, questID = renown[2].questID2, title = title2, level = 24 }
					
					-- Exception for Dragonscale Expedition, for some reason
					if renown[1].factionID == 2507 then
						renownInfo[2].locked = C_MajorFactions.GetRenownLevels(renown[1].factionID)[23].locked
						renownInfo[2].level = 23
					end

					renownCount = 0
					for key, info in ipairs(renownInfo) do
						renownInfo[key].status = app.iconNotReady
						if C_QuestLog.IsQuestFlaggedCompleted(renownInfo[key].questID) == true then
							renownInfo[key].status = app.iconReady
							renownCount = renownCount + 1
						elseif renownInfo[key].locked == true then
							renownInfo[key].status = app.iconWaiting
						end
					end

					if renownCount == 4 then renownStatus = app.iconReady end
					if renownStatus == app.iconNotReady then progress = false end
				end

				-- Weekly knowledge (text)
				local oldText
				knowledgePointTooltipText:SetText("Weekly:|cffFFFFFF")

				if dmf ~= nil and dmfActive == true then
					oldText = knowledgePointTooltipText:GetText()
					knowledgePointTooltipText:SetText(oldText.."\n".."|T"..dmfStatus..":0|t "..dmfNumber.."/1 "..CALENDAR_FILTER_DARKMOON)
				end

				if treatiseQuest ~= nil then
					-- Cache treatise item
					if not C_Item.IsItemDataCachedByID(treatiseItem) then local item = Item:CreateFromItemID(treatiseItem) end
					-- Get item link
					local _, itemLink = GetItemInfo(treatiseItem)
					-- If link missing, try again
					if itemLink == nil then
						RunNextFrame(kpTooltip)
						do return end
					end
					oldText = knowledgePointTooltipText:GetText()
					knowledgePointTooltipText:SetText(oldText.."\n".."|T"..treatiseStatus..":0|t "..treatiseNumber.."/1 "..itemLink)
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

					if IsModifierKeyDown() == true or userSettings["knowledgeAlwaysShowDetails"] == true then
						for _, dropInfo in ipairs(drops) do
							oldText = knowledgePointTooltipText:GetText()

							-- Cache item
							if not C_Item.IsItemDataCachedByID(dropInfo.itemID) then local item = Item:CreateFromItemID(dropInfo.itemID) end
							-- Get item info
							local _, itemLink = GetItemInfo(dropInfo.itemID)
							-- If links missing, try again
							if itemLink == nil then
								RunNextFrame(kpTooltip)
								do return end
							end
		
							if C_QuestLog.IsQuestFlaggedCompleted(dropInfo.questID) then
								knowledgePointTooltipText:SetText(oldText.."\n   ".."|T"..app.iconReady..":0|t "..itemLink.." - "..dropInfo.source)
							else
								knowledgePointTooltipText:SetText(oldText.."\n   ".."|T"..app.iconNotReady..":0|t "..itemLink.." - "..dropInfo.source)
							end
						end
					end
				end

				-- One-time knowledge (text)
				if userSettings["knowledgeHideDone"] == true and shardNo == 4 and hiddenNumber == 1 and (treasureNoCurrent == treasureNoTotal or treasures == nil) and (bookNoCurrent == bookNoTotal) then
					-- Do not show this
				else
					oldText = knowledgePointTooltipText:GetText()
					knowledgePointTooltipText:SetText(oldText.."\n\n|cffFFD000One-time:|cffFFFFFF")
				end
				
				-- Dragon Shard of Knowledge
				if userSettings["knowledgeHideDone"] == true and shardNo == 4 then
					-- Don't show this
				else
					-- Cache dragon shard item
					if not C_Item.IsItemDataCachedByID(191784) then local item = Item:CreateFromItemID(191784) end
					-- Get item link
					local _, itemLink = GetItemInfo(191784)
					-- If link missing, try again
					if itemLink == nil then
						RunNextFrame(kpTooltip)
						do return end
					end

					oldText = knowledgePointTooltipText:GetText()
					knowledgePointTooltipText:SetText(oldText.."\n|T"..shardStatus..":0|t "..shardNo.."/4 "..itemLink)

					if IsModifierKeyDown() == true or userSettings["knowledgeAlwaysShowDetails"] == true then
						for no, questID in pairs(shardQuests) do
							oldText = knowledgePointTooltipText:GetText()
							local questTitle = C_QuestLog.GetTitleForQuestID(questID)

							-- If link missing, try again
							if questTitle == nil then
								RunNextFrame(kpTooltip)
								do return end
							end

							if C_QuestLog.IsQuestFlaggedCompleted(questID) then
								knowledgePointTooltipText:SetText(oldText.."\n   ".."|T"..app.iconReady..":0|t ".."|cffffff00|Hquest:"..questID.."62|h["..questTitle.."]|h|r")
							else
								knowledgePointTooltipText:SetText(oldText.."\n   ".."|T"..app.iconNotReady..":0|t ".."|cffffff00|Hquest:"..questID.."62|h["..questTitle.."]|h|r")
							end
						end
					end
				end

				-- Hidden profession master
				if userSettings["knowledgeHideDone"] == true and hiddenNumber == 1 then
					-- Don't show this
				else
					oldText = knowledgePointTooltipText:GetText()
					knowledgePointTooltipText:SetText(oldText.."\n".."|T"..hiddenStatus..":0|t "..hiddenNumber.."/1 Hidden profession master")
				end

				-- Treasures
				if treasures ~= nil then
					if userSettings["knowledgeHideDone"] == true and treasureNoCurrent == treasureNoTotal then
						-- Don't show this
					else
						oldText = knowledgePointTooltipText:GetText()
						knowledgePointTooltipText:SetText(oldText.."\n".."|T"..treasureStatus..":0|t "..treasureNoCurrent.."/"..treasureNoTotal.." Treasures")

						if IsModifierKeyDown() == true or userSettings["knowledgeAlwaysShowDetails"] == true then
							for questID, itemID in pairs(treasures) do
								oldText = knowledgePointTooltipText:GetText()

								-- Cache item
								if not C_Item.IsItemDataCachedByID(itemID) then local item = Item:CreateFromItemID(itemID) end
								-- Get item link
								local _, itemLink = GetItemInfo(itemID)
								-- If link missing, try again
								if itemLink == nil then
									RunNextFrame(kpTooltip)
									do return end
								end
			
								if C_QuestLog.IsQuestFlaggedCompleted(questID) then
									knowledgePointTooltipText:SetText(oldText.."\n   ".."|T"..app.iconReady..":0|t "..itemLink)
								else
									knowledgePointTooltipText:SetText(oldText.."\n   ".."|T"..app.iconNotReady..":0|t "..itemLink)
								end
							end
						end
					end
				end

				-- Books
				if books ~= nil then
					if userSettings["knowledgeHideDone"] == true and bookNoCurrent == bookNoTotal then
						-- Don't show this
					else
						oldText = knowledgePointTooltipText:GetText()
						knowledgePointTooltipText:SetText(oldText.."\n".."|T"..bookStatus..":0|t "..bookNoCurrent.."/"..bookNoTotal.." Books")

						if IsModifierKeyDown() == true or userSettings["knowledgeAlwaysShowDetails"] == true then
							for _, bookInfo in ipairs(books) do
								oldText = knowledgePointTooltipText:GetText()

								-- Cache item
								if not C_Item.IsItemDataCachedByID(bookInfo.itemID) then local item = Item:CreateFromItemID(bookInfo.itemID) end
								-- Get item link
								local _, itemLink = GetItemInfo(bookInfo.itemID)
								-- If link missing, try again
								if itemLink == nil then
									RunNextFrame(kpTooltip)
									do return end
								end
			
								if C_QuestLog.IsQuestFlaggedCompleted(bookInfo.questID) then
									knowledgePointTooltipText:SetText(oldText.."\n   ".."|T"..app.iconReady..":0|t "..itemLink)
								else
									knowledgePointTooltipText:SetText(oldText.."\n   ".."|T"..app.iconNotReady..":0|t "..itemLink)
								end
							end
						end
					end
				end

				-- Renown
				if renown ~= nil then
					if userSettings["knowledgeHideDone"] == true and renownCount == 4 then
						-- Don't show this
					else
						oldText = knowledgePointTooltipText:GetText()
						knowledgePointTooltipText:SetText(oldText.."\n".."|T"..renownStatus..":0|t "..renownCount.."/4 Renown")
						if IsModifierKeyDown() == true or userSettings["knowledgeAlwaysShowDetails"] == true then
							for key, info in ipairs(renownInfo) do

								oldText = knowledgePointTooltipText:GetText()
								knowledgePointTooltipText:SetText(oldText.."\n   ".."|T"..renownInfo[key].status..":0|t "..renownInfo[key].title.." ("..RENOWN_LEVEL_LABEL..renownInfo[key].level..")")
							end
						end
					end
				end
				
				oldText = knowledgePointTooltipText:GetText()
				if IsModifierKeyDown() == false and userSettings["knowledgeAlwaysShowDetails"] == false then knowledgePointTooltipText:SetText(oldText.."\n\n|cffFFD000Hold Alt, Ctrl, or Shift to show details.") end

				-- Set the tooltip size to fit its contents
				knowledgePointTooltip:SetHeight(knowledgePointTooltipText:GetStringHeight()+20)
				knowledgePointTooltip:SetWidth(knowledgePointTooltipText:GetStringWidth()+20)

				-- Make progress bar green if everything is done
				local minValue, maxValue = knowledgePointTracker.Bar:GetMinMaxValues() 
				local currentValue = knowledgePointTracker.Bar:GetValue()

				if progress == true or maxValue == currentValue then
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

			-- Hide the tooltip when not mouse-over
			knowledgePointTracker:SetScript("OnLeave", function()
				knowledgePointTooltip:Hide()
			end)

			-- Refresh the tooltip on key down/up (to check for IsModifierKeyDown)
			knowledgePointTracker:SetScript("OnKeyDown", function()
				kpTooltip()
			end)
			knowledgePointTracker:SetScript("OnKeyUp", function()
				kpTooltip()
			end)

			-- Blacksmithing
			if professionID == 1 then
				treatiseItem = 198454
				treatiseQuest = 74109
				orderQuest = 70589
				gatherQuests = {66517, 66897, 66941, 72398, 75148, 75569, 77935, 77936}
				craftQuests = {70211, 70233, 70234, 70235}
				hiddenMaster = 70250
				drops = {}
				drops[1] = {questID = 66381, itemID = 192131, source = "Treasures"}
				drops[2] = {questID = 66382, itemID = 192132, source = "Treasures"}
				drops[3] = {questID = 70512, itemID = 198965, source = "Mobs: Earth"}
				drops[4] = {questID = 70513, itemID = 198966, source = "Mobs: Fire"}
				drops[5] = {questID = 74931, itemID = 204230, source = "Tidesmith Zarviss"}
				treasures = {}
				-- 10.0
				treasures[70230] = 198791	-- Glimmer of Blacksmithing Wisdom
				treasures[70246] = 201007	-- Ancient Monument
				treasures[70296] = 201008	-- Molten Ingot
				treasures[70310] = 201010	-- Qalashi Weapon Diagram
				treasures[70311] = 201006	-- Draconic Flux
				treasures[70312] = 201005	-- Curious Ingots
				treasures[70313] = 201004	-- Ancient Spear Shards
				treasures[70314] = 201011	-- Spelltouched Tongs
				treasures[70353] = 201009	-- Falconer Gauntlet Drawings
				-- 10.1
				treasures[76078] = 205986	-- Well-Worn Kiln
				treasures[76079] = 205987	-- Brimstone Rescue Ring
				treasures[76080] = 205988	-- Zaqali Elder Spear
				-- 10.2
				treasures[78417] = 210464	-- Amirdrassil Defender's Shield
				treasures[78418] = 210465	-- Deathstalker Chassis
				treasures[78419] = 210466	-- Flamesworn Render
				books = {}
				books[1] = {questID = 71894, itemID = 200972}
				books[2] = {questID = 71905, itemID = 201268}
				books[3] = {questID = 71916, itemID = 201279}
				books[4] = {questID = 75755, itemID = 205352}
				books[5] = {questID = 75846, itemID = 205428}
				books[6] = {questID = 75849, itemID = 205439}
				renown = {}
				renown[1] = {factionID = 2503, questID1 = 72312, questID2 = 72315}
				renown[2] = {factionID = 2510, questID1 = 72329, questID2 = 70909}
				dmf = 29508
			end

			-- Leatherworking
			if professionID == 2 then
				treatiseItem = 194700
				treatiseQuest = 74113
				orderQuest = 70594
				gatherQuests = {66363, 66364, 66951, 72407, 75354, 75368, 77945, 77946}
				craftQuests = {70567, 70568, 70569, 70571}
				hiddenMaster = 70256
				drops = {}
				drops[1] = {questID = 66384, itemID = 193910, source = "Treasures"}
				drops[2] = {questID = 66385, itemID = 193913, source = "Treasures"}
				drops[3] = {questID = 70522, itemID = 198975, source = "Mobs: Proto-Drakes"}
				drops[4] = {questID = 70523, itemID = 198976, source = "Mobs: Slyvern & Vorquin"}
				drops[5] = {questID = 74928, itemID = 204232, source = "Snarfang"}
				treasures = {}
				-- 10.0
				treasures[70266] = 198658	-- Decay-Infused Tanning Oil
				treasures[70269] = 201018	-- Well-Danced Drum
				treasures[70280] = 198667	-- Spare Djaradin Tools
				treasures[70286] = 198683	-- Treated Hides
				treasures[70294] = 198690	-- Bag of Decayed Scales
				treasures[70300] = 198696	-- Wind-Blessed Hide
				treasures[70308] = 198711	-- Poacher's Pack
				-- 10.1
				treasures[75495] = 204986	-- Flame-Infused Scale Oil
				treasures[75496] = 204987	-- Lava-Forged Leatherworker's "Knife"
				treasures[75502] = 204988	-- Sulfur-Soaked Skins
				-- 10.2
				treasures[78298] = 210208	-- Tuft of Dreamsaber Fur
				treasures[78299] = 210211	-- Molted Fearie Dragon Scales
				treasures[78305] = 210215	-- Dreamtalon Claw
				books = {}
				books[1] = {questID = 71900, itemID = 200979}
				books[2] = {questID = 71911, itemID = 201275}
				books[3] = {questID = 71922, itemID = 201286}
				books[4] = {questID = 75751, itemID = 198613}
				books[5] = {questID = 75840, itemID = 205426}
				books[6] = {questID = 75855, itemID = 205437}
				renown = {}
				renown[1] = {factionID = 2503, questID1 = 72296, questID2 = 72297}
				renown[2] = {factionID = 2511, questID1 = 72321, questID2 = 72326}
				dmf = 29517
			end

			-- Alchemy
			if professionID == 3 then
				treatiseItem = 194697
				treatiseQuest = 74108
				orderQuest = nil
				gatherQuests = {66937, 66938, 66940, 72427, 75363, 75371, 77932, 77918}
				craftQuests = {70530, 70531, 70532, 70533}
				hiddenMaster = 70247
				drops = {}
				drops[1] = {questID = 66373, itemID = 193891, source = "Treasures"}
				drops[2] = {questID = 66374, itemID = 193897, source = "Treasures"}
				drops[3] = {questID = 70504, itemID = 198963, source = "Mobs: Decay"}
				drops[4] = {questID = 70511, itemID = 198964, source = "Mobs: Elemental"}
				drops[5] = {questID = 74935, itemID = 204226, source = "Agni Blazehoof"}
				treasures = {}
				-- 10.0
				treasures[70208] = 198599	-- Experimental Decay Sample
				treasures[70274] = 198663	-- Frostforged Potion
				treasures[70278] = 203471	-- Tasty Candy (formerly Furry Gloop 201003)
				treasures[70289] = 198685	-- Well Insulated Mug
				treasures[70301] = 198697	-- Contraband Concoction
				treasures[70305] = 198710	-- Canteen of Suspicious Water
				treasures[70309] = 198712	-- Small Basket of Firewater Powder
				-- 10.1
				treasures[75646] = 205211	-- Nutriend Diluted Protofluid
				treasures[75649] = 205212	-- Marrow-Ripened Slime
				treasures[75651] = 205213	-- Suspicious Mold
				-- 10.2
				treasures[78264] = 210184	-- Half-Filled Dreamless Sleep Potion
				treasures[78269] = 210185	-- Splash Potion of Narcolepsy
				treasures[78275] = 210190	-- Blazeroot
				books = {}
				books[1] = {questID = 71893, itemID = 200974}
				books[2] = {questID = 71904, itemID = 201270}
				books[3] = {questID = 71915, itemID = 201281}
				books[4] = {questID = 75756, itemID = 205353}
				books[5] = {questID = 75847, itemID = 205429}
				books[6] = {questID = 75848, itemID = 205440}
				renown = {}
				renown[1] = {factionID = 2503, questID1 = 72311, questID2 = 72314}
				renown[2] = {factionID = 2510, questID1 = 70892, questID2 = 70889}
				dmf = 29506
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
				drops[1] = {questID = 71857, itemID = 200677, source = "Herbs"}
				drops[2] = {questID = 71858, itemID = 200677, source = "Herbs"}
				drops[3] = {questID = 71859, itemID = 200677, source = "Herbs"}
				drops[4] = {questID = 71860, itemID = 200677, source = "Herbs"}
				drops[5] = {questID = 71861, itemID = 200677, source = "Herbs"}
				drops[6] = {questID = 71864, itemID = 200678, source = "Herbs"}
				drops[7] = {questID = 74933, itemID = 204228, source = "Kangalo"}
				treasures = nil
				books = {}
				books[1] = {questID = 71897, itemID = 200980}
				books[2] = {questID = 71908, itemID = 201276}
				books[3] = {questID = 71919, itemID = 201287}
				books[4] = {questID = 75753, itemID = 205358}
				books[5] = {questID = 75843, itemID = 205434}
				books[6] = {questID = 75852, itemID = 205445}
				renown = {}
				renown[1] = {factionID = 2503, questID1 = 72313, questID2 = 72316}
				renown[2] = {factionID = 2511, questID1 = 72319, questID2 = 72324}
				dmf = 29514
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
				drops[1] = {questID = 72160, itemID = 201300, source = "Deposits"}
				drops[2] = {questID = 72161, itemID = 201300, source = "Deposits"}
				drops[3] = {questID = 72162, itemID = 201300, source = "Deposits"}
				drops[4] = {questID = 72163, itemID = 201300, source = "Deposits"}
				drops[5] = {questID = 72164, itemID = 201300, source = "Deposits"}
				drops[6] = {questID = 72165, itemID = 201301, source = "Deposits"}
				drops[7] = {questID = 74926, itemID = 204233, source = "Tectonus"}
				treasures = nil
				books = {}
				books[1] = {questID = 71901, itemID = 200981}
				books[2] = {questID = 71912, itemID = 201277}
				books[3] = {questID = 71923, itemID = 201288}
				books[4] = {questID = 75758, itemID = 205356}
				books[5] = {questID = 75839, itemID = 205432}
				books[6] = {questID = 75856, itemID = 205443}
				renown = {}
				renown[1] = {factionID = 2507, questID1 = 72302, questID2 = 72308}
				renown[2] = {factionID = 2510, questID1 = 72332, questID2 = 72335}
				dmf = 29518
			end

			-- Tailoring
			if professionID == 7 then
				treatiseItem = 194698
				treatiseQuest = 74115
				orderQuest = 70595
				gatherQuests = {66899, 66952, 66953, 72410, 75407, 75600, 77947, 77949}
				craftQuests = {70572, 70582, 70586, 70587}
				hiddenMaster = 70260
				drops = {}
				drops[1] = {questID = 66386, itemID = 193898, source = "Treasures"}
				drops[2] = {questID = 66387, itemID = 193899, source = "Treasures"}
				drops[3] = {questID = 70524, itemID = 198977, source = "Mobs: Centaur"}
				drops[4] = {questID = 70525, itemID = 198978, source = "Mobs: Gnoll"}
				drops[5] = {questID = 74929, itemID = 204225, source = "Gareed"}
				treasures = {}
				-- 10.0
				treasures[70267] = 198662	-- Intriguing Bolt of Blue Cloth
				treasures[70284] = 198680	-- Decaying Brackenhide Blanket
				treasures[70288] = 198684	-- Miniature Bronze Dragonflight Banner
				treasures[70295] = 198692	-- Noteworthy Scrap of Carpet
				treasures[70302] = 198699	-- Mysterious Banner
				treasures[70303] = 201020	-- Silky Surprise
				treasures[70304] = 198702	-- Itinerant Singed Fabric
				treasures[70372] = 201019	-- Ancient Dragonweave Bolt
				-- 10.1
				treasures[76102] = 206019	-- Abandoned Reserve Chute
				treasures[76110] = 206025	-- Used Medical Wrap Kit
				treasures[76116] = 206030	-- Exquisitely Embroidered Banner
				-- 10.2
				treasures[78414] = 210461	-- Exceedingly Soft Wildercloth
				treasures[78415] = 210462	-- Plush Pillow
				treasures[78416] = 210463	-- Snuggle Buddy
				books = {}
				books[1] = {questID = 71903, itemID = 200975}
				books[2] = {questID = 71914, itemID = 201271}
				books[3] = {questID = 71925, itemID = 201282}
				books[4] = {questID = 75757, itemID = 205355}
				books[5] = {questID = 75837, itemID = 205431}
				books[6] = {questID = 75858, itemID = 205442}
				renown = {}
				renown[1] = {factionID = 2507, questID1 = 72303, questID2 = 72309}
				renown[2] = {factionID = 2510, questID1 = 72333, questID2 = 72336}
				dmf = 29520
			end

			-- Engineering
			if professionID == 8 then
				treatiseItem = 198510
				treatiseQuest = 74111
				orderQuest = 70591
				gatherQuests = {66890, 66891, 66942, 72396, 75575, 75608, 77891, 77938}
				craftQuests = {70539, 70540, 70545, 70557}
				hiddenMaster = 70252
				drops = {}
				drops[1] = {questID = 66379, itemID = 193902, source = "Treasures"}
				drops[2] = {questID = 66380, itemID = 193903, source = "Treasures"}
				drops[3] = {questID = 70516, itemID = 198969, source = "Mobs: Keeper"}
				drops[4] = {questID = 70517, itemID = 198970, source = "Mobs: Dragonkin"}
				drops[5] = {questID = 74934, itemID = 204227, source = "Fimbol"}
				treasures = {}
				-- 10.0
				treasures[70270] = 201014	-- Boomthyr Rocket
				treasures[70275] = 198789	-- Intact Coil Capacitor
				-- 10.1
				treasures[75180] = 204469	-- Misplaced Aberrus Outflow Blueprints
				treasures[75183] = 204470	-- Haphazardly Discarded Bomb
				treasures[75184] = 204471	-- Defective Survival Pack
				treasures[75186] = 204475	-- Busted Wyrmhole Generator
				treasures[75188] = 204480	-- Inconspicuous Data Miner
				treasures[75430] = 204850	-- Handful of Khaz'gorite Bolts
				treasures[75431] = 204853	-- Discarded Dracothyst Drill
				treasures[75433] = 204855	-- Overclocked Determination Core
				-- 10.2
				treasures[78278] = 210193	-- Experimental Dreamcatcher
				treasures[78279] = 210194	-- Insomniotron
				treasures[78281] = 210197	-- Unhatched Battery
				books = {}
				books[1] = {questID = 71896, itemID = 200977}
				books[2] = {questID = 71907, itemID = 201273}
				books[3] = {questID = 71918, itemID = 201284}
				books[4] = {questID = 75759, itemID = 205349}
				books[5] = {questID = 75844, itemID = 205425}
				books[6] = {questID = 75851, itemID = 205436}
				renown = {}
				renown[1] = {factionID = 2507, questID1 = 72300, questID2 = 72305}
				renown[2] = {factionID = 2510, questID1 = 72330, questID2 = 70902}
				dmf = 29511
			end

			-- Enchanting
			if professionID == 9 then
				treatiseItem = 194702
				treatiseQuest = 74110
				orderQuest = nil
				gatherQuests = {66884, 66900, 66935, 72423, 75150, 75865, 77910, 77937}
				craftQuests = {72155, 72172, 72173, 72175}
				hiddenMaster = 70251
				drops = {}
				drops[1] = {questID = 66377, itemID = 193900, source = "Treasures"}
				drops[2] = {questID = 66378, itemID = 193901, source = "Treasures"}
				drops[3] = {questID = 70514, itemID = 198967, source = "Mobs: Arcane"}
				drops[4] = {questID = 70515, itemID = 198968, source = "Mobs: Primalist"}
				drops[5] = {questID = 74927, itemID = 204224, source = "Manathema"}
				treasures = {}
				-- 10.0
				treasures[70272] = 201012	-- Enchanted Debris
				treasures[70283] = 198675	-- Lava-Infused Seed
				treasures[70290] = 201013	-- Faintly Enchanted Remains
				treasures[70291] = 198689	-- Stormbound Horn
				treasures[70298] = 198694	-- Enriched Earthen Shard
				treasures[70320] = 198798	-- Flashfrozen Scroll
				treasures[70336] = 198799	-- Forgotten Arcane Tome
				treasures[70342] = 198800	-- Fractured Titanic Sphere
				-- 10.1
				treasures[75508] = 204990	-- Lava-Drenched Shadow Crystal
				treasures[75509] = 204999	-- Shimmering Aqueous Orb
				treasures[75510] = 205001	-- Resonating Arcane Crystal
				-- 10.2
				treasures[78308] = 210228	-- Pure Dream Water
				treasures[78309] = 210231	-- Everburning Core
				treasures[78310] = 210234	-- Essence of Dreams
				books = {}
				books[1] = {questID = 71895, itemID = 200976}
				books[2] = {questID = 71906, itemID = 201272}
				books[3] = {questID = 71917, itemID = 201283}
				books[4] = {questID = 75752, itemID = 205351}
				books[5] = {questID = 75845, itemID = 205427}
				books[6] = {questID = 75850, itemID = 205438}
				renown = {}
				renown[1] = {factionID = 2507, questID1 = 72299, questID2 = 72304}
				renown[2] = {factionID = 2511, questID1 = 72318, questID2 = 72323}
				dmf = 29510
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
				drops[1] = {questID = 70381, itemID = 198837, source = "Skinning"}
				drops[2] = {questID = 70383, itemID = 198837, source = "Skinning"}
				drops[3] = {questID = 70384, itemID = 198837, source = "Skinning"}
				drops[4] = {questID = 70385, itemID = 198837, source = "Skinning"}
				drops[5] = {questID = 70386, itemID = 198837, source = "Skinning"}
				drops[6] = {questID = 70389, itemID = 198841, source = "Skinning"}
				drops[7] = {questID = 74930, itemID = 204231, source = "Faunos"}
				treasures = nil
				books = {}
				books[1] = {questID = 71902, itemID = 200982}
				books[2] = {questID = 71913, itemID = 201278}
				books[3] = {questID = 71924, itemID = 201289}
				books[4] = {questID = 75760, itemID = 205357}
				books[5] = {questID = 75838, itemID = 205433}
				books[6] = {questID = 75857, itemID = 205444}
				renown = {}
				renown[1] = {factionID = 2503, questID1 = 72310, questID2 = 72317}
				renown[2] = {factionID = 2511, questID1 = 72322, questID2 = 72327}
				dmf = 29519
			end

			-- Jewelcrafting
			if professionID == 12 then
				treatiseItem = 194703
				treatiseQuest = 74112
				orderQuest = 70593
				gatherQuests = {66516, 66949, 66950, 72428, 75362, 75602, 77892, 77912}
				craftQuests = {70562, 70563, 70564, 70565}
				hiddenMaster = 70255
				drops = {}
				drops[1] = {questID = 66388, itemID = 193909, source = "Treasures"}
				drops[2] = {questID = 66389, itemID = 193907, source = "Treasures"}
				drops[3] = {questID = 70520, itemID = 198973, source = "Mobs: Elemental"}
				drops[4] = {questID = 70521, itemID = 198974, source = "Mobs: Dragonkin"}
				drops[5] = {questID = 74936, itemID = 204222, source = "Amephyst"}
				treasures = {}
				-- 10.0
				treasures[70273] = 201017	-- Igneous Gem
				treasures[70292] = 198687	-- Closely Guarded Shiny
				treasures[70271] = 201016	-- Harmonic Crystal Harmonizer
				treasures[70277] = 198664	-- Crystalline Overgrowth
				treasures[70282] = 198670	-- Lofty Malygite
				treasures[70263] = 198660	-- Fragmented Key
				treasures[70261] = 198656	-- Painter's Pretty Jewel
				treasures[70285] = 198682	-- Alexstraszite Cluster
				-- 10.1
				treasures[75652] = 205214	-- Snubbed Snail Shells
				treasures[75653] = 205216	-- Gently Jostled Jewels
				treasures[75654] = 205219	-- Broken Barter Boulder
				-- 10.2
				treasures[78282] = 210200	-- Petrified Hope
				treasures[78283] = 210201	-- Handful of Pebbles
				treasures[78285] = 210202	-- Coalesced Dreamstone
				books = {}
				books[1] = {questID = 71899, itemID = 200978}
				books[2] = {questID = 71910, itemID = 201274}
				books[3] = {questID = 71921, itemID = 201285}
				books[4] = {questID = 75754, itemID = 205348}
				books[5] = {questID = 75841, itemID = 205424}
				books[6] = {questID = 75854, itemID = 205435}
				renown = {}
				renown[1] = {factionID = 2507, questID1 = 72301, questID2 = 72306}
				renown[2] = {factionID = 2511, questID1 = 72320, questID2 = 72325}
				dmf = 29516
			end

			-- Inscription
			if professionID == 13 then
				treatiseItem = 194699
				treatiseQuest = 74105
				orderQuest = 70592
				gatherQuests = {66943, 66944, 66945, 72438, 75149, 75573, 77889, 77914}
				craftQuests = {70558, 70559, 70560, 70561}
				hiddenMaster = 70254
				drops = {}
				drops[1] = {questID = 66375, itemID = 193904, source = "Treasures"}
				drops[2] = {questID = 66376, itemID = 193905, source = "Treasures"}
				drops[3] = {questID = 70518, itemID = 198971, source = "Mobs: Djaradin"}
				drops[4] = {questID = 70519, itemID = 198972, source = "Mobs: Dragonkin"}
				drops[5] = {questID = 74932, itemID = 204229, source = "Arcantrix"}
				treasures = {}
				-- 10.0
				treasures[70248] = 198659	-- Forgetful Apprentice's Tome 1
				treasures[70264] = 198659	-- Forgetful Apprentice's Tome 2
				treasures[70281] = 198669	-- How to Train Your Whelpling
				treasures[70287] = 201015	-- Counterfeit Darkmoon Deck
				treasures[70293] = 198686	-- Frosted Parchment
				treasures[70297] = 198693	-- Dusty Darkmoon Card
				treasures[70306] = 198704	-- Pulsing Earth Rune
				treasures[70307] = 198703	-- Sign Language Reference Sheet
				-- 10.1
				treasures[76117] = 206031	-- Intricate Zaqali Runes
				treasures[76120] = 206034	-- Hissing Rune Draft
				treasures[76121] = 206035	-- Ancient Research
				-- 10.2
				treasures[78411] = 210458	-- Winnie's Notes on Flora and Fauna
				treasures[78412] = 210459	-- Grove Keeper's Pillar
				treasures[78413] = 210460	-- Primalist Shadowbinding Rune
				books = {}
				books[1] = {questID = 71898, itemID = 200973}
				books[2] = {questID = 71909, itemID = 201269}
				books[3] = {questID = 71920, itemID = 201280}
				books[4] = {questID = 75761, itemID = 205354}
				books[5] = {questID = 75842, itemID = 205430}
				books[6] = {questID = 75853, itemID = 205441}
				renown = {}
				renown[1] = {factionID = 2507, questID1 = 72294, questID2 = 72295}
				renown[2] = {factionID = 2510, questID1 = 72331, questID2 = 72334}
				dmf = 29515
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

			-- Cooking Fire and Chef's Hat buttons
			if professionID == 5 then
				cookingFireButton:Show()
				chefsHatButton:Show()
			else
				cookingFireButton:Hide()
				chefsHatButton:Hide()
			end

			-- Thermal Anvil button
			if professionID == 1 or professionID == 6 or professionID == 8 then
				thermalAnvilButton:Show()
				alvinButton:Show()
				local _, _, raceID = UnitRace("player")
				if raceID == 30 then
					lightforgeButton:Show()
				end
			else
				thermalAnvilButton:Hide()
				alvinButton:Hide()
				lightforgeButton:Hide()
			end
		end
		if app.Flag["tradeskillAssets"] == true then professionFeatures() end
	end
end

-- When closing the crafting orders window
function event:CRAFTINGORDERS_HIDE_CUSTOMER()
	app.Flag["recraft"] = false
end
	
-- When a spell is succesfully cast by the player
function event:UNIT_SPELLCAST_SUCCEEDED(unitTarget, castGUID, spellID)
	if UnitAffectingCombat("player") == false and unitTarget == "player" then
		-- Profession button stuff
		if spellID == 818 or spellID == 67556 or spellID == 126462 or spellID == 279205 or spellID == 259930 then
			C_Timer.After(0.1, function() app.UpdateAssets() end)
		end
	
		-- Run only when the spell cast is a known recipe
		if recipeLibrary[spellID] then
			-- With a delay due to how quickly that info is updated after UNIT_SPELLCAST_SUCCEEDED
			C_Timer.After(0.1, function()
				-- Get character info
				local character = UnitName("player")
				local realm = GetNormalizedRealmName()

				-- Get spell cooldown info
				local recipeName = C_TradeSkillUI.GetRecipeSchematic(spellID, false).name
				local cooldown, isDayCooldown, charges, maxCharges = C_TradeSkillUI.GetRecipeCooldown(spellID)	-- For daily cooldowns, this returns the time until midnight. Only after a relog does it return the time until daily reset, when the recipe actually resets.
				local recipeStart = GetServerTime()

				-- Set timer to 7 days for the Alchemy sac transmutes
				if spellID == 213256 or spellID == 251808 then
					cooldown = 7 * 24 * 60 * 60
				-- Keep the actual spell coolcown for Dragonflight Alchemy experimentations, and only show the last one done
				elseif spellID == 370743 or spellID == 370745 or spellID == 370746 or spellID == 370747 then
					local spells = {370743,  370745, 370746, 370747}
					for k, v in pairs(spells) do
						if v ~= spellID then
							for k2, v2 in pairs(recipeCooldowns) do
								if v2.recipeID == v then
									recipeCooldowns[k2] = nil
								end
							end
						end
					end
				-- Otherwise, if the cooldown exists, set it to line up with daily reset
				elseif cooldown and cooldown >= 60 then
					local days = math.floor( cooldown / 86400 )	-- Count how many days we add to the time until daily reset
					cooldown = GetQuestResetTime() + ( days * 86400 )
				end

				-- If the spell cooldown exists
				if cooldown then
					-- Replace the existing entry if it exists
					local cdExists = false
					for k, v in ipairs(recipeCooldowns) do
						if v.recipeID == spellID and v.user == character .. "-" .. realm then
							recipeCooldowns[k] = {name = recipeName, recipeID = spellID, cooldown = cooldown, start = recipeStart, user = character .. "-" .. realm, charges = charges, maxCharges = maxCharges}
							cdExists = true
						end
					end
					-- Otherwise, create a new entry
					if cdExists == false then
						recipeCooldowns[#recipeCooldowns+1] = {name = recipeName, recipeID = spellID, cooldown = cooldown, start = recipeStart, user = character .. "-" .. realm, charges = charges, maxCharges = maxCharges}
					end
					-- And then update our window
					app.UpdateRecipes()
				end
			end)
		end

		-- Run only when crafting a tracked recipe, and if the remove craft option is enabled
		if recipesTracked[spellID] and userSettings["removeCraft"] == true then
			-- Remove 1 tracked recipe when it has been crafted (if the option is enabled)
			app.UntrackRecipe(spellID, 1)
			
			-- Close windows if no recipes are left and the option is enabled
			local next = next
			if next(recipesTracked) == nil then
				app.Window:Hide()
			end
		end
	end
end

-- When bag changes occur (out of combat)
function event:BAG_UPDATE_DELAYED()
	if UnitAffectingCombat("player") == false then
		-- If any recipes are tracked
		local next = next
		if next(recipesTracked) ~= nil then
			app.UpdateNumbers()
		end

		-- If the setting for split reagent bag count is enabled
		if userSettings["backpackCount"] == true then
			-- Get number of free bag slots
			local freeSlots1 = C_Container.GetContainerNumFreeSlots(0) + C_Container.GetContainerNumFreeSlots(1) + C_Container.GetContainerNumFreeSlots(2) + C_Container.GetContainerNumFreeSlots(3) + C_Container.GetContainerNumFreeSlots(4)
			local freeSlots2 = C_Container.GetContainerNumFreeSlots(5)

			-- If a reagent bag is equipped
			if C_Container.GetContainerNumSlots(5) ~= 0 then
				-- Replace the bag count text
				MainMenuBarBackpackButtonCount:SetText("(" .. freeSlots1 .. "+" .. freeSlots2 .. ")")
			end
		end
	end
end

-- When a vendor window is opened
function event:MERCHANT_SHOW()
	-- Notification popup
	if userSettings["onetimeMessages"].vendorItems == false then
		app.Popup(true, "|cffFFFFFFYou can now track vendor items with "..app.NameLong.."|cffFFFFFF!\n|RAlt+Click|cffFFFFFF any vendor item and "..app.NameShort.."|cffFFFFFF tracks the total costs.")

		userSettings["onetimeMessages"].vendorItems = true
	end

	-- Set the Vendor filter to 'All' if the option is enabled
	if userSettings["vendorAll"] == true then
		RunNextFrame(function()
			SetMerchantFilter(1)
			MerchantFrame_Update()
		end)
	end

	-- When the user Alt+clicks a vendor item
	local function TrackMerchantItem(index)
		if IsAltKeyDown() == true then
			-- Use the page number to get the proper vendor index
			local page = string.match(MerchantPageText:GetText(), "%s(%d+)%s")
			index = index + (page - 1) * 10
			
			-- Get merchant info
			local merchant = MerchantFrameTitleText:GetText()

			-- Get item info
			local itemID = GetMerchantItemID(index)
			local itemLink = GetMerchantItemLink(index)
			local _, _, itemPrice = GetMerchantItemInfo(index)

			-- Add this as a fake recipe
			local key = merchant..":"..itemID
			fakeRecipeLibrary[key] = {
				["itemID"] = itemID,
				["tradeskillID"] = 0,	-- Vendor item
				["costCopper"] = 0,
				["costItems"] = {},
				["costCurrency"] = {},
			}

			if itemPrice then
				fakeRecipeLibrary[key].costCopper = itemPrice
				reagentCache["gold"] = { 
					icon = app.iconProfession[0],
					link = BONUS_ROLL_REWARD_MONEY,
				}
			end
			-- Get the different currencies needed to purchase the item
			for i=1, GetMerchantItemCostInfo(index), 1 do
				local itemTexture, itemValue, itemLink, currencyName = GetMerchantItemCostItem(index, i)
				if currencyName and itemLink then
					local currencyID = C_CurrencyInfo.GetCurrencyIDFromLink(itemLink)

					fakeRecipeLibrary[key].costCurrency[currencyID] = itemValue
					reagentCache["currency:"..currencyID] = { 
						icon = itemTexture,
						link = currencyName,
					}
				elseif itemLink then
					local itemID = GetItemInfoFromHyperlink(itemLink)
					fakeRecipeLibrary[key].costItems[itemID] = itemValue
					if not reagentTiers[itemID] then
						reagentTiers[itemID] = {
							one = itemID,
							two = 0,
							three = 0,
						}
					end
				end
				
			end

			-- Track the vendor item as a fake recipe
			if not recipesTracked[key] then recipesTracked[key] = { quantity = 0, link = itemLink} end
			recipesTracked[key].quantity = recipesTracked[key].quantity + 1

			-- Show the window
			app.Show()
		end
	end

	-- Hook the script onto the merchant buttons (once)
	if app.Flag["merchantAssets"] == false then
		MerchantItem1ItemButton:HookScript("OnClick", function() TrackMerchantItem(1) end)
		MerchantItem2ItemButton:HookScript("OnClick", function() TrackMerchantItem(2) end)
		MerchantItem3ItemButton:HookScript("OnClick", function() TrackMerchantItem(3) end)
		MerchantItem4ItemButton:HookScript("OnClick", function() TrackMerchantItem(4) end)
		MerchantItem5ItemButton:HookScript("OnClick", function() TrackMerchantItem(5) end)
		MerchantItem6ItemButton:HookScript("OnClick", function() TrackMerchantItem(6) end)
		MerchantItem7ItemButton:HookScript("OnClick", function() TrackMerchantItem(7) end)
		MerchantItem8ItemButton:HookScript("OnClick", function() TrackMerchantItem(8) end)
		MerchantItem9ItemButton:HookScript("OnClick", function() TrackMerchantItem(9) end)
		MerchantItem10ItemButton:HookScript("OnClick", function() TrackMerchantItem(10) end)

		-- Set the flag to true so it doesn't trigger again
		app.Flag["merchantAssets"] = true
	end
end

-- If placing a crafting order through PSL
function event:CRAFTINGORDERS_ORDER_PLACEMENT_RESPONSE(result)
	if app.Flag["quickOrder"] >= 1 then
		-- Count a(nother) quick order attempt
		app.QuickOrderAttempts = app.QuickOrderAttempts + 1
		
		-- If this gives an error
		if result ~= 0 then
			-- Count a(nother) error for the quick order attempt
			app.QuickOrderErrors = app.QuickOrderErrors + 1

			-- Hide the error frame
			UIErrorsFrame:Hide()

			-- Clear the error frame before showing it again
			C_Timer.After(1.0, function() UIErrorsFrame:Clear() UIErrorsFrame:Show() end)

			-- If all 4 attempts fail, tell the user this
			if app.QuickOrderErrors >= 4 then
				app.Print("Quick order failed. Sorry. :(")
			end
		end
		-- Separate error message for mandatory reagents
		if result == 29 then
			app.Print("Can't create a quick order for items with mandatory reagents. Sorry. :(")
		end

		-- Save this info as the last order done, unless it was afaileds order
		if result ~= 29 or app.QuickOrderErrors >= 4 then personalOrders["last"] = app.SelectedRecipeID end

		-- Set the last used recipe name for the repeat order button title
		local recipeName = "No last order found"
		-- Check for the name if there has been a last order
		if personalOrders["last"] ~= nil then
			recipeName = C_TradeSkillUI.GetRecipeSchematic(personalOrders["last"], false).name

			local reagents = "false"
			local recipient = personalOrders[personalOrders["last"]]
			if userSettings["useLocalReagents"] == true then reagents = "true" end
			repeatOrderTooltipText:SetText("Repeat the last Quick Order done on this character.\nRecipient: "..recipient.."\nUse local reagents: "..reagents)
			repeatOrderTooltip:SetHeight(repeatOrderTooltipText:GetStringHeight()+20)
			repeatOrderTooltip:SetWidth(repeatOrderTooltipText:GetStringWidth()+20)
		end
		repeatOrderButton:SetText(recipeName)
		repeatOrderButton:SetWidth(repeatOrderButton:GetTextWidth()+20)

		-- Reset all the numbers if we're done
		if (app.Flag["quickOrder"] == 1 and app.QuickOrderAttempts >= 1) or (app.Flag["quickOrder"] == 2 and app.QuickOrderAttempts >= 4) then
			app.Flag["quickOrder"] = 0
			app.QuickOrderAttempts = 0
			app.QuickOrderErrors = 0
		end
	end
end

-- Save the order recipeID if the order has been started, because SPELL_LOAD_RESULT does not fire for it anymore
function event:CRAFTINGORDERS_CLAIM_ORDER_RESPONSE()
	app.OrderRecipeID = app.SelectedRecipeID
end

-- Revert the above if the order is cancelled or fulfilled, since then SPELL_LOAD_RESULT fires again for it
function event:CRAFTINGORDERS_RELEASE_ORDER_RESPONSE()
	app.OrderRecipeID = 0
end

function event:CRAFTINGORDERS_FULFILL_ORDER_RESPONSE()
	app.OrderRecipeID = 0
end

-- Replace the in-game tracking of shift+clicking a recipe with PSL's
function event:TRACKED_RECIPE_UPDATE(recipeID, tracked)
	if tracked == true then
		app.TrackRecipe(recipeID,1)
		C_TradeSkillUI.SetRecipeTracked(recipeID, false, false)
	end
end

-- When the Auction House is opened
function event:AUCTION_HOUSE_SHOW()
	-- If Auctionator is loaded
	local loaded, finished = IsAddOnLoaded("Auctionator")
	if finished == true then
		-- Create a temporary variable
		if not auctionatorReagents then local auctionatorReagents end

		-- Grab all item names for tracked reagents
		local function getReagentNames()
			-- Reset the reagents list
			auctionatorReagents = "PSL"

			for reagentID, reagentAmount in pairs(app.ReagentQuantities) do
				-- Cache item
				if not C_Item.IsItemDataCachedByID(reagentID) then local item = Item:CreateFromItemID(reagentID) end
				
				-- Get item info
				local itemName = GetItemInfo(reagentID)
		
				-- Try again if error
				if itemName == nil then
					RunNextFrame(getReagentNames)
					do return end
				end

				-- Put the item names in the temporary variable
				auctionatorReagents = auctionatorReagents .. '^"' .. itemName .. '";;0;0;0;0;0;0;0;0;;#;;' .. reagentAmount
			end
		end

		-- Wait 3 seconds, because Auctionator needs to create its frames
		C_Timer.After(3, function()
			-- Create PSL Import button for Auctionator, if the frame exists (and the AddOn is loaded)
			if AuctionatorImportListFrame and not auctionatorImportButton then
				auctionatorImportButton = CreateFrame("Button", nil, AuctionatorImportListFrame.Import, "UIPanelButtonTemplate")
				auctionatorImportButton:SetText("Copy from PSL")
				auctionatorImportButton:SetWidth(110)
				auctionatorImportButton:SetPoint("BOTTOMRIGHT", AuctionatorImportListFrame.Import, "BOTTOMLEFT", 0, 0)
				auctionatorImportButton:SetScript("OnClick", function()
					app.UpdateRecipes()
					-- Add another delay because I have no idea how to optimise my AddOn
					C_Timer.After(0.5, function()
						getReagentNames()
						-- Remove old list
						if Auctionator.Shopping.ListManager:GetIndexForName("PSL") ~= nil then
							Auctionator.Shopping.ListManager:Delete("PSL")
						end
						-- Import new list
						AuctionatorImportListFrame.EditBoxContainer:SetText(auctionatorReagents)
					end)
				end)
			end
		end)
	end
end

-- When the user encounters a loading screen
function event:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
	-- Only on initialLoad
	if isInitialLogin == true then
		-- Check all tracked recipe cooldowns
		for k, recipeInfo in pairs(recipeCooldowns) do
			-- Check the remaining cooldown
			local cooldownRemaining = recipeInfo.start + recipeInfo.cooldown - GetServerTime()

			-- If the recipe is off cooldown
			if cooldownRemaining <= 0 then
				-- Check charges if they exist and return one
				if recipeInfo.maxCharges > 0 and recipeInfo.maxCharges > recipeInfo.charges then
					recipeCooldowns[k].charges = recipeCooldowns[k].charges + 1

					-- And move the reset time if we're not at full charges yet
					if recipeCooldowns[k].charges ~= recipeCooldowns[k].maxCharges then
						recipeCooldowns[k].start = GetServerTime()
						recipeCooldowns[k].cooldown = GetQuestResetTime()
					end
				end

				-- If the option to show recipe cooldowns is enabled and all charges are full (or 0 = 0 for recipes without charges)
				if userSettings["showRecipeCooldowns"] == true and recipeCooldowns[k].charges == recipeCooldowns[k].maxCharges then
					-- Show the reminder
					app.Print(recipeInfo.name .. " is ready to craft again on " .. recipeInfo.user .. ".")
				end
			end
		end
	end
end

-- When a LFG queue or pet battle queue pops up
function event:LFG_PROPOSAL_SHOW()
	-- If the setting for queue sounds is enabled
	if userSettings["queueSound"] == true then
		-- Play the DBM-style sound
		PlaySoundFile(567478, "Master")
	end
end

function event:PET_BATTLE_QUEUE_PROPOSE_MATCH()
	-- If the setting for queue sounds is enabled
	if userSettings["queueSound"] == true then
		-- Play the DBM-style sound
		PlaySoundFile(567478, "Master")
	end
end

-- When a recipe is selected (very for realsies)
EventRegistry:RegisterCallback("ProfessionsRecipeListMixin.Event.OnRecipeSelected", function(_, recipeInfo)
	if recipeInfo["isRecraft"] == true then app.Flag["recraft"] = true
	elseif recipeInfo["isRecraft"] == false then app.Flag["recraft"] = false
	end
end)

-- When opening the recrafting order window
EventRegistry:RegisterCallback("ProfessionsCustomerOrders.RecraftCategorySelected", function()
	app.Flag["recraft"] = true
end)

-- When selecting a non-recrafting order
EventRegistry:RegisterCallback("ProfessionsCustomerOrders.RecipeSelected", function()
	app.Flag["recraft"] = false
end)

-- When a PvP queue pops up
hooksecurefunc("PVPReadyDialog_Display", function()
	-- If the setting for queue sounds is enabled
	if userSettings["queueSound"] == true then
		-- Play the DBM-style sound
		PlaySoundFile(567478, "Master")
	end
end)