------------------------------------------
-- Profession Shopping List: Tweaks.lua --
------------------------------------------
-- Tweaks module

-- Initialisation
local appName, app =  ...	-- Returns the AddOn name and a unique table
local L = app.locales

------------------
-- INITIAL LOAD --
------------------

-- When the AddOn is fully loaded, actually run the components
app.Event:Register("ADDON_LOADED", function(addOnName, containsBindings)
	if addOnName == appName then
		app.UnderminePrices()
		app.HideOribos()
		app.DisableHandyNotesAltRMB()
		app.SettingsTweaks()
	end
end)

----------------------
-- BACKPACK SORTING --
----------------------

app.Event:Register("PLAYER_ENTERING_WORLD", function(isInitialLogin, isReloadingUi)
	-- Enforce backpack sorting options
	if ProfessionShoppingList_Settings["backpackCleanup"] == 1 then
		C_Container.SetSortBagsRightToLeft(false)
	elseif ProfessionShoppingList_Settings["backpackCleanup"] == 2 then
		C_Container.SetSortBagsRightToLeft(true)
	end
	
	if ProfessionShoppingList_Settings["backpackLoot"] == 1 then
		C_Container.SetInsertItemsLeftToRight(true)
	elseif ProfessionShoppingList_Settings["backpackLoot"] == 2 then
		C_Container.SetInsertItemsLeftToRight(false)
	end
end)

-----------------------------
-- SPLIT REAGENT BAG COUNT --
-----------------------------

-- When bag changes occur (out of combat)
app.Event:Register("BAG_UPDATE_DELAYED", function()
	if not UnitAffectingCombat("player") then
		-- If the setting for split reagent bag count is enabled
		if ProfessionShoppingList_Settings["backpackCount"] then
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
end)

-----------------
-- QUEUE SOUND --
-----------------

-- Play the DBM-style queue sound
function app.QueueSound()
	-- If the setting is enabled
	if ProfessionShoppingList_Settings["queueSound"] then
		PlaySoundFile(567478, "Master")
	end
end

-- When a LFG queue pops
app.Event:Register("LFG_PROPOSAL_SHOW", function()
	app.QueueSound()
end)

-- When a pet battle queue pops
app.Event:Register("PET_BATTLE_QUEUE_PROPOSE_MATCH", function()
	app.QueueSound()
end)

-- When a PvP queue pops
hooksecurefunc("PVPReadyDialog_Display", function()
	app.QueueSound()
end)

---------------------
-- MERCHANT FILTER --
---------------------

-- Set the Vendor filter to 'All'
function app.MerchantFilter()
	-- If the setting is enabled
	if ProfessionShoppingList_Settings["vendorAll"] then
		RunNextFrame(function()
			SetMerchantFilter(1)
			MerchantFrame_Update()
		end)
	end
end

-- When a vendor window is opened
app.Event:Register("MERCHANT_SHOW", function()
	app.MerchantFilter()
end)

----------------------
-- UNDERMINE PRICES --
----------------------

function app.UnderminePrices()
	local function OnTooltipSetItem(tooltip)
		-- Get item info from the last processed tooltip and the primary tooltip
		local _, unreliableItemLink, itemID = TooltipUtil.GetDisplayedItem(tooltip)

		-- Stop if error, it will try again on its own REAL soon
		if itemID == nil then return end

		-- Also grab the itemLink from the itemID, rather than the itemLink provided above, because uhhhh shit is wack
		local _, itemLink = C_Item.GetItemInfo(itemID)

		-- Only run this if the setting is enabled
		if ProfessionShoppingList_Settings["underminePrices"] then
			-- If Oribos Exchange is loaded
			local loaded, finished = C_AddOns.IsAddOnLoaded("OribosExchange")
			if finished then
				-- Grab the pricing information
				local marketPrice = 0
				local regionPrice = 0

				-- Check both links for pricing data
				local oeData = {}
				OEMarketInfo(itemLink,oeData)
				if oeData["market"] == nil and oeData["region"] == nil then
					-- Unless the item is BoP (BoP recipes for example)
					local bindType = select(14, C_Item.GetItemInfo(itemID))
					if bindType ~= 1 then
						OEMarketInfo(unreliableItemLink,oeData)
					end
				end
				
				if oeData["market"] ~= nil then
					marketPrice = oeData["market"]
				end
				if oeData["region"] ~= nil then
					regionPrice = oeData["region"]
				end

				-- Process the pricing information
				if marketPrice + regionPrice > 0 then
					-- Round up to the nearest full gold value
					local function round(number)
						return math.ceil(number / 10000) * 10000
					end
					marketPrice = round(marketPrice)
					regionPrice = round(regionPrice)

					-- Set the tooltip information
					tooltip:AddLine(" ")	-- Blank line
					if marketPrice > 0 then
						tooltip:AddDoubleLine(GetNormalizedRealmName(),GetMoneyString(marketPrice, true))
					end
					if regionPrice > 0 then
						tooltip:AddDoubleLine(GetCurrentRegionName() .. " " .. L.REGION,GetMoneyString(regionPrice, true))
					end
				end
			end
		end
	end
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)
end

