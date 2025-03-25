/// sio_emit_create_player()
/// @descr Send player creation packet to the server
function sio_emit_create_ball() {

	show_debug_message("// Отправка данных о создании игрока...");

	// Создаём JSON-объект с данными
	var data = ds_map_create();
	data[? "ball_type"] = ""; // Имя игрока
	
	sio_emit("create_ball", json_encode(data)); // Отправка данных на сервер
	
	ds_map_destroy(data);
	
	//sio_emit_request_players_list();
}
///home/ftpuser/scripts/gms_frontend/8-pool_gms/;