/// @description Insert description here
// You can write your code in this editor

draw_sprite(spr_ball_shadow,0,x,y);

draw_self();
//draw_sprite(spr_ball_high,0,x,y);
//draw_sprite(spr_ball_basic_highlight,0,x,y);
var stripe_angle = (vert_angle*0.81)/100;
	draw_sprite_ext(spr_ball_stripe,stripe_angle,x,y,1,1,image_angle,image_blend,1);
//image_angle = direction;

if (isSelected)
{
	//image_blend = c_blue;
	//draw_line(x,y,mouse_x,mouse_y);
	//draw_line(x,y,mouse_x,mouse_y);
	//var dist = point_distance(x,y,mouse_x, mouse_y)/32;
	
	var angle = point_direction(mouse_x, mouse_y, x, y);
	var stick_angle = point_direction(x,y,mouse_x, mouse_y);
	var dist = point_distance(x,y,mouse_x, mouse_y)/4;
	var xx = x + lengthdir_x(50+dist, angle);
	var yy = y + lengthdir_y(50+dist, angle);
	//var xxx = x + lengthdir_x(300+dist, angle);
	//var yyy = y + lengthdir_y(300+dist, angle);
	draw_line_width_color(x,y,mouse_x,mouse_y,1,c_blue,c_blue);
	draw_circle_color(mouse_x,mouse_y,24,c_blue,c_blue,1);
	
	draw_sprite_ext(spr_stick_pro,0,xx,yy,1,1,stick_angle,c_white,1);
	//global.playerDirection = stick_angle;
	// Разница между текущим и предыдущим углом
	var adiff = angle_difference(global.playerDirection, stick_angle);
	draw_text(330,330,"ADIFF: "+string(adiff));
	if ( abs(adiff) > 5)
	{
	    global.playerDirection = stick_angle;
	    sio_emit_change_dir();  // Отправляем изменение направления
	}

	//global.table.player_force[global.playerTurn] = dist;

	//draw_text(mouse_x,mouse_y,string(dist) );
}
else
{
	image_blend = c_white;
	//var xx = x + lengthdir_x(50+dist, global.playerDirection);
	//var yy = y + lengthdir_y(50+dist,  global.playerDirection);
	
	var _dir = global.playerDirection;
	var _diff = angle_difference(_dir, lerp_stick_angle);
	lerp_stick_angle += _diff * 0.1;
	draw_sprite_ext(spr_stick_pro,0,room_width/2,room_height/2,1,1,lerp_stick_angle,c_white,1);
}


if (speed > 0)
{
	draw_line_width_color(x,y,x+lengthdir_x(speed+32,direction),y+lengthdir_y(speed+32,direction),1,c_white,c_white);
}





