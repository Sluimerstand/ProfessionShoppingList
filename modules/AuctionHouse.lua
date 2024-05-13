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
	app.AuctionatorButton:SetNormalTexture("Interface\\AddOns\\ProfessionShoppingList\\assets\\button-auctionator.blp")
	app.AuctionatorButton:GetNormalTexture():SetTexCoord(39/256, 75/256, 1/128, 38/128)
	app.AuctionatorButton:SetDisabledTexture("Interface\\AddOns\\ProfessionShoppingList\\assets\\button-auctionator.blp")
	app.AuctionatorButton:GetDisabledTexture():SetTexCoord(39/256, 75/256, 41/128, 78/128)
	app.AuctionatorButton:SetPushedTexture("Interface\\AddOns\\ProfessionShoppingList\\assets\\button-auctionator.blp")
	app.AuctionatorButton:GetPushedTexture():SetTexCoord(39/256, 75/256, 81/128, 118/128)
	app.AuctionatorButton:SetScript("OnClick", function()
		app.UpdateRecipes()
		-- Add a delay because I have no idea how to optimise my AddOn
		C_Timer.After(0.5, function()
			local function makeShoppingList()
				local searchStrings = {}

				for reagentID, reagentAmount in pairs(app.ReagentQuantities) do
					-- Cache item
					if not C_Item.IsItemDataCachedByID(reagentID) then local item = Item:CreateFromItemID(reagentID) end
					
					-- Get item info
					local itemName = C_Item.GetItemInfo(reagentID)
			
					-- Try again if error
					if itemName == nil then
						RunNextFrame(makeShoppingList)
						do return end
					end

					-- Set reagent quality if applicable
					local reagentQuality = ""
					if reagentTiers[reagentID].two ~= 0 then
						reagentQuality = userSettings["reagentQuality"]
					end

					-- Put the items in the temporary variable
					table.insert(searchStrings, Auctionator.API.v1.ConvertToSearchString(app.Name, { searchString = itemName, isExact = true, categoryKey = "", tier = reagentQuality, quantity = reagentAmount}))
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
	local loaded, finished = IsAddOnLoaded("Auctionator")
	if finished == false then
		app.AuctionatorButton:Hide()
	end
end

function event:ADDON_LOADED(addOnName, containsBindings)
	if addOnName == appName then
		app.CreateAuctionatorButton()
	end
end