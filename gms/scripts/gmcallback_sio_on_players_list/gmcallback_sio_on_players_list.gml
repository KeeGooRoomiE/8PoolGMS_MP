/// gmcallback_sio_on_players_list()
/// @descr Receive and update the player list from the server
function gmcallback_sio_on_players_list() {
    var json_data = json_decode(argument0); // Decode the JSON data from the server

    if (!json_data) {
        add_log("Error: Failed to decode players list data");
        return;
    }

    var players = json_data[? "players"]; // Get the players array from the data
    global.playersCount = real(json_data[? "playerCount"]); // Set the player count

    // Clear the old player list
    global.playersList = [];

    // Update global.playerList with the new player data
    for (var i = 0; i < array_length(players); i++) {
        global.playersList[i] = players[i].id; // Add player ID to the list
    }

    // Log the updated player list
    add_log("Updated player list: " + string(global.playersList));
}