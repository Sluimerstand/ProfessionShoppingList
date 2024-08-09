------------------------------------------
-- Profession Shopping List: Tweaks.lua --
------------------------------------------
-- Tweaks module

-- Initialisation
local appName, app = ...	-- Returns the AddOn name and a unique table

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
event:RegisterEvent("LFG_PROPOSAL_SHOW")
event:RegisterEvent("MERCHANT_SHOW")
event:RegisterEvent("PET_BATTLE_QUEUE_PROPOSE_MATCH")
event:RegisterEvent("PLAYER_ENTERING_WORLD")

------------------
-- INITIAL LOAD --
------------------

-- Create default user settings
function app.InitialiseTweaks()
	-- Backpack
	if ProfessionShoppingList_Settings["backpackCount"] == nil then ProfessionShoppingList_Settings["backpackCount"] = true end
	if ProfessionShoppingList_Settings["backpackCleanup"] == nil then ProfessionShoppingList_Settings["backpackCleanup"] = 0 end
	if ProfessionShoppingList_Settings["backpackLoot"] == nil then ProfessionShoppingList_Settings["backpackLoot"] = 0 end
	-- Other Tweaks
	if ProfessionShoppingList_Settings["vendorAll"] == nil then ProfessionShoppingList_Settings["vendorAll"] = true end
	if ProfessionShoppingList_Settings["queueSound"] == nil then ProfessionShoppingList_Settings["queueSound"] = false end
	if ProfessionShoppingList_Settings["underminePrices"] == nil then ProfessionShoppingList_Settings["underminePrices"] = false end
	if ProfessionShoppingList_Settings["handyNotes"] == nil then ProfessionShoppingList_Settings["handyNotes"] = false end
end

-- When the AddOn is fully loaded, actually run the components
function event:ADDON_LOADED(addOnName, containsBindings)
	if addOnName == appName then
		app.InitialiseTweaks()
		app.UnderminePrices()
		app.HideOribos()
		app.DisableHandyNotesAltRMB()
		app.SettingsTweaks()
	end
end

----------------------
-- BACKPACK SORTING --
----------------------

function event:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
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
end

-----------------
-- QUEUE SOUND --
-----------------

-- Play the DBM-style queue sound
function app.QueueSound()
	-- If the setting is enabled
	if ProfessionShoppingList_Settings["queueSound"] == true then
		PlaySoundFile(567478, "Master")
	end
end

-- When a LFG queue pops
function event:LFG_PROPOSAL_SHOW()
	app.QueueSound()
end

-- When a pet battle queue pops
function event:PET_BATTLE_QUEUE_PROPOSE_MATCH()
	app.QueueSound()
end

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
	if ProfessionShoppingList_Settings["vendorAll"] == true then
		RunNextFrame(function()
			SetMerchantFilter(1)
			MerchantFrame_Update()
		end)
	end
end

-- When a vendor window is opened
function event:MERCHANT_SHOW()
	app.MerchantFilter()
end

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
		if ProfessionShoppingList_Settings["underminePrices"] == true then
			-- If Oribos Exchange is loaded
			local loaded, finished = C_AddOns.IsAddOnLoaded("OribosExchange")
			if finished == true then
				-- Grab the pricing information
				local marketPrice = 0
				local regionPrice = 0

				-- Check both links for pricing data
				local oeData = {}
				OEMarketInfo(itemLink,oeData)
				if oeData['market'] == nil and oeData['region'] == nil then
					-- Unless the item is BoP (BoP recipes for example)
					local bindType = select(14, C_Item.GetItemInfo(itemID))
					if bindType ~= 1 then
						OEMarketInfo(unreliableItemLink,oeData)
					end
				end
				
				if oeData['market'] ~= nil then
					marketPrice = oeData['market']
				end
				if oeData['region'] ~= nil then
					regionPrice = oeData['region']
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
						tooltip:AddDoubleLine(GetCurrentRegionName().." Region",GetMoneyString(regionPrice, true))
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
	if ProfessionShoppingList_Settings["underminePrices"] == true then
		-- If Oribos Exchange is loaded
		local loaded, finished = C_AddOns.IsAddOnLoaded("OribosExchange")
		if finished == true then
			local speciesID1, level, breedQuality, maxHealth, power, speed, bracketName = ...

			-- Make itemLink if it grabs the proper pet
			local itemLink = "|cff0070dd|Hbattlepet:"..speciesID1..":"..level..":"..breedQuality..":"..maxHealth..":"..power..":"..speed.."|h"..bracketName.."|h|r"

			-- Stop if error, it will try again on its own REAL soon
			if itemLink == nil then return end

			-- Grab pricing information
			local oeData = {}
			OEMarketInfo(itemLink,oeData)
			local marketPrice = 0
			local regionPrice = 0

			if oeData['market'] ~= nil then
				marketPrice = oeData['market']
			end
			if oeData['region'] ~= nil then
				regionPrice = oeData['region']
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
					LibBattlePetTooltipLine:AddDoubleLine(BattlePetTooltip, GetCurrentRegionName().." Region", GetMoneyString(regionPrice, true))
				end
			end
		end
	end
