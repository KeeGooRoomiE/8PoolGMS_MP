/// @description Ball interactions

show_debug_message("Collision!");


#region --- Collisions v1 [NOT USED]

//var dir = point_direction(x, y, other.x, other.y);

//other.speed = speed*other_contact_mod;
////speed = speed*self_contact_mod;
//other.direction = dir;

//var dir_o = point_direction(other.x,other.y,x,y);
//move_outside_all(dir_o,1);


//// Разложим скорости на компоненты
//var vx1 = lengthdir_x(speed, direction);
//var vy1 = lengthdir_y(speed, direction);
//var vx2 = lengthdir_x(other.speed, other.direction);
//var vy2 = lengthdir_y(other.speed, other.direction);

//// Найдём разность скоростей
//var dvx = vx2 - vx1;
//var dvy = vy2 - vy1;

//// Проверим, движутся ли шары друг к другу
//if (dvx * (other.x - x) + dvy * (other.y - y) < 0) {
//    // Рассчитаем проекцию скорости на линию столкновения
//    var impact = dcos(dir) * dvx + dsin(dir) * dvy;

//    if (impact > 0) {
//        // Расчёт новой скорости после столкновения
//        var impulse = (2 * impact) / (ballMass + other.ballMass);

//        vx1 += impulse * other.ballMass * dcos(dir);
//        vy1 += impulse * other.ballMass * dsin(dir);
//        vx2 -= impulse * other.ballMass * dcos(dir);
//        vy2 -= impulse * other.ballMass * dsin(dir);

//        // Обновляем скорости и направления
//        speed = point_distance(0, 0, vx1, vy1);
//        direction = point_direction(0, 0, vx1, vy1);

//        other.speed = point_distance(0, 0, vx2, vy2);
//        other.direction = point_direction(0, 0, vx2, vy2);

//        // Двигаем шары чуть-чуть, чтобы они не застряли друг в друге
//        move_outside_all(direction, 1);
//        other.move_outside_all(other.direction, 1);
//    }
//}

#endregion
#region --- Collisions v2 [NOT USED]

/// Рассчёт столкновения двух шаров с передачей скорости

//var dx = other.x - x;
//var dy = other.y - y;
//var dist = sqrt(dx * dx + dy * dy);
//var min_dist = sprite_width; // Радиус шара

//if (dist < min_dist) { // Если шары пересеклись
//    var collision_angle = point_direction(x, y, other.x, other.y);
    
//    // Разложение скорости на компоненты
//    var v1x = lengthdir_x(speed, direction);
//    var v1y = lengthdir_y(speed, direction);
//    var v2x = lengthdir_x(other.speed, other.direction);
//    var v2y = lengthdir_y(other.speed, other.direction);

//    // Проекция скоростей на линию столкновения (массы считаем одинаковыми)
//    var v1p = v1x * dcos(collision_angle) + v1y * dsin(collision_angle);
//    var v2p = v2x * dcos(collision_angle) + v2y * dsin(collision_angle);

//    // Обмен импульсом
//    var temp = v1p;
//    v1p = v2p;
//    v2p = temp;

//    // Преобразуем обратно в векторы
//    v1x = v1p * dcos(collision_angle) + v1x * dcos(collision_angle + 90);
//    v1y = v1p * dsin(collision_angle) + v1y * dsin(collision_angle + 90);

//    v2x = v2p * dcos(collision_angle) + v2x * dcos(collision_angle + 90);
//    v2y = v2p * dsin(collision_angle) + v2y * dsin(collision_angle + 90);

//    // Применяем новые скорости
//    speed = sqrt(v1x * v1x + v1y * v1y);
//    direction = point_direction(0, 0, v1x, v1y);

//    other.speed = sqrt(v2x * v2x + v2y * v2y);
//    other.direction = point_direction(0, 0, v2x, v2y);
//}

#endregion

/// Обработка столкновения двух шаров
var dx = other.x - x;
var dy = other.y - y;
var dist = point_distance(x, y, other.x, other.y);

// Проверяем, что шары не застряли друг в друге
if (dist == 0) exit;

// 1️⃣ Нормализуем вектор столкновения
var nx = dx / dist;
var ny = dy / dist;

// 2️⃣ Проецируем скорости на нормаль (скалярное произведение)
var vA_n = vx * nx + vy * ny;
var vB_n = other.vx * nx + other.vy * ny;

// 3️⃣ Обмен нормальными компонентами скоростей
var vA_n_new = vB_n;
var vB_n_new = vA_n;

// 4️⃣ Пересчитываем скорости
vx += (vA_n_new - vA_n) * nx;
vy += (vA_n_new - vA_n) * ny;

other.vx += (vB_n_new - vB_n) * nx;
other.vy += (vB_n_new - vB_n) * ny;



// Кручение: передаём часть угловой скорости
var spin_transfer = (angular_speed - other.angular_speed) * 0.2;
angular_speed -= spin_transfer;
other.angular_speed += spin_transfer;



#region --- Angular difference spin

// Разница в углах и импульс скольжения
var spin = (other.speed - speed) * 0.2;
angular_speed -= spin;
other.angular_speed += spin;

#endregion






