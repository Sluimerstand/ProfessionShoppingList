----------------------------------------
-- Profession Shopping List: ptBR.lua --
----------------------------------------
-- Portuguese (Brazil) localisation

-- Initialisation
local appName, app =  ...	-- Returns the AddOn name and a unique table
local L = app.locales

-- Only load this file when the appropriate locale is found
if GetLocale() ~= "ptBR" then return end

-- Main window
-- L.WINDOW_BUTTON_CLOSE =					"Close the window."
-- L.WINDOW_BUTTON_LOCK =					"Lock the window."
-- L.WINDOW_BUTTON_UNLOCK =				"Unlock the window."
-- L.WINDOW_BUTTON_SETTINGS =				"Open the settings."
-- L.WINDOW_BUTTON_CLEAR =					"Clear all tracked recipes."
-- L.WINDOW_BUTTON_AUCTIONATOR =			"Create an Auctionator shopping list.\n" ..
-- 										"Also initiates a search if you have the Shopping tab open at the Auction House."
-- L.WINDOW_BUTTON_CORNER =				"Double " .. app.IconLMB .. "|cffFFFFFF: Autosize to fit the window."

-- L.WINDOW_HEADER_RECIPES =				PROFESSIONS_RECIPES_TAB	-- "Recipes"
-- L.WINDOW_HEADER_ITEMS =					ITEMS	-- "Items"
-- L.WINDOW_HEADER_REAGENTS =				PROFESSIONS_COLUMN_HEADER_REAGENTS	-- "Reagents"
-- L.WINDOW_HEADER_COSTS =					"Costs"

-- L.WINDOW_TOOLTIP_RECIPES =				"Shift " .. app.IconLMB .. "|cffFFFFFF: Link the recipe.\n|r" ..
-- 										"Ctrl " .. app.IconLMB .. "|cffFFFFFF: Open the recipe (if known).\n|r" ..
-- 										"Alt " .. app.IconLMB .. "|cffFFFFFF: Attempt to craft this recipe (as many times as you have it tracked).\n\n|r" ..
-- 										app.IconRMB .. "|cffFFFFFF: Untrack 1 of the selected recipe.\n|r" ..
-- 										"Ctrl " .. app.IconRMB .. "|cffFFFFFF: Untrack all of the selected recipe."
-- L.WINDOW_TOOLTIP_REAGENTS =				"Shift " .. app.IconLMB .. "|cffFFFFFF: Link the reagent.\n|r" ..
-- 										"Ctrl " .. app.IconLMB .. "|cffFFFFFF: Add recipe for the selected subreagent, if it exists and is cached."
-- L.WINDOW_TOOLTIP_COOLDOWNS =			"Shift " .. app.IconRMB .. "|cffFFFFFF: Remove this specific cooldown reminder.\n|r" ..
-- 										"Ctrl " .. app.IconLMB .. "|cffFFFFFF: Open the recipe (if known).\n|r" ..
-- 										"Alt " .. app.IconLMB .. "|cffFFFFFF: Attempt to craft this recipe."
									
-- L.CLEAR_CONFIRMATION =					"This will clear all recipes."
-- L.CONFIRMATION =						"Do you wish to proceed?"
-- L.SUBREAGENTS1 =						"There are multiple recipes that can create"	-- Followed by an item link
-- L.SUBREAGENTS2 =						"Please select one of the following"
-- L.GOLD =								BONUS_ROLL_REWARD_MONEY	-- "Gold"

-- L.WARBANK_CHECKBOX =					"Include Warbank"
-- L.WARBANK_TOOLTIP =						"Because crafting orders cannot use items stored in the Warbank currently, you can disable tracking them."

-- Cooldowns
-- L.RECHARGED =							"Fully recharged"
-- L.READY =								"Ready"
-- L.DAYS =								"d"
-- L.HOURS =								"h"
-- L.MINUTES =								"m"
-- L.READY_TO_CRAFT =						"is ready to craft again on"	-- Preceded by a recipe name, followed by a character name