end)

function app.HideOribos()
	-- Only run this if the setting is enabled
	if ProfessionShoppingList_Settings["underminePrices"] == true then
		-- If Oribos Exchange is loaded
		local loaded, finished = C_AddOns.IsAddOnLoaded("OribosExchange")
		if finished == true then
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
					C_Timer.After(1, function() RunNextFrame(removeMessage) end)
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
	if ProfessionShoppingList_Settings["handyNotes"] == true then
		-- Thank you for this code, Numy, this saves me a lot of frustration
		if C_AddOns.IsAddOnLoaded("HandyNotes") and LibStub("AceAddon-3.0"):GetAddon("HandyNotes") then
			local f = LibStub("AceAddon-3.0"):GetAddon("HandyNotes"):GetModule("HandyNotes").ClickHandlerFrame
			local f2 = CreateFrame("Frame")
			f:SetParent(f2)
			f2:Hide()
		end
	end
end

--------------
-- SETTINGS --
--------------

function app.SettingsTweaks()
	local category, layout = Settings.RegisterVerticalLayoutSubcategory(app.Category, "Tweaks")
	Settings.RegisterAddOnCategory(category)

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(BAG_NAME_BACKPACK))

	local variable, name, tooltip = "backpackCount", "Split reagent bag count", "Shows the free slots of your regular bags and your reagent bag separately on top of the backpack icon."
	local setting = Settings.RegisterAddOnSetting(category, appName.."_"..variable, variable, ProfessionShoppingList_Settings, Settings.VarType.Boolean, name)
	Settings.CreateCheckbox(category, setting, tooltip)
	Settings.SetOnValueChangedCallback(variable, app.SettingChanged)
	Settings.SetOnValueChangedCallback(variable, function()
		-- Get number of free bag slots
		local freeSlots1 = C_Container.GetContainerNumFreeSlots(0) + C_Container.GetContainerNumFreeSlots(1) + C_Container.GetContainerNumFreeSlots(2) + C_Container.GetContainerNumFreeSlots(3) + C_Container.GetContainerNumFreeSlots(4)
		local freeSlots2 = C_Container.GetContainerNumFreeSlots(5)

		-- If the setting for split reagent bag count is enabled and the player has a reagent bag
		if ProfessionShoppingList_Settings["backpackCount"] == true and C_Container.GetContainerNumSlots(5) ~= 0 then
			print("true")
			-- Replace the bag count text
			MainMenuBarBackpackButtonCount:SetText("(" .. freeSlots1 .. "+" .. freeSlots2 .. ")")
		else
			print("false")
			-- Reset the bag count text
			MainMenuBarBackpackButtonCount:SetText("(" .. freeSlots1 + freeSlots2 .. ")")
		end
	end)

	local variable, name, tooltip = "backpackCleanup", "Clean up bags", "Let ".. app.NameShort.." enforce cleanup sorting direction.\n- Default means "..app.NameShort.." won't touch the game's default behaviour;\n- The other options let "..app.NameShort.." enforce that particular setting."
	local function GetOptions()
		local container = Settings.CreateControlTextContainer()
		container:Add(0, "Default")
		container:Add(1, "Left-to-Right")
		container:Add(2, "Right-to-Left")
		return container:GetData()
	end
	local defaultValue = 0
	local setting = Settings.RegisterAddOnSetting(category, appName.."_"..variable, variable, ProfessionShoppingList_Settings, Settings.VarType.Number, name)
	Settings.CreateDropdown(category, setting, GetOptions, tooltip)
	Settings.SetOnValueChangedCallback(variable, app.SettingChanged)
	Settings.SetOnValueChangedCallback(variable, function()
		if ProfessionShoppingList_Settings["backpackCleanup"] == 1 then
			C_Container.SetSortBagsRightToLeft(false)
		elseif ProfessionShoppingList_Settings["backpackCleanup"] == 2 then
			C_Container.SetSortBagsRightToLeft(true)
		end
		
	end)

	local variable, name, tooltip = "backpackLoot", "Loot order", "Let ".. app.NameShort.." enforce loot sorting direction.\n- Default means "..app.NameShort.." won't touch the game's default behaviour;\n- The other options let "..app.NameShort.." enforce that particular setting."
	local function GetOptions()
		local container = Settings.CreateControlTextContainer()
		container:Add(0, "Default")
		container:Add(1, "Left-to-Right")
		container:Add(2, "Right-to-Left")
		return container:GetData()
	end
	local defaultValue = 0
	local setting = Settings.RegisterAddOnSetting(category, appName.."_"..variable, variable, ProfessionShoppingList_Settings, Settings.VarType.Number, name)
	Settings.CreateDropdown(category, setting, GetOptions, tooltip)
	Settings.SetOnValueChangedCallback(variable, app.SettingChanged)
	Settings.SetOnValueChangedCallback(variable, function()
		if ProfessionShoppingList_Settings["backpackLoot"] == 1 then
			C_Container.SetInsertItemsLeftToRight(true)
		elseif ProfessionShoppingList_Settings["backpackLoot"] == 2 then
			C_Container.SetInsertItemsLeftToRight(false)
		end
	end)

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Other Tweaks"))

	local variable, name, tooltip = "vendorAll", "Disable vendor filter", "Automatically set all vendor filters to |cffFFFFFFAll|R to display items normally not shown to your class."
	local setting = Settings.RegisterAddOnSetting(category, appName.."_"..variable, variable, ProfessionShoppingList_Settings, Settings.VarType.Boolean, name)
	Settings.CreateCheckbox(category, setting, tooltip)
	Settings.SetOnValueChangedCallback(variable, app.SettingChanged)

	local variable, name, tooltip = "queueSound", "Play queue sound", "Play the Deadly Boss Mods style queue sound when any queue pops, including battlegrounds and pet battles."
	local setting = Settings.RegisterAddOnSetting(category, appName.."_"..variable, variable, ProfessionShoppingList_Settings, Settings.VarType.Boolean, name)
	Settings.CreateCheckbox(category, setting, tooltip)
	Settings.SetOnValueChangedCallback(variable, app.SettingChanged)

	local variable, name, tooltip = "underminePrices", "Fix Oribos Exchange tooltip", "Let "..app.NameShort.." simplify and fix the tooltip provided by the Oribos Exchange AddOn:\n- Round to the nearest gold;\n- Fix recipe prices;\n- Fix profession window prices;\n- Show battle pet prices inside the existing tooltip."
	local setting = Settings.RegisterAddOnSetting(category, appName.."_"..variable, variable, ProfessionShoppingList_Settings, Settings.VarType.Boolean, name)
	Settings.CreateCheckbox(category, setting, tooltip)
	Settings.SetOnValueChangedCallback(variable, app.SettingChanged)
	Settings.SetOnValueChangedCallback(variable, function()
		app.HideOribos()
	end)

	local variable, name, tooltip = "handyNotes", "Disable HandyNotes Alt+RMB", "Let "..app.NameShort.." disable this keybind on the map, re-enabling it for TomTom waypoints instead.\n\n|cffFF0000"..REQUIRES_RELOAD
	local setting = Settings.RegisterAddOnSetting(category, appName.."_"..variable, variable, ProfessionShoppingList_Settings, Settings.VarType.Boolean, name)
	Settings.CreateCheckbox(category, setting, tooltip)
	Settings.SetOnValueChangedCallback(variable, app.SettingChanged)
end