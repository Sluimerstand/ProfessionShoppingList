-- Core.lua: Main AddOn code (once cleaned up and reviewed)

-- Initialisation
local appName, app = ...	-- Returns the addon name and a unique table
app.api = {}	-- Create a table to use for our "API"
ProfessionShoppingList = app.api	-- Create a namespace for our "API"
-- local api = app.api	-- Our "API" prefix
-- local ScrollingTable = LibStub("ScrollingTable")	-- To refer to the ScrollingTable library