-- Recipe tracking
-- L.TRACK =								"Track"
-- L.UNTRACK =								"Untrack"
-- L.RANK =								RANK	-- "Rank"
-- L.RECRAFT_TOOLTIP =						"Select an item with a cached recipe to track it.\n" .. 
-- 										"To cache a recipe, open the profession the recipe belongs to on any character\nor view the item as a regular crafting order."
-- L.QUICKORDER =							"Quick Order"
-- L.QUICKORDER_TOOLTIP =					"|cffFF0000Instantly|r create a crafting order for the specified recipient.\n\n" ..
-- 										"Use |cffFFFFFFGUILD|r (all uppercase) to place a " .. PROFESSIONS_CRAFTING_FORM_ORDER_RECIPIENT_GUILD .. ".\n" ..	-- "Guild Order". Don't translate "|cffFFFFFFGUILD|r" as this is hardcoded
-- 										"Use a character name to place a " .. PROFESSIONS_CRAFTING_FORM_ORDER_RECIPIENT_PRIVATE .. ".\n" ..	-- "Personal Order"
-- 										"Recipients are saved per recipe."
-- L.LOCALREAGENTS_LABEL =					"Use local reagents"
-- L.LOCALREAGENTS_TOOLTIP =				"Use (the lowest quality) available local reagents. Which reagents are used |cffFF0000cannot|r be customised."
-- L.QUICKORDER_REPEAT_TOOLTIP =			"Repeat the last " .. L.QUICKORDER .. " done on this character."
-- L.RECIPIENT =							"Recipient"

-- Profession window
-- L.MILLING_INFO =						"Milling Information"
-- L.THAUMATURGY_INFO =					"Thaumaturgy Information"
-- L.FROM =								"from"	-- I will convert this whole section to item links, then this is the only localisation needed. I recommend skipping the rest of this section. :)

-- L.MILLING_CLASSIC =						"Sapphire Pigment: 25% from Golden Sansam, Dreamfoil, Mountain Silversage, Sorrowmoss, Icecap\n" ..
-- 										"Silvery Pigment: 75% from Golden Sansam, Dreamfoil, Mountain Silversage, Sorrowmoss, Icecap\n\n" ..
-- 										"Ruby Pigment: 25% from Firebloom, Purple Lotus, Arthas' Tears, Sungrass, Blindweed,\n      Ghost Mushroom, Gromsblood\n" ..
-- 										"Violet Pigment: 75% from Firebloom, Purple Lotus, Arthas' Tears, Sungrass, Blindweed,\n      Ghost Mushroom, Gromsblood\n\n" ..
-- 										"Indigo Pigment: 25% from Fadeleaf, Goldthorn, Khadgar's Whisker, Dragon's Teeth\n" ..
-- 										"Emerald Pigment: 75% from Fadeleaf, Goldthorn, Khadgar's Whisker, Dragon's Teeth\n\n" ..
-- 										"Burnt Pigment: 25% from Wild Steelbloom, Grave Moss, Kingsblood, Liferoot\n" ..
-- 										"Golden Pigment: 75% from Wild Steelbloom, Grave Moss, Kingsblood, Liferoot\n\n" ..
-- 										"Verdant Pigment: 25% from Mageroyal, Briarthorn, Swiftthistle, Bruiseweed, Stranglekelp\n" ..
-- 										"Dusky Pigment: 75% from Mageroyal, Briarthorn, Swiftthistle, Bruiseweed, Stranglekelp\n\n" ..
-- 										"Alabaster Pigment: 100% from Peacebloom, Silverleaf, Earthroot"
-- L.MILLING_TBC =							"Ebon Pigment: 25%\n" ..
-- 										"Nether Pigment: 100%"
-- L.MILLING_WOTLK =						"Icy Pigment: 25%\n" ..
-- 										"Azure Pigment: 100%"
-- L.MILLING_CATA =						"Burning Embers: 25%, 50% from Twilight Jasmine, Whiptail\n" ..
-- 										"Ashen Pigment: 100%"
-- L.MILLING_MOP =							"Misty Pigment: 25%, 50% from Fool's Cap\n" ..
-- 										"Shadow Pigment: 100%"
-- L.MILLING_WOD =							"Cerulean Pigment: 100%"
-- L.MILLING_LEGION =						"Sallow Pigment: 10%, 80% from Felwort\n" ..
-- 										"Roseate Pigment: 90%"
-- L.MILLING_BFA =							"Viridescent Pigment: 10%, 30% from Anchor Weed\n" ..
-- 										"Ultramarine Pigment: 25%\n" ..
-- 										"Crimson Pigment: 75%"
-- L.MILLING_SL =							"Tranquil Pigment: Nightshade\n" ..
-- 										"Luminous Pigment: Death Blossom, Rising Glory, Vigil's Torch\n" ..
-- 										"Umbral Pigment: Death's Blossom, Marrowroot, Widowbloom"
-- L.MILLING_DF =							"Blazing Pigment: Saxifrage\n" ..
-- 										"Flourishing Pigment: Writhebark\n" ..
-- 										"Serene Pigment: Bubble Poppy\n" ..
-- 										"Shimmering Pigment: Hochenblume"
-- L.MILLING_TWW =							"Blossom Pigment: Blessing Blossom\n" ..
-- 										"Luredrop Pigment: Luredrop\n" ..
-- 										"Orbinid Pigment: Orbinid\n" ..
-- 										"Nacreous Pigment: Mycobloom"
-- L.THAUMATURGY_TWW =						"Mercurial Transmutagen: Aqirite, Gloom Chitin, Luredrop, Orbinid\n" ..
-- 										"Ominous Transmutagen: Bismuth, Mycobloom, Storm Dust, Weavercloth\n" ..
-- 										"Volatile Transmutagen: Arathor's Spear, Blessing Blossom, Ironclaw Ore, Stormcharged Leather"

