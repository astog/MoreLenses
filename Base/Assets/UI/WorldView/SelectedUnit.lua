-- ===========================================================================
--	Handles selected unit actions with the game engine
-- ===========================================================================


-- ===========================================================================
--	VARIABLES
-- ===========================================================================
local AUTO_APPLY_SETLER_LENS = true
local AUTO_APPLY_RELIGION_LENS = true

local m_MovementRange : number = UILens.CreateLensLayerHash("Movement_Range");
local m_MovementZoneOfControl : number = UILens.CreateLensLayerHash("Movement_Zone_Of_Control");
local m_HexColoringWaterAvail : number = UILens.CreateLensLayerHash("Hex_Coloring_Water_Availablity");
local m_HexColoringReligion : number = UILens.CreateLensLayerHash("Hex_Coloring_Religion");
local m_Selection : number = UILens.CreateLensLayerHash("Selection");

-- ===========================================================================
--	GLOBALS
-- ===========================================================================

m_HexColoringGreatPeople = UILens.CreateLensLayerHash("Hex_Coloring_Great_People");

-- ===========================================================================
--	MEMBERS
-- ===========================================================================

-- ===========================================================================
function RealizeMoveRadius( kUnit:table )
	
	UILens.ClearLayerHexes( m_MovementRange );
	UILens.ClearLayerHexes( m_MovementZoneOfControl );

	if kUnit ~= nil and ( not GameInfo.Units[kUnit:GetUnitType()].IgnoreMoves ) and ( not UI.IsGameCoreBusy() ) then
		
		if not ( kUnit:GetMovesRemaining() > 0 )then
			return;
		end
		
		local eLocalPlayer	:number = Game.GetLocalPlayer();
		local kUnitInfo		:table = GameInfo.Units[kUnit:GetUnitType()];

		if kUnitInfo ~= nil and (kUnitInfo.Spy or kUnitInfo.MakeTradeRoute) then
			-- Spies and Traders don't move like normal units so these lens layers can be ignored
			return;
			
		else
			local kAttackPlots			:table = UnitManager.GetReachableTargets( kUnit );
			local kMovePlots			:table = nil;
			local kZOCPlots				:table = nil;
			local kAttackIndicators		:table = {};
			
			if not kUnit:HasMovedIntoZOC() then
				kMovePlots	 = UnitManager.GetReachableMovement( kUnit );
				kZOCPlots	 = UnitManager.GetReachableZonesOfControl( kUnit, true );	-- Only plots visible to the unit.
				if kZOCPlots == nil then kZOCPlots = {} end
			else
				kMovePlots = {};
				kZOCPlots = {};
				table.insert( kMovePlots, Map.GetPlot( kUnit:GetX(), kUnit:GetY() ):GetIndex() );
			end
						
			local isShowingTarget :boolean = kUnit:GetAttacksRemaining() > 0;

			-- Extract attack indicator locations and extensions to movement range
			if isShowingTarget and kAttackPlots ~= nil and table.count( kAttackPlots ) > 0 then
				if kMovePlots == nil then kMovePlots = {} end
				for _, plot in ipairs( kAttackPlots ) do
					table.insert( kAttackIndicators, { "AttackRange_Target", plot } );
					table.insert( kMovePlots, plot );
				end
			end

			-- Extract attack indicator locations for ranged attacks
			local pResults = UnitManager.GetOperationTargets(kUnit, UnitOperationTypes.RANGE_ATTACK );
			local pAllPlots = pResults[UnitOperationResults.PLOTS];
			if pAllPlots ~= nil then
				for i, modifier in ipairs( pResults[UnitOperationResults.MODIFIERS] ) do
					if modifier == UnitOperationResults.MODIFIER_IS_TARGET then
						-- Dedupe hexes
						local kPlotId :number = pAllPlots[i];
						local isUnique : boolean = true;
						for k, v in ipairs( kAttackIndicators ) do
							if v[2] == kPlotId then
								isUnique = false;
								break;
							end
						end
						if isUnique then
							table.insert( kAttackIndicators, { "AttackRange_Target", kPlotId } );
						end
					end
				end
			end

			-- Lay down ZOC and attack indicators
			if table.count( kZOCPlots ) > 0 or table.count( kAttackIndicators ) > 0 then
				UILens.SetLayerHexesArea( m_MovementZoneOfControl, eLocalPlayer, kZOCPlots, kAttackIndicators );
			end

			-- Lay down movement border around movable and attack-movable hexes
			if kMovePlots ~= nil and table.count( kMovePlots ) > 0 then
				UILens.SetLayerHexesArea( m_MovementRange, eLocalPlayer, kMovePlots );
			end
		end
	end
