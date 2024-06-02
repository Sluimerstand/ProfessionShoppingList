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
event:RegisterEvent("BAG_UPDATE_DELAYED")
event:RegisterEvent("MERCHANT_SHOW")
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

-- App colour
function app.Colour(string)
	return "|cffC69B6D"..string.."|R"
end

-- Print with AddOn prefix
function app.Print(...)
	print(app.NameShort..":", ...)
end

-- Pop-up window
function app.Popup(show, text)
	-- Create popup frame
	local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	frame:SetPoint("CENTER")
	frame:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	frame:SetBackdropColor(0, 0, 0, 1)
	frame:EnableMouse(true)
	if show == true then
		frame:Show()
	else
		frame:Hide()
	end

	-- Close button
	local close = CreateFrame("Button", "", frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 2, 2)
	close:SetScript("OnClick", function()
		frame:Hide()
	end)

	-- Text
	local string = frame:CreateFontString("ARTWORK", nil, "GameFontNormal")
	string:SetPoint("CENTER", frame, "CENTER", 0, 0)
	string:SetPoint("TOP", frame, "TOP", 0, -25)
	string:SetJustifyH("CENTER")
	string:SetText(text)
	frame:SetHeight(string:GetStringHeight()+50)
	frame:SetWidth(string:GetStringWidth()+50)

	return frame
end

-- Border
function app.Border(parent, a, b, c, d)
	local border = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	border:SetPoint("TOPLEFT", parent, a or 0, b or 0)
	border:SetPoint("BOTTOMRIGHT", parent, c or 0, d or 0)
	border:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		edgeSize = 14,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	border:SetBackdropColor(0, 0, 0, 0)
	border:SetBackdropBorderColor(0.776, 0.608, 0.427)
end

-- Button
function app.Button(parent, text)
	local frame = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	frame:SetText(text)
	frame:SetWidth(frame:GetTextWidth()+20)

	app.Border(frame, 0, 0, 0, -1)
	return frame
end

-- Window tooltip body
function app.WindowTooltip(text)
	-- Tooltip
	local frame = CreateFrame("Frame", nil, app.Window, "BackdropTemplate")
	frame:SetFrameStrata("TOOLTIP")
	frame:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	frame:SetBackdropColor(0, 0, 0, 0.9)
	frame:EnableMouse(false)
	frame:SetMovable(false)
	frame:Hide()

	local string = frame:CreateFontString("ARTWORK", nil, "GameFontNormal")
	string:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10)
	string:SetJustifyH("LEFT")
	string:SetText(text)

	-- Set the tooltip size to fit its contents
	frame:SetHeight(string:GetStringHeight()+20)
	frame:SetWidth(string:GetStringWidth()+20)

	return frame
end

-- Window tooltip show/hide
function app.WindowTooltipShow(frame)
	-- Set the tooltip to either the left or right, depending on where the window is placed
	if GetScreenWidth()/2-ProfessionShoppingList_Settings["windowPosition"].width/2-app.Window:GetLeft() >= 0 then
		frame:ClearAllPoints()
		frame:SetPoint("LEFT", app.Window, "RIGHT", 0, 0)
	else
		frame:ClearAllPoints()
		frame:SetPoint("RIGHT", app.Window, "LEFT", 0, 0)
	end
	frame:Show()
end

------------------
-- INITIAL LOAD --
------------------

-- Create SavedVariables, default user settings, and session variables
function app.InitialiseCore()
	-- Declare SavedVariables
	if not ProfessionShoppingList_Settings then ProfessionShoppingList_Settings = {} end

	if not ProfessionShoppingList_Data then ProfessionShoppingList_Data = {} end
	if not ProfessionShoppingList_Data.Recipes then ProfessionShoppingList_Data.Recipes = {} end
	if not ProfessionShoppingList_Data.Cooldowns then ProfessionShoppingList_Data.Cooldowns = {} end

	if not ProfessionShoppingList_Library then ProfessionShoppingList_Library = {} end

	if not ProfessionShoppingList_Cache then ProfessionShoppingList_Cache = {} end
	if not ProfessionShoppingList_Cache.ReagentTiers then ProfessionShoppingList_Cache.ReagentTiers = {} end
	if not ProfessionShoppingList_Cache.Reagents then ProfessionShoppingList_Cache.Reagents = {} end
	if not ProfessionShoppingList_Cache.FakeRecipes then ProfessionShoppingList_Cache.FakeRecipes = {} end
	
	if not ProfessionShoppingList_CharacterData then ProfessionShoppingList_CharacterData = {} end
	if not ProfessionShoppingList_CharacterData.Recipes then ProfessionShoppingList_CharacterData.Recipes = {} end
	if not ProfessionShoppingList_CharacterData.Orders then ProfessionShoppingList_CharacterData.Orders = {} end

	-- Enable default user settings
	if ProfessionShoppingList_Settings["hide"] == nil then ProfessionShoppingList_Settings["hide"] = false end
	if ProfessionShoppingList_Settings["minimapIcon"] == nil then ProfessionShoppingList_Settings["minimapIcon"] = true end
	if ProfessionShoppingList_Settings["pcRecipes"] == nil then ProfessionShoppingList_Settings["pcRecipes"] = false end
	if ProfessionShoppingList_Settings["pcWindows"] == nil then ProfessionShoppingList_Settings["pcWindows"] = false end
	-- Tracking Window
	if ProfessionShoppingList_Settings["showRecipeCooldowns"] == nil then ProfessionShoppingList_Settings["showRecipeCooldowns"] = true end
	if ProfessionShoppingList_Settings["showRemaining"] == nil then ProfessionShoppingList_Settings["showRemaining"] = false end
	if ProfessionShoppingList_Settings["reagentQuality"] == nil then ProfessionShoppingList_Settings["reagentQuality"] = 1 end
	if ProfessionShoppingList_Settings["removeCraft"] == nil then ProfessionShoppingList_Settings["removeCraft"] = true end
	if ProfessionShoppingList_Settings["closeWhenDone"] == nil then ProfessionShoppingList_Settings["closeWhenDone"] = false end
	if ProfessionShoppingList_Settings["showTooltip"] == nil then ProfessionShoppingList_Settings["showTooltip"] = true end
	-- Hidden	
	if ProfessionShoppingList_Settings["windowPosition"] == nil then ProfessionShoppingList_Settings["windowPosition"] = { ["left"] = 1295, ["bottom"] = 836, ["width"] = 200, ["height"] = 200, } end
	if ProfessionShoppingList_Settings["pcWindowPosition"] == nil then ProfessionShoppingList_Settings["pcWindowPosition"] = ProfessionShoppingList_Settings["windowPosition"] end
	if ProfessionShoppingList_Settings["alvinGUID"] == nil then ProfessionShoppingList_Settings["alvinGUID"] = "unknown" end
	if ProfessionShoppingList_Settings["onetimeMessages"] == nil then ProfessionShoppingList_Settings["onetimeMessages"] = {} end
	if ProfessionShoppingList_Settings["onetimeMessages"].vendorItems == nil then ProfessionShoppingList_Settings["onetimeMessages"].vendorItems = false end

	-- Load personal recipes, if the setting is enabled
	if ProfessionShoppingList_Settings["pcRecipes"] == true then
		ProfessionShoppingList_Data.Recipes = ProfessionShoppingList_CharacterData.Recipes
	end

	-- Initialise some session variables
	app.Hidden = CreateFrame("Frame")
	app.Flag = {}
	app.Flag["changingRecipes"] = false
	app.Flag["merchantAssets"] = false
	app.Flag["recraft"] = false
	app.Flag["tradeskillAssets"] = false
	app.ReagentQuantities = {}
	app.SelectedRecipeID = 0
	app.UpdatedCooldownWidth = 0
	app.UpdatedReagentWidth = 0
end

