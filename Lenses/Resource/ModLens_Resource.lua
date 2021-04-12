include("LensSupport")

local PANEL_OFFSET_Y:number = 32
local PANEL_OFFSET_X:number = -5

local LENS_NAME = "ML_RESOURCE"
local ML_LENS_LAYER = UILens.CreateLensLayerHash("Hex_Coloring_Appeal_Level")

-- ===========================================================================
--  Member Variables
-- ===========================================================================

local m_isOpen:boolean = false
local m_bonusResourcesToHide:table = {}
local m_luxuryResourcesToHide:table = {}
local m_strategicResourcesToHide:table = {}

local m_showBonusResource:boolean = true
local m_showLuxuryResource:boolean = true
local m_showStrategicResource:boolean = true

local m_resetBonusResourceList:boolean = true
local m_resetLuxuryResourceList:boolean = true
local m_resetStrategicResourceList:boolean = true

local m_resourceExclusionList:table = {
    "RESOURCE_ANTIQUITY_SITE",
    "RESOURCE_SHIPWRECK"
}

-- ===========================================================================
--  City Overlap Support functions
-- ===========================================================================

local function ShowResourceLens()
    print("Showing " .. LENS_NAME)
    LuaEvents.MinimapPanel_SetActiveModLens(LENS_NAME)
    UILens.ToggleLayerOn(ML_LENS_LAYER)
end

local function ClearResourceLens()
    print("Clearing " .. LENS_NAME)
    if UILens.IsLayerOn(ML_LENS_LAYER) then
        UILens.ToggleLayerOff(ML_LENS_LAYER)
    else
        print("Nothing to clear")
    end
    LuaEvents.MinimapPanel_SetActiveModLens("NONE")
end

local function clamp(val, min, max)
    if val < min then
        return min
    elseif val > max then
        return max
    end
    return val
end

-- ===========================================================================
--  Exported functions
-- ===========================================================================

function RefreshResourceLens()
    -- Assuming city overlap lens is already applied
    UILens.ClearLayerHexes(ML_LENS_LAYER)
    SetResourceLens()
end

