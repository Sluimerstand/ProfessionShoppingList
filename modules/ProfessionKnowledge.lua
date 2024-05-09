-------------------------------------------------------
-- Profession Shopping List: ProfessionKnowledge.lua --
-------------------------------------------------------
-- Profession Knowledge module

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
event:RegisterEvent("SPELL_DATA_LOAD_RESULT")
event:RegisterEvent("TRADE_SKILL_SHOW")

------------------
-- INITIAL LOAD --
------------------

-- Create SavedVariables, default user settings, and session variables
function app.InitialiseProfessionKnowledge()
	-- Enable default user settings
	if userSettings["showKnowledgeNotPerks"] == nil then userSettings["showKnowledgeNotPerks"] = false end
	if userSettings["knowledgeHideDone"] == nil then userSettings["knowledgeHideDone"] = false end
	if userSettings["knowledgeAlwaysShowDetails"] == nil then userSettings["knowledgeAlwaysShowDetails"] = false end
end

-----------------------
-- KNOWLEDGE TRACKER --
-----------------------

-- Create knowledge tracker
function app.CreateProfessionKnowledgeAssets()
	-- Create Knowledge Point tracker
	if not knowledgePointTracker then
		-- Bar wrapper
		knowledgePointTracker = CreateFrame("Frame", "KnowledgePointTracker", ProfessionsFrame.SpecPage, "TooltipBackdropTemplate")
		knowledgePointTracker:SetBackdropBorderColor(0.5, 0.5, 0.5)
		knowledgePointTracker:SetSize(470,25)
		knowledgePointTracker:SetPoint("TOPRIGHT", ProfessionsFrame.SpecPage, "TOPRIGHT", -5, -24)
		knowledgePointTracker:SetFrameStrata("HIGH")

		-- Bar
		knowledgePointTracker.Bar = CreateFrame("StatusBar", nil, knowledgePointTracker)
		knowledgePointTracker.Bar:SetStatusBarTexture("Interface\\AddOns\\ProfessionShoppingList\\assets\\profbars\\generic.blp")
		
		knowledgePointTracker.Bar:SetPoint("TOPLEFT", 5, -5)
		knowledgePointTracker.Bar:SetPoint("BOTTOMRIGHT", -5, 5)
		Mixin(knowledgePointTracker.Bar, SmoothStatusBarMixin)

		-- Text
		knowledgePointTracker.Text = knowledgePointTracker.Bar:CreateFontString("OVERLAY", nil, "GameFontNormalOutline")
		knowledgePointTracker.Text:SetPoint("CENTER", knowledgePointTracker, "CENTER", 0, 0)
		knowledgePointTracker.Text:SetTextColor(1, 1, 1, 1)
	end

	-- Create Knowledge Point tracker tooltip
	if not knowledgePointTooltip then
		knowledgePointTooltip = CreateFrame("Frame", nil, knowledgePointTracker, "BackdropTemplate")
		knowledgePointTooltip:SetPoint("CENTER")
		knowledgePointTooltip:SetPoint("TOP", knowledgePointTracker, "BOTTOM", 0, 0)
		knowledgePointTooltip:SetFrameStrata("TOOLTIP")
		knowledgePointTooltip:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})
		knowledgePointTooltip:SetBackdropColor(0, 0, 0, 0.9)
		knowledgePointTooltip:EnableMouse(false)
		knowledgePointTooltip:SetMovable(false)
		knowledgePointTooltip:Hide()

		knowledgePointTooltipText = knowledgePointTooltip:CreateFontString("ARTWORK", nil, "GameFontNormal")
		knowledgePointTooltipText:SetPoint("TOPLEFT", knowledgePointTooltip, "TOPLEFT", 10, -10)
		knowledgePointTooltipText:SetJustifyH("LEFT")
	end
end

