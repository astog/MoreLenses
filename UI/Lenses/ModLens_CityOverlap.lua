include("LensSupport")

local PANEL_OFFSET_Y:number = 32
local PANEL_OFFSET_X:number = -5

local LENS_NAME = "ML_CITYOVERLAP"
local ML_LENS_LAYER = LensLayers.HEX_COLORING_APPEAL_LEVEL

-- ===========================================================================
--  Member Variables
-- ===========================================================================

local m_isOpen:boolean = false
local m_cityOverlapRange:number = 6
local m_currentCursorPlotID:number = -1

-- ===========================================================================
--  City Overlap Support functions
-- ===========================================================================

--[[
local function ShowCityOverlapLens()
    print("Showing " .. LENS_NAME)
    LuaEvents.MinimapPanel_SetActiveModLens(LENS_NAME)
    UILens.ToggleLayerOn(ML_LENS_LAYER)
end

local function ClearCityOverlapLens()
    print("Clearing " .. LENS_NAME)
    if UILens.IsLayerOn(ML_LENS_LAYER) then
        UILens.ToggleLayerOff(ML_LENS_LAYER);
    else
        print("Nothing to clear")
    end
    LuaEvents.MinimapPanel_SetActiveModLens("NONE");
end
]]

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

local function OnGetColorPlotTable(range, outsideBorder)
    if range == nil then
        range = 6
    end

    if outsideBorder == nil then
        outsideBorder = true -- no param is defaulted to show tiles outside border
    end

    local mapWidth, mapHeight = Map.GetGridSize();
    local localPlayer   :number = Game.GetLocalPlayer();
    local localPlayerVis:table = PlayersVisibility[localPlayer];

    local plotEntries       :table = {};
    local numCityEntries    :table = {};
    local localPlayerCities = Players[localPlayer]:GetCities()

    for i = 0, (mapWidth * mapHeight) - 1, 1 do
        local pPlot:table = Map.GetPlotByIndex(i);

        if localPlayerVis:IsRevealed(pPlot:GetX(), pPlot:GetY()) then
            if pPlot:GetOwner() == localPlayer or outsideBorder then
                local numCities = 0;
                for _, pCity in localPlayerCities:Members() do
                    if Map.GetPlotDistance(pPlot:GetX(), pPlot:GetY(), pCity:GetX(), pCity:GetY()) <= range then
                        numCities = numCities + 1;
                    end
                end

                if numCities > 0 then
                    numCities = clamp(numCities, 1, 8);
                    table.insert(plotEntries, i);
                    table.insert(numCityEntries, numCities);
                end
            end
        end
    end

    local colorPlot = {}
    for i = 1, 8 do
        colorPlot[UI.GetColorValue("COLOR_GRADIENT8_" .. tostring(i))] = {}
    end

    for i = 1, #plotEntries, 1 do
        local colorKey:string = "COLOR_GRADIENT8_" .. tostring(numCityEntries[i]);
        local color:number = UI.GetColorValue(colorKey);
        table.insert(colorPlot[color], plotEntries[i])
    end
    return colorPlot
end

local function GetRangeMouseTable(range)
    local plotId = UI.GetCursorPlotID();
    if (not Map.IsPlot(plotId)) then
        return;
    end

    local pPlot = Map.GetPlotByIndex(plotId)
    local localPlayer = Game.GetLocalPlayer()
    local localPlayerVis:table = PlayersVisibility[localPlayer]

    local cityPlotColor:number = UI.GetColorValue("COLOR_GRADIENT8_1")
    local normalColor:number = UI.GetColorValue("COLOR_GRADIENT8_3")
    local colorPlot = {}
    colorPlot[cityPlotColor] = {}
    colorPlot[normalColor] = {}

    for pAdjacencyPlot in PlotAreaSpiralIterator(pPlot, m_cityOverlapRange, SECTOR_NONE, DIRECTION_CLOCKWISE, DIRECTION_OUTWARDS, CENTRE_INCLUDE) do
        if localPlayerVis:IsRevealed(pAdjacencyPlot:GetX(), pAdjacencyPlot:GetY()) then
            if (pAdjacencyPlot:GetOwner() == localPlayer and pAdjacencyPlot:IsCity()) then
                table.insert(colorPlot[cityPlotColor], pAdjacencyPlot:GetIndex());
            else
                table.insert(colorPlot[normalColor], pAdjacencyPlot:GetIndex());
            end
        end
    end
    return colorPlot
end

-- ===========================================================================
--  UI Controls
-- ===========================================================================

local function RefreshCityOverlapLens()
    -- Assuming city overlap lens is already applied
    UILens.ClearLayerHexes(ML_LENS_LAYER)
    local colorPlot = nil
    if Controls.OverlapLensMouseRange:IsChecked() then
        colorPlot = GetRangeMouseTable(m_cityOverlapRange)
    else
        colorPlot = OnGetColorPlotTable(m_cityOverlapRange, Controls.ShowLensOutsideBorder:IsChecked())
    end

    -- Same from @SetModLensHexes in MinimapPanel.lua
    local localPlayer = Game.GetLocalPlayer()
    for color, plots in pairs(colorPlot) do
        if table.count(plots) > 0 then
            -- print("Showing " .. table.count(plots) .. " plots with color " .. color)
            UILens.SetLayerHexesColoredArea(ML_LENS_LAYER, localPlayer, plots, color);
        end
    end