-- Convert and/or delete older SavedVariables
function app.Legacy()
	-- v10.2.0-007
		-- Convert recipeLinks to recipesTracked
		if recipesTracked then
			for key, value in pairs(recipesTracked) do
				if type(value) == "number" then
					recipesTracked[key] = { quantity = value, recraft = false }
				end
			end
		end

		if pcRecipesTracked then
			for key, value in pairs(pcRecipesTracked) do
				if type(value) == "number" then
					pcRecipesTracked[key] = { quantity = value, recraft = false }
				end
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
		if userSettings then
			userSettings["recipeRows"] = nil
			userSettings["reagentRows"] = nil
			userSettings["recipeWidth"] = nil
			userSettings["recipeNoWidth"] = nil
			userSettings["reagentWidth"] = nil
			userSettings["reagentNoWidth"] = nil
		end
	
	-- v10.2.5-002
	if recipeCooldowns then
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

	-- v10.2.7-003
	if userSettings then
		if userSettings["backpackCleanup"] == "default" then userSettings["backpackCleanup"] = 0 end
		if userSettings["backpackCleanup"] == "ltor" then userSettings["backpackCleanup"] = 1 end
		if userSettings["backpackCleanup"] == "rtol" then userSettings["backpackCleanup"] = 2 end

		if userSettings["backpackLoot"] == "default" then userSettings["backpackLoot"] = 0 end
		if userSettings["backpackLoot"] == "ltor" then userSettings["backpackLoot"] = 1 end
		if userSettings["backpackLoot"] == "rtol" then userSettings["backpackLoot"] = 2 end

		userSettings["headerTooltip"] = nil
	end

	-- v10.2.7-006
	if userSettings then ProfessionShoppingList_Settings = userSettings end

	if recipesTracked then ProfessionShoppingList_Data.Recipes = recipesTracked end
	if recipeCooldowns then ProfessionShoppingList_Data.Cooldowns = recipeCooldowns end

	if recipeLibrary then ProfessionShoppingList_Library = recipeLibrary end

	if reagentTiers then ProfessionShoppingList_Cache.ReagentTiers = reagentTiers end
	if reagentCache then ProfessionShoppingList_Cache.Reagents = reagentCache end
	if fakeRecipeLibrary then ProfessionShoppingList_Cache.FakeRecipes = fakeRecipeLibrary end

	if pcRecipesTracked then ProfessionShoppingList_CharacterData.Recipes = pcRecipesTracked end
	if personalOrders then ProfessionShoppingList_CharacterData.Orders = personalOrders end
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
	ProfessionShoppingList_Settings["windowPosition"] = { ["left"] = left, ["bottom"] = bottom, ["width"] = width, ["height"] = height, }
	ProfessionShoppingList_Settings["pcWindowPosition"] = ProfessionShoppingList_Settings["windowPosition"]
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
	app.Window:SetBackdropBorderColor(0.776, 0.608, 0.427)
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
	close:SetPoint("TOPRIGHT", app.Window, "TOPRIGHT", 2, 2)
	close:SetScript("OnClick", function()
		app.Window:Hide()
	end)
	close:SetScript("OnEnter", function()
		app.WindowTooltipShow(app.CloseButtonTooltip)
	end)
	close:SetScript("OnLeave", function()
		app.CloseButtonTooltip:Hide()
	end)

	-- Clear button
	app.ClearButton = CreateFrame("Button", "pslOptionClearButton", app.Window, "UIPanelCloseButton")
	app.ClearButton:SetPoint("TOPRIGHT", close, "TOPLEFT", -2, 0)
	app.ClearButton:SetNormalTexture("Interface\\AddOns\\ProfessionShoppingList\\assets\\button-clear.blp")
	app.ClearButton:GetNormalTexture():SetTexCoord(39/256, 75/256, 1/128, 38/128)
	app.ClearButton:SetDisabledTexture("Interface\\AddOns\\ProfessionShoppingList\\assets\\button-clear.blp")
	app.ClearButton:GetDisabledTexture():SetTexCoord(39/256, 75/256, 41/128, 78/128)
	app.ClearButton:SetPushedTexture("Interface\\AddOns\\ProfessionShoppingList\\assets\\button-clear.blp")
	app.ClearButton:GetPushedTexture():SetTexCoord(39/256, 75/256, 81/128, 118/128)
	app.ClearButton:SetScript("OnClick", function()
		StaticPopupDialogs["CLEAR_RECIPES"] = {
			text = app.NameLong.."\nDo you want to clear all recipes?",
			button1 = YES,
			button2 = NO,
			OnAccept = function()
			app.Clear()
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			showAlert = true,
		}
		StaticPopup_Show("CLEAR_RECIPES", "Interface\\AddOns\\ProfessionShoppingList\assets\\psl_icon.blp")
	end)
	app.ClearButton:SetScript("OnEnter", function()
		app.WindowTooltipShow(app.ClearButtonTooltip)
	end)
	app.ClearButton:SetScript("OnLeave", function()
		app.ClearButtonTooltip:Hide()
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
	local reagentQuality = qualityTier or ProfessionShoppingList_Settings["reagentQuality"]

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

			-- Add the different reagent tiers into ProfessionShoppingList_Cache.ReagentTiers so they can be queried later
			-- No need to check if they already exist, we can just overwrite it
			ProfessionShoppingList_Cache.ReagentTiers[reagentID1] = {one = reagentID1, two = reagentID2, three = reagentID3}
			ProfessionShoppingList_Cache.ReagentTiers[reagentID2] = {one = reagentID1, two = reagentID2, three = reagentID3}
			ProfessionShoppingList_Cache.ReagentTiers[reagentID3] = {one = reagentID1, two = reagentID2, three = reagentID3}

			-- Remove ProfessionShoppingList_Cache.ReagentTiers[0]
			if ProfessionShoppingList_Cache.ReagentTiers[0] then ProfessionShoppingList_Cache.ReagentTiers[0] = nil end

			-- Check which quality reagent to use
			if reagentQuality == 3 and reagentID3 ~= 0 then
				reagentID = reagentID3
			elseif reagentQuality == 2 and reagentID2 ~= 0 then
				reagentID = reagentID2
			else
				reagentID = reagentID1
			end

			-- Add the reagentID to the reagent cache
			if not ProfessionShoppingList_Cache.Reagents[reagentID] then
				local item = Item:CreateFromItemID(reagentID)
			
				-- And when the item is cached
				item:ContinueOnItemLoad(function()
					-- Get item info
					_, itemLink, _, _, _, _, _, _, _, fileID = C_Item.GetItemInfo(reagentID)

					-- Write the info to the cache
					ProfessionShoppingList_Cache.Reagents[reagentID] = {link = itemLink, icon = fileID}
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

		if not ProfessionShoppingList_Cache.Reagents[reagentID] then
			-- Cache item
			if not C_Item.IsItemDataCachedByID(reagentID) then local item = Item:CreateFromItemID(reagentID) end

			-- Get item info
			_, itemLink, _, _, _, _, _, _, _, fileID = C_Item.GetItemInfo(reagentID)

			-- Try again if error
			if itemLink == nil then
				RunNextFrame(app.UpdateNumbers)
				do return end
			end

			-- Write the info to the cache
			ProfessionShoppingList_Cache.Reagents[reagentID] = {link = itemLink, icon = fileID}
		else
			-- Read the info from the cache
			itemLink = ProfessionShoppingList_Cache.Reagents[reagentID].link
			icon = ProfessionShoppingList_Cache.Reagents[reagentID].icon
		end

		local itemAmount = ""
		local itemIcon = ProfessionShoppingList_Cache.Reagents[reagentID].icon

		if type(reagentID) == "number" then
			-- Get needed/owned number of reagents
			local reagentAmountHave1 = 0
			local reagentAmountHave2 = 0
			local reagentAmountHave3 = 0

			reagentAmountHave1 = C_Item.GetItemCount(ProfessionShoppingList_Cache.ReagentTiers[reagentID].one, true, false, true)
			if ProfessionShoppingList_Cache.ReagentTiers[reagentID].two ~= 0 then
				reagentAmountHave2 = C_Item.GetItemCount(ProfessionShoppingList_Cache.ReagentTiers[reagentID].two, true, false, true)
			end
			if ProfessionShoppingList_Cache.ReagentTiers[reagentID].three ~= 0 then
				reagentAmountHave3 = C_Item.GetItemCount(ProfessionShoppingList_Cache.ReagentTiers[reagentID].three, true, false, true)
			end

			-- Calculate owned amount based on the quality of the item
			local reagentAmountHave = 0
			if reagentID == ProfessionShoppingList_Cache.ReagentTiers[reagentID].one then
				reagentAmountHave = reagentAmountHave1 + reagentAmountHave2 + reagentAmountHave3
			elseif reagentID == ProfessionShoppingList_Cache.ReagentTiers[reagentID].two then
				reagentAmountHave = reagentAmountHave2 + reagentAmountHave3
			elseif reagentID == ProfessionShoppingList_Cache.ReagentTiers[reagentID].three then
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
			if ProfessionShoppingList_Settings["showRemaining"] == false then
				itemAmount = itemAmount..reagentAmountHave.."/"..amount
			else
				itemAmount = itemAmount..math.max(0,amount-reagentAmountHave)
			end
		elseif reagentID == "gold" then
			-- Set the colour of both strings and the icon
			local colour = ""
			if math.max(0,amount-GetMoney()) == 0 then
				itemIcon = app.iconReady
				colour = "|cff9d9d9d"
				itemLink = colour..itemLink
			end

			-- Set the displayed amount based on settings
			if ProfessionShoppingList_Settings["showRemaining"] == false then
				itemAmount = colour..GetCoinTextureString(amount)
			else
				itemAmount = colour..GetCoinTextureString(math.max(0,amount-GetMoney()))
			end
		elseif string.find(reagentID, "currency") then
			local number = string.gsub(reagentID, "currency:", "")
			local quantity = C_CurrencyInfo.GetCurrencyInfo(tonumber(number)).quantity

			-- Set the colour of both strings and the icon
			local colour = ""
			if math.max(0,amount-quantity) == 0 then
				itemIcon = app.iconReady
				colour = "|cff9d9d9d"
				itemLink = string.gsub(itemLink, "|cff9d9d9d|", "|cff9d9d9d|") -- Poor
				itemLink = string.gsub(itemLink, "|cffffffff|", "|cff9d9d9d|") -- Common
				itemLink = string.gsub(itemLink, "|cff1eff00|", "|cff9d9d9d|") -- Uncommon
				itemLink = string.gsub(itemLink, "|cff0070dd|", "|cff9d9d9d|") -- Rare
				itemLink = string.gsub(itemLink, "|cffa335ee|", "|cff9d9d9d|") -- Epic
				itemLink = string.gsub(itemLink, "|cffff8000|", "|cff9d9d9d|") -- Legendary
				itemLink = string.gsub(itemLink, "|cffe6cc80|", "|cff9d9d9d|") -- Artifact
			end

			-- Set the displayed amount based on settings
			if ProfessionShoppingList_Settings["showRemaining"] == false then
				itemAmount = colour..quantity.."/"..amount
			else
				itemAmount = colour..math.max(0,amount-quantity)
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
					local name = C_CurrencyInfo.GetCurrencyLink(tonumber(number))
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

	-- Enable or disable the clear button when appropriate
	local next = next
	if next(ProfessionShoppingList_Data.Recipes) == nil then
		app.ClearButton:Disable()
	else
		app.ClearButton:Enable()
	end
end

-- Update cooldown numbers
function app.UpdateCooldowns()
	app.UpdatedCooldownWidth = 0
	if cooldownRow then
		if #cooldownRow >= 1 then
			for i, row in ipairs(cooldownRow) do
				local rowID = row:GetID()
				local cooldownRemaining = ProfessionShoppingList_Data.Cooldowns[rowID].start + ProfessionShoppingList_Data.Cooldowns[rowID].cooldown - GetServerTime()
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
	ProfessionShoppingList_CharacterData.Recipes = ProfessionShoppingList_Data.Recipes

	-- Recalculate reagents tracked
	if app.Flag["changingRecipes"] == false then
		app.ReagentQuantities = {}

		for recipeID, recipeInfo in pairs(ProfessionShoppingList_Data.Recipes) do
			if type(recipeID) == "number" then
				app.GetReagents(app.ReagentQuantities, recipeID, recipeInfo.quantity, recipeInfo.recraft)
			elseif ProfessionShoppingList_Cache.FakeRecipes[recipeID] then
				-- Add gold costs
				if ProfessionShoppingList_Cache.FakeRecipes[recipeID].costCopper > 0 then
					if app.ReagentQuantities["gold"] == nil then app.ReagentQuantities["gold"] = 0 end
					app.ReagentQuantities["gold"] = app.ReagentQuantities["gold"] + ( ProfessionShoppingList_Cache.FakeRecipes[recipeID].costCopper * ProfessionShoppingList_Data.Recipes[recipeID].quantity )
				end
				-- Add item costs
				for reagentID, reagentAmount in pairs(ProfessionShoppingList_Cache.FakeRecipes[recipeID].costItems) do
					if app.ReagentQuantities[reagentID] == nil then app.ReagentQuantities[reagentID] = 0 end
					app.ReagentQuantities[reagentID] = app.ReagentQuantities[reagentID] + ( reagentAmount * ProfessionShoppingList_Data.Recipes[recipeID].quantity )
				end
				-- Add currency costs
				for currencyID, currencyAmount in pairs(ProfessionShoppingList_Cache.FakeRecipes[recipeID].costCurrency) do
					local key = "currency:"..currencyID
					if app.ReagentQuantities[key] == nil then app.ReagentQuantities[key] = 0 end
					app.ReagentQuantities[key] = app.ReagentQuantities[key] + ( currencyAmount * ProfessionShoppingList_Data.Recipes[recipeID].quantity )
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
			app.WindowTooltipShow(app.RecipesHeaderTooltip)
		end)
		app.Window.Recipes:SetScript("OnLeave", function()
			app.RecipesHeaderTooltip:Hide()
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
	
	for k, v in pairs(ProfessionShoppingList_Data.Recipes) do
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
			if GetScreenWidth()/2-ProfessionShoppingList_Settings["windowPosition"].width/2-app.Window:GetLeft() >= 0 then
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
					if selectedRecipeID ~= 0 and C_TradeSkillUI.IsRecipeProfessionLearned(selectedRecipeID) == true then
						C_TradeSkillUI.SetRecipeItemNameFilter("")	-- Clear search filter, which can interfere
						C_TradeSkillUI.OpenRecipe(selectedRecipeID)
					end
				end
			end
		end)

		recipeRow[rowNo] = row

		local tradeskill = 999
		if ProfessionShoppingList_Cache.FakeRecipes[recipeInfo.recipeID] then
			tradeskill = ProfessionShoppingList_Cache.FakeRecipes[recipeInfo.recipeID].tradeskillID
		elseif ProfessionShoppingList_Library[recipeInfo.recipeID] then
	   		tradeskill = ProfessionShoppingList_Library[recipeInfo.recipeID].tradeskillID or 999
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
			app.WindowTooltipShow(app.ReagentsHeaderTooltip)
		end)
		app.Window.Reagents:SetScript("OnLeave", function()
			app.ReagentsHeaderTooltip:Hide()
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
		if not ProfessionShoppingList_Cache.Reagents[k] then
			C_Timer.After(1, function() app.UpdateRecipes() end)
			do return end
		end
		reagentsSorted[#reagentsSorted+1] = {reagentID = k, quantity = v, icon = ProfessionShoppingList_Cache.Reagents[k].icon, link = ProfessionShoppingList_Cache.Reagents[k].link}
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
			if GetScreenWidth()/2-ProfessionShoppingList_Settings["windowPosition"].width/2-app.Window:GetLeft() >= 0 then
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
				local amount = math.max(0, math.ceil((app.ReagentQuantities[itemID] - C_Item.GetItemCount(itemID, true, false, true)) / quantityMade))
				if ProfessionShoppingList_Data.Recipes[recipeID] then amount = math.max(0, (amount - ProfessionShoppingList_Data.Recipes[recipeID].quantity)) end

				-- Track the recipe (don't track if 0)
				if amount > 0 then app.TrackRecipe(recipeID, amount) end
			end

			-- Control+click on reagent
			if button == "LeftButton" and IsControlKeyDown() == true then
				-- Get itemIDs
				local itemID = reagentInfo.reagentID
				if ProfessionShoppingList_Cache.ReagentTiers[itemID] then itemID = ProfessionShoppingList_Cache.ReagentTiers[itemID].one end

				-- Get possible recipeIDs
				local recipeIDs = {}
				local no = 0

				for recipe, recipeInfo in pairs(ProfessionShoppingList_Library) do
					if type(recipeInfo) ~= "number" then	-- Because of old ProfessionShoppingList_Library
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
							local itemName, itemLink = C_Item.GetItemInfo(reagentID)

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
					pslOptionButton1 = app.Button(f, C_TradeSkillUI.GetRecipeSchematic(recipeIDs[1], false).name)
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
								local itemName, itemLink = C_Item.GetItemInfo(reagentID)

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
						pslOptionButton2 = app.Button(f, C_TradeSkillUI.GetRecipeSchematic(recipeIDs[2], false).name)
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
								local itemName, itemLink = C_Item.GetItemInfo(reagentID)

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
						pslOptionButton3 = app.Button(f, C_TradeSkillUI.GetRecipeSchematic(recipeIDs[3], false).name)
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
								local itemName, itemLink = C_Item.GetItemInfo(reagentID)

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
						pslOptionButton4 = app.Button(f, C_TradeSkillUI.GetRecipeSchematic(recipeIDs[4], false).name)
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
								local itemName, itemLink = C_Item.GetItemInfo(reagentID)

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
						pslOptionButton5 = app.Button(f, C_TradeSkillUI.GetRecipeSchematic(recipeIDs[5], false).name)
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
								local itemName, itemLink = C_Item.GetItemInfo(reagentID)

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
						pslOptionButton6 = app.Button(f, C_TradeSkillUI.GetRecipeSchematic(recipeIDs[6], false).name)
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
	for k, v in pairs(ProfessionShoppingList_Data.Recipes) do
		if type(k) == "number" then
			trackRecipes = true
		else
			trackItems = true
		end
	end

	-- Set the header title accordingly
	if trackRecipes == true and trackItems == true then
		app.RecipeHeader:SetText(PROFESSIONS_RECIPES_TAB.." & "..ITEMS.." ("..#recipeRow..")")
		app.ReagentHeader:SetText(PROFESSIONS_COLUMN_HEADER_REAGENTS.." & Costs")
	elseif trackRecipes == false and trackItems == true then
		app.RecipeHeader:SetText(ITEMS.." ("..#recipeRow..")")
		app.ReagentHeader:SetText("Costs")
	else
		if #recipeRow == 0 then
			app.RecipeHeader:SetText(PROFESSIONS_RECIPES_TAB)
		else
			app.RecipeHeader:SetText(PROFESSIONS_RECIPES_TAB.." ("..#recipeRow..")")
		end
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
			app.WindowTooltipShow(app.CooldownsHeaderTooltip)
		end)
		app.Window.Cooldowns:SetScript("OnLeave", function()
			app.CooldownsHeaderTooltip:Hide()
		end)
		
		local cooldowns1 = app.Window.Cooldowns:CreateFontString("ARTWORK", nil, "GameFontNormal")
		cooldowns1:SetPoint("LEFT", app.Window.Cooldowns)
		cooldowns1:SetText("Cooldowns")
		cooldowns1:SetScale(1.1)
	end

	local next = next
	if next(ProfessionShoppingList_Data.Cooldowns) == nil or ProfessionShoppingList_Settings["showRecipeCooldowns"] == false then
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
	for k, v in pairs(ProfessionShoppingList_Data.Cooldowns) do
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
			if GetScreenWidth()/2-ProfessionShoppingList_Settings["windowPosition"].width/2-app.Window:GetLeft() >= 0 then
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
				ProfessionShoppingList_Data.Cooldowns[cooldownInfo.id] = nil
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

		local tradeskill = ProfessionShoppingList_Library[cooldownInfo.recipeID].tradeskillID or 999

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
		if next(ProfessionShoppingList_Data.Cooldowns) == nil or ProfessionShoppingList_Settings["showRecipeCooldowns"] == false then
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
		if showRecipes == false or #ProfessionShoppingList_Data.Recipes < 1 then
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
		app.WindowTooltipShow(app.CornerButtonTooltip)
	end)
	app.Window.Corner:SetScript("OnLeave", function()
		app.CornerButtonTooltip:Hide()
	end)

	-- Check if the Untrack button should be enabled
	if not ProfessionShoppingList_Data.Recipes[app.SelectedRecipeID] or ProfessionShoppingList_Data.Recipes[app.SelectedRecipeID].quantity == 0 then
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
		if not ProfessionShoppingList_Data.Recipes[app.OrderRecipeID] or ProfessionShoppingList_Data.Recipes[app.OrderRecipeID].quantity == 0 then
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
	if ProfessionShoppingList_Settings["pcWindows"] == true then
		app.Window:SetSize(ProfessionShoppingList_Settings["pcWindowPosition"].width, ProfessionShoppingList_Settings["pcWindowPosition"].height)
		app.Window:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", ProfessionShoppingList_Settings["pcWindowPosition"].left, ProfessionShoppingList_Settings["pcWindowPosition"].bottom)
	else
		app.Window:SetSize(ProfessionShoppingList_Settings["windowPosition"].width, ProfessionShoppingList_Settings["windowPosition"].height)
		app.Window:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", ProfessionShoppingList_Settings["windowPosition"].left, ProfessionShoppingList_Settings["windowPosition"].bottom)
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
			_, itemLink = C_Item.GetItemInfo(itemID)

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
	if not ProfessionShoppingList_Data.Recipes[recipeID] then ProfessionShoppingList_Data.Recipes[recipeID] = { quantity = 0, recraft = app.Flag["recraft"], link = recipeLink } end
	ProfessionShoppingList_Data.Recipes[recipeID].quantity = ProfessionShoppingList_Data.Recipes[recipeID].quantity + recipeQuantity

	-- Show windows
	app.Show()	-- This also triggers the recipe update

	-- Update the editbox
	if app.Flag["tradeskillAssets"] == true then
		ebRecipeQuantityNo = ProfessionShoppingList_Data.Recipes[recipeID].quantity or 0
		ebRecipeQuantity:SetText(ebRecipeQuantityNo)
	end
end

-- Untrack recipe
function app.UntrackRecipe(recipeID, recipeQuantity)
	if ProfessionShoppingList_Data.Recipes[recipeID] ~= nil then
		-- Clear all recipes if quantity was set to 0
		if recipeQuantity == 0 then ProfessionShoppingList_Data.Recipes[recipeID].quantity = 0 end

		-- Untrack recipe
		ProfessionShoppingList_Data.Recipes[recipeID].quantity = ProfessionShoppingList_Data.Recipes[recipeID].quantity - recipeQuantity

		-- Set numbers to nil if it doesn't exist anymore
		if ProfessionShoppingList_Data.Recipes[recipeID].quantity <= 0 then
			ProfessionShoppingList_Data.Recipes[recipeID] = nil
		end
	end

	-- Clear the cache if no recipes are tracked anymore
	local next = next
	if next(ProfessionShoppingList_Data.Recipes) == nil then app.Clear() end

	-- Update numbers
	app.UpdateRecipes()

	-- Update the editbox
	if app.Flag["tradeskillAssets"] == true then
		if ProfessionShoppingList_Data.Recipes[app.SelectedRecipeID] then
			ebRecipeQuantityNo = ProfessionShoppingList_Data.Recipes[app.SelectedRecipeID].quantity
		else
			ebRecipeQuantityNo = 0
		end
		ebRecipeQuantity:SetText(ebRecipeQuantityNo)
	end
end

-- Create assets
function app.CreateGeneralAssets()
	-- Create Recipes header tooltip
	app.RecipesHeaderTooltip = app.WindowTooltip("Shift+click|cffFFFFFF: Link the recipe.\n|RCtrl+click|cffFFFFFF: Open the recipe (if known on current character).\n|RRight-click|cffFFFFFF: Untrack 1 of the selected recipe.\n|RCtrl+right-click|cffFFFFFF: Untrack all of the selected recipe.")

	-- Create Reagents header tooltip
	app.ReagentsHeaderTooltip = app.WindowTooltip("Shift+click|cffFFFFFF: Link the reagent.\n|RCtrl+click|cffFFFFFF: Add recipe for the selected subreagent, if it exists.\n(This only works for professions that have been opened with PSL active.)\nThe reagents listed here can also be imported to a new Auctionator shopping list.")

	-- Create Cooldowns header tooltip
	app.CooldownsHeaderTooltip = app.WindowTooltip("Right+click|cffFFFFFF: Remove the cooldown reminder.")

	-- Create Close button tooltip
	app.CloseButtonTooltip = app.WindowTooltip("Close the window.")

	-- Create Clear button tooltip
	app.ClearButtonTooltip = app.WindowTooltip("Clear all tracked recipes.")

	-- Create Auctionator button tooltip
	app.AuctionatorButtonTooltip = app.WindowTooltip("Create an Auctionator shopping list.\nAlso initiates a search if you have the Shopping tab open at the Auction House.")

	-- Create corner button tooltip
	app.CornerButtonTooltip = app.WindowTooltip("Double-click|cffFFFFFF: Autosize to fit the window.")
end

function app.CreateTradeskillAssets()
	-- Hide and disable existing tracking buttons
	ProfessionsFrame.CraftingPage.SchematicForm.TrackRecipeCheckBox:SetAlpha(0)
	ProfessionsFrame.CraftingPage.SchematicForm.TrackRecipeCheckBox:EnableMouse(false)
	ProfessionsFrame.OrdersPage.OrderView.OrderDetails.SchematicForm.TrackRecipeCheckBox:SetAlpha(0)
	ProfessionsFrame.OrdersPage.OrderView.OrderDetails.SchematicForm.TrackRecipeCheckBox:EnableMouse(false)

	-- Create the profession UI track button
	if not trackProfessionButton then
		trackProfessionButton = app.Button(ProfessionsFrame.CraftingPage, "Track")
		trackProfessionButton:SetPoint("TOPRIGHT", ProfessionsFrame.CraftingPage.SchematicForm, "TOPRIGHT", -9, -10)
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
		app.Border(ebRecipeQuantity, -6, 1, 2, -2)
	end

	-- Create the profession UI untrack button
	if not untrackProfessionButton then
		untrackProfessionButton = app.Button(ProfessionsFrame.CraftingPage, "Untrack")
		untrackProfessionButton:SetPoint("TOP", trackProfessionButton, "TOP", 0, 0)
		untrackProfessionButton:SetPoint("RIGHT", ebRecipeQuantity, "LEFT", -8, 0)
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
		app.Border(ebSLrank, -6, 1, 2, -2)
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
		app.Border(cookingFireButton, -1, 2, 2, -1)
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
		app.Border(chefsHatButton, -1, 2, 2, -1)

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
		app.Border(thermalAnvilButton, -1, 2, 2, -1)

		thermalAnvilCooldown = CreateFrame("Cooldown", "ThermalAnvilCooldown", thermalAnvilButton, "CooldownFrameTemplate")
		thermalAnvilCooldown:SetAllPoints(thermalAnvilButton)
		thermalAnvilCooldown:SetSwipeColor(1, 1, 1)

		thermalAnvilCharges = thermalAnvilButton:CreateFontString("ARTWORK", nil, "GameFontNormal")
		thermalAnvilCharges:SetPoint("BOTTOMRIGHT", thermalAnvilButton, "BOTTOMRIGHT", 0, 0)
		thermalAnvilCharges:SetJustifyH("RIGHT")
		if not C_Item.IsItemDataCachedByID(87216) then local item = Item:CreateFromItemID(87216) end
		local anvilCharges = C_Item.GetItemCount(87216, false, true, false)
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
		app.Border(alvinButton, -1, 2, 2, -1)

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
		app.Border(lightforgeButton, -1, 2, 2, -1)

		lightforgeCooldown = CreateFrame("Cooldown", "LightforgeCooldown", lightforgeButton, "CooldownFrameTemplate")
		lightforgeCooldown:SetAllPoints(lightforgeButton)
		lightforgeCooldown:SetSwipeColor(1, 1, 1)
	end

	-- Create Dragonflight Milling info
	if not millingDragonflight then
		millingDragonflight = ProfessionsFrame.CraftingPage.SchematicForm:CreateFontString("ARTWORK", nil, "GameFontNormal")
		millingDragonflight:SetPoint("BOTTOMLEFT", ProfessionsFrame.CraftingPage.SchematicForm, "BOTTOMLEFT", 30, 30)
		millingDragonflight:SetJustifyH("LEFT")
		millingDragonflight:SetText(app.Colour("Milling information").."\n|cffFFFFFFFlourishing Pigment: Writhebark\nSerene Pigment: Bubble Poppy\nBlazing Pigment: Saxifrage\nShimmering Pigment: Hochenblume")
	end

	-- Create the fulfil crafting orders UI Track button
	if not trackMakeOrderButton then
		trackMakeOrderButton = app.Button(ProfessionsFrame.OrdersPage.OrderView.OrderDetails, "Track")
		trackMakeOrderButton:SetPoint("TOPRIGHT", ProfessionsFrame.OrdersPage.OrderView.OrderDetails, "TOPRIGHT", -9, -10)
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
		untrackMakeOrderButton = app.Button(ProfessionsFrame.OrdersPage.OrderView.OrderDetails, "Untrack")
		untrackMakeOrderButton:SetPoint("TOPRIGHT", trackMakeOrderButton, "TOPLEFT", -4, 0)
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
		if not ProfessionShoppingList_Data.Recipes[app.SelectedRecipeID] or ProfessionShoppingList_Data.Recipes[app.SelectedRecipeID].quantity == 0 then
			untrackProfessionButton:Disable()
		else
			untrackProfessionButton:Enable()
		end

		-- Update the quantity textbox
		if ebRecipeQuantityNo ~= nil then
			if ProfessionShoppingList_Data.Recipes[app.SelectedRecipeID] then
				ebRecipeQuantityNo = ProfessionShoppingList_Data.Recipes[app.SelectedRecipeID].quantity
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
		local anvilCount = C_Item.GetItemCount(87216)
		-- (De)saturate based on that
		if anvilCount >= 1 then
			thermalAnvilButton:GetNormalTexture():SetDesaturated(false)
		else
			thermalAnvilButton:GetNormalTexture():SetDesaturated(true)
		end
		-- Update charges
		local anvilCharges = C_Item.GetItemCount(87216, false, true, false)
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
		if C_PetJournal.PetIsSummonable(ProfessionShoppingList_Settings["alvinGUID"]) == true then
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
	if not ProfessionShoppingList_Data.Recipes[app.SelectedRecipeID] or ProfessionShoppingList_Data.Recipes[app.SelectedRecipeID].quantity == 0 then
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
	if ProfessionShoppingList_CharacterData.Orders[app.SelectedRecipeID] == "" then ProfessionShoppingList_CharacterData.Orders[app.SelectedRecipeID] = nil end

	-- Enable the quick order button if abilityID and target are known
	if app.Flag["craftingOrderAssets"] == true then
		if ProfessionShoppingList_Library[app.SelectedRecipeID] and type(ProfessionShoppingList_Library[app.SelectedRecipeID]) ~= "number" then
			if ProfessionShoppingList_Library[app.SelectedRecipeID].abilityID ~= nil and ProfessionShoppingList_CharacterData.Orders[app.SelectedRecipeID] ~= nil then
				personalOrderButton:Enable()
			else
				personalOrderButton:Disable()
			end
		else
			personalOrderButton:Disable()
		end

		-- Update the personal order name textbox
		if ProfessionShoppingList_CharacterData.Orders[app.SelectedRecipeID] then
			personalCharname:SetText(ProfessionShoppingList_CharacterData.Orders[app.SelectedRecipeID])
		else
			personalCharname:SetText("")
		end
	end
end

-- Tooltip information
function app.TooltipInfo()
	local function OnTooltipSetItem(tooltip)
		-- Get item info from the last processed tooltip and the primary tooltip
		local _, _, itemID = TooltipUtil.GetDisplayedItem(tooltip)
		local _, _, primaryItemID = TooltipUtil.GetDisplayedItem(GameTooltip)

		-- If the last processed tooltip is the same as the primary tooltip (aka, not a compare tooltip)
		if itemID == primaryItemID then
			-- Only then send it to the global variable (for usage in vendor tracking)
			app.TooltipItemID = itemID
		end

		-- Only run this if the setting is enabled
		if ProfessionShoppingList_Settings["showTooltip"] == true then
			-- Stop if error, it will try again on its own REAL soon
			if itemID == nil then return end

			-- Get owned number of reagents
			local reagentID1
			local reagentID2
			local reagentID3
			local reagentAmountHave1 = 0
			local reagentAmountHave2 = 0
			local reagentAmountHave3 = 0

			if ProfessionShoppingList_Cache.ReagentTiers[itemID] and ProfessionShoppingList_Cache.ReagentTiers[itemID].one ~= 0 then
				reagentID1 = ProfessionShoppingList_Cache.ReagentTiers[itemID].one
				reagentAmountHave1 = C_Item.GetItemCount(ProfessionShoppingList_Cache.ReagentTiers[itemID].one, true, false, true)
			end
			if ProfessionShoppingList_Cache.ReagentTiers[itemID] and ProfessionShoppingList_Cache.ReagentTiers[itemID].two ~= 0 then
				reagentID2 = ProfessionShoppingList_Cache.ReagentTiers[itemID].two
				reagentAmountHave2 = C_Item.GetItemCount(ProfessionShoppingList_Cache.ReagentTiers[itemID].two, true, false, true)
			end
			if ProfessionShoppingList_Cache.ReagentTiers[itemID] and ProfessionShoppingList_Cache.ReagentTiers[itemID].three ~= 0 then
				reagentID3 = ProfessionShoppingList_Cache.ReagentTiers[itemID].three
				reagentAmountHave3 = C_Item.GetItemCount(ProfessionShoppingList_Cache.ReagentTiers[itemID].three, true, false, true)
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
				tooltip:AddLine(app.NameShort..": "..reagentAmountHave.."/"..reagentAmountNeed.." ("..math.max(0,reagentAmountNeed-reagentAmountHave).." more needed)")
			end
		end
	end
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)
end

-- Clear everything except the recipe cache
function app.Clear()
	ProfessionShoppingList_Data.Recipes = {}
	ProfessionShoppingList_Cache.ReagentTiers = {}
	ProfessionShoppingList_Cache.Reagents = {}
	ProfessionShoppingList_Cache.FakeRecipes = {}
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
	Settings.OpenToCategory(app.Category:GetID())
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
	GameTooltip:AddLine(app.NameLong.."\n|cff9D9D9DLMB:|R Toggle the windows.\n|cff9D9D9DRMB:|R Show the settings.")
	GameTooltip:Show()
end

function ProfessionShoppingList_Leave()
	GameTooltip:Hide()
end

-- Settings and minimap icon
function app.Settings()
	-- Minimap button
	local miniButton = LibStub("LibDataBroker-1.1"):NewDataObject("ProfessionShoppingList", {
		type = "data source",
		text = app.NameLong,
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
			tooltip:AddLine(app.NameLong.."\n|cff9D9D9DLMB:|R Toggle the windows.\n|cff9D9D9DRMB:|R Show the settings.")
		end,
	})
						
	local icon = LibStub("LibDBIcon-1.0", true)
	icon:Register("ProfessionShoppingList", miniButton, ProfessionShoppingList_Settings)

	if ProfessionShoppingList_Settings["minimapIcon"] == true then
		ProfessionShoppingList_Settings["hide"] = false
		icon:Show("ProfessionShoppingList")
	else
		ProfessionShoppingList_Settings["hide"] = true
		icon:Hide("ProfessionShoppingList")
	end

	-- Settings page
	function app.SettingChanged(_, setting, value)
		local variable = setting:GetVariable()
		ProfessionShoppingList_Settings[variable] = value
	end

	local category, layout = Settings.RegisterVerticalLayoutCategory(app.NameLong)
	Settings.RegisterAddOnCategory(category)
	app.Category = category

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(GetAddOnMetadata("ProfessionShoppingList", "Version")))

	local variable, name, tooltip = "minimapIcon", "Show minimap icon", "Show the minimap icon. If you disable this, "..app.NameShort.." is still available from the AddOn Compartment."
	local setting = Settings.RegisterAddOnSetting(category, name, variable, Settings.VarType.Boolean, ProfessionShoppingList_Settings[variable])
	Settings.CreateCheckBox(category, setting, tooltip)
	Settings.SetOnValueChangedCallback(variable, app.SettingChanged)
	Settings.SetOnValueChangedCallback(variable, function()
		if ProfessionShoppingList_Settings["minimapIcon"] == true then
			ProfessionShoppingList_Settings["hide"] = false
			icon:Show("ProfessionShoppingList")
		else
			ProfessionShoppingList_Settings["hide"] = true
			icon:Hide("ProfessionShoppingList")
		end
	end)

	local variable, name, tooltip = "ProfessionShoppingList_CharacterData.Recipes", "Track recipes per character", "Track recipes per character, instead of account-wide."
	local setting = Settings.RegisterAddOnSetting(category, name, variable, Settings.VarType.Boolean, ProfessionShoppingList_Settings[variable])
	Settings.CreateCheckBox(category, setting, tooltip)
	Settings.SetOnValueChangedCallback(variable, app.SettingChanged)
	Settings.SetOnValueChangedCallback(variable, function()
		app.UpdateRecipes()
	end)

	local variable, name, tooltip = "pcWindows", "Window position per character", "Save the window position per character, instead of account-wide."
	local setting = Settings.RegisterAddOnSetting(category, name, variable, Settings.VarType.Boolean, ProfessionShoppingList_Settings[variable])
	Settings.CreateCheckBox(category, setting, tooltip)
	Settings.SetOnValueChangedCallback(variable, app.SettingChanged)

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Tracking Window"))

	local variable, name, tooltip = "showRecipeCooldowns", "Track recipe cooldowns", "Enable the tracking of recipe cooldowns. These will show in the tracking window, and in chat upon login if ready."
	local setting = Settings.RegisterAddOnSetting(category, name, variable, Settings.VarType.Boolean, ProfessionShoppingList_Settings[variable])
	Settings.CreateCheckBox(category, setting, tooltip)
	Settings.SetOnValueChangedCallback(variable, app.SettingChanged)
	Settings.SetOnValueChangedCallback(variable, function()
		app.UpdateRecipes()
	end)

	local variable, name, tooltip = "showRemaining", "Show remaining reagents", "Only show how many reagents you still need in the tracking window, instead of have/need."
	local setting = Settings.RegisterAddOnSetting(category, name, variable, Settings.VarType.Boolean, ProfessionShoppingList_Settings[variable])
	Settings.CreateCheckBox(category, setting, tooltip)
	Settings.SetOnValueChangedCallback(variable, app.SettingChanged)
	Settings.SetOnValueChangedCallback(variable, function()
		C_Timer.After(0.5, function() app.UpdateRecipes() end) -- Toggling this setting seems buggy? This fixes it. :)
	end)

	local variable, name, tooltip = "reagentQuality", "Minimum reagent quality", "Set the minimum quality reagents need to be before "..app.NameShort.." includes them in the item count."
	local function GetOptions()
		local container = Settings.CreateControlTextContainer()
		container:Add(1, "|A:Professions-ChatIcon-Quality-Tier1:17:15::1|a Tier 1")
		container:Add(2, "|A:Professions-ChatIcon-Quality-Tier2:17:15::1|a Tier 2")
		container:Add(3, "|A:Professions-ChatIcon-Quality-Tier3:17:15::1|a Tier 3")
		return container:GetData()
	end
	local setting = Settings.RegisterAddOnSetting(category, name, variable, Settings.VarType.Number, ProfessionShoppingList_Settings[variable])
	Settings.CreateDropDown(category, setting, GetOptions, tooltip)
	Settings.SetOnValueChangedCallback(variable, app.SettingChanged)
	Settings.SetOnValueChangedCallback(variable, function()
		C_Timer.After(0.5, function() app.UpdateRecipes() end) -- Toggling this setting seems buggy? This fixes it. :)
	end)

	local variable, name, tooltip = "removeCraft", "Untrack on craft", "Remove one of a tracked recipe when you successfully craft it."
	local setting = Settings.RegisterAddOnSetting(category, name, variable, Settings.VarType.Boolean, ProfessionShoppingList_Settings[variable])
	local parentSetting = Settings.CreateCheckBox(category, setting, tooltip)
	Settings.SetOnValueChangedCallback(variable, app.SettingChanged)

	local variable, name, tooltip = "closeWhenDone", "Close window when done", "Close the tracking window after crafting the last tracked recipe."
	local setting = Settings.RegisterAddOnSetting(category, name, variable, Settings.VarType.Boolean, ProfessionShoppingList_Settings[variable])
	local subSetting = Settings.CreateCheckBox(category, setting, tooltip)
	Settings.SetOnValueChangedCallback(variable, app.SettingChanged)
	subSetting:SetParentInitializer(parentSetting, function() return ProfessionShoppingList_Settings["removeCraft"] end)

	local variable, name, tooltip = "showTooltip", "Show tooltip information", "Show how many of a reagent you have/need on the item's tooltip."
	local setting = Settings.RegisterAddOnSetting(category, name, variable, Settings.VarType.Boolean, ProfessionShoppingList_Settings[variable])
	Settings.CreateCheckBox(category, setting, tooltip)
	Settings.SetOnValueChangedCallback(variable, app.SettingChanged)

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Information"))

	local variable, name, tooltip = "", "Slash commands", "Type these in chat to use them!"
	local function GetOptions()
		local container = Settings.CreateControlTextContainer()
		container:Add(1, "/psl", "Toggle the tracking window.")
		container:Add(2, "/psl resetpos", "Reset the tracking window position.")
		container:Add(3, "/psl settings", "Go to the settings.")
		container:Add(4, "/psl clear", "Clear all tracked recipes.")
		container:Add(5, "/psl track |cff1B9C85recipeID quantity|R", "Track a recipe.")
		container:Add(6, "/psl untrack |cff1B9C85recipeID quantity|R", "Untrack a recipe.")
		container:Add(7, "/psl untrack |cff1B9C85recipeID |Rall", "Untrack all of a recipe.")
		container:Add(8, "/psl |cff1B9C85[crafting achievement]|R", "Track the recipes needed for the linked achievement.")
		container:Add(9, "/psl duration |cff1B9C85number|R", "Set the default quick order duration.")
		return container:GetData()
	end
	local setting = Settings.RegisterAddOnSetting(category, name, variable, Settings.VarType.Number, "")
	Settings.CreateDropDown(category, setting, GetOptions, tooltip)
	
	--initializer:AddSearchTags
