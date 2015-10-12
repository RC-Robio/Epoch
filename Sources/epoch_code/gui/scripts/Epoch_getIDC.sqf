/*
	Used to register and unregister IDC used in dynamic menus.
	Pass the control to unregister or just call fnc to get a unique IDC
*/
private ["_in","_list","_out","_find"];
_in = param [0,controlNull,[controlNull]];
_list = uiNamespace getVariable ["rmx_var_uniqueIDC",[]];

if (ctrlIDC _in isEqualTo -1) then {
	_out = -90000 - (count _list);
	_list pushBack _out;
} else {
	_find = _list find (ctrlIDC _in);
	_list deleteAt _find;
	_out = true;
};
uiNamespace setVariable ["rmx_var_uniqueIDC",_list];

_out
