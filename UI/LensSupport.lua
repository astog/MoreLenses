local CITY_WORK_RANGE:number = 3;


function plotHasCorrectImprovement(plot)
    local plotIndex = plot:GetIndex()
    local playerID = Game.GetLocalPlayer()

    -- If the plot has a resource, and the player has discovered it, get the improvement specific to that
    if playerHasDiscoveredResource(playerID, plotIndex) then
        local resourceInfo = GameInfo.Resources[plot:GetResourceType()]
        if resourceInfo ~= nil then
            local improvementType;
            for validResourceInfo in GameInfo.Improvement_ValidResources() do
                if validResourceInfo ~= nil and validResourceInfo.ResourceType == resourceInfo.ResourceType then
                    improvementType = validResourceInfo.ImprovementType;
                    break
                end
            end

            if improvementType ~= nil and GameInfo.Improvements[improvementType] ~= nil then
                local improvementID = GameInfo.Improvements[improvementType].RowId - 1;
                if plot:GetImprovementType() == improvementID then
                    return true
                end
            end
        end
    else
        -- This plot has either no resource or a undiscovered resource
        -- hence assuming correct resource type
        return true
    end

    return false
end

function plotWithinWorkingRange(playerID, plotIndex)
    local localPlayerCities = Players[playerID]:GetCities()
    local pPlot = Map.GetPlotByIndex(plotIndex)
    local plotX = pPlot:GetX()
    local plotY = pPlot:GetY()

    for _, pCity in localPlayerCities:Members() do
        if Map.GetPlotDistance(plotX, plotY, pCity:GetX(), pCity:GetY()) <= CITY_WORK_RANGE then
            return true
        end
    end
    return false
end

function plotHasImprovement(plot)
    return plot:GetImprovementType() ~= -1;
end

function plotHasResource(plot)
    return plot:GetResourceType() ~= -1;
end

function plotHasFeature(plot)
    return plot:GetFeatureType() ~= -1;
end

function plotHasRemovableFeature(plot)
    local featureInfo = GameInfo.Features[plot:GetFeatureType()];
    if featureInfo ~= nil and featureInfo.Removable then
        return true;
    end
    return false;
end

function plotHasImprovableHill(plot)
    local terrainInfo = GameInfo.Terrains[plot:GetTerrainType()];
    local improvInfo = GameInfo.Improvements["IMPROVEMENT_MINE"];
    local playerID = Game.GetLocalPlayer()

    if (terrainInfo ~= nil and terrainInfo.Hills
            and playerCanHave(playerID, improvInfo)) then
        return true
    end
    return false;
end

function plotHasWonder(plot)
    return plot:GetWonderType() ~= -1;
end

function plotHasDistrict(plot)
    return plot:GetDistrictType() ~= -1;
end

function plotHasNaturalWonder(plot)
    local featureInfo = GameInfo.Features[plot:GetFeatureType()];
    if featureInfo ~= nil and featureInfo.NaturalWonder then
        return true
    end
    return false
end

function plotHasImprovableWonder(plot)
    -- List of wonders that can have an improvement on them.
    local permitWonderList = {
        "FEATURE_CLIFFS_DOVER"
    }

    local featureInfo = GameInfo.Features[plot:GetFeatureType()];
    if featureInfo ~= nil then
        for i, wonderType in ipairs(permitWonderList) do
            if featureInfo.FeatureType == wonderType then
                return true
            end
        end
    end
    return false
end

function IsAdjYieldWonder(featureInfo)
    -- List any wonders here that provide yield bonuses, but not mentioned in Features.xml
    local specialWonderList = {
        "FEATURE_TORRES_DEL_PAINE"
    }

    if featureInfo ~= nil and featureInfo.NaturalWonder then
        for adjYieldInfo in GameInfo.Feature_AdjacentYields() do
            if adjYieldInfo ~= nil and adjYieldInfo.FeatureType == featureInfo.FeatureType then
                return true
            end
        end

        for i, featureType in ipairs(specialWonderList) do
            if featureType == featureInfo.FeatureType then
                return true
            end
        end
    end
    return false