end

-- ===========================================================================
function RealizeGreatPersonLens( kUnit:table )
	UILens.ClearLayerHexes(m_HexColoringGreatPeople);
	if UILens.IsLayerOn( m_HexColoringGreatPeople ) then
		UILens.ToggleLayerOff(m_HexColoringGreatPeople);
	end
	if kUnit ~= nil and ( not UI.IsGameCoreBusy() ) then
		local playerID:number = kUnit:GetOwner();
		if playerID == Game.GetLocalPlayer() then
			local kUnitArchaeology:table = kUnit:GetArchaeology();
			local kUnitGreatPerson:table = kUnit:GetGreatPerson();
			if kUnitGreatPerson ~= nil and kUnitGreatPerson:IsGreatPerson() then
				local greatPersonInfo:table = GameInfo.GreatPersonIndividuals[kUnitGreatPerson:GetIndividual()];
				-- Highlight an area around the Great Person (if they have an area of effect trait)
				local areaHighlightPlots:table = {};
				if (greatPersonInfo ~= nil and greatPersonInfo.AreaHighlightRadius ~= nil) then
					areaHighlightPlots = kUnitGreatPerson:GetAreaHighlightPlots();
				end
				-- Highlight the plots the Great Person could use its action on
				local activationPlots:table = {};
				if (greatPersonInfo ~= nil and greatPersonInfo.ActionEffectTileHighlighting ~= nil and greatPersonInfo.ActionEffectTileHighlighting) then
					local rawActivationPlots:table = kUnitGreatPerson:GetActivationHighlightPlots();
					for _,plotIndex:number in ipairs(rawActivationPlots) do
						table.insert(activationPlots, {"Great_People", plotIndex});
					end
				end
				UILens.SetLayerHexesArea(m_HexColoringGreatPeople, playerID, areaHighlightPlots, activationPlots);
				UILens.ToggleLayerOn(m_HexColoringGreatPeople);
			elseif( kUnitArchaeology ~= nil and GameInfo.Units[kUnit:GetUnitType()].ExtractsArtifacts == true) then 
				-- Highlight plots that can activated by Archaeologists
				local activationPlots:table = {};
				local rawActivationPlots:table = kUnitArchaeology:GetActivationHighlightPlots();
				for _,plotIndex:number in ipairs(rawActivationPlots) do
					table.insert(activationPlots, {"Great_People", plotIndex});
				end
					
				UILens.SetLayerHexesArea(m_HexColoringGreatPeople, playerID, {}, activationPlots);
				UILens.ToggleLayerOn(m_HexColoringGreatPeople);
			elseif GameInfo.Units[kUnit:GetUnitType()].ParkCharges > 0 then -- Highlight plots that can activated by Naturalists
				local parkPlots:table = {};
				local rawParkPlots:table = Game.GetNationalParks():GetPossibleParkTiles(playerID);
				for _,plotIndex:number in ipairs(rawParkPlots) do
					table.insert(parkPlots, {"Great_People", plotIndex});
				end
				UILens.SetLayerHexesArea(m_HexColoringGreatPeople, playerID, {}, parkPlots);
				UILens.ToggleLayerOn(m_HexColoringGreatPeople);
			end
		end
	end
end
-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnUnitVisibilityChanged( playerID: number, unitID : number, eVisibility : number)
end

-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnUnitSelectionChanged( playerID:number, unitID:number, hexI:number, hexJ:number, hexK:number, isSelected:boolean, isEditable:boolean )
	if playerID ~= Game.GetLocalPlayer() then
		return;
	end

	-- Mode(s) to skip selecting a unit
	local eMode:number = UI.GetInterfaceMode();
	if eMode == InterfaceModeTypes.CINEMATIC then return; end	-- (Still) in Cinematic mode; one may have just queued up after the other.


	local kUnit		:table = nil;
	local pPlayer	:table = Players[playerID];
	if pPlayer ~= nil then
		kUnit = pPlayer:GetUnits():FindID(unitID);

		if isSelected then
			-- If a selection is occuring and the modal lens interface mode is up, take it down.
			if UI.GetInterfaceMode() == InterfaceModeTypes.VIEW_MODAL_LENS then
				UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);
			end
			
			-- If a selection is occuring and the city attack interface mode is up, take it down.
			if UI.GetInterfaceMode() == InterfaceModeTypes.CITY_RANGE_ATTACK then
				UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);
			end

			UILens.SetActive("Default");

			local religiousStrength :number = kUnit:GetReligiousStrength();
			if religiousStrength > 0 and not UILens.IsLensActive("Religion") and AUTO_APPLY_RELIGION_LENS then
				UILens.SetActive("Religion");
			elseif GameInfo.Units[kUnit:GetUnitType()].FoundCity and AUTO_APPLY_SETLER_LENS and pPlayer:GetCities():GetCount() > 0 then
				UILens.ToggleLayerOn(m_HexColoringWaterAvail);			-- Used on the settler lens
			end
		else
			if kUnit ~= nil then
				local religiousStrength :number = kUnit:GetReligiousStrength();
				if religiousStrength > 0 and UILens.IsLensActive("Religion") then
					UILens.SetActive("Default");
				elseif GameInfo.Units[kUnit:GetUnitType()].FoundCity and UILens.IsLayerOn(m_HexColoringWaterAvail) then
					UILens.ToggleLayerOff(m_HexColoringWaterAvail);
				end
				kUnit = nil; -- Ensure movement radius is turned off.
			else
				-- No selected unit, if a missionary just consumed themselves,
				-- kUnit will be nul but the lens still needs to be turned off.
				if UILens.IsLensActive("Religion") then
					UILens.SetActive("Default");
				end
			end
		end
	end

	RealizeMoveRadius( kUnit );
	RealizeGreatPersonLens( kUnit );
