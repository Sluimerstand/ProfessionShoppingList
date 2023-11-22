-- Database.lua: Raw information to refer to

-- Initialisation
local appName, app = ...	-- Returns the addon name and a unique table

-- Used textures
app.iconWaiting = "Interface\\RaidFrame\\ReadyCheck-Waiting"
app.iconReady = "Interface\\RaidFrame\\ReadyCheck-Ready"
app.iconNotReady = "Interface\\RaidFrame\\ReadyCheck-NotReady"

-- Shadowlands Legendary craft SpellIDs
app.slLegendaryRecipeIDs = {}
app.slLegendaryRecipeIDs[307705] = { rank = 1, one = 307705, two = 332006, three = 332041, four = 338976 }
app.slLegendaryRecipeIDs[307712] = { rank = 1, one = 307712, two = 332013, three = 332048, four = 338968 }
app.slLegendaryRecipeIDs[307710] = { rank = 1, one = 307710, two = 332011, three = 332046, four = 338970 }
app.slLegendaryRecipeIDs[307708] = { rank = 1, one = 307708, two = 332009, three = 332044, four = 338972 }
app.slLegendaryRecipeIDs[307709] = { rank = 1, one = 307709, two = 332010, three = 332045, four = 338971 }
app.slLegendaryRecipeIDs[307707] = { rank = 1, one = 307707, two = 332008, three = 332043, four = 338974 }
app.slLegendaryRecipeIDs[307711] = { rank = 1, one = 307711, two = 332012, three = 332047, four = 338969 }
app.slLegendaryRecipeIDs[307706] = { rank = 1, one = 307706, two = 332007, three = 332042, four = 338975 }
app.slLegendaryRecipeIDs[309205] = { rank = 1, one = 309205, two = 332021, three = 332056, four = 338986 }
app.slLegendaryRecipeIDs[309200] = { rank = 1, one = 309200, two = 332016, three = 332051, four = 338981 }
app.slLegendaryRecipeIDs[309201] = { rank = 1, one = 309201, two = 332017, three = 332052, four = 338982 }
app.slLegendaryRecipeIDs[309202] = { rank = 1, one = 309202, two = 332018, three = 332053, four = 338983 }
app.slLegendaryRecipeIDs[309203] = { rank = 1, one = 309203, two = 332019, three = 332054, four = 338984 }
app.slLegendaryRecipeIDs[309198] = { rank = 1, one = 309198, two = 332014, three = 332049, four = 338980 }
app.slLegendaryRecipeIDs[309199] = { rank = 1, one = 309199, two = 332015, three = 332050, four = 338979 }
app.slLegendaryRecipeIDs[309204] = { rank = 1, one = 309204, two = 332020, three = 332055, four = 338985 }
app.slLegendaryRecipeIDs[309213] = { rank = 1, one = 309213, two = 332029, three = 332064, four = 338994 }
app.slLegendaryRecipeIDs[309208] = { rank = 1, one = 309208, two = 332024, three = 332059, four = 338989 }
app.slLegendaryRecipeIDs[309209] = { rank = 1, one = 309209, two = 332025, three = 332060, four = 338990 }
app.slLegendaryRecipeIDs[309210] = { rank = 1, one = 309210, two = 332026, three = 332061, four = 338991 }
app.slLegendaryRecipeIDs[309211] = { rank = 1, one = 309211, two = 332027, three = 332062, four = 338992 }
app.slLegendaryRecipeIDs[309206] = { rank = 1, one = 309206, two = 332022, three = 332057, four = 338988 }
app.slLegendaryRecipeIDs[309207] = { rank = 1, one = 309207, two = 332023, three = 332058, four = 338987 }
app.slLegendaryRecipeIDs[309212] = { rank = 1, one = 309212, two = 332028, three = 332063, four = 338993 }
app.slLegendaryRecipeIDs[310885] = { rank = 1, one = 310885, two = 332037, three = 332072, four = 339003 }
app.slLegendaryRecipeIDs[310886] = { rank = 1, one = 310886, two = 332038, three = 332073, four = 339004 }
app.slLegendaryRecipeIDs[310880] = { rank = 1, one = 310880, two = 332032, three = 332067, four = 338995 }
app.slLegendaryRecipeIDs[310882] = { rank = 1, one = 310882, two = 332034, three = 332069, four = 339000 }
app.slLegendaryRecipeIDs[310881] = { rank = 1, one = 310881, two = 332033, three = 332068, four = 338998 }
app.slLegendaryRecipeIDs[310883] = { rank = 1, one = 310883, two = 332035, three = 332070, four = 339001 }
app.slLegendaryRecipeIDs[310879] = { rank = 1, one = 310879, two = 332031, three = 332066, four = 338996 }
app.slLegendaryRecipeIDs[310878] = { rank = 1, one = 310878, two = 332030, three = 332065, four = 338997 }
app.slLegendaryRecipeIDs[310884] = { rank = 1, one = 310884, two = 332036, three = 332071, four = 339002 }
app.slLegendaryRecipeIDs[327920] = { rank = 1, one = 327920, two = 332039, three = 332074, four = 338978 }
app.slLegendaryRecipeIDs[327921] = { rank = 1, one = 327921, two = 332040, three = 332075, four = 338977 }
app.slLegendaryRecipeIDs[332006] = { rank = 2, one = 307705, two = 332006, three = 332041, four = 338976 }
app.slLegendaryRecipeIDs[332013] = { rank = 2, one = 307712, two = 332013, three = 332048, four = 338968 }
app.slLegendaryRecipeIDs[332011] = { rank = 2, one = 307710, two = 332011, three = 332046, four = 338970 }
app.slLegendaryRecipeIDs[332009] = { rank = 2, one = 307708, two = 332009, three = 332044, four = 338972 }
app.slLegendaryRecipeIDs[332010] = { rank = 2, one = 307709, two = 332010, three = 332045, four = 338971 }
app.slLegendaryRecipeIDs[332008] = { rank = 2, one = 307707, two = 332008, three = 332043, four = 338974 }
app.slLegendaryRecipeIDs[332012] = { rank = 2, one = 307711, two = 332012, three = 332047, four = 338969 }
app.slLegendaryRecipeIDs[332007] = { rank = 2, one = 307706, two = 332007, three = 332042, four = 338975 }
app.slLegendaryRecipeIDs[332021] = { rank = 2, one = 309205, two = 332021, three = 332056, four = 338986 }
app.slLegendaryRecipeIDs[332016] = { rank = 2, one = 309200, two = 332016, three = 332051, four = 338981 }
app.slLegendaryRecipeIDs[332017] = { rank = 2, one = 309201, two = 332017, three = 332052, four = 338982 }
app.slLegendaryRecipeIDs[332018] = { rank = 2, one = 309202, two = 332018, three = 332053, four = 338983 }
app.slLegendaryRecipeIDs[332019] = { rank = 2, one = 309203, two = 332019, three = 332054, four = 338984 }
app.slLegendaryRecipeIDs[332014] = { rank = 2, one = 309198, two = 332014, three = 332049, four = 338980 }
app.slLegendaryRecipeIDs[332015] = { rank = 2, one = 309199, two = 332015, three = 332050, four = 338979 }
app.slLegendaryRecipeIDs[332020] = { rank = 2, one = 309204, two = 332020, three = 332055, four = 338985 }
app.slLegendaryRecipeIDs[332029] = { rank = 2, one = 309213, two = 332029, three = 332064, four = 338994 }
app.slLegendaryRecipeIDs[332024] = { rank = 2, one = 309208, two = 332024, three = 332059, four = 338989 }
app.slLegendaryRecipeIDs[332025] = { rank = 2, one = 309209, two = 332025, three = 332060, four = 338990 }
app.slLegendaryRecipeIDs[332026] = { rank = 2, one = 309210, two = 332026, three = 332061, four = 338991 }
app.slLegendaryRecipeIDs[332027] = { rank = 2, one = 309211, two = 332027, three = 332062, four = 338992 }
app.slLegendaryRecipeIDs[332022] = { rank = 2, one = 309206, two = 332022, three = 332057, four = 338988 }
app.slLegendaryRecipeIDs[332023] = { rank = 2, one = 309207, two = 332023, three = 332058, four = 338987 }
app.slLegendaryRecipeIDs[332028] = { rank = 2, one = 309212, two = 332028, three = 332063, four = 338993 }
app.slLegendaryRecipeIDs[332037] = { rank = 2, one = 310885, two = 332037, three = 332072, four = 339003 }
app.slLegendaryRecipeIDs[332038] = { rank = 2, one = 310886, two = 332038, three = 332073, four = 339004 }
app.slLegendaryRecipeIDs[332032] = { rank = 2, one = 310880, two = 332032, three = 332067, four = 338995 }
app.slLegendaryRecipeIDs[332034] = { rank = 2, one = 310882, two = 332034, three = 332069, four = 339000 }
app.slLegendaryRecipeIDs[332033] = { rank = 2, one = 310881, two = 332033, three = 332068, four = 338998 }
app.slLegendaryRecipeIDs[332035] = { rank = 2, one = 310883, two = 332035, three = 332070, four = 339001 }
app.slLegendaryRecipeIDs[332031] = { rank = 2, one = 310879, two = 332031, three = 332066, four = 338996 }
app.slLegendaryRecipeIDs[332030] = { rank = 2, one = 310878, two = 332030, three = 332065, four = 338997 }
app.slLegendaryRecipeIDs[332036] = { rank = 2, one = 310884, two = 332036, three = 332071, four = 339002 }
app.slLegendaryRecipeIDs[332039] = { rank = 2, one = 327920, two = 332039, three = 332074, four = 338978 }
app.slLegendaryRecipeIDs[332040] = { rank = 2, one = 327921, two = 332040, three = 332075, four = 338977 }
app.slLegendaryRecipeIDs[332041] = { rank = 3, one = 307705, two = 332006, three = 332041, four = 338976 }
app.slLegendaryRecipeIDs[332048] = { rank = 3, one = 307712, two = 332013, three = 332048, four = 338968 }
app.slLegendaryRecipeIDs[332046] = { rank = 3, one = 307710, two = 332011, three = 332046, four = 338970 }
app.slLegendaryRecipeIDs[332044] = { rank = 3, one = 307708, two = 332009, three = 332044, four = 338972 }
app.slLegendaryRecipeIDs[332045] = { rank = 3, one = 307709, two = 332010, three = 332045, four = 338971 }
app.slLegendaryRecipeIDs[332043] = { rank = 3, one = 307707, two = 332008, three = 332043, four = 338974 }
app.slLegendaryRecipeIDs[332047] = { rank = 3, one = 307711, two = 332012, three = 332047, four = 338969 }
app.slLegendaryRecipeIDs[332042] = { rank = 3, one = 307706, two = 332007, three = 332042, four = 338975 }
app.slLegendaryRecipeIDs[332056] = { rank = 3, one = 309205, two = 332021, three = 332056, four = 338986 }
app.slLegendaryRecipeIDs[332051] = { rank = 3, one = 309200, two = 332016, three = 332051, four = 338981 }
app.slLegendaryRecipeIDs[332052] = { rank = 3, one = 309201, two = 332017, three = 332052, four = 338982 }
app.slLegendaryRecipeIDs[332053] = { rank = 3, one = 309202, two = 332018, three = 332053, four = 338983 }
app.slLegendaryRecipeIDs[332054] = { rank = 3, one = 309203, two = 332019, three = 332054, four = 338984 }
app.slLegendaryRecipeIDs[332049] = { rank = 3, one = 309198, two = 332014, three = 332049, four = 338980 }
app.slLegendaryRecipeIDs[332050] = { rank = 3, one = 309199, two = 332015, three = 332050, four = 338979 }
app.slLegendaryRecipeIDs[332055] = { rank = 3, one = 309204, two = 332020, three = 332055, four = 338985 }
app.slLegendaryRecipeIDs[332064] = { rank = 3, one = 309213, two = 332029, three = 332064, four = 338994 }
app.slLegendaryRecipeIDs[332059] = { rank = 3, one = 309208, two = 332024, three = 332059, four = 338989 }
app.slLegendaryRecipeIDs[332060] = { rank = 3, one = 309209, two = 332025, three = 332060, four = 338990 }
app.slLegendaryRecipeIDs[332061] = { rank = 3, one = 309210, two = 332026, three = 332061, four = 338991 }
app.slLegendaryRecipeIDs[332062] = { rank = 3, one = 309211, two = 332027, three = 332062, four = 338992 }
app.slLegendaryRecipeIDs[332057] = { rank = 3, one = 309206, two = 332022, three = 332057, four = 338988 }
app.slLegendaryRecipeIDs[332058] = { rank = 3, one = 309207, two = 332023, three = 332058, four = 338987 }
app.slLegendaryRecipeIDs[332063] = { rank = 3, one = 309212, two = 332028, three = 332063, four = 338993 }
app.slLegendaryRecipeIDs[332072] = { rank = 3, one = 310885, two = 332037, three = 332072, four = 339003 }
app.slLegendaryRecipeIDs[332073] = { rank = 3, one = 310886, two = 332038, three = 332073, four = 339004 }
app.slLegendaryRecipeIDs[332067] = { rank = 3, one = 310880, two = 332032, three = 332067, four = 338995 }
app.slLegendaryRecipeIDs[332069] = { rank = 3, one = 310882, two = 332034, three = 332069, four = 339000 }
app.slLegendaryRecipeIDs[332068] = { rank = 3, one = 310881, two = 332033, three = 332068, four = 338998 }
app.slLegendaryRecipeIDs[332070] = { rank = 3, one = 310883, two = 332035, three = 332070, four = 339001 }
app.slLegendaryRecipeIDs[332066] = { rank = 3, one = 310879, two = 332031, three = 332066, four = 338996 }
app.slLegendaryRecipeIDs[332065] = { rank = 3, one = 310878, two = 332030, three = 332065, four = 338997 }
app.slLegendaryRecipeIDs[332071] = { rank = 3, one = 310884, two = 332036, three = 332071, four = 339002 }
app.slLegendaryRecipeIDs[332074] = { rank = 3, one = 327920, two = 332039, three = 332074, four = 338978 }
app.slLegendaryRecipeIDs[332075] = { rank = 3, one = 327921, two = 332040, three = 332075, four = 338977 }
app.slLegendaryRecipeIDs[338976] = { rank = 4, one = 307705, two = 332006, three = 332041, four = 338976 }
app.slLegendaryRecipeIDs[338968] = { rank = 4, one = 307712, two = 332013, three = 332048, four = 338968 }
app.slLegendaryRecipeIDs[338970] = { rank = 4, one = 307710, two = 332011, three = 332046, four = 338970 }
app.slLegendaryRecipeIDs[338972] = { rank = 4, one = 307708, two = 332009, three = 332044, four = 338972 }
app.slLegendaryRecipeIDs[338971] = { rank = 4, one = 307709, two = 332010, three = 332045, four = 338971 }
app.slLegendaryRecipeIDs[338974] = { rank = 4, one = 307707, two = 332008, three = 332043, four = 338974 }
app.slLegendaryRecipeIDs[338969] = { rank = 4, one = 307711, two = 332012, three = 332047, four = 338969 }
app.slLegendaryRecipeIDs[338975] = { rank = 4, one = 307706, two = 332007, three = 332042, four = 338975 }
app.slLegendaryRecipeIDs[338986] = { rank = 4, one = 309205, two = 332021, three = 332056, four = 338986 }
app.slLegendaryRecipeIDs[338981] = { rank = 4, one = 309200, two = 332016, three = 332051, four = 338981 }
app.slLegendaryRecipeIDs[338982] = { rank = 4, one = 309201, two = 332017, three = 332052, four = 338982 }
app.slLegendaryRecipeIDs[338983] = { rank = 4, one = 309202, two = 332018, three = 332053, four = 338983 }
app.slLegendaryRecipeIDs[338984] = { rank = 4, one = 309203, two = 332019, three = 332054, four = 338984 }
app.slLegendaryRecipeIDs[338980] = { rank = 4, one = 309198, two = 332014, three = 332049, four = 338980 }
app.slLegendaryRecipeIDs[338979] = { rank = 4, one = 309199, two = 332015, three = 332050, four = 338979 }
app.slLegendaryRecipeIDs[338985] = { rank = 4, one = 309204, two = 332020, three = 332055, four = 338985 }
app.slLegendaryRecipeIDs[338994] = { rank = 4, one = 309213, two = 332029, three = 332064, four = 338994 }
app.slLegendaryRecipeIDs[338989] = { rank = 4, one = 309208, two = 332024, three = 332059, four = 338989 }
app.slLegendaryRecipeIDs[338990] = { rank = 4, one = 309209, two = 332025, three = 332060, four = 338990 }
app.slLegendaryRecipeIDs[338991] = { rank = 4, one = 309210, two = 332026, three = 332061, four = 338991 }
app.slLegendaryRecipeIDs[338992] = { rank = 4, one = 309211, two = 332027, three = 332062, four = 338992 }
app.slLegendaryRecipeIDs[338988] = { rank = 4, one = 309206, two = 332022, three = 332057, four = 338988 }
app.slLegendaryRecipeIDs[338987] = { rank = 4, one = 309207, two = 332023, three = 332058, four = 338987 }
app.slLegendaryRecipeIDs[338993] = { rank = 4, one = 309212, two = 332028, three = 332063, four = 338993 }
app.slLegendaryRecipeIDs[339003] = { rank = 4, one = 310885, two = 332037, three = 332072, four = 339003 }
app.slLegendaryRecipeIDs[339004] = { rank = 4, one = 310886, two = 332038, three = 332073, four = 339004 }
app.slLegendaryRecipeIDs[338995] = { rank = 4, one = 310880, two = 332032, three = 332067, four = 338995 }
app.slLegendaryRecipeIDs[339000] = { rank = 4, one = 310882, two = 332034, three = 332069, four = 339000 }
app.slLegendaryRecipeIDs[338998] = { rank = 4, one = 310881, two = 332033, three = 332068, four = 338998 }
app.slLegendaryRecipeIDs[339001] = { rank = 4, one = 310883, two = 332035, three = 332070, four = 339001 }
app.slLegendaryRecipeIDs[338996] = { rank = 4, one = 310879, two = 332031, three = 332066, four = 338996 }
app.slLegendaryRecipeIDs[338997] = { rank = 4, one = 310878, two = 332030, three = 332065, four = 338997 }
app.slLegendaryRecipeIDs[339002] = { rank = 4, one = 310884, two = 332036, three = 332071, four = 339002 }
app.slLegendaryRecipeIDs[338978] = { rank = 4, one = 327920, two = 332039, three = 332074, four = 338978 }
app.slLegendaryRecipeIDs[338977] = { rank = 4, one = 327921, two = 332040, three = 332075, four = 338977 }