end

function plotNextToBuffingWonder(plot)
    for pPlot in PlotRingIterator(plot, 1, SECTOR_NONE, DIRECTION_CLOCKWISE) do
        local featureInfo = GameInfo.Features[pPlot:GetFeatureType()]
        if IsAdjYieldWonder(featureInfo) then
            return true
        end
    end
    return false
end

function plotHasRecomFeature(plot)
    local playerID = Game.GetLocalPlayer()
    local featureInfo = GameInfo.Features[plot:GetFeatureType()]
    local farmImprovInfo = GameInfo.Improvements["IMPROVEMENT_FARM"]
    local lumberImprovInfo = GameInfo.Improvements["IMPROVEMENT_LUMBER_MILL"]

    if featureInfo ~= nil then

        -- 1. Is it a floodplain?
        if featureInfo.FeatureType == "FEATURE_FLOODPLAINS" and
                playerCanHave(playerID, farmImprovInfo) then
            return true
        end

        -- 2. Is it a forest next to a river?
        if featureInfo.FeatureType == "FEATURE_FOREST" and plot:IsRiver() and
                playerCanHave(playerID, lumberImprovInfo) then
            return true
        end

        -- 3. Is it a tile next to buffing wonder?
        if plotNextToBuffingWonder(plot) then
            return true
        end

        -- 4. Is it wonder, that can have an improvement?
        if plotHasImprovableWonder(plot) then
            if featureInfo.FeatureType == "FEATURE_FOREST" and
                    playerCanHave(playerID, lumberImprovInfo) then
                return true
            end

            if plotCanHaveFarm(plot) then
                return true
            end
        end
    end
    return false
end

function plotHasAnitquitySite(plot)
    local resourceInfo = GameInfo.Resources[plot:GetResourceType()];
    if resourceInfo ~= nil and resourceInfo.ResourceType == "RESOURCE_ANTIQUITY_SITE" then
        return true;
    end
    return false
end

function plotHasShipwreck(plot)
    local resourceInfo = GameInfo.Resources[plot:GetResourceType()];
    if resourceInfo ~= nil and resourceInfo.ResourceType == "RESOURCE_SHIPWRECK" then
        return true;
    end
    return false
end

function plotHasBarbCamp(plot)
    local improvementInfo = GameInfo.Improvements[plot:GetImprovementType()];
    if improvementInfo ~= nil and improvementInfo.ImprovementType == "IMPROVEMENT_BARBARIAN_CAMP" then
        return true;
    end
    return false;
end

-- TODO: Check for valid feature
function plotCanHaveFarm(plot)
    local farmImprovInfo = GameInfo.Improvements["IMPROVEMENT_FARM"]
    if not playerCanHave(playerID, farmImprovInfo) then
        return false;
    end

    local validTerrain:boolean = false;
    local playerID = Game.GetLocalPlayer()

    for improvTerrainInfo in GameInfo.Improvement_ValidTerrains() do
        if (improvTerrainInfo.ImprovementType == "IMPROVEMENT_FARM"
                and playerCanHave(playerID, improvTerrainInfo)) then
            return true;
        end
    end
    return false
end

function plotHasGoodyHut(plot)
    local improvementInfo = GameInfo.Improvements[plot:GetImprovementType()];
    if improvementInfo ~= nil and improvementInfo.ImprovementType == "IMPROVEMENT_GOODY_HUT" then
        return true;
    end
    return false;
end