local LibBattlePetTooltipLine = LibStub("LibBattlePetTooltipLine-1-0")	-- Load this library
hooksecurefunc("BattlePetToolTip_Show", function(...)
	-- Only run this if the setting is enabled
	if ProfessionShoppingList_Settings["underminePrices"] then
		-- If Oribos Exchange is loaded
		local loaded, finished = C_AddOns.IsAddOnLoaded("OribosExchange")
		if finished then
			local speciesID1, level, breedQuality, maxHealth, power, speed, bracketName =  ...

			-- Make itemLink if it grabs the proper pet
			local itemLink = "|cff0070dd|Hbattlepet:" .. speciesID1 .. ":" .. level .. ":" .. breedQuality .. ":" .. maxHealth .. ":" .. power .. ":" .. speed .. "|h" .. bracketName .. "|h|r"

			-- Stop if error, it will try again on its own REAL soon
			if itemLink == nil then return end

			-- Grab pricing information
			local oeData = {}
			OEMarketInfo(itemLink,oeData)
			local marketPrice = 0
			local regionPrice = 0

			if oeData["market"] ~= nil then
				marketPrice = oeData["market"]
			end
			if oeData["region"] ~= nil then
				regionPrice = oeData["region"]
			end

			-- Process the pricing information
			if marketPrice + regionPrice > 0 then
				-- Round up to the nearest full gold value
				marketPrice = math.ceil(marketPrice / 10000) * 10000
				regionPrice = math.ceil(regionPrice / 10000) * 10000

				-- Set the tooltip information
				LibBattlePetTooltipLine:AddDoubleLine(BattlePetTooltip, " ", " ")
				if marketPrice > 0 then
					LibBattlePetTooltipLine:AddDoubleLine(BattlePetTooltip, GetNormalizedRealmName(), GetMoneyString(marketPrice, true))
				end
				if regionPrice > 0 then
					LibBattlePetTooltipLine:AddDoubleLine(BattlePetTooltip, GetCurrentRegionName() .. " " .. L.REGION, GetMoneyString(regionPrice, true))
				end
			end
		end
	end
end)

function app.HideOribos()
	-- Only run this if the setting is enabled
	if ProfessionShoppingList_Settings["underminePrices"] then
		-- If Oribos Exchange is loaded
		local loaded, finished = C_AddOns.IsAddOnLoaded("OribosExchange")
		if finished then
			-- Disable the original tooltip
			OETooltip(false)

			-- And hide the warning about it
			local function removeMessage()
				local message = "Tooltip prices disabled. Run |cFFFFFF78/oetooltip on|r to enable."
				local removed = 0

				-- Remove the message if it contains the message string above
				ChatFrame1:RemoveMessagesByPredicate(function(m)
					-- We're probably too fast, so mark removed as +1
					if m:find(message) ~= nil then removed = removed + 1 end
					return m:find(message) ~= nil
				end)

				-- Try again if we failed, but only 10 times max
				if removed < 10 then
					C_Timer.After(1, function()
						RunNextFrame(removeMessage)
					end)
				end
			end
			removeMessage()
		end
	end
end

----------------------------
-- HANDYNOTES ALT+RMB FIX --
----------------------------

function app.DisableHandyNotesAltRMB()
	-- Only run this if the setting is enabled
	if ProfessionShoppingList_Settings["handyNotes"] then
		-- Thank you for this code, Numy, this saves me a lot of frustration
		if C_AddOns.IsAddOnLoaded("HandyNotes") and LibStub("AceAddon-3.0"):GetAddon("HandyNotes") then
			local f = LibStub("AceAddon-3.0"):GetAddon("HandyNotes"):GetModule("HandyNotes").ClickHandlerFrame
			local f2 = CreateFrame("Frame")
			f:SetParent(f2)
			f2:Hide()
		end
	end
