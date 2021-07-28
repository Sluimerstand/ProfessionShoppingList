-- Windows
local f = CreateFrame("Frame")
local ScrollingTable = LibStub("ScrollingTable")

-- API Events
f:RegisterEvent("TRADE_SKILL_SHOW")
f:RegisterEvent("BAG_UPDATE")

-- Load the TradeSkillUI to prevent stuff from being wonky
if not TradeSkillFrame then
    UIParentLoadAddOn("Blizzard_TradeSkillUI")
end

-- Declare some variables
if not userSettings then userSettings = {} end
if not recipesTracked then recipesTracked = {} end
if not reagentNumbers then reagentNumbers = {} end
if not reagentLinks then reagentLinks = {} end
if not recipeLinks then recipeLinks = {} end

--Enable default user settings
function userSettingsDefault()
    -- Button size
    if not userSettings["buttonSize"] then userSettings["buttonSize"] = "normal" end
end

userSettingsDefault()

--Create Tracking windows
function createTrackingWindows()
    -- Reagent tracking
    if not pslFrame1 then
        -- Frame
        pslFrame1 = CreateFrame("Frame", "pslTrackingWindow1", UIParent, "BackdropTemplateMixin" and "BackdropTemplate")
        pslFrame1:SetSize(230, 270)
        pslFrame1:SetPoint("CENTER")
        pslFrame1:SetResizable(true)
        pslFrame1:SetMinResize(230, 270)
        pslFrame1:Hide()

        -- Background
        -- pslFrame1:SetBackdrop({
        --     bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        --     edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        --     edgeSize = 1,
        -- })
        -- pslFrame1:SetBackdropColor(0, 0, 0, .5)
        -- pslFrame1:SetBackdropBorderColor(0, 0, 0)

        -- Movable window
        pslFrame1:EnableMouse(true)
        pslFrame1:SetMovable(true)
        pslFrame1:RegisterForDrag("LeftButton")
        pslFrame1:SetScript("OnDragStart", f.StartMoving)
        pslFrame1:SetScript("OnDragStop", f.StopMovingOrSizing)
        pslFrame1:SetScript("OnHide", f.StopMovingOrSizing)

        -- Close button
        local close = CreateFrame("Button", "pslCloseButtonName1", pslFrame1, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", pslFrame1, "TOPRIGHT", 6, 6)
        close:SetScript("OnClick", function()
            pslFrame1:Hide()
        end)

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

        -- Drag me
        pslFrame1.text = pslFrame1:CreateFontString(nil,"ARTWORK") 
        pslFrame1.text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        pslFrame1.text:SetPoint("BOTTOM", 0, 5)
        pslFrame1.text:SetText("Drag me")
        pslFrame1.text:Hide()
        pslFrame1:SetScript("OnEnter", function() pslFrame1.text:Show() end)
        pslFrame1:SetScript("OnLeave", function() pslFrame1.text:Hide() end)

        -- Column formatting, Reagents
        local cols = {}
        cols[1] = {
            ["name"] = "Reagents",
            ["width"] = 145,
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
            ["width"] = 55,
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
        table1 = ScrollingTable:CreateST(cols, 15, nil, nil, pslFrame1);
    end

    -- Recipe tracking
    if not pslFrame2 then
        -- Frame
        pslFrame2 = CreateFrame("Frame", "pslTrackingWindow2", UIParent, "BackdropTemplateMixin" and "BackdropTemplate")
        pslFrame2:SetSize(230, 270)
        pslFrame2:SetPoint("CENTER", 300, 0)
        pslFrame2:SetResizable(true)
        pslFrame2:SetMinResize(230, 270)
        pslFrame2:Hide()

        -- Background
        -- pslFrame2:SetBackdrop({
        --     bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        --     edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        --     edgeSize = 1,
        -- })
        -- pslFrame2:SetBackdropColor(0, 0, 0, .5)
        -- pslFrame2:SetBackdropBorderColor(0, 0, 0)

        -- Movable window
        pslFrame2:EnableMouse(true)
        pslFrame2:SetMovable(true)
        pslFrame2:RegisterForDrag("LeftButton")
        pslFrame2:SetScript("OnDragStart", f.StartMoving)
        pslFrame2:SetScript("OnDragStop", f.StopMovingOrSizing)
        pslFrame2:SetScript("OnHide", f.StopMovingOrSizing)

        -- Close button
        local close = CreateFrame("Button", "pslCloseButtonName2", pslFrame2, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", pslFrame2, "TOPRIGHT", 6, 6)
        close:SetScript("OnClick", function()
            pslFrame2:Hide()
        end)

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

        -- Drag me
        pslFrame2.text = pslFrame2:CreateFontString(nil,"ARTWORK") 
        pslFrame2.text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        pslFrame2.text:SetPoint("BOTTOM", 0, 5)
        pslFrame2.text:SetText("Drag me")
        pslFrame2.text:Hide()
        pslFrame2:SetScript('OnEnter', function() pslFrame2.text:Show() end)
        pslFrame2:SetScript('OnLeave', function() pslFrame2.text:Hide() end)

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
        table2 = ScrollingTable:CreateST(cols, 15, nil, nil, pslFrame2);
    end
end

createTrackingWindows()

-- Slash command to toggle window
SLASH_PSL1 = "/psl";
function SlashCmdList.PSL(msg, editBox)
    -- Toggle button size
    if msg == "button" then
        if userSettings["buttonSize"] == "normal" then userSettings["buttonSize"] = "small"
        elseif userSettings["buttonSize"] == "small" then userSettings["buttonSize"] = "normal"
        end
        --ChatFrame1:AddMessage("[PSL] Button size is now: "..userSettings["buttonSize"]..". Re-open the tradeskill window for the change to take effect.")
        pslCreateButtons()
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
    if userSettings["buttonSize"] == "normal" then
        addCraftListButton:SetText("Add to list")
        addCraftListButton:SetWidth(90)
        addCraftListButton:SetPoint("TOPRIGHT", TradeSkillFrame.DetailsFrame.CreateButton, "TOPRIGHT", -150, 418)
    -- If button size is small
    elseif userSettings["buttonSize"] == "small" then
        addCraftListButton:SetText("+")
        addCraftListButton:SetWidth(30)
        addCraftListButton:SetPoint("TOPRIGHT", TradeSkillFrame.DetailsFrame.CreateButton, "TOPRIGHT", -210, 418)
    end

    -- Create the "Remove from list" button
    if not removeCraftListButton then
        removeCraftListButton = CreateFrame("Button", nil, TradeSkillFrame, "UIPanelButtonTemplate")
    end
    -- If button size is normal
    if userSettings["buttonSize"] == "normal" then
        removeCraftListButton:SetText("Remove from list")
        removeCraftListButton:SetWidth(130)
        removeCraftListButton:SetPoint("TOPRIGHT", TradeSkillFrame.DetailsFrame.CreateButton, "TOPRIGHT", -20, 418)
    -- If button size is small
    elseif userSettings["buttonSize"] == "small" then
        removeCraftListButton:SetText("-")
        removeCraftListButton:SetWidth(30)
        removeCraftListButton:SetPoint("TOPRIGHT", TradeSkillFrame.DetailsFrame.CreateButton, "TOPRIGHT", -180, 418)
    end
end

pslCreateButtons()

-- Make the "Add to list" button actually do the thing
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

-- Make the "Remove from list" button actually do the thing
removeCraftListButton:SetScript("OnClick", function()
    -- Get selected recipe ID
    local recipeID = TradeSkillFrame.RecipeList:GetSelectedRecipeID()

    -- Untrack recipe
    recipesTracked[recipeID] = recipesTracked[recipeID] - 1 --Lua error

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

f:SetScript("OnEvent", function(self,event, ...)
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
end

-- Update the numbers when bag changes occur
if event == "BAG_UPDATE" then
    trackReagents()
end

end)