function plotResourceImprovable(plot)
    local plotIndex = plot:GetIndex()
    local playerID = Game.GetLocalPlayer()

    -- If the plot has a resource, and the player has discovered it, get the improvement specific to that
    if playerHasDiscoveredResource(playerID, plotIndex) then
        local resourceInfo = GameInfo.Resources[plot:GetResourceType()]
        if resourceInfo ~= nil then
            local improvementType;
            for validResourceInfo in GameInfo.Improvement_ValidResources() do
                if validResourceInfo ~= nil and validResourceInfo.ResourceType == resourceInfo.ResourceType then
                    improvementType = validResourceInfo.ImprovementType;
                    break
                end
            end

            if improvementType ~= nil then
                local improvementInfo = GameInfo.Improvements[improvementType];
                -- print("Plot " .. plotIndex .. " possibly can have " .. improvementType)
                return playerCanHave(playerID, improvementInfo);
            end
        end
    end

    return false
end

function playerCanRemoveFeature(playerID, plotIndex)
    local pPlot = Map.GetPlotByIndex(plotIndex)
    local pPlayer = Players[playerID];
    local featureInfo = GameInfo.Features[pPlot:GetFeatureType()]

    if featureInfo ~= nil then
        if not featureInfo.Removable then return false; end

        -- Check for remove tech
        if featureInfo.RemoveTech ~= nil then
            local tech = GameInfo.Technologies[featureInfo.RemoveTech]
            local playerTech:table = pPlayer:GetTechs();
            if tech ~= nil  then
                return playerTech:HasTech(tech.Index);
            else
                return false;
            end
        else
            return true;
        end
    end

    return false;
end

function BuilderCanConstruct(improvementInfo)
    for improvementBuildUnits in GameInfo.Improvement_ValidBuildUnits() do
        if improvementBuildUnits ~= nil and improvementBuildUnits.ImprovementType == improvementInfo.ImprovementType and
            improvementBuildUnits.UnitType == "UNIT_BUILDER" then
                return true
        end
    end

    return false
end

function plotCanHaveImprovement(playerID, plotIndex)
    local pPlot = Map.GetPlotByIndex(plotIndex)
    local pPlayer = Players[playerID]

    -- Handler for a generic tile
    for improvementInfo in GameInfo.Improvements() do
        if improvementInfo ~= nil and improvementInfo.Buildable then

            -- Does the player the prereq techs and civis
            if BuilderCanConstruct(improvementInfo) and playerCanHave(playerID, improvementInfo) then
                local improvementValid:boolean = false;

                -- Check for valid feature
                for validFeatureInfo in GameInfo.Improvement_ValidFeatures() do
                    if validFeatureInfo ~= nil and validFeatureInfo.ImprovementType == improvementInfo.ImprovementType then
                        -- Does this plot have this feature?
                        local featureInfo = GameInfo.Features[validFeatureInfo.FeatureType]
                        if featureInfo ~= nil and pPlot:GetFeatureType() == featureInfo.Index then
                            if playerCanHave(playerID, featureInfo) and playerCanHave(playerID, validFeatureInfo) then
                                print("(feature) Plot " .. pPlot:GetIndex() .. " can have " .. improvementInfo.ImprovementType)
                                improvementValid = true;
                                break;
                            end
                        end
                    end
                end

                -- Check for valid terrain
                if not improvementValid then
                    for validTerrainInfo in GameInfo.Improvement_ValidTerrains() do
                        if validTerrainInfo ~= nil and validTerrainInfo.ImprovementType == improvementInfo.ImprovementType then
                            -- Does this plot have this terrain?
                            local terrainInfo = GameInfo.Terrains[validTerrainInfo.TerrainType]
                            if terrainInfo ~= nil and pPlot:GetTerrainType() == terrainInfo.Index then
                                if playerCanHave(playerID, terrainInfo) and playerCanHave(playerID, validTerrainInfo)  then
                                    print("(terrain) Plot " .. pPlot:GetIndex() .. " can have " .. improvementInfo.ImprovementType)
                                    improvementValid = true;
                                    break;
                                end
                            end
                        end
                    end
                end

                -- Check for valid resource
                if not improvementValid then
                    for validResourceInfo in GameInfo.Improvement_ValidResources() do
                        if validResourceInfo ~= nil and validResourceInfo.ImprovementType == improvementInfo.ImprovementType then
                            -- Does this plot have this terrain?
                            local resourceInfo = GameInfo.Resources[validResourceInfo.ResourceType]
                            if resourceInfo ~= nil and pPlot:GetResourceType() == resourceInfo.Index then
                                if playerCanHave(playerID, resourceInfo) and playerCanHave(playerID, validResourceInfo)  then
                                    print("(resource) Plot " .. pPlot:GetIndex() .. " can have " .. improvementInfo.ImprovementType)
                                    improvementValid = true;
                                    break;
                                end
                            end
                        end
                    end
                end

                -- Special check for coastal requirement
                if improvementInfo.Coast and (not pPlot:IsCoastalLand()) then
                    print(plotIndex .. " plot is not coastal")
                    improvementValid = false;
                end

                if improvementValid then
                    return true
                end
            end
        end
    end

    return false;
