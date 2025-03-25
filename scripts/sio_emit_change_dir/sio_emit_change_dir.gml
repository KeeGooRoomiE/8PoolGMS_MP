/// sio_emit_change_dir()
/// @descr Отправка данных о смене направления на сервер
function sio_emit_change_dir() {
    var data = ds_map_create();
    data[? "playerDirection"] = global.playerDirection;  // Допустим, у нас есть глобальная переменная playerDirection

    sio_emit("change_dir", json_encode(data));  // Отправка данных на сервер
    ds_map_destroy(data);
}