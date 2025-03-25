/// @description Insert description here
// You can write your code in this editor

alarm[1]=5*room_speed;

var connectionStatus;

if(!sio_get_connection_status()){
	connectionStatus = "We're NOT connected to the server!";	
}
else {
	connectionStatus = "We're connected to the server!";
}

show_debug_message(connectionStatus);