end

-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function UnitSimPositionChanged( playerID:number, unitID:number, worldX:number, worldY:number, worldZ:number, bVisible:boolean, isComplete:boolean )
	if playerID ~= Game.GetLocalPlayer() then
		return
	end
	local kUnit:table = nil;
	if isComplete then
		local pPlayer:table = Players[ playerID ];
		if pPlayer ~= nil then
			-- If the unit that just finished moving is STILL the selected unit,
			-- then it has more moves to make, update the move radius...
			kUnit = pPlayer:GetUnits():FindID(unitID);
			if kUnit == UI.GetHeadSelectedUnit() then
				RealizeMoveRadius( kUnit );
				RealizeGreatPersonLens( kUnit );
			end
		end
	end
end

-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnBeginWonderReveal()
	UILens.ToggleLayerOff(m_Selection);
	UILens.ClearLayerHexes(m_Selection);
end

-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnEndWonderReveal()
	UILens.ToggleLayerOn(m_Selection);
end

-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnInterfaceModeChanged(eOldMode:number, eNewMode:number)
	if eNewMode == InterfaceModeTypes.VIEW_MODAL_LENS then
		UI.DeselectAll();
	end
end

-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnLensLayerOn( layerNum:number )
	if layerNum == m_MovementRange then
		local pUnit:table = UI.GetHeadSelectedUnit();
		if pUnit ~= nil then
			RealizeMoveRadius( pUnit );
		end
	end
end


-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnCombatVisBegin()
	UILens.ClearLayerHexes( m_MovementRange );
	UILens.ClearLayerHexes( m_MovementZoneOfControl  );
	UILens.ClearLayerHexes( m_Selection );
end

-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnCombatVisEnd(aCombatVisData : table)

	-- Only do this if the local player was involved
	local localPlayerID = Game.GetLocalPlayer();
	if (localPlayerID == -1) then
		return;
	end

	local isInvolvesLocalPlayer = false;

	for _, i in ipairs(aCombatVisData) do
		if i.playerID == localPlayerID then
			isInvolvesLocalPlayer = true;
		end
	end

	if isInvolvesLocalPlayer then

		local pUnit :table = UI.GetHeadSelectedUnit();

		-- Explicitly deselect the unit if they have no more moves, this allows
		-- UI pieces stop showing the previous unit's info.
		if pUnit ~= nil and aCombatVisData[CombatVisType.ATTACKER].componentID == pUnit:GetID() and pUnit:GetMovesRemaining() == 0 then
			UI.DeselectUnit(pUnit);
			-- Start the timer for the UI systems auto unit cycling code, which will handle selecting the next unit
			-- This is better than calling the selection advance directly because queued events may pending that want to control the camera.
			UI.SetCycleAdvanceTimer();
		end
	end
end


-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnLocalPlayerTurnBegin()
	local idLocalPlayer	:number = Game.GetLocalPlayer();
	local pPlayer		:table = Players[ idLocalPlayer ];
	
	if UI.GetInterfaceMode() == InterfaceModeTypes.VIEW_MODAL_LENS then
		UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);
	end
	UILens.SetActive("Default");
end

-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnPlayerTurnActivated( ePlayer:number, isFirstTime:boolean )
	if ePlayer == Game.GetLocalPlayer() then
		local kUnit = UI.GetHeadSelectedUnit();
		if (kUnit ~= nil) then
			RealizeMoveRadius( kUnit );
		end
	end
end

