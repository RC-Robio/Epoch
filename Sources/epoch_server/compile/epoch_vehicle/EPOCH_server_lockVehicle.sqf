/*
	Author: Aaron Clark - EpochMod.com

    Contributors:

	Description:
    (Un)Lock Vehicles

    Licence:
    Arma Public License Share Alike (APL-SA) - https://www.bistudio.com/community/licenses/arma-public-license-share-alike

    Github:
    https://github.com/EpochModTeam/Epoch/tree/release/Sources/epoch_server/compile/epoch_vehicle/EPOCH_server_lockVehicle.sqf
*/
//[[[cog import generate_private_arrays ]]]
private ["_crew","_driver","_isLocked","_lockOwner","_lockedOwner","_logic","_playerGroup","_playerUID","_response","_vehLockHiveKey","_vehSlot"];
//[[[end]]]
params [
    ["_vehicle",objNull,[objNull]],
    ["_value",true,[true]],
    ["_player",objNull,[objNull]],
    ["_token","",[""]]
];

if (isNull _vehicle) exitWith {};
if !([_player,_token] call EPOCH_server_getPToken) exitWith {};
if (_player distance _vehicle > 20) exitWith {};

// Group access
_playerUID = getPlayerUID _player;
_playerGroup = _player getVariable["GROUP", ""];

_lockOwner = _playerUID;
if (_playerGroup != "") then {
	_lockOwner = _playerGroup;
};

_lockedOwner = "-1";
_vehSlot = _vehicle getVariable["VEHICLE_SLOT", "ABORT"];
_vehLockHiveKey = format["%1:%2", (call EPOCH_fn_InstanceID), _vehSlot];
if (_vehSlot != "ABORT") then {
	_response = ["VehicleLock", _vehLockHiveKey] call EPOCH_fnc_server_hiveGETRANGE;
	if ((_response select 0) == 1 && (_response select 1) isEqualType [] && !((_response select 1) isEqualTo[])) then {
		_lockedOwner = _response select 1 select 0;
	};
};

// get locked state
_isLocked = locked _vehicle in[2, 3];

_driver = driver _vehicle;
_crew = [];
{
	// only get alive crew
	if (alive _x) then {
		_crew pushBack _x;
	};
} forEach (crew _vehicle);

// if vehicle has a crew and player is not inside vehicle only allow locking if already owner
_logic = if !(_crew isEqualTo []) then {
	if (_player in _crew) then {
		// allow unlock if player is the driver or is inside the vehicle with out a driver.
		(_player isEqualTo _driver || isNull(_driver) || _lockedOwner == _lockOwner || !alive _driver)
	} else {
		// allow only if player is already the owner as they are not inside the occupied vehicle.
		(_lockedOwner == _lockOwner)
	};
} else {
	// vehicle has no crew, so allow only if: unlocked, is already the owner, vehicle has no owner.
	(!_isLocked || _lockedOwner == _lockOwner || _lockedOwner == "-1")
};

// Lockout mech
if (_logic) then {

	if (_value) then {
		["VehicleLock", _vehLockHiveKey, EPOCH_vehicleLockTime, [_lockOwner]] call EPOCH_fnc_server_hiveSETEX;
	} else {
        // re-allow damage (server-side) on first unlock
        if (_vehicle getVariable ["EPOCH_disallowedDamage", false]) then {
            _vehicle allowDamage true;
            _vehicle setVariable ["EPOCH_disallowedDamage", nil];
        };
    };

    // lock/unlock
	if (local _vehicle) then {
		_vehicle lock _value;
	} else {
		[_vehicle, _value] remoteExec ['EPOCH_client_lockVehicle',_vehicle];
	};
};