end

-- When the AddOn is fully loaded, actually run the components
function event:ADDON_LOADED(addOnName, containsBindings)
	if addOnName == appName then
		app.InitialiseCore()
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
				ProfessionShoppingList_Settings["windowPosition"] = { ["left"] = GetScreenWidth()/2-100, ["bottom"] = GetScreenHeight()/2-100, ["width"] = 200, ["height"] = 200, }
				ProfessionShoppingList_Settings["pcWindowPosition"] = ProfessionShoppingList_Settings["windowPosition"]

				-- Show the window, which will also run setting its size and position
				app.Show()
			-- Track recipe
			elseif command == 'track' then
				-- Split entered recipeID and recipeQuantity and turn them into real numbers
				local part1, part2 = rest:match("^(%S*)%s*(.-)$")
				recipeID = tonumber(part1)
				recipeQuantity = tonumber(part2)

				-- Only run if the recipeID is cached and the quantity is an actual number
				if ProfessionShoppingList_Library[recipeID] then
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
				if ProfessionShoppingList_Data.Recipes[recipeID] then
					if part2 == "all" then
						app.UntrackRecipe(recipeID, 0)

						-- Show windows
						app.Show()
					elseif type(recipeQuantity) == "number" and recipeQuantity ~= 0 and recipeQuantity <= ProfessionShoppingList_Data.Recipes[recipeID].quantity then
						app.UntrackRecipe(recipeID, recipeQuantity)

						-- Show windows
						app.Show()
					else
						app.Print("Invalid parameters. Please enter a valid recipe quantity.")
					end
				else
					app.Print("Invalid parameters. Please enter a tracked recipe ID.")
				end
			-- Quick order duration
			elseif command == 'duration' then
				rest = tonumber(rest)
				if rest == 0 or rest == 12 then
					ProfessionShoppingList_Settings["quickOrderDuration"] = 0
					app.Print("Quick order duration set to 12hr (short).")
				elseif rest == 1 or rest == 24 then
					ProfessionShoppingList_Settings["quickOrderDuration"] = 1
					app.Print("Quick order duration set to 24hr (medium).")
				elseif rest == 2 or rest == 48 then
					ProfessionShoppingList_Settings["quickOrderDuration"] = 2
					app.Print("Quick order duration set to 48hr (long).")
				else
					app.Print("Invalid parameter. Use a number: 0, 1, 2 (duration) or 12, 24, or 48 (hours) to set the default quick order duration.")
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
			ProfessionShoppingList_Library[recipeID] = {itemID = item, abilityID = ability, tradeskillID = tradeskill}
		else
			ProfessionShoppingList_Library[recipeID] = {itemID = 0, abilityID = ability, tradeskillID = tradeskill}
		end
	end

	-- Get Alvin the Anvil's GUID
	for i=1, 9999 do
		local petID, speciesID = C_PetJournal.GetPetInfoByIndex(i)
		if speciesID == 3274 then
			if petID then ProfessionShoppingList_Settings["alvinGUID"] = petID end
			break
		elseif speciesID == nil then
			break
		end
	end

	if app.Flag["tradeskillAssets"] == true then
		if ProfessionShoppingList_Settings["alvinGUID"] ~= "unknown" then
			alvinButton:SetAttribute("macrotext1", "/run C_PetJournal.SummonPetByGUID('"..ProfessionShoppingList_Settings["alvinGUID"].."')")
		else
			alvinButton:SetAttribute("macrotext1", "")
		end
	end
