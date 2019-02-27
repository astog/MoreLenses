-- ===========================================================================
--    Toggle Unit Lense
-- ===========================================================================

include("ModLens_Archaeologist")
include("ModLens_Builder")
include("ModLens_Scout")

local m_SettlerLensLayerHash : number = UILens.CreateLensLayerHash("Hex_Coloring_Water_Availablity");
local m_ModLensLayerHash : number = UILens.CreateLensLayerHash("Hex_Coloring_Appeal_Level");

function OnToggleUnitLense()
    local pUnit :table = UI.GetHeadSelectedUnit();
    if( pUnit == nil ) then
        return;
    end
  
    local bPlaySound :boolean = true;
    local religiousStrength :number = pUnit:GetReligiousStrength();
    local unitType = GameInfo.Units[pUnit:GetUnitType()].UnitType;
    local unitPromotionClass = GameInfo.Units[pUnit:GetUnitType()].PromotionClass;
    
    if GameInfo.Units[pUnit:GetUnitType()].FoundCity then
        if UILens.IsLayerOn(m_SettlerLensLayerHash) then
            UILens.ToggleLayerOff(m_SettlerLensLayerHash);
        else
            UILens.ToggleLayerOn(m_SettlerLensLayerHash);
        end
    elseif religiousStrength > 0 then
        if UILens.IsLensActive("Religion") then
            UILens.SetActive("Default");
        else
            UILens.SetActive("Religion");
        end
    elseif unitType == "UNIT_ARCHAEOLOGIST" then
        if UILens.IsLayerOn(m_ModLensLayerHash) then
            ClearArchaeologistLens();
        else
            ShowArchaeologistLens();
        end
    elseif unitType == "UNIT_BUILDER" then
        if UILens.IsLayerOn(m_ModLensLayerHash) then
            ClearBuilderLens();
        else
            ShowBuilderLens();
        end
    elseif unitPromotionClass == "PROMOTION_CLASS_RECON" then
        if UILens.IsLayerOn(m_ModLensLayerHash) then
            ClearScoutLens();
        else
            ShowScoutLens();
        end
    else
        bPlaySound = false
    end
  
    if bPlaySound then
        UI.PlaySound("Play_UI_Click");    
    end
end

function OnIngameAction(actionId)
    if Game.GetLocalPlayer() == -1 then
        return;
    end
    if actionId == Input.GetActionId("ModLens_ToggleUnitLense") then
        OnToggleUnitLense();
    end
end


-- ===========================================================================
-- INITIALIZATION
-- ===========================================================================
function OnInit(isReload:boolean)

end

function OnShutdown()
    Events.InputActionTriggered.Remove( OnIngameAction );
end

function Initialize()
    ContextPtr:SetInitHandler( OnInit );
    ContextPtr:SetShutdown( OnShutdown );
    Events.InputActionTriggered.Add( OnIngameAction );
end
Initialize();
