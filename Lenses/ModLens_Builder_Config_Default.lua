include("LensSupport")

-- ===========================================================================
-- Builder Lens Support
-- ===========================================================================

local function isAncientClassicalWonder(wonderTypeID:number)
    for row in GameInfo.Buildings() do
        if row.Index == wonderTypeID then
            -- Make hash, and get era
            if row.PrereqTech ~= nil then
                prereqTechHash = DB.MakeHash(row.PrereqTech)
                eraType = GameInfo.Technologies[prereqTechHash].EraType
            elseif row.PrereqCivic ~= nil then
                prereqCivicHash = DB.MakeHash(row.PrereqCivic)
                eraType = GameInfo.Civics[prereqCivicHash].EraType
            else
                -- Wonder has no prereq
                return true
            end

            if eraType == nil then
                return true
            elseif eraType == "ERA_ANCIENT" or eraType == "ERA_CLASSICAL" then
                return true
            end
        end
    end
    return false
end

local function BuilderCanConstruct(improvementInfo)
    for improvementBuildUnits in GameInfo.Improvement_ValidBuildUnits() do
        if improvementBuildUnits ~= nil and improvementBuildUnits.ImprovementType == improvementInfo.ImprovementType and
            improvementBuildUnits.UnitType == "UNIT_BUILDER" then
                return true
        end
    end
    return false
end

local function playerCanRemoveFeature(pPlayer:table, pPlot:table)
    local featureInfo = GameInfo.Features[pPlot:GetFeatureType()]
    if featureInfo ~= nil then
        if not featureInfo.Removable then return false end

        -- Check for remove tech
        if featureInfo.RemoveTech ~= nil then
            local tech = GameInfo.Technologies[featureInfo.RemoveTech]
            local playerTech:table = pPlayer:GetTechs()
            if tech ~= nil  then
                return playerTech:HasTech(tech.Index)
            else
                return false
            end
        else
            return true
        end
    end
    return false
end

local function playerCanImproveFeature(pPlayer:table, pPlot:table)
    local featureInfo = GameInfo.Features[pPlot:GetFeatureType()]
    if featureInfo ~= nil then
        for validFeatureInfo in GameInfo.Improvement_ValidFeatures() do
            if validFeatureInfo ~= nil and validFeatureInfo.FeatureType == featureInfo.FeatureType then
                improvementType = validFeatureInfo.ImprovementType
                improvementInfo = GameInfo.Improvements[improvementType]
                if improvementInfo ~= nil and playerCanHave(pPlayer, improvementInfo) then
                        return true
                end
            end
        end
    end
end


-- Incomplete handler to check if that plot has a buildable improvement
-- FIXME: Does not check requirements properly so some improvements pass through, example: fishery
local function plotCanHaveImprovement(pPlayer:table, pPlot:table)
    for improvementInfo in GameInfo.Improvements() do
        if improvementInfo ~= nil and improvementInfo.Buildable then

            -- Is it an improvement buildable by a builder
            -- Does the player the prereq techs and civis
            if BuilderCanConstruct(improvementInfo) and playerCanHave(pPlayer, improvementInfo) then
                local improvementValid:boolean = false

                -- Check for valid feature
                for validFeatureInfo in GameInfo.Improvement_ValidFeatures() do
                    if validFeatureInfo ~= nil and validFeatureInfo.ImprovementType == improvementInfo.ImprovementType then
                        -- Does this plot have this feature?
                        local featureInfo = GameInfo.Features[validFeatureInfo.FeatureType]
                        if featureInfo ~= nil and pPlot:GetFeatureType() == featureInfo.Index then
                            if playerCanHave(pPlayer, featureInfo) and playerCanHave(pPlayer, validFeatureInfo) then
                                print("(feature) Plot " .. pPlot:GetIndex() .. " can have " .. improvementInfo.ImprovementType)
                                improvementValid = true
                                break
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
                                if playerCanHave(pPlayer, terrainInfo) and playerCanHave(pPlayer, validTerrainInfo)  then
                                    print("(terrain) Plot " .. pPlot:GetIndex() .. " can have " .. improvementInfo.ImprovementType)
                                    improvementValid = true
                                    break
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
                                if playerCanHave(pPlayer, resourceInfo) and playerCanHave(pPlayer, validResourceInfo)  then
                                    print("(resource) Plot " .. pPlot:GetIndex() .. " can have " .. improvementInfo.ImprovementType)
                                    improvementValid = true
                                    break
                                end
                            end
                        end
                    end
                end

                -- Special check for coastal requirement
                if improvementInfo.Coast and (not pPlot:IsCoastalLand()) then
                    print(plotIndex .. " plot is not coastal")
                    improvementValid = false
                end

                if improvementValid then
                    return true
                end
            end
        end
    end
    return false
