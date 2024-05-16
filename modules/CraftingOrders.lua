--------------------------------------------------
-- Profession Shopping List: CraftingOrders.lua --
--------------------------------------------------
-- Crafting Orders module

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
event:RegisterEvent("CRAFTINGORDERS_CLAIM_ORDER_RESPONSE")
event:RegisterEvent("CRAFTINGORDERS_FULFILL_ORDER_RESPONSE")
event:RegisterEvent("CRAFTINGORDERS_HIDE_CUSTOMER")
event:RegisterEvent("CRAFTINGORDERS_ORDER_PLACEMENT_RESPONSE")
event:RegisterEvent("CRAFTINGORDERS_RELEASE_ORDER_RESPONSE")
event:RegisterEvent("CRAFTINGORDERS_SHOW_CUSTOMER")

------------------
-- INITIAL LOAD --
------------------

-- Create SavedVariables, default user settings, and session variables
function app.InitialiseCraftingOrders()
	-- Enable default user settings
	if ProfessionShoppingList_Settings["useLocalReagents"] == nil then ProfessionShoppingList_Settings["useLocalReagents"] = false end
	if ProfessionShoppingList_Settings["quickOrderDuration"] == nil then ProfessionShoppingList_Settings["quickOrderDuration"] = 0 end

	-- Initialise some session variables
	app.Flag["craftingOrderAssets"] = false
	app.Flag["quickOrder"] = 0
	app.OrderRecipeID = 0
	app.QuickOrderAttempts = 0
	app.QuickOrderErrors = 0
end

