-- Windows
local f = CreateFrame("Frame")
local ScrollingTable = LibStub("ScrollingTable")

-- API Events
f:RegisterEvent("TRADE_SKILL_SHOW")
f:RegisterEvent("BAG_UPDATE")
f:RegisterEvent("ADDON_LOADED")

-- Load the TradeSkillUI to prevent stuff from being wonky
if not TradeSkillFrame then
    UIParentLoadAddOn("Blizzard_TradeSkillUI")
end

function pslInitialise()
    -- Declare some variables
    if not userSettings then userSettings = {} end
    if not recipesTracked then recipesTracked = {} end
    if not reagentNumbers then reagentNumbers = {} end
    if not reagentLinks then reagentLinks = {} end
    if not recipeLinks then recipeLinks = {} end

    -- Enable default user settings
    if not userSettings["smallButtons"] then userSettings["smallButtons"] = false end
end
pslInitialise()

--Create Tracking windows
function pslCreateTrackingWindows()
    -- Reagent tracking
    if not pslFrame1 then
        -- Frame
        pslFrame1 = CreateFrame("Frame", "pslTrackingWindow1", UIParent, "BackdropTemplateMixin" and "BackdropTemplate")
        pslFrame1:SetSize(255, 270)
        pslFrame1:SetPoint("CENTER")
        pslFrame1:EnableMouse(true)
        pslFrame1:SetMovable(true)
        pslFrame1:Hide()

        -- Background
        -- pslFrame1:SetBackdrop({
        --     bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        --     edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        --     edgeSize = 1,
        -- })
        -- pslFrame1:SetBackdropColor(0, 0, 0, .8)
        -- pslFrame1:SetBackdropBorderColor(0, 0, 0)

        -- Close button
        local close = CreateFrame("Button", "pslCloseButtonName1", pslFrame1, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", pslFrame1, "TOPRIGHT", 6, 6)
        close:SetScript("OnClick", function()
            pslFrame1:Hide()
        end)

        -- This doesn't resize the actual table, so useless.
        -- Resize button
        -- local rb1 = CreateFrame("Button", nil, pslFrame1)
        -- rb1:SetPoint("BOTTOMRIGHT", 0, 0)
        -- rb1:SetSize(16, 16)
        -- rb1:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        -- rb1:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        -- rb1:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        -- rb1:SetScript("OnMouseDown", function()
        --     pslFrame1:StartSizing("BOTTOMRIGHT")
        -- end)
        -- rb1:SetScript("OnMouseUp", function()
        --     pslFrame1:StopMovingOrSizing()
        -- end)
        -- pslFrame1:SetResizable(true)
        -- pslFrame1:SetMinResize(255, 270)

        -- Column formatting, Reagents
        local cols = {}
        cols[1] = {
            ["name"] = "Reagents",
            ["width"] = 155,
            ["align"] = "LEFT",
            ["color"] = {
                ["r"] = 1.0,
                ["g"] = 1.0,
                ["b"] = 1.0,
                ["a"] = 1.0
            },
            ["colorargs"] = nil,
            ["bgcolor"] = {
                ["r"] = 0.0,
                ["g"] = 0.0,
                ["b"] = 0.0,
                ["a"] = 0.0
            },
            ["defaultsort"] = "dsc",
            ["sort"] = "dsc",
            ["DoCellUpdate"] = nil,
        }
        
        -- Column formatting, Amount
        cols[2] = {
            ["name"] = "Amount",
            ["width"] = 70,
            ["align"] = "RIGHT",
            ["color"] = {
                ["r"] = 1.0,
                ["g"] = 1.0,
                ["b"] = 1.0,
                ["a"] = 1.0
            },
            ["bgcolor"] = {
                ["r"] = 0.0,
                ["g"] = 0.0,
                ["b"] = 0.0,
                ["a"] = 0.0
            },
            ["defaultsort"] = "dsc",
            ["sort"] = "dsc",
            ["DoCellUpdate"] = nil,
        }

        -- Create tracking window
        table1 = ScrollingTable:CreateST(cols, 15, nil, nil, pslFrame1)
    end

    -- Recipe tracking
    if not pslFrame2 then
        -- Frame
        pslFrame2 = CreateFrame("Frame", "pslTrackingWindow2", UIParent, "BackdropTemplateMixin" and "BackdropTemplate")
        pslFrame2:SetSize(230, 270)
        pslFrame2:SetPoint("CENTER")
        pslFrame2:EnableMouse(true)
        pslFrame2:SetMovable(true)
        pslFrame2:Hide()

        -- Background
        -- pslFrame2:SetBackdrop({
        --     bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        --     edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        --     edgeSize = 1,
        -- })
        -- pslFrame2:SetBackdropColor(0, 0, 0, .8)
        -- pslFrame2:SetBackdropBorderColor(0, 0, 0)

        -- Close button
        local close = CreateFrame("Button", "pslCloseButtonName2", pslFrame2, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", pslFrame2, "TOPRIGHT", 6, 6)
        close:SetScript("OnClick", function()
            pslFrame2:Hide()
        end)

        -- This doesn't resize the actual table, so useless.
        -- Resize button
        -- local rb2 = CreateFrame("Button", nil, pslFrame2)
        -- rb2:SetPoint("BOTTOMRIGHT", 0, 0)
        -- rb2:SetSize(16, 16)
        -- rb2:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        -- rb2:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        -- rb2:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        -- rb2:SetScript("OnMouseDown", function()
        --     pslFrame2:StartSizing("BOTTOMRIGHT")
        -- end)
        -- rb2:SetScript("OnMouseUp", function()
        --     pslFrame2:StopMovingOrSizing()
        -- end)
        -- pslFrame2:SetResizable(true)
        -- pslFrame2:SetMinResize(230, 270)

        -- Column formatting, Recipes
        local cols = {}
        cols[1] = {
            ["name"] = "Recipes",
            ["width"] = 155,
            ["align"] = "LEFT",
            ["color"] = {
                ["r"] = 1.0,
                ["g"] = 1.0,
                ["b"] = 1.0,
                ["a"] = 1.0
            },
            ["colorargs"] = nil,
            ["bgcolor"] = {
                ["r"] = 0.0,
                ["g"] = 0.0,
                ["b"] = 0.0,
                ["a"] = 0.0
            },
            ["defaultsort"] = "dsc",
            ["sort"] = "dsc",
            ["DoCellUpdate"] = nil,
        }
        
        -- Column formatting, Tracked
        cols[2] = {
            ["name"] = "Tracked",
            ["width"] = 45,
            ["align"] = "RIGHT",
            ["color"] = {
                ["r"] = 1.0,
                ["g"] = 1.0,
                ["b"] = 1.0,
                ["a"] = 1.0
            },
            ["bgcolor"] = {
                ["r"] = 0.0,
                ["g"] = 0.0,
                ["b"] = 0.0,
                ["a"] = 0.0
            },
            ["defaultsort"] = "dsc",
            ["sort"] = "dsc",
            ["DoCellUpdate"] = nil,
        }

        -- Create tracking window
        table2 = ScrollingTable:CreateST(cols, 15, nil, nil, pslFrame2)
    end
end
pslCreateTrackingWindows()

-- Update numbers
function trackReagents()
    -- Update reagents tracked
    local data = {}
        for i, no in pairs(reagentNumbers) do 
            table.insert(data, {reagentLinks[i], GetItemCount(reagentLinks[i], true, false, true).."/"..no})
        end
    table1:SetData(data, true)

    -- Update recipes tracked
    local data = {};
    for i, no in pairs(recipesTracked) do 
        table.insert(data, {recipeLinks[i], no})
    end
    table2:SetData(data, true)
end

function pslCreateButtons()
    -- Create the "Add to list" button
    if not addCraftListButton then
        addCraftListButton = CreateFrame("Button", nil, TradeSkillFrame, "UIPanelButtonTemplate")
    end
    -- If button size is normal
    if userSettings["smallButtons"] == false then
        addCraftListButton:SetText("Track")
        addCraftListButton:SetWidth(60)
        addCraftListButton:SetPoint("TOPRIGHT", TradeSkillFrame.DetailsFrame.CreateButton, "TOPRIGHT", -180, 418)
    -- If button size is small
    elseif userSettings["smallButtons"] == true then
        addCraftListButton:SetText("+")
        addCraftListButton:SetWidth(30)
        addCraftListButton:SetPoint("TOPRIGHT", TradeSkillFrame.DetailsFrame.CreateButton, "TOPRIGHT", -210, 418)
    end

    -- Create the "Remove from list" button
    if not removeCraftListButton then
        removeCraftListButton = CreateFrame("Button", nil, TradeSkillFrame, "UIPanelButtonTemplate")
    end
    -- If button size is normal
    if userSettings["smallButtons"] == false then
        removeCraftListButton:SetText("Untrack")
        removeCraftListButton:SetWidth(70)
        removeCraftListButton:SetPoint("TOPRIGHT", TradeSkillFrame.DetailsFrame.CreateButton, "TOPRIGHT", -110, 418)
    -- If button size is small
    elseif userSettings["smallButtons"] == true then
        removeCraftListButton:SetText("-")
        removeCraftListButton:SetWidth(30)
        removeCraftListButton:SetPoint("TOPRIGHT", TradeSkillFrame.DetailsFrame.CreateButton, "TOPRIGHT", -180, 418)
    end

    -- Add Chef's Hat button
    if not cookingFireButton then
        cookingFireButton = CreateFrame("Button", nil, TradeSkillFrame, "UIPanelButtonTemplate")
    end

    if not chefsHatButton then
        chefsHatButton = CreateFrame("Button", nil, TradeSkillFrame, "UIPanelButtonTemplate")
    end
    chefsHatButton:SetWidth(40)
    chefsHatButton:SetHeight(40)
    chefsHatButton:SetNormalTexture(236571)
    chefsHatButton:SetPoint("BOTTOMRIGHT", TradeSkillFrame.DetailsFrame, "BOTTOMRIGHT", 0, 4)
    chefsHatButton:SetScript("OnClick", function()
        UseToyByName("Chef's Hat")
    end)
end
pslCreateButtons()

-- Make the "Track" button actually do the thing
addCraftListButton:SetScript("OnClick", function()
    -- Get selected recipe ID
    local recipeID = TradeSkillFrame.RecipeList:GetSelectedRecipeID()

    -- Track recipe
    if not recipesTracked[recipeID] then recipesTracked[recipeID] = 0 end
    recipesTracked[recipeID] = recipesTracked[recipeID] + 1

    -- Get recipe link
    recipeLinks[recipeID] = C_TradeSkillUI.GetRecipeItemLink(recipeID)

    -- Enable the remove button
    removeCraftListButton:Enable()

    -- Add the reagents to the total count
    for idx = 1, C_TradeSkillUI.GetRecipeNumReagents(recipeID) do
        -- Get name, icon and number
        local reagentName, reagentTexture, reagentCount = C_TradeSkillUI.GetRecipeReagentInfo(recipeID, idx)
        -- Set number to 0 if it doesn't exist so we can do maths
        if not reagentNumbers[reagentName] then reagentNumbers[reagentName] = 0 end
        -- Do maths
        reagentNumbers[reagentName] = reagentNumbers[reagentName] + reagentCount
        -- Get item link
        reagentLinks[reagentName] = C_TradeSkillUI.GetRecipeReagentItemLink(recipeID, idx)
    end

    -- Show windows
    pslFrame1:Show()
    pslFrame2:Show()

    -- Update numbers
    trackReagents()
end)

-- Make the "Untrack" button actually do the thing
removeCraftListButton:SetScript("OnClick", function()
    -- Get selected recipe ID
    local recipeID = TradeSkillFrame.RecipeList:GetSelectedRecipeID()

    -- Untrack recipe
    recipesTracked[recipeID] = recipesTracked[recipeID] - 1

    -- Set numbers to nil if it doesn't exist anymore
    if recipesTracked[recipeID] == 0 then
        recipesTracked[recipeID] = nil
        recipeLinks[recipeID] = nil
    end

    -- Disable the remove button if the recipe isn't tracked anymore
    if not recipesTracked[recipeID] then removeCraftListButton:Disable() end

    -- Remove the reagents from the total count
    for idx = 1, C_TradeSkillUI.GetRecipeNumReagents(recipeID) do
        -- Get name, icon and number
        local reagentName, reagentTexture, reagentCount = C_TradeSkillUI.GetRecipeReagentInfo(recipeID, idx)
        -- Do maths
        reagentNumbers[reagentName] = reagentNumbers[reagentName] - reagentCount
        -- Set numbers to nil if it doesn't exist anymore
        if reagentNumbers[reagentName] == 0 then
            reagentNumbers[reagentName] = nil
            reagentLinks[reagentName] = nil
        end
    end

    -- Show windows
    pslFrame1:Show()
    pslFrame2:Show()

    -- Update numbers
    trackReagents()
end)

-- Window functions
table1:RegisterEvents({
    ["OnEnter"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
        if row then
            local celldata = data[realrow][1]
            GameTooltip:ClearLines()
            GameTooltip:SetOwner(pslFrame1, "ANCHOR_BOTTOM")
            GameTooltip:SetHyperlink(celldata)
            GameTooltip:Show()
        end
    end
})
table1:RegisterEvents({
    ["OnLeave"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
        GameTooltip:ClearLines()
        GameTooltip:Hide()
    end
})
table1:RegisterEvents({
    ["OnDragStart"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
        ChatFrame1:AddMessage("[PSL] Dragging")
    end
})
table1:RegisterEvents({
    ["OnMouseDown"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, button, ...)
        if button == "LeftButton" then
            pslFrame1:StartMoving()
            GameTooltip:ClearLines()
            GameTooltip:Hide()
        end
    end
})
table1:RegisterEvents({
    ["OnMouseUp"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
        pslFrame1:StopMovingOrSizing()

        local celldata = data[realrow][1]
        GameTooltip:ClearLines()
        GameTooltip:SetOwner(pslFrame1, "ANCHOR_BOTTOM")
        GameTooltip:SetHyperlink(celldata)
        GameTooltip:Show()
    end
})

table2:RegisterEvents({
    ["OnEnter"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
        if row then
            local celldata = data[realrow][1]
            GameTooltip:ClearLines()
            GameTooltip:SetOwner(pslFrame2, "ANCHOR_BOTTOM")
            GameTooltip:SetHyperlink(celldata)
            GameTooltip:Show()
        end
    end
})
table2:RegisterEvents({
    ["OnLeave"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
        GameTooltip:ClearLines()
        GameTooltip:Hide()
    end
})
table2:RegisterEvents({
    ["OnClick"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, button, ...)
        -- Only activate if right-clicking on the tracked column
        if column == 2 and button == "RightButton" then
            -- Get selected recipe ID
            function getkey(t, value)
                for k,v in pairs(t) do
                  if v == value then return k end
                end
                return nil
            end
            local recipeID = getkey(recipeLinks, data[realrow][1])

            -- Untrack recipe
            recipesTracked[recipeID] = recipesTracked[recipeID] - 1

            -- Set numbers to nil if it doesn't exist anymore
            if recipesTracked[recipeID] == 0 then
                recipesTracked[recipeID] = nil
                recipeLinks[recipeID] = nil
            end

            -- Disable the remove button if the recipe isn't tracked anymore
            if not recipesTracked[recipeID] then removeCraftListButton:Disable() end

            -- Remove the reagents from the total count
            for idx = 1, C_TradeSkillUI.GetRecipeNumReagents(recipeID) do
                -- Get name, icon and number
                local reagentName, reagentTexture, reagentCount = C_TradeSkillUI.GetRecipeReagentInfo(recipeID, idx)
                -- Do maths
                reagentNumbers[reagentName] = reagentNumbers[reagentName] - reagentCount
                -- Set numbers to nil if it doesn't exist anymore
                if reagentNumbers[reagentName] == 0 then
                    reagentNumbers[reagentName] = nil
                    reagentLinks[reagentName] = nil
                end
            end

            -- Show windows
            pslFrame1:Show()
            pslFrame2:Show()

            -- Update numbers
            trackReagents()
        elseif button == "LeftButton" then
            --
        end
    end
})
table2:RegisterEvents({
    ["OnMouseDown"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, button, ...)
        if button == "LeftButton" then
            pslFrame2:StartMoving()
            GameTooltip:ClearLines()
            GameTooltip:Hide()
        end
    end
})
table2:RegisterEvents({
    ["OnMouseUp"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
        pslFrame2:StopMovingOrSizing()

        local celldata = data[realrow][1]
        GameTooltip:ClearLines()
        GameTooltip:SetOwner(pslFrame2, "ANCHOR_BOTTOM")
        GameTooltip:SetHyperlink(celldata)
        GameTooltip:Show()
    end
})

f:SetScript("OnEvent", function(self,event, loadedAddon, ...)
    if event == "ADDON_LOADED" and loadedAddon == "ProfessionShoppingList" then
        pslInitialise()
        pslCreateTrackingWindows()
        pslCreateButtons()

        -- Initialise the Settings page so the Minimap button can go there
        local settings = CreateFrame("Frame")
        settings.name = "ProfessionShoppingList"
        InterfaceOptions_AddCategory(settings)

        -- Initialise the minimap button before the settings button is made, so it can toggle it
        local miniButton = LibStub("LibDataBroker-1.1"):NewDataObject("ProfessionShoppingList", {
            type = "data source",
            text = "Profession Shopping List",
            icon = 136249,
            
            OnClick = function(self, button)
                if button == "LeftButton" then
                    -- Toggle tracking windows
                    if pslFrame1:IsShown() then
                        pslFrame1:Hide()
                        pslFrame2:Hide()
                    else
                        pslFrame1:Show()
                        pslFrame2:Show()
                    end
                    -- Only update numbers if numbers exist
                    if reagentNumbers then trackReagents() end
                elseif button == "RightButton" then
                    InterfaceAddOnsList_Update()
                    InterfaceOptionsFrame_OpenToCategory(settings)
                end
            end,
            
            OnTooltipShow = function(tooltip)
                if not tooltip or not tooltip.AddLine then return end
                tooltip:AddLine("Left-click: Toggle the PSL window.\nRight-click: Open PSL settings.")
            end,   
        })
                            
        local icon = LibStub("LibDBIcon-1.0", true)
        icon:Register("ProfessionShoppingList", miniButton, userSettings)

        if userSettings["hide"] == true then
            icon:Hide("ProfessionShoppingList")
        else
            icon:Show("ProfessionShoppingList")
        end

        -- Settings scroll frame
        local scrollFrame = CreateFrame("ScrollFrame", nil, settings, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 3, -4)
        scrollFrame:SetPoint("BOTTOMRIGHT", -27, 4)

        local scrollChild = CreateFrame("Frame")
        scrollFrame:SetScrollChild(scrollChild)
        scrollChild:SetWidth(InterfaceOptionsFramePanelContainer:GetWidth()-18)
        scrollChild:SetHeight(1) 

        -- Settings
        local title = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 10, -8)
        title:SetText("Profession Shopping List")

        local cbMinimapButton = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
        cbMinimapButton.Text:SetText("Minimap button")
        cbMinimapButton:SetPoint("TOPLEFT", 10, -25)
        cbMinimapButton:SetChecked(not userSettings["hide"])
        cbMinimapButton.SetValue = function()
            userSettings["hide"] = not cbMinimapButton:GetChecked()
            if userSettings["hide"] == true then
                icon:Hide("ProfessionShoppingList")
            else
                icon:Show("ProfessionShoppingList")
            end
        end

        local cbSmallButtons = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
        cbSmallButtons.Text:SetText("Small buttons")
        cbSmallButtons:SetPoint("TOPLEFT", cbMinimapButton, "BOTTOMLEFT", 0, 0)
        cbSmallButtons:SetChecked(userSettings["smallButtons"])
        cbSmallButtons.SetValue = function()
            userSettings["smallButtons"] = cbSmallButtons:GetChecked()
            pslCreateButtons()
        end

        local pslSettingsText1 = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
        pslSettingsText1:SetPoint("TOP", cbMinimapButton.Text, "TOP")
        pslSettingsText1:SetPoint("LEFT", scrollChild, "LEFT", 250, 0)
        pslSettingsText1:SetJustifyH("LEFT");
        pslSettingsText1:SetText("Chat commands:\n/psl |cffFFFFFF- Toggle the PSL windows.\n|R/psl settings |cffFFFFFF- Open the PSL settings.\n|R/psl clear |cffFFFFFF- Clear all tracked recipes.")

        local pslSettingsText2 = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
        pslSettingsText2:SetPoint("TOPLEFT", pslSettingsText1, "BOTTOMLEFT", 0, -15)
        pslSettingsText2:SetJustifyH("LEFT");
        pslSettingsText2:SetText("Mouse interactions:\nLeft-click + Drag|cffFFFFFF: Move the PSL windows.\n|RRight-click in the Tracked column|cffFFFFFF: Untrack 1 recipe.")

        local pslSettingsText3 = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
        pslSettingsText3:SetPoint("TOPLEFT", pslSettingsText2, "BOTTOMLEFT", 0, -15)
        pslSettingsText3:SetJustifyH("LEFT");
        pslSettingsText3:SetText("Other features:\n|cffFFFFFF- Adds a Chef's Hat button to the Cooking window,\nif the toy is owned.")

        -- Slash commands
        SLASH_PSL1 = "/psl";
        function SlashCmdList.PSL(msg, editBox)
            if msg == "settings" then
                InterfaceAddOnsList_Update()
                InterfaceOptionsFrame_OpenToCategory(settings)
            -- Clear list
            elseif msg == "clear" then
                recipesTracked = {}
                reagentNumbers = {}
                reagentLinks = {}
                recipeLinks = {}
                trackReagents()
            -- No arguments
            else
                -- Toggle tracking windows
                if pslFrame1:IsShown() then
                    pslFrame1:Hide()
                    pslFrame2:Hide()
                else
                    pslFrame1:Show()
                    pslFrame2:Show()
                end
                -- Only update numbers if numbers exist
                if reagentNumbers then trackReagents() end
            end
        end
    end

    -- Check if the Remove button should be disabled
    if event == "TRADE_SKILL_SHOW" then
        function checkRemoveButton()
            -- Get selected recipe ID
            local recipeID = TradeSkillFrame.RecipeList:GetSelectedRecipeID()

            -- Check if recipe is tracked
            if not recipesTracked[recipeID] then removeCraftListButton:Disable()
            elseif recipesTracked[recipeID] == 0 then removeCraftListButton:Disable()
            else removeCraftListButton:Enable()
            end
        end

        checkRemoveButton()

        -- Check whenever a new recipe is selected
        hooksecurefunc(TradeSkillFrame.RecipeList, "OnRecipeButtonClicked", function(self, recipeButton, recipeInfo, mouseButton)
            checkRemoveButton()
        end)

        -- Show the Chef's Hat if the Cooking window is open and the toy is known
        skillLineID = C_TradeSkillUI.GetTradeSkillLine()

        if skillLineID == 185 and PlayerHasToy(134020) then
            chefsHatButton:Show()
        else
            chefsHatButton:Hide()
        end
    end

    -- Update the numbers when bag changes occur
    if event == "BAG_UPDATE" then
        trackReagents()
    end

end)