function SetResourceLens()
    -- print("Show Resource lens")
    local mapWidth, mapHeight = Map.GetGridSize()
    local localPlayer:number = Game.GetLocalPlayer()
    local pPlayer:table = Players[localPlayer]
    local localPlayerVis:table = PlayersVisibility[localPlayer]

    local LuxConnectedColor   :number = UI.GetColorValue("COLOR_LUXCONNECTED_RES_LENS")
    local StratConnectedColor :number = UI.GetColorValue("COLOR_STRATCONNECTED_RES_LENS")
    local BonusConnectedColor :number = UI.GetColorValue("COLOR_BONUSCONNECTED_RES_LENS")
    local LuxNConnectedColor  :number = UI.GetColorValue("COLOR_LUXNCONNECTED_RES_LENS")
    local StratNConnectedColor  :number = UI.GetColorValue("COLOR_STRATNCONNECTED_RES_LENS")
    local BonusNConnectedColor  :number = UI.GetColorValue("COLOR_BONUSNCONNECTED_RES_LENS")
    local IgnoreColor         :number = UI.GetColorValue("COLOR_MORELENSES_GREY")

    local ConnectedLuxury       = {}
    local ConnectedStrategic    = {}
    local ConnectedBonus        = {}
    local NotConnectedLuxury    = {}
    local NotConnectedStrategic = {}
    local NotConnectedBonus     = {}
    local IgnorePlots           = {}

    for i = 0, (mapWidth * mapHeight) - 1, 1 do
        local pPlot:table = Map.GetPlotByIndex(i)

        if localPlayerVis:IsRevealed(pPlot:GetX(), pPlot:GetY()) then
            if playerHasDiscoveredResource(pPlayer, pPlot) then
                local resourceType = pPlot:GetResourceType()
                if resourceType ~= nil and resourceType >= 0 then
                    local resourceInfo = GameInfo.Resources[resourceType]
                    if resourceInfo ~= nil then
                        -- Check if resource is not in exclusion list
                        if not has_value(m_resourceExclusionList, resourceInfo.ResourceType) then
                            if resourceInfo.ResourceClassType == "RESOURCECLASS_BONUS" and m_showBonusResource and
                                    (not has_value(m_bonusResourcesToHide, resourceInfo.ResourceType)) then
                                if plotHasImprovement(pPlot) and not pPlot:IsImprovementPillaged() then
                                    table.insert(ConnectedBonus, i)
                                else
                                    table.insert(NotConnectedBonus, i)
                                end
                            elseif resourceInfo.ResourceClassType == "RESOURCECLASS_LUXURY" and m_showLuxuryResource and
                                    (not has_value(m_luxuryResourcesToHide, resourceInfo.ResourceType)) then
                                if plotHasImprovement(pPlot) and not pPlot:IsImprovementPillaged() then
                                    table.insert(ConnectedLuxury, i)
                                else
                                    table.insert(NotConnectedLuxury, i)
                                end
                            elseif resourceInfo.ResourceClassType == "RESOURCECLASS_STRATEGIC" and m_showStrategicResource and
                                    (not has_value(m_strategicResourcesToHide, resourceInfo.ResourceType)) then
                                if plotHasImprovement(pPlot) and not pPlot:IsImprovementPillaged() then
                                    table.insert(ConnectedStrategic, i)
                                else
                                    table.insert(NotConnectedStrategic, i)
                                end
                            else
                                table.insert(IgnorePlots, i)
                            end
                        else
                            table.insert(IgnorePlots, i)
                        end
                    else
                        table.insert(IgnorePlots, i)
                    end
                else
                    table.insert(IgnorePlots, i)
                end
            else
                table.insert(IgnorePlots, i)
            end
        end
    end

    if table.count(ConnectedLuxury) > 0 then
        UILens.SetLayerHexesColoredArea( ML_LENS_LAYER, localPlayer, ConnectedLuxury, LuxConnectedColor )
    end
    if table.count(ConnectedStrategic) > 0 then
        UILens.SetLayerHexesColoredArea( ML_LENS_LAYER, localPlayer, ConnectedStrategic, StratConnectedColor )
    end
    if table.count(ConnectedBonus) > 0 then
        UILens.SetLayerHexesColoredArea( ML_LENS_LAYER, localPlayer, ConnectedBonus, BonusConnectedColor )
    end
    if table.count(NotConnectedLuxury) > 0 then
        UILens.SetLayerHexesColoredArea( ML_LENS_LAYER, localPlayer, NotConnectedLuxury, LuxNConnectedColor )
    end
    if table.count(NotConnectedStrategic) > 0 then
        UILens.SetLayerHexesColoredArea( ML_LENS_LAYER, localPlayer, NotConnectedStrategic, StratNConnectedColor )
    end
    if table.count(NotConnectedBonus) > 0 then
        UILens.SetLayerHexesColoredArea( ML_LENS_LAYER, localPlayer, NotConnectedBonus, BonusNConnectedColor )
    end
    if table.count(IgnorePlots) > 0 then
        UILens.SetLayerHexesColoredArea( ML_LENS_LAYER, localPlayer, IgnorePlots, IgnoreColor )
    end
end

