/// gmcallback_sio_on_change_turn()
/// @descr Получение данных о смене хода от сервера
function gmcallback_sio_on_change_turn() {
    var json_data = json_decode(argument0);  // Декодируем полученные данные

    if (!json_data) {
        add_log("Error: Failed to decode player turn data");
        return;
    }

    global.playerTurn = real(json_data[? "playerTurn"]);  // Обновляем переменную playerTurn
    add_log("Player turn updated: " + string(global.playerTurn));
}