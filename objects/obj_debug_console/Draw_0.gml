/// @description Insert description here
// You can write your code in this editor
depth = -9999;

draw_set_halign(fa_center);

for (var i = 0; i< max_delay; i++)
{
	draw_text_ext_color(room_width/2,0+i*24,string(log[log_count-i]),48,640,c_white,c_white,c_white,c_white,1-(0.05*i));
}