function RefreshResourcePicker()
    print("Show Resource Picker")
    local mapWidth, mapHeight = Map.GetGridSize()
    local localPlayer:number = Game.GetLocalPlayer()
    local pPlayer:table = Players[localPlayer]
    local localPlayerVis:table = PlayersVisibility[localPlayer]

    local BonusResources:table = {}
    local LuxuryResources:table = {}
    local StrategicResources:table = {}
    local resourceCounts:table = {}
    local playerResourceCounts:table = {}
    local playerImprovedResourceCounts:table = {}

    -- Reset our resources to hide
    if m_resetBonusResourceList then
        m_bonusResourcesToHide = {}
    end
    if m_resetLuxuryResourceList then
        m_luxuryResourcesToHide = {}
    end
    if m_resetStrategicResourceList then
        m_strategicResourcesToHide = {}
    end

    for i = 0, (mapWidth * mapHeight) - 1, 1 do
        local pPlot:table = Map.GetPlotByIndex(i)
        if localPlayerVis:IsRevealed(pPlot:GetX(), pPlot:GetY()) and playerHasDiscoveredResource(pPlayer, pPlot) then
            local resourceType = pPlot:GetResourceType()
            if resourceType ~= nil and resourceType >= 0 then
                local resourceInfo = GameInfo.Resources[resourceType]
                if resourceInfo ~= nil then
                    -- Check if resource is not in exclusion list
                    if not has_value(m_resourceExclusionList, resourceInfo.ResourceType) then
                        -- Add entry if it doesn't exist
                        if resourceCounts[resourceInfo.ResourceType] == nil then
                            resourceCounts[resourceInfo.ResourceType] = 0
                        end
                        if playerResourceCounts[resourceInfo.ResourceType] == nil then
                            playerResourceCounts[resourceInfo.ResourceType] = 0
                        end
                        if playerImprovedResourceCounts[resourceInfo.ResourceType] == nil then
                            playerImprovedResourceCounts[resourceInfo.ResourceType] = 0
                        end

                        -- Count resources
                        resourceCounts[resourceInfo.ResourceType] = resourceCounts[resourceInfo.ResourceType] + 1
                        if pPlot:GetOwner() == Game.GetLocalPlayer() then
                            playerResourceCounts[resourceInfo.ResourceType] = playerResourceCounts[resourceInfo.ResourceType] + 1
                            if pPlot:GetImprovementType() ~= -1 then
                                playerImprovedResourceCounts[resourceInfo.ResourceType] = playerImprovedResourceCounts[resourceInfo.ResourceType] + 1
                            end
                        end

                        -- Add resource to specific group
                        if resourceInfo.ResourceClassType == "RESOURCECLASS_BONUS" then
                            if not has_rInfo(BonusResources, resourceInfo.ResourceType) then
                                table.insert(BonusResources, resourceInfo)
                                if (not m_showBonusResource) and m_resetBonusResourceList then
                                    table.insert(m_bonusResourcesToHide, resourceInfo.ResourceType)
                                end
                            end
                        elseif resourceInfo.ResourceClassType == "RESOURCECLASS_LUXURY" then
                            if not has_rInfo(LuxuryResources, resourceInfo.ResourceType) then
                                table.insert(LuxuryResources, resourceInfo)
                                if (not m_showLuxuryResource) and m_resetLuxuryResourceList then
                                    table.insert(m_luxuryResourcesToHide, resourceInfo.ResourceType)
                                end
                            end
                        elseif resourceInfo.ResourceClassType == "RESOURCECLASS_STRATEGIC" then
                            if not has_rInfo(StrategicResources, resourceInfo.ResourceType) then
                                table.insert(StrategicResources, resourceInfo)
                                if (not m_showStrategicResource) and m_resetStrategicResourceList then
                                    table.insert(m_strategicResourcesToHide, resourceInfo.ResourceType)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Done with reset
    m_resetBonusResourceList = false
    m_resetLuxuryResourceList = false
    m_resetStrategicResourceList = false

    Controls.BonusResourcePickStack:DestroyAllChildren()
    Controls.LuxuryResourcePickStack:DestroyAllChildren()
    Controls.StrategicResourcePickStack:DestroyAllChildren()

    -- Bonus Resources
    if table.count(BonusResources) > 0 then
        for i, resourceInfo in ipairs(BonusResources) do
            -- print(Locale.Lookup(resourceInfo.Name))
            local resourcePickInstance:table = {}
            ContextPtr:BuildInstanceForControl( "ResourcePickEntry", resourcePickInstance, Controls.BonusResourcePickStack )

            local nameLabel:string = "[ICON_" .. resourceInfo.ResourceType .. "]" .. Locale.Lookup(resourceInfo.Name)
            local countLabel:string = playerResourceCounts[resourceInfo.ResourceType] .. "/" .. resourceCounts[resourceInfo.ResourceType]
            local tooltipLabel:string = Locale.Lookup("LOC_HUD_RESOURCE_LENS_COUNT_TOOLTIP", playerResourceCounts[resourceInfo.ResourceType],
                    playerImprovedResourceCounts[resourceInfo.ResourceType], resourceCounts[resourceInfo.ResourceType], nameLabel)
            resourcePickInstance.ResourceLabel:SetText(nameLabel)
            resourcePickInstance.ResourceCount:SetText(countLabel)
            resourcePickInstance.ResourceCount:SetToolTipString(tooltipLabel)

            local bHideResource:boolean = (not m_showBonusResource) or has_value(m_bonusResourcesToHide, resourceInfo.ResourceType)
            resourcePickInstance.ResourceCheckbox:SetCheck(not bHideResource)
            resourcePickInstance.ResourceCheckbox:RegisterCallback(
                Mouse.eLClick,
                function()
                    HandleBonusResourceCheckbox(resourcePickInstance, resourceInfo.ResourceType)
                end)
        end
    end

    -- Luxury Resources
    if table.count(LuxuryResources) > 0 then
        for i, resourceInfo in ipairs(LuxuryResources) do
            -- print(Locale.Lookup(resourceInfo.Name))
            local resourcePickInstance:table = {}
            ContextPtr:BuildInstanceForControl( "ResourcePickEntry", resourcePickInstance, Controls.LuxuryResourcePickStack )

            local nameLabel:string = "[ICON_" .. resourceInfo.ResourceType .. "]" .. Locale.Lookup(resourceInfo.Name)
            local countLabel:string = playerResourceCounts[resourceInfo.ResourceType] .. "/" .. resourceCounts[resourceInfo.ResourceType]
            local tooltipLabel:string = Locale.Lookup("LOC_HUD_RESOURCE_LENS_COUNT_TOOLTIP", playerResourceCounts[resourceInfo.ResourceType],
                    playerImprovedResourceCounts[resourceInfo.ResourceType], resourceCounts[resourceInfo.ResourceType], nameLabel)
            resourcePickInstance.ResourceLabel:SetText(nameLabel)
            resourcePickInstance.ResourceCount:SetText(countLabel)
            resourcePickInstance.ResourceCount:SetToolTipString(tooltipLabel)

            local bHideResource:boolean = (not m_showLuxuryResource) or has_value(m_luxuryResourcesToHide, resourceInfo.ResourceType)
            resourcePickInstance.ResourceCheckbox:SetCheck(not bHideResource)
            resourcePickInstance.ResourceCheckbox:RegisterCallback(
                Mouse.eLClick,
                function()
                    HandleLuxuryResourceCheckbox(resourcePickInstance, resourceInfo.ResourceType)
                end)
        end
    end

    -- Strategic Resources
    if table.count(StrategicResources) > 0 then
        for i, resourceInfo in ipairs(StrategicResources) do
            -- print(Locale.Lookup(resourceInfo.Name))
            local resourcePickInstance:table = {}
            ContextPtr:BuildInstanceForControl( "ResourcePickEntry", resourcePickInstance, Controls.StrategicResourcePickStack )

            local nameLabel:string = "[ICON_" .. resourceInfo.ResourceType .. "]" .. Locale.Lookup(resourceInfo.Name)
            local countLabel:string = playerResourceCounts[resourceInfo.ResourceType] .. "/" .. resourceCounts[resourceInfo.ResourceType]
            local tooltipLabel:string = Locale.Lookup("LOC_HUD_RESOURCE_LENS_COUNT_TOOLTIP", playerResourceCounts[resourceInfo.ResourceType],
                    playerImprovedResourceCounts[resourceInfo.ResourceType], resourceCounts[resourceInfo.ResourceType], nameLabel)
            resourcePickInstance.ResourceLabel:SetText(nameLabel)
            resourcePickInstance.ResourceCount:SetText(countLabel)
            resourcePickInstance.ResourceCount:SetToolTipString(tooltipLabel)

            local bHideResource:boolean = (not m_showStrategicResource) or has_value(m_strategicResourcesToHide, resourceInfo.ResourceType)
            resourcePickInstance.ResourceCheckbox:SetCheck(not bHideResource)
            resourcePickInstance.ResourceCheckbox:RegisterCallback(
                Mouse.eLClick,
                function()
                    HandleStrategicResourceCheckbox(resourcePickInstance, resourceInfo.ResourceType)
                end)
        end
    end

    -- Cleanup
    Controls.BonusResourcePickStack:CalculateSize()
    Controls.LuxuryResourcePickStack:CalculateSize()
    Controls.StrategicResourcePickStack:CalculateSize()
    Controls.ResourcePickList:CalculateSize()
