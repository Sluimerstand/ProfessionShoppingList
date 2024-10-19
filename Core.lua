----------------------------------------
-- Profession Shopping List: Core.lua --
----------------------------------------
-- Main AddOn code

-- Initialisation
local appName, app =  ...	-- Returns the AddOn name and a unique table
app.api = {}	-- Create a table to use for our API
ProfessionShoppingList = app.api	-- Create a namespace for our API
local api = app.api	-- Our API prefix
app.locales = {}	-- Localisation table
local L = app.locales

---------------------------
-- WOW API EVENT HANDLER --
---------------------------

app.Event = CreateFrame("Frame")
app.Event.handlers = {}

-- Register the event and add it to the handlers table
function app.Event:Register(eventName, func)
    if not self.handlers[eventName] then
        self.handlers[eventName] = {}
        self:RegisterEvent(eventName)
    end
    table.insert(self.handlers[eventName], func)
end

-- Run all handlers for a given event, when it fires
app.Event:SetScript("OnEvent", function(self, event, ...)
    if self.handlers[event] then
        for _, handler in ipairs(self.handlers[event]) do
            handler(...)
        end
    end
end)

----------------------
-- HELPER FUNCTIONS --
----------------------

-- Table dump
function app.Dump(table)
	local function dumpTable(o)
		if type(o) == 'table' then
			local s = '{ '
			for k,v in pairs(o) do
				if type(k) ~= 'number' then k = '"' .. k .. '"' end
				s = s .. '[' .. k .. '] = ' .. dumpTable(v) .. ','
			end
		return s .. '} '
		else
			return tostring(o)
		end
	end
	print(dumpTable(table))
end

-- Fix sequential tables with missing indexes (yes I expect to have to re-use this xD)
function app.FixTable(table)
	local fixedTable = {}
	local index = 1
	
	for i = 1, #table do
		if table[i] ~= nil then
			fixedTable[index] = table[i]
			index = index + 1
		end
	end
	
	return fixedTable
end

-- App colour
function app.Colour(string)
	return "|cffC69B6D" .. string .. "|r"
end

-- Print with AddOn prefix
function app.Print(...)
	print(app.NameShort .. ":", ...)
end

-- Debug print with AddOn prefix
function app.Debug(...)
	if ProfessionShoppingList_Settings["debug"] then
		print(app.NameShort .. app.Colour(" Debug") .. ":", ...)
	end
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
	if show then
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

-- Window tooltip show
function app.WindowTooltipShow(text, hyperlink)
	-- Set the tooltip to either the left or right, depending on where the window is placed
	GameTooltip:SetOwner(app.Window, "ANCHOR_NONE")
	if GetScreenWidth()/2-ProfessionShoppingList_Settings["windowPosition"].width/2-app.Window:GetLeft() >= 0 then
		GameTooltip:SetPoint("LEFT", app.Window, "RIGHT", 0, 0)
	else
		GameTooltip:SetPoint("RIGHT", app.Window, "LEFT", 0, 0)
	end

	-- Set the text
	if hyperlink then
		GameTooltip:SetHyperlink(text)
	else
		GameTooltip:SetText(text)
	end

	-- Show the tooltip
	GameTooltip:Show()
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
	if not ProfessionShoppingList_Data.Pets then ProfessionShoppingList_Data.Pets = {} end

	if not ProfessionShoppingList_Library then ProfessionShoppingList_Library = {} end

	if not ProfessionShoppingList_Cache then ProfessionShoppingList_Cache = {} end
	if not ProfessionShoppingList_Cache.ReagentTiers then ProfessionShoppingList_Cache.ReagentTiers = {} end
	if not ProfessionShoppingList_Cache.Reagents then ProfessionShoppingList_Cache.Reagents = {} end
	if not ProfessionShoppingList_Cache.FakeRecipes then ProfessionShoppingList_Cache.FakeRecipes = {} end
	if not ProfessionShoppingList_Cache.SimulatedRecipes then ProfessionShoppingList_Cache.SimulatedRecipes = {} end
	
	if not ProfessionShoppingList_CharacterData then ProfessionShoppingList_CharacterData = {} end
	if not ProfessionShoppingList_CharacterData.Recipes then ProfessionShoppingList_CharacterData.Recipes = {} end
	if not ProfessionShoppingList_CharacterData.Orders then ProfessionShoppingList_CharacterData.Orders = {} end

	-- Enable default user settings
	if ProfessionShoppingList_Settings["hide"] == nil then ProfessionShoppingList_Settings["hide"] = false end
	if ProfessionShoppingList_Settings["windowPosition"] == nil then ProfessionShoppingList_Settings["windowPosition"] = { ["left"] = 1295, ["bottom"] = 836, ["width"] = 200, ["height"] = 200, } end
	if ProfessionShoppingList_Settings["pcWindowPosition"] == nil then ProfessionShoppingList_Settings["pcWindowPosition"] = ProfessionShoppingList_Settings["windowPosition"] end
	if ProfessionShoppingList_Settings["windowLocked"] == nil then ProfessionShoppingList_Settings["windowLocked"] = false end
	if ProfessionShoppingList_Settings["debug"] == nil then ProfessionShoppingList_Settings["debug"] = false end

	-- Load personal recipes, if the setting is enabled
	if ProfessionShoppingList_Settings["pcRecipes"] then
		ProfessionShoppingList_Data.Recipes = ProfessionShoppingList_CharacterData.Recipes
	end

	-- Initialise some session variables
	app.Hidden = CreateFrame("Frame")
	app.Flag = {}
	app.Flag["changingRecipes"] = false
	app.Flag["merchantAssets"] = false
	app.Flag["tradeskillAssets"] = false
	app.Flag["versionCheck"] = 0
	app.ReagentQuantities = {}
	app.SelectedRecipe = {}
	app.SelectedRecipe.Profession = { recipeID = 0, recraft = false, recipeType = 0 }
	app.SelectedRecipe.PlaceOrder = { recipeID = 0, recraft = false, recipeType = 0 }
	app.SelectedRecipe.MakeOrder = {}
	app.UpdatedCooldownWidth = 0
	app.UpdatedReagentWidth = 0
	app.IncludeWarbank = true	-- Temporary flag until Blizz fixes their shit
	app.SimAddOns = {"CraftSim", "TestFlight"}

	-- Register our AddOn communications channel
	C_ChatInfo.RegisterAddonMessagePrefix("ProfShopList")

	-- Legacy compatibility
	if ProfessionShoppingList_Cache.CraftSimRecipes then
		ProfessionShoppingList_Cache.SimulatedRecipes = ProfessionShoppingList_Cache.CraftSimRecipes
		ProfessionShoppingList_Cache.CraftSimRecipes = nil
	end
	if ProfessionShoppingList_Settings["alvinGUID"] then ProfessionShoppingList_Settings["alvinGUID"] = nil end
	if ProfessionShoppingList_Settings["ragnarosGUID"] then ProfessionShoppingList_Settings["ragnarosGUID"] = nil end
end

-- When the AddOn is fully loaded, actually run the components
app.Event:Register("ADDON_LOADED", function(addOnName, containsBindings)
	if addOnName == appName then
		app.InitialiseCore()
		app.CreateWindow()
		app.TooltipInfo()		
		app.Settings()

		local function refreshCooldowns()
			app.UpdateCooldowns()
			C_Timer.After(60, refreshCooldowns)
		end
		refreshCooldowns()

		-- Slash commands
		SLASH_ProfessionShoppingList1 = "/psl";
		function SlashCmdList.ProfessionShoppingList(msg, editBox)
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
						app.Print(L.INVALID_RECIPEQUANTITY)
					end
				else
					app.Print(L.INVALID_RECIPEID)
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

						-- Show window
						app.Show()
					elseif type(recipeQuantity) == "number" and recipeQuantity ~= 0 and recipeQuantity <= ProfessionShoppingList_Data.Recipes[recipeID].quantity then
						app.UntrackRecipe(recipeID, recipeQuantity)

						-- Show window
						app.Show()
					else
						app.Print(L.INVALID_RECIPEQUANTITY)
					end
				else
					app.Print(L.INVALID_RECIPE_TRACKED)
				end
			-- Toggle debug mode
			elseif command == 'debug' then
				if ProfessionShoppingList_Settings["debug"] then
					ProfessionShoppingList_Settings["debug"] = false
					app.Print(L.DEBUG_DISABLED)
				else
					ProfessionShoppingList_Settings["debug"] = true
					app.Print(L.DEBUG_ENABLED)
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
					local _, criteriaType = GetAchievementCriteriaInfo(achievementID, 1, true)

					-- If the asset type is a (crafting) spell
					if criteriaType == 29 then
						-- Make sure that we check the only criteria if numCriteria was evaluated to be 0
						if numCriteria == 0 then numCriteria = 1 end
						-- For each criteria, track the SpellID
						for i = 1, numCriteria, 1 do
							local _, criteriaType, completed, quantity, reqQuantity, _, _, assetID = GetAchievementCriteriaInfo(achievementID, i, true)
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
						app.Print(L.INVALID_ACHIEVEMENT)
					end
				else
					app.Print(L.INVALID_COMMAND)
				end
			end
		end
	end
end)