end

-- General function to check if the player has xmlEntry.PrereqTech and xmlEntry.PrereqTech
-- Also handles unique traits, and bonuses received from city states
function playerCanHave(playerID, xmlEntry)
    if xmlEntry == nil then return false; end;

    local pPlayer = Players[playerID]
    if xmlEntry.PrereqTech ~= nil then
        local playerTech:table = pPlayer:GetTechs();
        local tech = GameInfo.Technologies[xmlEntry.PrereqTech]
        if tech ~= nil and (not playerTech:HasTech(tech.Index)) then
            -- print("Player does not have " .. tech.TechnologyType)
            return false;
        end
    end

    -- Does the player have the prereq civic if one exists
    if xmlEntry.PrereqCivic ~= nil then
        local playerCulture = pPlayer:GetCulture();
        local civic = GameInfo.Civics[xmlEntry.PrereqCivic]
        if civic ~= nil and (not playerCulture:HasCivic(civic.Index)) then
            -- print("Player does not have " .. civic.CivicType)
            return false;
        end
    end

    -- Is it a Unique thing to a player/civ
    if xmlEntry.TraitType ~= nil then
        -- print(xmlEntry.TraitType)
        local civilizationType = PlayerConfigurations[playerID]:GetCivilizationTypeName()
        local leaderType = PlayerConfigurations[playerID]:GetLeaderTypeName()
        local isSuzerain:boolean = false;

        -- Special handler for city state traits.
        local spitResult = Split(xmlEntry.TraitType, "_");
        if spitResult[1] == "MINOR" then
            local traitLeaderType;
            for traitInfo in GameInfo.LeaderTraits() do
                if traitInfo.TraitType == xmlEntry.TraitType then
                    traitLeaderType = traitInfo.LeaderType
                    break
                end
            end

            if traitLeaderType ~= nil then
                -- print("traitLeaderType " .. traitLeaderType)
                local traitLeaderID;

                -- See if this city state is present in the game
                for minorID in ipairs(PlayerManager.GetAliveMinorIDs()) do
                    local minorLeaderType = PlayerConfigurations[minorID]:GetLeaderTypeName()
                    if minorLeaderType == traitLeaderType then
                        traitLeaderID = minorID;
                        break;
                    end
                end

                if traitLeaderID ~= nil then
                    -- Found the player in the game. Is the suzerain the player
                    if playerID ~= Players[traitLeaderID]:GetInfluence():GetSuzerain() then
                        -- print("Player is not the suzerain of " .. minorLeaderType)
                        return false
                    else
                        return true;
                    end
                else
                    -- print(traitLeaderType .. " is not in this game")
                    return false;
                end
            end
        end

        for traitInfo in GameInfo.CivilizationTraits() do
            if traitInfo.TraitType == xmlEntry.TraitType and
                    traitInfo.CivilizationType ~= nil and
                    civilizationType ~= traitInfo.CivilizationType then
                -- print(civilizationType .. " ~= " .. traitInfo.CivilizationType)
                return false
            end
        end

        for traitInfo in GameInfo.LeaderTraits() do
            if traitInfo.TraitType == xmlEntry.TraitType and
                    traitInfo.LeaderType ~= nil and
                    leaderType ~= traitInfo.LeaderType then
                -- print(civilizationType .. " ~= " .. traitInfo.LeaderType)
                return false
            end
        end

    end

    return true;
