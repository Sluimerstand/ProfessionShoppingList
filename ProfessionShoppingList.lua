-- Windows
local f = CreateFrame("Frame")
local ScrollingTable = LibStub("ScrollingTable")

-- API Events
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("BAG_UPDATE")
f:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
f:RegisterEvent("TRADE_SKILL_SHOW")
f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

-- Load the TradeSkillUI to prevent stuff from being wonky
if not TradeSkillFrame then
    UIParentLoadAddOn("Blizzard_TradeSkillUI")
end

-- Create SavedVariables
function pslInitialise()
    -- Declare some variables
    if not userSettings then userSettings = {} end
    if not recipesTracked then recipesTracked = {} end
    if not reagentNumbers then reagentNumbers = {} end
    if not reagentLinks then reagentLinks = {} end
    if not recipeLinks then recipeLinks = {} end
    if not recipeLibrary then recipeLibrary = {} end

    -- Enable default user settings
    if userSettings["smallButtons"] == nil then userSettings["smallButtons"] = false end
    if userSettings["removeCraft"] == nil then userSettings["removeCraft"] = true end
    if userSettings["showRemaining"] == nil then userSettings["showRemaining"] = false end
    if userSettings["showTooltip"] == nil then userSettings["showTooltip"] = true end
    if userSettings["recipeRows"] == nil then userSettings["recipeRows"] = 15 end
    if userSettings["reagentRows"] == nil then userSettings["reagentRows"] = 15 end
    if userSettings["recipeWidth"] == nil then userSettings["recipeWidth"] = 150 end
    if userSettings["recipeNoWidth"] == nil then userSettings["recipeNoWidth"] = 30 end
    if userSettings["reagentWidth"] == nil then userSettings["reagentWidth"] = 150 end
    if userSettings["reagentNoWidth"] == nil then userSettings["reagentNoWidth"] = 50 end
end

