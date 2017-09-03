if !(EPOCH_arr_interactedObjs isEqualTo[]) then {
	[EPOCH_arr_interactedObjs] remoteExec["EPOCH_server_save_vehicles", 2];
	EPOCH_arr_interactedObjs = [];
};

if (damage player != _damagePlayer) then {
	if (alive player) then {
		true call EPOCH_pushCustomVar;
		_damagePlayer = damage player;
	};
};

// calculate total available power
// 1. number of power production devices within range 75m

// find share of power based on factors
// 1. number of players
// 2. Other sources of drain (Lights)

_energyValue = EPOCH_chargeRate min _energyRegenMax;
_vehicle = vehicle player;
if (_vehicle != player && isEngineOn _vehicle) then {
	_energyValue = _energyValue + 5;
};

if (currentVisionMode player == 1) then { //NV enabled
	_energyValue = _energyValue - _energyCostNV;
	if (EPOCH_playerEnergy == 0) then {
		player action["nvGogglesOff", player];
		["Night Vision Goggles: Need Energy", 5] call Epoch_message;
	};
};

// Sets visual effect
if (EPOCH_playerAlcohol > 20) then {
	_drunkVal = linearConversion [0,100,EPOCH_playerAlcohol,0.1,1,true];
	[(round(_drunkVal * 10)/10), 2] call epoch_setDrunk;
} else {
	[0, 2] call epoch_setDrunk;
};

// Sets visual effect
if (_playerRadiation > 1) then {
	_radiationVal = linearConversion [0,100,_playerRadiation,0.1,1,true];
	[(round(_radiationVal * 10)/10), 2] call epoch_setRadiation;
} else {
	[0, 2] call epoch_setRadiation;
};

EPOCH_playerEnergy = ((EPOCH_playerEnergy + _energyValue) min EPOCH_playerEnergyMax) max 0;

if !(EPOCH_playerEnergy isEqualTo _prevEnergy) then {
	9993 cutRsc["EpochGameUI3", "PLAIN", 0, false];
	_display3 = uiNamespace getVariable "EPOCH_EpochGameUI3";
	_energyDiff = round(EPOCH_playerEnergy - _prevEnergy);
	_diffText = if (_energyDiff > 0) then {format["+%1",_energyDiff]} else {format["%1",_energyDiff]};
	(_display3 displayCtrl 21210) ctrlSetText format["%1/%2 %3", round(EPOCH_playerEnergy), EPOCH_playerEnergyMax, _diffText];
	_prevEnergy = EPOCH_playerEnergy;
};

if (EPOCH_playerEnergy == 0) then {
	if (EPOCH_buildMode > 0) then {
		EPOCH_buildMode = 0;
		EPOCH_snapDirection = 0;
		["Build Mode Disabled: Need Energy", 5] call Epoch_message;
		EPOCH_Target = objNull;
		EPOCH_Z_OFFSET = 0;
		EPOCH_X_OFFSET = 0;
		EPOCH_Y_OFFSET = 5;
	};
};

_attackers = player nearEntities[["Snake_random_EPOCH", "GreatWhite_F", "Epoch_Cloak_F"], 30];
if !(_attackers isEqualTo[]) then {
	(_attackers select 0) call EPOCH_client_bitePlayer;
	_panic = true;
} else {
	_toxicObjs = player nearobjects["SmokeShellCustom", 6];
	if!(_toxicObjs IsEqualTo[]) then {
		(_toxicObjs select 0) call EPOCH_client_bitePlayer;
		_panic = true;
	} else {
		_panic = false;
	};
};

// weather stats
_airTemp = EPOCH_CURRENT_WEATHER;
_waterTemp = EPOCH_CURRENT_WEATHER/2;
_warming = true;
_wet = false;
_maxTemp = 98.6; // normal body temp
_increaseWet = 0;
_wetsuit = (getText(configfile >> "cfgweapons" >> uniform player >> "itemInfo" >> "uniformType") == "Neopren");

if (_isOnFoot) then {
	if (EPOCH_playerIsSwimming) then {
		// do nothing if player is wearing a wetsuit
		if (!_wetsuit) then {
			if (_waterTemp <= 50) then {
				_warming = false;
			};
			_wet = true;
			_increaseWet = 10;
		};
	} else {
		if (EPOCH_playerWet > 50 && _airTemp <= 32) then {
			_isNearFire = {inflamed _x} count (nearestObjects [player, ["ALL"], 3]);
			if (!(call EPOCH_fnc_isInsideBuilding) && _isNearFire == 0) then {
				_warming = false;
			};
		};
		if (rain >= 0.25) then {
			if (!_wetsuit) then {
				_isNearFire = { inflamed _x } count(nearestObjects[player, ["ALL"], 3]);
				if (!(call EPOCH_fnc_isInsideBuilding) && _isNearFire == 0) then {
					_wet = true;
					_increaseWet = rain * 10;
				};
			};
		};
	};
};

// allow player to over heat if air temp is high and player is Fatigued
if ((getFatigue player) >= 0.7 && _airTemp > 100) then {
	_maxTemp = _airTemp;
};

// toxic fever and immunity increase
if (EPOCH_playerToxicity > 0) then {
	EPOCH_playerImmunity = (EPOCH_playerImmunity + 0.1) min 100;
	EPOCH_playerToxicity = (EPOCH_playerToxicity - 0.1) max 0;
	_maxTemp = 106.7 + 10;
};

if (_warming) then {
	EPOCH_playerTemp = (EPOCH_playerTemp + 0.01) min _maxTemp;
} else {
	EPOCH_playerTemp = (EPOCH_playerTemp - 0.01) max (95.0 - 10);
};

// wet/dry
if (_wet) then {
	EPOCH_playerWet = (EPOCH_playerWet + _increaseWet) min 100;
	if (EPOCH_playerWet > 50) then {
		EPOCH_playerSoiled = (EPOCH_playerSoiled - 1) max 0;
	};
} else {
	if (_warming) then {
		EPOCH_playerWet = (EPOCH_playerWet - 1) max 0;
	};
};

// Hunger / Thirst
_hungerlossRate = _baseHungerLoss * timeMultiplier;
_thirstlossRate = _baseThirstLoss * timeMultiplier;

// Increase hunger if player is Fatigued
if (EPOCH_playerStamina < 100) then {
	if ((getFatigue player) > 0) then {
		_hungerlossRate = _hungerlossRate + (_hungerlossRate*(getFatigue player));
	};
} else {
    // reduce hunger loss if player stamina is greater than 100
	_hungerlossRate = (_hungerlossRate / 2);
};

EPOCH_playerHunger = (EPOCH_playerHunger - _hungerlossRate) max 0;
EPOCH_playerThirst = (EPOCH_playerThirst - _thirstlossRate) max 0;

call _lootBubble;

EPOCH_playerStaminaMax = (100 * (round(EPOCH_playerAliveTime/360)/10)) min 2500;

// downtick Nuisance
(EPOCH_customVarLimits select (EPOCH_customVars find "Nuisance")) params [["_playerLimitMax",100],["_playerLimitMin",0]];
EPOCH_playerNuisance = ((EPOCH_playerNuisance - 1) min _playerLimitMax) max _playerLimitMin;