-- L.BUTTON_COOKINGFIRE =					app.IconLMB .. ": " .. BINDING_NAME_TARGETSELF .. ".\n" ..
-- 										app.IconRMB .. ": " .. STATUS_TEXT_TARGET .. "."
-- L.BUTTON_COOKINGPET =					app.IconLMB .. ": Summon this pet.\n" ..
-- 										app.IconRMB .. ": Switch between available pets."

-- Track new mogs
-- L.BUTTON_TRACKNEW =						"Track New Mogs"
-- L.CURRENT_SETTING =						"Current setting:"
-- L.MODE_APPEARANCES =					"new appearances"
-- L.MODE_SOURCES =						"new appearances and sources"
-- L.TRACK_NEW1 =							"This will check the"	-- Followed by a number
-- L.TRACK_NEW2 =							"visible recipes for"	-- Preceded by a number, followed by L.MODE_APPEARANCES or L.MODE_SOURCES
-- L.TRACK_NEW3 =							"Your game may freeze for a few seconds."
-- L.ADDED_RECIPES1 =						"Added"	-- Followed by a number
-- L.ADDED_RECIPES2 =						"eligible recipes"	-- Preceded by a number

-- Tooltip info
-- L.MORE_NEEDED =							"more needed" -- Preceded by a number
-- L.MADE_WITH =							"Made with"	-- Followed by a profession name such as "Blacksmithing" or "Leatherworking"
-- L.RECIPE_LEARNED =						"recipe learned"
-- L.RECIPE_UNLEARNED =					"recipe not learned"
-- L.REGION =								"Region"	-- Preceded by an abbreviated region name such as "EU" or "US"

-- Profession knowledge
-- L.PERKS_UNLOCKED =						"perks unlocked"
-- L.PROFESSION_KNOWLEDGE =				"knowledge"
-- L.VENDORS =								"Vendors"
-- L.RENOWN =								RENOWN_LEVEL_LABEL	-- "Renown "
-- L.WORLD =								"World"
-- L.HIDDEN_PROFESSION_MASTER =			"Hidden Profession Master"

