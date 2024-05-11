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

------------------
-- INITIAL LOAD --
------------------

-- Create SavedVariables, default user settings, and session variables
function app.InitialiseTweaks()
	if userSettings["vendorAll"] == nil then userSettings["vendorAll"] = true end
	if userSettings["queueSound"] == nil then userSettings["queueSound"] = false end
	if userSettings["underminePrices"] == nil then userSettings["underminePrices"] = false end
end

-- When the AddOn is fully loaded, actually run the components
function event:ADDON_LOADED(addOnName, containsBindings)
	if addOnName == appName then
		app.InitialiseTweaks()
		app.UnderminePrices()
		app.HideOribos()
		app.SettingsTweaks()
	end
end

-----------------
-- QUEUE SOUND --
-----------------

-- Play the DBM-style queue sound
function app.QueueSound()
	-- If the setting is enabled
	if userSettings["queueSound"] == true then
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
	if userSettings["vendorAll"] == true then
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
		if userSettings["underminePrices"] == true then
			-- If Oribos Exchange is loaded
			local loaded, finished = IsAddOnLoaded("OribosExchange")
			if finished == true then
				-- Grab the pricing information
				local marketPrice = 0
				local regionPrice = 0

				-- Check both links for pricing data
				local oeData = {}
				OEMarketInfo(itemLink,oeData)
				if oeData['market'] == nil and oeData['region'] == nil then
					OEMarketInfo(unreliableItemLink,oeData)
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
	if userSettings["underminePrices"] == true then
		-- If Oribos Exchange is loaded
		local loaded, finished = IsAddOnLoaded("OribosExchange")
		if finished == true then
			local speciesID1, level, breedQuality, maxHealth, power, speed, bracketName = ...

			-- Make itemLink if it grabs the proper pet
			local itemLink = "|cff0070dd|Hbattlepet:"..speciesID1..":"..level..":"..breedQuality..":"..maxHealth..":"..power..":"..speed.."|h"..bracketName.."|h|r"

			-- Stop if error, it will try again on its own REAL soon
			if itemLink == nil then return end

			-- Grab pricing information
			local oeData = {}
			OEMarketInfo(itemLink,oeData)

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
	if userSettings["underminePrices"] == true then
		-- If Oribos Exchange is loaded
		local loaded, finished = IsAddOnLoaded("OribosExchange")
		if finished == true then
			-- Disable the original tooltip
			OETooltip(false)

			-- And hide the warning about it (thanks ChatGPT)
			local function ChatFrame_AddMessageOverride(self, message, ...)
				if message and message:find("Tooltip prices disabled. Run |cFFFFFF78/oetooltip on|r to enable.") then
					-- Modify the message to prevent the error, we can't send an empty string due to LS Glass
					message = "|cff000000" .. " " .. "|R"
				end
				-- Add the message to the ChatFrame
				self:ChatFrame_AddMessageOriginal(message, ...)
			end

			-- Hook the ChatFrame's AddMessage method
			for i = 1, NUM_CHAT_WINDOWS do
				local frame = _G["ChatFrame"..i]
				if frame then
					frame.ChatFrame_AddMessageOriginal = frame.AddMessage
					frame.AddMessage = ChatFrame_AddMessageOverride
				end
			end
		end
	end
end

--------------
-- SETTINGS --
--------------

function app.SettingsTweaks()
	-- Add subcategory
	local scrollFrame = CreateFrame("ScrollFrame", nil, self, "ScrollFrameTemplate")
	scrollFrame:Hide()	-- I'm fairly sure this isn't how you're supposed to prevent the subcategories from showing initially, but it works!
	scrollFrame.ScrollBar:ClearPoint("RIGHT")
	scrollFrame.ScrollBar:SetPoint("RIGHT", -36, 0)

	local scrollChild = CreateFrame("Frame")
	scrollFrame:SetScrollChild(scrollChild)
	scrollChild:SetWidth(1)    -- This is automatically defined, so long as the attribute exists at all
	scrollChild:SetHeight(1)    -- This is automatically defined, so long as the attribute exists at all

	local subcategory = scrollFrame
	subcategory.name = "Tweaks"
	subcategory.parent = "Profession Shopping List"
	InterfaceOptions_AddCategory(subcategory)

	-- Category: Tweaks
	local titleOtherFeatures = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
	titleOtherFeatures:SetPoint("TOPLEFT", 0, 0)
	titleOtherFeatures:SetJustifyH("LEFT")
	titleOtherFeatures:SetScale(1.2)
	titleOtherFeatures:SetText("Tweaks")

	local cbShowRecipeCooldowns = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
	cbShowRecipeCooldowns.Text:SetText("Recipe cooldown reminders")
	cbShowRecipeCooldowns.Text:SetTextColor(1, 1, 1, 1)
	cbShowRecipeCooldowns.Text:SetScale(1.2)
	cbShowRecipeCooldowns:SetPoint("TOPLEFT", titleOtherFeatures, "BOTTOMLEFT", 0, 0)
	cbShowRecipeCooldowns:SetChecked(userSettings["showRecipeCooldowns"])
	cbShowRecipeCooldowns:SetScript("OnClick", function(self)
		userSettings["showRecipeCooldowns"] = cbShowRecipeCooldowns:GetChecked()
	end)

	local cbVendorAll = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
	cbVendorAll.Text:SetText("Always set vendor filter to 'All'")
	cbVendorAll.Text:SetTextColor(1, 1, 1, 1)
	cbVendorAll.Text:SetScale(1.2)
	cbVendorAll:SetPoint("TOPLEFT", cbShowRecipeCooldowns, "BOTTOMLEFT", 0, 0)
	cbVendorAll:SetChecked(userSettings["vendorAll"])
	cbVendorAll:SetScript("OnClick", function(self)
		userSettings["vendorAll"] = cbVendorAll:GetChecked()
	end)

	local cbQueueSounds = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
	cbQueueSounds.Text:SetText("Play sound when any queue pops")
	cbQueueSounds.Text:SetTextColor(1, 1, 1, 1)
	cbQueueSounds.Text:SetScale(1.2)
	cbQueueSounds:SetPoint("TOPLEFT", cbVendorAll, "BOTTOMLEFT", 0, 0)
	cbQueueSounds:SetChecked(userSettings["queueSound"])
	cbQueueSounds:SetScript("OnClick", function(self)
		userSettings["queueSound"] = cbQueueSounds:GetChecked()
	end)

	local cbUnderminePrices = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
	cbUnderminePrices.Text:SetText("Use custom style for Oribos Exchange addon")
	cbUnderminePrices.Text:SetTextColor(1, 1, 1, 1)
	cbUnderminePrices.Text:SetScale(1.2)
	cbUnderminePrices:SetPoint("TOPLEFT", cbQueueSounds, "BOTTOMLEFT", 0, 0)
	cbUnderminePrices:SetChecked(userSettings["underminePrices"])
	cbUnderminePrices:SetScript("OnClick", function(self)
		userSettings["underminePrices"] = cbUnderminePrices:GetChecked()
	end)
end