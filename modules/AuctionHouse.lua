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
event:RegisterEvent("AUCTION_HOUSE_SHOW")

------------------------
-- AUCTIONATOR IMPORT --
------------------------

-- When the Auction House is opened
function event:AUCTION_HOUSE_SHOW()
	-- If Auctionator is loaded
	local loaded, finished = IsAddOnLoaded("Auctionator")
	if finished == true then
		-- Create a temporary variable
		if not auctionatorReagents then local auctionatorReagents end

		-- Grab all item names for tracked reagents
		local function getReagentNames()
			-- Reset the reagents list
			auctionatorReagents = "PSL"

			for reagentID, reagentAmount in pairs(app.ReagentQuantities) do
				-- Cache item
				if not C_Item.IsItemDataCachedByID(reagentID) then local item = Item:CreateFromItemID(reagentID) end
				
				-- Get item info
				local itemName = C_Item.GetItemInfo(reagentID)
		
				-- Try again if error
				if itemName == nil then
					RunNextFrame(getReagentNames)
					do return end
				end

				-- Put the item names in the temporary variable
				auctionatorReagents = auctionatorReagents .. '^"' .. itemName .. '";;0;0;0;0;0;0;0;0;;#;;' .. reagentAmount
			end
		end

		-- Wait 3 seconds, because Auctionator needs to create its frames
		C_Timer.After(3, function()
			-- Create PSL Import button for Auctionator, if the frame exists (and the AddOn is loaded)
			if AuctionatorImportListFrame and not auctionatorImportButton then
				auctionatorImportButton = CreateFrame("Button", nil, AuctionatorImportListFrame.Import, "UIPanelButtonTemplate")
				auctionatorImportButton:SetText("Copy from PSL")
				auctionatorImportButton:SetWidth(110)
				auctionatorImportButton:SetPoint("BOTTOMRIGHT", AuctionatorImportListFrame.Import, "BOTTOMLEFT", 0, 0)
				auctionatorImportButton:SetScript("OnClick", function()
					app.UpdateRecipes()
					-- Add another delay because I have no idea how to optimise my AddOn
					C_Timer.After(0.5, function()
						getReagentNames()
						-- Remove old list
						if Auctionator.Shopping.ListManager:GetIndexForName("PSL") ~= nil then
							Auctionator.Shopping.ListManager:Delete("PSL")
						end
						-- Import new list
						AuctionatorImportListFrame.EditBoxContainer:SetText(auctionatorReagents)
					end)
				end)
			end
		end)
	end
end