end

local function plotHasRemovableFeature(pPlot:table)
    local featureInfo = GameInfo.Features[pPlot:GetFeatureType()]
    if featureInfo ~= nil and featureInfo.Removable then
        return true
    end
    return false
end

local function IsAdjYieldWonder(featureInfo)
    -- List any wonders here that provide yield bonuses, but not mentioned in Features.xml
    local specialWonderList = {
        "FEATURE_TORRES_DEL_PAINE"
    }

    if featureInfo ~= nil and featureInfo.NaturalWonder then
        for adjYieldInfo in GameInfo.Feature_AdjacentYields() do
            if adjYieldInfo ~= nil and adjYieldInfo.FeatureType == featureInfo.FeatureType
                    and adjYieldInfo.YieldChange > 0 then
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

local function plotNextToBuffingWonder(pPlot:table)
    for pAdjPlot in PlotRingIterator(pPlot, 1, SECTOR_NONE, DIRECTION_CLOCKWISE) do
        local featureInfo = GameInfo.Features[pAdjPlot:GetFeatureType()]
        if IsAdjYieldWonder(featureInfo) then
            return true
        end
    end
    return false
end

-- Checks if the resource at this plot has an improvment for it, and the player has tech/civic to build it
local function plotResourceImprovable(pPlayer:table, pPlot:table)
    local resourceInfo = GameInfo.Resources[pPlot:GetResourceType()]
    if resourceInfo ~= nil then
        local improvementType = nil
        for validResourceInfo in GameInfo.Improvement_ValidResources() do
            if validResourceInfo ~= nil and validResourceInfo.ResourceType == resourceInfo.ResourceType then
                improvementType = validResourceInfo.ImprovementType
                if improvementType ~= nil then
                    local improvementInfo = GameInfo.Improvements[improvementType]
                    if playerCanHave(pPlayer, improvementInfo) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function plotHasCorrectImprovement(pPlot:table)
    local resourceInfo = GameInfo.Resources[pPlot:GetResourceType()]
    if resourceInfo ~= nil then
        for validResourceInfo in GameInfo.Improvement_ValidResources() do
            if validResourceInfo ~= nil and validResourceInfo.ResourceType == resourceInfo.ResourceType then
                local improvementType = validResourceInfo.ImprovementType
                if improvementType ~= nil and GameInfo.Improvements[improvementType] ~= nil then
                    local improvementID = GameInfo.Improvements[improvementType].RowId - 1
                    if pPlot:GetImprovementType() == improvementID then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function playerHasBuilderWonderModifier(playerID)
    return playerHasModifier(playerID, "MODIFIER_PLAYER_ADJUST_UNIT_WONDER_PERCENT")
end

local function playerHasBuilderDistrictModifier(playerID)
    return playerHasModifier(playerID, "MODIFIER_PLAYER_ADJUST_UNIT_DISTRICT_PERCENT")
end

-- ===========================================================================
-- Add rules for builder lens
-- ===========================================================================

local localPlayer = Game.GetLocalPlayer()
local pPlayer:table = Players[localPlayer]

local m_NothingColor:number = UI.GetColorValue("COLOR_NOTHING_BUILDER_LENS")
local m_ResourceColor:number = UI.GetColorValue("COLOR_RESOURCE_BUILDER_LENS")
local m_DamagedColor:number = UI.GetColorValue("COLOR_DAMAGED_BUILDER_LENS")
local m_RecommendedColor:number = UI.GetColorValue("COLOR_RECOMMENDED_BUILDER_LENS")
local m_HillColor:number = UI.GetColorValue("COLOR_HILL_BUILDER_LENS")
local m_FeatureColor:number = UI.GetColorValue("COLOR_FEATURE_BUILDER_LENS")
local m_GenericColor:number = UI.GetColorValue("COLOR_GENERIC_BUILDER_LENS")


-- NATIONAL PARK
--------------------------------------
table.insert(g_ModLenses_Builder_Config[m_NothingColor],
    function(pPlot)
        if pPlot:GetOwner() == localPlayer then
            if pPlot:IsNationalPark() then
                return m_NothingColor
            end
        end
        return -1
    end)