end

function ToggleResourceLens_Bonus()
    m_showBonusResource = Controls.ShowBonusResource:IsChecked()
    m_resetBonusResourceList = true

    -- Assuming resource lens is already applied
    RefreshResourcePicker()
    RefreshResourceLens()
end

function ToggleResourceLens_Luxury()
    m_showLuxuryResource = Controls.ShowLuxuryResource:IsChecked()
    m_resetLuxuryResourceList = true

    -- Assuming resource lens is already applied
    RefreshResourcePicker()
    RefreshResourceLens()
end

function ToggleResourceLens_Strategic()
    m_showStrategicResource = Controls.ShowStrategicResource:IsChecked()
    m_resetStrategicResourceList = true

    -- Assuming resource lens is already applied
    RefreshResourcePicker()
    RefreshResourceLens()
end

function HandleBonusResourceCheckbox(pControl, resourceType)
    if not pControl.ResourceCheckbox:IsChecked() then
        -- Don't show this resource
        ndup_insert(m_bonusResourcesToHide, resourceType)
    else
        -- Ensure the bonus resource category is checked
        Controls.ShowBonusResource:SetCheck(true)
        m_showBonusResource = true

        -- Show this resource
        find_and_remove(m_bonusResourcesToHide, resourceType)
    end

    -- Assuming resource lens is already applied
    RefreshResourceLens()
