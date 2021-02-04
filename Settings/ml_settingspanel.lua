-- ===========================================================================
--  Helper Functions
-- ===========================================================================

-- Sourced from Azurency's CQUI link: https://github.com/Azurency/CQUI_Community-Edition/blob/master/Assets/UI/civ6common.lua
local function PopulateCheckBox(control, setting_name)
    local current_value = GameConfiguration.GetValue(setting_name);
    if (current_value == nil) then
        if (GameInfo.ML_Settings[setting_name]) then --LY Checks if this setting has a default state defined in the database
            if (GameInfo.ML_Settings[setting_name].Value == 0) then --because 0 is true in Lua
                current_value = false;
            else
                current_value = true;
            end
        else
            current_value = false;
        end
        GameConfiguration.SetValue(setting_name, current_value); --/LY
    end

    control:SetSelected(current_value);
    control:RegisterCallback(Mouse.eLClick,
        function()
            local selected = not control:IsSelected();
            control:SetSelected(selected);
            GameConfiguration.SetValue(setting_name, selected);
            LuaEvents.ML_SettingsUpdate();
        end
    );
end

function InitButton(control, callbackLClick, callbackRClick)
    control:RegisterCallback(Mouse.eLClick, callbackLClick)
    if callbackRClick ~= nil then
        control:RegisterCallback(Mouse.eRClick, callbackRClick)
    end
    control:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over") end)
end

-- ===========================================================================
--  UI Handler
-- ===========================================================================

local function OnOpen()
    print("Showing panel!")
    ContextPtr:SetHide(false);
end

local function OnClose()
    ContextPtr:SetHide(true);
end

-- ===========================================================================
--  Game Engine Handlers
-- ===========================================================================

local function ChangeContainer()
    print("Changing container to ingame hud")
    -- Change the parent to /InGame/HUD container so that it hides correcty during diplomacy, etc
    local hudContainer = ContextPtr:LookUpControl("/InGame/HUD")
    Controls.SettingsPanel:ChangeParent(hudContainer)
end

local function OnInit(isReload:boolean)
    if isReload then
        ChangeContainer()
    end
end

local function OnShutdown()
    -- Destroy the container manually
    local hudContainer = ContextPtr:LookUpControl("/InGame/HUD")
    if hudContainer ~= nil then
        hudContainer:DestroyChild(Controls.SettingsPanel)
    end
end

-- ===========================================================================
--  Init
-- ===========================================================================

local function Initialize()
    print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
    print("          ML Settings Panel")
    print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")

    ContextPtr:SetInitHandler( OnInit )
    ContextPtr:SetShutdown( OnShutdown )
    ContextPtr:SetInputHandler( OnInputHandler, true )

    PopulateCheckBox(Controls.AutoApplyBuilderLensCheckbox, "ML_AutoApplyBuilderLens")
    PopulateCheckBox(Controls.AutoApplyScoutLensCheckbox, "ML_AutoApplyScoutLens")

    -- Call this once to ensure all files have updated settings
    LuaEvents.ML_SettingsUpdate();

    InitButton(Controls.ConfirmButton, OnClose)

    LuaEvents.ML_ShowSettingsMenu.Add( OnOpen )
end

Initialize()
