function gmcallback_sio_on_create_player() {
	var json_data = json_decode(argument0);
	var player_info = json_decode(json_data[? "player"]); // Fix: Double JSON decode

	add_log("// Player created: " + json_encode(player_info));

	if (!variable_global_exists("playersList")) {
        global.playersList = 0;
    }

// Ensure global.playersCount exists
    if (!variable_global_exists("playersCount")) {
        global.playersCount = 0;
    }
	if (!variable_global_exists("localPlayerId")) {
        global.localPlayerId = 0;
    }
	// Save data to global variables
	 if (!is_array(global.playersList)) {
        global.playersList = []; 
		global.playersCount = 0;
    }
	global.playersList[global.playersCount] = player_info[? "id"];
	global.localPlayerId = player_info[? "id"];
}