end

function HandleLuxuryResourceCheckbox(pControl, resourceType)
    if not pControl.ResourceCheckbox:IsChecked() then
        -- Don't show this resource
        ndup_insert(m_luxuryResourcesToHide, resourceType)
    else
        -- Ensure the bonus resource category is checked
        Controls.ShowLuxuryResource:SetCheck(true)
        m_showLuxuryResource = true

        -- Show this resource
        find_and_remove(m_luxuryResourcesToHide, resourceType)
    end

    -- Assuming resource lens is already applied
    RefreshResourceLens()
end

function HandleStrategicResourceCheckbox(pControl, resourceType)
    if not pControl.ResourceCheckbox:IsChecked() then
        -- Don't show this resource
        ndup_insert(m_strategicResourcesToHide, resourceType)
    else
        -- Ensure the bonus resource category is checked
        Controls.ShowStrategicResource:SetCheck(true)
        m_showStrategicResource = true

        -- Show this resource
        find_and_remove(m_strategicResourcesToHide, resourceType)
    end

    -- Assuming resource lens is already applied
    RefreshResourceLens()
end

-- ===========================================================================
--  UI Controls
-- ===========================================================================

local function Open()
    Controls.ResourceLensOptionsPanel:SetHide(false)
    m_isOpen = true
    RefreshResourcePicker()  -- Recall this to apply options properly
end

local function Close()
    Controls.ResourceLensOptionsPanel:SetHide(true)
    m_isOpen = false
end

local function TogglePanel()
    if m_isOpen then
        Close()
    else
        Open()
    end
end

local function OnReoffsetPanel()
    -- Get size and offsets for minimap panel
    local offsets = {}
    LuaEvents.MinimapPanel_GetLensPanelOffsets(offsets)
    Controls.ResourceLensOptionsPanel:SetOffsetY(offsets.Y + PANEL_OFFSET_Y)
    Controls.ResourceLensOptionsPanel:SetOffsetX(offsets.X + PANEL_OFFSET_X)