end

function playerHasBuilderWonderModifier(playerID)
    return playerHasModifier(playerID, "MODIFIER_PLAYER_ADJUST_UNIT_WONDER_PERCENT");
end

function playerHasBuilderDistrictModifier(playerID)
    return playerHasModifier(playerID, "MODIFIER_PLAYER_ADJUST_UNIT_DISTRICT_PERCENT");
end

function playerHasModifier(playerID, modifierType)
    -- Get civ, and leader
    local civTypeName = PlayerConfigurations[playerID]:GetCivilizationTypeName();
    local leaderTypeName = PlayerConfigurations[playerID]:GetLeaderTypeName();

    local civUA = GetCivilizationUniqueTraits(civTypeName);
    local leaderUA = GetLeaderUniqueTraits(leaderTypeName);

    for _, item in ipairs(civUA) do
        local traitType = civUA[1].TraitType
        -- print("Trait type: " .. traitType)

        -- Find the modifier ID
        local modifierID;
        for row in GameInfo.TraitModifiers() do
            if row.TraitType == traitType then
                local modifierID = row.ModifierId;

                -- Find the matching modifier type
                if modifierID ~= nil then
                    -- print("Modifier ID: " .. modifierID)
                    for row in GameInfo.Modifiers() do
                        if row.ModifierId == modifierID and row.ModifierType == modifierType then
                            -- print("Player has a modifier for district")
                            return true;
                        end
                    end
                end
            end
        end
    end

    for _, item in ipairs(leaderUA) do
        local traitType = leaderUA[1].TraitType
        -- print("Trait type: " .. traitType)

        -- Find the modifier ID
        local modifierID;
        for row in GameInfo.TraitModifiers() do
            if row.TraitType == traitType then
                local modifierID = row.ModifierId;

                -- Find the matching modifier type
                if modifierID ~= nil then
                    -- print("Modifier ID: " .. modifierID)
                    for row in GameInfo.Modifiers() do
                        if row.ModifierId == modifierID and row.ModifierType == modifierType then
                            -- print("Player has a modifier for district")
                            return true;
                        end
                    end
                end
            end
        end
    end
end

-- Uses same logic as the icon manager (returns true, if the resource icon is being displayed on the map)
function playerHasDiscoveredResource(playerID, plotIndex)
    local eObserverID = Game.GetLocalObserver();
    local pLocalPlayerVis = PlayerVisibilityManager.GetPlayerVisibility(eObserverID);

    local pPlot = Map.GetPlotByIndex(plotIndex);
    -- Have a Resource?
    local eResource = pLocalPlayerVis:GetLayerValue(VisibilityLayerTypes.RESOURCES, plotIndex);
    local bHideResource = ( pPlot ~= nil and ( pPlot:GetDistrictType() > 0 or pPlot:IsCity() ) );
    if (eResource ~= nil and eResource ~= -1 and not bHideResource ) then
        return true;
    end

    return false;
end

-- Tells if the district on this plot is complete or not
function districtComplete(playerID, plotIndex)
    local pPlayer = Players[playerID];
    local pPlot = Map.GetPlotByIndex(plotIndex);
    local districtID = pPlot:GetDistrictID();

    if districtID ~= nil and districtID >= 0 then
        local pDistrict = pPlayer:GetDistricts():FindID(districtID);
        if pDistrict ~= nil then
            return pDistrict:IsComplete()
        end
    end

    return false;
end