end

local function IncreseOverlapRange()
    m_cityOverlapRange = m_cityOverlapRange + 1;
    Controls.OverlapRangeLabel:SetText(m_cityOverlapRange);
    RefreshCityOverlapLens();
end

local function DecreaseOverlapRange()
    if (m_cityOverlapRange > 0) then
        m_cityOverlapRange = m_cityOverlapRange - 1;
    end
    Controls.OverlapRangeLabel:SetText(m_cityOverlapRange);
    RefreshCityOverlapLens();
end

local function Open()
    Controls.OverlapLensOptionsPanel:SetHide(false)
    m_isOpen = true

    -- Reset settings
    m_cityOverlapRange = 6
    Controls.OverlapRangeLabel:SetText(m_cityOverlapRange);
    Controls.OverlapLensMouseRange:SetCheck(false);
    Controls.OverlapLensMouseNone:SetCheck(true);
    Controls.ShowLensOutsideBorder:SetCheck(true);
end

local function Close()
    Controls.OverlapLensOptionsPanel:SetHide(true)
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
    Controls.OverlapLensOptionsPanel:SetOffsetY(offsets.Y + PANEL_OFFSET_Y)
    Controls.OverlapLensOptionsPanel:SetOffsetX(offsets.X + PANEL_OFFSET_X)
end

-- ===========================================================================
--  Game Engine Events
-- ===========================================================================

local function OnInputHandler(pInputStruct:table)
    -- Skip all if panel is hidden
    if m_isOpen then
        -- Get plot under cursor
        local plotId = UI.GetCursorPlotID();
        if (not Map.IsPlot(plotId)) then
            return false
        end

        -- If the cursor plot has not changed don't refresh
        if (m_CurrentCursorPlotID == plotId) then
            return false
        end
        m_CurrentCursorPlotID = plotId

        -- Handler for City Overlap lens
        local lens = {}
        LuaEvents.MinimapPanel_GetActiveModLens(lens)
        if lens[1] == LENS_NAME then
            if Controls.OverlapLensMouseRange:IsChecked() then
                RefreshCityOverlapLens()
            end
        end
    end
    return false
end

local function ChangeContainer()
    -- Change the parent to /InGame/HUD container so that it hides correcty during diplomacy, etc
    local hudContainer = ContextPtr:LookUpControl("/InGame/HUD")
    Controls.OverlapLensOptionsPanel:ChangeParent(hudContainer)
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
        hudContainer:DestroyChild(Controls.OverlapLensOptionsPanel)
    end
end

-- ===========================================================================
--  Init
-- ===========================================================================

-- minimappanel.lua
local CityOverlapLensEntry = {
    LensButtonText = "LOC_HUD_CITYOVERLAP_LENS",
    LensButtonTooltip = "LOC_HUD_CITYOVERLAP_LENS_TOOLTIP",
    Initialize = nil,
    OnToggle = TogglePanel,
    GetColorPlotTable = OnGetColorPlotTable
}

-- modallenspanel.lua
local CityOverlapLensModalPanelEntry = {}
CityOverlapLensModalPanelEntry.Legend = {}
CityOverlapLensModalPanelEntry.LensTextKey = "LOC_HUD_CITYOVERLAP_LENS"
for i = 1, 8 do
    local params:table = {
        "LOC_WORLDBUILDER_TAB_CITIES",
        UI.GetColorValue("COLOR_GRADIENT8_" .. tostring(i)),
        nil,  -- bonus icon
        "+ " .. tostring(i)  -- bonus value
    }
    table.insert(CityOverlapLensModalPanelEntry.Legend, params)
end

-- Don't import this into g_ModLenses, since this for the UI (ie not lens)
local function Initialize()
    print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
    print("          City Overlap Panel")
    print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
    Close()
    OnReoffsetPanel()

    ContextPtr:SetInitHandler( OnInit )
    ContextPtr:SetShutdown( OnShutdown )
    ContextPtr:SetInputHandler( OnInputHandler, true );

    Events.LoadScreenClose.Add(
        function()
            ChangeContainer()
            LuaEvents.MinimapPanel_AddLensEntry(LENS_NAME, CityOverlapLensEntry);
            LuaEvents.ModalLensPanel_AddLensEntry(LENS_NAME, CityOverlapLensModalPanelEntry);
        end
    )

    -- City Overlap Lens Setting
    Controls.OverlapRangeUp:RegisterCallback( Mouse.eLClick, IncreseOverlapRange );
    Controls.OverlapRangeDown:RegisterCallback( Mouse.eLClick, DecreaseOverlapRange );
    Controls.OverlapLensMouseNone:RegisterCallback( Mouse.eLClick, RefreshCityOverlapLens );
    Controls.OverlapLensMouseRange:RegisterCallback( Mouse.eLClick, RefreshCityOverlapLens );
    Controls.ShowLensOutsideBorder:RegisterCallback( Mouse.eLClick, RefreshCityOverlapLens );

    LuaEvents.ModLens_ReoffsetPanels.Add( OnReoffsetPanel );
    LuaEvents.ML_CloseLensPanels.Add( Close );
end

Initialize()