-- NYI recipes
app.nyiRecipes = {}
app.nyiRecipes[2336] = true	-- Elixir of Tongues
app.nyiRecipes[2671] = true	-- Rough Bronze Bracers
app.nyiRecipes[7636] = true	-- Green Woolen Robe
app.nyiRecipes[8366] = true	-- Ironforge Chain
app.nyiRecipes[8368] = true	-- Ironforge Gauntlets
app.nyiRecipes[8778] = true	-- Boots of Darkness
app.nyiRecipes[9942] = true	-- Mithril Scale Gloves
app.nyiRecipes[9957] = true	-- Orcish War Leggings
app.nyiRecipes[9972] = true	-- Ornate Mithril Breastplate
app.nyiRecipes[9979] = true	-- Ornate Mithril Boots
app.nyiRecipes[9980] = true	-- Ornate Mithril Helm
app.nyiRecipes[10550] = true	-- Nightscape Cloak
app.nyiRecipes[12062] = true	-- Stormcloth Pants
app.nyiRecipes[12063] = true	-- Stormcloth Gloves
app.nyiRecipes[12068] = true	-- Stormcloth Vest
app.nyiRecipes[12083] = true	-- Stormcloth Headband
app.nyiRecipes[12087] = true	-- Stormcloth Shoulders
app.nyiRecipes[12090] = true	-- Stormcloth Boots
app.nyiRecipes[16960] = true	-- Thorium Greatsword
app.nyiRecipes[16965] = true	-- Bleakwood Hew
app.nyiRecipes[16967] = true	-- Inlaid Thorium Hammer
app.nyiRecipes[16980] = true	-- Rune Edge
app.nyiRecipes[16986] = true	-- Blood Talon
app.nyiRecipes[16987] = true	-- Darkspear
app.nyiRecipes[17632] = true	-- Alchemist's Stone
app.nyiRecipes[19106] = true	-- Onyxia Scale Breastplate
app.nyiRecipes[21924] = true	-- Runecloth Robe
app.nyiRecipes[24315] = true	-- Heavy Netherweave Net
app.nyiRecipes[28021] = true	-- Arcane Dust
app.nyiRecipes[29120] = true	-- Truefaith Vestments
app.nyiRecipes[30342] = true	-- Red Smoke Flare
app.nyiRecipes[30343] = true	-- Blue Smoke Flare
app.nyiRecipes[30549] = true	-- Critter Enlarger
app.nyiRecipes[30555] = true	-- Remote Mail Terminal
app.nyiRecipes[35518] = true	-- Bracers of Nimble Thought
app.nyiRecipes[35522] = true	-- Mantle of Nimble Thought
app.nyiRecipes[35525] = true	-- Swiftheal Mantle
app.nyiRecipes[35526] = true	-- Swiftheal Wraps
app.nyiRecipes[35544] = true	-- Hands of Eternal Light
app.nyiRecipes[35548] = true	-- Robe of Eternal Light
app.nyiRecipes[35551] = true	-- Sunfire Handwraps
app.nyiRecipes[35552] = true	-- Sunfire Robe
app.nyiRecipes[36665] = true	-- Netherflame Robe
app.nyiRecipes[36667] = true	-- Netherflame Belt
app.nyiRecipes[36668] = true	-- Netherflame Boots
app.nyiRecipes[36669] = true	-- Lifeblood Leggings
app.nyiRecipes[36670] = true	-- Lifeblood Belt
app.nyiRecipes[36672] = true	-- Lifeblood Bracers
app.nyiRecipes[41133] = true	-- Swiftsteel Shoulders
app.nyiRecipes[41135] = true	-- Dawnsteel Shoulders
app.nyiRecipes[44438] = true	-- Shoveltusk Soup
app.nyiRecipes[45547] = true	-- Succulent Orca Stew
app.nyiRecipes[46142] = true	-- Sunblessed Breastplate
app.nyiRecipes[168851] = true	-- Miniature Flying Carpet
app.nyiRecipes[169669] = true	-- Hexweave Cloth
app.nyiRecipes[173415] = true	-- Murloc Chew Toy