-- Tweaks
-- L.CATALYSTBUTTON_LABEL =				"Instantly Catalyze"

-- Chat feedback
-- L.INVALID_PARAMETERS =					"Invalid parameters."
-- L.INVALID_RECIPEQUANTITY =				L.INVALID_PARAMETERS .. " Please enter a valid recipe quantity."
-- L.INVALID_RECIPE_CACHE =				L.INVALID_PARAMETERS .. " Please enter a cached recipeID."
-- L.INVALID_RECIPE_TRACKED =				L.INVALID_PARAMETERS .. " Please enter a tracked recipeID."
-- L.INVALID_ACHIEVEMENT =					L.INVALID_PARAMETERS .. " This is not a crafting achievement. No recipes were added."
-- L.INVALID_RESET_ARG =					L.INVALID_PARAMETERS .. " You can use the following arguments:"
-- L.INVALID_COMMAND =						"Invalid command. See " .. app.Colour("/psl settings") .. " for more info."
-- L.DEBUG_ENABLED =						"Debug mode enabled."
-- L.DEBUG_DISABLED =						"Debug mode disabled."
-- L.RESET_DONE =							"Data reset performed successfully."
-- L.REQUIRES_RELOAD =						"|cffFF0000" .. REQUIRES_RELOAD .. ".|r Use |cffFFFFFF/reload|r or relog."	-- "Requires Reload"

-- L.FALSE =								"false"
-- L.TRUE =								"true"
-- L.NOLASTORDER =							"No last " .. L.QUICKORDER .. " found."
-- L.ERROR =								"Error"
-- L.ERROR_CRAFTSIM =						L.ERROR .. ": Could not read the information from CraftSim."
-- L.ERROR_QUICKORDER =					L.ERROR .. ": " .. L.QUICKORDER  .. " failed. Sorry. :("
-- L.ERROR_REAGENTS =						L.ERROR .. ": Can't create a " .. L.QUICKORDER .. " for items with mandatory reagents. Sorry. :("
-- L.ERROR_WARBANK =						L.ERROR .. ": Can't create a " .. L.QUICKORDER .. " with items in the Warbank."
-- L.ERROR_GUILD =							L.ERROR .. ": Can't create a " .. PROFESSIONS_CRAFTING_FORM_ORDER_RECIPIENT_GUILD .. " while not in a guild."	-- "Guild Order"
-- L.ERROR_RECIPIENT =						L.ERROR .. ": Target recipient cannot craft that item. Please enter a valid recipient name."
-- L.ERROR_MULTISIM =						L.ERROR .. ": No simulated reagents have been used. Please only enable one of the following supported AddOns:"

-- L.VERSION_CHECK =						"There is a newer version of " .. app.NameLong .. " available:"

-- Settings
-- L.SETTINGS_TOOLTIP =					app.IconLMB .. "|cffFFFFFF: Toggle the window.\n" ..
-- 										app.IconRMB .. ": " .. L.WINDOW_BUTTON_SETTINGS

