function sio_emit_get_players_list() {
    sio_emit("get_players_list", ""); // Emit an event to the server to fetch the players list
}