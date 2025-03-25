/// sio_init()
function sio_init() {
    gml_pragma("global", "sio_init()");
	global.logger = noone;

    show_debug_message("INIT Socket.io global");
    
    #region macros
    //#macro URL "45.93.20.5:3003" // Изменён порт на 3003
	#macro URL "localhost:3003" // Изменён порт на 3003
    #endregion

    #region SocketIO
    sio_connect_by_url(URL);
    show_debug_message("UPD Socket.io connecting by url");

    // Проверяем подключение через небольшую задержку (можно использовать alarm)
    //alarm[0] = room_speed * 1; // 1 секунда перед повторной проверкой
    #endregion

    #region SocketIO:Events
    sio_addEvent("create_player");
    sio_addEvent("create_player_other");
    sio_addEvent("destroy_player");
    //sio_addEvent("position_update"); // Добавлено
    //sio_addEvent("apply_force");     // Добавлено
    //sio_addEvent("create_ball");     // Добавлено
	sio_addEvent("change_turn");
	sio_addEvent("change_dir");
	sio_addEvent("get_players_list");
    show_debug_message("UPD Socket.io sending events list");
    #endregion
}
