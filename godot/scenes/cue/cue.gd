extends Node2D

const MAX_FORCE := 600.0
const CUE_OFFSET := 80.0    # px from ball center to cue base
const FORCE_SCALE := 8.0    # mouse distance → force

@onready var sprite: Sprite2D = $Sprite2D
@onready var aim_line: Line2D = $AimLine
@onready var force_bar: TextureProgressBar = $ForceBar

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
	if target_ball:
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

	var ball_pos := target_ball.global_position
	var mouse_pos := get_global_mouse_position()

	# Direction: from mouse toward ball (pull-back mechanic)
	_shot_dir_deg = rad_to_deg(ball_pos.angle_to_point(mouse_pos))
	var pull_dist := minf(ball_pos.distance_to(mouse_pos) / FORCE_SCALE, MAX_FORCE)
	_shot_force = pull_dist

	# Position and rotate the cue stick
	var dir_vec := Vector2.from_angle(deg_to_rad(_shot_dir_deg))
	global_position = ball_pos + dir_vec * (CUE_OFFSET + pull_dist * 0.15)
	rotation = deg_to_rad(_shot_dir_deg + 180.0)

	# Aim guide line (trajectory hint)
	var aim_dir := -dir_vec  # direction ball will travel
	aim_line.global_position = ball_pos
	aim_line.clear_points()
	aim_line.add_point(Vector2.ZERO)
	aim_line.add_point(aim_dir * 250.0)

	# Force indicator
	force_bar.value = _shot_force / MAX_FORCE * 100.0
	sprite.modulate = Color(1.0, 1.0 - (_shot_force / MAX_FORCE) * 0.85, 0.2)

# Called by table_controller on mouse release
func shoot() -> void:
	if not is_aiming or not is_instance_valid(target_ball):
		return
	NetworkManager.rpc_request_shot.rpc_id(1, _shot_force, _shot_dir_deg, target_ball.ball_id)
	cancel()