-----------------
-- MAIN WINDOW --
-----------------

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
	app.Window:SetClampedToScreen(true)
	app.Window:SetResizable(true)
	app.Window:SetResizeBounds(140, 140)
	app.Window:RegisterForDrag("LeftButton")
	app.Window:SetScript("OnDragStart", function()
		app.MoveWindow()
	end)
	app.Window:SetScript("OnDragStop", function()
		app.SaveWindow()
	end)
	app.Window:Hide()

	-- Resize corner
	app.Window.Corner = CreateFrame("Button", nil, app.Window)
	app.Window.Corner:EnableMouse("true")
	app.Window.Corner:SetPoint("BOTTOMRIGHT")
	app.Window.Corner:SetSize(16,16)
	app.Window.Corner:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	app.Window.Corner:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	app.Window.Corner:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	app.Window.Corner:SetScript("OnMouseDown", function()
		app.Window:StartSizing("BOTTOMRIGHT")
		GameTooltip:ClearLines()
		GameTooltip:Hide()
	end)
	app.Window.Corner:SetScript("OnMouseUp", function()
		app.SaveWindow()
	end)

	-- Close button
	local close = CreateFrame("Button", "", app.Window, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", app.Window, "TOPRIGHT", 2, 2)
	close:SetScript("OnClick", function()
		app.Window:Hide()
	end)
	close:SetScript("OnEnter", function()
		app.WindowTooltipShow(L.WINDOW_BUTTON_CLOSE)
	end)
	close:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-- Lock button
	app.LockButton = CreateFrame("Button", "", app.Window, "UIPanelCloseButton")
	app.LockButton:SetPoint("TOPRIGHT", close, "TOPLEFT", -2, 0)
	app.LockButton:SetNormalTexture("Interface\\AddOns\\ProfessionShoppingList\\assets\\buttons.blp")
	app.LockButton:GetNormalTexture():SetTexCoord(183/256, 219/256, 1/128, 39/128)
	app.LockButton:SetDisabledTexture("Interface\\AddOns\\ProfessionShoppingList\\assets\\buttons.blp")
	app.LockButton:GetDisabledTexture():SetTexCoord(183/256, 219/256, 41/128, 79/128)
	app.LockButton:SetPushedTexture("Interface\\AddOns\\ProfessionShoppingList\\assets\\buttons.blp")
	app.LockButton:GetPushedTexture():SetTexCoord(183/256, 219/256, 81/128, 119/128)
	app.LockButton:SetScript("OnClick", function()
		ProfessionShoppingList_Settings["windowLocked"] = true
		app.Window.Corner:Hide()
		app.LockButton:Hide()
		app.UnlockButton:Show()
	end)
	app.LockButton:SetScript("OnEnter", function()
		app.WindowTooltipShow(L.WINDOW_BUTTON_LOCK)
	end)
	app.LockButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-- Unlock button
	app.UnlockButton = CreateFrame("Button", "", app.Window, "UIPanelCloseButton")
	app.UnlockButton:SetPoint("TOPRIGHT", close, "TOPLEFT", -2, 0)
	app.UnlockButton:SetNormalTexture("Interface\\AddOns\\ProfessionShoppingList\\assets\\buttons.blp")
	app.UnlockButton:GetNormalTexture():SetTexCoord(148/256, 184/256, 1/128, 39/128)
	app.UnlockButton:SetDisabledTexture("Interface\\AddOns\\ProfessionShoppingList\\assets\\buttons.blp")
	app.UnlockButton:GetDisabledTexture():SetTexCoord(148/256, 184/256, 41/128, 79/128)
	app.UnlockButton:SetPushedTexture("Interface\\AddOns\\ProfessionShoppingList\\assets\\buttons.blp")
	app.UnlockButton:GetPushedTexture():SetTexCoord(148/256, 184/256, 81/128, 119/128)
	app.UnlockButton:SetScript("OnClick", function()
		ProfessionShoppingList_Settings["windowLocked"] = false
		app.Window.Corner:Show()
		app.LockButton:Show()
		app.UnlockButton:Hide()
	end)
	app.UnlockButton:SetScript("OnEnter", function()
		app.WindowTooltipShow(L.WINDOW_BUTTON_UNLOCK)
	end)
	app.UnlockButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	if ProfessionShoppingList_Settings["windowLocked"] then
		app.Window.Corner:Hide()
		app.LockButton:Hide()
		app.UnlockButton:Show()
	else
		app.Window.Corner:Show()
		app.LockButton:Show()
		app.UnlockButton:Hide()
	end

	-- Settings button
	app.SettingsButton = CreateFrame("Button", "", app.Window, "UIPanelCloseButton")
	app.SettingsButton:SetPoint("TOPRIGHT", app.LockButton, "TOPLEFT", -2, 0)
	app.SettingsButton:SetNormalTexture("Interface\\AddOns\\ProfessionShoppingList\\assets\\buttons.blp")
	app.SettingsButton:GetNormalTexture():SetTexCoord(112/256, 148/256, 1/128, 39/128)
	app.SettingsButton:SetDisabledTexture("Interface\\AddOns\\ProfessionShoppingList\\assets\\buttons.blp")
	app.SettingsButton:GetDisabledTexture():SetTexCoord(112/256, 148/256, 41/128, 79/128)
	app.SettingsButton:SetPushedTexture("Interface\\AddOns\\ProfessionShoppingList\\assets\\buttons.blp")
	app.SettingsButton:GetPushedTexture():SetTexCoord(112/256, 148/256, 81/128, 119/128)
	app.SettingsButton:SetScript("OnClick", function()
		app.OpenSettings()
	end)
	app.SettingsButton:SetScript("OnEnter", function()
		app.WindowTooltipShow(L.WINDOW_BUTTON_SETTINGS)
	end)
	app.SettingsButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-- Clear button
	app.ClearButton = CreateFrame("Button", "", app.Window, "UIPanelCloseButton")
	app.ClearButton:SetPoint("TOPRIGHT", app.SettingsButton, "TOPLEFT", -2, 0)
	app.ClearButton:SetNormalTexture("Interface\\AddOns\\ProfessionShoppingList\\assets\\buttons.blp")
	app.ClearButton:GetNormalTexture():SetTexCoord(1/256, 37/256, 1/128, 39/128)
	app.ClearButton:SetDisabledTexture("Interface\\AddOns\\ProfessionShoppingList\\assets\\buttons.blp")
	app.ClearButton:GetDisabledTexture():SetTexCoord(1/256, 37/256, 41/128, 79/128)
	app.ClearButton:SetPushedTexture("Interface\\AddOns\\ProfessionShoppingList\\assets\\buttons.blp")
	app.ClearButton:GetPushedTexture():SetTexCoord(1/256, 37/256, 81/128, 119/128)
	app.ClearButton:SetScript("OnClick", function()
		StaticPopupDialogs["CLEAR_RECIPES"] = {
			text = app.NameLong .. "\n\n" .. L.CLEAR_CONFIRMATION .. "\n" .. L.CONFIRMATION,
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
		StaticPopup_Show("CLEAR_RECIPES")
	end)
	app.ClearButton:SetScript("OnEnter", function()
		app.WindowTooltipShow(L.WINDOW_BUTTON_CLEAR)
	end)
	app.ClearButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
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

	-- Temporary checkbox until Blizz fixes their shit
	local checkBox = CreateFrame("CheckButton", nil, app.Window, "ChatConfigCheckButtonTemplate")
	checkBox:SetPoint("TOPLEFT", app.Window, "BOTTOMLEFT", 2, 0)
	checkBox.Text:SetText(L.WARBANK_CHECKBOX)
	checkBox.tooltip = L.WARBANK_TOOLTIP
	checkBox:HookScript("OnClick", function()
		app.IncludeWarbank = checkBox:GetChecked()
		app.UpdateNumbers()
	end)
	checkBox:SetChecked(app.IncludeWarbank)
end

-- Move the main window
function app.MoveWindow()
	if ProfessionShoppingList_Settings["windowLocked"] then
		-- Highlight the Unlock button
		app.UnlockButton:LockHighlight()
	else
		-- Start moving the window, and hide any visible tooltips
		app.Window:StartMoving()
		GameTooltip:ClearLines()
		GameTooltip:Hide()
	end
end

-- Save the main window position and size
function app.SaveWindow()
	-- Stop highlighting the unlock button
	app.UnlockButton:UnlockHighlight()

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

-- Update numbers tracked
function app.UpdateNumbers()
	-- Update reagents tracked
	for reagentID, amount in pairs(app.ReagentQuantities) do
		local itemLink, fileID

		if not ProfessionShoppingList_Cache.Reagents[reagentID] then
			-- Cache item
			if not C_Item.IsItemDataCachedByID(reagentID) then
				app.CacheItem(reagentID, true)
				RunNextFrame(app.UpdateNumbers)
				app.Debug("app.UpdateNumbers()")
				do return end
			end
		else
			-- Read the info from the cache
			itemLink = ProfessionShoppingList_Cache.Reagents[reagentID].link
			icon = ProfessionShoppingList_Cache.Reagents[reagentID].icon
		end

		local itemAmount = ""
		local itemIcon = "|T" .. ProfessionShoppingList_Cache.Reagents[reagentID].icon .. ":0|t"

		if type(reagentID) == "number" then
			-- Get needed/owned number of reagents
			local reagentAmountHave = app.GetReagentCount(reagentID)

			-- Make stuff grey and add a checkmark if 0 are needed
			if math.max(0,amount-reagentAmountHave) == 0 then
				itemIcon = app.IconReady
				itemAmount = "|cff9d9d9d"
				itemLink = string.gsub(itemLink, "|cff9d9d9d|", "|cff9d9d9d|") -- Poor
				itemLink = string.gsub(itemLink, "|cffffffff|", "|cff9d9d9d|") -- Common
				itemLink = string.gsub(itemLink, "|cff1eff00|", "|cff9d9d9d|") -- Uncommon
				itemLink = string.gsub(itemLink, "|cff0070dd|", "|cff9d9d9d|") -- Rare
				itemLink = string.gsub(itemLink, "|cffa335ee|", "|cff9d9d9d|") -- Epic
				itemLink = string.gsub(itemLink, "|cffff8000|", "|cff9d9d9d|") -- Legendary
				itemLink = string.gsub(itemLink, "|cffe6cc80|", "|cff9d9d9d|") -- Artifact
			-- Make the icon an arrow if it is a subreagent, but not at 0 needed
			else
				for k, v in pairs(ProfessionShoppingList_Data.Recipes) do
					if ProfessionShoppingList_Library[k] and ProfessionShoppingList_Library[k].itemID == reagentID then
						itemIcon = app.IconArrow
						-- Set the itemlink to be Artifact colour and then its original colour, to force it being sorted at the top
						itemLink = "|cff000000|r" .. itemLink
						break
					end
				end
			end

			-- Set the displayed amount based on settings
			if ProfessionShoppingList_Settings["showRemaining"] == false then
				itemAmount = itemAmount .. reagentAmountHave .. "/" .. amount
			else
				itemAmount = itemAmount .. math.max(0,amount-reagentAmountHave)
			end
		elseif reagentID == "gold" then
			-- Set the colour of both strings and the icon
			local colour = ""
			if math.max(0,amount-GetMoney()) == 0 then
				itemIcon = app.IconReady
				colour = "|cff9d9d9d"
				itemLink = colour .. itemLink
			end

			-- Set the displayed amount based on settings
			if ProfessionShoppingList_Settings["showRemaining"] == false then
				itemAmount = colour .. GetCoinTextureString(amount)
			else
				itemAmount = colour .. GetCoinTextureString(math.max(0,amount-GetMoney()))
			end
		elseif string.find(reagentID, "currency") then
			local number = string.gsub(reagentID, "currency:", "")
			local quantity = C_CurrencyInfo.GetCurrencyInfo(tonumber(number)).quantity

			-- Set the colour of both strings and the icon
			local colour = ""
			if math.max(0,amount-quantity) == 0 then
				itemIcon = app.IconReady
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
				itemAmount = colour .. quantity .. "/" .. amount
			else
				itemAmount = colour .. math.max(0,amount-quantity)
			end
		end

		-- Push the info to the window
		if reagentRow then
			for i, row in pairs(reagentRow) do
				if row:GetID() == reagentID or (reagentID == "gold" and row.text1:GetText() == L.GOLD) then
					row.icon:SetText(itemIcon)
					row.text1:SetText(itemLink)
					row.text2:SetText(itemAmount)
					app.UpdatedReagentWidth = math.max(row.icon:GetStringWidth()+row.text1:GetStringWidth()+row.text2:GetStringWidth(), app.UpdatedReagentWidth)
				elseif string.find(reagentID, "currency") then
					local number = string.gsub(reagentID, "currency:", "")
					local name = C_CurrencyInfo.GetCurrencyLink(tonumber(number))
					if name == row.text1:GetText() then
						row.icon:SetText(itemIcon)
						row.text1:SetText(itemLink)
						row.text2:SetText(itemAmount)
						app.UpdatedReagentWidth = math.max(row.icon:GetStringWidth()+row.text1:GetStringWidth()+row.text2:GetStringWidth(), app.UpdatedReagentWidth)
					end
				end
			end
		end
	end

	local customSortList = {
		-- Needed reagents
		"|cffe6cc80",				-- Artifact
		"|cffff8000",				-- Legendary
		"|cffa335ee",				-- Epic
		"|cff0070dd",				-- Rare
		"|cff1eff00",				-- Uncommon
		"|cffffffff",				-- Common
		-- Subreagents
		"|cff000000|r|cffe6cc80",	-- Artifact
		"|cff000000|r|cffff8000",	-- Legendary
		"|cff000000|r|cffa335ee",	-- Epic
		"|cff000000|r|cff0070dd",	-- Rare
		"|cff000000|r|cff1eff00",	-- Uncommon
		"|cff000000|r|cffffffff",	-- Common
		-- Collected reagents
		"|cff9d9d9d",				-- Poor (quantity 0)
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
					row.text2:SetText(L.READY)
				elseif cooldownRemaining < 60*60 then
					row.text2:SetText(minutes .. L.MINUTES)
				elseif cooldownRemaining < 60*60*24 then
					row.text2:SetText(hours .. L.HOURS .. " " .. minutes .. L.MINUTES)
				else
					row.text2:SetText(days .. L.DAYS .. " " .. hours .. L.HOURS .. " " .. minutes .. L.MINUTES)
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
			-- Normal recipes
			if type(recipeID) == "number" then
				app.GetReagents(app.ReagentQuantities, recipeID, recipeInfo.quantity, recipeInfo.recraft)
			-- Patron orders
			elseif ProfessionShoppingList_Cache.FakeRecipes[recipeID] and string.sub(recipeID, 1, 6) == "order:" then
				app.GetReagents(app.ReagentQuantities, recipeID, recipeInfo.quantity, recipeInfo.recraft)
			-- Guild/Personal orders
			elseif string.sub(recipeID, 1, 6) == "order:" then
				app.GetReagents(app.ReagentQuantities, recipeID, recipeInfo.quantity, recipeInfo.recraft)
			-- Vendor items
			elseif ProfessionShoppingList_Cache.FakeRecipes[recipeID] and string.sub(recipeID, 1, 7) == "vendor:" then
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
					local key = "currency:" .. currencyID
					if app.ReagentQuantities[key] == nil then app.ReagentQuantities[key] = 0 end
					app.ReagentQuantities[key] = app.ReagentQuantities[key] + ( currencyAmount * ProfessionShoppingList_Data.Recipes[recipeID].quantity )
				end
			end
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
			app.Window.Recipes:SetScript("OnDragStart", function() app.MoveWindow()	end)
			app.Window.Recipes:SetScript("OnDragStop", function() app.SaveWindow() end)
			app.Window.Recipes:SetScript("OnEnter", function()
				app.WindowTooltipShow(L.WINDOW_TOOLTIP_RECIPES)
			end)
			app.Window.Recipes:SetScript("OnLeave", function()
			GameTooltip:Hide()
			end)
			
			local recipes1 = app.Window.Recipes:CreateFontString("ARTWORK", nil, "GameFontNormal")
			recipes1:SetPoint("LEFT", app.Window.Recipes)
			recipes1:SetScale(1.1)
			app.RecipeHeader = recipes1
		end

		app.Window.Recipes:SetScript("OnClick", function(self)
			local children = {self:GetChildren()}

			if showRecipes then
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
			row:RegisterForClicks("AnyUp")
			row:SetScript("OnDragStart", function() app.MoveWindow() end)
			row:SetScript("OnDragStop", function() app.SaveWindow() end)
			row:SetScript("OnEnter", function()
				app.WindowTooltipShow(recipeInfo.link, true)
			end)
			row:SetScript("OnLeave", function()
				GameTooltip:ClearLines()
				GameTooltip:Hide()
			end)
			row:SetScript("OnClick", function(self, button)
				-- Right-click on recipe amount
				if button == "RightButton" then
					-- Untrack the recipe
					if IsControlKeyDown() then
						app.UntrackRecipe(recipeInfo.recipeID, 0)
					else
						app.UntrackRecipe(recipeInfo.recipeID, 1)
					end

					-- Show window
					app.Show()
				-- Left-click on recipe
				elseif button == "LeftButton" then
					-- If Shift is held also
					if IsShiftKeyDown() then
						-- Try write link to chat
						ChatEdit_InsertLink(recipeInfo.link)
						app.SearchAH(recipeInfo.link)
					-- If Control is held also
					elseif IsControlKeyDown() and type(recipeInfo.recipeID) == "number" then
							C_TradeSkillUI.SetRecipeItemNameFilter("")	-- Clear search filter, which can interfere
							C_TradeSkillUI.OpenRecipe(recipeInfo.recipeID)
					-- If Alt is held also
					elseif IsAltKeyDown() and type(recipeInfo.recipeID) == "number" then
						C_TradeSkillUI.SetRecipeItemNameFilter("")	-- Clear search filter, which can interfere
						C_TradeSkillUI.OpenRecipe(recipeInfo.recipeID)
						-- Make sure the tradeskill frame is loaded
						if C_AddOns.IsAddOnLoaded("Blizzard_Professions") then
							C_TradeSkillUI.CraftRecipe(recipeInfo.recipeID, ProfessionShoppingList_Data.Recipes[recipeInfo.recipeID].quantity)
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
			icon1:SetText(app.IconProfession[tradeskill])

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
			app.Window.Reagents:SetScript("OnDragStart", function() app.MoveWindow() end)
			app.Window.Reagents:SetScript("OnDragStop", function() app.SaveWindow() end)
			app.Window.Reagents:SetScript("OnEnter", function()
				app.WindowTooltipShow(L.WINDOW_TOOLTIP_REAGENTS)
			end)
			app.Window.Reagents:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)
			
			local reagents1 = app.Window.Reagents:CreateFontString("ARTWORK", nil, "GameFontNormal")
			reagents1:SetPoint("LEFT", app.Window.Reagents)
			reagents1:SetText(L.WINDOW_HEADER_REAGENTS)
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

			if showReagents then
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
				C_Timer.After(1, function()
					app.CacheItem(k, true)
					app.UpdateRecipes()
				end)
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
			row:SetScript("OnDragStart", function() app.MoveWindow() end)
			row:SetScript("OnDragStop", function() app.SaveWindow() end)
			row:SetScript("OnEnter", function()
				app.WindowTooltipShow(reagentInfo.link, true)
			end)
			row:SetScript("OnLeave", function()
				GameTooltip:ClearLines()
				GameTooltip:Hide()
			end)
			row:SetScript("OnClick", function(self, button)
				local function trackSubreagent(recipeID, itemID)
					-- Define the amount of recipes to be tracked
					local quantityMade = C_TradeSkillUI.GetRecipeSchematic(recipeID, false).quantityMin
					local amount = math.max(0, math.ceil((app.ReagentQuantities[itemID] - app.GetReagentCount(itemID)) / quantityMade))
					if ProfessionShoppingList_Data.Recipes[recipeID] then amount = math.max(0, (amount - ProfessionShoppingList_Data.Recipes[recipeID].quantity)) end

					-- Track the recipe (don't track if 0)
					if amount > 0 then app.TrackRecipe(recipeID, amount) end
				end

				-- Control+click on reagent
				if button == "LeftButton" and IsControlKeyDown() then
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
						pslOptionText:SetText("|cffFFFFFF" .. L.SUBREAGENTS1 .. ":\n" .. reagentInfo.link .. "\n\n" .. L.SUBREAGENTS2 .. ":")

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
									app.Debug("getInfo()")
									do return end
								end

								-- Add text
								pslOption1:SetText(pslOption1:GetText() .. reagentAmount .. "× " .. itemLink .. "\n")
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
										app.Debug("getInfo()")
										do return end
									end

									-- Add text
									pslOption2:SetText(pslOption2:GetText() .. reagentAmount .. "× " .. itemLink .. "\n")
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
										app.Debug("getInfo()")
										do return end
									end

									-- Add text
									pslOption3:SetText(pslOption3:GetText() .. reagentAmount .. "× " .. itemLink .. "\n")
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
										app.Debug("getInfo()")
										do return end
									end

									-- Add text
									pslOption4:SetText(pslOption4:GetText() .. reagentAmount .. "× " .. itemLink .. "\n")
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
										app.Debug("getInfo()")
										do return end
									end

									-- Add text
									pslOption5:SetText(pslOption5:GetText() .. reagentAmount .. "× " .. itemLink .. "\n")
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
										app.Debug("getInfo()")
										do return end
									end

									-- Add text
									pslOption6:SetText(pslOption6:GetText() .. reagentAmount .. "× " .. itemLink .. "\n")
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
				-- Activate if Shift+clicking on the reagent
				elseif button == "LeftButton" and IsShiftKeyDown() then
					ChatEdit_InsertLink(reagentInfo.link)
					app.SearchAH(reagentInfo.link)
				end
			end)

			reagentRow[rowNo2] = row

			local icon1 = row:CreateFontString("ARTWORK", nil, "GameFontNormal")
			icon1:SetPoint("LEFT", row)
			icon1:SetScale(1.2)
			icon1:SetText("|T" .. reagentInfo.icon .. ":0|t")
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
			if type(k) == "number" or string.sub(k, 1, 6) == "order:" then
				trackRecipes = true
			else
				trackItems = true
			end
		end

		-- Set the header title accordingly
		if trackRecipes and trackItems then
			app.RecipeHeader:SetText(L.WINDOW_HEADER_RECIPES .. " & " .. L.WINDOW_HEADER_ITEMS .. " (" .. #recipeRow .. ")")
			app.ReagentHeader:SetText(L.WINDOW_HEADER_REAGENTS .. "&" .. L.WINDOW_HEADER_COSTS)
		elseif trackRecipes == false and trackItems then
			app.RecipeHeader:SetText(L.WINDOW_HEADER_ITEMS .. " (" .. #recipeRow .. ")")
			app.ReagentHeader:SetText(L.WINDOW_HEADER_COSTS)
		else
			if #recipeRow == 0 then
				app.RecipeHeader:SetText(L.WINDOW_HEADER_RECIPES)
			else
				app.RecipeHeader:SetText(L.WINDOW_HEADER_RECIPES .. " (" .. #recipeRow .. ")")
			end
			app.ReagentHeader:SetText(L.WINDOW_HEADER_REAGENTS)
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
			app.Window.Cooldowns:SetScript("OnDragStart", function() app.MoveWindow() end)
			app.Window.Cooldowns:SetScript("OnDragStop", function() app.SaveWindow() end)
			app.Window.Cooldowns:SetScript("OnEnter", function()
				app.WindowTooltipShow(L.WINDOW_TOOLTIP_COOLDOWNS)
			end)
			app.Window.Cooldowns:SetScript("OnLeave", function()
				GameTooltip:Hide()
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

			if showCooldowns then
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
			row:RegisterForClicks("AnyUp")
			row:SetScript("OnDragStart", function() app.MoveWindow() end)
			row:SetScript("OnDragStop", function() app.SaveWindow() end)
			row:SetScript("OnEnter", function()
				app.WindowTooltipShow("|cffFFFFFF" .. cooldownInfo.user)
			end)
			row:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)
			row:SetScript("OnClick", function(self, button)
				if button == "RightButton" and IsShiftKeyDown() then
					table.remove(ProfessionShoppingList_Data.Cooldowns, cooldownInfo.id)
					app.UpdateRecipes()
				elseif button == "LeftButton" then
					-- If Control is held also
					if IsControlKeyDown() then
						C_TradeSkillUI.SetRecipeItemNameFilter("")	-- Clear search filter, which can interfere
						C_TradeSkillUI.OpenRecipe(cooldownInfo.recipeID)
					-- If Alt is held also
					elseif IsAltKeyDown() then
						C_TradeSkillUI.SetRecipeItemNameFilter("")	-- Clear search filter, which can interfere
						C_TradeSkillUI.OpenRecipe(cooldownInfo.recipeID)
						-- Make sure the tradeskill frame is loaded
						if C_AddOns.IsAddOnLoaded("Blizzard_Professions") then
							C_TradeSkillUI.CraftRecipe(cooldownInfo.recipeID)
						end
					end
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
			icon1:SetText(app.IconProfession[tradeskill])
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
				text2:SetText(L.READY)
			elseif cooldownRemaining < 60*60 then
				text2:SetText(minutes .. L.MINUTES)
			elseif cooldownRemaining < 60*60*24 then
				text2:SetText(hours .. L.HOURS .. " " .. minutes .. L.MINUTES)
			else
				text2:SetText(days .. L.DAYS .. " " .. hours .. L.HOURS .. " " .. minutes .. L.MINUTES)
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
			elseif showCooldowns then
				windowHeight = windowHeight + rowNo3 * 16
				windowWidth = math.max(windowWidth, maxLength3, app.UpdatedCooldownWidth)
			end
			if showReagents then
				windowHeight = windowHeight + rowNo2 * 16
				windowWidth = math.max(windowWidth, maxLength2, app.UpdatedReagentWidth)
			end
			if showRecipes then
				windowHeight = windowHeight + rowNo * 16
				windowWidth = math.max(windowWidth, maxLength1)
			end
			if showRecipes == false or #ProfessionShoppingList_Data.Recipes < 1 then
				windowHeight = windowHeight + 2	-- Not sure why this is needed, but whatever
			end
			if windowHeight > math.floor(GetScreenHeight()*0.8) then windowHeight = math.floor(GetScreenHeight()*0.8) end
			if windowWidth > math.floor(GetScreenWidth()*0.8) then windowWidth = math.floor(GetScreenWidth()*0.8) end
			app.Window:SetHeight(math.max(140,windowHeight))
			app.Window:SetWidth(math.max(140,windowWidth+40))
			app.Window.ScrollFrame:SetVerticalScroll(0)
			app.SaveWindow()
		end)
		app.Window.Corner:SetScript("OnEnter", function()
			app.WindowTooltipShow(L.WINDOW_BUTTON_CORNER)
		end)
		app.Window.Corner:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

		-- Update numbers tracked and assets like buttons
		app.UpdateNumbers()
		app.UpdateAssets()
	end
end

-- Show window and update numbers
function app.Show()
	-- Set window to its proper position and size
	app.Window:ClearAllPoints()
	if ProfessionShoppingList_Settings["pcWindows"] then
		app.Window:SetSize(ProfessionShoppingList_Settings["pcWindowPosition"].width, ProfessionShoppingList_Settings["pcWindowPosition"].height)
		app.Window:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", ProfessionShoppingList_Settings["pcWindowPosition"].left, ProfessionShoppingList_Settings["pcWindowPosition"].bottom)
	else
		app.Window:SetSize(ProfessionShoppingList_Settings["windowPosition"].width, ProfessionShoppingList_Settings["windowPosition"].height)
		app.Window:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", ProfessionShoppingList_Settings["windowPosition"].left, ProfessionShoppingList_Settings["windowPosition"].bottom)
	end

	-- Show the window
	app.Window:Show()

	-- Update numbers
	app.UpdateRecipes()
end

-- Toggle window
function app.Toggle()
	-- Toggle tracking window
	if app.Window:IsShown() then
		app.Window:Hide()
	else
		app.Show()
	end
end

-- When the player gains currency
app.Event:Register("CHAT_MSG_CURRENCY", function()
	if not UnitAffectingCombat("player") then
		-- If any recipes are tracked
		local next = next
		if next(ProfessionShoppingList_Data.Recipes) ~= nil then
			app.UpdateNumbers()
		end
	end
end)

-- When bag changes occur (out of combat)
app.Event:Register("BAG_UPDATE_DELAYED", function()
	if not UnitAffectingCombat("player") then
		-- If any recipes are tracked
		local next = next
		if next(ProfessionShoppingList_Data.Recipes) ~= nil then
			app.UpdateNumbers()
		end

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

------------
-- ASSETS --
------------

-- Create assets
function app.CreateTradeskillAssets()
	-- Hide and disable existing tracking buttons
	ProfessionsFrame.CraftingPage.SchematicForm.TrackRecipeCheckbox:SetAlpha(0)
	ProfessionsFrame.CraftingPage.SchematicForm.TrackRecipeCheckbox:EnableMouse(false)
	ProfessionsFrame.OrdersPage.OrderView.OrderDetails.SchematicForm.TrackRecipeCheckbox:SetAlpha(0)
	ProfessionsFrame.OrdersPage.OrderView.OrderDetails.SchematicForm.TrackRecipeCheckbox:EnableMouse(false)

	-- Create the profession UI track button
	if not app.TrackProfessionButton then
		app.TrackProfessionButton = app.Button(ProfessionsFrame.CraftingPage, L.TRACK)
		app.TrackProfessionButton:SetPoint("TOPRIGHT", ProfessionsFrame.CraftingPage.SchematicForm, "TOPRIGHT", -9, -10)
		app.TrackProfessionButton:SetScript("OnClick", function()
			app.TrackRecipe(app.SelectedRecipe.Profession.recipeID, 1, app.SelectedRecipe.Profession.recraft)
		end)
	end
	
	-- Create the profession UI quantity editbox
	local function ebRecipeQuantityUpdate(self, newValue)
		-- Get the entered number cleanly
		newValue = math.floor(self:GetNumber())
		-- If the value is positive, change the number of recipes tracked
		if newValue >= 0 then
			app.UntrackRecipe(app.SelectedRecipe.Profession.recipeID, 0)
			if newValue > 0 then
				app.TrackRecipe(app.SelectedRecipe.Profession.recipeID, newValue, app.SelectedRecipe.Profession.recraft)
			end
		end
	end
	if not app.RecipeQuantityBox then
		app.RecipeQuantityBox = CreateFrame("EditBox", nil, ProfessionsFrame.CraftingPage, "InputBoxTemplate")
		app.RecipeQuantityBox:SetSize(25,20)
		app.RecipeQuantityBox:SetPoint("CENTER", app.TrackProfessionButton, "CENTER", 0, 0)
		app.RecipeQuantityBox:SetPoint("RIGHT", app.TrackProfessionButton, "LEFT", -4, 0)
		app.RecipeQuantityBox:SetAutoFocus(false)
		app.RecipeQuantityBox:SetText(0)
		app.RecipeQuantityBox:SetCursorPosition(0)
		app.RecipeQuantityBox:SetScript("OnEditFocusGained", function(self, newValue)
			app.TrackProfessionButton:Disable()
			app.UntrackProfessionButton:Disable()
		end)
		app.RecipeQuantityBox:SetScript("OnEditFocusLost", function(self, newValue)
			ebRecipeQuantityUpdate(self, newValue)
			app.TrackProfessionButton:Enable()
			if type(newValue) == "number" and newValue >= 1 then
				app.UntrackProfessionButton:Enable()
			end
		end)
		app.RecipeQuantityBox:SetScript("OnEnterPressed", function(self, newValue)
			ebRecipeQuantityUpdate(self, newValue)
			self:ClearFocus()
		end)
		app.RecipeQuantityBox:SetScript("OnEscapePressed", function(self, newValue)
			self:SetText(ProfessionShoppingList_Data.Recipes[app.SelectedRecipe.Profession.recipeID].quantity)
		end)
		app.Border(app.RecipeQuantityBox, -6, 1, 2, -2)
	end

	-- Create the profession UI untrack button
	if not app.UntrackProfessionButton then
		app.UntrackProfessionButton = app.Button(ProfessionsFrame.CraftingPage, L.UNTRACK)
		app.UntrackProfessionButton:SetPoint("TOP", app.TrackProfessionButton, "TOP", 0, 0)
		app.UntrackProfessionButton:SetPoint("RIGHT", app.RecipeQuantityBox, "LEFT", -8, 0)
		app.UntrackProfessionButton:SetFrameStrata("HIGH")
		app.UntrackProfessionButton:SetScript("OnClick", function()
			app.UntrackRecipe(app.SelectedRecipe.Profession.recipeID, 1)
	
			-- Show window
			app.Show()
		end)
	end

	-- Create the rank editbox for SL legendary recipes
	if not app.ShadowlandsRankBox then
		app.ShadowlandsRankBox = CreateFrame("EditBox", nil, ProfessionsFrame.CraftingPage, "InputBoxTemplate")
		app.ShadowlandsRankBox:SetSize(25,20)
		app.ShadowlandsRankBox:SetPoint("CENTER", app.RecipeQuantityBox, "CENTER", 0, 0)
		app.ShadowlandsRankBox:SetPoint("TOP", app.RecipeQuantityBox, "BOTTOM", 0, -4)
		app.ShadowlandsRankBox:SetAutoFocus(false)
		app.ShadowlandsRankBox:SetCursorPosition(0)
		app.ShadowlandsRankBox:Hide()
		app.Border(app.ShadowlandsRankBox, -6, 1, 2, -2)
	end
	if not app.ShadowlandsRankText then
		app.ShadowlandsRankText = ProfessionsFrame.CraftingPage.SchematicForm:CreateFontString("ARTWORK", nil, "GameFontNormal")
		app.ShadowlandsRankText:SetPoint("RIGHT", app.ShadowlandsRankBox, "LEFT", -10, 0)
		app.ShadowlandsRankText:SetJustifyH("LEFT")
		app.ShadowlandsRankText:SetText(L.RANK .. ":")
		app.ShadowlandsRankText:Hide()
	end

	-- Create the Track Unlearned Mogs button
	if not app.TrackUnlearnedMogsButton then
		local modeText = ""
		if ProfessionShoppingList_Settings["collectMode"] == 1 then
			modeText = L.MODE_APPEARANCES
		elseif ProfessionShoppingList_Settings["collectMode"] == 2 then
			modeText = L.MODE_SOURCES
		end

		app.TrackUnlearnedMogsButton = app.Button(ProfessionsFrame.CraftingPage, L.BUTTON_TRACKNEW)
		app.TrackUnlearnedMogsButton:SetPoint("TOPLEFT", ProfessionsFrame.CraftingPage.SchematicForm, "BOTTOMLEFT", 0, -4)
		app.TrackUnlearnedMogsButton:SetFrameStrata("HIGH")
		app.TrackUnlearnedMogsButton:SetScript("OnClick", function()
			local recipes = app.GetVisibleRecipes()

			StaticPopupDialogs["TRACK_NEW_MOGS"] = {
				text = app.NameLong .. "\n\n" .. L.TRACK_NEW1 .. " " .. #recipes .. " " .. L.TRACK_NEW2 .. "\n" .. modeText .. ".\n\n" .. L.TRACK_NEW3 .. "\n" .. L.CONFIRMATION,
				button1 = YES,
				button2 = NO,
				OnAccept = function()
					app.TrackUnlearnedMog()
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				showAlert = true,
			}
			StaticPopup_Show("TRACK_NEW_MOGS")
		end)
		app.TrackUnlearnedMogsButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
			GameTooltip:SetText(L.CURRENT_SETTING .. ": " .. modeText)
			GameTooltip:Show()
		end)
		app.TrackUnlearnedMogsButton:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

		-- Move the button if CraftScan or TestFlight is enabled, because we're nice
		if C_AddOns.IsAddOnLoaded("CraftScan") or C_AddOns.IsAddOnLoaded("TestFlight") then
			app.TrackUnlearnedMogsButton:SetPoint("TOPLEFT", ProfessionsFrame.CraftingPage.SchematicForm, "BOTTOMLEFT", 2, 24)
		end
	end

	-- Create Cooking Fire button
	if not app.CookingFireButton then
		app.CookingFireButton = CreateFrame("Button", "CookingFireButton", ProfessionsFrame.CraftingPage, "SecureActionButtonTemplate")
		app.CookingFireButton:SetWidth(40)
		app.CookingFireButton:SetHeight(40)
		app.CookingFireButton:SetNormalTexture(135805)
		app.CookingFireButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
		app.CookingFireButton:SetPoint("BOTTOMRIGHT", ProfessionsFrame.CraftingPage.SchematicForm, "BOTTOMRIGHT", -5, 4)
		app.CookingFireButton:SetFrameStrata("HIGH")
		app.CookingFireButton:RegisterForClicks("AnyDown", "AnyUp")
		app.CookingFireButton:SetAttribute("type", "spell")
		app.CookingFireButton:SetAttribute("spell1", 818)
		app.CookingFireButton:SetAttribute("unit1", "player")
		app.CookingFireButton:SetAttribute("spell2", 818)
		app.CookingFireButton:Hide()
		app.CookingFireButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
			GameTooltip:SetText(L.BUTTON_COOKINGFIRE)
			GameTooltip:Show()
		end)
		app.CookingFireButton:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		app.Border(app.CookingFireButton, -1, 2, 2, -1)

		app.CookingFireCooldown = CreateFrame("Cooldown", "CookingFireCooldown", app.CookingFireButton, "CooldownFrameTemplate")
		app.CookingFireCooldown:SetAllPoints(app.CookingFireButton)
		app.CookingFireCooldown:SetSwipeColor(1, 1, 1)

	end

	-- Create Chef's Hat button
	if not app.ChefsHatButton then
		app.ChefsHatButton = CreateFrame("Button", "ChefsHatButton", ProfessionsFrame.CraftingPage, "SecureActionButtonTemplate")
		app.ChefsHatButton:SetWidth(40)
		app.ChefsHatButton:SetHeight(40)
		app.ChefsHatButton:SetNormalTexture(236571)
		app.ChefsHatButton:GetNormalTexture():SetDesaturated(true)
		app.ChefsHatButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
		app.ChefsHatButton:SetPoint("BOTTOMRIGHT", app.CookingFireButton, "BOTTOMLEFT", -3, 0)
		app.ChefsHatButton:SetFrameStrata("HIGH")
		app.ChefsHatButton:RegisterForClicks("AnyDown", "AnyUp")
		app.ChefsHatButton:SetAttribute("type1", "toy")
		app.ChefsHatButton:SetAttribute("toy", 134020)
		app.Border(app.ChefsHatButton, -1, 2, 2, -1)

		app.ChefsHatCooldown = CreateFrame("Cooldown", "ChefsHatCooldown", app.ChefsHatButton, "CooldownFrameTemplate")
		app.ChefsHatCooldown:SetAllPoints(app.ChefsHatButton)
		app.ChefsHatCooldown:SetSwipeColor(1, 1, 1)
	end

	-- Create Thermal Anvil button
	if not app.ThermalAnvilButton then
		app.ThermalAnvilButton = CreateFrame("Button", "ThermalAnvilButton", ProfessionsFrame.CraftingPage, "SecureActionButtonTemplate")
		app.ThermalAnvilButton:SetWidth(40)
		app.ThermalAnvilButton:SetHeight(40)
		app.ThermalAnvilButton:SetNormalTexture(136241)
		app.ThermalAnvilButton:GetNormalTexture():SetDesaturated(true)
		app.ThermalAnvilButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
		app.ThermalAnvilButton:SetPoint("BOTTOMRIGHT", ProfessionsFrame.CraftingPage.SchematicForm, "BOTTOMRIGHT", -5, 4)
		app.ThermalAnvilButton:SetFrameStrata("HIGH")
		app.ThermalAnvilButton:RegisterForClicks("AnyDown", "AnyUp")
		app.ThermalAnvilButton:SetAttribute("type1", "macro")
		app.ThermalAnvilButton:SetAttribute("macrotext1", "/use item:87216")
		app.Border(app.ThermalAnvilButton, -1, 2, 2, -1)

		app.ThermalAnvilCooldown = CreateFrame("Cooldown", "ThermalAnvilCooldown", app.ThermalAnvilButton, "CooldownFrameTemplate")
		app.ThermalAnvilCooldown:SetAllPoints(app.ThermalAnvilButton)
		app.ThermalAnvilCooldown:SetSwipeColor(1, 1, 1)

		app.ThermalAnvilCharges = app.ThermalAnvilButton:CreateFontString("ARTWORK", nil, "GameFontNormal")
		app.ThermalAnvilCharges:SetPoint("BOTTOMRIGHT", app.ThermalAnvilButton, "BOTTOMRIGHT", 0, 0)
		app.ThermalAnvilCharges:SetJustifyH("RIGHT")
		if not C_Item.IsItemDataCachedByID(87216) then local item = Item:CreateFromItemID(87216) end
		local anvilCharges = C_Item.GetItemCount(87216, false, true, false, false)
		app.ThermalAnvilCharges:SetText(anvilCharges)
	end

	-- Create Alvin the Anvil button
	if not app.AlvinButton then
		app.AlvinButton = CreateFrame("Button", "AlvinButton", ProfessionsFrame.CraftingPage, "SecureActionButtonTemplate")
		app.AlvinButton:SetWidth(40)
		app.AlvinButton:SetHeight(40)
		app.AlvinButton:SetNormalTexture(1020356)
		app.AlvinButton:GetNormalTexture():SetDesaturated(true)
		app.AlvinButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
		app.AlvinButton:SetPoint("BOTTOMRIGHT", app.ThermalAnvilButton, "BOTTOMLEFT", -3, 0)
		app.AlvinButton:SetFrameStrata("HIGH")
		app.AlvinButton:RegisterForClicks("AnyDown", "AnyUp")
		app.Border(app.AlvinButton, -1, 2, 2, -1)

		app.AlvinCooldown = CreateFrame("Cooldown", "AlvinCooldown", app.AlvinButton, "CooldownFrameTemplate")
		app.AlvinCooldown:SetAllPoints(app.AlvinButton)
		app.AlvinCooldown:SetSwipeColor(1, 1, 1)
	end

	-- Create Lil' Ragnaros button
	if not app.RagnarosButton then
		app.RagnarosButton = CreateFrame("Button", "RagnarosButton", ProfessionsFrame.CraftingPage, "SecureActionButtonTemplate")
		app.RagnarosButton:SetWidth(40)
		app.RagnarosButton:SetHeight(40)
		app.RagnarosButton:SetNormalTexture(254652)
		app.RagnarosButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
		app.RagnarosButton:SetPoint("BOTTOMRIGHT", ProfessionsFrame.CraftingPage.SchematicForm, "BOTTOMRIGHT", -5, 4)
		app.RagnarosButton:SetFrameStrata("HIGH")
		app.RagnarosButton:RegisterForClicks("AnyDown", "AnyUp")
		app.RagnarosButton:Hide()
		app.RagnarosButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
			GameTooltip:SetText("|cffFFFFFF" .. L.BUTTON_COOKINGPET)
			GameTooltip:Show()
		end)
		app.RagnarosButton:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		app.Border(app.RagnarosButton, -1, 2, 2, -1)

		app.RagnarosCooldown = CreateFrame("Cooldown", "RagnarosCooldown", app.RagnarosButton, "CooldownFrameTemplate")
		app.RagnarosCooldown:SetAllPoints(app.RagnarosButton)
		app.RagnarosCooldown:SetSwipeColor(1, 1, 1)
	end

	-- Create Pierre button
	if not app.PierreButton then
		app.PierreButton = CreateFrame("Button", "PierreButton", ProfessionsFrame.CraftingPage, "SecureActionButtonTemplate")
		app.PierreButton:SetWidth(40)
		app.PierreButton:SetHeight(40)
		app.PierreButton:SetNormalTexture(798062)
		app.PierreButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
		app.PierreButton:SetPoint("BOTTOMRIGHT", ProfessionsFrame.CraftingPage.SchematicForm, "BOTTOMRIGHT", -5, 4)
		app.PierreButton:SetFrameStrata("HIGH")
		app.PierreButton:RegisterForClicks("AnyDown", "AnyUp")
		app.PierreButton:Hide()
		app.PierreButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
			GameTooltip:SetText("|cffFFFFFF" .. L.BUTTON_COOKINGPET)
			GameTooltip:Show()
		end)
		app.PierreButton:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		app.Border(app.PierreButton, -1, 2, 2, -1)

		app.PierreCooldown = CreateFrame("Cooldown", "PierreCooldown", app.PierreButton, "CooldownFrameTemplate")
		app.PierreCooldown:SetAllPoints(app.PierreButton)
		app.PierreCooldown:SetSwipeColor(1, 1, 1)
	end

	-- Create Lightforged Draenei Lightforge button
	if not app.LightforgeButton then
		app.LightforgeButton = CreateFrame("Button", "LightforgeButton", ProfessionsFrame.CraftingPage, "SecureActionButtonTemplate")
		app.LightforgeButton:SetWidth(40)
		app.LightforgeButton:SetHeight(40)
		app.LightforgeButton:SetNormalTexture(1723995)
		app.LightforgeButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
		app.LightforgeButton:SetPoint("BOTTOMRIGHT", app.AlvinButton, "BOTTOMLEFT", -3, 0)
		app.LightforgeButton:SetFrameStrata("HIGH")
		app.LightforgeButton:RegisterForClicks("AnyDown", "AnyUp")
		app.LightforgeButton:SetAttribute("type", "spell")
		app.LightforgeButton:SetAttribute("spell", 259930)
		app.LightforgeButton:Hide()
		app.Border(app.LightforgeButton, -1, 2, 2, -1)

		app.LightforgeCooldown = CreateFrame("Cooldown", "LightforgeCooldown", app.LightforgeButton, "CooldownFrameTemplate")
		app.LightforgeCooldown:SetAllPoints(app.LightforgeButton)
		app.LightforgeCooldown:SetSwipeColor(1, 1, 1)
	end

	-- Create Classic Milling info
	if not app.MillingClassic then
		app.MillingClassic = ProfessionsFrame.CraftingPage.SchematicForm:CreateFontString("ARTWORK", nil, "GameFontNormal")
		app.MillingClassic:SetPoint("BOTTOMLEFT", ProfessionsFrame.CraftingPage.SchematicForm, "BOTTOMLEFT", 35, 50)
		app.MillingClassic:SetJustifyH("LEFT")
		app.MillingClassic:SetText(app.Colour(L.MILLING_INFO) .. "\n|cffFFFFFF" .. L.MILLING_CLASSIC)
	end

	-- Create The Burning Crusade Milling info
	if not app.MillingTheBurningCrusade then
		app.MillingTheBurningCrusade = ProfessionsFrame.CraftingPage.SchematicForm:CreateFontString("ARTWORK", nil, "GameFontNormal")
		app.MillingTheBurningCrusade:SetPoint("BOTTOMLEFT", ProfessionsFrame.CraftingPage.SchematicForm, "BOTTOMLEFT", 35, 50)
		app.MillingTheBurningCrusade:SetJustifyH("LEFT")
		app.MillingTheBurningCrusade:SetText(app.Colour(L.MILLING_INFO) .. "\n|cffFFFFFF" .. L.MILLING_TBC)
	end

	-- Create Wrath of the Lich King Milling info
	if not app.MillingWrathOfTheLichKing then
		app.MillingWrathOfTheLichKing = ProfessionsFrame.CraftingPage.SchematicForm:CreateFontString("ARTWORK", nil, "GameFontNormal")
		app.MillingWrathOfTheLichKing:SetPoint("BOTTOMLEFT", ProfessionsFrame.CraftingPage.SchematicForm, "BOTTOMLEFT", 35, 50)
		app.MillingWrathOfTheLichKing:SetJustifyH("LEFT")
		app.MillingWrathOfTheLichKing:SetText(app.Colour(L.MILLING_INFO) .. "\n|cffFFFFFF" .. L.MILLING_WOTLK)
	end

	-- Create Cataclysm Milling info
	if not app.MillingCataclysm then
		app.MillingCataclysm = ProfessionsFrame.CraftingPage.SchematicForm:CreateFontString("ARTWORK", nil, "GameFontNormal")
		app.MillingCataclysm:SetPoint("BOTTOMLEFT", ProfessionsFrame.CraftingPage.SchematicForm, "BOTTOMLEFT", 35, 50)
		app.MillingCataclysm:SetJustifyH("LEFT")
		app.MillingCataclysm:SetText(app.Colour(L.MILLING_INFO) .. "\n|cffFFFFFF" .. L.MILLING_CATA)
	end

	-- Create Mists of Pandaria Milling info
	if not app.MillingMistsOfPandaria then
		app.MillingMistsOfPandaria = ProfessionsFrame.CraftingPage.SchematicForm:CreateFontString("ARTWORK", nil, "GameFontNormal")
		app.MillingMistsOfPandaria:SetPoint("BOTTOMLEFT", ProfessionsFrame.CraftingPage.SchematicForm, "BOTTOMLEFT", 35, 50)
		app.MillingMistsOfPandaria:SetJustifyH("LEFT")
		app.MillingMistsOfPandaria:SetText(app.Colour(L.MILLING_INFO) .. "\n|cffFFFFFF" .. L.MILLING_MOP)
	end

	-- Create Warlords of Draenor Milling info
	if not app.MillingWarlordsOfDraenor then
		app.MillingWarlordsOfDraenor = ProfessionsFrame.CraftingPage.SchematicForm:CreateFontString("ARTWORK", nil, "GameFontNormal")
		app.MillingWarlordsOfDraenor:SetPoint("BOTTOMLEFT", ProfessionsFrame.CraftingPage.SchematicForm, "BOTTOMLEFT", 35, 50)
		app.MillingWarlordsOfDraenor:SetJustifyH("LEFT")
		app.MillingWarlordsOfDraenor:SetText(app.Colour(L.MILLING_INFO) .. "\n|cffFFFFFF" .. L.MILLING_WOD)
	end

	-- Create Legion Milling info
	if not app.MillingLegion then
		app.MillingLegion = ProfessionsFrame.CraftingPage.SchematicForm:CreateFontString("ARTWORK", nil, "GameFontNormal")
		app.MillingLegion:SetPoint("BOTTOMLEFT", ProfessionsFrame.CraftingPage.SchematicForm, "BOTTOMLEFT", 35, 50)
		app.MillingLegion:SetJustifyH("LEFT")
		app.MillingLegion:SetText(app.Colour(L.MILLING_INFO) .. "\n|cffFFFFFF" .. L.MILLING_LEGION)
	end

	-- Create Battle for Azeroth Milling info
	if not app.MillingBattleForAzeroth then
		app.MillingBattleForAzeroth = ProfessionsFrame.CraftingPage.SchematicForm:CreateFontString("ARTWORK", nil, "GameFontNormal")
		app.MillingBattleForAzeroth:SetPoint("BOTTOMLEFT", ProfessionsFrame.CraftingPage.SchematicForm, "BOTTOMLEFT", 35, 50)
		app.MillingBattleForAzeroth:SetJustifyH("LEFT")
		app.MillingBattleForAzeroth:SetText(app.Colour(L.MILLING_INFO) .. "\n|cffFFFFFF" .. L.MILLING_BFA)
	end

	-- Create Shadowlands Milling info
	if not app.MillingShadowlands then
		app.MillingShadowlands = ProfessionsFrame.CraftingPage.SchematicForm:CreateFontString("ARTWORK", nil, "GameFontNormal")
		app.MillingShadowlands:SetPoint("BOTTOMLEFT", ProfessionsFrame.CraftingPage.SchematicForm, "BOTTOMLEFT", 35, 50)
		app.MillingShadowlands:SetJustifyH("LEFT")
		app.MillingShadowlands:SetText(app.Colour(L.MILLING_INFO) .. "\n|cffFFFFFF" .. L.MILLING_SL)
	end

	-- Create Dragonflight Milling info
	if not app.MillingDragonflight then
		app.MillingDragonflight = ProfessionsFrame.CraftingPage.SchematicForm:CreateFontString("ARTWORK", nil, "GameFontNormal")
		app.MillingDragonflight:SetPoint("BOTTOMLEFT", ProfessionsFrame.CraftingPage.SchematicForm, "BOTTOMLEFT", 35, 50)
		app.MillingDragonflight:SetJustifyH("LEFT")
		app.MillingDragonflight:SetText(app.Colour(L.MILLING_INFO) .. "\n|cffFFFFFF" .. L.MILLING_DF)
	end

	-- Create The War Within Milling info
	if not app.MillingTheWarWithin then
		app.MillingTheWarWithin = ProfessionsFrame.CraftingPage.SchematicForm:CreateFontString("ARTWORK", nil, "GameFontNormal")
		app.MillingTheWarWithin:SetPoint("BOTTOMLEFT", ProfessionsFrame.CraftingPage.SchematicForm, "BOTTOMLEFT", 35, 50)
		app.MillingTheWarWithin:SetJustifyH("LEFT")
		app.MillingTheWarWithin:SetText(app.Colour(L.MILLING_INFO) .. "\n|cffFFFFFF" .. L.MILLING_TWW)
	end

	-- Create The War Within Thaumaturgy info
	if not app.ThaumaturgyTheWarWithin then
		app.ThaumaturgyTheWarWithin = ProfessionsFrame.CraftingPage.SchematicForm:CreateFontString("ARTWORK", nil, "GameFontNormal")
		app.ThaumaturgyTheWarWithin:SetPoint("BOTTOMLEFT", ProfessionsFrame.CraftingPage.SchematicForm, "BOTTOMLEFT", 35, 50)
		app.ThaumaturgyTheWarWithin:SetJustifyH("LEFT")
		app.ThaumaturgyTheWarWithin:SetText(app.Colour(L.THAUMATURGY_INFO) .. "\n|cffFFFFFF" .. L.THAUMATURGY_TWW)
	end

	-- Grab the order information when opening a crafting order (THANK YOU PLUSMOUSE <3)
	hooksecurefunc(ProfessionsFrame.OrdersPage, "ViewOrder", function(_, orderDetails)
		app.SelectedRecipe.MakeOrder = orderDetails

		local key = "order:" .. app.SelectedRecipe.MakeOrder.orderID .. ":" .. app.SelectedRecipe.MakeOrder.spellID

		if ProfessionShoppingList_Data.Recipes[key] then
			app.TrackMakeOrderButton:SetText(L.UNTRACK)
			app.TrackMakeOrderButton:SetWidth(app.TrackMakeOrderButton:GetTextWidth()+20)
		else
			app.TrackMakeOrderButton:SetText(L.TRACK)
			app.TrackMakeOrderButton:SetWidth(app.TrackMakeOrderButton:GetTextWidth()+20)
		end
	end)

	-- Create the fulfil crafting orders UI (Un)track button
	if not app.TrackMakeOrderButton then
		app.TrackMakeOrderButton = app.Button(ProfessionsFrame.OrdersPage.OrderView.OrderDetails, L.TRACK)
		app.TrackMakeOrderButton:SetPoint("TOPRIGHT", ProfessionsFrame.OrdersPage.OrderView.OrderDetails, "TOPRIGHT", -9, -10)
		app.TrackMakeOrderButton:SetScript("OnClick", function()
			local key = "order:" .. app.SelectedRecipe.MakeOrder.orderID .. ":" .. app.SelectedRecipe.MakeOrder.spellID
			
			if ProfessionShoppingList_Data.Recipes[key] then
				-- Untrack the recipe
				app.UntrackRecipe(key, 1)

				-- Change button text
				app.TrackMakeOrderButton:SetText(L.TRACK)
				app.TrackMakeOrderButton:SetWidth(app.TrackMakeOrderButton:GetTextWidth()+20)
			else
				-- Track the recipe
				app.TrackRecipe(app.SelectedRecipe.MakeOrder.spellID, 1, app.SelectedRecipe.MakeOrder.isRecraft, app.SelectedRecipe.MakeOrder.orderID)

				-- Change button text
				app.TrackMakeOrderButton:SetText(L.UNTRACK)
				app.TrackMakeOrderButton:SetWidth(app.TrackMakeOrderButton:GetTextWidth()+20)
			end

			-- Show window
			app.Show()
		end)
	end

	-- Create Concentration info
	if not app.Concentration1 then
		ProfessionsFrame.CraftingPage.ConcentrationDisplay.Amount:SetPoint("TOPLEFT", ProfessionsFrame.CraftingPage.ConcentrationDisplay.Icon, "TOPRIGHT", 6, 0)

		app.Concentration1 = ProfessionsFrame.CraftingPage.ConcentrationDisplay:CreateFontString("ARTWORK", nil, "GameFontNormal")
		app.Concentration1:SetPoint("TOPLEFT", ProfessionsFrame.CraftingPage.ConcentrationDisplay.Amount, "BOTTOMLEFT", 0, 0)
		app.Concentration1:SetJustifyH("LEFT")
	end

	if not app.Concentration2 then
		ProfessionsFrame.OrdersPage.OrderView.ConcentrationDisplay.Amount:SetPoint("TOPLEFT", ProfessionsFrame.OrdersPage.OrderView.ConcentrationDisplay.Icon, "TOPRIGHT", 6, 0)

		app.Concentration2 = ProfessionsFrame.OrdersPage.OrderView.ConcentrationDisplay:CreateFontString("ARTWORK", nil, "GameFontNormal")
		app.Concentration2:SetPoint("TOPLEFT", ProfessionsFrame.OrdersPage.OrderView.ConcentrationDisplay.Amount, "BOTTOMLEFT", 0, 0)
		app.Concentration2:SetJustifyH("LEFT")
	end

	-- Set the flag for assets created to true
	app.Flag["tradeskillAssets"] = true
end

-- Update assets
function app.UpdateAssets()
	-- Profession window
	if app.Flag["tradeskillAssets"] then
		-- Enable Profession tracking for 1 = Item, 3 = Enchant
		if app.SelectedRecipe.Profession.recipeType == 1 or app.SelectedRecipe.Profession.recipeType == 3 then
			app.TrackProfessionButton:Enable()
			app.RecipeQuantityBox:Enable()
		end

		-- Disable Profession tracking for 2 = Salvage, recipes without reagents
		if app.SelectedRecipe.Profession.recipeType == 2 or C_TradeSkillUI.GetRecipeSchematic(app.SelectedRecipe.Profession.recipeID,false).reagentSlotSchematics[1] == nil then
			app.TrackProfessionButton:Disable()
			app.UntrackProfessionButton:Disable()
			app.RecipeQuantityBox:Disable()
		end

		-- Enable Profession untracking for tracked recipes
		if not ProfessionShoppingList_Data.Recipes[app.SelectedRecipe.Profession.recipeID] or ProfessionShoppingList_Data.Recipes[app.SelectedRecipe.Profession.recipeID].quantity == 0 then
			app.UntrackProfessionButton:Disable()
		else
			app.UntrackProfessionButton:Enable()
		end

		-- Update the Profession quantity editbox
		if ProfessionShoppingList_Data.Recipes[app.SelectedRecipe.Profession.recipeID] then
			app.RecipeQuantityBox:SetText(ProfessionShoppingList_Data.Recipes[app.SelectedRecipe.Profession.recipeID].quantity or 0)
		else
			app.RecipeQuantityBox:SetText(0)
		end

		-- Make the Chef's Hat button not desaturated if it can be used
		if PlayerHasToy(134020) then
			app.ChefsHatButton:GetNormalTexture():SetDesaturated(false)
		end

		-- Check how many thermal anvils the player has
		if not C_Item.IsItemDataCachedByID(87216) then local item = Item:CreateFromItemID(87216) end
		local anvilCount = C_Item.GetItemCount(87216, false, false, false, false)
		-- (De)saturate based on that
		if anvilCount >= 1 then
			app.ThermalAnvilButton:GetNormalTexture():SetDesaturated(false)
		else
			app.ThermalAnvilButton:GetNormalTexture():SetDesaturated(true)
		end
		-- Update charges
		local anvilCharges = C_Item.GetItemCount(87216, false, true, false, false)
		app.ThermalAnvilCharges:SetText(anvilCharges)

		-- Cooking Fire button cooldown
		local startTime = C_Spell.GetSpellCooldown(818).startTime
		local duration = C_Spell.GetSpellCooldown(818).duration
		app.CookingFireCooldown:SetCooldown(startTime, duration)

		-- Chef's Hat button cooldown
		startTime, duration = C_Item.GetItemCooldown(134020)
		app.ChefsHatCooldown:SetCooldown(startTime, duration)

		-- Thermal Anvil button cooldown
		startTime, duration = C_Item.GetItemCooldown(87216)
		app.ThermalAnvilCooldown:SetCooldown(startTime, duration)

		-- Make the Alvin the Anvil button not desaturated if it can be used
		if ProfessionShoppingList_Data.Pets["alvin"] and C_PetJournal.PetIsSummonable(ProfessionShoppingList_Data.Pets["alvin"].guid) then
			app.AlvinButton:GetNormalTexture():SetDesaturated(false)
		end

		-- Pet buttons cooldown
		startTime = C_Spell.GetSpellCooldown(61304).startTime
		duration = C_Spell.GetSpellCooldown(61304).duration
		app.AlvinCooldown:SetCooldown(startTime, duration)
		app.RagnarosCooldown:SetCooldown(startTime, duration)
		app.PierreCooldown:SetCooldown(startTime, duration)

		-- Lightforge cooldown
		startTime = C_Spell.GetSpellCooldown(259930).startTime
		duration = C_Spell.GetSpellCooldown(259930).duration
		app.LightforgeCooldown:SetCooldown(startTime, duration)
	end

	-- Crafting orders window
	if app.Flag["craftingOrderAssets"] then
		-- Disable tracking for recrafts without a cached recipe
		if app.SelectedRecipe.PlaceOrder.recraft and app.SelectedRecipe.PlaceOrder.recipeID == 0 then
			app.TrackPlaceOrderButton:Disable()
		else
			app.TrackPlaceOrderButton:Enable()
		end

		-- Disable untracking for untracked recipes
		if not ProfessionShoppingList_Data.Recipes[app.SelectedRecipe.PlaceOrder.recipeID] or ProfessionShoppingList_Data.Recipes[app.SelectedRecipe.PlaceOrder.recipeID].quantity == 0 then
			app.UntrackPlaceOrderButton:Disable()
		else
			app.UntrackPlaceOrderButton:Enable()
		end

		-- Remove the personal order entry if the value is ""
		if ProfessionShoppingList_CharacterData.Orders[app.SelectedRecipe.PlaceOrder.recipeID] == "" then
			ProfessionShoppingList_CharacterData.Orders[app.SelectedRecipe.PlaceOrder.recipeID] = nil
		end

		-- Enable the quick order button if recipe is cached and target are known
		if ProfessionShoppingList_Library[app.SelectedRecipe.PlaceOrder.recipeID] and ProfessionShoppingList_CharacterData.Orders[app.SelectedRecipe.PlaceOrder.recipeID] then
			app.QuickOrderButton:Enable()
		else
			app.QuickOrderButton:Disable()
		end

		-- Update the personal order name textbox
		if ProfessionShoppingList_CharacterData.Orders[app.SelectedRecipe.PlaceOrder.recipeID] then
			app.QuickOrderTargetBox:SetText(ProfessionShoppingList_CharacterData.Orders[app.SelectedRecipe.PlaceOrder.recipeID])
		else
			app.QuickOrderTargetBox:SetText("")
		end
	end
end

-- When a tradeskill window is opened
app.Event:Register("TRADE_SKILL_SHOW", function()
	if not UnitAffectingCombat("player") then
		if C_AddOns.IsAddOnLoaded("Blizzard_Professions") then
			app.CreateTradeskillAssets()
		end

		local function getGUID(id, name)
			if not ProfessionShoppingList_Data.Pets[name] then
				for i=1, 9999 do
					local petID, speciesID = C_PetJournal.GetPetInfoByIndex(i)
					if speciesID == id and petID then
						ProfessionShoppingList_Data.Pets[name] = {guid = petID, enabled = true}
						break
					elseif speciesID == nil then
						break
					end
				end
			end
		end

		--ProfessionShoppingList_Data.Pets[name]
		getGUID(297, "ragnaros")
		getGUID(1204, "pierre")
		getGUID(3274, "alvin")

		if app.Flag["tradeskillAssets"] then
			-- Alvin button
			if ProfessionShoppingList_Data.Pets["alvin"] then
				app.AlvinButton:SetAttribute("type1", "macro")
				app.AlvinButton:SetAttribute("macrotext1", "/run C_PetJournal.SummonPetByGUID('" .. ProfessionShoppingList_Data.Pets["alvin"].guid .. "')")
			end

			-- Lil' Ragnaros button
			if ProfessionShoppingList_Data.Pets["ragnaros"] then
				app.RagnarosButton:SetAttribute("type1", "macro")
				app.RagnarosButton:SetAttribute("macrotext1", "/run C_PetJournal.SummonPetByGUID('" .. ProfessionShoppingList_Data.Pets["ragnaros"].guid .. "')")
				app.RagnarosButton:SetAttribute("type2", "macro")
				app.RagnarosButton:SetAttribute("macrotext2", "/run ProfessionShoppingList.SwapCookingPet()")
			end

			-- Pierre button
			if ProfessionShoppingList_Data.Pets["pierre"] then
				app.PierreButton:SetAttribute("type1", "macro")
				app.PierreButton:SetAttribute("macrotext1", "/run C_PetJournal.SummonPetByGUID('" .. ProfessionShoppingList_Data.Pets["pierre"].guid .. "')")
				app.PierreButton:SetAttribute("type2", "macro")
				app.PierreButton:SetAttribute("macrotext2", "/run ProfessionShoppingList.SwapCookingPet()")
			end

			-- Recharge timer
			C_Timer.After(1, function()
				if ProfessionsFrame.CraftingPage.ConcentrationDisplay.Amount:GetText() then
					local concentration = string.match(ProfessionsFrame.CraftingPage.ConcentrationDisplay.Amount:GetText(), "%d+")
				
					if concentration then
						-- 250 Concentration per 24 hours
						local timeLeft = math.ceil((1000 - concentration) / 250 * 24)

						app.Concentration1:SetText("|cffFFFFFF" .. L.RECHARGED .. ":|r " .. timeLeft .. L.HOURS)
						app.Concentration2:SetText("|cffFFFFFF" .. L.RECHARGED .. ":|r " .. timeLeft .. L.HOURS)
					else
						app.Concentration1:SetText("|cffFFFFFF" .. L.RECHARGED .. ":|r ?")
						app.Concentration2:SetText("|cffFFFFFF" .. L.RECHARGED .. ":|r ?")
					end
				end
			end)
		end
	end
end)

function api.SwapCookingPet()
	-- Only do things if there's something to swap
	if ProfessionShoppingList_Data.Pets["ragnaros"] and ProfessionShoppingList_Data.Pets["pierre"] then
		if ProfessionShoppingList_Data.Pets["ragnaros"].enabled then
			ProfessionShoppingList_Data.Pets["ragnaros"].enabled = false
			app.RagnarosButton:Hide()
			ProfessionShoppingList_Data.Pets["pierre"].enabled = true
			app.PierreButton:Show()
		else
			ProfessionShoppingList_Data.Pets["ragnaros"].enabled = true
			app.RagnarosButton:Show()
			ProfessionShoppingList_Data.Pets["pierre"].enabled = false
			app.PierreButton:Hide()
		end
	end
end

-- When a recipe is selected
app.Event:Register("SPELL_DATA_LOAD_RESULT", function(spellID, success)
	if not UnitAffectingCombat("player") then
		-- Recipe-specific assets
		local function recipeAssets()
			if spellID == 444181 then	-- The War Within Thaumaturgy
				app.MillingTheWarWithin:Show()
			else
				app.MillingTheWarWithin:Hide()
			end

			if spellID == 430315 then	-- The War Within Milling
				app.ThaumaturgyTheWarWithin:Show()
			else
				app.ThaumaturgyTheWarWithin:Hide()
			end

			if spellID == 382981 then	-- Dragonflight Milling
				app.MillingDragonflight:Show()
			else
				app.MillingDragonflight:Hide()
			end

			if spellID == 382982 then	-- Shadowlands Milling
				app.MillingShadowlands:Show()
			else
				app.MillingShadowlands:Hide()
			end

			if spellID == 382984 then	-- Battle for Azeroth Milling
				app.MillingBattleForAzeroth:Show()
			else
				app.MillingBattleForAzeroth:Hide()
			end

			if spellID == 382986 then	-- Legion Milling
				app.MillingLegion:Show()
			else
				app.MillingLegion:Hide()
			end

			if spellID == 382987 then	-- Warlords of Draenor Milling
				app.MillingWarlordsOfDraenor:Show()
			else
				app.MillingWarlordsOfDraenor:Hide()
			end

			if spellID == 382988 then	-- Mists of Pandaria Milling
				app.MillingMistsOfPandaria:Show()
			else
				app.MillingMistsOfPandaria:Hide()
			end

			if spellID == 382989 then	-- Cataclysm Milling
				app.MillingCataclysm:Show()
			else
				app.MillingCataclysm:Hide()
			end

			if spellID == 382990 then	-- Wrath of the Lich King Milling
				app.MillingWrathOfTheLichKing:Show()
			else
				app.MillingWrathOfTheLichKing:Hide()
			end

			if spellID == 382991 then	-- The Burning Crusade Milling
				app.MillingTheBurningCrusade:Show()
			else
				app.MillingTheBurningCrusade:Hide()
			end

			if spellID == 382994 then	-- Classic Milling
				app.MillingClassic:Show()
			else
				app.MillingClassic:Hide()
			end

			if app.slLegendaryRecipeIDs[app.SelectedRecipe.Profession.recipeID] then	-- Shadowlands Legendary recipes
				app.ShadowlandsRankText:Show()
				app.ShadowlandsRankBox:Show()
				app.ShadowlandsRankBox:SetText(app.slLegendaryRecipeIDs[app.SelectedRecipe.Profession.recipeID].rank)
			else
				app.ShadowlandsRankText:Hide()
				app.ShadowlandsRankBox:Hide()
			end
		end

		-- Profession buttons
		local function professionButtons()
			-- Show stuff depending on which profession is opened
			local skillLineID = C_TradeSkillUI.GetProfessionChildSkillLineID()
			local professionID = C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID).profession

			-- Cooking Fire and Chef's Hat buttons
			if professionID == 5 then
				if ProfessionShoppingList_Data.Pets["ragnaros"] and ProfessionShoppingList_Data.Pets["ragnaros"].enabled then
					app.RagnarosButton:Show()
				elseif ProfessionShoppingList_Data.Pets["pierre"] and ProfessionShoppingList_Data.Pets["pierre"].enabled then
					app.PierreButton:Show()
				else
					app.CookingFireButton:Show()
				end
				app.ChefsHatButton:Show()
			else
				app.CookingFireButton:Hide()
				app.RagnarosButton:Hide()
				app.PierreButton:Hide()
				app.ChefsHatButton:Hide()
			end

			-- Thermal Anvil button
			if professionID == 1 or professionID == 6 or professionID == 8 then
				app.ThermalAnvilButton:Show()
				app.AlvinButton:Show()
				local _, _, raceID = UnitRace("player")
				if raceID == 30 then
					app.LightforgeButton:Show()
				end
			else
				app.ThermalAnvilButton:Hide()
				app.AlvinButton:Hide()
				app.LightforgeButton:Hide()
			end
		end

		if app.Flag["tradeskillAssets"] then
			recipeAssets()
			professionButtons()
		end
	end
end)

-- When a spell is succesfully cast by the player (for updating profession buttons)
app.Event:Register("UNIT_SPELLCAST_SUCCEEDED", function(unitTarget, castGUID, spellID)
	if not UnitAffectingCombat("player") and unitTarget == "player" then
		-- Profession button stuff
		if spellID == 818 or spellID == 67556 or spellID == 126462 or spellID == 279205 or spellID == 259930 then
			C_Timer.After(0.1, function()
				app.UpdateAssets()
			end)
		end
	end
end)

------------------------
-- RECIPE INFORMATION --
------------------------

-- Register a recipe's information
function app.RegisterRecipe(recipeID)
	-- If there is an output item
	local item = C_TradeSkillUI.GetRecipeOutputItemData(recipeID).itemID
	local _, _, tradeskill = C_TradeSkillUI.GetTradeSkillLineForRecipe(recipeID)
	local ability = C_TradeSkillUI.GetRecipeInfo(recipeID).skillLineAbilityID

	-- Register if the recipe is known
	local recipeLearned = C_TradeSkillUI.GetRecipeInfo(recipeID).learned

	-- Set the itemID to 0 if there is no output item
	if item == nil then
		itemID = 0
	end

	if ProfessionShoppingList_Library[recipeID] then
		ProfessionShoppingList_Library[recipeID].itemID = item
		ProfessionShoppingList_Library[recipeID].abilityID = ability
		ProfessionShoppingList_Library[recipeID].tradeskillID = tradeskill

		if not ProfessionShoppingList_Library[recipeID].learned then
			ProfessionShoppingList_Library[recipeID].learned = recipeLearned
		end
	else
		ProfessionShoppingList_Library[recipeID] = {itemID = item, abilityID = ability, tradeskillID = tradeskill, learned = recipeLearned }
	end
end

-- When a tradeskill window is opened
app.Event:Register("TRADE_SKILL_SHOW", function()
	if not UnitAffectingCombat("player") then
		-- Register all recipes for this profession, on a delay so we give all this info time to load.
		C_Timer.After(2, function()
			for _, recipeID in pairs(C_TradeSkillUI.GetAllRecipeIDs()) do
				app.RegisterRecipe(recipeID)
			end
		end)
	end
end)

function app.CacheItem(itemID, save)
	local item = Item:CreateFromItemID(itemID)
			
	-- And when the item is cached
	if save then
		item:ContinueOnItemLoad(function()
			-- Get item info
			_, itemLink, _, _, _, _, _, _, _, fileID = C_Item.GetItemInfo(itemID)

			-- Write the info to the cache
			ProfessionShoppingList_Cache.Reagents[itemID] = {link = itemLink, icon = fileID}
		end)
	end
end

-- Get reagents for recipe
function app.GetReagents(reagentVariable, recipeID, recipeQuantity, recraft, qualityTier)
	-- Grab all the reagent info from the API
	local reagentsTable

	-- Check to see if it's a crafting order
	local craftingOrder = false
	local craftingRecipeID = recipeID
	if string.sub(recipeID, 1, 6) == "order:" then
		craftingOrder = true
		recipeID = string.match(recipeID, "^order:%d+:(%d+)")
	end

	-- Exception for SL legendary crafts
	if app.slLegendaryRecipeIDs[recipeID] then
		reagentsTable = C_TradeSkillUI.GetRecipeSchematic(recipeID, false, app.slLegendaryRecipeIDs[recipeID].rank).reagentSlotSchematics
	else
		reagentsTable = C_TradeSkillUI.GetRecipeSchematic(recipeID, recraft or false).reagentSlotSchematics
	end

	-- Check which quality to use
	local reagentQuality = qualityTier or ProfessionShoppingList_Settings["reagentQuality"]

	-- For every reagent, do
	for numReagent, reagentInfo in pairs(reagentsTable) do
		-- Only check basic reagents, not optional or finishing reagents
		if reagentInfo.reagentType == 1 then
			-- Get (quality tier 1) info
			local reagentID
			local reagentID1 = reagentInfo.reagents[1].itemID or 0
			local reagentID2 = 0
			local reagentID3 = 0
			local reagentAmount = reagentInfo.quantityRequired

			-- Get quality tier 2 info
			if reagentInfo.reagents[2] then
				reagentID2 = reagentInfo.reagents[2].itemID or 0
			end

			-- Get quality tier 3 info
			if reagentInfo.reagents[3] then
				reagentID3 = reagentInfo.reagents[3].itemID or 0
			end

			-- Adjust the numbers for crafting orders
			if craftingOrder and not ProfessionShoppingList_Data.Recipes[craftingRecipeID].simRecipe then
				for k, v in pairs(ProfessionShoppingList_Cache.FakeRecipes[craftingRecipeID].reagents) do
					if v.reagent.itemID == reagentID1 or v.reagent.itemID == reagentID2 or v.reagent.itemID == reagentID3 then
						reagentAmount = reagentAmount - v.reagent.quantity
					end
				end
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
				app.CacheItem(reagentID, true)
			end

			-- Add the info to the specified variable, if it's not 0 and not a simulated recipe
			if (ProfessionShoppingList_Data.Recipes[craftingRecipeID] and not ProfessionShoppingList_Data.Recipes[craftingRecipeID].simRecipe and reagentAmount > 0) or not ProfessionShoppingList_Data.Recipes[craftingRecipeID] then
				if reagentVariable[reagentID] == nil then reagentVariable[reagentID] = 0 end
				reagentVariable[reagentID] = reagentVariable[reagentID] + ( reagentAmount * recipeQuantity )
			end
		end
	end

	-- Manually insert the reagents if it's a simulated recipe
	if ProfessionShoppingList_Data.Recipes[craftingRecipeID] and ProfessionShoppingList_Data.Recipes[craftingRecipeID].simRecipe then
		for k, v in pairs(ProfessionShoppingList_Cache.SimulatedRecipes[craftingRecipeID]) do
			-- Check if the reagent isn't provided if it's a crafting order
			local providedReagents = {}
			if ProfessionShoppingList_Cache.FakeRecipes[craftingRecipeID] then
				for k, v in pairs(ProfessionShoppingList_Cache.FakeRecipes[craftingRecipeID].reagents) do
					-- Just add all qualities to be thorough, these can't double up within the same recipe anyway
					-- Unless it's a Spark >:(
					if ProfessionShoppingList_Cache.ReagentTiers[v.reagent.itemID] then
						providedReagents[ProfessionShoppingList_Cache.ReagentTiers[v.reagent.itemID].one] = v.reagent.quantity
						providedReagents[ProfessionShoppingList_Cache.ReagentTiers[v.reagent.itemID].two] = v.reagent.quantity
						providedReagents[ProfessionShoppingList_Cache.ReagentTiers[v.reagent.itemID].three] = v.reagent.quantity
					end
				end
			end
			
			if not providedReagents[k] then
				if reagentVariable[k] == nil then reagentVariable[k] = 0 end
				reagentVariable[k] = reagentVariable[k] + (v * ProfessionShoppingList_Data.Recipes[craftingRecipeID].quantity)
			end
		end
	end
end

-- Get owned reagent quantity, accounting for reagent quality
function app.GetReagentCount(reagentID)
	local reagentCount = 0

	-- Index simulated reagents, whose quality is not subject to our quality setting
	local simulatedReagents = {}
	for k, v in pairs(ProfessionShoppingList_Cache.SimulatedRecipes) do
		for k2, v2 in pairs(v) do
			simulatedReagents[k2] = v2
		end
	end

	-- Helper functions
	local function tierThree()
		local reagentCount = C_Item.GetItemCount(ProfessionShoppingList_Cache.ReagentTiers[reagentID].three, true, false, true, app.IncludeWarbank)
		return reagentCount
	end

	local function tierTwo()
		local reagentCount
		if ProfessionShoppingList_Settings["includeHigher"] == 1 then
			reagentCount = math.max(0, C_Item.GetItemCount(ProfessionShoppingList_Cache.ReagentTiers[reagentID].three, true, false, true, app.IncludeWarbank) - (app.ReagentQuantities[ProfessionShoppingList_Cache.ReagentTiers[reagentID].three] or 0)) + C_Item.GetItemCount(ProfessionShoppingList_Cache.ReagentTiers[reagentID].two, true, false, true, app.IncludeWarbank)
		elseif ProfessionShoppingList_Settings["includeHigher"] >= 2 then
			reagentCount = C_Item.GetItemCount(ProfessionShoppingList_Cache.ReagentTiers[reagentID].two, true, false, true, app.IncludeWarbank)
		end
		return reagentCount
	end

	local function tierOne()
		local reagentCount
		if ProfessionShoppingList_Settings["includeHigher"] == 1 then
			reagentCount = math.max(0, (math.max(0, C_Item.GetItemCount(ProfessionShoppingList_Cache.ReagentTiers[reagentID].three, true, false, true, app.IncludeWarbank) - (app.ReagentQuantities[ProfessionShoppingList_Cache.ReagentTiers[reagentID].three] or 0)) + C_Item.GetItemCount(ProfessionShoppingList_Cache.ReagentTiers[reagentID].two, true, false, true, app.IncludeWarbank)) - (app.ReagentQuantities[ProfessionShoppingList_Cache.ReagentTiers[reagentID].two] or 0)) + C_Item.GetItemCount(ProfessionShoppingList_Cache.ReagentTiers[reagentID].one, true, false, true, app.IncludeWarbank)
		elseif ProfessionShoppingList_Settings["includeHigher"] == 2 then
			reagentCount = math.max(0, C_Item.GetItemCount(ProfessionShoppingList_Cache.ReagentTiers[reagentID].two, true, false, true, app.IncludeWarbank) - (app.ReagentQuantities[ProfessionShoppingList_Cache.ReagentTiers[reagentID].two] or 0)) + C_Item.GetItemCount(ProfessionShoppingList_Cache.ReagentTiers[reagentID].one, true, false, true, app.IncludeWarbank)
		elseif ProfessionShoppingList_Settings["includeHigher"] == 3 then
			reagentCount = C_Item.GetItemCount(ProfessionShoppingList_Cache.ReagentTiers[reagentID].one, true, false, true, app.IncludeWarbank)
		end
		return reagentCount
	end

	-- Count the right reagents when it's applicable
	if simulatedReagents[reagentID] then
		if ProfessionShoppingList_Cache.ReagentTiers[reagentID] then
			if ProfessionShoppingList_Cache.ReagentTiers[reagentID].three == reagentID then
				reagentCount = tierThree()
			elseif ProfessionShoppingList_Cache.ReagentTiers[reagentID].two == reagentID then
				reagentCount = tierTwo()
			elseif ProfessionShoppingList_Cache.ReagentTiers[reagentID].one == reagentID then
				reagentCount = tierOne()
			end
		end
	-- Use our addon setting if there is no quality specified
	elseif ProfessionShoppingList_Cache.ReagentTiers[reagentID].three ~= 0 and ProfessionShoppingList_Settings["reagentQuality"] == 3 then
		reagentCount = tierThree()
	elseif ProfessionShoppingList_Cache.ReagentTiers[reagentID].two ~= 0 and ProfessionShoppingList_Settings["reagentQuality"] == 2 then
		reagentCount = tierTwo()
	elseif ProfessionShoppingList_Cache.ReagentTiers[reagentID].one ~= 0 and ProfessionShoppingList_Settings["reagentQuality"] == 1 then
		reagentCount = tierOne()
	-- And use this fallback if nothing even matters anymore
	else
		reagentCount = C_Item.GetItemCount(reagentID, true, false, true, app.IncludeWarbank)
	end

	return reagentCount
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
		if ProfessionShoppingList_Settings["showTooltip"] then
			-- Stop if error, it will try again on its own REAL soon
			if itemID == nil then
				return
			end

			-- Get have/need
			local reagentID1 = 0
			local reagentID2 = 0
			local reagentID3 = 0
			local reagentAmountNeed = 0
			local reagentAmountNeed1 = 0
			local reagentAmountNeed2 = 0
			local reagentAmountNeed3 = 0

			if ProfessionShoppingList_Cache.ReagentTiers[itemID] then
				if ProfessionShoppingList_Cache.ReagentTiers[itemID].one ~= 0 then
					reagentID1 = ProfessionShoppingList_Cache.ReagentTiers[itemID].one
					reagentAmountNeed1 = app.ReagentQuantities[ProfessionShoppingList_Cache.ReagentTiers[itemID].one] or 0
				end
				if ProfessionShoppingList_Cache.ReagentTiers[itemID].two ~= 0 then
					reagentID2 = ProfessionShoppingList_Cache.ReagentTiers[itemID].two
					reagentAmountNeed2 = app.ReagentQuantities[ProfessionShoppingList_Cache.ReagentTiers[itemID].two] or 0
				end
				if ProfessionShoppingList_Cache.ReagentTiers[itemID].three ~= 0 then
					reagentID3 = ProfessionShoppingList_Cache.ReagentTiers[itemID].three
					reagentAmountNeed3 = app.ReagentQuantities[ProfessionShoppingList_Cache.ReagentTiers[itemID].three] or 0
				end
			end
			
			if itemID == reagentID3 then
				reagentAmountNeed = reagentAmountNeed1 + reagentAmountNeed2 + reagentAmountNeed3
			elseif itemID == reagentID2 then
				reagentAmountNeed = reagentAmountNeed1 + reagentAmountNeed2
			elseif itemID == reagentID1 then
				reagentAmountNeed = reagentAmountNeed1
			end		

			-- Add the tooltip info
			local emptyLine = false
			if reagentAmountNeed > 0 then
				local reagentAmountHave = app.GetReagentCount(itemID)
				tooltip:AddLine(" ")
				emptyLine = true
				tooltip:AddLine(app.IconPSL .. " " .. reagentAmountHave .. "/" .. reagentAmountNeed  .. " (" .. math.max(0,reagentAmountNeed-reagentAmountHave)  .. " " .. L.MORE_NEEDED .. ")")
			end

			-- Check for crafting info
			if ProfessionShoppingList_Settings["showCraftTooltip"] then
				for k, v in pairs(ProfessionShoppingList_Library) do
					if type(v) ~= "number" and v.itemID == itemID then	-- No clue why these non-table values are here, tbh
						if emptyLine == false then
							tooltip:AddLine(" ")
						end
						if v.learned and v.tradeskillID then
							tooltip:AddLine(app.IconPSL .. " " .. L.MADE_WITH .. "  " .. app.IconProfession[v.tradeskillID] .. " " .. C_TradeSkillUI.GetTradeSkillDisplayName(v.tradeskillID) .. " (" .. L.RECIPE_LEARNED .. ")")
						elseif v.tradeskillID then
							tooltip:AddLine(app.IconPSL .. " " .. L.MADE_WITH .. "  " .. app.IconProfession[v.tradeskillID] .. " " .. C_TradeSkillUI.GetTradeSkillDisplayName(v.tradeskillID) .. " (" .. L.RECIPE_UNLEARNED .. ")")
						end
						break
					end
				end
			end
		end
	end
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)
end

--------------------------------
-- RECIPE (AND ITEM) TRACKING --
--------------------------------

-- Track recipe
function app.TrackRecipe(recipeID, recipeQuantity, recraft, orderID)
	local originalRecipeID = recipeID

	-- 2 = Salvage, recipes without reagents | Disable these, cause they shouldn't be tracked
	if C_TradeSkillUI.GetRecipeSchematic(recipeID,false).recipeType == 2 or C_TradeSkillUI.GetRecipeSchematic(recipeID,false).reagentSlotSchematics[1] == nil then
		do return end
	end
	
	-- Adjust the recipeID for SL legendary crafts, if a custom rank is entered
	if app.slLegendaryRecipeIDs[recipeID] then
		local rank = math.floor(app.ShadowlandsRankBox:GetNumber())
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
				RunNextFrame(function()
					app.TrackRecipe(recipeID, recipeQuantity, recraft or false, orderID)
					app.Debug("TrackRecipe()")
				end)
				do return end
			end
		-- Exception for stuff like Abominable Stitching
		else
			itemLink = C_TradeSkillUI.GetRecipeSchematic(recipeID,false).name
		end

		-- Exceptions for SL legendary crafts
		if app.slLegendaryRecipeIDs[recipeID] then
			itemLink = itemLink .. " (" ..  L.RANK .. " " .. app.slLegendaryRecipeIDs[recipeID].rank .. ")" -- Append the rank
		else
			itemLink = string.gsub(itemLink, " |A:Professions%-ChatIcon%-Quality%-Tier1:17:15::1|a", "") -- Remove the quality from the item string
		end

		-- Add quantity
		if recipeMin == recipeMax and recipeMin ~= 1 then
			itemLink = itemLink .. " ×" .. recipeMin
		elseif recipeMin ~= 1 then
			itemLink = itemLink .. " ×" .. recipeMin .. "-" .. recipeMax
		end

		recipeLink = itemLink

	-- Add recipe "link" for enchants
	elseif recipeType == 3 then recipeLink = C_TradeSkillUI.GetRecipeSchematic(recipeID,false).name
	end

	-- Order recipes
	if orderID then
		-- Process Patron Orders
		local ordersTable = C_CraftingOrders.GetCrafterOrders()
		local reagents = {}
		local key
		
		for i, orderInfo in pairs(ordersTable) do
			if orderID == orderInfo.orderID then
				key = "order:" .. orderID .. ":" .. recipeID

				ProfessionShoppingList_Cache.FakeRecipes[key] = {
					["spellID"] = recipeID,
					["tradeskillID"] = 1,	-- Crafting order
					["reagents"] = orderInfo.reagents
				}

				recipeID = key
			end
		end

		-- Process Personal/Guild Orders
		if not ProfessionShoppingList_Cache.FakeRecipes[key] then
			key = "order:" .. orderID .. ":" .. recipeID

			ProfessionShoppingList_Cache.FakeRecipes[key] = {
				["spellID"] = recipeID,
				["tradeskillID"] = 1,	-- Crafting order
				["reagents"] = app.SelectedRecipe.MakeOrder.reagents
			}

			recipeID = key
		end
	end

	-- List custom reagents for simulated recipes
	local simRecipe = false
	if app.SimCount() == 1 then
		if C_AddOns.IsAddOnLoaded("CraftSim") and CraftSimAPI.GetCraftSim().SIMULATION_MODE.isActive then
			simRecipe = true
			
			-- Grab the reagents it provides
			local simulatedSimulationMode = CraftSimAPI.GetCraftSim().SIMULATION_MODE
			simulatedRequiredReagents = simulatedSimulationMode.recipeData.reagentData.requiredReagents
	
			if simulatedRequiredReagents then
				local reagents = {}
				for k, v in pairs(simulatedRequiredReagents) do
					-- For reagents without quality
					if not v.hasQuality then
						reagents[v.items[1].item.itemID] = v.requiredQuantity
					-- For reagents with quality
					else
						for k2, v2 in pairs(v.items) do
							if v2.quantity > 0 then
								reagents[v2.item.itemID] = v2.quantity
							end
						end
					end
				end
	
				-- Save the reagents into a fake recipe
				ProfessionShoppingList_Cache.SimulatedRecipes[recipeID] = reagents
			else
				app.Print(L.ERROR_CRAFTSIM)
			end
		elseif C_AddOns.IsAddOnLoaded("TestFlight") then
			-- Let the game track the recipe temporarily, so we can grab TestFlight's info
			app.Flag["trackingRecipes"] = true
			C_TradeSkillUI.SetRecipeTracked(originalRecipeID, true, recraft or false)

			-- Save the reagents into a fake recipe
			simRecipe = true
			ProfessionShoppingList_Cache.SimulatedRecipes[recipeID] = TestFlight.Reagents:GetTrackedBySource()

			-- Untrack the recipe from the game
			C_TradeSkillUI.SetRecipeTracked(originalRecipeID, false, recraft or false)
			app.Flag["trackingRecipes"] = false
		end
	elseif app.SimCount() > 1 then
		local addons = ""
		for k, v in pairs(app.SimAddOns) do
			if k > 1 then
				addons = addons .. ", "
			end
			addons = addons .. v
		end
		app.Print(L.ERROR_MULTISIM, addons)
	end

	-- Track recipe
	if not ProfessionShoppingList_Data.Recipes[recipeID] then
		ProfessionShoppingList_Data.Recipes[recipeID] = { quantity = 0, recraft = recraft or false, link = recipeLink, simRecipe = simRecipe }
	end
	ProfessionShoppingList_Data.Recipes[recipeID].quantity = ProfessionShoppingList_Data.Recipes[recipeID].quantity + recipeQuantity

	-- Show window
	app.Show()	-- This also triggers the recipe update
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
			ProfessionShoppingList_Cache.SimulatedRecipes[recipeID] = nil
		end
	end

	-- Clear the cache if no recipes are tracked anymore
	local next = next
	if next(ProfessionShoppingList_Data.Recipes) == nil then app.Clear() end

	-- Update numbers
	app.UpdateRecipes()
end

-- Clear everything except the recipe cache
function app.Clear()
	ProfessionShoppingList_Data.Recipes = {}
	ProfessionShoppingList_Cache.ReagentTiers = {}
	ProfessionShoppingList_Cache.Reagents = {}
	ProfessionShoppingList_Cache.FakeRecipes = {}
	ProfessionShoppingList_Cache.SimulatedRecipes = {}
	app.UpdateRecipes()
	app.Window.ScrollFrame:SetVerticalScroll(0)

	-- Disable remove button
	if app.Flag["tradeskillAssets"] then
		app.UntrackProfessionButton:Disable()
		app.TrackMakeOrderButton:SetText(L.TRACK)
		app.TrackMakeOrderButton:SetWidth(app.TrackMakeOrderButton:GetTextWidth()+20)
	end
	if app.Flag["craftingOrderAssets"] then
		app.UntrackPlaceOrderButton:Disable()
	end
	-- Set the quantity box to 0
	if app.RecipeQuantityBox then
		app.RecipeQuantityBox:SetText("0")
	end
end

-- Replace the in-game tracking of shift+clicking a recipe with PSL's
app.Event:Register("TRACKED_RECIPE_UPDATE", function(recipeID, tracked)
	if not app.Flag["trackingRecipes"] and tracked then
		app.TrackRecipe(recipeID, 1)
		C_TradeSkillUI.SetRecipeTracked(recipeID, false, false)
		C_TradeSkillUI.SetRecipeTracked(recipeID, false, true)
	end
end)

-- When a recipe is selected in the tradeskillUI
EventRegistry:RegisterCallback("ProfessionsRecipeListMixin.Event.OnRecipeSelected", function(_, recipeInfo)
	app.SelectedRecipe.Profession = { recipeID = recipeInfo["recipeID"], recraft = recipeInfo["isRecraft"], recipeType = C_TradeSkillUI.GetRecipeSchematic(recipeInfo["recipeID"],false).recipeType }
	app.UpdateAssets()
end)

-- When a vendor window is opened
app.Event:Register("MERCHANT_SHOW", function()
	-- When the user Alt+clicks a vendor item
	local function TrackMerchantItem()
		if IsAltKeyDown() then
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
			local key = "vendor:" .. merchant .. ":" .. itemID
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
					icon = app.IconProfession[0],
					link = L.GOLD,
				}
			end

			-- Get the different currencies needed to purchase the item
			for i=1, GetMerchantItemCostInfo(vendorIndex), 1 do
				local itemTexture, itemValue, itemLink, currencyName = GetMerchantItemCostItem(vendorIndex, i)
				if currencyName and itemLink then
					local currencyID = C_CurrencyInfo.GetCurrencyIDFromLink(itemLink)

					ProfessionShoppingList_Cache.FakeRecipes[key].costCurrency[currencyID] = itemValue
					ProfessionShoppingList_Cache.Reagents["currency:" .. currencyID] = { 
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
			local itemButton = _G["MerchantItem" .. i .. "ItemButton"]
			if itemButton then
				itemButton:HookScript("OnClick", function() TrackMerchantItem() end)
			end
		end

		-- Set the flag to true so it doesn't trigger again
		app.Flag["merchantAssets"] = true
	end
end)

-- When a spell is succesfully cast by the player (for  removing crafted recipes)
app.Event:Register("UNIT_SPELLCAST_SUCCEEDED", function(unitTarget, castGUID, spellID)
	if not UnitAffectingCombat("player") and unitTarget == "player" then
		-- Run only when crafting a tracked recipe, and if the remove craft option is enabled
		if ProfessionShoppingList_Data.Recipes[spellID] and ProfessionShoppingList_Settings["removeCraft"] then
			-- Remove 1 tracked recipe when it has been crafted (if the option is enabled)
			app.UntrackRecipe(spellID, 1)
			
			-- Close window if no recipes are left and the option is enabled
			local next = next
			if #ProfessionShoppingList_Data.Recipes < 1 and ProfessionShoppingList_Settings["closeWhenDone"] then
				app.Window:Hide()
			end
		end
	end
end)

-- Count how many supported sim addons are enabled
function app.SimCount()
	local addonCount = 0

	for k, v in pairs(app.SimAddOns) do
		if C_AddOns.IsAddOnLoaded(v) then
			addonCount = addonCount + 1
		end
	end

	return addonCount
end

-----------------------
-- COOLDOWN TRACKING --
-----------------------

-- When the user encounters a loading screen
app.Event:Register("PLAYER_ENTERING_WORLD", function(isInitialLogin, isReloadingUi)
	-- Only on initialLoad
	if isInitialLogin then
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
						ProfessionShoppingList_Data.Cooldowns[k].cooldown = C_DateAndTime.GetSecondsUntilDailyReset()
					end
				end

				-- If the option to show recipe cooldowns is enabled and all charges are full (or 0 = 0 for recipes without charges)
				if ProfessionShoppingList_Settings["showRecipeCooldowns"] and ProfessionShoppingList_Data.Cooldowns[k].charges == ProfessionShoppingList_Data.Cooldowns[k].maxCharges then
					-- Show the reminder
					app.Print(recipeInfo.name .. " " .. L.READY_TO_CRAFT .. " " .. recipeInfo.user .. ".")
				end
			end
		end
	end
end)

-- When a spell is succesfully cast by the player
app.Event:Register("UNIT_SPELLCAST_SUCCEEDED", function(unitTarget, castGUID, spellID)
	if not UnitAffectingCombat("player") and unitTarget == "player" then	
		-- Run only when the spell cast is a known recipe
		if ProfessionShoppingList_Library[spellID] then
			-- With a delay due to how quickly that info is updated after UNIT_SPELLCAST_SUCCEEDED
			C_Timer.After(0.1, function()
				-- Get character info
				local character = UnitName("player")
				local realm = GetNormalizedRealmName()

				-- Get spell cooldown info
				local recipeName = C_TradeSkillUI.GetRecipeSchematic(spellID, false).name
				local cooldown, isDayCooldown, charges, maxCharges = C_TradeSkillUI.GetRecipeCooldown(spellID)	-- For daily cooldowns, 'cooldown' returns the time until midnight, after relogging it's accurate. 'isDayCooldown' can be used to identify if it should be aligned with daily reset right away.
				local recipeStart = GetServerTime()

				-- Remove shared cooldowns and only leave the last one done
				-- TODO: Make this a database thing and create the sets of shared cooldowns
				local function sharedCooldowns(spells)
					for k, v in pairs(spells) do
						if v ~= spellID then
							for k2, v2 in pairs(ProfessionShoppingList_Data.Cooldowns) do
								if v2.recipeID == v and v2.user == character .. "-" .. realm then
									table.remove(ProfessionShoppingList_Data.Cooldowns, k2)
								end
							end
						end
					end
				end

				-- Set timer to 7 days for the Alchemy sac transmutes
				if spellID == 213256 or spellID == 251808 then
					cooldown = 7 * 24 * 60 * 60
				-- Shared cooldowns for Dragonflight Alchemy experimentations
				elseif spellID == 370743 or spellID == 370745 or spellID == 370746 or spellID == 370747 then
					local spells = {370743,  370745, 370746, 370747}
					sharedCooldowns(spells)
				-- Shared cooldowns for The War Within Alchemy experimentations
				elseif spellID == 427174 or spellID == 430345 then
					local spells = {427174,  430345}
					sharedCooldowns(spells)
				-- Daily cooldowns (which return the wrong 'cooldown' info initially)
				elseif isDayCooldown then
					-- Set the cooldown to align with daily reset
					cooldown = C_DateAndTime.GetSecondsUntilDailyReset()
				end

				-- If the spell cooldown exists
				if cooldown then
					-- Fix the cooldown table if necessary
					ProfessionShoppingList_Data.Cooldowns = app.FixTable(ProfessionShoppingList_Data.Cooldowns)

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
	end
end)

-------------------------
-- TRACK UNLEARNED MOG --
-------------------------

-- Scan the tooltip for the appearance text, localised
function app.GetAppearanceInfo(itemLinkie, searchString)
	-- Grab the original value for this setting
	local cvar = C_CVar.GetCVarInfo("missingTransmogSourceInItemTooltips")
	
	-- Enable this CVar, because we need it
	C_CVar.SetCVar("missingTransmogSourceInItemTooltips", 1)

	-- Get our tooltip information
	local tooltip = C_TooltipInfo.GetHyperlink(itemLinkie)

	-- Return the CVar to its original setting
	C_CVar.SetCVar("missingTransmogSourceInItemTooltips", cvar)

	-- Read all the lines as plain text
	if tooltip["lines"] then
		for k, v in ipairs(tooltip["lines"]) do
			-- And if the transmog text line was found
			if v["leftText"] and v["leftText"]:find(searchString) then
				return true
			end
		end
	end

	-- Otherwise
	return false
end

-- Get all visible recipes
function app.GetVisibleRecipes(targetTable)
	-- If no table is provided, create a new one
	targetTable = targetTable or {}

	local skillLineID = C_TradeSkillUI.GetProfessionChildSkillLineID()
	local targetTable = C_TradeSkillUI.GetFilteredRecipeIDs()
	-- If we're not searching for any recipes
	if C_TradeSkillUI.GetRecipeItemNameFilter() == "" then
		for k = #targetTable, 1, -1 do
			-- If the recipe is NYI, or does not belong to our currently visible expansion
			if app.nyiRecipes[k] or not C_TradeSkillUI.IsRecipeInSkillLine(targetTable[k], skillLineID) then
				-- Remove it
				table.remove(targetTable, k)
			end
		end
	end

	return targetTable
end

function app.TrackUnlearnedMog()
	-- Set the update handler to active, to prevent multiple list updates from freezing the game
	app.Flag["changingRecipes"] = true

	local recipes = app.GetVisibleRecipes()

	-- Start a count
	local added = 0

	for i, recipeID in pairs(recipes) do
		-- Grab the output itemID
		local itemID = C_TradeSkillUI.GetRecipeSchematic(recipeID, false).outputItemID

		-- Cache the item, if there is an output item
		if itemID then
			local item = Item:CreateFromItemID(itemID)

			-- And when the item is cached
			item:ContinueOnItemLoad(function()
				-- Get item link
				local _, itemLink = C_Item.GetItemInfo(itemID)

				-- If the appearance is unlearned, track the recipe (taking our collection mode into account)
				if app.GetAppearanceInfo(itemLink, TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN)
				or (ProfessionShoppingList_Settings["collectMode"] == 2 and app.GetAppearanceInfo(itemLink, TRANSMOGRIFY_TOOLTIP_ITEM_UNKNOWN_APPEARANCE_KNOWN)) then
					app.TrackRecipe(recipeID, 1)
					added = added + 1
				end

				-- If this is our last iteration, set update handler to false and force an update, and let the user know what we did
				if i == #recipes then
					app.Flag["changingRecipes"] = false
					app.UpdateRecipes()
					app.Print(L.ADDED_RECIPES1 .. " " .. added .. " " .. L.ADDED_RECIPES2 .. ".")
				end
			end)
		end
	end
end

--------------
-- SETTINGS --
--------------

-- Open settings
function app.OpenSettings()
	Settings.OpenToCategory(app.Category:GetID())
end

-- AddOn Compartment click
function ProfessionShoppingList_Click(self, button)
	if button == "LeftButton" then
		app.Toggle()
	elseif button == "RightButton" then
		app.OpenSettings()
	end
end

-- AddOn Compartment enter
function ProfessionShoppingList_Enter(self, button)
	GameTooltip:ClearLines()
	GameTooltip:SetOwner(type(self) ~= "string" and self or button, "ANCHOR_LEFT")
	GameTooltip:AddLine(app.NameLong .. "\n" .. L.SETTINGS_TOOLTIP)
	GameTooltip:Show()
end

-- AddOn Compartment leave
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
			tooltip:AddLine(app.NameLong .. "\n" .. L.SETTINGS_TOOLTIP)
		end,
	})
	
	local icon = LibStub("LibDBIcon-1.0", true)
	icon:Register("ProfessionShoppingList", miniButton, ProfessionShoppingList_Settings)

	if ProfessionShoppingList_Settings["minimapIcon"] then
		ProfessionShoppingList_Settings["hide"] = false
		icon:Show("ProfessionShoppingList")
	else
		ProfessionShoppingList_Settings["hide"] = true
		icon:Hide("ProfessionShoppingList")
	end

	-- Settings page
	local category, layout = Settings.RegisterVerticalLayoutCategory(app.NameLong)
	Settings.RegisterAddOnCategory(category)
	app.Category = category

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(C_AddOns.GetAddOnMetadata(appName, "Version")))

	local variable, name, tooltip = "minimapIcon", L.SETTINGS_MINIMAP_TITLE, L.SETTINGS_MINIMAP_TOOLTIP
	local setting = Settings.RegisterAddOnSetting(category, appName .. "_" .. variable, variable, ProfessionShoppingList_Settings, Settings.VarType.Boolean, name, true)
	Settings.CreateCheckbox(category, setting, tooltip)
	setting:SetValueChangedCallback(function()
		if ProfessionShoppingList_Settings["minimapIcon"] then
			ProfessionShoppingList_Settings["hide"] = false
			icon:Show("ProfessionShoppingList")
		else
			ProfessionShoppingList_Settings["hide"] = true
			icon:Hide("ProfessionShoppingList")
		end
	end)

	local variable, name, tooltip = "showRecipeCooldowns", L.SETTINGS_COOLDOWNS_TITLE, L.SETTINGS_COOLDOWNS_TOOLTIP
	local setting = Settings.RegisterAddOnSetting(category, appName .. "_" .. variable, variable, ProfessionShoppingList_Settings, Settings.VarType.Boolean, name, true)
	Settings.CreateCheckbox(category, setting, tooltip)
	setting:SetValueChangedCallback(function()
		app.UpdateRecipes()
	end)

	local variable, name, tooltip = "showTooltip", L.SETTINGS_TOOLTIP_TITLE, L.SETTINGS_TOOLTIP_TOOLTIP
	local setting = Settings.RegisterAddOnSetting(category, appName .. "_" .. variable, variable, ProfessionShoppingList_Settings, Settings.VarType.Boolean, name, true)
	local parentSetting = Settings.CreateCheckbox(category, setting, tooltip)

	local variable, name, tooltip = "showCraftTooltip", L.SETTINGS_CRAFTTOOLTIP_TITLE, L.SETTINGS_CRAFTTOOLTIP_TOOLTIP
	local setting = Settings.RegisterAddOnSetting(category, appName .. "_" .. variable, variable, ProfessionShoppingList_Settings, Settings.VarType.Boolean, name, true)
	local subSetting = Settings.CreateCheckbox(category, setting, tooltip)
	subSetting:SetParentInitializer(parentSetting, function() return ProfessionShoppingList_Settings["showTooltip"] end)

	local variable, name, tooltip = "reagentQuality", L.SETTINGS_REAGENTQUALITY_TITLE, L.SETTINGS_REAGENTQUALITY_TOOLTIP
	local function GetOptions()
		local container = Settings.CreateControlTextContainer()
		container:Add(1, "|A:Professions-ChatIcon-Quality-Tier1:17:15::1|a" .. L.SETTINGS_REAGENTTIER .. " 1")
		container:Add(2, "|A:Professions-ChatIcon-Quality-Tier2:17:15::1|a" .. L.SETTINGS_REAGENTTIER .. " 2")
		container:Add(3, "|A:Professions-ChatIcon-Quality-Tier3:17:15::1|a" .. L.SETTINGS_REAGENTTIER .. " 3")
		return container:GetData()
	end
	local setting = Settings.RegisterAddOnSetting(category, appName .. "_" .. variable, variable, ProfessionShoppingList_Settings, Settings.VarType.Number, name, 1)
	Settings.CreateDropdown(category, setting, GetOptions, tooltip)
	setting:SetValueChangedCallback(function()
		C_Timer.After(0.5, function() app.UpdateRecipes() end) -- Toggling this setting seems buggy? This fixes it. :)
	end)

	local variable, name, tooltip = "includeHigher", L.SETTINGS_INCLUDEHIGHER_TITLE, L.SETTINGS_INCLUDEHIGHER_TOOLTIP
	local function GetOptions()
		local container = Settings.CreateControlTextContainer()
		container:Add(1, L.SETTINGS_INCLUDE .. "|A:Professions-ChatIcon-Quality-Tier3:17:15::1|a " .. L.SETTINGS_REAGENTTIER .. " 3 & " ..  "|A:Professions-ChatIcon-Quality-Tier2:17:15::1|a " .. L.SETTINGS_REAGENTTIER .. " 2")
		container:Add(2, L.SETTINGS_ONLY_INCLUDE .. " |A:Professions-ChatIcon-Quality-Tier2:17:15::1|a " .. L.SETTINGS_REAGENTTIER .. " 2")
		container:Add(3, L.SETTINGS_DONT_INCLUDE)
		return container:GetData()
	end
	local setting = Settings.RegisterAddOnSetting(category, appName .. "_" .. variable, variable, ProfessionShoppingList_Settings, Settings.VarType.Number, name, 1)
	Settings.CreateDropdown(category, setting, GetOptions, tooltip)
	setting:SetValueChangedCallback(function()
		C_Timer.After(0.5, function() app.UpdateRecipes() end) -- Toggling this setting seems buggy? This fixes it. :)
	end)

	local variable, name, tooltip = "collectMode", L.SETTINGS_COLLECTMODE_TITLE, L.SETTINGS_COLLECTMODE_TOOLTIP
	local function GetOptions()
		local container = Settings.CreateControlTextContainer()
		container:Add(1, L.SETTINGS_APPEARANCES_TITLE, L.SETTINGS_APPEARANCES_TEXT)
		container:Add(2, L.SETTINGS_SOURCES_TITLE, L.SETTINGS_SOURCES_TEXT)
		return container:GetData()
	end
	local setting = Settings.RegisterAddOnSetting(category, appName .. "_" .. variable, variable, ProfessionShoppingList_Settings, Settings.VarType.Number, name, 1)
	Settings.CreateDropdown(category, setting, GetOptions, tooltip)

	local variable, name, tooltip = "quickOrderDuration", L.SETTINGS_QUICKORDER_TITLE, L.SETTINGS_QUICKORDER_TOOLTIP
	local function GetOptions()
		local container = Settings.CreateControlTextContainer()
		container:Add(0, L.SETTINGS_DURATION_SHORT)
		container:Add(1, L.SETTINGS_DURATION_MEDIUM)
		container:Add(2, L.SETTINGS_DURATION_LONG)
		return container:GetData()
	end
	local setting = Settings.RegisterAddOnSetting(category, appName .. "_" .. variable, variable, ProfessionShoppingList_Settings, Settings.VarType.Number, name, 0)
	Settings.CreateDropdown(category, setting, GetOptions, tooltip)

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.SETTINGS_HEADER_TRACK))

	local variable, name, tooltip = "pcWindows", L.SETTINGS_PERSONALWINDOWS_TITLE, L.SETTINGS_PERSONALWINDOWS_TOOLTIP
	local setting = Settings.RegisterAddOnSetting(category, appName .. "_" .. variable, variable, ProfessionShoppingList_Settings, Settings.VarType.Boolean, name, false)
	Settings.CreateCheckbox(category, setting, tooltip)

	local variable, name, tooltip = "pcRecipes", L.SETTINGS_PERSONALRECIPES_TITLE, L.SETTINGS_PERSONALRECIPES_TOOLTIP
	local setting = Settings.RegisterAddOnSetting(category, appName .. "_" .. variable, variable, ProfessionShoppingList_Settings, Settings.VarType.Boolean, name, false)
	Settings.CreateCheckbox(category, setting, tooltip)
	setting:SetValueChangedCallback(function()
		app.UpdateRecipes()
	end)

	local variable, name, tooltip = "showRemaining", L.SETTINGS_SHOWREMAINING_TITLE, L.SETTINGS_SHOWREMAINING_TOOLTIP
	local setting = Settings.RegisterAddOnSetting(category, appName .. "_" .. variable, variable, ProfessionShoppingList_Settings, Settings.VarType.Boolean, name, false)
	Settings.CreateCheckbox(category, setting, tooltip)
	setting:SetValueChangedCallback(function()
		C_Timer.After(0.5, function() app.UpdateRecipes() end) -- Toggling this setting seems buggy? This fixes it. :)
	end)

	local variable, name, tooltip = "removeCraft", L.SETTINGS_REMOVECRAFT_TITLE, L.SETTINGS_REMOVECRAFT_TOOLTIP
	local setting = Settings.RegisterAddOnSetting(category, appName .. "_" .. variable, variable, ProfessionShoppingList_Settings, Settings.VarType.Boolean, name, true)
	local parentSetting = Settings.CreateCheckbox(category, setting, tooltip)

	local variable, name, tooltip = "closeWhenDone", L.SETTINGS_CLOSEWHENDONE_TITLE, L.SETTINGS_CLOSEWHENDONE_TOOLTIP
	local setting = Settings.RegisterAddOnSetting(category, appName .. "_" .. variable, variable, ProfessionShoppingList_Settings, Settings.VarType.Boolean, name, false)
	local subSetting = Settings.CreateCheckbox(category, setting, tooltip)
	subSetting:SetParentInitializer(parentSetting, function() return ProfessionShoppingList_Settings["removeCraft"] end)

	layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L.SETTINGS_HEADER_INFO))

	local variable, name, tooltip = "", L.SETTINGS_SLASHCOMMANDS_TITLE, L.SETTINGS_SLASHCOMMANDS_TOOLTIP
	local function GetOptions()
		local container = Settings.CreateControlTextContainer()
		container:Add(1, "/psl", L.SETTINGS_SLASH_TOGGLE)
		container:Add(2, "/psl resetpos", L.SETTINGS_SLASH_RESETPOS)
		container:Add(3, "/psl settings", L.SETTINGS_SLASH_SETTINGS)
		container:Add(4, "/psl clear", L.WINDOW_BUTTON_CLEAR)
		container:Add(5, "/psl track " .. app.Colour(L.SETTINGS_SLASH_RECIPEID .. " " .. L.SETTINGS_SLASH_QUANTITY), L.SETTINGS_SLASH_TRACK)
		container:Add(6, "/psl untrack " .. app.Colour(L.SETTINGS_SLASH_RECIPEID .. " " .. L.SETTINGS_SLASH_QUANTITY), L.SETTINGS_SLASH_UNTRACK)
		container:Add(7, "/psl untrack " .. app.Colour(L.SETTINGS_SLASH_RECIPEID) .. " all", L.SETTINGS_SLASH_UNTRACKALL)
		container:Add(8, "/psl " .. app.Colour("[" .. L.SETTINGS_SLASH_CRAFTINGACHIE .. "]"), L.SETTINGS_SLASH_TRACKACHIE)
		return container:GetData()
	end
	local setting = Settings.RegisterAddOnSetting(category, appName .. "_" .. variable, variable, ProfessionShoppingList_Settings, Settings.VarType.Number, name, 1)
	Settings.CreateDropdown(category, setting, GetOptions, tooltip)
