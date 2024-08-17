------------------------------------------------
-- Profession Shopping List: AuctionHouse.lua --
------------------------------------------------
-- Auction House module

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
						if not C_Item.IsItemDataCachedByID(reagentID) then local item = Item:CreateFromItemID(reagentID) end
						
						-- Get item info
						local itemName = C_Item.GetItemInfo(reagentID)
				
						-- Try again if error
						if itemName == nil then
							RunNextFrame(makeShoppingList)
							do return end
						end

						-- Set reagent quality to 2 or 3 if applicable and the user has this set, otherwise don't specify quality
						-- Also include the itemCount here, since that depends on the reagentQuality setting
						local reagentQuality = ""
						local reagentCount

						if ProfessionShoppingList_Cache.ReagentTiers[reagentID].two ~= 0 and ProfessionShoppingList_Settings["reagentQuality"] == 3 then
							reagentQuality = 3
							reagentCount = C_Item.GetItemCount(ProfessionShoppingList_Cache.ReagentTiers[reagentID].three, true, false, true, true)
						elseif ProfessionShoppingList_Cache.ReagentTiers[reagentID].two ~= 0 and ProfessionShoppingList_Settings["reagentQuality"] == 2 then
							reagentQuality = 2
							reagentCount = C_Item.GetItemCount(ProfessionShoppingList_Cache.ReagentTiers[reagentID].three, true, false, true, true)
										 + C_Item.GetItemCount(ProfessionShoppingList_Cache.ReagentTiers[reagentID].two, true, false, true, true)
						elseif ProfessionShoppingList_Cache.ReagentTiers[reagentID].two ~= 0 and ProfessionShoppingList_Settings["reagentQuality"] == 1 then
							reagentCount = C_Item.GetItemCount(ProfessionShoppingList_Cache.ReagentTiers[reagentID].three, true, false, true, true)
										 + C_Item.GetItemCount(ProfessionShoppingList_Cache.ReagentTiers[reagentID].two, true, false, true, true)
										 + C_Item.GetItemCount(ProfessionShoppingList_Cache.ReagentTiers[reagentID].one, true, false, true, true)
						else
							reagentCount = C_Item.GetItemCount(reagentID, true, false, true, true)
						end

						-- Calculate how many we still need
						reagentCount = math.max(0, reagentAmount - reagentCount)

						-- Put the items in the temporary variable
						if reagentCount > 0 then
							table.insert(searchStrings, Auctionator.API.v1.ConvertToSearchString(app.Name, { searchString = itemName, isExact = true, categoryKey = "", tier = reagentQuality, quantity = reagentCount}))
							if reagentQuality == 2 then
								-- Also add tier 3 for minimum reagent quality 2
								table.insert(searchStrings, Auctionator.API.v1.ConvertToSearchString(app.Name, { searchString = itemName, isExact = true, categoryKey = "", tier = 3, quantity = reagentCount}))
							end
						end
					end
				end

				Auctionator.API.v1.CreateShoppingList(app.Name, "PSL", searchStrings)
			end
			makeShoppingList()
		end)
	end)
	app.AuctionatorButton:SetScript("OnEnter", function()
		app.WindowTooltipShow(app.AuctionatorButtonTooltip)
	end)
	app.AuctionatorButton:SetScript("OnLeave", function()
		app.AuctionatorButtonTooltip:Hide()
	end)

	-- Only show the button if Auctionator is enabled and loaded
	local loaded, finished = C_AddOns.IsAddOnLoaded("Auctionator")
	if finished == false then
		app.AuctionatorButton:Hide()
	end
end

function event:ADDON_LOADED(addOnName, containsBindings)
	if addOnName == appName then
		app.CreateAuctionatorButton()
	end
end