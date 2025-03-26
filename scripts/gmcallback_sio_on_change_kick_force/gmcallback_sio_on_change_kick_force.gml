/// gmcallback_sio_on_change_kick_focre()
/// @descr Получение данных о смене направления от сервера
function gmcallback_sio_on_change_kick_force() {
    var json_data = json_decode(argument0);  // Декодируем полученные данные

    if (!json_data) {
        //sadd_log("Error: Failed to decode player direction data");
        return;
    }

    global.playerForce = real(json_data[? "kickForce"]);  // Обновляем переменную playerDirection
	if (global.controllingBall != 0)
	{
		global.controllingBall.applyForce(global.playerForce,global.playerDirection);
	}
    //add_log("Player direction updated: " + string(global.playerDirection));
}