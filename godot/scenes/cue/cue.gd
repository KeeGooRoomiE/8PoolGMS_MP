extends Node2D

const MAX_FORCE   := 550.0
const CUE_OFFSET  := 36.0    # расстояние от центра шара до торца кия
const FORCE_SCALE := 6.0     # px мышки → единицы силы
const CUE_LENGTH  := 200.0
const CUE_WIDTH   := 7.0

@onready var aim_line: Line2D = $AimLine

var target_ball: RigidBody2D = null
var is_aiming: bool = false
var _shot_force: float = 0.0
var _shot_dir_deg: float = 0.0

# ---------------------------------------------------------------------------
func _ready() -> void:
	hide()

func aim_at(ball: RigidBody2D) -> void:
	target_ball = ball
	GameState.selected_ball = ball
	is_aiming = true
	show()
	ball.queue_redraw()

func cancel() -> void:
	if is_instance_valid(target_ball):
		target_ball.queue_redraw()
	target_ball = null
	GameState.selected_ball = null
	is_aiming = false
	aim_line.clear_points()
	hide()

# ---------------------------------------------------------------------------
func _process(_delta: float) -> void:
	if not is_aiming or not is_instance_valid(target_ball):
		return
	if not GameState.can_local_player_move:
		cancel()
		return

	var ball_pos  := target_ball.global_position
	var mouse_pos := get_global_mouse_position()

	_shot_dir_deg = rad_to_deg(ball_pos.angle_to_point(mouse_pos))
	var pull      := minf(ball_pos.distance_to(mouse_pos) / FORCE_SCALE, MAX_FORCE)
	_shot_force   = pull

	# Позиция и поворот кия
	var dir_vec := Vector2.from_angle(deg_to_rad(_shot_dir_deg))
	global_position = ball_pos + dir_vec * (CUE_OFFSET + pull * 0.12)
	rotation = deg_to_rad(_shot_dir_deg + 180.0)

	# Линия прицела
	aim_line.global_position = ball_pos
	aim_line.clear_points()
	aim_line.add_point(Vector2.ZERO)
	aim_line.add_point(-dir_vec * 320.0)

	queue_redraw()

func _draw() -> void:
	if not is_aiming:
		return
	# Кий: прямоугольник, сужается к концу
	var t := _shot_force / MAX_FORCE
	var tip_w := CUE_WIDTH * 0.35
	var col := Color(0.75, 0.55, 0.25).lerp(Color(1.0, 0.3, 0.1), t)

	# Рисуем трапецию как два треугольника (по локальным осям)
	var pts := PackedVector2Array([
		Vector2(0.0,       -tip_w * 0.5),
		Vector2(0.0,        tip_w * 0.5),
		Vector2(CUE_LENGTH, CUE_WIDTH * 0.5),
		Vector2(CUE_LENGTH, -CUE_WIDTH * 0.5),
	])
	draw_colored_polygon(pts, col)
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0, 0, 0, 0.4), 1.0)

# ---------------------------------------------------------------------------
func shoot() -> void:
	if not is_aiming or not is_instance_valid(target_ball):
		return

	if GameState.is_solo:
		# Офлайн: применяем силу напрямую
		target_ball.apply_shot(_shot_force, _shot_dir_deg)
	else:
		NetworkManager.rpc_request_shot.rpc_id(1, _shot_force, _shot_dir_deg, target_ball.ball_id)

	cancel()
