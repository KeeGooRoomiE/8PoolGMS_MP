/// @description Common behaviour
// You can write your code in this editor


function applyForce(force,dir)
{
	var isApplied = false;
	if (!isApplied)
	{
		speed = force;
		direction = dir;
		isApplied = true;
	}
}


if (isSelected)
{
	global.selectedBall = id;
}
else
{
	global.selectedBall = noone;
}

#region --- Overall ball behaviour

move_wrap(1,1,0); // --- Bring it back in case of OOB

	#region --- Vertical angular rotation 

	angular_speed *= (1 - rotation_friction); // Постепенно тормозим вращение


	var radius = sprite_width / 2; 
	var rotation_amount = (speed / (2 * radius)) * 360; 

	image_angle += rotation_amount;
	vert_angle += rotation_amount;

	angular_speed *= angular_friction; 

	#endregion

#endregion