-- RESOURCE
--------------------------------------
table.insert(g_ModLenses_Builder_Config[m_ResourceColor],
    function(pPlot)
        if pPlot:GetOwner() == localPlayer and not plotHasDistrict(pPlot) then
            if playerHasDiscoveredResource(pPlayer, pPlot) then
                if plotHasImprovement(pPlot) then
                    if plotHasCorrectImprovement(pPlot) then
                        return m_NothingColor
                    end
                end

                if plotResourceImprovable(pPlayer, pPlot) then
                    return m_ResourceColor
                else
                    return m_NothingColor
                end
            end
        end
        return -1
    end)


-- DAMAGED / PILLAGED
--------------------------------------
table.insert(g_ModLenses_Builder_Config[m_DamagedColor],
    function(pPlot)
        if pPlot:GetOwner() == localPlayer and not plotHasDistrict(pPlot) then
            if plotHasImprovement(pPlot) and pPlot:IsImprovementPillaged() then
                return m_DamagedColor
            end
        end
        return -1
    end)


-- RECOMMENDED PLOTS
--------------------------------------
table.insert(g_ModLenses_Builder_Config[m_RecommendedColor],
    function(pPlot)
        if pPlot:GetOwner() == localPlayer and not plotHasDistrict(pPlot) and not plotHasImprovement(pPlot) then
            if plotHasFeature(pPlot) then
                local featureInfo = GameInfo.Features[pPlot:GetFeatureType()]
                if featureInfo.NaturalWonder then
                    return m_NothingColor
                end

                local terrainInfo = GameInfo.Terrains[pPlot:GetTerrainType()]

                -- 1. Non-hill woods next to river (lumbermill)
                local lumberImprovInfo = GameInfo.Improvements["IMPROVEMENT_LUMBER_MILL"]
                if not terrainInfo.Hills and featureInfo.FeatureType == "FEATURE_FOREST" and pPlot:IsRiver() and
                        playerCanHave(pPlayer, lumberImprovInfo) then

                    return m_RecommendedColor
                end

                -- 2. Farms on floodplains or volcanic soil
                local farmImprovInfo = GameInfo.Improvements["IMPROVEMENT_FARM"]
                if featureInfo.FeatureType == "FEATURE_VOLCANIC_SOIL" or featureInfo.FeatureType == "FEATURE_FLOODPLAINS_GRASSLAND"
                        or featureInfo.FeatureType == "FEATURE_FLOODPLAINS_PLAINS" and playerCanHave(pPlayer, farmImprovInfo) then

                    return m_RecommendedColor
                end

                -- 3. Tile next to buffing wonder
                if plotNextToBuffingWonder(pPlot) and plotCanHaveImprovement(pPlayer, pPlot) then
                    return m_RecommendedColor
                end
            end
        end
        return -1
    end)


-- HILLS
--------------------------------------
table.insert(g_ModLenses_Builder_Config[m_RecommendedColor],
    function(pPlot)
        if pPlot:GetOwner() == localPlayer and not plotHasDistrict(pPlot) and not plotHasImprovement(pPlot) then
            local terrainInfo = GameInfo.Terrains[pPlot:GetTerrainType()]
            local mineInfo = GameInfo.Improvements["IMPROVEMENT_MINE"]
            if terrainInfo.Hills and playerCanHave(pPlayer, mineInfo) then
                return m_HillColor
            end
        end
        return -1
    end)


-- FEATURE
--------------------------------------
table.insert(g_ModLenses_Builder_Config[m_FeatureColor],
    function(pPlot)
        if pPlot:GetOwner() == localPlayer and not plotHasDistrict(pPlot) and plotHasFeature(pPlot) then
            if playerCanRemoveFeature(pPlayer, pPlot) or playerCanImproveFeature(pPlayer, pPlot) then
                return m_FeatureColor
            else
                return m_NothingColor
            end
        end
        return -1
    end)


-- PRE-GENERIC (fallback)
--------------------------------------
table.insert(g_ModLenses_Builder_Config[m_GenericColor],
    function(pPlot)
        if pPlot:GetOwner() == localPlayer then

            -- Mountains, natural wonders, etec
            if plotHasDistrict(pPlot) then
                return m_NothingColor
            end

            -- Mountains, natural wonders, etec
            if pPlot:IsImpassable() then
                return m_NothingColor
            end

            -- Assume at this point if there is an improvement, don't color anything
            if plotHasImprovement(pPlot) then
                return m_NothingColor
            end

            if plotCanHaveImprovement(pPlayer, pPlot) then
                return m_GenericColor
            end
        end
        return -1
    end)