end

-- When a recipe is selected (also used to determine professionID, which TRADE_SKILL_SHOW() is too quick for)
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

		-- Milling info
		local function millingInfo()
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

		-- Profession buttons
		local function professionButtons()
			-- Show stuff depending on which profession is opened
			local skillLineID = C_TradeSkillUI.GetProfessionChildSkillLineID()
			local professionID = C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID).profession

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

		if app.Flag["tradeskillAssets"] == true then
			millingInfo()
			professionButtons()
		end
	end
end

-- When a spell is succesfully cast by the player
function event:UNIT_SPELLCAST_SUCCEEDED(unitTarget, castGUID, spellID)
	if UnitAffectingCombat("player") == false and unitTarget == "player" then
		-- Profession button stuff
		if spellID == 818 or spellID == 67556 or spellID == 126462 or spellID == 279205 or spellID == 259930 then
			C_Timer.After(0.1, function() app.UpdateAssets() end)
		end
	
		-- Run only when the spell cast is a known recipe
		if ProfessionShoppingList_Library[spellID] then
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
							for k2, v2 in pairs(ProfessionShoppingList_Data.Cooldowns) do
								if v2.recipeID == v then
									ProfessionShoppingList_Data.Cooldowns[k2] = nil
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
					for k, v in ipairs(ProfessionShoppingList_Data.Cooldowns) do
						if v.recipeID == spellID and v.user == character .. "-" .. realm then
							ProfessionShoppingList_Data.Cooldowns[k] = {name = recipeName, recipeID = spellID, cooldown = cooldown, start = recipeStart, user = character .. "-" .. realm, charges = charges, maxCharges = maxCharges}
							cdExists = true
						end
					end
					-- Otherwise, create a new entry
					if cdExists == false then
						ProfessionShoppingList_Data.Cooldowns[#ProfessionShoppingList_Data.Cooldowns+1] = {name = recipeName, recipeID = spellID, cooldown = cooldown, start = recipeStart, user = character .. "-" .. realm, charges = charges, maxCharges = maxCharges}
					end
					-- And then update our window
					app.UpdateRecipes()
				end
			end)
		end

		-- Run only when crafting a tracked recipe, and if the remove craft option is enabled
		if ProfessionShoppingList_Data.Recipes[spellID] and ProfessionShoppingList_Settings["removeCraft"] == true then
			-- Remove 1 tracked recipe when it has been crafted (if the option is enabled)
			app.UntrackRecipe(spellID, 1)
			
			-- Close windows if no recipes are left and the option is enabled
			local next = next
			if next(ProfessionShoppingList_Data.Recipes) == nil then
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
		if next(ProfessionShoppingList_Data.Recipes) ~= nil then
			app.UpdateNumbers()
		end

		-- If the setting for split reagent bag count is enabled
		if ProfessionShoppingList_Settings["backpackCount"] == true then
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
	if ProfessionShoppingList_Settings["onetimeMessages"].vendorItems == false then
		app.Popup(true, "|cffFFFFFFYou can now track vendor items with "..app.NameLong.."|cffFFFFFF!\n|RAlt+Click|cffFFFFFF any vendor item and "..app.NameShort.."|cffFFFFFF tracks the total costs.")

		ProfessionShoppingList_Settings["onetimeMessages"].vendorItems = true
	end

	-- When the user Alt+clicks a vendor item
	local function TrackMerchantItem()
		if IsAltKeyDown() == true then
			-- Get merchant info
			local merchant = MerchantFrameTitleText:GetText()

			-- Get item info from tooltip
			local itemID = app.TooltipItemID

			-- Get the item index for this vendor
			local vendorIndex = 0
			for index = 1, GetMerchantNumItems() do
				if GetMerchantItemID(index) == itemID then vendorIndex = index end
			end

			-- Stop the function if the vendor does not have the item that is being Alt+clicked
			if vendorIndex == 0 then do return end end

			local itemLink = GetMerchantItemLink(vendorIndex)
			local _, _, itemPrice = GetMerchantItemInfo(vendorIndex)

			-- Add this as a fake recipe
			local key = merchant..":"..itemID
			ProfessionShoppingList_Cache.FakeRecipes[key] = {
				["itemID"] = itemID,
				["tradeskillID"] = 0,	-- Vendor item
				["costCopper"] = 0,
				["costItems"] = {},
				["costCurrency"] = {},
			}

			if itemPrice then
				ProfessionShoppingList_Cache.FakeRecipes[key].costCopper = itemPrice
				ProfessionShoppingList_Cache.Reagents["gold"] = { 
					icon = app.iconProfession[0],
					link = BONUS_ROLL_REWARD_MONEY,
				}
			end

			-- Get the different currencies needed to purchase the item
			for i=1, GetMerchantItemCostInfo(vendorIndex), 1 do
				local itemTexture, itemValue, itemLink, currencyName = GetMerchantItemCostItem(vendorIndex, i)
				if currencyName and itemLink then
					local currencyID = C_CurrencyInfo.GetCurrencyIDFromLink(itemLink)

					ProfessionShoppingList_Cache.FakeRecipes[key].costCurrency[currencyID] = itemValue
					ProfessionShoppingList_Cache.Reagents["currency:"..currencyID] = { 
						icon = itemTexture,
						link = C_CurrencyInfo.GetCurrencyLink(currencyID),
					}
				elseif itemLink then
					local itemID = GetItemInfoFromHyperlink(itemLink)
					ProfessionShoppingList_Cache.FakeRecipes[key].costItems[itemID] = itemValue
					if not ProfessionShoppingList_Cache.ReagentTiers[itemID] then
						ProfessionShoppingList_Cache.ReagentTiers[itemID] = {
							one = itemID,
							two = 0,
							three = 0,
						}
					end
				end
				
			end

			-- Track the vendor item as a fake recipe
			if not ProfessionShoppingList_Data.Recipes[key] then ProfessionShoppingList_Data.Recipes[key] = { quantity = 0, link = itemLink} end
			ProfessionShoppingList_Data.Recipes[key].quantity = ProfessionShoppingList_Data.Recipes[key].quantity + 1

			-- Show the window
			app.Show()
		end
	end

	-- Hook the script onto the merchant buttons (once)
	if app.Flag["merchantAssets"] == false then
		for i = 1, 99 do	-- Works for AddOns that expand the vendor frame up to 99 slots
			local itemButton = _G["MerchantItem"..i.."ItemButton"]
			if itemButton then
				itemButton:HookScript("OnClick", function() TrackMerchantItem() end)
			end
		end

		-- Set the flag to true so it doesn't trigger again
		app.Flag["merchantAssets"] = true
	end