-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnUnitPromotionChanged(playerID : number, unitID : number )
	local idLocalPlayer	:number = Game.GetLocalPlayer();
	if idLocalPlayer > -1 and playerID == idLocalPlayer then
		local kUnit = UI.GetHeadSelectedUnit();
		if (kUnit ~= nil) then
			RealizeMoveRadius( kUnit );
		end
	end
end

-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnUnitTeleported(playerID: number, unitID : number, x : number, y : number)
	local idLocalPlayer	:number = Game.GetLocalPlayer();
	if idLocalPlayer > -1 and playerID == idLocalPlayer then
		local kUnit = UI.GetHeadSelectedUnit();
		if (kUnit ~= nil) then
			RealizeMoveRadius( kUnit );
			RealizeGreatPersonLens( kUnit );
		end
	end
end

-- ===========================================================================
--	Engine EVENT
--	Local player changed; likely a hotseat game
-- ===========================================================================
function OnLocalPlayerChanged( eLocalPlayer:number , ePrevLocalPlayer:number )
	if eLocalPlayer == -1 then
		return;
	end
	UI.DeselectAllUnits();
	UI.DeselectAllCities();

	-- Equivalent to original code, not sure if actually needed
	if UILens.IsLensActive("Religion") then
		UILens.ClearLayerHexes( m_HexColoringReligion );
	end
	
	if UI.GetInterfaceMode() == InterfaceModeTypes.VIEW_MODAL_LENS then
		UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);
	end
	UILens.SetActive("Default");

	if(UILens.IsLayerOn(m_HexColoringGreatPeople)) then
		UILens.ClearLayerHexes( m_HexColoringGreatPeople );
		UILens.ToggleLayerOff( m_HexColoringGreatPeople );
	end

	if(UILens.IsLayerOn(m_HexColoringWaterAvail)) then
		UILens.ClearLayerHexes( m_HexColoringWaterAvail );
		UILens.ToggleLayerOff( m_HexColoringWaterAvail );
	end

	if(UILens.IsLayerOn(m_MovementZoneOfControl)) then
		UILens.ClearLayerHexes( m_MovementZoneOfControl );
		UILens.ToggleLayerOff( m_MovementZoneOfControl );
	end

	if(UILens.IsLayerOn(m_MovementRange)) then
		UILens.ClearLayerHexes( m_MovementRange );
		UILens.ToggleLayerOff( m_MovementRange );
	end
end
-- ===========================================================================
--	LUA Event
--	Do not show "water" available lens when settler is selected.
-- ===========================================================================
function OnTutorialUIRoot_DisableSettleHintLens()
	AUTO_APPLY_SETLER_LENS = false;
end

-- ===========================================================================
--	UI Event
-- ===========================================================================
function OnContextInitialize(bHotload : boolean)
	if bHotload then
	end
end

-- ===========================================================================
--	Handle the UI shutting down.
function OnShutdown()
	Events.LocalPlayerTurnBegin.Remove( OnLocalPlayerTurnBegin );
	Events.UnitSelectionChanged.Remove( OnUnitSelectionChanged );
	Events.UnitSimPositionChanged.Remove( UnitSimPositionChanged );
	Events.UnitVisibilityChanged.Remove( OnUnitVisibilityChanged );
end

-- ===========================================================================
function Initialize()

	UI.SetSelectedUnitUIArt("MovementGood_Select");

	ContextPtr:SetInitHandler( OnContextInitialize );
	ContextPtr:SetShutdown( OnShutdown );

	Events.BeginWonderReveal.Add( OnBeginWonderReveal );
	Events.CombatVisBegin.Add( OnCombatVisBegin );
	Events.CombatVisEnd.Add( OnCombatVisEnd );
	Events.EndWonderReveal.Add( OnEndWonderReveal );
	Events.InterfaceModeChanged.Add( OnInterfaceModeChanged );
	Events.LensLayerOn.Add( OnLensLayerOn );
	Events.LocalPlayerTurnBegin.Add( OnLocalPlayerTurnBegin );
	Events.PlayerTurnActivated.Add( OnPlayerTurnActivated );
	Events.UnitTeleported.Add( OnUnitTeleported );
	Events.UnitPromoted.Add( OnUnitPromotionChanged );
	Events.UnitSelectionChanged.Add( OnUnitSelectionChanged );
	Events.UnitSimPositionChanged.Add( UnitSimPositionChanged );
	Events.UnitVisibilityChanged.Add( OnUnitVisibilityChanged );
	Events.LocalPlayerChanged.Add(OnLocalPlayerChanged);

	LuaEvents.TutorialUIRoot_DisableSettleHintLens.Add( OnTutorialUIRoot_DisableSettleHintLens );
end
Initialize();
