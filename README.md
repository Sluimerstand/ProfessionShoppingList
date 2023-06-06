# Profession Shopping List
A World of Warcraft AddOn that adds a shopping list for tracked recipes.

Profession Shopping List is an AddOn that allows you to track recipes, and shows you the materials you need to craft them.
It does not replace the profession windows, it only adds a few buttons and two tracking windows: one for the materials, and one for the recipes.

[CurseForge page](https://www.curseforge.com/wow/addons/profession-shopping-list) | [Wago.io page](https://addons.wago.io/addons/psl)

**If you are experiencing issues**
- Use `/psl clear`. Some new versions come with logic changes, and then it is necessary to clear the tracked recipes once.
- If the issues remain, or you have other feedback, feel free to join the [All The Things Discord](https://discord.gg/allthethings) and ask in the #profession-shopping-list Retail channel, or create a [ticket on GitHub](https://github.com/Sluimerstand/ProfessionShoppingList/issues). :)

**Chat commands**

- /psl - Toggle the tracking windows
- /psl resetpos - Reset the tracking window positions
- /psl settings - Open the settings window
- /psl clear - Clear all tracked recipes
- /psl track [recipeID] [quantity] - Track a recipe
- /psl untrack [recipeID] [quantity] - Untrack a recipe
- /psl untrack [recipeID] all - Untrack all of a recipe

**Mouse interactions**

- Drag: Move the tracking windows
- Shift+click Recipe: Link the recipe
- Ctrl+click Recipe: Open the selected recipe
- Right-click Recipe (# column): Untrack 1 of the selected recipe
- Ctrl+right-click Recipe (# column): Untrack all of the selected recipe
- Shift+click Reagent: Link the reagent
- Ctrl+click Reagent: Add recipe for the selected subreagent, if it exists

**Other features**

- Untrack recipes after crafting them
- Tooltip information for tracked reagents
- Recipe cooldown reminders
- Copy tracked reagents to the Auctionator import window
- Buttons for Cooking Fire, Chef's Hat, and Thermal Anvil
- Quick order button, to instantly create personal crafting orders
- Profession Knowledge tracker
- Automatically set vendors' filter to 'All'
- Split bag count to accommodate the reagent bag