end

-- Replace the in-game tracking of shift+clicking a recipe with PSL's
function event:TRACKED_RECIPE_UPDATE(recipeID, tracked)
	if tracked == true then
		app.TrackRecipe(recipeID,1)
		C_TradeSkillUI.SetRecipeTracked(recipeID, false, false)
		C_TradeSkillUI.SetRecipeTracked(recipeID, false, true)
	end
end

-- When the user encounters a loading screen
function event:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
	-- Only on initialLoad
	if isInitialLogin == true then
		-- Check all tracked recipe cooldowns
		for k, recipeInfo in pairs(ProfessionShoppingList_Data.Cooldowns) do
			-- Check the remaining cooldown
			local cooldownRemaining = recipeInfo.start + recipeInfo.cooldown - GetServerTime()

			-- If the recipe is off cooldown
			if cooldownRemaining <= 0 then
				-- Check charges if they exist and return one
				if recipeInfo.maxCharges > 0 and recipeInfo.maxCharges > recipeInfo.charges then
					ProfessionShoppingList_Data.Cooldowns[k].charges = ProfessionShoppingList_Data.Cooldowns[k].charges + 1

					-- And move the reset time if we're not at full charges yet
					if ProfessionShoppingList_Data.Cooldowns[k].charges ~= ProfessionShoppingList_Data.Cooldowns[k].maxCharges then
						ProfessionShoppingList_Data.Cooldowns[k].start = GetServerTime()
						ProfessionShoppingList_Data.Cooldowns[k].cooldown = GetQuestResetTime()
					end
				end

				-- If the option to show recipe cooldowns is enabled and all charges are full (or 0 = 0 for recipes without charges)
				if ProfessionShoppingList_Settings["showRecipeCooldowns"] == true and ProfessionShoppingList_Data.Cooldowns[k].charges == ProfessionShoppingList_Data.Cooldowns[k].maxCharges then
					-- Show the reminder
					app.Print(recipeInfo.name .. " is ready to craft again on " .. recipeInfo.user .. ".")
				end
			end
		end
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