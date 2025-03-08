/// @description Insert description here
// You can write your code in this editor

draw_self();
draw_sprite(spr_ball_basic_highlight,0,x,y);
image_index = (vert_angle*0.81)/12;
//image_angle = direction;

if (isSelected)
{
	//image_blend = c_blue;
	//draw_line(x,y,mouse_x,mouse_y);
	//draw_line(x,y,mouse_x,mouse_y);
	//var dist = point_distance(x,y,mouse_x, mouse_y)/32;
	
	var angle = point_direction(mouse_x, mouse_y, x, y);
	var dist = point_distance(x,y,mouse_x, mouse_y)/8;
	var xx = x + lengthdir_x(50+dist, angle);
	var yy = y + lengthdir_y(50+dist, angle);
	var xxx = x + lengthdir_x(300+dist, angle);
	var yyy = y + lengthdir_y(300+dist, angle);
	draw_line_width_color(xx,yy,xxx,yyy,8,c_blue,c_blue);

	//draw_text(mouse_x,mouse_y,string(dist) );
}
else
{
	image_blend = c_white;
}


if (speed > 0)
{
	draw_line_width_color(x,y,x+lengthdir_x(speed+32,direction),y+lengthdir_y(speed+32,direction),1,c_white,c_white);
}





