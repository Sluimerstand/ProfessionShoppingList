-- Windows
local f = CreateFrame("Frame")
local ScrollingTable = LibStub("ScrollingTable")

-- API Events
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("BAG_UPDATE")
f:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
f:RegisterEvent("TRADE_SKILL_SHOW")
f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
f:RegisterEvent("SPELL_DATA_LOAD_RESULT")

-- Load the TradeSkillUI to prevent stuff from being wonky
if not C_TradeSkillUI then
    UIParentLoadAddOn("C_TradeSkillUI")
end

-- Create SavedVariables
function pslInitialise()
    -- Declare some variables
    if not userSettings then userSettings = {} end
    if not recipesTracked then recipesTracked = {} end
    if not recipeLinks then recipeLinks = {} end
    if not reagentsTracked then reagentsTracked = {} end
    if not recipeLibrary then recipeLibrary = {} end

    -- Enable default user settings
    if userSettings["hide"] == nil then userSettings["hide"] = false end
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

    -- Reagent tracking
    if not pslFrame1 then
        -- Frame
        pslFrame1 = CreateFrame("Frame", "pslTrackingWindow1", UIParent, "BackdropTemplateMixin" and "BackdropTemplate")
        pslFrame1:SetSize(255, 270)
        pslFrame1:SetPoint("CENTER")
        pslFrame1:EnableMouse(true)
        pslFrame1:SetMovable(true)
        pslFrame1:Hide()

        -- Close button
        local close = CreateFrame("Button", "pslCloseButtonName1", pslFrame1, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", pslFrame1, "TOPRIGHT", 1, -2)
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
        pslFrame2:SetScript("OnDragStart", function(self, button) self:StartMoving() end)
        pslFrame2:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

        -- Close button
        local close = CreateFrame("Button", "pslCloseButtonName2", pslFrame2, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", pslFrame2, "TOPRIGHT", 1, -2)
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
function pslReagents()
    -- Update recipes tracked
    local data = {};
    for recipeID, no in pairs(recipesTracked) do
        table.insert(data, {recipeLinks[recipeID], no})
        table2:SetData(data, true)
    end
    table2:SetData(data, true)
    
    -- Recalculate reagents
    reagentsTracked = {}

    for recipeID, no in pairs(recipesTracked) do
        -- Get numReagents
        local reagentsTable = C_TradeSkillUI.GetRecipeSchematic(recipeID, false).reagentSlotSchematics
        local numReagents = 0
        if reagentsTable[9] then numReagents = 9
        elseif reagentsTable[8] then numReagents = 8
        elseif reagentsTable[7] then numReagents = 7
        elseif reagentsTable[6] then numReagents = 6
        elseif reagentsTable[5] then numReagents = 5
        elseif reagentsTable[4] then numReagents = 4
        elseif reagentsTable[3] then numReagents = 3
        elseif reagentsTable[2] then numReagents = 2
        elseif reagentsTable[1] then numReagents = 1
        end

        if numReagents ~= 0 then
            for idx = 1, numReagents do
                -- Get info
                local reagentID = C_TradeSkillUI.GetRecipeSchematic(recipeID, false).reagentSlotSchematics[idx].reagents[1].itemID
                local reagentAmount = C_TradeSkillUI.GetRecipeSchematic(recipeID, false).reagentSlotSchematics[idx].quantityRequired

                -- Set value to zero if it doesn't exist
                if reagentsTracked[reagentID] == nil then reagentsTracked[reagentID] = 0 end

                -- Do maths
                reagentsTracked[reagentID] = reagentsTracked[reagentID] + reagentAmount * no
            end
        end
    end

    -- Update reagents tracked
    local data = {}
    for i, no in pairs(reagentsTracked) do
        local function getInfo()
            local itemName, itemLink = GetItemInfo(i)

            -- Try again if error
            if itemName == nil or itemLink == nil then
                C_Timer.After(.5, getInfo)
                do return end
            end
            
            if userSettings["showRemaining"] == false then
                table.insert(data, {itemLink, GetItemCount(i, true, false, true).."/"..no})
            else
                table.insert(data, {itemLink, math.max(0,no-GetItemCount(i, true, false, true))})
            end

            table1:SetData(data, true)
        end
        getInfo()
    end
    table1:SetData(data, true)

    -- Check if the Untrack button should be enabled
    if not recipesTracked[pslSelectedRecipeID] then removeCraftListButton:Disable()
    elseif recipesTracked[pslSelectedRecipeID] == 0 then removeCraftListButton:Disable()
    else removeCraftListButton:Enable()
    end
end

-- Create buttons
function pslCreateButtons()
    -- Hide and disable existing tracking button
    ProfessionsFrame.CraftingPage.SchematicForm.TrackRecipeCheckBox:SetAlpha(0)
    ProfessionsFrame.CraftingPage.SchematicForm.TrackRecipeCheckBox:EnableMouse(false)

    -- Create the "Track" button
    if not addCraftListButton then
        addCraftListButton = CreateFrame("Button", nil, ProfessionsFrame, "UIPanelButtonTemplate")
    end
    addCraftListButton:SetText("Track")
    addCraftListButton:SetWidth(60)
    addCraftListButton:SetPoint("TOPRIGHT", ProfessionsFrame.CraftingPage.SchematicForm, "TOPRIGHT", -9, -10)
    addCraftListButton:SetFrameStrata("HIGH")

    -- Create the "Untrack" button
    if not removeCraftListButton then
        removeCraftListButton = CreateFrame("Button", nil, ProfessionsFrame, "UIPanelButtonTemplate")
    end
    removeCraftListButton:SetText("Untrack")
    removeCraftListButton:SetWidth(70)
    removeCraftListButton:SetPoint("TOPRIGHT", addCraftListButton, "TOPLEFT", -4, 0)
    removeCraftListButton:SetFrameStrata("HIGH")

    -- Make the "Track" button actually do the thing
    addCraftListButton:SetScript("OnClick", function()
        -- Get selected recipe ID
        local recipeID = pslSelectedRecipeID

        -- Track recipe
        if not recipesTracked[recipeID] then recipesTracked[recipeID] = 0 end
        recipesTracked[recipeID] = recipesTracked[recipeID] + 1

        -- Add recipe link
        recipeLinks[recipeID] = C_TradeSkillUI.GetRecipeOutputItemData(recipeID).hyperlink

        -- Show windows
        pslFrame1:Show()
        pslFrame2:Show()

        -- Update numbers
        pslReagents()
    end)

    -- Make the "Untrack" button actually do the thing
    removeCraftListButton:SetScript("OnClick", function()
        -- Get selected recipe ID
        local recipeID = pslSelectedRecipeID

        -- Show windows
        pslFrame1:Show()
        pslFrame2:Show()

        -- Untrack recipe
        recipesTracked[recipeID] = recipesTracked[recipeID] - 1

        -- Set numbers to nil if it doesn't exist anymore
        if recipesTracked[recipeID] == 0 then
            recipesTracked[recipeID] = nil
            recipeLinks[recipeID] = nil
        end

        -- Update numbers
        pslReagents()
    end)

    -- Create Chef's Hat button
    if not chefsHatButton then
        chefsHatButton = CreateFrame("Button", "ChefsHatButton", ProfessionsFrame, "UIPanelButtonTemplate")
    end

    chefsHatButton:SetWidth(40)
    chefsHatButton:SetHeight(40)
    chefsHatButton:SetNormalTexture(236571)
    chefsHatButton:SetPoint("BOTTOMRIGHT", ProfessionsFrame.CraftingPage.SchematicForm, "BOTTOMRIGHT", -5, 4)
    chefsHatButton:SetFrameStrata("HIGH")
    chefsHatButton:SetScript("OnClick", function()
        UseToyByName("Chef's Hat")
    end)
end

-- Tooltip information
function pslTooltipInfo()
    --local match = string.match
    --local strsplit = strsplit

    local function OnTooltipSetItem(tooltip)
        -- Catch the GetItem() error
        if not tooltip.GetItem then return end

        local _, link = tooltip:GetItem()

        -- Don't do anything if no item link
        if not link then return end

        -- Get itemID
        local itemID = GetItemInfoFromHyperlink(link)

        if userSettings["showTooltip"] == true and reagentsTracked[itemID] then
            tooltip:AddLine(" ")
            tooltip:AddLine("PSL: "..GetItemCount(reagentsTracked[itemID], true, false, true).."/"..reagentsTracked[itemID].." ("..math.max(0,reagentsTracked[itemID]-GetItemCount(reagentsTracked[itemID], true, false, true)).." more needed)")
        end
    end

    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)
end

f:SetScript("OnEvent", function(self, event, arg1, arg2, ...)
    -- When the AddOn is fully loaded, actually run the components
    if event == "ADDON_LOADED" and arg1 == "ProfessionShoppingList" then
        pslInitialise()
        pslCreateTrackingWindows()
        pslCreateButtons()
        pslTooltipInfo()

        -- Settings and minimap icon
        function pslSettings()
            -- Initialise the Settings page so the Minimap button can go there
            local settings = CreateFrame("Frame")            
            settings.name = "Profession Shopping List"
            InterfaceOptions_AddCategory(settings)

            -- Initialise the minimap button before the settings button is made, so it can toggle it
            local miniButton = LibStub("LibDataBroker-1.1"):NewDataObject("ProfessionShoppingList", {
                type = "data source",
                text = "Profession Shopping List",
                icon = "Interface\\AddOns\\ProfessionShoppingList\\assets\\psl_icon",
                
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
                        -- Only update numbers if numbers exist, delayed to fix WoWThingSync interference
                        if reagentsTracked then pslReagents() end
                    elseif button == "RightButton" then
                        InterfaceOptionsFrame_OpenToCategory("Profession Shopping List")
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

            -- Settings frame
            local scrollFrame = CreateFrame("ScrollFrame", nil, settings, "UIPanelScrollFrameTemplate")
            scrollFrame:SetPoint("TOPLEFT", 3, -4)
            scrollFrame:SetPoint("BOTTOMRIGHT", -27, 4)

            local scrollChild = CreateFrame("Frame")
            scrollFrame:SetScrollChild(scrollChild)
            scrollChild:SetWidth(SettingsPanel.Container.SettingsCanvas:GetWidth()-18)
            scrollChild:SetHeight(1) 

            -- Settings
            local title = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
            title:SetPoint("TOPLEFT", 10, -8)
            title:SetText("Profession Shopping List")

            local cbMinimapButton = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
            cbMinimapButton.Text:SetText("Minimap button")
            cbMinimapButton:SetPoint("TOPLEFT", 10, -25)
            cbMinimapButton:SetChecked(not userSettings["hide"])
            cbMinimapButton:SetScript("OnClick", function(self)
                userSettings["hide"] = not self:GetChecked()
                if userSettings["hide"] == true then
                    icon:Hide("ProfessionShoppingList")
                else
                    icon:Show("ProfessionShoppingList")
                end
            end)

            local cbRemoveCraft = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
            cbRemoveCraft.Text:SetText("Untrack on crafting")
            cbRemoveCraft:SetPoint("TOPLEFT", cbMinimapButton, "BOTTOMLEFT", 0, 0)
            cbRemoveCraft:SetChecked(userSettings["removeCraft"])
            cbRemoveCraft:SetScript("OnClick", function(self)
                userSettings["removeCraft"] = cbRemoveCraft:GetChecked()
            end)

            local cbShowRemaining = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
            cbShowRemaining.Text:SetText("Show remaining reagents, not total")
            cbShowRemaining:SetPoint("TOPLEFT", cbRemoveCraft, "BOTTOMLEFT", 0, 0)
            cbShowRemaining:SetChecked(userSettings["showRemaining"])
            cbShowRemaining:SetScript("OnClick", function(self)
                userSettings["showRemaining"] = cbShowRemaining:GetChecked()
                pslReagents()
            end)

            local cbShowTooltip = CreateFrame("CheckButton", nil, scrollChild, "InterfaceOptionsCheckButtonTemplate")
            cbShowTooltip.Text:SetText("Show tooltip information")
            cbShowTooltip:SetPoint("TOPLEFT", cbShowRemaining, "BOTTOMLEFT", 0, 0)
            cbShowTooltip:SetChecked(userSettings["showTooltip"])
            cbShowTooltip:SetScript("OnClick", function(self)
                userSettings["showTooltip"] = cbShowTooltip:GetChecked()
            end)

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
            pslSettingsText1:SetPoint("TOPLEFT", labelReagentColumns, "BOTTOMLEFT", 0, -10)
            pslSettingsText1:SetJustifyH("LEFT");
            pslSettingsText1:SetText("Chat commands:\n/psl |cffFFFFFF- Toggle the PSL windows.\n|R/psl settings |cffFFFFFF- Open the PSL settings.\n|R/psl clear |cffFFFFFF- Clear all tracked recipes.")

            local pslSettingsText2 = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
            pslSettingsText2:SetPoint("TOPLEFT", pslSettingsText1, "BOTTOMLEFT", 0, -15)
            pslSettingsText2:SetJustifyH("LEFT");
            pslSettingsText2:SetText("Mouse interactions:\nDrag|cffFFFFFF: Move the PSL windows.\n|RLeft-click Recipe|cffFFFFFF: Open the recipe (if known on current character).\n|RRight-click Recipe #|cffFFFFFF: Untrack 1 of the selected recipe.\n|RShift+right-click Recipe #|cffFFFFFF: Untrack all of the selected recipe.\n|RShift+click Reagent|cffFFFFFF: Add recipe for the selected subreagent, if it exists.\n(This only works for professions that have been opened with PSL active.)")

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
                -- Clear recipes and reagents
                recipesTracked = {}
                reagentsTracked = {}
                recipeLinks = {}
                recipeLibrary = {}
                pslReagents()

                -- Disable remove button
                removeCraftListButton:Disable()

                -- Remove old version variables
                reagentNumbers = nil
                reagentLinks = nil
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
                -- Only update numbers if numbers exist, delayed to fix WoWThingSync interference
                if reagentsTracked then pslReagents() end
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
                    if column == 1 and button == "LeftButton" and IsShiftKeyDown() == true and realrow ~= nil then
                        -- Get recipeID
                        local itemID = GetItemInfoFromHyperlink(data[realrow][1])

                        -- Get possible recipeIDs
                        local recipeIDs = {}
                        local no = 0

                        for r, i in pairs(recipeLibrary) do
                            if i == itemID then
                                no = no + 1
                                recipeIDs[no] = r
                            end
                        end

                        -- If there is only one possible recipe, use that
                        if no == 1 then
                            local recipeID = recipeIDs[no]

                            -- Track recipe
                            local quantityMade = C_TradeSkillUI.GetRecipeSchematic(recipeID, false).quantityMin
                            recipesTracked[recipeID] = math.max(0, math.ceil(reagentsTracked[itemID] / quantityMade) - GetItemCount(itemID))

                            -- Add recipe link
                            recipeLinks[recipeID] = C_TradeSkillUI.GetRecipeOutputItemData(recipeID).hyperlink

                            -- Show windows
                            pslFrame1:Show()
                            pslFrame2:Show()

                            -- Update numbers
                            pslReagents()

                        -- If there is more than one possible recipe, provide options
                        elseif no > 1 then
                            -- Create popup frame
                            local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
                            f:SetPoint("CENTER")
                            f:SetBackdrop({
                                bgFile = "Interface/Tooltips/UI-Tooltip-Background",
                                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                                edgeSize = 16,
                                insets = { left = 4, right = 4, top = 4, bottom = 4 },
                            })
                            f:SetBackdropColor(0, 0, 0, 1)
                            f:EnableMouse(true)
                            f:SetMovable(true)
                            f:RegisterForDrag("LeftButton")
                            f:SetScript("OnDragStart", function(self, button) self:StartMoving() end)
                            f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)     
                            f:Show()

                            -- Close button
                            local close = CreateFrame("Button", "pslOptionCloseButton", f, "UIPanelCloseButton")
                            close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
                            close:SetScript("OnClick", function()
                                f:Hide()
                            end)

                            -- Text
                            local pslOptionText = f:CreateFontString("ARTWORK", nil, "GameFontNormal")
                            pslOptionText:SetPoint("CENTER", f, "CENTER", 0, 0)
                            pslOptionText:SetPoint("TOP", f, "TOP", 0, -10)
                            pslOptionText:SetJustifyH("CENTER")
                            pslOptionText:SetText("|cffFFFFFFThere are multiple recipes which can create\n"..data[realrow][1]..".\n\nPlease select one of the following:")

                            -- Get numReagents #1
                            local reagentsTable = C_TradeSkillUI.GetRecipeSchematic(recipeIDs[1], false).reagentSlotSchematics
                            local numReagents = 0
                            if reagentsTable[9] then numReagents = 9
                            elseif reagentsTable[8] then numReagents = 8
                            elseif reagentsTable[7] then numReagents = 7
                            elseif reagentsTable[6] then numReagents = 6
                            elseif reagentsTable[5] then numReagents = 5
                            elseif reagentsTable[4] then numReagents = 4
                            elseif reagentsTable[3] then numReagents = 3
                            elseif reagentsTable[2] then numReagents = 2
                            elseif reagentsTable[1] then numReagents = 1
                            end

                            -- Text
                            local pslOption1 = f:CreateFontString("ARTWORK", nil, "GameFontNormal")
                            pslOption1:SetPoint("LEFT", f, "LEFT", 10, 0)
                            pslOption1:SetPoint("TOP", pslOptionText, "BOTTOM", 0, -40)
                            pslOption1:SetWidth(200)
                            pslOption1:SetJustifyH("LEFT")
                            pslOption1:SetText("|cffFFFFFF")

                            -- Get reagents #1
                            if numReagents ~= 0 then
                                for idx = 1, numReagents do
                                    -- Get info
                                    local reagentID = C_TradeSkillUI.GetRecipeSchematic(recipeIDs[1], false).reagentSlotSchematics[idx].reagents[1].itemID
                                    local reagentAmount = C_TradeSkillUI.GetRecipeSchematic(recipeIDs[1], false).reagentSlotSchematics[idx].quantityRequired
                                    local itemName, itemLink = GetItemInfo(reagentID)

                                    -- Text
                                    oldText = pslOption1:GetText()
                                    pslOption1:SetText(oldText..reagentAmount.."x "..itemLink.."\n")
                                end
                            end

                            -- Button #1
                            pslOptionButton1 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
                            pslOptionButton1:SetText(C_TradeSkillUI.GetRecipeSchematic(recipeIDs[1], false).name)
                            pslOptionButton1:SetWidth(200)
                            pslOptionButton1:SetPoint("BOTTOM", pslOption1, "TOP", 0, 5)
                            pslOptionButton1:SetPoint("CENTER", pslOption1, "CENTER", 0, 0)
                            pslOptionButton1:SetScript("OnClick", function()
                                -- Get selected recipe ID
                                local recipeID = recipeIDs[1]
                        
                                -- Track recipe
                                local quantityMade = C_TradeSkillUI.GetRecipeSchematic(recipeID, false).quantityMin
                                recipesTracked[recipeID] = math.max(0, math.ceil(reagentsTracked[itemID] / quantityMade) - GetItemCount(itemID))
                        
                                -- Add recipe link
                                recipeLinks[recipeID] = C_TradeSkillUI.GetRecipeOutputItemData(recipeID).hyperlink
                        
                                -- Show windows
                                pslFrame1:Show()
                                pslFrame2:Show()
                                f:Hide()
                        
                                -- Update numbers
                                pslReagents()
                            end)
                            
                            -- If two options
                            if no >= 2 then
                                -- Adjust popup frame
                                f:SetSize(430, 205)

                                -- Get numReagents #2
                                local reagentsTable = C_TradeSkillUI.GetRecipeSchematic(recipeIDs[2], false).reagentSlotSchematics
                                local numReagents = 0
                                if reagentsTable[9] then numReagents = 9
                                elseif reagentsTable[8] then numReagents = 8
                                elseif reagentsTable[7] then numReagents = 7
                                elseif reagentsTable[6] then numReagents = 6
                                elseif reagentsTable[5] then numReagents = 5
                                elseif reagentsTable[4] then numReagents = 4
                                elseif reagentsTable[3] then numReagents = 3
                                elseif reagentsTable[2] then numReagents = 2
                                elseif reagentsTable[1] then numReagents = 1
                                end

                                -- Text
                                local pslOption2 = f:CreateFontString("ARTWORK", nil, "GameFontNormal")
                                pslOption2:SetPoint("LEFT", pslOption1, "RIGHT", 10, 0)
                                pslOption2:SetPoint("TOP", pslOption1, "TOP", 0, 0)
                                pslOption2:SetWidth(200)
                                pslOption2:SetJustifyH("LEFT")
                                pslOption2:SetText("|cffFFFFFF")

                                -- Get reagents #2
                                if numReagents ~= 0 then
                                    for idx = 1, numReagents do
                                        -- Get info
                                        local reagentID = C_TradeSkillUI.GetRecipeSchematic(recipeIDs[2], false).reagentSlotSchematics[idx].reagents[1].itemID
                                        local reagentAmount = C_TradeSkillUI.GetRecipeSchematic(recipeIDs[2], false).reagentSlotSchematics[idx].quantityRequired
                                        local itemName, itemLink = GetItemInfo(reagentID)

                                        -- Text
                                        oldText = pslOption2:GetText()
                                        pslOption2:SetText(oldText..reagentAmount.."x "..itemLink.."\n")
                                    end
                                end

                                -- Button #2
                                pslOptionButton2 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
                                pslOptionButton2:SetText(C_TradeSkillUI.GetRecipeSchematic(recipeIDs[2], false).name)
                                pslOptionButton2:SetWidth(200)
                                pslOptionButton2:SetPoint("BOTTOM", pslOption2, "TOP", 0, 5)
                                pslOptionButton2:SetPoint("CENTER", pslOption2, "CENTER", 0, 0)
                                pslOptionButton2:SetScript("OnClick", function()
                                    -- Get selected recipe ID
                                    local recipeID = recipeIDs[2]
                            
                                    -- Track recipe
                                    local quantityMade = C_TradeSkillUI.GetRecipeSchematic(recipeID, false).quantityMin
                                    recipesTracked[recipeID] = math.max(0, math.ceil(reagentsTracked[itemID] / quantityMade) - GetItemCount(itemID))
                            
                                    -- Add recipe link
                                    recipeLinks[recipeID] = C_TradeSkillUI.GetRecipeOutputItemData(recipeID).hyperlink
                            
                                    -- Show windows
                                    pslFrame1:Show()
                                    pslFrame2:Show()
                                    f:Hide()
                            
                                    -- Update numbers
                                    pslReagents()
                                end)
                            end

                            -- If three options
                            if no >= 3 then
                                -- Adjust popup frame
                                f:SetSize(640, 200)

                                -- Get numReagents #3
                                local reagentsTable = C_TradeSkillUI.GetRecipeSchematic(recipeIDs[3], false).reagentSlotSchematics
                                local numReagents = 0
                                if reagentsTable[9] then numReagents = 9
                                elseif reagentsTable[8] then numReagents = 8
                                elseif reagentsTable[7] then numReagents = 7
                                elseif reagentsTable[6] then numReagents = 6
                                elseif reagentsTable[5] then numReagents = 5
                                elseif reagentsTable[4] then numReagents = 4
                                elseif reagentsTable[3] then numReagents = 3
                                elseif reagentsTable[2] then numReagents = 2
                                elseif reagentsTable[1] then numReagents = 1
                                end

                                -- Text
                                local pslOption3 = f:CreateFontString("ARTWORK", nil, "GameFontNormal")
                                pslOption3:SetPoint("LEFT", pslOption1, "RIGHT", 220, 0)
                                pslOption3:SetPoint("TOP", pslOption1, "TOP", 0, 0)
                                pslOption3:SetWidth(200)
                                pslOption3:SetJustifyH("LEFT")
                                pslOption3:SetText("|cffFFFFFF")

                                -- Get reagents #3
                                if numReagents ~= 0 then
                                    for idx = 1, numReagents do
                                        -- Get info
                                        local reagentID = C_TradeSkillUI.GetRecipeSchematic(recipeIDs[3], false).reagentSlotSchematics[idx].reagents[1].itemID
                                        local reagentAmount = C_TradeSkillUI.GetRecipeSchematic(recipeIDs[3], false).reagentSlotSchematics[idx].quantityRequired
                                        local itemName, itemLink = GetItemInfo(reagentID)

                                        -- Text
                                        oldText = pslOption3:GetText()
                                        pslOption3:SetText(oldText..reagentAmount.."x "..itemLink.."\n")
                                    end
                                end

                                -- Button #3
                                pslOptionButton3 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
                                pslOptionButton3:SetText(C_TradeSkillUI.GetRecipeSchematic(recipeIDs[3], false).name)
                                pslOptionButton3:SetWidth(200)
                                pslOptionButton3:SetPoint("BOTTOM", pslOption3, "TOP", 0, 5)
                                pslOptionButton3:SetPoint("CENTER", pslOption3, "CENTER", 0, 0)
                                pslOptionButton3:SetScript("OnClick", function()
                                    -- Get selected recipe ID
                                    local recipeID = recipeIDs[3]
                            
                                    -- Track recipe
                                    local quantityMade = C_TradeSkillUI.GetRecipeSchematic(recipeID, false).quantityMin
                                    recipesTracked[recipeID] = math.max(0, math.ceil(reagentsTracked[itemID] / quantityMade) - GetItemCount(itemID))
                            
                                    -- Add recipe link
                                    recipeLinks[recipeID] = C_TradeSkillUI.GetRecipeOutputItemData(recipeID).hyperlink
                            
                                    -- Show windows
                                    pslFrame1:Show()
                                    pslFrame2:Show()
                                    f:Hide()
                            
                                    -- Update numbers
                                    pslReagents()
                                end)
                            end

                            -- If four options
                            if no >= 4 then
                                -- Adjust popup frame
                                f:SetSize(640, 335)

                                -- Get numReagents #4
                                local reagentsTable = C_TradeSkillUI.GetRecipeSchematic(recipeIDs[4], false).reagentSlotSchematics
                                local numReagents = 0
                                if reagentsTable[9] then numReagents = 9
                                elseif reagentsTable[8] then numReagents = 8
                                elseif reagentsTable[7] then numReagents = 7
                                elseif reagentsTable[6] then numReagents = 6
                                elseif reagentsTable[5] then numReagents = 5
                                elseif reagentsTable[4] then numReagents = 4
                                elseif reagentsTable[3] then numReagents = 3
                                elseif reagentsTable[2] then numReagents = 2
                                elseif reagentsTable[1] then numReagents = 1
                                end

                                -- Text
                                local pslOption4 = f:CreateFontString("ARTWORK", nil, "GameFontNormal")
                                pslOption4:SetPoint("LEFT", pslOption1, "LEFT", 0, 0)
                                pslOption4:SetPoint("TOP", pslOption1, "TOP", 0, -130)
                                pslOption4:SetWidth(200)
                                pslOption4:SetJustifyH("LEFT")
                                pslOption4:SetText("|cffFFFFFF")

                                -- Get reagents #4
                                if numReagents ~= 0 then
                                    for idx = 1, numReagents do
                                        -- Get info
                                        local reagentID = C_TradeSkillUI.GetRecipeSchematic(recipeIDs[4], false).reagentSlotSchematics[idx].reagents[1].itemID
                                        local reagentAmount = C_TradeSkillUI.GetRecipeSchematic(recipeIDs[4], false).reagentSlotSchematics[idx].quantityRequired
                                        local itemName, itemLink = GetItemInfo(reagentID)

                                        -- Text
                                        oldText = pslOption4:GetText()
                                        pslOption4:SetText(oldText..reagentAmount.."x "..itemLink.."\n")
                                    end
                                end

                                -- Button #4
                                pslOptionButton4 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
                                pslOptionButton4:SetText(C_TradeSkillUI.GetRecipeSchematic(recipeIDs[4], false).name)
                                pslOptionButton4:SetWidth(200)
                                pslOptionButton4:SetPoint("BOTTOM", pslOption4, "TOP", 0, 5)
                                pslOptionButton4:SetPoint("CENTER", pslOption4, "CENTER", 0, 0)
                                pslOptionButton4:SetScript("OnClick", function()
                                    -- Get selected recipe ID
                                    local recipeID = recipeIDs[4]
                            
                                    -- Track recipe
                                    local quantityMade = C_TradeSkillUI.GetRecipeSchematic(recipeID, false).quantityMin
                                    recipesTracked[recipeID] = math.max(0, math.ceil(reagentsTracked[itemID] / quantityMade) - GetItemCount(itemID))
                            
                                    -- Add recipe link
                                    recipeLinks[recipeID] = C_TradeSkillUI.GetRecipeOutputItemData(recipeID).hyperlink
                            
                                    -- Show windows
                                    pslFrame1:Show()
                                    pslFrame2:Show()
                                    f:Hide()
                            
                                    -- Update numbers
                                    pslReagents()
                                end)
                            end

                            -- If five options
                            if no >= 5 then
                                -- Get numReagents #5
                                local reagentsTable = C_TradeSkillUI.GetRecipeSchematic(recipeIDs[5], false).reagentSlotSchematics
                                local numReagents = 0
                                if reagentsTable[9] then numReagents = 9
                                elseif reagentsTable[8] then numReagents = 8
                                elseif reagentsTable[7] then numReagents = 7
                                elseif reagentsTable[6] then numReagents = 6
                                elseif reagentsTable[5] then numReagents = 5
                                elseif reagentsTable[4] then numReagents = 4
                                elseif reagentsTable[3] then numReagents = 3
                                elseif reagentsTable[2] then numReagents = 2
                                elseif reagentsTable[1] then numReagents = 1
                                end

                                -- Text
                                local pslOption5 = f:CreateFontString("ARTWORK", nil, "GameFontNormal")
                                pslOption5:SetPoint("LEFT", pslOption1, "RIGHT", 10, 0)
                                pslOption5:SetPoint("TOP", pslOption1, "TOP", 0, -130)
                                pslOption5:SetWidth(200)
                                pslOption5:SetJustifyH("LEFT")
                                pslOption5:SetText("|cffFFFFFF")

                                -- Get reagents #5
                                if numReagents ~= 0 then
                                    for idx = 1, numReagents do
                                        -- Get info
                                        local reagentID = C_TradeSkillUI.GetRecipeSchematic(recipeIDs[5], false).reagentSlotSchematics[idx].reagents[1].itemID
                                        local reagentAmount = C_TradeSkillUI.GetRecipeSchematic(recipeIDs[5], false).reagentSlotSchematics[idx].quantityRequired
                                        local itemName, itemLink = GetItemInfo(reagentID)

                                        -- Text
                                        oldText = pslOption5:GetText()
                                        pslOption5:SetText(oldText..reagentAmount.."x "..itemLink.."\n")
                                    end
                                end

                                -- Button #5
                                pslOptionButton5 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
                                pslOptionButton5:SetText(C_TradeSkillUI.GetRecipeSchematic(recipeIDs[5], false).name)
                                pslOptionButton5:SetWidth(200)
                                pslOptionButton5:SetPoint("BOTTOM", pslOption5, "TOP", 0, 5)
                                pslOptionButton5:SetPoint("CENTER", pslOption5, "CENTER", 0, 0)
                                pslOptionButton5:SetScript("OnClick", function()
                                    -- Get selected recipe ID
                                    local recipeID = recipeIDs[5]
                            
                                    -- Track recipe
                                    local quantityMade = C_TradeSkillUI.GetRecipeSchematic(recipeID, false).quantityMin
                                    recipesTracked[recipeID] = math.max(0, math.ceil(reagentsTracked[itemID] / quantityMade) - GetItemCount(itemID))
                            
                                    -- Add recipe link
                                    recipeLinks[recipeID] = C_TradeSkillUI.GetRecipeOutputItemData(recipeID).hyperlink
                            
                                    -- Show windows
                                    pslFrame1:Show()
                                    pslFrame2:Show()
                                    f:Hide()
                            
                                    -- Update numbers
                                    pslReagents()
                                end)
                            end

                            -- If six options
                            if no >= 6 then
                                -- Get numReagents #6
                                local reagentsTable = C_TradeSkillUI.GetRecipeSchematic(recipeIDs[5], false).reagentSlotSchematics
                                local numReagents = 0
                                if reagentsTable[9] then numReagents = 9
                                elseif reagentsTable[8] then numReagents = 8
                                elseif reagentsTable[7] then numReagents = 7
                                elseif reagentsTable[6] then numReagents = 6
                                elseif reagentsTable[5] then numReagents = 5
                                elseif reagentsTable[4] then numReagents = 4
                                elseif reagentsTable[3] then numReagents = 3
                                elseif reagentsTable[2] then numReagents = 2
                                elseif reagentsTable[1] then numReagents = 1
                                end

                                -- Text
                                local pslOption6 = f:CreateFontString("ARTWORK", nil, "GameFontNormal")
                                pslOption6:SetPoint("LEFT", pslOption1, "RIGHT", 220, 0)
                                pslOption6:SetPoint("TOP", pslOption1, "TOP", 0, -130)
                                pslOption6:SetWidth(200)
                                pslOption6:SetJustifyH("LEFT")
                                pslOption6:SetText("|cffFFFFFF")

                                -- Get reagents #6
                                if numReagents ~= 0 then
                                    for idx = 1, numReagents do
                                        -- Get info
                                        local reagentID = C_TradeSkillUI.GetRecipeSchematic(recipeIDs[6], false).reagentSlotSchematics[idx].reagents[1].itemID
                                        local reagentAmount = C_TradeSkillUI.GetRecipeSchematic(recipeIDs[6], false).reagentSlotSchematics[idx].quantityRequired
                                        local itemName, itemLink = GetItemInfo(reagentID)

                                        -- Text
                                        oldText = pslOption6:GetText()
                                        pslOption6:SetText(oldText..reagentAmount.."x "..itemLink.."\n")
                                    end
                                end

                                -- Button #6
                                pslOptionButton6 = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
                                pslOptionButton6:SetText(C_TradeSkillUI.GetRecipeSchematic(recipeIDs[6], false).name)
                                pslOptionButton6:SetWidth(200)
                                pslOptionButton6:SetPoint("BOTTOM", pslOption6, "TOP", 0, 5)
                                pslOptionButton6:SetPoint("CENTER", pslOption6, "CENTER", 0, 0)
                                pslOptionButton6:SetScript("OnClick", function()
                                    -- Get selected recipe ID
                                    local recipeID = recipeIDs[6]
                            
                                    -- Track recipe
                                    local quantityMade = C_TradeSkillUI.GetRecipeSchematic(recipeID, false).quantityMin
                                    recipesTracked[recipeID] = math.max(0, math.ceil(reagentsTracked[itemID] / quantityMade) - GetItemCount(itemID))
                            
                                    -- Add recipe link
                                    recipeLinks[recipeID] = C_TradeSkillUI.GetRecipeOutputItemData(recipeID).hyperlink
                            
                                    -- Show windows
                                    pslFrame1:Show()
                                    pslFrame2:Show()
                                    f:Hide()
                            
                                    -- Update numbers
                                    pslReagents()
                                end)
                            end
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
                    if column == 2 and button == "RightButton" and row ~= nil and realrow ~= nil then
                        -- Get itemID
                        local itemID = GetItemInfoFromHyperlink(data[realrow][1])

                        -- Get possible recipeIDs
                        local recipeIDs = {}
                        local no = 0

                        for r, i in pairs(recipeLibrary) do
                            if i == itemID then
                                no = no + 1
                                recipeIDs[no] = r
                            end
                        end

                        -- Untrack one of each possible recipeID if it is tracked (should be exactly one recipeID)
                        if no ~= 0 then
                            for idx = 1, no do
                                if recipesTracked[recipeIDs[idx]] ~= nil then
                                    if IsShiftKeyDown() == true then
                                        recipesTracked[recipeIDs[idx]] = nil
                                    else
                                        recipesTracked[recipeIDs[idx]] = recipesTracked[recipeIDs[idx]] - 1
                                    end

                                    -- Set numbers to nil if it doesn't exist anymore
                                    if recipesTracked[recipeIDs[idx]] == 0 then
                                        recipesTracked[recipeIDs[idx]] = nil
                                        recipeLinks[recipeIDs[idx]] = nil
                                    end
                                end
                            end
                        end

                        -- Show windows
                        pslFrame1:Show()
                        pslFrame2:Show()
                        
                        -- Update numbers
                        pslReagents()

                    elseif column == 1 and button == "LeftButton" and row ~= nil and realrow ~= nil then
                        -- Find recipeID
                        local recipeID = 0
                        local itemName, itemLink = GetItemInfo(data[realrow][1])
                        for r, i in pairs(recipeLinks) do
                            if GetItemInfoFromHyperlink(i) == GetItemInfoFromHyperlink(data[realrow][1]) then recipeID = r end
                        end

                        -- Open recipe if profession is known
                        if recipeID ~= 0 and C_TradeSkillUI.IsRecipeProfessionLearned(recipeID) == true then C_TradeSkillUI.OpenRecipe(recipeID) end
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

    -- When a recipe is selected or the profession window is opened
    if event == "SPELL_DATA_LOAD_RESULT" then
        -- Check if the Remove button should be disabled
        function checkRemoveButton()
            -- Get selected recipe ID
            if pslSelectedRecipeID == nil then pslSelectedRecipeID = 0 end
            pslSelectedRecipeID = arg1

            -- Check if recipe is tracked
            if not recipesTracked[pslSelectedRecipeID] then removeCraftListButton:Disable()
            elseif recipesTracked[pslSelectedRecipeID] == 0 then removeCraftListButton:Disable()
            else removeCraftListButton:Enable()
            end
        end
        checkRemoveButton()

        -- Show the Chef's Hat if the Cooking window is open and the toy is known
        professionID = C_TradeSkillUI.GetProfessionInfoBySkillLineID(C_TradeSkillUI.GetProfessionChildSkillLineID()).profession

        if professionID == 5 and PlayerHasToy(134020) then
            chefsHatButton:Show()
        else
            chefsHatButton:Hide()
        end
    end
    
    -- Do stuff when a profession window is loaded
    if event == "TRADE_SKILL_LIST_UPDATE" then
        -- Register all recipes for this profession
        for _, id in pairs(C_TradeSkillUI.GetAllRecipeIDs()) do
            local itemID = C_TradeSkillUI.GetRecipeOutputItemData(id).itemID
            if itemID ~= nil then
                recipeLibrary[id] = itemID
            end
        end
    end

    -- Remove 1 tracked recipe when it has been crafted
    if event == "UNIT_SPELLCAST_SUCCEEDED" and userSettings["removeCraft"] == true then
        -- Get selected recipeID
        local recipeID = ...

        if recipesTracked[recipeID] ~= nil then
            -- Untrack recipe
            recipesTracked[recipeID] = recipesTracked[recipeID] - 1
        
            -- Set numbers to nil if it doesn't exist anymore
            if recipesTracked[recipeID] == 0 then
                recipesTracked[recipeID] = nil
            end
        
            -- Disable the remove button if the recipe isn't tracked anymore
            if not recipesTracked[recipeID] then removeCraftListButton:Disable() end
        
            -- Update numbers
            pslReagents()
        end
    end

    -- Update the numbers when bag changes occur
    if event == "BAG_UPDATE" then
        pslReagents()
    end

end)