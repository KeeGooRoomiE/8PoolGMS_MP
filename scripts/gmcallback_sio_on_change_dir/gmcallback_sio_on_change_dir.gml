/// gmcallback_sio_on_change_dir()
/// @descr Получение данных о смене направления от сервера
function gmcallback_sio_on_change_dir() {
    var json_data = json_decode(argument0);  // Декодируем полученные данные

    if (!json_data) {
        //sadd_log("Error: Failed to decode player direction data");
        return;
    }

    global.playerDirection = real(json_data[? "playerDirection"]);  // Обновляем переменную playerDirection
    //add_log("Player direction updated: " + string(global.playerDirection));
}