/// @description Insert description here
// You can write your code in this editor

var dir = point_direction(x, y, other.x, other.y);

other.speed = speed*.81;
speed = speed*.81
other.direction = dir;

var dir_o = point_direction(other.x,other.y,x,y);
move_outside_all(dir_o,1);


// Массы одинаковые (1), но можно добавить массу, если понадобится
var mass = 1;
var mass_other = 1;

// Разложим скорости на компоненты
var vx1 = lengthdir_x(speed, direction);
var vy1 = lengthdir_y(speed, direction);
var vx2 = lengthdir_x(other.speed, other.direction);
var vy2 = lengthdir_y(other.speed, other.direction);

// Найдём разность скоростей
var dvx = vx2 - vx1;
var dvy = vy2 - vy1;

// Проверим, движутся ли шары друг к другу
if (dvx * (other.x - x) + dvy * (other.y - y) < 0) {
    // Рассчитаем проекцию скорости на линию столкновения
    var impact = dcos(dir) * dvx + dsin(dir) * dvy;

    if (impact > 0) {
        // Расчёт новой скорости после столкновения
        var impulse = (2 * impact) / (mass + mass_other);

        vx1 += impulse * mass_other * dcos(dir);
        vy1 += impulse * mass_other * dsin(dir);
        vx2 -= impulse * mass * dcos(dir);
        vy2 -= impulse * mass * dsin(dir);

        // Обновляем скорости и направления
        speed = point_distance(0, 0, vx1, vy1);
        direction = point_direction(0, 0, vx1, vy1);

        other.speed = point_distance(0, 0, vx2, vy2);
        other.direction = point_direction(0, 0, vx2, vy2);

        // Двигаем шары чуть-чуть, чтобы они не застряли друг в друге
        move_outside_all(direction, 1);
        other.move_outside_all(other.direction, 1);
    }
}

// Разница в углах и импульс скольжения
var spin = (other.speed - speed) * 0.2;
angular_speed -= spin;
other.angular_speed += spin;