function isAncientClassicalWonder(wonderTypeID)
    -- print("Checking wonder " .. wonderTypeID .. " if ancient or classical")

    for row in GameInfo.Buildings() do
        if row.Index == wonderTypeID then
            -- Make hash, and get era
            if row.PrereqTech ~= nil then
                prereqTechHash = DB.MakeHash(row.PrereqTech);
                eraType = GameInfo.Technologies[prereqTechHash].EraType;
            elseif row.PrereqCivic ~= nil then
                prereqCivicHash = DB.MakeHash(row.PrereqCivic);
                eraType = GameInfo.Civics[prereqCivicHash].EraType;
            else
                -- Wonder has no prereq
                return true;
            end

            -- print("Era = " .. eraType);

            if eraType == nil then
                -- print("Could not find era for wonder " .. wonderTypeID)
                return true
            elseif eraType == "ERA_ANCIENT" or eraType == "ERA_CLASSICAL" then
                return true;
            end
        end
    end

    return false;
end

function GetUnitType( playerID: number, unitID : number )
    if( playerID == Game.GetLocalPlayer() ) then
        local pPlayer   :table = Players[playerID];
        local pUnit     :table = pPlayer:GetUnits():FindID(unitID);
        if pUnit ~= nil then
            return GameInfo.Units[pUnit:GetUnitType()].UnitType;
        end
    end
    return nil;
end

function has_value (tab, val)
    for _, value in ipairs (tab) do
        if value == val then
            return true
        end
    end
    return false
end

function has_rInfo (tab, val)
    for _, value in ipairs (tab) do
        if value.ResourceType == val then
            return true
        end
    end
    return false
end

function find_and_remove(tab, val)
    for i, item in ipairs(tab) do
        if item == val then
            table.remove(tab, i);
            return
        end
    end
end

function ndup_insert(tab, val)
    if not has_value(tab, val) then
        table.insert(tab, val);
    end
end

function get_common_values(tab1, tab2)
    local common_table = {}
    for _, value1 in ipairs (tab1) do
        for _, value2 in ipairs (tab2) do
            if value1 == value2 then
                table.insert(common_table, value1)
            end
        end
    end
    return common_table
end