end

-----------------
-- ADDON COMMS --
-----------------

-- Send information to other PSL users
function app.SendAddonMessage(message)
	-- Check which channel to use
	if IsInRaid(2) or IsInGroup(2) then
		-- Share with instance group first
		ChatThrottleLib:SendAddonMessage("NORMAL", "ProfShopList", message, "INSTANCE_CHAT")
	elseif IsInRaid() then
		-- If not in an instance group, share it with the raid
		ChatThrottleLib:SendAddonMessage("NORMAL", "ProfShopList", message, "RAID")
	elseif IsInGroup() then
		-- If not in a raid group, share it with the party
		ChatThrottleLib:SendAddonMessage("NORMAL", "ProfShopList", message, "PARTY")
	end
end

-- When joining a group
app.Event:Register("GROUP_ROSTER_UPDATE", function(category, partyGUID)
	-- Share our AddOn version with other users
	local message = "version:" .. C_AddOns.GetAddOnMetadata("ProfessionShoppingList", "Version")
	app.SendAddonMessage(message)
end)

-- When we receive information over the addon comms
app.Event:Register("CHAT_MSG_ADDON", function(prefix, text, channel, sender, target, zoneChannelID, localID, name, instanceID)
	-- If it's our message
	if prefix == "ProfShopList" then
		-- Version
		local version = text:match("version:(.+)")
		if version then
			if version ~= "@project-version@" then
				-- Extract the interface and version from this
				local expansion, major, minor, iteration = version:match("v(%d+)%.(%d+)%.(%d+)%-(%d%d%d)")
				expansion = string.format("%02d", expansion)
				major = string.format("%02d", major)
				minor = string.format("%02d", minor)
				local otherGameVersion = tonumber(expansion .. major .. minor)
				local otherAddonVersion = tonumber(iteration)

				-- Do the same for our local version
				local localVersion = C_AddOns.GetAddOnMetadata("ProfessionShoppingList", "Version")
				if localVersion ~= "@project-version@" then
					expansion, major, minor, iteration = localVersion:match("v(%d+)%.(%d+)%.(%d+)%-(%d%d%d)")
					expansion = string.format("%02d", expansion)
					major = string.format("%02d", major)
					minor = string.format("%02d", minor)
					local localGameVersion = tonumber(expansion .. major .. minor)
					local localAddonVersion = tonumber(iteration)

					-- Now compare our versions
					if otherGameVersion > localGameVersion or (otherGameVersion == localGameVersion and otherAddonVersion > localAddonVersion) then
						-- But only send the message once every 10 minutes
						if GetServerTime() - app.Flag["versionCheck"] > 600 then
							app.Print(L.VERSION_CHECK .. ": " .. version)
							app.Flag["versionCheck"] = GetServerTime()
						end
					end
				end
			end
		end
	end
end)