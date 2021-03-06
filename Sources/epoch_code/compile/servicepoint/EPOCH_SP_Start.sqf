Ignatz_Refuel = nil;
Ignatz_Repair = nil;
Ignatz_Rearm0 = nil;
Ignatz_Rearm1 = nil;
Ignatz_Rearm2 = nil;
Ignatz_Rearm3 = nil;

if (vehicle player == player) exitwith {false};
if !(local vehicle player) exitwith {false};
if (speed vehicle player > 2 || speed vehicle player < -2) exitwith {false};
if (((getpos vehicle player) select 2) > 1) exitwith {false};

private ['_missingammo','_ownedcompletemags','_magname','_actionTitle','_costs','_vehicle','_refuel_costs','_refuel_updateInterval','_refuel_amount','_costsFree','_repair_costs','_repair_repairTime','_fnc_getCosts','_fnc_actionTitle'];

_config = 					'CfgServicePoint' call EPOCH_returnConfig;
_servicepoints = 			getArray (_config >> worldname >> 'ServicePoints');
_servicepointDist = 		["CfgServicePoint", "ServicePointDist", 40] call EPOCH_fnc_returnConfigEntryV2;

if !(({player distance _x < _servicepointDist} count _servicepoints > 0)) exitwith {false};
_Vehicle = vehicle player;
if (!(_Vehicle iskindof 'ship') && (((getposasl _Vehicle)  select 2) < 1)) exitwith {false};

_repair_costs = 			["CfgServicePoint", "repair_costs", []] call EPOCH_fnc_returnConfigEntryV2;
_refuel_costs = 			["CfgServicePoint", "refuel_costs", []] call EPOCH_fnc_returnConfigEntryV2;
_refuel_updateInterval = 	["CfgServicePoint", "refuel_updateInterval", 1] call EPOCH_fnc_returnConfigEntryV2;
_refuel_amount = 			["CfgServicePoint", "refuel_amount", 0.1] call EPOCH_fnc_returnConfigEntryV2;
_repairTime = 				["CfgServicePoint", "repairTime", 1.2] call EPOCH_fnc_returnConfigEntryV2;
_VehiclesAndAmmo = 			["CfgServicePoint", "VehiclesAndAmmo", []] call EPOCH_fnc_returnConfigEntryV2;

_Ignatz_SP_Array = [];
_costsFree = 'free';

_fnc_getCosts = {
	private ['_typeName','_vehicle','_costs','_cost'];
	_vehicle = _this select 0;
	_costs = _this select 1;
	_cost = 0;
	{
		_typeName = _x select 0;
		if (_vehicle isKindOf _typeName) exitWith {
			_cost = _x select 1;
		};
	} forEach _costs;
	_cost
};
_fnc_actionTitle = {
	private ['_itemName','_displayName','_actionName','_costs','_costsText','_actionTitle'];
	_actionName = _this select 0;
	_costs = _this select 1;
	_costsText = _costsFree;
	if (_costs > 0) then {
		_costsText = format ['%1 Crypto',_costs];
	};
	_actionTitle = format ['%1 (%2)', _actionName, _costsText];
	_actionTitle
};

{
	if ((typeof _vehicle) == _x select 0) exitwith {
		{
			_ammotype = _x select 0;
			_turret = _x select 1;
			_maxmags = _x select 2;
			_costs = _x select 3;
			_ammocount = getNumber (configfile >> "CfgMagazines" >> (_x select 0) >> "count");
			_maxammototal = _maxmags*_ammocount;
			_totalammocount = 0;
			{
				if (_ammotype isequalto (_x select 0) && _turret isequalto (_x select 1)) then {
					_totalammocount = _totalammocount + (_x select 2);
				};
			} foreach (magazinesAllTurrets  _vehicle);
			if (_totalammocount < _maxammototal) then {
				for '_i' from 1 to 10 do {
					if (_totalammocount < _i*_ammocount) exitwith {
						_ownedcompletemags = _i-1;
						_missingammo = _ammocount*_i - _totalammocount;
						_costs = round (_costs/_ammocount*_missingammo);
					};
				};
				_magname = getText (configFile >> 'CfgMagazines' >> _ammotype >> 'displayName');
				if (_magname isequalto '') then {
					_magname = _ammotype;
				};
				_reloagmags = _ownedcompletemags+1;
				_actionTitle = format['Rearm %1 with %2 round %3 (%4 Crypto)',getText (configFile >> 'Cfgvehicles' >> typeOf _vehicle >> 'displayName'),_missingammo,_magname, _costs];
				_Ignatz_SP_Array pushback [_actionTitle,[_vehicle,_ammotype,_turret,_reloagmags,_ammocount,_costs]];
			};
		} foreach (_x select 1);
	};
} foreach _VehiclesAndAmmo;

_costs = [_vehicle, _refuel_costs] call _fnc_getCosts;
_actionTitle = [format['Refuel %1',getText (configFile >> 'Cfgvehicles' >> typeOf _vehicle >> 'displayName')], _costs] call _fnc_actionTitle;
Ignatz_Refuel = [_actionTitle,[_vehicle,[_costs, _refuel_updateInterval,_refuel_amount]]];

_costs = [_vehicle, _repair_costs] call _fnc_getCosts;
_actionTitle = [format['Repair %1',getText (configFile >> 'Cfgvehicles' >> typeOf _vehicle >> 'displayName')], _costs] call _fnc_actionTitle;
Ignatz_Repair = [_actionTitle,[_vehicle,[_costs, _repairTime]]];
if (count _Ignatz_SP_Array > 0) then {Ignatz_Rearm0 = _Ignatz_SP_Array select 0;};
if (count _Ignatz_SP_Array > 1) then {Ignatz_Rearm1 = _Ignatz_SP_Array select 1;};
if (count _Ignatz_SP_Array > 2) then {Ignatz_Rearm2 = _Ignatz_SP_Array select 2;};
if (count _Ignatz_SP_Array > 3) then {Ignatz_Rearm3 = _Ignatz_SP_Array select 3;};
true
