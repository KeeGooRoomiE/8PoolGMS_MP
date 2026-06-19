/// sio_emit_change_turn()
/// @descr Отправка данных о смене хода на сервер
function sio_emit_change_turn() {
    var data = ds_map_create();
    data[? "playerTurn"] = global.playerTurn;  // Допустим, у нас есть глобальная переменная playerTurn

    sio_emit("change_turn", json_encode(data));  // Отправка данных на сервер
    ds_map_destroy(data);
}