-- Populate knowledge tracker
function app.KnowledgeTracker()
	-- Show stuff depending on which profession is opened
	local skillLineID = C_TradeSkillUI.GetProfessionChildSkillLineID()
	local professionID = C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID).profession

	-- Knowledge Point Tracker
	local function setKnowledgePointTracker()
		-- Variables
		local configID = C_ProfSpecs.GetConfigIDForSkillLine(skillLineID)
		local specTabIDs = C_ProfSpecs.GetSpecTabIDsForSkillLine(skillLineID)

		-- Helper functions
		local appendChildPathIDsForRoot -- Declare this one before the function itself, otherwise it can't find the function to refer to within itself apparently
		appendChildPathIDsForRoot = function(t, pathID)
			t[pathID] = 1
			for _, childID in ipairs(C_ProfSpecs.GetChildrenForPath(pathID)) do
				appendChildPathIDsForRoot(t, childID)
			end
		end

		-- Get all profession specialisation paths
		local pathIDs = {}
		for _, specTabID in ipairs(C_ProfSpecs.GetSpecTabIDsForSkillLine(skillLineID)) do
			appendChildPathIDsForRoot(pathIDs, C_ProfSpecs.GetRootPathForTab(specTabID))
		end

		-- Get all perks
		local perkCount = 0
		local perkIDs = {}
		for pathID, _ in pairs(pathIDs) do
			local perks = C_ProfSpecs.GetPerksForPath(pathID)
			for no, perk in pairs(perks) do
				perkCount = perkCount + 1
				perkIDs[perkCount] = perk.perkID
			end
		end

		-- Get perk info
		local perksEarned = 0
		for no, perk in pairs(perkIDs) do
			if C_ProfSpecs.GetStateForPerk(perk, configID) == 2 then
				perksEarned = perksEarned + 1
			end
		end

		-- Get knowledge info
		local knowledgeSpent = 0
		local knowledgeMax = 0
		for pathID, _ in pairs(pathIDs) do
			local pathInfo = C_Traits.GetNodeInfo(C_ProfSpecs.GetConfigIDForSkillLine(skillLineID), pathID)
			knowledgeSpent = knowledgeSpent + math.max(0,(pathInfo.activeRank - 1))
			knowledgeMax = knowledgeMax + (pathInfo.maxRanks - 1)
		end

		-- Set text, background, and progress, then show bar
		if userSettings["showKnowledgeNotPerks"] == true then
			knowledgePointTracker.Text:SetText(knowledgeSpent.."/"..knowledgeMax.." knowledge spent")
			knowledgePointTracker.Bar:SetMinMaxSmoothedValue(0, knowledgeMax)
			knowledgePointTracker.Bar:SetSmoothedValue(knowledgeSpent)
		else
			knowledgePointTracker.Text:SetText(perksEarned.."/"..perkCount.." perks unlocked")
			knowledgePointTracker.Bar:SetMinMaxSmoothedValue(0, perkCount)
			knowledgePointTracker.Bar:SetSmoothedValue(perksEarned)
		end
		knowledgePointTracker.Bar:SetStatusBarTexture("Interface\\AddOns\\ProfessionShoppingList\\assets\\profbars\\"..professionID..".blp")
		knowledgePointTracker:Show()
		knowledgePointTracker:SetPropagateKeyboardInput(true) -- So keyboard presses can be done
	end

	-- Knowledge Point Tooltip
	local treatiseItem
	local treatiseQuest
	local orderQuest
	local gatherQuests
	local craftQuests
	local drops
	local hiddenMaster
	local treasures
	local books
	local progress = true

	local function kpTooltip()
		-- Check if DMF is active
		local dmfActive = false
		C_Calendar.OpenCalendar()
		local date = C_DateAndTime.GetCurrentCalendarTime()
		local numEvents = C_Calendar.GetNumDayEvents(0, date.monthDay)
		for i=1, numEvents do
			local event = C_Calendar.GetHolidayInfo(0, date.monthDay, i)
			if event and (event.texture == 235446 or event.texture == 235447 or event.texture == 235448) then -- Non-localised way to detect specific holiday
				dmfActive = true
			end
		end

		-- Darkmoon Faire
		local dmfStatus = app.iconNotReady
		local dmfNumber = 0

		if dmf ~= nil and dmfActive == true then
			if C_QuestLog.IsQuestFlaggedCompleted(dmf) then
				dmfStatus = app.iconReady
				treatiseNumber = 1
			end

			if dmfStatus == app.iconNotReady then progress = false end
		end

		-- Treatise
		local treatiseStatus = app.iconNotReady
		local treatiseNumber = 0
		
		if treatiseQuest ~= nil then
			if C_QuestLog.IsQuestFlaggedCompleted(treatiseQuest) then
				treatiseStatus = app.iconReady
				treatiseNumber = 1
			end

			if treatiseStatus == app.iconNotReady then progress = false end
		end

		-- Crafting order quest
		local orderQuestStatus = app.iconNotReady
		local orderQuestNumber = 0

		if orderQuest ~= nil then 
			if C_QuestLog.IsQuestFlaggedCompleted(orderQuest) then
				orderQuestStatus = app.iconReady
				orderQuestNumber = 1
			end

			if orderQuestStatus == app.iconNotReady then progress = false end
		end

		-- Gather quests
		local gatherQuestStatus = app.iconNotReady
		local gatherQuestNumber = 0

		if gatherQuests ~= nil then
			for no, questID in pairs(gatherQuests) do
				if C_QuestLog.IsQuestFlaggedCompleted(questID) then
					gatherQuestStatus = app.iconReady
					gatherQuestNumber = 1
				end
			end

			if gatherQuestStatus == app.iconNotReady then progress = false end
		end

		-- Craft quests
		local craftQuestStatus = app.iconNotReady
		local craftQuestNumber = 0

		if craftQuests ~= nil then
			for no, questID in pairs(craftQuests) do
				if C_QuestLog.IsQuestFlaggedCompleted(questID) then
					craftQuestNumber = 1
					craftQuestStatus = app.iconReady
				end
			end

			if craftQuestStatus == app.iconNotReady then progress = false end
		end

		-- Drops
		local dropsStatus = app.iconNotReady
		local dropsNoCurrent = 0
		local dropsNoTotal = 0

		if drops ~= nil then
			for _, dropInfo in ipairs(drops) do
				if C_QuestLog.IsQuestFlaggedCompleted(dropInfo.questID) then
					dropsNoCurrent = dropsNoCurrent + 1
				end
				dropsNoTotal = dropsNoTotal + 1
			end

			if dropsNoCurrent == dropsNoTotal then
				dropsStatus = app.iconReady
			end

			if dropsStatus == app.iconNotReady then progress = false end
		end

		-- Dragon Shards
		local shardQuests = {67295, 69946, 69979, 67298}
		local shardStatus = app.iconNotReady
		local shardNo = 0

		for _, questID in pairs(shardQuests) do
			if C_QuestLog.IsQuestFlaggedCompleted(questID) then
				shardNo = shardNo + 1
			end
		end

		if shardNo == 4 then shardStatus = app.iconReady end

		if shardStatus == app.iconNotReady then progress = false end

		-- Hidden profession master
		local hiddenStatus = app.iconNotReady
		local hiddenNumber = 0

		if hiddenMaster ~= nil then 
			if C_QuestLog.IsQuestFlaggedCompleted(hiddenMaster) then
				hiddenNumber = 1
				hiddenStatus = app.iconReady
			end

			if hiddenStatus == app.iconNotReady then progress = false end
		end

		-- Treasures
		local treasureStatus = app.iconNotReady
		local treasureNoCurrent = 0
		local treasureNoTotal = 0

		if treasures ~= nil then
			for questID, itemID in pairs(treasures) do
				if C_QuestLog.IsQuestFlaggedCompleted(questID) then
					treasureNoCurrent = treasureNoCurrent + 1
				end
				treasureNoTotal = treasureNoTotal + 1
			end

			if treasureNoCurrent == treasureNoTotal then treasureStatus = app.iconReady end

			if treasureStatus == app.iconNotReady then progress = false end
		end

		-- Books
		local bookStatus = app.iconNotReady
		local bookNoCurrent = 0
		local bookNoTotal = 0

		if books ~= nil then
			for _, bookInfo in ipairs(books) do
				if C_QuestLog.IsQuestFlaggedCompleted(bookInfo.questID) then
					bookNoCurrent = bookNoCurrent + 1
				end
				bookNoTotal = bookNoTotal + 1
			end

			if bookNoCurrent == bookNoTotal then bookStatus = app.iconReady end
			if bookStatus == app.iconNotReady then progress = false end
		end
		
		-- Renown
		if renown ~= nil then
			renownStatus = app.iconNotReady

			renownInfo = {}
			local title1 = GetFactionInfoByID(renown[1].factionID)
			local title2 = GetFactionInfoByID(renown[2].factionID)
			renownInfo[1] = { locked = C_MajorFactions.GetRenownLevels(renown[1].factionID)[14].locked, questID = renown[1].questID1, title = title1, level = 14 }
			renownInfo[2] = { locked = C_MajorFactions.GetRenownLevels(renown[1].factionID)[24].locked, questID = renown[1].questID2, title = title1, level = 24 }
			renownInfo[3] = { locked = C_MajorFactions.GetRenownLevels(renown[2].factionID)[14].locked, questID = renown[2].questID1, title = title2, level = 14 }
			renownInfo[4] = { locked = C_MajorFactions.GetRenownLevels(renown[2].factionID)[24].locked, questID = renown[2].questID2, title = title2, level = 24 }
			
			-- Exception for Dragonscale Expedition, for some reason
			if renown[1].factionID == 2507 then
				renownInfo[2].locked = C_MajorFactions.GetRenownLevels(renown[1].factionID)[23].locked
				renownInfo[2].level = 23
			end

			renownCount = 0
			for key, info in ipairs(renownInfo) do
				renownInfo[key].status = app.iconNotReady
				if C_QuestLog.IsQuestFlaggedCompleted(renownInfo[key].questID) == true then
					renownInfo[key].status = app.iconReady
					renownCount = renownCount + 1
				elseif renownInfo[key].locked == true then
					renownInfo[key].status = app.iconWaiting
				end
			end

			if renownCount == 4 then renownStatus = app.iconReady end
			if renownStatus == app.iconNotReady then progress = false end
		end

		-- Weekly knowledge (text)
		local oldText
		knowledgePointTooltipText:SetText("Weekly:|cffFFFFFF")

		if dmf ~= nil and dmfActive == true then
			oldText = knowledgePointTooltipText:GetText()
			knowledgePointTooltipText:SetText(oldText.."\n".."|T"..dmfStatus..":0|t "..dmfNumber.."/1 "..CALENDAR_FILTER_DARKMOON)
		end

		if treatiseQuest ~= nil then
			-- Cache treatise item
			if not C_Item.IsItemDataCachedByID(treatiseItem) then local item = Item:CreateFromItemID(treatiseItem) end
			-- Get item link
			local _, itemLink = C_Item.GetItemInfo(treatiseItem)
			-- If link missing, try again
			if itemLink == nil then
				RunNextFrame(kpTooltip)
				do return end
			end
			oldText = knowledgePointTooltipText:GetText()
			knowledgePointTooltipText:SetText(oldText.."\n".."|T"..treatiseStatus..":0|t "..treatiseNumber.."/1 "..itemLink)
		end

		if orderQuest ~= nil then
			oldText = knowledgePointTooltipText:GetText()
			knowledgePointTooltipText:SetText(oldText.."\n".."|T"..orderQuestStatus..":0|t "..orderQuestNumber.."/1 Crafting Orders quest")
		end

		if gatherQuests ~= nil then
			oldText = knowledgePointTooltipText:GetText()
			knowledgePointTooltipText:SetText(oldText.."\n".."|T"..gatherQuestStatus..":0|t "..gatherQuestNumber.."/1 Gather quest")
		end

		if craftQuests ~= nil then
			oldText = knowledgePointTooltipText:GetText()
			knowledgePointTooltipText:SetText(oldText.."\n".."|T"..craftQuestStatus..":0|t "..craftQuestNumber.."/1 Craft quest")
		end

		if drops ~= nil then
			oldText = knowledgePointTooltipText:GetText()
			knowledgePointTooltipText:SetText(oldText.."\n".."|T"..dropsStatus..":0|t "..dropsNoCurrent.."/"..dropsNoTotal.." Drops")

			if IsModifierKeyDown() == true or userSettings["knowledgeAlwaysShowDetails"] == true then
				for _, dropInfo in ipairs(drops) do
					oldText = knowledgePointTooltipText:GetText()

					-- Cache item
					if not C_Item.IsItemDataCachedByID(dropInfo.itemID) then local item = Item:CreateFromItemID(dropInfo.itemID) end
					-- Get item info
					local _, itemLink = C_Item.GetItemInfo(dropInfo.itemID)
					-- If links missing, try again
					if itemLink == nil then
						RunNextFrame(kpTooltip)
						do return end
					end

					if C_QuestLog.IsQuestFlaggedCompleted(dropInfo.questID) then
						knowledgePointTooltipText:SetText(oldText.."\n   ".."|T"..app.iconReady..":0|t "..itemLink.." - "..dropInfo.source)
					else
						knowledgePointTooltipText:SetText(oldText.."\n   ".."|T"..app.iconNotReady..":0|t "..itemLink.." - "..dropInfo.source)
					end
				end
			end
		end

		-- One-time knowledge (text)
		if userSettings["knowledgeHideDone"] == true and shardNo == 4 and hiddenNumber == 1 and (treasureNoCurrent == treasureNoTotal or treasures == nil) and (bookNoCurrent == bookNoTotal) then
			-- Do not show this
		else
			oldText = knowledgePointTooltipText:GetText()
			knowledgePointTooltipText:SetText(oldText.."\n\n|cffFFD000One-time:|cffFFFFFF")
		end
		
		-- Dragon Shard of Knowledge
		if userSettings["knowledgeHideDone"] == true and shardNo == 4 then
			-- Don't show this
		else
			-- Cache dragon shard item
			if not C_Item.IsItemDataCachedByID(191784) then local item = Item:CreateFromItemID(191784) end
			-- Get item link
			local _, itemLink = C_Item.GetItemInfo(191784)
			-- If link missing, try again
			if itemLink == nil then
				RunNextFrame(kpTooltip)
				do return end
			end

			oldText = knowledgePointTooltipText:GetText()
			knowledgePointTooltipText:SetText(oldText.."\n|T"..shardStatus..":0|t "..shardNo.."/4 "..itemLink)

			if IsModifierKeyDown() == true or userSettings["knowledgeAlwaysShowDetails"] == true then
				for no, questID in pairs(shardQuests) do
					oldText = knowledgePointTooltipText:GetText()
					local questTitle = C_QuestLog.GetTitleForQuestID(questID)

					-- If link missing, try again
					if questTitle == nil then
						RunNextFrame(kpTooltip)
						do return end
					end

					if C_QuestLog.IsQuestFlaggedCompleted(questID) then
						knowledgePointTooltipText:SetText(oldText.."\n   ".."|T"..app.iconReady..":0|t ".."|cffffff00|Hquest:"..questID.."62|h["..questTitle.."]|h|r")
					else
						knowledgePointTooltipText:SetText(oldText.."\n   ".."|T"..app.iconNotReady..":0|t ".."|cffffff00|Hquest:"..questID.."62|h["..questTitle.."]|h|r")
					end
				end
			end
		end

		-- Hidden profession master
		if userSettings["knowledgeHideDone"] == true and hiddenNumber == 1 then
			-- Don't show this
		else
			oldText = knowledgePointTooltipText:GetText()
			knowledgePointTooltipText:SetText(oldText.."\n".."|T"..hiddenStatus..":0|t "..hiddenNumber.."/1 Hidden profession master")
		end

		-- Treasures
		if treasures ~= nil then
			if userSettings["knowledgeHideDone"] == true and treasureNoCurrent == treasureNoTotal then
				-- Don't show this
			else
				oldText = knowledgePointTooltipText:GetText()
				knowledgePointTooltipText:SetText(oldText.."\n".."|T"..treasureStatus..":0|t "..treasureNoCurrent.."/"..treasureNoTotal.." Treasures")

				if IsModifierKeyDown() == true or userSettings["knowledgeAlwaysShowDetails"] == true then
					for questID, itemID in pairs(treasures) do
						oldText = knowledgePointTooltipText:GetText()

						-- Cache item
						if not C_Item.IsItemDataCachedByID(itemID) then local item = Item:CreateFromItemID(itemID) end
						-- Get item link
						local _, itemLink = C_Item.GetItemInfo(itemID)
						-- If link missing, try again
						if itemLink == nil then
							RunNextFrame(kpTooltip)
							do return end
						end
	
						if C_QuestLog.IsQuestFlaggedCompleted(questID) then
							knowledgePointTooltipText:SetText(oldText.."\n   ".."|T"..app.iconReady..":0|t "..itemLink)
						else
							knowledgePointTooltipText:SetText(oldText.."\n   ".."|T"..app.iconNotReady..":0|t "..itemLink)
						end
					end
				end
			end
		end

		-- Books
		if books ~= nil then
			if userSettings["knowledgeHideDone"] == true and bookNoCurrent == bookNoTotal then
				-- Don't show this
			else
				oldText = knowledgePointTooltipText:GetText()
				knowledgePointTooltipText:SetText(oldText.."\n".."|T"..bookStatus..":0|t "..bookNoCurrent.."/"..bookNoTotal.." Books")

				if IsModifierKeyDown() == true or userSettings["knowledgeAlwaysShowDetails"] == true then
					for _, bookInfo in ipairs(books) do
						oldText = knowledgePointTooltipText:GetText()

						-- Cache item
						if not C_Item.IsItemDataCachedByID(bookInfo.itemID) then local item = Item:CreateFromItemID(bookInfo.itemID) end
						-- Get item link
						local _, itemLink = C_Item.GetItemInfo(bookInfo.itemID)
						-- If link missing, try again
						if itemLink == nil then
							RunNextFrame(kpTooltip)
							do return end
						end
	
						if C_QuestLog.IsQuestFlaggedCompleted(bookInfo.questID) then
							knowledgePointTooltipText:SetText(oldText.."\n   ".."|T"..app.iconReady..":0|t "..itemLink)
						else
							knowledgePointTooltipText:SetText(oldText.."\n   ".."|T"..app.iconNotReady..":0|t "..itemLink)
						end
					end
				end
			end
		end

		-- Renown
		if renown ~= nil then
			if userSettings["knowledgeHideDone"] == true and renownCount == 4 then
				-- Don't show this
			else
				oldText = knowledgePointTooltipText:GetText()
				knowledgePointTooltipText:SetText(oldText.."\n".."|T"..renownStatus..":0|t "..renownCount.."/4 Renown")
				if IsModifierKeyDown() == true or userSettings["knowledgeAlwaysShowDetails"] == true then
					for key, info in ipairs(renownInfo) do

						oldText = knowledgePointTooltipText:GetText()
						knowledgePointTooltipText:SetText(oldText.."\n   ".."|T"..renownInfo[key].status..":0|t "..renownInfo[key].title.." ("..RENOWN_LEVEL_LABEL..renownInfo[key].level..")")
					end
				end
			end
		end
		
		oldText = knowledgePointTooltipText:GetText()
		if IsModifierKeyDown() == false and userSettings["knowledgeAlwaysShowDetails"] == false then knowledgePointTooltipText:SetText(oldText.."\n\n|cffFFD000Hold Alt, Ctrl, or Shift to show details.") end

		-- Set the tooltip size to fit its contents
		knowledgePointTooltip:SetHeight(knowledgePointTooltipText:GetStringHeight()+20)
		knowledgePointTooltip:SetWidth(knowledgePointTooltipText:GetStringWidth()+20)
	end

	-- Refresh and show the tooltip on mouse-over
	knowledgePointTracker:SetScript("OnEnter", function()
		kpTooltip()
		knowledgePointTooltip:Show()
	end)

	-- Hide the tooltip when not mouse-over
	knowledgePointTracker:SetScript("OnLeave", function()
		knowledgePointTooltip:Hide()
	end)

	-- Refresh the tooltip on key down/up (to check for IsModifierKeyDown)
	knowledgePointTracker:SetScript("OnKeyDown", function()
		kpTooltip()
	end)
	knowledgePointTracker:SetScript("OnKeyUp", function()
		kpTooltip()
	end)

	-- Blacksmithing
	if professionID == 1 then
		treatiseItem = 198454
		treatiseQuest = 74109
		orderQuest = 70589
		gatherQuests = {66517, 66897, 66941, 72398, 75148, 75569, 77935, 77936}
		craftQuests = {70211, 70233, 70234, 70235}
		hiddenMaster = 70250
		drops = {}
		drops[1] = {questID = 66381, itemID = 192131, source = "Treasures"}
		drops[2] = {questID = 66382, itemID = 192132, source = "Treasures"}
		drops[3] = {questID = 70512, itemID = 198965, source = "Mobs: Earth"}
		drops[4] = {questID = 70513, itemID = 198966, source = "Mobs: Fire"}
		drops[5] = {questID = 74931, itemID = 204230, source = "Tidesmith Zarviss"}
		treasures = {}
		-- 10.0
		treasures[70230] = 198791	-- Glimmer of Blacksmithing Wisdom
		treasures[70246] = 201007	-- Ancient Monument
		treasures[70296] = 201008	-- Molten Ingot
		treasures[70310] = 201010	-- Qalashi Weapon Diagram
		treasures[70311] = 201006	-- Draconic Flux
		treasures[70312] = 201005	-- Curious Ingots
		treasures[70313] = 201004	-- Ancient Spear Shards
		treasures[70314] = 201011	-- Spelltouched Tongs
		treasures[70353] = 201009	-- Falconer Gauntlet Drawings
		-- 10.1
		treasures[76078] = 205986	-- Well-Worn Kiln
		treasures[76079] = 205987	-- Brimstone Rescue Ring
		treasures[76080] = 205988	-- Zaqali Elder Spear
		-- 10.2
		treasures[78417] = 210464	-- Amirdrassil Defender's Shield
		treasures[78418] = 210465	-- Deathstalker Chassis
		treasures[78419] = 210466	-- Flamesworn Render
		books = {}
		books[1] = {questID = 71894, itemID = 200972}
		books[2] = {questID = 71905, itemID = 201268}
		books[3] = {questID = 71916, itemID = 201279}
		books[4] = {questID = 75755, itemID = 205352}
		books[5] = {questID = 75846, itemID = 205428}
		books[6] = {questID = 75849, itemID = 205439}
		renown = {}
		renown[1] = {factionID = 2503, questID1 = 72312, questID2 = 72315}
		renown[2] = {factionID = 2510, questID1 = 72329, questID2 = 70909}
		dmf = 29508
	end

	-- Leatherworking
	if professionID == 2 then
		treatiseItem = 194700
		treatiseQuest = 74113
		orderQuest = 70594
		gatherQuests = {66363, 66364, 66951, 72407, 75354, 75368, 77945, 77946}
		craftQuests = {70567, 70568, 70569, 70571}
		hiddenMaster = 70256
		drops = {}
		drops[1] = {questID = 66384, itemID = 193910, source = "Treasures"}
		drops[2] = {questID = 66385, itemID = 193913, source = "Treasures"}
		drops[3] = {questID = 70522, itemID = 198975, source = "Mobs: Proto-Drakes"}
		drops[4] = {questID = 70523, itemID = 198976, source = "Mobs: Slyvern & Vorquin"}
		drops[5] = {questID = 74928, itemID = 204232, source = "Snarfang"}
		treasures = {}
		-- 10.0
		treasures[70266] = 198658	-- Decay-Infused Tanning Oil
		treasures[70269] = 201018	-- Well-Danced Drum
		treasures[70280] = 198667	-- Spare Djaradin Tools
		treasures[70286] = 198683	-- Treated Hides
		treasures[70294] = 198690	-- Bag of Decayed Scales
		treasures[70300] = 198696	-- Wind-Blessed Hide
		treasures[70308] = 198711	-- Poacher's Pack
		-- 10.1
		treasures[75495] = 204986	-- Flame-Infused Scale Oil
		treasures[75496] = 204987	-- Lava-Forged Leatherworker's "Knife"
		treasures[75502] = 204988	-- Sulfur-Soaked Skins
		-- 10.2
		treasures[78298] = 210208	-- Tuft of Dreamsaber Fur
		treasures[78299] = 210211	-- Molted Fearie Dragon Scales
		treasures[78305] = 210215	-- Dreamtalon Claw
		books = {}
		books[1] = {questID = 71900, itemID = 200979}
		books[2] = {questID = 71911, itemID = 201275}
		books[3] = {questID = 71922, itemID = 201286}
		books[4] = {questID = 75751, itemID = 198613}
		books[5] = {questID = 75840, itemID = 205426}
		books[6] = {questID = 75855, itemID = 205437}
		renown = {}
		renown[1] = {factionID = 2503, questID1 = 72296, questID2 = 72297}
		renown[2] = {factionID = 2511, questID1 = 72321, questID2 = 72326}
		dmf = 29517
	end

	-- Alchemy
	if professionID == 3 then
		treatiseItem = 194697
		treatiseQuest = 74108
		orderQuest = nil
		gatherQuests = {66937, 66938, 66940, 72427, 75363, 75371, 77932, 77918}
		craftQuests = {70530, 70531, 70532, 70533}
		hiddenMaster = 70247
		drops = {}
		drops[1] = {questID = 66373, itemID = 193891, source = "Treasures"}
		drops[2] = {questID = 66374, itemID = 193897, source = "Treasures"}
		drops[3] = {questID = 70504, itemID = 198963, source = "Mobs: Decay"}
		drops[4] = {questID = 70511, itemID = 198964, source = "Mobs: Elemental"}
		drops[5] = {questID = 74935, itemID = 204226, source = "Agni Blazehoof"}
		treasures = {}
		-- 10.0
		treasures[70208] = 198599	-- Experimental Decay Sample
		treasures[70274] = 198663	-- Frostforged Potion
		treasures[70278] = 203471	-- Tasty Candy (formerly Furry Gloop 201003)
		treasures[70289] = 198685	-- Well Insulated Mug
		treasures[70301] = 198697	-- Contraband Concoction
		treasures[70305] = 198710	-- Canteen of Suspicious Water
		treasures[70309] = 198712	-- Small Basket of Firewater Powder
		-- 10.1
		treasures[75646] = 205211	-- Nutriend Diluted Protofluid
		treasures[75649] = 205212	-- Marrow-Ripened Slime
		treasures[75651] = 205213	-- Suspicious Mold
		-- 10.2
		treasures[78264] = 210184	-- Half-Filled Dreamless Sleep Potion
		treasures[78269] = 210185	-- Splash Potion of Narcolepsy
		treasures[78275] = 210190	-- Blazeroot
		books = {}
		books[1] = {questID = 71893, itemID = 200974}
		books[2] = {questID = 71904, itemID = 201270}
		books[3] = {questID = 71915, itemID = 201281}
		books[4] = {questID = 75756, itemID = 205353}
		books[5] = {questID = 75847, itemID = 205429}
		books[6] = {questID = 75848, itemID = 205440}
		renown = {}
		renown[1] = {factionID = 2503, questID1 = 72311, questID2 = 72314}
		renown[2] = {factionID = 2510, questID1 = 70892, questID2 = 70889}
		dmf = 29506
	end

	-- Herbalism
	if professionID == 4 then
		treatiseItem = 194704
		treatiseQuest = 74107
		orderQuest = nil
		gatherQuests = {70613, 70614, 70615, 70616}
		craftQuests = nil
		hiddenMaster = 70253
		drops = {}
		drops[1] = {questID = 71857, itemID = 200677, source = "Herbs"}
		drops[2] = {questID = 71858, itemID = 200677, source = "Herbs"}
		drops[3] = {questID = 71859, itemID = 200677, source = "Herbs"}
		drops[4] = {questID = 71860, itemID = 200677, source = "Herbs"}
		drops[5] = {questID = 71861, itemID = 200677, source = "Herbs"}
		drops[6] = {questID = 71864, itemID = 200678, source = "Herbs"}
		drops[7] = {questID = 74933, itemID = 204228, source = "Kangalo"}
		treasures = nil
		books = {}
		books[1] = {questID = 71897, itemID = 200980}
		books[2] = {questID = 71908, itemID = 201276}
		books[3] = {questID = 71919, itemID = 201287}
		books[4] = {questID = 75753, itemID = 205358}
		books[5] = {questID = 75843, itemID = 205434}
		books[6] = {questID = 75852, itemID = 205445}
		renown = {}
		renown[1] = {factionID = 2503, questID1 = 72313, questID2 = 72316}
		renown[2] = {factionID = 2511, questID1 = 72319, questID2 = 72324}
		dmf = 29514
	end

	-- Mining
	if professionID == 6 then
		treatiseItem = 194708
		treatiseQuest = 74106
		orderQuest = nil
		gatherQuests = {70617, 70618, 72156, 72157}
		craftQuests = nil
		hiddenMaster = 70258
		drops = {}
		drops[1] = {questID = 72160, itemID = 201300, source = "Deposits"}
		drops[2] = {questID = 72161, itemID = 201300, source = "Deposits"}
		drops[3] = {questID = 72162, itemID = 201300, source = "Deposits"}
		drops[4] = {questID = 72163, itemID = 201300, source = "Deposits"}
		drops[5] = {questID = 72164, itemID = 201300, source = "Deposits"}
		drops[6] = {questID = 72165, itemID = 201301, source = "Deposits"}
		drops[7] = {questID = 74926, itemID = 204233, source = "Tectonus"}
		treasures = nil
		books = {}
		books[1] = {questID = 71901, itemID = 200981}
		books[2] = {questID = 71912, itemID = 201277}
		books[3] = {questID = 71923, itemID = 201288}
		books[4] = {questID = 75758, itemID = 205356}
		books[5] = {questID = 75839, itemID = 205432}
		books[6] = {questID = 75856, itemID = 205443}
		renown = {}
		renown[1] = {factionID = 2507, questID1 = 72302, questID2 = 72308}
		renown[2] = {factionID = 2510, questID1 = 72332, questID2 = 72335}
		dmf = 29518
	end

	-- Tailoring
	if professionID == 7 then
		treatiseItem = 194698
		treatiseQuest = 74115
		orderQuest = 70595
		gatherQuests = {66899, 66952, 66953, 72410, 75407, 75600, 77947, 77949}
		craftQuests = {70572, 70582, 70586, 70587}
		hiddenMaster = 70260
		drops = {}
		drops[1] = {questID = 66386, itemID = 193898, source = "Treasures"}
		drops[2] = {questID = 66387, itemID = 193899, source = "Treasures"}
		drops[3] = {questID = 70524, itemID = 198977, source = "Mobs: Centaur"}
		drops[4] = {questID = 70525, itemID = 198978, source = "Mobs: Gnoll"}
		drops[5] = {questID = 74929, itemID = 204225, source = "Gareed"}
		treasures = {}
		-- 10.0
		treasures[70267] = 198662	-- Intriguing Bolt of Blue Cloth
		treasures[70284] = 198680	-- Decaying Brackenhide Blanket
		treasures[70288] = 198684	-- Miniature Bronze Dragonflight Banner
		treasures[70295] = 198692	-- Noteworthy Scrap of Carpet
		treasures[70302] = 198699	-- Mysterious Banner
		treasures[70303] = 201020	-- Silky Surprise
		treasures[70304] = 198702	-- Itinerant Singed Fabric
		treasures[70372] = 201019	-- Ancient Dragonweave Bolt
		-- 10.1
		treasures[76102] = 206019	-- Abandoned Reserve Chute
		treasures[76110] = 206025	-- Used Medical Wrap Kit
		treasures[76116] = 206030	-- Exquisitely Embroidered Banner
		-- 10.2
		treasures[78414] = 210461	-- Exceedingly Soft Wildercloth
		treasures[78415] = 210462	-- Plush Pillow
		treasures[78416] = 210463	-- Snuggle Buddy
		books = {}
		books[1] = {questID = 71903, itemID = 200975}
		books[2] = {questID = 71914, itemID = 201271}
		books[3] = {questID = 71925, itemID = 201282}
		books[4] = {questID = 75757, itemID = 205355}
		books[5] = {questID = 75837, itemID = 205431}
		books[6] = {questID = 75858, itemID = 205442}
		renown = {}
		renown[1] = {factionID = 2507, questID1 = 72303, questID2 = 72309}
		renown[2] = {factionID = 2510, questID1 = 72333, questID2 = 72336}
		dmf = 29520
	end

	-- Engineering
	if professionID == 8 then
		treatiseItem = 198510
		treatiseQuest = 74111
		orderQuest = 70591
		gatherQuests = {66890, 66891, 66942, 72396, 75575, 75608, 77891, 77938}
		craftQuests = {70539, 70540, 70545, 70557}
		hiddenMaster = 70252
		drops = {}
		drops[1] = {questID = 66379, itemID = 193902, source = "Treasures"}
		drops[2] = {questID = 66380, itemID = 193903, source = "Treasures"}
		drops[3] = {questID = 70516, itemID = 198969, source = "Mobs: Keeper"}
		drops[4] = {questID = 70517, itemID = 198970, source = "Mobs: Dragonkin"}
		drops[5] = {questID = 74934, itemID = 204227, source = "Fimbol"}
		treasures = {}
		-- 10.0
		treasures[70270] = 201014	-- Boomthyr Rocket
		treasures[70275] = 198789	-- Intact Coil Capacitor
		-- 10.1
		treasures[75180] = 204469	-- Misplaced Aberrus Outflow Blueprints
		treasures[75183] = 204470	-- Haphazardly Discarded Bomb
		treasures[75184] = 204471	-- Defective Survival Pack
		treasures[75186] = 204475	-- Busted Wyrmhole Generator
		treasures[75188] = 204480	-- Inconspicuous Data Miner
		treasures[75430] = 204850	-- Handful of Khaz'gorite Bolts
		treasures[75431] = 204853	-- Discarded Dracothyst Drill
		treasures[75433] = 204855	-- Overclocked Determination Core
		-- 10.2
		treasures[78278] = 210193	-- Experimental Dreamcatcher
		treasures[78279] = 210194	-- Insomniotron
		treasures[78281] = 210197	-- Unhatched Battery
		books = {}
		books[1] = {questID = 71896, itemID = 200977}
		books[2] = {questID = 71907, itemID = 201273}
		books[3] = {questID = 71918, itemID = 201284}
		books[4] = {questID = 75759, itemID = 205349}
		books[5] = {questID = 75844, itemID = 205425}
		books[6] = {questID = 75851, itemID = 205436}
		renown = {}
		renown[1] = {factionID = 2507, questID1 = 72300, questID2 = 72305}
		renown[2] = {factionID = 2510, questID1 = 72330, questID2 = 70902}
		dmf = 29511
	end

	-- Enchanting
	if professionID == 9 then
		treatiseItem = 194702
		treatiseQuest = 74110
		orderQuest = nil
		gatherQuests = {66884, 66900, 66935, 72423, 75150, 75865, 77910, 77937}
		craftQuests = {72155, 72172, 72173, 72175}
		hiddenMaster = 70251
		drops = {}
		drops[1] = {questID = 66377, itemID = 193900, source = "Treasures"}
		drops[2] = {questID = 66378, itemID = 193901, source = "Treasures"}
		drops[3] = {questID = 70514, itemID = 198967, source = "Mobs: Arcane"}
		drops[4] = {questID = 70515, itemID = 198968, source = "Mobs: Primalist"}
		drops[5] = {questID = 74927, itemID = 204224, source = "Manathema"}
		treasures = {}
		-- 10.0
		treasures[70272] = 201012	-- Enchanted Debris
		treasures[70283] = 198675	-- Lava-Infused Seed
		treasures[70290] = 201013	-- Faintly Enchanted Remains
		treasures[70291] = 198689	-- Stormbound Horn
		treasures[70298] = 198694	-- Enriched Earthen Shard
		treasures[70320] = 198798	-- Flashfrozen Scroll
		treasures[70336] = 198799	-- Forgotten Arcane Tome
		treasures[70342] = 198800	-- Fractured Titanic Sphere
		-- 10.1
		treasures[75508] = 204990	-- Lava-Drenched Shadow Crystal
		treasures[75509] = 204999	-- Shimmering Aqueous Orb
		treasures[75510] = 205001	-- Resonating Arcane Crystal
		-- 10.2
		treasures[78308] = 210228	-- Pure Dream Water
		treasures[78309] = 210231	-- Everburning Core
		treasures[78310] = 210234	-- Essence of Dreams
		books = {}
		books[1] = {questID = 71895, itemID = 200976}
		books[2] = {questID = 71906, itemID = 201272}
		books[3] = {questID = 71917, itemID = 201283}
		books[4] = {questID = 75752, itemID = 205351}
		books[5] = {questID = 75845, itemID = 205427}
		books[6] = {questID = 75850, itemID = 205438}
		renown = {}
		renown[1] = {factionID = 2507, questID1 = 72299, questID2 = 72304}
		renown[2] = {factionID = 2511, questID1 = 72318, questID2 = 72323}
		dmf = 29510
	end

	-- Skinning
	if professionID == 11 then
		treatiseItem = 201023
		treatiseQuest = 74114
		orderQuest = nil
		gatherQuests = {70619, 70620, 72158, 72159}
		craftQuests = nil
		hiddenMaster = 70259
		drops = {}
		drops[1] = {questID = 70381, itemID = 198837, source = "Skinning"}
		drops[2] = {questID = 70383, itemID = 198837, source = "Skinning"}
		drops[3] = {questID = 70384, itemID = 198837, source = "Skinning"}
		drops[4] = {questID = 70385, itemID = 198837, source = "Skinning"}
		drops[5] = {questID = 70386, itemID = 198837, source = "Skinning"}
		drops[6] = {questID = 70389, itemID = 198841, source = "Skinning"}
		drops[7] = {questID = 74930, itemID = 204231, source = "Faunos"}
		treasures = nil
		books = {}
		books[1] = {questID = 71902, itemID = 200982}
		books[2] = {questID = 71913, itemID = 201278}
		books[3] = {questID = 71924, itemID = 201289}
		books[4] = {questID = 75760, itemID = 205357}
		books[5] = {questID = 75838, itemID = 205433}
		books[6] = {questID = 75857, itemID = 205444}
		renown = {}
		renown[1] = {factionID = 2503, questID1 = 72310, questID2 = 72317}
		renown[2] = {factionID = 2511, questID1 = 72322, questID2 = 72327}
		dmf = 29519
	end

	-- Jewelcrafting
	if professionID == 12 then
		treatiseItem = 194703
		treatiseQuest = 74112
		orderQuest = 70593
		gatherQuests = {66516, 66949, 66950, 72428, 75362, 75602, 77892, 77912}
		craftQuests = {70562, 70563, 70564, 70565}
		hiddenMaster = 70255
		drops = {}
		drops[1] = {questID = 66388, itemID = 193909, source = "Treasures"}
		drops[2] = {questID = 66389, itemID = 193907, source = "Treasures"}
		drops[3] = {questID = 70520, itemID = 198973, source = "Mobs: Elemental"}
		drops[4] = {questID = 70521, itemID = 198974, source = "Mobs: Dragonkin"}
		drops[5] = {questID = 74936, itemID = 204222, source = "Amephyst"}
		treasures = {}
		-- 10.0
		treasures[70273] = 201017	-- Igneous Gem
		treasures[70292] = 198687	-- Closely Guarded Shiny
		treasures[70271] = 201016	-- Harmonic Crystal Harmonizer
		treasures[70277] = 198664	-- Crystalline Overgrowth
		treasures[70282] = 198670	-- Lofty Malygite
		treasures[70263] = 198660	-- Fragmented Key
		treasures[70261] = 198656	-- Painter's Pretty Jewel
		treasures[70285] = 198682	-- Alexstraszite Cluster
		-- 10.1
		treasures[75652] = 205214	-- Snubbed Snail Shells
		treasures[75653] = 205216	-- Gently Jostled Jewels
		treasures[75654] = 205219	-- Broken Barter Boulder
		-- 10.2
		treasures[78282] = 210200	-- Petrified Hope
		treasures[78283] = 210201	-- Handful of Pebbles
		treasures[78285] = 210202	-- Coalesced Dreamstone
		books = {}
		books[1] = {questID = 71899, itemID = 200978}
		books[2] = {questID = 71910, itemID = 201274}
		books[3] = {questID = 71921, itemID = 201285}
		books[4] = {questID = 75754, itemID = 205348}
		books[5] = {questID = 75841, itemID = 205424}
		books[6] = {questID = 75854, itemID = 205435}
		renown = {}
		renown[1] = {factionID = 2507, questID1 = 72301, questID2 = 72306}
		renown[2] = {factionID = 2511, questID1 = 72320, questID2 = 72325}
		dmf = 29516
	end

	-- Inscription
	if professionID == 13 then
		treatiseItem = 194699
		treatiseQuest = 74105
		orderQuest = 70592
		gatherQuests = {66943, 66944, 66945, 72438, 75149, 75573, 77889, 77914}
		craftQuests = {70558, 70559, 70560, 70561}
		hiddenMaster = 70254
		drops = {}
		drops[1] = {questID = 66375, itemID = 193904, source = "Treasures"}
		drops[2] = {questID = 66376, itemID = 193905, source = "Treasures"}
		drops[3] = {questID = 70518, itemID = 198971, source = "Mobs: Djaradin"}
		drops[4] = {questID = 70519, itemID = 198972, source = "Mobs: Dragonkin"}
		drops[5] = {questID = 74932, itemID = 204229, source = "Arcantrix"}
		treasures = {}
		-- 10.0
		treasures[70248] = 198659	-- Forgetful Apprentice's Tome 1
		treasures[70264] = 198659	-- Forgetful Apprentice's Tome 2
		treasures[70281] = 198669	-- How to Train Your Whelpling
		treasures[70287] = 201015	-- Counterfeit Darkmoon Deck
		treasures[70293] = 198686	-- Frosted Parchment
		treasures[70297] = 198693	-- Dusty Darkmoon Card
		treasures[70306] = 198704	-- Pulsing Earth Rune
		treasures[70307] = 198703	-- Sign Language Reference Sheet
		-- 10.1
		treasures[76117] = 206031	-- Intricate Zaqali Runes
		treasures[76120] = 206034	-- Hissing Rune Draft
		treasures[76121] = 206035	-- Ancient Research
		-- 10.2
		treasures[78411] = 210458	-- Winnie's Notes on Flora and Fauna
		treasures[78412] = 210459	-- Grove Keeper's Pillar
		treasures[78413] = 210460	-- Primalist Shadowbinding Rune
		books = {}
		books[1] = {questID = 71898, itemID = 200973}
		books[2] = {questID = 71909, itemID = 201269}
		books[3] = {questID = 71920, itemID = 201280}
		books[4] = {questID = 75761, itemID = 205354}
		books[5] = {questID = 75842, itemID = 205430}
		books[6] = {questID = 75853, itemID = 205441}
		renown = {}
		renown[1] = {factionID = 2507, questID1 = 72294, questID2 = 72295}
		renown[2] = {factionID = 2510, questID1 = 72331, questID2 = 72334}
		dmf = 29515
	end

	-- Professions with Knowledge Points
	if professionID == 1
	or professionID == 2
	or professionID == 3
	or professionID == 4
	or professionID == 6
	or professionID == 7
	or professionID == 8
	or professionID == 9
	or professionID == 11
	or professionID == 12
	or professionID == 13 then
		-- When not viewing another character's
		if C_TradeSkillUI.IsTradeSkillLinked() == false and C_TradeSkillUI.IsTradeSkillGuild() == false then
			setKnowledgePointTracker()
			kpTooltip()
		end
	else
		knowledgePointTracker:Hide()
	end
end

----------------------
-- EVENT COMPONENTS --
----------------------

-- When the AddOn is fully loaded
function event:ADDON_LOADED(addOnName, containsBindings)
	if addOnName == appName then
		app.InitialiseProfessionKnowledge()
	end
end

-- When a tradeskill window is opened
function event:TRADE_SKILL_SHOW()
	if C_AddOns.IsAddOnLoaded("Blizzard_Professions") == true then
		app.CreateProfessionKnowledgeAssets()
	end
end

-- When a recipe is selected (also used to determine professionID, which TRADE_SKILL_SHOW() is too quick for)
function event:SPELL_DATA_LOAD_RESULT(spellID, success)
	if C_AddOns.IsAddOnLoaded("Blizzard_Professions") == true then
		app.KnowledgeTracker()
	end
end