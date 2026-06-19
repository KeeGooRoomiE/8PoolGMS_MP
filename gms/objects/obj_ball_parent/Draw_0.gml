/// @description Draw ball layers

//Shadow layer
draw_sprite(spr_ball_shadow,0,x,y);

//Base layer
draw_self();

//Stripe layer
var stripe_angle = (vert_angle*0.81)/100;
	draw_sprite_ext(spr_ball_stripe,stripe_angle,x,y,1,1,image_angle,image_blend,1);

//Selection layer
if (isSelected)
{	
	cursor_angle = point_direction(mouse_x, mouse_y, x, y);
	stick_angle = point_direction(x,y,mouse_x, mouse_y);
	var dist = point_distance(x,y,mouse_x, mouse_y)/4;
	var xx = x + lengthdir_x(stick_base_dist+dist, cursor_angle);
	var yy = y + lengthdir_y(stick_base_dist+dist, cursor_angle);
	
	//Cursor pointer
	draw_line_width_color(x,y,mouse_x,mouse_y,1,c_blue,c_blue);
	draw_circle_color(mouse_x,mouse_y,24,c_blue,c_blue,1);
	
	//Stick drawing
	draw_sprite_ext(spr_stick_pro,0,xx,yy,1,1,stick_angle,c_white,1);
	var adiff = angle_difference(global.playerDirection, stick_angle);
	//Send data
	if ( abs(adiff) > stick_lerp_diff)
	{
	    global.playerDirection = stick_angle;
	    sio_emit_change_dir(); 
	}
}
else
{
	if (global.controllingBall == id)
	{
		if (speed == 0)
		{
			//Draw stick from external data
			var _diff = angle_difference(global.playerDirection, _diff);
			lerp_stick_angle += _diff * 0.1;
			var xx = x + lengthdir_x(-stick_base_dist, lerp_stick_angle);
			var yy = y + lengthdir_y(-stick_base_dist, lerp_stick_angle);
			draw_sprite_ext(spr_stick_pro,0,xx,yy,1,1,lerp_stick_angle,c_white,1);
		}
	}
	
}


// DEBUG  Draw vector motion line
if (speed > 0)
{
	draw_line_width_color(x,y,x+lengthdir_x(speed+32,direction),y+lengthdir_y(speed+32,direction),1,c_white,c_white);
}





