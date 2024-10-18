--------------------------------------------------
-- Profession Shopping List: CraftingOrders.lua --
--------------------------------------------------
-- Crafting Orders module

-- Initialisation
local appName, app =  ...	-- Returns the AddOn name and a unique table
local L = app.locales

------------------
-- INITIAL LOAD --
------------------

-- Create SavedVariables, default user settings, and session variables
function app.InitialiseCraftingOrders()
	-- Enable default user settings
	if ProfessionShoppingList_Settings["useLocalReagents"] == nil then ProfessionShoppingList_Settings["useLocalReagents"] = false end

	-- Initialise some session variables
	app.Flag["craftingOrderAssets"] = false
	app.Flag["quickOrder"] = 0
	app.RepeatQuickOrderTooltip = {}
	app.QuickOrderRecipeID = 0
	app.QuickOrderAttempts = 0
	app.QuickOrderErrors = 0
end

-- When the AddOn is fully loaded, actually run the components
app.Event:Register("ADDON_LOADED", function(addOnName, containsBindings)
	if addOnName == appName then
		app.InitialiseCraftingOrders()
	end
end)

------------
-- ASSETS --
------------

-- Create buttons for the Crafting Orders window
function app.CreateCraftingOrdersAssets()
	-- Hide and disable existing tracking buttons
	ProfessionsCustomerOrdersFrame.Form.TrackRecipeCheckbox:SetAlpha(0)
	ProfessionsCustomerOrdersFrame.Form.TrackRecipeCheckbox.Checkbox:EnableMouse(false)

	-- Create the place crafting orders UI Track button
	if not app.TrackPlaceOrderButton then
		app.TrackPlaceOrderButton = app.Button(ProfessionsCustomerOrdersFrame.Form, L.TRACK)
		app.TrackPlaceOrderButton:SetPoint("TOPLEFT", ProfessionsCustomerOrdersFrame.Form, "TOPLEFT", 12, -73)
		app.TrackPlaceOrderButton:SetScript("OnClick", function()
			app.TrackRecipe(app.SelectedRecipe.PlaceOrder.recipeID, 1, app.SelectedRecipe.PlaceOrder.recraft)
		end)
	end

	-- Create the place crafting orders UI untrack button
	if not app.UntrackPlaceOrderButton then
		app.UntrackPlaceOrderButton = app.Button(ProfessionsCustomerOrdersFrame.Form, L.UNTRACK)
		app.UntrackPlaceOrderButton:SetPoint("TOPLEFT", app.TrackPlaceOrderButton, "TOPRIGHT", 2, 0)
		app.UntrackPlaceOrderButton:SetScript("OnClick", function()
			app.UntrackRecipe(app.SelectedRecipe.PlaceOrder.recipeID, 1)
	
			-- Show windows
			app.Show()
		end)
	end

	-- Create a frame overlay for hover detection
	local overlayFrame1 = CreateFrame("Frame", nil, app.TrackPlaceOrderButton)
	overlayFrame1:SetAllPoints(app.TrackPlaceOrderButton)
	overlayFrame1:EnableMouse(true)
	overlayFrame1:SetPropagateMouseClicks(true)
	overlayFrame1:SetPropagateMouseMotion(true)
	overlayFrame1:SetScript("OnEnter", function(self)
		if app.SelectedRecipe.PlaceOrder.recipeID == 0 then
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
			GameTooltip:SetText(L.RECRAFT_TOOLTIP)
			GameTooltip:Show()
		end
	end)
	overlayFrame1:SetScript("OnLeave", function()
		if app.SelectedRecipe.PlaceOrder.recipeID == 0 then
			GameTooltip:Hide()
		end
	end)

	-- Create the place crafting orders UI personal order name field
	if not app.QuickOrderTargetBox then
		app.QuickOrderTargetBox = CreateFrame("EditBox", nil, ProfessionsCustomerOrdersFrame.Form, "InputBoxTemplate")
		app.QuickOrderTargetBox:SetSize(80,20)
		app.QuickOrderTargetBox:SetPoint("CENTER", app.TrackPlaceOrderButton, "CENTER", 0, 0)
		app.QuickOrderTargetBox:SetPoint("LEFT", app.TrackPlaceOrderButton, "LEFT", 415, 0)
		app.QuickOrderTargetBox:SetAutoFocus(false)
		app.QuickOrderTargetBox:SetCursorPosition(0)
		app.QuickOrderTargetBox:SetScript("OnEditFocusLost", function(self)
			ProfessionShoppingList_CharacterData.Orders[app.SelectedRecipe.PlaceOrder.recipeID] = tostring(app.QuickOrderTargetBox:GetText())
			app.UpdateAssets()
		end)
		app.QuickOrderTargetBox:SetScript("OnEnterPressed", function(self)
			ProfessionShoppingList_CharacterData.Orders[app.SelectedRecipe.PlaceOrder.recipeID] = tostring(app.QuickOrderTargetBox:GetText())
			self:ClearFocus()
			app.UpdateAssets()
		end)
		app.QuickOrderTargetBox:SetScript("OnEscapePressed", function(self)
			app.UpdateAssets()
		end)
		app.Border(app.QuickOrderTargetBox, -6, 1, 2, -2)
	end

	local function quickOrder(recipeID)
		-- Create crafting info variables
		app.QuickOrderRecipeID = recipeID
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
					if ProfessionShoppingList_Cache.ReagentTiers[reagentID].three ~= 0 then
						-- Set it to the lowest quality we have enough of for this order
						if C_Item.GetItemCount(ProfessionShoppingList_Cache.ReagentTiers[reagentID].one, true, false, true, true) >= quantityNo then
							craftingReagentInfo[no1] = {itemID = ProfessionShoppingList_Cache.ReagentTiers[reagentID].one, dataSlotIndex = i, quantity = quantityNo}
							no1 = no1 + 1
						elseif C_Item.GetItemCount(ProfessionShoppingList_Cache.ReagentTiers[reagentID].two, true, false, true, true) >= quantityNo then
							craftingReagentInfo[no1] = {itemID = ProfessionShoppingList_Cache.ReagentTiers[reagentID].two, dataSlotIndex = i, quantity = quantityNo}
							no1 = no1 + 1
						elseif C_Item.GetItemCount(ProfessionShoppingList_Cache.ReagentTiers[reagentID].three, true, false, true, true) >= quantityNo then
							craftingReagentInfo[no1] = {itemID = ProfessionShoppingList_Cache.ReagentTiers[reagentID].three, dataSlotIndex = i, quantity = quantityNo}
							no1 = no1 + 1
						end
					-- Add the info for non-tiered reagents to reagentItems
					else
						if C_Item.GetItemCount(reagentID, true, false, true, true) >= quantityNo then
							reagentInfo[no2] = {itemID = ProfessionShoppingList_Cache.ReagentTiers[reagentID].one, quantity = quantityNo}
							no2 = no2 + 1
						end
					end
				end
			end
		end

		-- Only add the reagentInfo if the option is enabled
		if ProfessionShoppingList_Settings["useLocalReagents"] == true then localReagentsOrder() end

		-- Signal that PSL is currently working on a quick order with tiered local reagents, if applicable
		local next = next
		if next(craftingReagentInfo) ~= nil and ProfessionShoppingList_Settings["useLocalReagents"] == true then
			app.Flag["quickOrder"] = 2
		end

		-- Place a guild order if the recipient is "GUILD"
		local typeOrder = 2
		if ProfessionShoppingList_CharacterData.Orders[recipeID] == "GUILD" then
			typeOrder = 1
		end

		-- Place the order
		C_CraftingOrders.PlaceNewOrder({ skillLineAbilityID=ProfessionShoppingList_Library[recipeID].abilityID, orderType=typeOrder, orderDuration=ProfessionShoppingList_Settings["quickOrderDuration"], tipAmount=100, customerNotes="", orderTarget=ProfessionShoppingList_CharacterData.Orders[recipeID], reagentItems=reagentInfo, craftingReagentItems=craftingReagentInfo })
		
		-- If there are tiered reagents and the user wants to use local reagents, adjust the dataSlotIndex and try again in case the first one failed
		local next = next
		if next(craftingReagentInfo) ~= nil and ProfessionShoppingList_Settings["useLocalReagents"] == true then
			for i, _ in ipairs(craftingReagentInfo) do
				craftingReagentInfo[i].dataSlotIndex = math.max(craftingReagentInfo[i].dataSlotIndex - 1, 0)
			end

			-- Place the alternative order (only one can succeed, worst case scenario it'll fail again)
			C_CraftingOrders.PlaceNewOrder({ skillLineAbilityID=ProfessionShoppingList_Library[recipeID].abilityID, orderType=typeOrder, orderDuration=ProfessionShoppingList_Settings["quickOrderDuration"], tipAmount=100, customerNotes="", orderTarget=ProfessionShoppingList_CharacterData.Orders[recipeID], reagentItems=reagentInfo, craftingReagentItems=craftingReagentInfo })
		
			for i, _ in ipairs(craftingReagentInfo) do
				craftingReagentInfo[i].dataSlotIndex = math.max(craftingReagentInfo[i].dataSlotIndex - 1, 0)
			end

			-- Place the alternative order (only one can succeed, worst case scenario it'll fail again)
			C_CraftingOrders.PlaceNewOrder({ skillLineAbilityID=ProfessionShoppingList_Library[recipeID].abilityID, orderType=typeOrder, orderDuration=ProfessionShoppingList_Settings["quickOrderDuration"], tipAmount=100, customerNotes="", orderTarget=ProfessionShoppingList_CharacterData.Orders[recipeID], reagentItems=reagentInfo, craftingReagentItems=craftingReagentInfo })
		
			for i, _ in ipairs(craftingReagentInfo) do
				craftingReagentInfo[i].dataSlotIndex = math.max(craftingReagentInfo[i].dataSlotIndex - 1, 0)
			end

			-- Place the alternative order (only one can succeed, worst case scenario it'll fail again)
			C_CraftingOrders.PlaceNewOrder({ skillLineAbilityID=ProfessionShoppingList_Library[recipeID].abilityID, orderType=typeOrder, orderDuration=ProfessionShoppingList_Settings["quickOrderDuration"], tipAmount=100, customerNotes="", orderTarget=ProfessionShoppingList_CharacterData.Orders[recipeID], reagentItems=reagentInfo, craftingReagentItems=craftingReagentInfo })
		end
	end

	-- Create the place crafting orders personal order button
	if not app.QuickOrderButton then
		app.QuickOrderButton = app.Button(ProfessionsCustomerOrdersFrame.Form, L.QUICKORDER)
		app.QuickOrderButton:SetPoint("CENTER", app.QuickOrderTargetBox, "CENTER", 0, 0)
		app.QuickOrderButton:SetPoint("RIGHT", app.QuickOrderTargetBox, "LEFT", -8, 0)
		app.QuickOrderButton:SetScript("OnClick", function()
			quickOrder(app.SelectedRecipe.PlaceOrder.recipeID)
		end)
	end

	-- Create a frame overlay for hover detection
	local overlayFrame2 = CreateFrame("Frame", nil, app.QuickOrderButton)
	overlayFrame2:SetAllPoints(app.QuickOrderButton)
	overlayFrame2:EnableMouse(true)
	overlayFrame2:SetPropagateMouseClicks(true)
	overlayFrame2:SetPropagateMouseMotion(true)
	overlayFrame2:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:SetText(L.QUICKORDER_TOOLTIP)
		GameTooltip:Show()
	end)
	overlayFrame2:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-- Create the local reagents checkbox
	if not app.LocalReagentsCheckbox then
		-- Temporary checkbox until Blizz fixes their shit
		app.LocalReagentsCheckbox = CreateFrame("CheckButton", nil, ProfessionsCustomerOrdersFrame.Form, "ChatConfigCheckButtonTemplate")
		app.LocalReagentsCheckbox:SetPoint("BOTTOMLEFT", app.QuickOrderButton, "TOPLEFT", 0, 0)
		app.LocalReagentsCheckbox.Text:SetText(L.LOCALREAGENTS_LABEL)
		app.LocalReagentsCheckbox.tooltip = L.LOCALREAGENTS_TOOLTIP
		app.LocalReagentsCheckbox:SetScript("OnClick", function(self)
			ProfessionShoppingList_Settings["useLocalReagents"] = self:GetChecked()

			if ProfessionShoppingList_CharacterData.Orders["last"] ~= nil and ProfessionShoppingList_CharacterData.Orders["last"] ~= 0 then
				app.RepeatQuickOrderTooltip.Reagents = L.FALSE
				if ProfessionShoppingList_Settings["useLocalReagents"] == true then
					app.RepeatQuickOrderTooltip.Reagents = L.TRUE
				end
			end
		end)
	end

	-- Create the repeat last crafting order button
	if not app.RepeatQuickOrderButton then
		app.RepeatQuickOrderButton = app.Button(ProfessionsCustomerOrdersFrame, "")
		app.RepeatQuickOrderButton:SetPoint("BOTTOMLEFT", ProfessionsCustomerOrdersFrame, 170, 5)
		app.RepeatQuickOrderButton:SetScript("OnClick", function()
			if ProfessionShoppingList_CharacterData.Orders["last"] ~= nil and ProfessionShoppingList_CharacterData.Orders["last"] ~= 0 then
				quickOrder(ProfessionShoppingList_CharacterData.Orders["last"])
				ProfessionsCustomerOrdersFrame.MyOrdersPage:RefreshOrders()
			else
				app.Print("No last Quick Order found.")
			end
		end)
		app.RepeatQuickOrderButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
			GameTooltip:SetText(app.RepeatQuickOrderTooltip.Text)
			GameTooltip:Show()
		end)
		app.RepeatQuickOrderButton:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

		-- Set the last used recipe name for the repeat order button title
		local recipeName = L.NOLASTORDER
		-- Check for the name if there has been a last order
		if ProfessionShoppingList_CharacterData.Orders["last"] ~= nil and ProfessionShoppingList_CharacterData.Orders["last"] ~= 0 then
			recipeName = C_TradeSkillUI.GetRecipeSchematic(ProfessionShoppingList_CharacterData.Orders["last"], false).name
		end
		app.RepeatQuickOrderButton:SetText(recipeName)
		app.RepeatQuickOrderButton:SetWidth(app.RepeatQuickOrderButton:GetTextWidth()+20)
	end

	-- Create the repeat last crafting order button text
	app.RepeatQuickOrderTooltip.Text = L.QUICKORDER_REPEAT_TOOLTIP

	if ProfessionShoppingList_CharacterData.Orders["last"] ~= nil and ProfessionShoppingList_CharacterData.Orders["last"] ~= 0 then
		app.RepeatQuickOrderTooltip.Reagents = L.FALSE
		if ProfessionShoppingList_Settings["useLocalReagents"] == true then
			app.RepeatQuickOrderTooltip.Reagents = L.TRUE
		end
		app.RepeatQuickOrderTooltip.Text = L.QUICKORDER_REPEAT_TOOLTIP .. "\n" .. L.RECIPIENT  .. ": " .. ProfessionShoppingList_CharacterData.Orders[ProfessionShoppingList_CharacterData.Orders["last"]] .. "\n" .. L.LOCALREAGENTS_LABEL .. ": " .. app.RepeatQuickOrderTooltip.Reagents
	end

	-- Set the flag for assets created to true
	app.Flag["craftingOrderAssets"] = true
end

---------------------
-- CRAFTING ORDERS --
---------------------

-- When opening the crafting orders window
app.Event:Register("CRAFTINGORDERS_SHOW_CUSTOMER", function()
	app.CreateCraftingOrdersAssets()
end)

-- When opening a recipe in the crafting orders window
EventRegistry:RegisterCallback("ProfessionsCustomerOrders.RecipeSelected", function(_, itemID, recipeID, abilityID)
	app.RegisterRecipe(recipeID)
	app.SelectedRecipe.PlaceOrder = { recipeID = recipeID, recraft = false, recipeType = C_TradeSkillUI.GetRecipeSchematic(recipeID,false).recipeType }
	app.UpdateAssets()
end)

-- When opening the recrafting category in the crafting orders window
EventRegistry:RegisterCallback("ProfessionsCustomerOrders.RecraftCategorySelected", function()
	app.SelectedRecipe.PlaceOrder = { recipeID = 0, recraft = true, recipeType = 0 }
	app.UpdateAssets()
end)

-- When a recipe is selected (or rather, when any spell is loaded, but this is the only way to grab the recipeID for placing a recrafting order)
app.Event:Register("SPELL_DATA_LOAD_RESULT", function(spellID, success)
	if not UnitAffectingCombat("player") and app.SelectedRecipe.PlaceOrder.recraft and ProfessionShoppingList_Library[spellID] then
		app.SelectedRecipe.PlaceOrder.recipeID = spellID
		app.UpdateAssets()
	end
end)

-- When closing the crafting orders window
app.Event:Register("CRAFTINGORDERS_HIDE_CUSTOMER", function()
	app.SelectedRecipe.PlaceOrder = { recipeID = 0, recraft = false, recipeType = 0 }
end)

-- When fulfilling an order
app.Event:Register("CRAFTINGORDERS_FULFILL_ORDER_RESPONSE", function(result, orderID)
	if ProfessionShoppingList_Settings["removeCraft"] == true then
		for k, v in pairs (ProfessionShoppingList_Data.Recipes) do
			if tonumber(string.match(k, ":(%d+):")) == orderID then
				-- Remove 1 tracked recipe when it has been crafted (if the option is enabled)
				app.UntrackRecipe(k, 1)
				break
			end
		end

		-- Close window if no recipes are left and the option is enabled
		local next = next
		if next(ProfessionShoppingList_Data.Recipes) == nil and ProfessionShoppingList_Settings["closeWhenDone"] then
			app.Window:Hide()
		end
	end
end)

------------------
-- QUICK ORDERS --
------------------

-- If placing a crafting order through PSL
app.Event:Register("CRAFTINGORDERS_ORDER_PLACEMENT_RESPONSE", function(result)
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
				app.Print(L.ERROR_QUICKORDER)
			end
		end
		-- Separate error messages
		if result == 29 then
			app.Print(L.ERROR_REAGENTS)
		elseif result == 34 then
			app.Print(L.ERROR_WARBANK)
		elseif result == 37 then
			app.Print(L.ERROR_GUILD)
		elseif result == 40 then
			app.Print(L.ERROR_RECIPIENT)
		end

		-- Save this info as the last order done, unless it was a failed order
		if (result ~= 29 and result ~= 34 and result ~= 37 and result ~= 40) or app.QuickOrderErrors >= 4 then ProfessionShoppingList_CharacterData.Orders["last"] = app.QuickOrderRecipeID end

		-- Set the last used recipe name for the repeat order button title
		local recipeName = L.NOLASTORDER
		-- Check for the name if there has been a last order
		if ProfessionShoppingList_CharacterData.Orders["last"] ~= nil and ProfessionShoppingList_CharacterData.Orders["last"] ~= 0 then
			app.RepeatQuickOrderTooltip.Reagents = L.FALSE
			if ProfessionShoppingList_Settings["useLocalReagents"] == true then
				app.RepeatQuickOrderTooltip.Reagents = L.TRUE
			end
			app.RepeatQuickOrderTooltip.Text = L.QUICKORDER_REPEAT_TOOLTIP .. "\n" .. L.RECIPIENT  .. ": " .. ProfessionShoppingList_CharacterData.Orders[ProfessionShoppingList_CharacterData.Orders["last"]] .. "\n" .. L.LOCALREAGENTS_LABEL .. ": " .. app.RepeatQuickOrderTooltip.Reagents
		end
		app.RepeatQuickOrderButton:SetText(recipeName)
		app.RepeatQuickOrderButton:SetWidth(app.RepeatQuickOrderButton:GetTextWidth()+20)

		-- Reset all the numbers if we're done
		if (app.Flag["quickOrder"] == 1 and app.QuickOrderAttempts >= 1) or (app.Flag["quickOrder"] == 2 and app.QuickOrderAttempts >= 4) then
			app.Flag["quickOrder"] = 0
			app.QuickOrderAttempts = 0
			app.QuickOrderErrors = 0
		end
	end
end)