end

------------------------
-- INSTANTLY CATALYSE --
------------------------

app.Event:Register("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", function(type)
	-- Only run this if the setting is enabled
	if ProfessionShoppingList_Settings["catalystButton"] then
		if type == 44 and not app.CatalystSkipButton then
			app.CatalystSkipButton = app.Button(ItemInteractionFrame, L.CATALYSTBUTTON_LABEL)
			app.CatalystSkipButton:SetPoint("CENTER", ItemInteractionFrameTitleText, 0, -30)
			app.CatalystSkipButton:SetScript("OnClick", function()
				ItemInteractionFrame:CompleteItemInteraction()
			end)
		elseif type == 44 and app.CatalystSkipButton then
			app.CatalystSkipButton:Show()
		end
	end
end)

app.Event:Register("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", function(type)
	if app.CatalystSkipButton then
		app.CatalystSkipButton:Hide()
	end
end)

-----------------------
-- Quality Assurance --
-----------------------

-- Remove title spam
app.Event:Register("PLAYER_LOGIN", function()
	-- Only run this if the setting is enabled
	if ProfessionShoppingList_Settings["qualityAssurance"] then
		local loginTime = GetTime()
		-- Hide dumb titles
		local function removeMessage()
			local message = string.sub(NEW_TITLE_EARNED, 1, -7)
			-- Remove the message if it contains the message string above
			ChatFrame1:RemoveMessagesByPredicate(function(m)
				return m:find(message) ~= nil
			end)
			-- Try again if we failed, but only for a little while
			if loginTime + 20 > GetTime() then
				C_Timer.After(1, function()
					removeMessage()
				end)
			else
				return
			end
		end
		removeMessage()
	end
end)

--------------
-- SETTINGS --
--------------