end

-- ===========================================================================
--  Game Engine Events
-- ===========================================================================

local function OnLensLayerOn(layerNum:number)
    if layerNum == ML_LENS_LAYER then
        local lens = {}
        LuaEvents.MinimapPanel_GetActiveModLens(lens)
        if lens[1] == LENS_NAME then
            SetResourceLens()
        end
    end
end

local function ChangeContainer()
    -- Change the parent to /InGame/HUD container so that it hides correcty during diplomacy, etc
    local hudContainer = ContextPtr:LookUpControl("/InGame/HUD")
    Controls.ResourceLensOptionsPanel:ChangeParent(hudContainer)
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
        hudContainer:DestroyChild(Controls.ResourceLensOptionsPanel)
    end
end

-- ===========================================================================
--  Init
-- ===========================================================================

-- minimappanel.lua
local ResourceLensEntry = {
    LensButtonText = "LOC_HUD_RESOURCE_LENS",
    LensButtonTooltip = "LOC_HUD_RESOURCE_LENS_TOOLTIP",
    Initialize = nil,
    OnToggle = TogglePanel,
    GetColorPlotTable = nil  -- Don't pass a function here since we will have our own trigger
}

-- modallenspanel.lua
local ResourceLensModalPanelEntry = {}
ResourceLensModalPanelEntry.LensTextKey = "LOC_HUD_RESOURCE_LENS"
ResourceLensModalPanelEntry.Legend = {
    {"LOC_TOOLTIP_RESOURCE_LENS_LUXURY",        UI.GetColorValue("COLOR_LUXCONNECTED_RES_LENS")},
    {"LOC_TOOLTIP_RESOURCE_LENS_NLUXURY",       UI.GetColorValue("COLOR_LUXNCONNECTED_RES_LENS")},
    {"LOC_TOOLTIP_RESOURCE_LENS_BONUS",         UI.GetColorValue("COLOR_BONUSCONNECTED_RES_LENS")},
    {"LOC_TOOLTIP_RESOURCE_LENS_NBONUS",        UI.GetColorValue("COLOR_BONUSNCONNECTED_RES_LENS")},
    {"LOC_TOOLTIP_RESOURCE_LENS_STRATEGIC",     UI.GetColorValue("COLOR_STRATCONNECTED_RES_LENS")},
    {"LOC_TOOLTIP_RESOURCE_LENS_NSTRATEGIC",    UI.GetColorValue("COLOR_STRATNCONNECTED_RES_LENS")}
}

-- Don't import this into g_ModLenses, since this for the UI (ie not lens)
local function Initialize()
    print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
    print("           Resource Panel")
    print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
    Close()
    OnReoffsetPanel()

    ContextPtr:SetInitHandler( OnInit )
    ContextPtr:SetShutdown( OnShutdown )
    ContextPtr:SetInputHandler( OnInputHandler, true )

    Events.LoadScreenClose.Add(
        function()
            ChangeContainer()
            LuaEvents.MinimapPanel_AddLensEntry(LENS_NAME, ResourceLensEntry)
            LuaEvents.ModalLensPanel_AddLensEntry(LENS_NAME, ResourceLensModalPanelEntry)
        end
    )
    Events.LensLayerOn.Add( OnLensLayerOn )

    -- Resource Lens Setting
    Controls.ShowBonusResource:RegisterCallback( Mouse.eLClick, ToggleResourceLens_Bonus )
    Controls.ShowLuxuryResource:RegisterCallback( Mouse.eLClick, ToggleResourceLens_Luxury )
    Controls.ShowStrategicResource:RegisterCallback( Mouse.eLClick, ToggleResourceLens_Strategic )

    LuaEvents.ML_ReoffsetPanels.Add( OnReoffsetPanel )
    LuaEvents.ML_CloseLensPanels.Add( Close )
end

Initialize()
