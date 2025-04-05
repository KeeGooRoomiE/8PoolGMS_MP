/// @description Insert description here
// You can write your code in this editor


#region --- Base object settings

direction = 0;
speed = 0;
friction = 0.08;
depth = -1;
image_speed = 0;

#endregion

#region --- Ball setups

isSelected = false;
angular_speed = 0; 
rotation_friction = 0.02; 
angular_friction = 0.96; 
vert_angle = 0;
ballId = 0;				//unique local iq
ballType = 0;			//0 - undef, 1- white, 2 - normal filled, 3 - normal stripped, 4 - black 
ballMass = 1;			//physics calculations 
ballSize = 64;

#endregion

vx = 0;
vy = 0;

#region --- Setups values

cursor_angle = 0;				//ball-to-mouse angle
stick_base_dist = 64;			//distance between ball and stick
stick_angle = 0;				//stick-to-ball angle
stick_lerp_diff = 6;			//lerping angle difference
lerp_stick_angle = 0;			//lerping middleware angle
self_contact_mod = 0.76;		//modificator for decreasing self speed after ball contact
other_contact_mod = 0.96;		//modificator for decreasing other speed after ball contact
solid_contact_mod = 0.81;		//modificator for decreasing self speed after wall contact


#endregion
