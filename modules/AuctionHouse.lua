------------------------------------------------
-- Profession Shopping List: AuctionHouse.lua --
------------------------------------------------
-- Auction House module

-- Initialisation
local appName, app =  ...	-- Returns the AddOn name and a unique table
local L = app.locales

------------------
-- INITIAL LOAD --
------------------

app.Event:Register("ADDON_LOADED", function(addOnName, containsBindings)
	if addOnName == appName then
		app.Flag["openAH"] = false
		app.CreateAuctionatorButton()
	end
end)

-----------------
-- LINK SEARCH --
-----------------

app.Event:Register("AUCTION_HOUSE_SHOW", function(addOnName, containsBindings)
	app.Flag["openAH"] = true
end)

app.Event:Register("AUCTION_HOUSE_CLOSED", function(addOnName, containsBindings)
	app.Flag["openAH"] = false
end)

function app.SearchAH(itemLink)
	if app.Flag["openAH"] then
		local query = { sorts = { sortOrder = Enum.AuctionHouseSortOrder.Price, reverseSort = false }, filters = {}, searchString = C_Item.GetItemInfo(itemLink) }
		C_AuctionHouse.SendBrowseQuery(query)
	end
end

------------------------
-- AUCTIONATOR IMPORT --
------------------------

-- Button
function app.CreateAuctionatorButton()
	-- Auctionator button
	app.AuctionatorButton = CreateFrame("Button", "pslOptionAuctionatorButton", app.Window, "UIPanelCloseButton")
	app.AuctionatorButton:SetPoint("TOPRIGHT", app.ClearButton, "TOPLEFT", -2, 0)
	app.AuctionatorButton:SetNormalTexture("Interface\\AddOns\\ProfessionShoppingList\\assets\\buttons.blp")
	app.AuctionatorButton:GetNormalTexture():SetTexCoord(219/256, 255/256, 1/128, 39/128)
	app.AuctionatorButton:SetDisabledTexture("Interface\\AddOns\\ProfessionShoppingList\\assets\\buttons.blp")
	app.AuctionatorButton:GetDisabledTexture():SetTexCoord(219/256, 255/256, 41/128, 79/128)
	app.AuctionatorButton:SetPushedTexture("Interface\\AddOns\\ProfessionShoppingList\\assets\\buttons.blp")
	app.AuctionatorButton:GetPushedTexture():SetTexCoord(219/256, 255/256, 81/128, 119/128)
	app.AuctionatorButton:SetScript("OnClick", function()
		app.UpdateRecipes()
		-- Add a delay because I have no idea how to optimise my AddOn
		C_Timer.After(0.5, function()
			local function makeShoppingList()
				local searchStrings = {}

				for reagentID, reagentAmount in pairs(app.ReagentQuantities) do
					-- Ignore tracked gold and currency costs
					if type(reagentID) == "number" then
						-- Cache item
						if not ProfessionShoppingList_Cache.ReagentTiers[reagentID] then
							app.CacheItem(reagentID)
						end

						if not C_Item.IsItemDataCachedByID(reagentID) then
							app.Debug("makeShoppingList(" .. reagentID .. ")")
			
							C_Item.RequestLoadItemDataByID(reagentID)
							local item = Item:CreateFromItemID(reagentID)
							
							item:ContinueOnItemLoad(function()
								makeShoppingList()
							end)
			
							return
						end
						
						-- Get item info
						local itemName = C_Item.GetItemInfo(reagentID)

						-- Index simulated reagents, whose quality is not subject to our quality setting
						local simulatedReagents = {}
						for k, v in pairs(ProfessionShoppingList_Cache.SimulatedRecipes) do
							for k2, v2 in pairs(v) do
								simulatedReagents[k2] = v2
							end
						end

						-- Set reagent quality to 2 or 3 if applicable and the user has this set, otherwise don't specify quality
						local reagentQuality = ""

						if simulatedReagents[reagentID] then
							if ProfessionShoppingList_Cache.ReagentTiers[reagentID].three == reagentID then
								reagentQuality = 3
							elseif ProfessionShoppingList_Cache.ReagentTiers[reagentID].two == reagentID then
								reagentQuality = 2
							end
						elseif ProfessionShoppingList_Cache.ReagentTiers[reagentID].three ~= 0 and ProfessionShoppingList_Settings["reagentQuality"] == 3 then
							reagentQuality = 3
						elseif ProfessionShoppingList_Cache.ReagentTiers[reagentID].two ~= 0 and ProfessionShoppingList_Settings["reagentQuality"] == 2 then
							reagentQuality = 2
						end

						-- Calculate how many we still need
						local reagentCount = app.GetReagentCount(reagentID)
						reagentCount = math.max(0, reagentAmount - reagentCount)

						-- But make it zero if it's a subreagent
						for k, v in pairs(ProfessionShoppingList_Data.Recipes) do
							if ProfessionShoppingList_Library[k] and ProfessionShoppingList_Library[k].itemID == reagentID then
								reagentCount = 0
							end
						end

						-- Put the items in the temporary variable
						if reagentCount > 0 then
							table.insert(searchStrings, Auctionator.API.v1.ConvertToSearchString(app.Name, { searchString = itemName, isExact = true, categoryKey = "", tier = reagentQuality, quantity = reagentCount}))
						end
					end
				end

				Auctionator.API.v1.CreateShoppingList(app.Name, "PSL", searchStrings)
			end
			makeShoppingList()
		end)
	end)
	app.AuctionatorButton:SetScript("OnEnter", function(self)
		app.WindowTooltipShow(L.WINDOW_BUTTON_AUCTIONATOR)
	end)
	app.AuctionatorButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-- Only show the button if Auctionator is enabled and loaded
	local loaded, finished = C_AddOns.IsAddOnLoaded("Auctionator")
	if finished == false then
		app.AuctionatorButton:Hide()
	end
end