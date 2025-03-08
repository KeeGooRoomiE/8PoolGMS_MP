/// @description Insert description here
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
move_wrap(1,1,0);

//image_angle = angular_speed;//angle_difference(image_angle,direction)*angular_speed;
angular_speed *= (1 - rotation_friction); // Постепенно тормозим вращение


var radius = sprite_width / 2; 

// Рассчитываем пройденное расстояние (по сути, окружность)
var rotation_amount = (speed / (2 * radius)) * 360; 

// Применяем вращение
image_angle += rotation_amount;
vert_angle += rotation_amount;

// Плавное замедление вращения (трение)
angular_speed *= 0.9; // 0.96 - коэффициент трения, можно настроить под реализм