-- L.SETTINGS_MINIMAP_TITLE =				"Show Minimap Icon"
-- L.SETTINGS_MINIMAP_TOOLTIP =			"Show the minimap icon. If you disable this, " .. app.NameShort .. " is still available from the AddOn Compartment."
-- L.SETTINGS_COOLDOWNS_TITLE =			"Track Recipe Cooldowns"
-- L.SETTINGS_COOLDOWNS_TOOLTIP =			"Enable the tracking of recipe cooldowns. These will show in the tracking window, and in chat upon login if ready."
-- L.SETTINGS_TOOLTIP_TITLE =				"Show Tooltip Information"
-- L.SETTINGS_TOOLTIP_TOOLTIP =			"Show how many of a reagent you have/need on the item's tooltip."
-- L.SETTINGS_CRAFTTOOLTIP_TITLE =			"Show Crafting Information"
-- L.SETTINGS_CRAFTTOOLTIP_TOOLTIP =		"Show with which profession a piece of gear is made, and if the recipe is known on your account."
-- L.SETTINGS_REAGENTQUALITY_TITLE =		"Minimum Reagent Quality"
-- L.SETTINGS_REAGENTQUALITY_TOOLTIP =		"Set the minimum quality reagents need to be before " .. app.NameShort .. " includes them in the item count. CraftSim results will still override this."
-- L.SETTINGS_INCLUDEHIGHER_TITLE =		"Include Higher Quality"
-- L.SETTINGS_INCLUDEHIGHER_TOOLTIP =		"Set which higher qualities to include when tracking lower quality reagents. (I.e. whether to include owned tier 3 reagents when counting tier 1 reagents.)"
-- L.SETTINGS_COLLECTMODE_TITLE =			"Collection Mode"
-- L.SETTINGS_COLLECTMODE_TOOLTIP =		"Set which items are included when using the " .. app.Colour(L.BUTTON_TRACKNEW) .. " button."
-- L.SETTINGS_QUICKORDER_TITLE =			"Quick Order Duration"
-- L.SETTINGS_QUICKORDER_TOOLTIP =			"Set the duration for placing quick orders with " .. app.NameShort .. "."

-- L.SETTINGS_REAGENTTIER =				"Tier"	-- Followed by a number
-- L.SETTINGS_INCLUDE =					"Include"	-- Followed by "Tier X"
-- L.SETTINGS_ONLY_INCLUDE =				"Only include"	-- Followed by "Tier X"
-- L.SETTINGS_DONT_INCLUDE =				"Don't include higher qualities"
-- L.SETTINGS_APPEARANCES_TITLE =			WARDROBE	-- "Appearances"
-- L.SETTINGS_APPEARANCES_TEXT =			"Include items only if they have a new appearance."
-- L.SETTINGS_SOURCES_TITLE =				"Sources"
-- L.SETTINGS_SOURCES_TEXT =				"Include items if they are a new source, including for known appearances."
-- L.SETTINGS_DURATION_SHORT =				"Short (12 hours)"
-- L.SETTINGS_DURATION_MEDIUM =			"Medium (24 hours)"
-- L.SETTINGS_DURATION_LONG =				"Long (48 hours)"

-- L.SETTINGS_HEADER_TRACK =				"Tracking Window"
-- L.SETTINGS_PERSONALWINDOWS_TITLE =		"Window Position per Character"
-- L.SETTINGS_PERSONALWINDOWS_TOOLTIP =	"Save the window position per character, instead of account wide."	
-- L.SETTINGS_PERSONALRECIPES_TITLE =		"Track Recipes per Character"
-- L.SETTINGS_PERSONALRECIPES_TOOLTIP =	"Track recipes per character, instead of account wide."	
-- L.SETTINGS_SHOWREMAINING_TITLE =		"Show Remaining Reagents"
-- L.SETTINGS_SHOWREMAINING_TOOLTIP =		"Only show how many reagents you still need in the tracking window, instead of have/need."
-- L.SETTINGS_REMOVECRAFT_TITLE =			"Untrack on Craft"
-- L.SETTINGS_REMOVECRAFT_TOOLTIP =		"Remove one of a tracked recipe when you successfully craft it."
-- L.SETTINGS_CLOSEWHENDONE_TITLE =		"Close Window When Done"	
-- L.SETTINGS_CLOSEWHENDONE_TOOLTIP =		"Close the tracking window after crafting the last tracked recipe."

