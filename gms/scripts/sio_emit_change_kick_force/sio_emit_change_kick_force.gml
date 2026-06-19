/// sio_emit_change_kick_force()
/// @descr Отправка данных о смене направления на сервер
function sio_emit_change_kick_force() {
    var data = ds_map_create();
    data[? "kickForce"] = global.playerForce;  // Допустим, у нас есть глобальная переменная playerDirection

    sio_emit("change_kick_force", json_encode(data));  // Отправка данных на сервер
    ds_map_destroy(data);
}