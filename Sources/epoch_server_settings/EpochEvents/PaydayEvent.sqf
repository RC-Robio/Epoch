/*
    Give everyone on the server 100 Crypto.
	by Aaron Clark - EpochMod.com

	Improvements and or bugfixes and other contributions are welcome via the github:
	https://github.com/EpochModTeam/Epoch/tree/release/Sources/epoch_server_settings/EpochEvents/PaydayEvent.sqf
*/

{[_x,100] call EPOCH_server_effectCrypto;} forEach allPlayers;
