/// @description Insert description here
// You can write your code in this editor

if (isSelected)
{
	var dir = point_direction(x,y,mouse_x, mouse_y);
	var dist =point_distance(x,y,mouse_x, mouse_y)/8;
	
	// Ограничиваем силу удара
	var max_force = 50; // Максимальная скорость удара (можно настроить)
	if (dist > max_force) 
	{
	    dist = max_force;
	}
	
	applyForce(dist, dir);
	isSelected = false;
	var log = "UPD Player" +string(global.playerTurn)+ " | DIR: " +string(dir);
	global.playerTurn = !global.playerTurn;
	sio_emit_change_turn();
	sio_emit_change_dir();
	global.table.canLocalPlayerMakeMove = false;
	add_log(log);
}