function app.SettingsTweaks()
	local category, layout = Settings.RegisterVerticalLayoutSubcategory(app.Category, L.SETTINGS_HEADER_TWEAKS)
	Settings.RegisterAddOnCategory(category)

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(BAG_NAME_BACKPACK))

	local variable, name, tooltip = "backpackCount", L.SETTINGS_SPLITBAG_TITLE, L.SETTINGS_SPLITBAG_TOOLTIP
	local setting = Settings.RegisterAddOnSetting(category, appName .. "_" .. variable, variable, ProfessionShoppingList_Settings, Settings.VarType.Boolean, name, true)
	Settings.CreateCheckbox(category, setting, tooltip)
	setting:SetValueChangedCallback(function()
		-- Get number of free bag slots
		local freeSlots1 = C_Container.GetContainerNumFreeSlots(0) + C_Container.GetContainerNumFreeSlots(1) + C_Container.GetContainerNumFreeSlots(2) + C_Container.GetContainerNumFreeSlots(3) + C_Container.GetContainerNumFreeSlots(4)
		local freeSlots2 = C_Container.GetContainerNumFreeSlots(5)

		-- If the setting for split reagent bag count is enabled and the player has a reagent bag
		if ProfessionShoppingList_Settings["backpackCount"] and C_Container.GetContainerNumSlots(5) ~= 0 then
			-- Replace the bag count text
			MainMenuBarBackpackButtonCount:SetText("(" .. freeSlots1 .. "+" .. freeSlots2 .. ")")
		else
			-- Reset the bag count text
			MainMenuBarBackpackButtonCount:SetText("(" .. freeSlots1 + freeSlots2 .. ")")
		end
	end)

	local variable, name, tooltip = "backpackCleanup", L.SETTINGS_CLEANBAG_TITLE, L.SETTINGS_CLEANBAG_TOOLTIP
	local function GetOptions()
		local container = Settings.CreateControlTextContainer()
		container:Add(0, L.SETTINGS_DEFAULT)
		container:Add(1, L.SETTINGS_LTOR)
		container:Add(2, L.SETTINGS_RTOL)
		return container:GetData()
	end
	local defaultValue = 0
	local setting = Settings.RegisterAddOnSetting(category, appName .. "_" .. variable, variable, ProfessionShoppingList_Settings, Settings.VarType.Number, name, 0)
	Settings.CreateDropdown(category, setting, GetOptions, tooltip)
	setting:SetValueChangedCallback(function()
		if ProfessionShoppingList_Settings["backpackCleanup"] == 1 then
			C_Container.SetSortBagsRightToLeft(false)
		elseif ProfessionShoppingList_Settings["backpackCleanup"] == 2 then
			C_Container.SetSortBagsRightToLeft(true)
		end
	end)

	local variable, name, tooltip = "backpackLoot", L.SETTINGS_LOOTBAG_TITLE, L.SETTINGS_LOOTBAG_TOOLTIP
	local function GetOptions()
		local container = Settings.CreateControlTextContainer()
		container:Add(0, L.SETTINGS_DEFAULT)
		container:Add(1, L.SETTINGS_LTOR)
		container:Add(2, L.SETTINGS_RTOL)
		return container:GetData()
	end
	local defaultValue = 0
	local setting = Settings.RegisterAddOnSetting(category, appName .. "_" .. variable, variable, ProfessionShoppingList_Settings, Settings.VarType.Number, name, 0)
	Settings.CreateDropdown(category, setting, GetOptions, tooltip)
	setting:SetValueChangedCallback(function()
		if ProfessionShoppingList_Settings["backpackLoot"] == 1 then
			C_Container.SetInsertItemsLeftToRight(true)
		elseif ProfessionShoppingList_Settings["backpackLoot"] == 2 then
			C_Container.SetInsertItemsLeftToRight(false)
		end
	end)

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.SETTINGS_HEADER_OTHERTWEAKS))

	local variable, name, tooltip = "vendorAll", L.SETTINGS_VENDORFILTER_TITLE, L.SETTINGS_VENDORFILTER_TOOLTIP
	local setting = Settings.RegisterAddOnSetting(category, appName .. "_" .. variable, variable, ProfessionShoppingList_Settings, Settings.VarType.Boolean, name, true)
	Settings.CreateCheckbox(category, setting, tooltip)

	local variable, name, tooltip = "catalystButton", L.SETTINGS_CATALYSTBUTTON_TITLE, L.SETTINGS_CATALYSTBUTTON_TOOLTIP
	local setting = Settings.RegisterAddOnSetting(category, appName .. "_" .. variable, variable, ProfessionShoppingList_Settings, Settings.VarType.Boolean, name, true)
	Settings.CreateCheckbox(category, setting, tooltip)

	local variable, name, tooltip = "queueSound", L.SETTINGS_QUEUESOUND_TITLE, L.SETTINGS_QUEUESOUND_TOOLTIP
	local setting = Settings.RegisterAddOnSetting(category, appName .. "_" .. variable, variable, ProfessionShoppingList_Settings, Settings.VarType.Boolean, name, false)
	Settings.CreateCheckbox(category, setting, tooltip)

	local variable, name, tooltip = "handyNotes", L.SETTINGS_HANDYNOTESFIX_TITLE, L.SETTINGS_HANDYNOTESFIX_TOOLTIP
	local setting = Settings.RegisterAddOnSetting(category, appName .. "_" .. variable, variable, ProfessionShoppingList_Settings, Settings.VarType.Boolean, name, true)
	Settings.CreateCheckbox(category, setting, tooltip)

	local variable, name, tooltip = "underminePrices", L.SETTINGS_ORIBOSEXCHANGEFIX_TITLE, L.SETTINGS_ORIBOSEXCHANGEFIX_TOOLTIP
	local setting = Settings.RegisterAddOnSetting(category, appName .. "_" .. variable, variable, ProfessionShoppingList_Settings, Settings.VarType.Boolean, name, true)
	Settings.CreateCheckbox(category, setting, tooltip)
	setting:SetValueChangedCallback(function()
		app.HideOribos()
	end)

	local variable, name, tooltip = "qualityAssurance", L.SETTINGS_QA_TITLE, L.SETTINGS_QA_TOOLTIP
	local setting = Settings.RegisterAddOnSetting(category, appName .. "_" .. variable, variable, ProfessionShoppingList_Settings, Settings.VarType.Boolean, name, true)
	Settings.CreateCheckbox(category, setting, tooltip)
	setting:SetValueChangedCallback(function()
		app.HideFrameSettings()
	end)
end