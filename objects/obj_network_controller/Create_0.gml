
//sio_init();

browser_input_capture(true);

alarm[0]=10*room_speed;	//ping
alarm[1]=5*room_speed;

global.logger = instance_create_depth(0,0,depth,obj_debug_console);
