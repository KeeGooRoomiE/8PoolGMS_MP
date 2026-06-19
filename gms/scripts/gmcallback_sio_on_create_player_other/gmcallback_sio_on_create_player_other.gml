function gmcallback_sio_on_create_player_other() {
	/// gml_Script_gmcallback_sio_on_create_player_other(data)
	/// @descr Adding another player to the game

	var json_data = json_decode(argument0);
	if (!json_data) {
		add_log("Error: Failed to decode JSON data");
		return;
	}

	// Check if the "player" key exists
	var player_info = json_data[? "player"];
	if (!player_info) {
		add_log("Error: 'player' data not found");
		return;
	}

	add_log("ADD Player: " + json_encode(player_info));

	// Ensure required keys exist in player_info
	if (!ds_map_exists(player_info, "id")) player_info[? "id"] = "";
	if (!ds_map_exists(player_info, "username")) player_info[? "username"] = "Unknown";
	if (!ds_map_exists(player_info, "turnOrder")) player_info[? "turnOrder"] = 0; // Default = 0

	// Initialize playersList if it doesn't exist
	if (!variable_global_exists("playersList")) {
        global.playersList = [];  // Initialize as an empty array
    }
	
	// Ensure playersList is an array
	if (!is_array(global.playersList)) {
		global.playersList = array_create(2); // Create array with 2 slots
	}
	
	// Ensure global.playersCount exists
    if (!variable_global_exists("playersCount")) {
        global.playersCount = 1; // Default count to 1 if not already set
    }

	// Ensure playersCount is a number and within valid range
	global.playersCount = real(player_info[? "turnOrder"]); // Convert to number

	// Check if index is within bounds
	if (global.playersCount < 0 || global.playersCount >= array_length(global.playersList)) {
		add_log("Error: Index out of bounds. Resizing playersList...");
		array_resize(global.playersList, global.playersCount + 1); // Resize array if needed
	}

	// Store player ID
	global.playersList[global.playersCount] = player_info[? "id"];
}