--------------------------------------------
-- Plot Iterator, Author: whoward69; URL: https://forums.civfanatics.com/threads/border-and-area-plot-iterators.474634/
    -- convert funcs odd-r offset to axial. URL: http://www.redblobgames.com/grids/hexagons/
    -- here grid == offset; hex == axial
    function ToHexFromGrid(grid)
        local hex = {
            x = grid.x - (grid.y - (grid.y % 2)) / 2;
            y = grid.y;
        }
        return hex
    end
    function ToGridFromHex(hex_x, hex_y)
        local grid = {
            x = hex_x + (hex_y - (hex_y % 2)) / 2;
            y = hex_y;
        }
        return grid.x, grid.y
    end

    SECTOR_NONE = nil
    SECTOR_NORTH = 1
    SECTOR_NORTHEAST = 2
    SECTOR_SOUTHEAST = 3
    SECTOR_SOUTH = 4
    SECTOR_SOUTHWEST = 5
    SECTOR_NORTHWEST = 6

    DIRECTION_CLOCKWISE = false
    DIRECTION_ANTICLOCKWISE = true

    DIRECTION_OUTWARDS = false
    DIRECTION_INWARDS = true

    CENTRE_INCLUDE = true
    CENTRE_EXCLUDE = false

    function PlotRingIterator(pPlot, r, sector, anticlock)
        -- print(string.format("PlotRingIterator((%i, %i), r=%i, s=%i, d=%s)", pPlot:GetX(), pPlot:GetY(), r, (sector or SECTOR_NORTH), (anticlock and "rev" or "fwd")))
        -- The important thing to remember with hex-coordinates is that x+y+z = 0
        -- so we never actually need to store z as we can always calculate it as -(x+y)
        -- See http://keekerdc.com/2011/03/hexagon-grids-coordinate-systems-and-distance-calculations/

        if (pPlot ~= nil and r > 0) then
            local hex = ToHexFromGrid({x=pPlot:GetX(), y=pPlot:GetY()})
            local x, y = hex.x, hex.y

            -- Along the North edge of the hex (x-r, y+r, z) to (x, y+r, z-r)
            local function north(x, y, r, i) return {x=x-r+i, y=y+r} end
            -- Along the North-East edge (x, y+r, z-r) to (x+r, y, z-r)
            local function northeast(x, y, r, i) return {x=x+i, y=y+r-i} end
            -- Along the South-East edge (x+r, y, z-r) to (x+r, y-r, z)
            local function southeast(x, y, r, i) return {x=x+r, y=y-i} end
            -- Along the South edge (x+r, y-r, z) to (x, y-r, z+r)
            local function south(x, y, r, i) return {x=x+r-i, y=y-r} end
            -- Along the South-West edge (x, y-r, z+r) to (x-r, y, z+r)
            local function southwest(x, y, r, i) return {x=x-i, y=y-r+i} end
            -- Along the North-West edge (x-r, y, z+r) to (x-r, y+r, z)
            local function northwest(x, y, r, i) return {x=x-r, y=y+i} end

            local side = {north, northeast, southeast, south, southwest, northwest}
            if (sector) then
                for i=(anticlock and 1 or 2), sector, 1 do
                    table.insert(side, table.remove(side, 1))
                end
            end

            -- This coroutine walks the edges of the hex centered on pPlot at radius r
            local next = coroutine.create(function ()
                if (anticlock) then
                    for s=6, 1, -1 do
                        for i=r, 1, -1 do
                            coroutine.yield(side[s](x, y, r, i))
                        end
                    end
                else
                    for s=1, 6, 1 do
                        for i=0, r-1, 1 do
                            coroutine.yield(side[s](x, y, r, i))
                        end
                    end
                end

                return nil
            end)

            -- This function returns the next edge plot in the sequence, ignoring those that fall off the edges of the map
            return function ()
                local pEdgePlot = nil
                local success, hex = coroutine.resume(next)
                -- if (hex ~= nil) then print(string.format("hex(%i, %i, %i)", hex.x, hex.y, -1 * (hex.x+hex.y))) else print("hex(nil)") end

                while (success and hex ~= nil and pEdgePlot == nil) do
                    pEdgePlot = Map.GetPlot(ToGridFromHex(hex.x, hex.y))
                    if (pEdgePlot == nil) then success, hex = coroutine.resume(next) end
                end

                return success and pEdgePlot or nil
            end
        else
            -- Iterators have to return a function, so return a function that returns nil
            return function () return nil end
        end
    end


    function PlotAreaSpiralIterator(pPlot, r, sector, anticlock, inwards, centre)
        -- print(string.format("PlotAreaSpiralIterator((%i, %i), r=%i, s=%i, d=%s, w=%s, c=%s)", pPlot:GetX(), pPlot:GetY(), r, (sector or SECTOR_NORTH), (anticlock and "rev" or "fwd"), (inwards and "in" or "out"), (centre and "yes" or "no")))
        -- This coroutine walks each ring in sequence
        local next = coroutine.create(function ()
            if (centre and not inwards) then
                coroutine.yield(pPlot)
            end

            if (inwards) then
                for i=r, 1, -1 do
                    for pEdgePlot in PlotRingIterator(pPlot, i, sector, anticlock) do
                        coroutine.yield(pEdgePlot)
                    end
                end
            else
                for i=1, r, 1 do
                    for pEdgePlot in PlotRingIterator(pPlot, i, sector, anticlock) do
                        coroutine.yield(pEdgePlot)
                    end
                end
            end

            if (centre and inwards) then
                coroutine.yield(pPlot)
            end

            return nil
        end)

        -- This function returns the next plot in the sequence
        return function ()
            local success, pAreaPlot = coroutine.resume(next)
            return success and pAreaPlot or nil
        end
    end
-- End of iterator code --------------------
