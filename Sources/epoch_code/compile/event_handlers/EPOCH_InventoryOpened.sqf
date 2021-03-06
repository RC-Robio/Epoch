/*
	Author: Aaron Clark - EpochMod.com

    Contributors: [Ignatz] He-Man

	Description:
	A3 Epoch InventoryOpened Eventhandler

    Licence:
    Arma Public License Share Alike (APL-SA) - https://www.bistudio.com/community/licenses/arma-public-license-share-alike

    Github:
    https://github.com/EpochModTeam/Epoch/tree/release/Sources/epoch_code/compile/event_handlers/EPOCH_InventoryOpened.sqf
*/
params ["_unit","_container","_sec"];
setMousePosition[0.5, 0.5];
call EPOCH_showStats;
_this spawn EPOCH_initUI;
_containerlocked = (locked _container in [2, 3] || _container getVariable['EPOCH_Locked', false]);
_seclocked = false;
if !(isNull _sec) then {
	_seclocked = (locked _sec in [2, 3] || _sec getVariable['EPOCH_Locked', false]);
};
_blocked = (_containerlocked && _seclocked);
if (!_blocked && _containerlocked || _seclocked) then {
	[] spawn {
		disableSerialization;
		waitUntil {!isNull findDisplay 602};
		_d = findDisplay 602;
		_cargo = _d displayCtrl 6401;
		_ground = _d displayCtrl 6321;
		_cargo ctrlEnable false;
		ctrlSetFocus _ground;
		ctrlActivate _ground;
	};
};
_blocked