--Create tracking windows
function pslCreateTrackingWindows()
    -- Reagent tracking

    -- Column formatting, Reagents
    local cols = {}
    cols[1] = {
        ["name"] = "Reagents",
        ["width"] = userSettings["reagentWidth"],
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
        ["name"] = "#",
        ["width"] = userSettings["reagentNoWidth"],
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

        -- Create tracking window
        table1 = ScrollingTable:CreateST(cols, 50, nil, nil, pslFrame1)
    end

    table1:SetDisplayRows(userSettings["reagentRows"], 15)
    table1:SetDisplayCols(cols)
    pslFrame1:SetSize(userSettings["reagentWidth"]+userSettings["reagentNoWidth"]+30, userSettings["reagentRows"]*15+45)

    -- Column formatting, Recipes
    local cols = {}
    cols[1] = {
        ["name"] = "Recipes",
        ["width"] = userSettings["recipeWidth"],
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
        ["name"] = "#",
        ["width"] = userSettings["recipeNoWidth"],
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

        -- Create tracking window
        table2 = ScrollingTable:CreateST(cols, 50, nil, nil, pslFrame2)
    end

    table2:SetDisplayRows(userSettings["recipeRows"], 15)
    table2:SetDisplayCols(cols)
    pslFrame2:SetSize(userSettings["recipeWidth"]+userSettings["recipeNoWidth"]+30, userSettings["recipeRows"]*15+45)
end

-- Update numbers
function trackReagents()
    -- Update recipes tracked
    local data = {};
    for i, no in pairs(recipesTracked) do 
        table.insert(data, {recipeLinks[i], no})
    end
    table2:SetData(data, true)

    -- Recalculate reagents
    reagentNumbers = {}

    for i, no in pairs(recipesTracked) do
        local recipeID = i
        for idx = 1, C_TradeSkillUI.GetRecipeNumReagents(recipeID) do
            -- Get name, icon and number
            local reagentName, reagentTexture, reagentCount = C_TradeSkillUI.GetRecipeReagentInfo(recipeID, idx)
            -- Set value to zero if it doesn't exist
            if not reagentNumbers[reagentName] then reagentNumbers[reagentName] = 0 end
            -- Do maths
            reagentNumbers[reagentName] = reagentNumbers[reagentName] + no * reagentCount
            -- Get item link
            reagentLinks[reagentName] = C_TradeSkillUI.GetRecipeReagentItemLink(recipeID, idx)
        end
    end

    -- Update reagents tracked
    local data = {}
        for i, no in pairs(reagentNumbers) do
            if userSettings["showRemaining"] == false then
                table.insert(data, {reagentLinks[i], GetItemCount(reagentLinks[i], true, false, true).."/"..no})
            else
                table.insert(data, {reagentLinks[i], math.max(0,no-GetItemCount(reagentLinks[i], true, false, true))})
            end
        end
    table1:SetData(data, true)
end

-- Create buttons
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

        -- Show windows
        pslFrame1:Show()
        pslFrame2:Show()

        -- Update numbers
        trackReagents()
    end)

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

-- Tooltip information
function pslTooltipInfo()
    local match = string.match
    local strsplit = strsplit

    local function GameTooltip_OnTooltipSetItem(tooltip)
        local _, link = tooltip:GetItem()
        if not link then return; end
        
        local itemString = match(link, "item[%-?%d:]+")
        --local _, itemID = strsplit(":", itemString)
        local itemName = GetItemInfo(itemString)

        if userSettings["showTooltip"] == true then
            if itemName then
                for k in pairs(reagentNumbers) do
                    if itemName == k then
                        tooltip:AddLine(" ")
                        tooltip:AddLine("PSL: "..GetItemCount(reagentLinks[k], true, false, true).."/"..reagentNumbers[k].." ("..math.max(0,reagentNumbers[k]-GetItemCount(reagentLinks[k], true, false, true)).." more needed)")
                    end
                end
            end
        end
    end

    GameTooltip:HookScript("OnTooltipSetItem", GameTooltip_OnTooltipSetItem)
end

f:SetScript("OnEvent", function(self, event, loadedAddon, ...)
    -- When the AddOn is fully loaded, actually run the components
    if event == "ADDON_LOADED" and loadedAddon == "ProfessionShoppingList" then
        pslInitialise()
        pslCreateTrackingWindows()
        pslCreateButtons()
        pslTooltipInfo()

        -- Settings page
        function pslSettings()
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

            local cbRemoveCraft = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
            cbRemoveCraft.Text:SetText("Untrack on crafting")
            cbRemoveCraft:SetPoint("TOPLEFT", cbSmallButtons, "BOTTOMLEFT", 0, 0)
            cbRemoveCraft:SetChecked(userSettings["removeCraft"])
            cbRemoveCraft.SetValue = function()
                userSettings["removeCraft"] = cbRemoveCraft:GetChecked()
            end

            local cbShowRemaining = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
            cbShowRemaining.Text:SetText("Show remaining reagents, not total")
            cbShowRemaining:SetPoint("TOPLEFT", cbRemoveCraft, "BOTTOMLEFT", 0, 0)
            cbShowRemaining:SetChecked(userSettings["showRemaining"])
            cbShowRemaining.SetValue = function()
                userSettings["showRemaining"] = cbShowRemaining:GetChecked()
                trackReagents()
            end

            local cbShowTooltip = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
            cbShowTooltip.Text:SetText("Show tooltip information")
            cbShowTooltip:SetPoint("TOPLEFT", cbShowRemaining, "BOTTOMLEFT", 0, 0)
            cbShowTooltip:SetChecked(userSettings["showTooltip"])
            cbShowTooltip.SetValue = function()
                userSettings["showTooltip"] = cbShowTooltip:GetChecked()
            end

            local labelRecipeRows = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
            labelRecipeRows:SetPoint("TOPLEFT", cbShowTooltip, "BOTTOMLEFT", 5, 0)
            labelRecipeRows:SetJustifyH("LEFT");
            labelRecipeRows:SetText("|cffFFFFFFRecipe rows:")

            local ebRecipeRows = CreateFrame("EditBox", nil, scrollChild, "InputBoxTemplate")
            ebRecipeRows:SetSize(20,20)
            ebRecipeRows:SetPoint("LEFT", labelRecipeRows, "RIGHT", 10, 0)
            ebRecipeRows:SetAutoFocus(false)
            ebRecipeRows:SetText(userSettings["recipeRows"])
            ebRecipeRows:SetCursorPosition(0)
            ebRecipeRows:SetScript("OnEditFocusLost", function(self, newValue)
                newValue = math.floor(self:GetNumber())
                if newValue >= 1 and newValue <= 50 then
                    userSettings["recipeRows"] = newValue
                elseif newValue > 50 then
                    userSettings["recipeRows"] = 50
                else
                    userSettings["recipeRows"] = 1
                end
                self:SetText(userSettings["recipeRows"])
                pslCreateTrackingWindows()
            end)

            local labelReagentRows = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
            labelReagentRows:SetPoint("TOPLEFT", labelRecipeRows, "BOTTOMLEFT", 0, -10)
            labelReagentRows:SetJustifyH("LEFT");
            labelReagentRows:SetText("|cffFFFFFFReagent rows:")

            local ebReagentRows = CreateFrame("EditBox", nil, scrollChild, "InputBoxTemplate")
            ebReagentRows:SetSize(20,20)
            ebReagentRows:SetPoint("LEFT", labelReagentRows, "RIGHT", 10, 0)
            ebReagentRows:SetAutoFocus(false)
            ebReagentRows:SetText(userSettings["reagentRows"])
            ebReagentRows:SetCursorPosition(0)
            ebReagentRows:SetScript("OnEditFocusLost", function(self, newValue)
                newValue = math.floor(self:GetNumber())
                if newValue >= 1 and newValue <= 50 then
                    userSettings["reagentRows"] = newValue
                elseif newValue > 50 then
                    userSettings["reagentRows"] = 50
                else
                    userSettings["reagentRows"] = 1
                end
                self:SetText(userSettings["reagentRows"])
                pslCreateTrackingWindows()
            end)

            local labelRecipeColumns = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
            labelRecipeColumns:SetPoint("TOPLEFT", labelReagentRows, "BOTTOMLEFT", 0, -10)
            labelRecipeColumns:SetJustifyH("LEFT");
            labelRecipeColumns:SetText("|cffFFFFFFRecipe column width:")

            local ebRecipeWidth = CreateFrame("EditBox", nil, scrollChild, "InputBoxTemplate")
            ebRecipeWidth:SetSize(30,20)
            ebRecipeWidth:SetPoint("LEFT", labelRecipeColumns, "RIGHT", 10, 0)
            ebRecipeWidth:SetAutoFocus(false)
            ebRecipeWidth:SetText(userSettings["recipeWidth"])
            ebRecipeWidth:SetCursorPosition(0)
            ebRecipeWidth:SetScript("OnEditFocusLost", function(self, newValue)
                newValue = math.floor(self:GetNumber())
                if newValue >= 60 and newValue <= 500 then
                    userSettings["recipeWidth"] = newValue
                elseif newValue > 500 then
                    userSettings["recipeWidth"] = 500
                else
                    userSettings["recipeWidth"] = 60
                end
                self:SetText(userSettings["recipeWidth"])
                pslCreateTrackingWindows()
            end)

            local ebRecipeNoWidth = CreateFrame("EditBox", nil, scrollChild, "InputBoxTemplate")
            ebRecipeNoWidth:SetSize(30,20)
            ebRecipeNoWidth:SetPoint("LEFT", ebRecipeWidth, "RIGHT", 10, 0)
            ebRecipeNoWidth:SetAutoFocus(false)
            ebRecipeNoWidth:SetText(userSettings["recipeNoWidth"])
            ebRecipeNoWidth:SetCursorPosition(0)
            ebRecipeNoWidth:SetScript("OnEditFocusLost", function(self, newValue)
                newValue = math.floor(self:GetNumber())
                if newValue >= 20 and newValue <= 500 then
                    userSettings["recipeNoWidth"] = newValue
                elseif newValue > 500 then
                    userSettings["recipeNoWidth"] = 500
                else
                    userSettings["recipeNoWidth"] = 20
                end
                self:SetText(userSettings["recipeNoWidth"])
                pslCreateTrackingWindows()
            end)

            local labelReagentColumns = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
            labelReagentColumns:SetPoint("TOPLEFT", labelRecipeColumns, "BOTTOMLEFT", 0, -10)
            labelReagentColumns:SetJustifyH("LEFT");
            labelReagentColumns:SetText("|cffFFFFFFReagent column width:")

            local ebReagentWidth = CreateFrame("EditBox", nil, scrollChild, "InputBoxTemplate")
            ebReagentWidth :SetSize(30,20)
            ebReagentWidth :SetPoint("LEFT", labelReagentColumns, "RIGHT", 10, 0)
            ebReagentWidth :SetAutoFocus(false)
            ebReagentWidth :SetText(userSettings["reagentWidth"])
            ebReagentWidth :SetCursorPosition(0)
            ebReagentWidth :SetScript("OnEditFocusLost", function(self, newValue)
                newValue = math.floor(self:GetNumber())
                if newValue >= 60 and newValue <= 500 then
                    userSettings["reagentWidth"] = newValue
                elseif newValue > 500 then
                    userSettings["reagentWidth"] = 500
                else
                    userSettings["reagentWidth"] = 60
                end
                self:SetText(userSettings["reagentWidth"])
                pslCreateTrackingWindows()
            end)

            local ebReagentNoWidth = CreateFrame("EditBox", nil, scrollChild, "InputBoxTemplate")
            ebReagentNoWidth:SetSize(30,20)
            ebReagentNoWidth:SetPoint("LEFT", ebReagentWidth, "RIGHT", 10, 0)
            ebReagentNoWidth:SetAutoFocus(false)
            ebReagentNoWidth:SetText(userSettings["reagentNoWidth"])
            ebReagentNoWidth:SetCursorPosition(0)
            ebReagentNoWidth:SetScript("OnEditFocusLost", function(self, newValue)
                newValue = math.floor(self:GetNumber())
                if newValue >= 20 and newValue <= 500 then
                    userSettings["reagentNoWidth"] = newValue
                elseif newValue > 500 then
                    userSettings["reagentNoWidth"] = 500
                else
                    userSettings["reagentNoWidth"] = 20
                end
                self:SetText(userSettings["reagentNoWidth"])
                pslCreateTrackingWindows()
            end)

            local pslSettingsText1 = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
            pslSettingsText1:SetPoint("TOPLEFT", labelReagentColumns, "BOTTOMLEFT", 5, -10)
            pslSettingsText1:SetJustifyH("LEFT");
            pslSettingsText1:SetText("Chat commands:\n/psl |cffFFFFFF- Toggle the PSL windows.\n|R/psl settings |cffFFFFFF- Open the PSL settings.\n|R/psl clear |cffFFFFFF- Clear all tracked recipes.")

            local pslSettingsText2 = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
            pslSettingsText2:SetPoint("TOPLEFT", pslSettingsText1, "BOTTOMLEFT", 0, -15)
            pslSettingsText2:SetJustifyH("LEFT");
            pslSettingsText2:SetText("Mouse interactions:\nLeft-click + Drag|cffFFFFFF: Move the PSL windows.\n|RRight-click in the Tracked column|cffFFFFFF: Untrack 1 of the selected recipe.\n|RShift + Right-click in the Tracked column|cffFFFFFF: Untrack all of the selected recipe.\n|RShift + Click in the Reagent column|cffFFFFFF: Add recipe for the selected subreagent, if it exists.\n(This only works for professions that have been opened with PSL active.)")

            local pslSettingsText3 = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
            pslSettingsText3:SetPoint("TOPLEFT", pslSettingsText2, "BOTTOMLEFT", 0, -15)
            pslSettingsText3:SetJustifyH("LEFT");
            pslSettingsText3:SetText("Other features:\n|cffFFFFFF- Adds a Chef's Hat button to the Cooking window, if the toy is known.")
        end
        pslSettings()

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

        -- Window functions
        function pslWindowFunctions()
            table1:RegisterEvents({
                ["OnEnter"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
                    if row and realrow ~= nil then
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

                    if realrow ~= nil then
                        local celldata = data[realrow][1]
                        GameTooltip:ClearLines()
                        GameTooltip:SetOwner(pslFrame1, "ANCHOR_BOTTOM")
                        GameTooltip:SetHyperlink(celldata)
                        GameTooltip:Show()
                    end
                end
            })
            table1:RegisterEvents({
                ["OnClick"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, button, ...)
                    -- Activate if shift+clicking on the reagents column
                    if column == 1 and button == "LeftButton" and IsShiftKeyDown() == true then
                        -- Get recipeID
                        local itemID = select(3, strfind(data[realrow][1], "item:(%d+)")) --Define this as a function somewhere, gonna use it a lot probably

                        if recipeLibrary[itemID] then
                            --Get selected recipe ID
                            local recipeID = recipeLibrary[itemID]

                            -- Track recipe
                            if not recipesTracked[recipeID] then recipesTracked[recipeID] = 0 end

                            local itemName = GetItemInfo(itemID)
                            recipesTracked[recipeID] = math.max(0, reagentNumbers[itemName] - GetItemCount(itemID))

                            -- Get recipe link
                            recipeLinks[recipeID] = C_TradeSkillUI.GetRecipeItemLink(recipeID)

                            -- Show windows
                            pslFrame1:Show()
                            pslFrame2:Show()

                            -- Update numbers
                            trackReagents()
                        end
                    end
                end
            })

            table2:RegisterEvents({
                ["OnEnter"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
                    if row and realrow ~= nil then
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
                    -- Activate if right-clicking on the tracked column
                    if column == 2 and button == "RightButton" then
                        -- Get selected recipe ID
                        function getkey(t, value)
                            for k,v in pairs(t) do
                            if v == value then return k end
                            end
                            return nil
                        end
                        local recipeID = getkey(recipeLinks, data[realrow][1])

                        -- Untrack recipe / Untrack all if Shift is pressed
                        if IsShiftKeyDown() == true then
                            recipesTracked[recipeID] = 0
                        else
                            recipesTracked[recipeID] = recipesTracked[recipeID] - 1
                        end

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

                        -- Update numbers
                        trackReagents()
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

                    if realrow ~= nil then
                        local celldata = data[realrow][1]
                        GameTooltip:ClearLines()
                        GameTooltip:SetOwner(pslFrame2, "ANCHOR_BOTTOM")
                        GameTooltip:SetHyperlink(celldata)
                        GameTooltip:Show()
                    end
                end
            })
        end
        pslWindowFunctions()
    end

    -- Do stuff when a profession window is opened
    if event == "TRADE_SKILL_SHOW" then
        -- Check if the Remove button should be disabled
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

    -- Do stuff when a profession window is loaded
    if event == "TRADE_SKILL_LIST_UPDATE" then
        -- Register all recipes for this profession
        for _, id in pairs(C_TradeSkillUI.GetAllRecipeIDs()) do
            local recipeInfo = C_TradeSkillUI.GetRecipeInfo(id)
            local craftID = C_TradeSkillUI.GetRecipeItemLink(recipeInfo.recipeID)
            local itemID = select(3, strfind(craftID, "item:(%d+)"))
            if itemID ~= nil then
                recipeLibrary[itemID] = recipeInfo.recipeID
            end
        end
    end

    -- Remove 1 tracked recipe when it has been crafted
    if event == "UNIT_SPELLCAST_SUCCEEDED" and userSettings["removeCraft"] == true then
        -- Get selected recipe ID
        local one, recipeID = ...

        if recipesTracked[recipeID] ~= nil then
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
        
            -- Update numbers
            trackReagents()
        end
    end

    -- Update the numbers when bag changes occur
    if event == "BAG_UPDATE" then
        trackReagents()
    end

end)