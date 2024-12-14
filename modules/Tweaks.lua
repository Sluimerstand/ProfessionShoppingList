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
end