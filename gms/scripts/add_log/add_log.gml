// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function add_log(argument0)
{
	if (instance_exists(global.logger))
	{
		global.logger.add_log(argument0);
	} 
	else
	{
		show_debug_message("!!!LOGGER NOT LOADED!!!");
		show_debug_message(argument0);
		global.logger = instance_create_depth(0,0,-9999,obj_debug_console);
	}
}