-- L.SETTINGS_HEADER_INFO =				"Information"
-- L.SETTINGS_SLASHCOMMANDS_TITLE =		"Slash Commands"
-- L.SETTINGS_SLASHCOMMANDS_TOOLTIP =		"Type these in chat to use them!"
-- L.SETTINGS_SLASH_TOGGLE =				"Toggle the tracking window."
-- L.SETTINGS_SLASH_RESETPOS =				"Reset the tracking window position."
-- L.SETTINGS_SLASH_RESET =				"Reset saved data."
-- L.SETTINGS_SLASH_TRACK =				"Track a recipe."
-- L.SETTINGS_SLASH_UNTRACK =				"Untrack a recipe."
-- L.SETTINGS_SLASH_UNTRACKALL =			"Untrack all of a recipe."
-- L.SETTINGS_SLASH_TRACKACHIE =			"Track the recipes needed for the linked achievement."
-- L.SETTINGS_SLASH_CRAFTINGACHIE =		"crafting achievement"
-- L.SETTINGS_SLASH_RECIPEID =				"recipeID"
-- L.SETTINGS_SLASH_QUANTITY =				"quantity"
-- L.SETTINGS_DEFAULT =					CHAT_DEFAULT	-- "Default"
-- L.SETTINGS_LTOR =						"Left-to-Right"
-- L.SETTINGS_RTOL =						"Right-to-Left"

-- L.SETTINGS_HEADER_TWEAKS =				"Tweaks"
-- L.SETTINGS_SPLITBAG_TITLE =				"Split Reagent Bag Count"
-- L.SETTINGS_SPLITBAG_TOOLTIP =			"Shows the free slots of your regular bags and your reagent bag separately on top of the backpack icon."
-- L.SETTINGS_BAG_EXPLAIN =				"- " .. CHAT_DEFAULT .. " means " .. app.NameShort .. " won't touch the game's default behavior.\n" ..
-- 										"- The other options let " .. app.NameShort .. " enforce that particular setting."
-- L.SETTINGS_CLEANBAG_TITLE =				BAG_CLEANUP_BAGS
-- L.SETTINGS_CLEANBAG_TOOLTIP =			"Let " ..  app.NameShort .. " enforce cleanup sorting direction.\n" .. L.SETTINGS_BAG_EXPLAIN
-- L.SETTINGS_LOOTBAG_TITLE =				"Loot Order"
-- L.SETTINGS_LOOTBAG_TOOLTIP =			"Let " .. app.NameShort .. " enforce loot sorting direction.\n" .. L.SETTINGS_BAG_EXPLAIN

-- L.SETTINGS_HEADER_OTHERTWEAKS =			"Other Tweaks"
-- L.SETTINGS_VENDORFILTER_TITLE =			"Disable Vendor Filter"
-- L.SETTINGS_VENDORFILTER_TOOLTIP =		"Automatically set all vendor filters to |cffFFFFFFAll|R to display items normally not shown to your class."
-- L.SETTINGS_CATALYSTBUTTON_TITLE =		"Show Catalyst Button"
-- L.SETTINGS_CATALYSTBUTTON_TOOLTIP =		"Show a button on the Revival Catalyst that allows you to instantly catalyze an item, skipping the 5 second confirmation timer."
-- L.SETTINGS_QUEUESOUND_TITLE =			"Play Queue Sound"
-- L.SETTINGS_QUEUESOUND_TOOLTIP =			"Play the Deadly Boss Mods style queue sound when any queue pops, including battlegrounds and pet battles."
-- L.SETTINGS_HANDYNOTESFIX_TITLE =		"Disable HandyNotes Alt " .. app.IconRMB
-- L.SETTINGS_HANDYNOTESFIX_TOOLTIP =		"Let " .. app.NameShort .. " disable HandyNotes' keybind on the map, re-enabling it for TomTom waypoints instead.\n\n" .. L.REQUIRES_RELOAD
-- L.SETTINGS_ORIBOSEXCHANGEFIX_TITLE =	"Fix Oribos Exchange Tooltip"
-- L.SETTINGS_ORIBOSEXCHANGEFIX_TOOLTIP =	"Let " .. app.NameShort .. " simplify and fix the tooltip provided by the Oribos Exchange AddOn:\n" ..
-- 										"- Round to the nearest gold.\n" ..
-- 										"- Fix recipe prices.\n" ..
-- 										"- Fix profession window prices.\n" ..
-- 										"- Show battle pet prices inside the existing tooltip."