-- Create buttons for the Crafting Orders window
function app.CreateCraftingOrdersAssets()
	-- Hide and disable existing tracking buttons
	ProfessionsCustomerOrdersFrame.Form.TrackRecipeCheckBox:SetAlpha(0)
	ProfessionsCustomerOrdersFrame.Form.TrackRecipeCheckBox:EnableMouse(false)

	-- Create the place crafting orders UI Track button
	if not trackPlaceOrderButton then
		trackPlaceOrderButton = app.Button(ProfessionsCustomerOrdersFrame.Form, "Track")
		trackPlaceOrderButton:SetPoint("TOPLEFT", ProfessionsCustomerOrdersFrame.Form, "TOPLEFT", 12, -73)
		trackPlaceOrderButton:SetScript("OnClick", function()
			app.TrackRecipe(app.SelectedRecipeID, 1)
		end)
	end

	-- Create the place crafting orders UI untrack button
	if not untrackPlaceOrderButton then
		untrackPlaceOrderButton = app.Button(ProfessionsCustomerOrdersFrame.Form, "Untrack")
		untrackPlaceOrderButton:SetPoint("TOPLEFT", trackPlaceOrderButton, "TOPRIGHT", 2, 0)
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
			ProfessionShoppingList_CharacterData.Orders[app.SelectedRecipeID] = tostring(personalCharname:GetText())
			app.UpdateAssets()
		end)
		personalCharname:SetScript("OnEnterPressed", function(self)
			ProfessionShoppingList_CharacterData.Orders[app.SelectedRecipeID] = tostring(personalCharname:GetText())
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
		app.Border(personalCharname, -6, 1, 2, -2)
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
					if ProfessionShoppingList_Cache.ReagentTiers[reagentID].three ~= 0 then
						-- Set it to the lowest quality we have enough of for this order
						if C_Item.GetItemCount(ProfessionShoppingList_Cache.ReagentTiers[reagentID].one, true, false, true) >= quantityNo then
							craftingReagentInfo[no1] = {itemID = ProfessionShoppingList_Cache.ReagentTiers[reagentID].one, dataSlotIndex = i, quantity = quantityNo}
							no1 = no1 + 1
						elseif C_Item.GetItemCount(ProfessionShoppingList_Cache.ReagentTiers[reagentID].two, true, false, true) >= quantityNo then
							craftingReagentInfo[no1] = {itemID = ProfessionShoppingList_Cache.ReagentTiers[reagentID].two, dataSlotIndex = i, quantity = quantityNo}
							no1 = no1 + 1
						elseif C_Item.GetItemCount(ProfessionShoppingList_Cache.ReagentTiers[reagentID].three, true, false, true) >= quantityNo then
							craftingReagentInfo[no1] = {itemID = ProfessionShoppingList_Cache.ReagentTiers[reagentID].three, dataSlotIndex = i, quantity = quantityNo}
							no1 = no1 + 1
						end
					-- Add the info for non-tiered reagents to reagentItems
					else
						if C_Item.GetItemCount(reagentID, true, false, true) >= quantityNo then
							reagentInfo[no2] = {itemID = ProfessionShoppingList_Cache.ReagentTiers[reagentID].one, quantity = quantityNo}
							no2 = no2 + 1
						end
					end
				end
			end
		end

		-- Only add the reagentInfo if the option is enabled
		if ProfessionShoppingList_Settings["useLocalReagents"] == true then localReagentsOrder() end

		-- Signal that PSL is currently working on a quick order with local reagents, if applicable
		local next = next
		if next(craftingReagentInfo) ~= nil and ProfessionShoppingList_Settings["useLocalReagents"] == true then
			app.Flag["quickOrder"] = 2
		end

		-- Place the order
		C_CraftingOrders.PlaceNewOrder({ skillLineAbilityID=ProfessionShoppingList_Library[recipeID].abilityID, orderType=2, orderDuration=ProfessionShoppingList_Settings["quickOrderDuration"], tipAmount=100, customerNotes="", orderTarget=ProfessionShoppingList_CharacterData.Orders[recipeID], reagentItems=reagentInfo, craftingReagentItems=craftingReagentInfo })
		
		-- If there are tiered reagents and the user wants to use local reagents, adjust the dataSlotIndex and try again in case the first one failed
		local next = next
		if next(craftingReagentInfo) ~= nil and ProfessionShoppingList_Settings["useLocalReagents"] == true then
			for i, _ in ipairs(craftingReagentInfo) do
				craftingReagentInfo[i].dataSlotIndex = math.max(craftingReagentInfo[i].dataSlotIndex - 1, 0)
			end

			-- Place the alternative order (only one can succeed, worst case scenario it'll fail again)
			C_CraftingOrders.PlaceNewOrder({ skillLineAbilityID=ProfessionShoppingList_Library[recipeID].abilityID, orderType=2, orderDuration=ProfessionShoppingList_Settings["quickOrderDuration"], tipAmount=100, customerNotes="", orderTarget=ProfessionShoppingList_CharacterData.Orders[recipeID], reagentItems=reagentInfo, craftingReagentItems=craftingReagentInfo })
		
			for i, _ in ipairs(craftingReagentInfo) do
				craftingReagentInfo[i].dataSlotIndex = math.max(craftingReagentInfo[i].dataSlotIndex - 1, 0)
			end

			-- Place the alternative order (only one can succeed, worst case scenario it'll fail again)
			C_CraftingOrders.PlaceNewOrder({ skillLineAbilityID=ProfessionShoppingList_Library[recipeID].abilityID, orderType=2, orderDuration=ProfessionShoppingList_Settings["quickOrderDuration"], tipAmount=100, customerNotes="", orderTarget=ProfessionShoppingList_CharacterData.Orders[recipeID], reagentItems=reagentInfo, craftingReagentItems=craftingReagentInfo })
		
			for i, _ in ipairs(craftingReagentInfo) do
				craftingReagentInfo[i].dataSlotIndex = math.max(craftingReagentInfo[i].dataSlotIndex - 1, 0)
			end

			-- Place the alternative order (only one can succeed, worst case scenario it'll fail again)
			C_CraftingOrders.PlaceNewOrder({ skillLineAbilityID=ProfessionShoppingList_Library[recipeID].abilityID, orderType=2, orderDuration=ProfessionShoppingList_Settings["quickOrderDuration"], tipAmount=100, customerNotes="", orderTarget=ProfessionShoppingList_CharacterData.Orders[recipeID], reagentItems=reagentInfo, craftingReagentItems=craftingReagentInfo })
		end
	end

	-- Create the place crafting orders personal order button
	if not personalOrderButton then
		personalOrderButton = app.Button(ProfessionsCustomerOrdersFrame.Form, "Quick Order")
		personalOrderButton:SetPoint("CENTER", personalCharname, "CENTER", 0, 0)
		personalOrderButton:SetPoint("RIGHT", personalCharname, "LEFT", -8, 0)
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
		cbUseLocalReagents:SetChecked(ProfessionShoppingList_Settings["useLocalReagents"])
		cbUseLocalReagents:SetScript("OnClick", function(self)
			ProfessionShoppingList_Settings["useLocalReagents"] = self:GetChecked()

			if ProfessionShoppingList_CharacterData.Orders["last"] ~= nil and ProfessionShoppingList_CharacterData.Orders["last"] ~= 0 then
				local reagents = "false"
				local recipient = ProfessionShoppingList_CharacterData.Orders[ProfessionShoppingList_CharacterData.Orders["last"]]
				if ProfessionShoppingList_Settings["useLocalReagents"] == true then reagents = "true" end
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
		repeatOrderButton = app.Button(ProfessionsCustomerOrdersFrame, "")
		repeatOrderButton:SetPoint("BOTTOMLEFT", ProfessionsCustomerOrdersFrame, 170, 5)
		repeatOrderButton:SetScript("OnClick", function()
			if ProfessionShoppingList_CharacterData.Orders["last"] ~= nil and ProfessionShoppingList_CharacterData.Orders["last"] ~= 0 then
				quickOrder(ProfessionShoppingList_CharacterData.Orders["last"])
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
		if ProfessionShoppingList_CharacterData.Orders["last"] ~= nil and ProfessionShoppingList_CharacterData.Orders["last"] ~= 0 then
			recipeName = C_TradeSkillUI.GetRecipeSchematic(ProfessionShoppingList_CharacterData.Orders["last"], false).name
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
		if ProfessionShoppingList_CharacterData.Orders["last"] ~= nil and ProfessionShoppingList_CharacterData.Orders["last"] ~= 0 then
			local reagents = "false"
			local recipient = ProfessionShoppingList_CharacterData.Orders[ProfessionShoppingList_CharacterData.Orders["last"]]
			if ProfessionShoppingList_Settings["useLocalReagents"] == true then reagents = "true" end
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

-- When the AddOn is fully loaded, actually run the components
function event:ADDON_LOADED(addOnName, containsBindings)
	if addOnName == appName then
		app.InitialiseCraftingOrders()
	end
end

---------------------
-- CRAFTING ORDERS --
---------------------

-- When opening the crafting orders window
function event:CRAFTINGORDERS_SHOW_CUSTOMER()
	app.CreateCraftingOrdersAssets()
end

-- When closing the crafting orders window
function event:CRAFTINGORDERS_HIDE_CUSTOMER()
	app.Flag["recraft"] = false
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

------------------
-- QUICK ORDERS --
------------------

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
		-- Separate error message if the target can't craft
		if result == 40 then
			app.Print("Target character cannot craft that item. Please enter a valid character name.")
		end

		-- Save this info as the last order done, unless it was a failed order
		if (result ~= 29 and result ~= 40) or app.QuickOrderErrors >= 4 then ProfessionShoppingList_CharacterData.Orders["last"] = app.SelectedRecipeID end

		-- Set the last used recipe name for the repeat order button title
		local recipeName = "No last order found"
		-- Check for the name if there has been a last order
		if ProfessionShoppingList_CharacterData.Orders["last"] ~= nil and ProfessionShoppingList_CharacterData.Orders["last"] ~= 0 then
			recipeName = C_TradeSkillUI.GetRecipeSchematic(ProfessionShoppingList_CharacterData.Orders["last"], false).name

			local reagents = "false"
			local recipient = ProfessionShoppingList_CharacterData.Orders[ProfessionShoppingList_CharacterData.Orders["last"]]
			if ProfessionShoppingList_Settings["useLocalReagents"] == true then reagents = "true" end
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