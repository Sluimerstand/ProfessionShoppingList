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
event:RegisterEvent("TRAIT_CONFIG_UPDATED")

------------------
-- INITIAL LOAD --
------------------

-- Create default user settings and session variables
function app.InitialiseProfessionKnowledge()
	-- Initialise session variables
	app.Flag["knowledgeAssets"] = false
end

-- When the AddOn is fully loaded
function event:ADDON_LOADED(addOnName, containsBindings)
	if addOnName == appName then
		app.InitialiseProfessionKnowledge()
	end
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

	app.Flag["knowledgeAssets"] = true
end

-- Populate knowledge tracker
function app.KnowledgeTracker()
	-- Show stuff depending on which profession+expansion is opened
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
		knowledgePointTracker.Text:SetText(perksEarned.."/"..perkCount.." perks unlocked ("..knowledgeSpent.."/"..knowledgeMax.." knowledge)")
		knowledgePointTracker.Bar:SetMinMaxSmoothedValue(0, knowledgeMax)
		knowledgePointTracker.Bar:SetSmoothedValue(knowledgeSpent)
		knowledgePointTracker.Bar:SetStatusBarTexture("Interface\\AddOns\\ProfessionShoppingList\\assets\\profbars\\"..professionID..".blp")
		knowledgePointTracker:Show()
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
		end
	else
		knowledgePointTracker:Hide()
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
	if C_AddOns.IsAddOnLoaded("Blizzard_Professions") == true and app.Flag["knowledgeAssets"] == true then
		app.KnowledgeTracker()
	end
end

-- When profession knowledge is spent
function event:TRAIT_CONFIG_UPDATED(spellID, success)
	if C_AddOns.IsAddOnLoaded("Blizzard_Professions") == true and app.Flag["knowledgeAssets"] == true then
		app.KnowledgeTracker()
	end
end