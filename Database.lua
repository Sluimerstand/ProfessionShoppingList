--------------------------------------------
-- Profession Shopping List: Database.lua	--
--------------------------------------------
-- Raw information to refer to

-- Initialisation
local appName, app =  ...	-- Returns the AddOn name and a unique table

-- Used strings
app.Name = "Profession Shopping List"
app.NameLong = app.Colour("Profession Shopping List")
app.NameShort = app.Colour("PSL")

-- Used textures
app.IconPSL = "|TInterface\\AddOns\\ProfessionShoppingList\\assets\\psl_icon.blp:0|t"
app.IconWaiting = "|TInterface\\RaidFrame\\ReadyCheck-Waiting:0|t"
app.IconReady = "|TInterface\\RaidFrame\\ReadyCheck-Ready:0|t"
app.IconNotReady = "|TInterface\\RaidFrame\\ReadyCheck-NotReady:0|t"
app.IconArrow = "|TInterface\\AddOns\\ProfessionShoppingList\\assets\\UI-RaidFrame-Arrow-Cropped:0|t"
app.IconLMB = "|TInterface\\TutorialFrame\\UI-Tutorial-Frame:12:12:0:0:512:512:10:65:228:283|t"
app.IconRMB = "|TInterface\\TutorialFrame\\UI-Tutorial-Frame:12:12:0:0:512:512:10:65:330:385|t"
app.IconProfession = {}
app.IconProfession[0] = "|TInterface\\MoneyFrame\\UI-GoldIcon:0|t"	-- Vendor
app.IconProfession[1] = "|TInterface\\AddOns\\ProfessionShoppingList\\assets\\hammer-32:0|t"	-- Crafting order
app.IconProfession[164] = "|TInterface\\Icons\\ui_profession_blacksmithing:0|t"
app.IconProfession[165] = "|TInterface\\Icons\\ui_profession_leatherworking:0|t"
app.IconProfession[171] = "|TInterface\\Icons\\ui_profession_alchemy:0|t"
app.IconProfession[182] = "|TInterface\\Icons\\ui_profession_herbalism:0|t"
app.IconProfession[185] = "|TInterface\\Icons\\ui_profession_cooking:0|t"
app.IconProfession[186] = "|TInterface\\Icons\\ui_profession_mining:0|t"
app.IconProfession[197] = "|TInterface\\Icons\\ui_profession_tailoring:0|t"
app.IconProfession[202] = "|TInterface\\Icons\\ui_profession_engineering:0|t"
app.IconProfession[333] = "|TInterface\\Icons\\ui_profession_enchanting:0|t"
app.IconProfession[356] = "|TInterface\\Icons\\ui_profession_fishing:0|t"
app.IconProfession[393] = "|TInterface\\Icons\\ui_profession_skinning:0|t"
app.IconProfession[755] = "|TInterface\\Icons\\ui_profession_jewelcrafting:0|t"
app.IconProfession[773] = "|TInterface\\Icons\\ui_profession_inscription:0|t"
app.IconProfession[999] = "|TInterface\\Icons\\inv_misc_questionmark:0|t"

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
app.nyiRecipes[2336] = true		-- Elixir of Tongues
app.nyiRecipes[2671] = true		-- Rough Bronze Bracers
app.nyiRecipes[7636] = true		-- Green Woolen Robe
app.nyiRecipes[8366] = true		-- Ironforge Chain
app.nyiRecipes[8368] = true		-- Ironforge Gauntlets
app.nyiRecipes[8778] = true		-- Boots of Darkness
app.nyiRecipes[9942] = true		-- Mithril Scale Gloves
app.nyiRecipes[9957] = true		-- Orcish War Leggings
app.nyiRecipes[9972] = true		-- Ornate Mithril Breastplate
app.nyiRecipes[9979] = true		-- Ornate Mithril Boots
app.nyiRecipes[9980] = true		-- Ornate Mithril Helm
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
app.nyiRecipes[382977] = true	-- Pandaria Prospecting (not NYI, but returns Shadowed Alloy)
app.nyiRecipes[382978] = true	-- Pandaria Prospecting (not NYI, but returns Infurious Alloy)

