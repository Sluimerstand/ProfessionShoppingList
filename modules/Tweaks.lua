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
event:RegisterEvent("LFG_PROPOSAL_SHOW")
event:RegisterEvent("MERCHANT_SHOW")
event:RegisterEvent("PET_BATTLE_QUEUE_PROPOSE_MATCH")

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