/// sio_emit_create_player()
/// @descr Send player creation packet to the server
function sio_emit_create_player() {

	//if (!sio_get_connection_status()) 
	//{
	//    add_log("Create player emit | NO CONNECTION");
	//    return;
	//}
	
	show_debug_message("Create player emit | MAKING DATA");

	 var data = ds_map_create();
    data[? "username"] = "Player"; // Player's name
    data[? "turnOrder"] = global.playersCount; // Turn order based on current count

	
	sio_emit("create_player", json_encode(data)); // Отправка данных на сервер
	show_debug_message("Create player emit end | SENDING DATA");
	
	//global.playersCount++;
	ds_map_destroy(data);
}