-- Profession Knowledge
app.ProfessionKnowledge = {}
app.ProfessionKnowledge[2823] = {	-- Dragonflight Alchemy
	-- Vendors
	{ quest = 71893, type = "vendor", item = 200974, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 71904, type = "vendor", item = 201270, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 71915, type = "vendor", item = 201281, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 75756, type = "vendor", item = 205353, source = 2564, renown = 12 },
	{ quest = 75847, type = "vendor", item = 205429, source = "Bartering", sourceType = "static" },
	{ quest = 75848, type = "vendor", item = 205440, source = "Bartering", sourceType = "static" },

	-- Renown
	{ quest = 72311, type = "renown", faction = 2503, renown = 14 },
	{ quest = 72314, type = "renown", faction = 2503, renown = 24 },
	{ quest = 70892, type = "renown", faction = 2510, renown = 14 },
	{ quest = 70889, type = "renown", faction = 2510, renown = 24 },

	-- Treasures
	{ quest = 70247, type = "world", zone = 2022 },					-- Hidden Master
	{ quest = 70274, type = "world", item = 198663, zone = 2022 },	-- Frostforged Potion
	{ quest = 70289, type = "world", item = 198685, zone = 2022 },	-- Well Insulated Mug
	{ quest = 70305, type = "world", item = 198710, zone = 2023 },	-- Canteen of Suspicious Water
	{ quest = 70208, type = "world", item = 198599, zone = 2024 },	-- Experimental Decay Sample
	{ quest = 70309, type = "world", item = 198712, zone = 2024 },	-- Small Basket of Firewater Powder
	{ quest = 70278, type = "world", item = 203471, zone = 2025 },	-- Tasty Candy (formerly Furry Gloop)
	{ quest = 70301, type = "world", item = 198697, zone = 2025 },	-- Contraband Concoction
	{ quest = 75646, type = "world", item = 205211, zone = 2133 },	-- Nutrient Diluted Protofluid
	{ quest = 75649, type = "world", item = 205212, zone = 2133 },	-- Marrow-Ripened Slime
	{ quest = 75651, type = "world", item = 205213, zone = 2133 },	-- Suspicious Mold
	{ quest = 78264, type = "world", item = 210184, zone = 2200 },	-- Half-Filled Dreamless Sleep Potion
	{ quest = 78269, type = "world", item = 210185, zone = 2200 },	-- Splash Potion of Narcolepsy
	{ quest = 78275, type = "world", item = 210190, zone = 2200 },	-- Blazeroot
}
app.ProfessionKnowledge[2822] = {	-- Dragonflight Blacksmithing
	-- Vendors
	{ quest = 71894, type = "vendor", item = 200972, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 71905, type = "vendor", item = 201268, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 71916, type = "vendor", item = 201279, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 75755, type = "vendor", item = 205352, source = 2564, renown = 12 },
	{ quest = 75846, type = "vendor", item = 205428, source = "Bartering", sourceType = "static" },
	{ quest = 75849, type = "vendor", item = 205439, source = "Bartering", sourceType = "static" },

	-- Renown
	{ quest = 72312, type = "renown", faction = 2503, renown = 14 },
	{ quest = 72315, type = "renown", faction = 2503, renown = 24 },
	{ quest = 72329, type = "renown", faction = 2510, renown = 14 },
	{ quest = 70909, type = "renown", faction = 2510, renown = 24 },

	-- Treasures
	{ quest = 70250, type = "world", zone = 2022 },					-- Hidden Master
	{ quest = 70230, type = "world", item = 198791, zone = 2022 },	-- Glimmer of Blacksmithing Wisdom
	{ quest = 70246, type = "world", item = 201007, zone = 2022 },	-- Ancient Monument
	{ quest = 70296, type = "world", item = 201008, zone = 2022 },	-- Molten Ingot
	{ quest = 70310, type = "world", item = 201010, zone = 2022 },	-- Qalashi Weapon Diagram
	{ quest = 70312, type = "world", item = 201005, zone = 2022 },	-- Curious Ingots
	{ quest = 70313, type = "world", item = 201004, zone = 2023 },	-- Ancient Spear Shards
	{ quest = 70353, type = "world", item = 201009, zone = 2023 },	-- Falconer Gauntlet Drawings
	{ quest = 70314, type = "world", item = 201011, zone = 2024 },	-- Spelltouched Tongs
	{ quest = 70311, type = "world", item = 201006, zone = 2025 },	-- Draconic Flux
	{ quest = 76078, type = "world", item = 205986, zone = 2133 },	-- Well-Worn Kiln
	{ quest = 76079, type = "world", item = 205987, zone = 2133 },	-- Brimstone Rescue Ring
	{ quest = 76080, type = "world", item = 205988, zone = 2133 },	-- Zaqali Elder Spear
	{ quest = 78417, type = "world", item = 210464, zone = 2200 },	-- Amirdrassil Defender's Shield
	{ quest = 78418, type = "world", item = 210465, zone = 2200 },	-- Deathstalker Chassis
	{ quest = 78419, type = "world", item = 210466, zone = 2200 },	-- Flamesworn Render
}
app.ProfessionKnowledge[2825] = {	-- Dragonflight Enchanting
	-- Vendors
	{ quest = 71895, type = "vendor", item = 200976, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 71906, type = "vendor", item = 201272, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 71917, type = "vendor", item = 201283, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 75752, type = "vendor", item = 205351, source = 2564, renown = 12 },
	{ quest = 75845, type = "vendor", item = 205427, source = "Bartering", sourceType = "static" },
	{ quest = 75850, type = "vendor", item = 205438, source = "Bartering", sourceType = "static" },

	-- Renown
	{ quest = 72299, type = "renown", faction = 2507, renown = 14 },
	{ quest = 72304, type = "renown", faction = 2507, renown = 23 },
	{ quest = 72318, type = "renown", faction = 2511, renown = 14 },
	{ quest = 72323, type = "renown", faction = 2511, renown = 24 },

	-- Treasures
	{ quest = 70251, type = "world", zone = 2023 },					-- Hidden Master
	{ quest = 70272, type = "world", item = 201012, zone = 2022 },	-- Enchanted Debris
	{ quest = 70283, type = "world", item = 198675, zone = 2022 },	-- Lava-Infused Seed
	{ quest = 70320, type = "world", item = 198798, zone = 2022 },	-- Flashfrozen Scroll
	{ quest = 70291, type = "world", item = 198689, zone = 2023 },	-- Stormbound Horn
	{ quest = 70290, type = "world", item = 201013, zone = 2024 },	-- Faintly Enchanted Remains
	{ quest = 70298, type = "world", item = 198694, zone = 2024 },	-- Enriched Earthen Shard
	{ quest = 70336, type = "world", item = 198799, zone = 2024 },	-- Forgotten Arcane Tome
	{ quest = 70342, type = "world", item = 198800, zone = 2025 },	-- Fractured Titanic Sphere
	{ quest = 75508, type = "world", item = 204990, zone = 2133 },	-- Lava-Drenched Shadow Crystal
	{ quest = 75509, type = "world", item = 204999, zone = 2133 },	-- Shimmering Aqueous Orb
	{ quest = 75510, type = "world", item = 205001, zone = 2133 },	-- Resonating Arcane Crystal
	{ quest = 78308, type = "world", item = 210228, zone = 2200 },	-- Pure Dream Water
	{ quest = 78309, type = "world", item = 210231, zone = 2200 },	-- Everburning Core
	{ quest = 78310, type = "world", item = 210234, zone = 2200 },	-- Essence of Dreams

	
}
app.ProfessionKnowledge[2827] = {	-- Dragonflight Engineering
	-- Vendors
	{ quest = 71896, type = "vendor", item = 200977, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 71907, type = "vendor", item = 201273, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 71918, type = "vendor", item = 201284, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 75759, type = "vendor", item = 205349, source = 2564, renown = 12 },
	{ quest = 75844, type = "vendor", item = 205425, source = "Bartering", sourceType = "static" },
	{ quest = 75851, type = "vendor", item = 205436, source = "Bartering", sourceType = "static" },

	-- Renown
	{ quest = 72300, type = "renown", faction = 2507, renown = 14 },
	{ quest = 72305, type = "renown", faction = 2507, renown = 23 },
	{ quest = 72330, type = "renown", faction = 2510, renown = 14 },
	{ quest = 70902, type = "renown", faction = 2510, renown = 24 },

	-- Treasures
	{ quest = 70252, type = "world", zone = 2024 },					-- Hidden Master
	{ quest = 70270, type = "world", item = 201014, zone = 2022 },	-- Boomthyr Rocket
	{ quest = 70275, type = "world", item = 198789, zone = 2022 },	-- Intact Coil Capacitor
	{ quest = 75180, type = "world", item = 204469, zone = 2133 },	-- Misplaced Aberrus Outflow Blueprints
	{ quest = 75183, type = "world", item = 204470, zone = 2133 },	-- Haphazardly Discarded Bomb
	{ quest = 75184, type = "world", item = 204471, zone = 2133 },	-- Defective Survival Pack
	{ quest = 75186, type = "world", item = 204475, zone = 2133 },	-- Busted Wyrmhole Generator
	{ quest = 75188, type = "world", item = 204480, zone = 2133 },	-- Inconspicuous Data Miner
	{ quest = 75430, type = "world", item = 204850, zone = 2133 },	-- Handful of Khaz'gorite Bolts
	{ quest = 75431, type = "world", item = 204853, zone = 2133 },	-- Discarded Dracothyst Drill
	{ quest = 75433, type = "world", item = 204855, zone = 2133 },	-- Overclocked Determination Core
	{ quest = 78278, type = "world", item = 210193, zone = 2200 },	-- Experimental Dreamcatcher
	{ quest = 78279, type = "world", item = 210194, zone = 2200 },	-- Insomniotron
	{ quest = 78281, type = "world", item = 210197, zone = 2200 },	-- Unhatched Battery
}
app.ProfessionKnowledge[2832] = {	-- Dragonflight Herbalism
	-- Vendors
	{ quest = 71897, type = "vendor", item = 200980, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 71908, type = "vendor", item = 201276, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 71919, type = "vendor", item = 201287, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 75753, type = "vendor", item = 205358, source = 2564, renown = 12 },
	{ quest = 75843, type = "vendor", item = 205434, source = "Bartering", sourceType = "static" },
	{ quest = 75852, type = "vendor", item = 205445, source = "Bartering", sourceType = "static" },

	-- Renown
	{ quest = 72313, type = "renown", faction = 2503, renown = 14 },
	{ quest = 72316, type = "renown", faction = 2503, renown = 24 },
	{ quest = 72319, type = "renown", faction = 2511, renown = 14 },
	{ quest = 72324, type = "renown", faction = 2511, renown = 24 },

	-- Treasures
	{ quest = 70253, type = "world", zone = 2023 },	-- Hidden Master
}
app.ProfessionKnowledge[2828] = {	-- Dragonflight Inscription
	-- Vendors
	{ quest = 71898, type = "vendor", item = 200973, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 71909, type = "vendor", item = 201269, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 71920, type = "vendor", item = 201280, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 75761, type = "vendor", item = 205354, source = 2564, renown = 12 },
	{ quest = 75842, type = "vendor", item = 205430, source = "Bartering", sourceType = "static" },
	{ quest = 75853, type = "vendor", item = 205441, source = "Bartering", sourceType = "static" },

	-- Renown
	{ quest = 72294, type = "renown", faction = 2507, renown = 14 },
	{ quest = 72295, type = "renown", faction = 2507, renown = 23 },
	{ quest = 72331, type = "renown", faction = 2510, renown = 14 },
	{ quest = 72334, type = "renown", faction = 2510, renown = 24 },

	-- Treasures
	{ quest = 70254, type = "world", zone = 2024 },					-- Hidden Master
	{ quest = 70306, type = "world", item = 198704, zone = 2022 },	-- Pulsing Earth Rune
	{ quest = 70307, type = "world", item = 198703, zone = 2023 },	-- Sign Language Reference Sheet
	{ quest = 70293, type = "world", item = 198686, zone = 2024 },	-- Frosted Parchment
	{ quest = 70297, type = "world", item = 198693, zone = 2024 },	-- Dusty Darkmoon Card
	{ quest = 70248, type = "world", item = 198659, zone = 2025 },	-- Forgetful Apprentice's Tome 1
	{ quest = 70264, type = "world", item = 198659, zone = 2025 },	-- Forgetful Apprentice's Tome 2
	{ quest = 70287, type = "world", item = 201015, zone = 2025 },	-- Counterfeit Darkmoon Deck
	{ quest = 70281, type = "world", item = 198669, zone = 2112 },	-- How to Train Your Whelpling
	{ quest = 76117, type = "world", item = 206031, zone = 2133 },	-- Intricate Zaqali Runes
	{ quest = 76120, type = "world", item = 206034, zone = 2133 },	-- Hissing Rune Draft
	{ quest = 76121, type = "world", item = 206035, zone = 2133 },	-- Ancient Research
	{ quest = 78411, type = "world", item = 210458, zone = 2200 },	-- Winnie's Notes on Flora and Fauna
	{ quest = 78412, type = "world", item = 210459, zone = 2200 },	-- Grove Keeper's Pillar
	{ quest = 78413, type = "world", item = 210460, zone = 2200 },	-- Primalist Shadowbinding Rune
}
app.ProfessionKnowledge[2829] = {	-- Dragonflight Jewelcrafting
	-- Vendors
	{ quest = 71899, type = "vendor", item = 200978, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 71910, type = "vendor", item = 201274, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 71921, type = "vendor", item = 201285, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 75754, type = "vendor", item = 205348, source = 2564, renown = 12 },
	{ quest = 75841, type = "vendor", item = 205424, source = "Bartering", sourceType = "static" },
	{ quest = 75854, type = "vendor", item = 205435, source = "Bartering", sourceType = "static" },

	-- Renown
	{ quest = 72301, type = "renown", faction = 2507, renown = 14 },
	{ quest = 72306, type = "renown", faction = 2507, renown = 23 },
	{ quest = 72320, type = "renown", faction = 2511, renown = 14 },
	{ quest = 72325, type = "renown", faction = 2511, renown = 24 },

	-- Treasures
	{ quest = 70255, type = "world", zone = 2024 },					-- Hidden Master
	{ quest = 70273, type = "world", item = 201017, zone = 2022 },	-- Igneous Gem
	{ quest = 70292, type = "world", item = 198687, zone = 2022 },	-- Closely Guarded Shiny
	{ quest = 70263, type = "world", item = 198660, zone = 2023 },	-- Fragmented Key
	{ quest = 70282, type = "world", item = 198670, zone = 2023 },	-- Lofty Malygite
	{ quest = 70271, type = "world", item = 201016, zone = 2024 },	-- Harmonic Crystal Harmonizer
	{ quest = 70277, type = "world", item = 198664, zone = 2024 },	-- Crystalline Overgrowth
	{ quest = 70261, type = "world", item = 198656, zone = 2025 },	-- Painter's Pretty Jewel
	{ quest = 70285, type = "world", item = 198682, zone = 2025 },	-- Alexstraszite Cluster
	{ quest = 75652, type = "world", item = 205214, zone = 2133 },	-- Snubbed Snail Shells
	{ quest = 75653, type = "world", item = 205216, zone = 2133 },	-- Gently Jostled Jewels
	{ quest = 75654, type = "world", item = 205219, zone = 2133 },	-- Broken Barter Boulder
	{ quest = 78282, type = "world", item = 210200, zone = 2200 },	-- Petrified Hope
	{ quest = 78283, type = "world", item = 210201, zone = 2200 },	-- Handful of Pebbles
	{ quest = 78285, type = "world", item = 210202, zone = 2200 },	-- Coalesced Dreamstone
}
app.ProfessionKnowledge[2830] = {	-- Dragonflight Leatherworking
	-- Vendors
	{ quest = 71900, type = "vendor", item = 200979, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 71911, type = "vendor", item = 201275, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 71922, type = "vendor", item = 201286, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 75751, type = "vendor", item = 198613, source = 2564, renown = 12 },
	{ quest = 75840, type = "vendor", item = 205426, source = "Bartering", sourceType = "static" },
	{ quest = 75855, type = "vendor", item = 205437, source = "Bartering", sourceType = "static" },

	-- Renown
	{ quest = 72296, type = "renown", faction = 2503, renown = 14 },
	{ quest = 72297, type = "renown", faction = 2503, renown = 24 },
	{ quest = 72321, type = "renown", faction = 2511, renown = 14 },
	{ quest = 72326, type = "renown", faction = 2511, renown = 24 },

	-- Treasures
	{ quest = 70254, type = "world", zone = 2023 },					-- Hidden Master
	{ quest = 70280, type = "world", item = 198667, zone = 2022 },	-- Spare Djaradin Tools
	{ quest = 70308, type = "world", item = 198711, zone = 2022 },	-- Poacher's Pack
	{ quest = 70266, type = "world", item = 198658, zone = 2024 },	-- Decay-Infused Tanning Oil
	{ quest = 70269, type = "world", item = 201018, zone = 2024 },	-- Well-Danced Drum
	{ quest = 70286, type = "world", item = 198683, zone = 2024 },	-- Treated Hides
	{ quest = 70300, type = "world", item = 198696, zone = 2023 },	-- Wind-Blessed Hide
	{ quest = 70294, type = "world", item = 198690, zone = 2025 },	-- Bag of Decayed Scales
	{ quest = 75495, type = "world", item = 204986, zone = 2133 },	-- Flame-Infused Scale Oil
	{ quest = 75496, type = "world", item = 204987, zone = 2133 },	-- Lava-Forged Leatherworker's "Knife"
	{ quest = 75502, type = "world", item = 204988, zone = 2133 },	-- Sulfur-Soaked Skins
	{ quest = 78298, type = "world", item = 210208, zone = 2200 },	-- Tuft of Dreamsaber Fur
	{ quest = 78299, type = "world", item = 210211, zone = 2200 },	-- Molted Fearie Dragon Scales
	{ quest = 78305, type = "world", item = 210215, zone = 2200 },	-- Dreamtalon Claw
}
app.ProfessionKnowledge[2833] = {	-- Dragonflight Mining
	-- Vendors
	{ quest = 71901, type = "vendor", item = 200981, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 71912, type = "vendor", item = 201277, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 71923, type = "vendor", item = 201288, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 75758, type = "vendor", item = 205356, source = 2564, renown = 12},
	{ quest = 75839, type = "vendor", item = 205432, source = "Bartering", sourceType = "static" },
	{ quest = 75856, type = "vendor", item = 205443, source = "Bartering", sourceType = "static" },

	-- Renown
	{ quest = 72302, type = "renown", faction = 2507, renown = 14 },
	{ quest = 72308, type = "renown", faction = 2507, renown = 23 },
	{ quest = 72332, type = "renown", faction = 2510, renown = 14 },
	{ quest = 72335, type = "renown", faction = 2510, renown = 24 },

	-- Treasures
	{ quest = 70258, type = "world", zone = 2025 },	-- Hidden Master
}
app.ProfessionKnowledge[2834] = {	-- Dragonflight Skinning
	-- Vendors
	{ quest = 71902, type = "vendor", item = 200982, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 71913, type = "vendor", item = 201278, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 71924, type = "vendor", item = 201289, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 75760, type = "vendor", item = 205357, source = 2564, renown = 12 },
	{ quest = 75838, type = "vendor", item = 205433, source = "Bartering", sourceType = "static" },
	{ quest = 75857, type = "vendor", item = 205444, source = "Bartering", sourceType = "static" },

	-- Renown
	{ quest = 72310, type = "renown", faction = 2503, renown = 14 },
	{ quest = 72317, type = "renown", faction = 2503, renown = 24 },
	{ quest = 72322, type = "renown", faction = 2511, renown = 14 },
	{ quest = 72327, type = "renown", faction = 2511, renown = 24 },

	-- Treasures
	{ quest = 70259, type = "world", zone = 2022 },	-- Hidden Master
}
app.ProfessionKnowledge[2831] = {	-- Dragonflight Tailoring
	-- Vendors
	{ quest = 71903, type = "vendor", item = 200975, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 71914, type = "vendor", item = 201271, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 71925, type = "vendor", item = 201282, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 75757, type = "vendor", item = 205355, source = 2564, renown = 12 },
	{ quest = 75837, type = "vendor", item = 205431, source = "Bartering", sourceType = "static" },
	{ quest = 75858, type = "vendor", item = 205442, source = "Bartering", sourceType = "static" },

	-- Renown
	{ quest = 72303, type = "renown", faction = 2507, renown = 14 },
	{ quest = 72309, type = "renown", faction = 2507, renown = 23 },
	{ quest = 72333, type = "renown", faction = 2510, renown = 14 },
	{ quest = 72336, type = "renown", faction = 2510, renown = 24 },

	-- Treasures
	{ quest = 70260, type = "world", zone = 2112 },					-- Hidden Master
	{ quest = 70302, type = "world", item = 198699, zone = 2022 },	-- Mysterious Banner
	{ quest = 70304, type = "world", item = 198702, zone = 2022 },	-- Itinerant Singed Fabric
	{ quest = 70295, type = "world", item = 198692, zone = 2023 },	-- Noteworthy Scrap of Carpet
	{ quest = 70303, type = "world", item = 201020, zone = 2023 },	-- Silky Surprise
	{ quest = 70267, type = "world", item = 198662, zone = 2024 },	-- Intriguing Bolt of Blue Cloth
	{ quest = 70284, type = "world", item = 198680, zone = 2024 },	-- Decaying Brackenhide Blanket
	{ quest = 70288, type = "world", item = 198684, zone = 2025 },	-- Miniature Bronze Dragonflight Banner
	{ quest = 70372, type = "world", item = 201019, zone = 2025 },	-- Ancient Dragonweave Bolt
	{ quest = 76102, type = "world", item = 206019, zone = 2133 },	-- Abandoned Reserve Chute
	{ quest = 76110, type = "world", item = 206025, zone = 2133 },	-- Used Medical Wrap Kit
	{ quest = 76116, type = "world", item = 206030, zone = 2133 },	-- Exquisitely Embroidered Banner
	{ quest = 78414, type = "world", item = 210461, zone = 2200 },	-- Exceedingly Soft Wildercloth
	{ quest = 78415, type = "world", item = 210462, zone = 2200 },	-- Plush Pillow
	{ quest = 78416, type = "world", item = 210463, zone = 2200 },	-- Snuggle Buddy
}
app.ProfessionKnowledge[2871] = {	-- The War Within Alchemy
	-- Vendors
	{ quest = 81146, type = "vendor", item = 227409, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 81147, type = "vendor", item = 227420, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 81148, type = "vendor", item = 227431, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 83058, type = "vendor", item = 224645, source = 2590, renown = 12 },
	{ quest = 82633, type = "vendor", item = 224024, source = 2213, sourceType = "zone"},

	-- Treasures
	{ quest = 83840, type = "world", item = 226265, zone = 2339 },	-- Earthen Iron Powder
	{ quest = 83841, type = "world", item = 226266, zone = 2248 },	-- Metal 2339 Frame
	{ quest = 83842, type = "world", item = 226267, zone = 2214 },	-- Reinforced Beaker
	{ quest = 83843, type = "world", item = 226268, zone = 2214 },	-- Engraved Stirring Rod
	{ quest = 83844, type = "world", item = 226269, zone = 2215 },	-- Chemist's Purified Water
	{ quest = 83845, type = "world", item = 226270, zone = 2215 },	-- Sanctified Mortar and Pestle
	{ quest = 83847, type = "world", item = 226272, zone = 2255 },	-- Dark Apothecary's Vial
	{ quest = 83846, type = "world", item = 226271, zone = 2213 },	-- Nerubian Mixing Salts
}
app.ProfessionKnowledge[2872] = {	-- The War Within Blacksmithing
	-- Vendors
	{ quest = 84226, type = "vendor", item = 227407, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 84227, type = "vendor", item = 227418, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 84228, type = "vendor", item = 227429, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 83059, type = "vendor", item = 224647, source = 2590, renown = 12 },
	{ quest = 82631, type = "vendor", item = 224038, source = 2213, sourceType = "zone"},

	-- Treasures
	{ quest = 83849, type = "world", item = 226277, zone = 2339 },	-- 2339 Hammer
	{ quest = 83848, type = "world", item = 226276, zone = 2248 },	-- Ancient Earthen Anvil
	{ quest = 83850, type = "world", item = 226278, zone = 2214 },	-- Ringing Hammer Vise
	{ quest = 83851, type = "world", item = 226279, zone = 2214 },	-- Earthen Chisels
	{ quest = 83852, type = "world", item = 226280, zone = 2215 },	-- Holy Flame Forge
	{ quest = 83853, type = "world", item = 226281, zone = 2215 },	-- Radiant Tongs
	{ quest = 83855, type = "world", item = 226283, zone = 2255 },	-- Spiderling's Wire Brush
	{ quest = 83854, type = "world", item = 226282, zone = 2213 },	-- Nerubian Smith's Kit
}
app.ProfessionKnowledge[2874] = {	-- The War Within Enchanting
	-- Vendors
	{ quest = 81076, type = "vendor", item = 227411, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 81077, type = "vendor", item = 227422, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 81078, type = "vendor", item = 227433, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 83060, type = "vendor", item = 224652, source = 2590, renown = 12 },
	{ quest = 82635, type = "vendor", item = 224050, source = 2213, sourceType = "zone"},

	-- Treasures
	{ quest = 83859, type = "world", item = 226285, zone = 2339 },	-- Silver 2339 Rod
	{ quest = 83856, type = "world", item = 226284, zone = 2248 },	-- Grinded Earthen Gem
	{ quest = 83860, type = "world", item = 226286, zone = 2214 },	-- Soot-Coated Orb
	{ quest = 83861, type = "world", item = 226287, zone = 2214 },	-- Animated Enchanting Dust
	{ quest = 83862, type = "world", item = 226288, zone = 2215 },	-- Essence of Holy Fire
	{ quest = 83863, type = "world", item = 226289, zone = 2215 },	-- Enchanted Arathi Scroll
	{ quest = 83865, type = "world", item = 226291, zone = 2255 },	-- Void Shard
	{ quest = 83864, type = "world", item = 226290, zone = 2213 },	-- Book of Dark Magic
}
app.ProfessionKnowledge[2875] = {	-- The War Within Engineering
	-- Vendors
	{ quest = 84229, type = "vendor", item = 227412, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 84230, type = "vendor", item = 227423, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 84231, type = "vendor", item = 227434, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 83063, type = "vendor", item = 224653, source = 2594, renown = 12 },
	{ quest = 82632, type = "vendor", item = 224052, source = 2213, sourceType = "zone"},

	-- Treasures
	{ quest = 83867, type = "world", item = 226293, zone = 2339 },	-- 2339 Spectacles
	{ quest = 83866, type = "world", item = 226292, zone = 2248 },	-- Rock Engineer's Wrench
	{ quest = 83868, type = "world", item = 226294, zone = 2214 },	-- Inert Mining Bomb
	{ quest = 83869, type = "world", item = 226295, zone = 2214 },	-- Earthen Construct Blueprints
	{ quest = 83870, type = "world", item = 226296, zone = 2215 },	-- Holy Firework Dud
	{ quest = 83871, type = "world", item = 226297, zone = 2215 },	-- Arathi Safety Gloves
	{ quest = 83872, type = "world", item = 226298, zone = 2255 },	-- Puppeted Mechanical Spider
	{ quest = 83873, type = "world", item = 226299, zone = 2213 },	-- Emptied Venom Canister
}
app.ProfessionKnowledge[2877] = {	-- The War Within Herbalism
	-- Vendors
	{ quest = 81422, type = "vendor", item = 227415, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 81423, type = "vendor", item = 227426, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 81424, type = "vendor", item = 227437, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 83066, type = "vendor", item = 224656, source = 2570, renown = 14 },
	{ quest = 82630, type = "vendor", item = 224023, source = 2213, sourceType = "zone"},

	-- Treasures
	{ quest = 83875, type = "world", item = 226301, zone = 2339 },	-- 2339 Gardening Scythe
	{ quest = 83874, type = "world", item = 226300, zone = 2248 },	-- Ancient Flower
	{ quest = 83876, type = "world", item = 226302, zone = 2214 },	-- Earthen Digging Fork
	{ quest = 83877, type = "world", item = 226303, zone = 2214 },	-- Fungarian Slicer's Knife
	{ quest = 83878, type = "world", item = 226304, zone = 2215 },	-- Arathi Garden Trowel
	{ quest = 83879, type = "world", item = 226305, zone = 2215 },	-- Arathi Herb Pruner
	{ quest = 83880, type = "world", item = 226306, zone = 2213 },	-- Web-Entangled Lotus
	{ quest = 83881, type = "world", item = 226307, zone = 2213 },	-- Tunneler's Shovel
}
app.ProfessionKnowledge[2878] = {	-- The War Within Inscription
	-- Vendors
	{ quest = 80749, type = "vendor", item = 227408, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 80750, type = "vendor", item = 227419, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 80751, type = "vendor", item = 227430, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 83064, type = "vendor", item = 224654, source = 2594, renown = 12 },
	{ quest = 82636, type = "vendor", item = 224053, source = 2213, sourceType = "zone"},
	
	-- Treasures
	{ quest = 83882, type = "world", item = 226308, zone = 2339 },	-- 2339 Scribe's Quill
	{ quest = 83883, type = "world", item = 226309, zone = 2248 },	-- Historian's Dip Pen
	{ quest = 83884, type = "world", item = 226310, zone = 2214 },	-- Runic Scroll
	{ quest = 83885, type = "world", item = 226311, zone = 2214 },	-- Blue Earthen Pigment
	{ quest = 83886, type = "world", item = 226312, zone = 2215 },	-- Informant's Fountain Pen
	{ quest = 83887, type = "world", item = 226313, zone = 2215 },	-- Calligrapher's Chiseled Marker
	{ quest = 83888, type = "world", item = 226314, zone = 2255 },	-- Nerubian Texts
	{ quest = 83889, type = "world", item = 226315, zone = 2213 },	-- Venomancer's Ink Well
}
app.ProfessionKnowledge[2879] = {	-- The War Within Jewelcrafting
	-- Vendors
	{ quest = 81259, type = "vendor", item = 227413, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 81260, type = "vendor", item = 227424, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 81261, type = "vendor", item = 227435, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 83065, type = "vendor", item = 224655, source = 2570, renown = 14 },
	{ quest = 82637, type = "vendor", item = 224054, source = 2213, sourceType = "zone"},

	-- Treasures
	{ quest = 83891, type = "world", item = 226317, zone = 2339 },	-- Earthen Gem Pliers
	{ quest = 83890, type = "world", item = 226316, zone = 2248 },	-- Gentle Jewel Hammer
	{ quest = 83892, type = "world", item = 226318, zone = 2214 },	-- Carved Stone File
	{ quest = 83893, type = "world", item = 226319, zone = 2214 },	-- Rune-Etched Ring Box
	{ quest = 83894, type = "world", item = 226320, zone = 2215 },	-- Hammered Golden Chain
	{ quest = 83895, type = "world", item = 226321, zone = 2215 },	-- Inscribed Sunstone Gem
	{ quest = 83897, type = "world", item = 226323, zone = 2255 },	-- Hardened Jewel Setter's Vise
	{ quest = 83896, type = "world", item = 226322, zone = 2213 },	-- Heavy Gem Sorting Gloves
}
app.ProfessionKnowledge[2880] = {	-- The War Within Leatherworking
	-- Vendors
	{ quest = 80978, type = "vendor", item = 227414, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 80979, type = "vendor", item = 227425, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 80980, type = "vendor", item = 227436, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 83068, type = "vendor", item = 224658, source = 2570, renown = 14 },
	{ quest = 82626, type = "vendor", item = 224056, source = 2213, sourceType = "zone"},

	-- Treasures
	{ quest = 83899, type = "world", item = 226325, zone = 2339 },	-- 2339 Stitching Clamp
	{ quest = 83898, type = "world", item = 226324, zone = 2248 },	-- Earthen Leatherworking Knife
	{ quest = 83900, type = "world", item = 226326, zone = 2214 },	-- Preserved Needle Kit
	{ quest = 83901, type = "world", item = 226327, zone = 2214 },	-- Reinforced Wax Thread
	{ quest = 83902, type = "world", item = 226328, zone = 2215 },	-- Sanctified Leatherworking Tools
	{ quest = 83903, type = "world", item = 226329, zone = 2215 },	-- Holy Arathi Leather Strap
	{ quest = 83905, type = "world", item = 226331, zone = 2255 },	-- Preserved Bug-Skinner Gloves
	{ quest = 83904, type = "world", item = 226330, zone = 2213 },	-- Nerubian Hide Preserver
}
app.ProfessionKnowledge[2881] = {	-- The War Within Mining
	-- Vendors
	{ quest = 81390, type = "vendor", item = 227416, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 81391, type = "vendor", item = 227427, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 81392, type = "vendor", item = 227438, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 83062, type = "vendor", item = 224651, source = 2594, renown = 12 },
	{ quest = 82614, type = "vendor", item = 224055, source = 2213, sourceType = "zone"},

	-- Treasures
	{ quest = 83907, type = "world", item = 226333, zone = 2339 },	-- Engraved 2339 Chisel
	{ quest = 83906, type = "world", item = 226332, zone = 2248 },	-- Ancient Earthen Pickaxe
	{ quest = 83908, type = "world", item = 226334, zone = 2214 },	-- Ringing Hammer Shovel
	{ quest = 83909, type = "world", item = 226335, zone = 2214 },	-- Sooty Hammer
	{ quest = 83910, type = "world", item = 226336, zone = 2215 },	-- Gleaming Arathi Ore Nugget
	{ quest = 83911, type = "world", item = 226337, zone = 2215 },	-- Chunk of Holy Ore
	{ quest = 83913, type = "world", item = 226339, zone = 2255 },	-- Dark Bug-Filled Ore
	{ quest = 83912, type = "world", item = 226338, zone = 2213 },	-- Nerubian Shale Fragments
}
app.ProfessionKnowledge[2882] = {	-- The War Within Skinning
	-- Vendors
	{ quest = 84232, type = "vendor", item = 227417, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 84233, type = "vendor", item = 227428, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 84234, type = "vendor", item = 227439, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 83067, type = "vendor", item = 224657, source = 2570, renown = 14 },
	{ quest = 82596, type = "vendor", item = 224007, source = 2213, sourceType = "zone"},

	-- Treasures
	{ quest = 83915, type = "world", item = 226341, zone = 2339 },	-- 2339 Preservation Kit
	{ quest = 83914, type = "world", item = 226340, zone = 2248 },	-- Earthen Skinning Knife
	{ quest = 83916, type = "world", item = 226342, zone = 2214 },	-- Hammer-Treated Hides
	{ quest = 83917, type = "world", item = 226343, zone = 2214 },	-- Shiny Bug-Hide
	{ quest = 83918, type = "world", item = 226344, zone = 2215 },	-- Pristine Fur Scraper
	{ quest = 83919, type = "world", item = 226345, zone = 2215 },	-- Holy Bug Carapace Preserver
	{ quest = 83921, type = "world", item = 226347, zone = 2255 },	-- Silk-Lined Shell Slicer
	{ quest = 83920, type = "world", item = 226346, zone = 2213 },	-- Nerubian Hide Pouch

}
app.ProfessionKnowledge[2883] = {	-- The War Within Tailoring
	-- Vendors
	{ quest = 80871, type = "vendor", item = 227410, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 80872, type = "vendor", item = 227421, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 80873, type = "vendor", item = 227432, source = ARTISANS_CONSORTIUM, sourceType = "static" },
	{ quest = 83061, type = "vendor", item = 224648, source = 2590, renown = 12 },
	{ quest = 82634, type = "vendor", item = 224036, source = 2213, sourceType = "zone"},

	-- Treasures
	{ quest = 83922, type = "world", item = 226348, zone = 2339 },	-- 2339 Seam Ripper
	{ quest = 83923, type = "world", item = 226349, zone = 2248 },	-- Earthen Tape Measure
	{ quest = 83924, type = "world", item = 226350, zone = 2214 },	-- Runed Earthen Pins
	{ quest = 83925, type = "world", item = 226351, zone = 2214 },	-- Earthen Stitcher's Snips
	{ quest = 83926, type = "world", item = 226352, zone = 2215 },	-- Arathi Rotary Cutter
	{ quest = 83927, type = "world", item = 226353, zone = 2215 },	-- Royal Outfitter's Protractor
	{ quest = 83928, type = "world", item = 226354, zone = 2255 },	-- Nerubian Quilt
	{ quest = 83929, type = "world", item = 226355, zone = 2213 },	-- Nerubian's Pincushion
}