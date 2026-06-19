extends Node2D

# Standard 8-ball rack (triangle tip at ~900px, centre at y=360)
const BALL_SPAWN_POSITIONS: Array[Vector2] = [
	# Row 1 (front tip)
	Vector2(900, 360),
	# Row 2
	Vector2(955, 332), Vector2(955, 388),
	# Row 3
	Vector2(1010, 304), Vector2(1010, 360), Vector2(1010, 416),
	# Row 4
	Vector2(1065, 276), Vector2(1065, 332), Vector2(1065, 388), Vector2(1065, 444),
	# Row 5 (back)
	Vector2(1120, 248), Vector2(1120, 304), Vector2(1120, 360), Vector2(1120, 416), Vector2(1120, 472),
]

# ball_id → ball_type  (standard rack: 8-ball in centre of rack = index 4 = position row3-centre)
const BALL_TYPE_MAP: Dictionary = {
	0: 1,   # white
	1: 2,  2: 3,  3: 2,  4: 3,   # row 1-2
	5: 2,  6: 4,  7: 3,           # row 3 (6 = 8-ball)
	8: 2,  9: 3,  10: 2,          # row 4
	11: 3, 12: 2, 13: 3, 14: 2, 15: 3,  # row 5
}

const WHITE_BALL_SPAWN := Vector2(320.0, 360.0)

@onready var balls_container: Node2D = $Balls
@onready var cue: Node2D = $Cue
@onready var hud_turn_label: Label = $HUD/TurnLabel
@onready var hud_players: VBoxContainer = $HUD/PlayersContainer
@onready var connection_panel: Control = $HUD/ConnectionPanel
@onready var server_url_edit: LineEdit = $HUD/ConnectionPanel/VBox/ServerUrlEdit
@onready var connect_button: Button = $HUD/ConnectionPanel/VBox/ConnectButton
@onready var status_label: Label = $HUD/ConnectionPanel/VBox/StatusLabel
@onready var stop_timer: Timer = $AllBallsStoppedTimer

var _ball_scene: PackedScene = preload("res://scenes/ball/ball.tscn")
var _waiting_for_balls_stop: bool = false
var _sync_tick: int = 0

# ---------------------------------------------------------------------------
func _ready() -> void:
	GameState.turn_changed.connect(_on_turn_changed)
	GameState.player_joined.connect(_on_player_joined)
	GameState.player_left.connect(_on_player_left)
	NetworkManager.connected_to_server.connect(_on_connected_to_server)

	stop_timer.timeout.connect(_on_stop_timer_timeout)
	stop_timer.one_shot = true
	stop_timer.wait_time = 0.6

	connection_panel.show()
	connect_button.pressed.connect(_on_connect_pressed)
	NetworkManager.connection_failed.connect(func(): status_label.text = "Connection failed!")
	NetworkManager.server_disconnected.connect(func(): status_label.text = "Server disconnected!")

func _on_connect_pressed() -> void:
	var url := server_url_edit.text.strip_edges()
	if url.is_empty():
		url = "ws://localhost:7777"
	status_label.text = "Connecting..."
	connect_button.disabled = true
	NetworkManager.connect_to_server(url)

func _physics_process(_delta: float) -> void:
	_handle_input()
	_check_balls_stopped()
	_server_sync_balls()

# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

func _handle_input() -> void:
	if not GameState.can_local_player_move:
		return

	if Input.is_action_just_pressed("click"):
		_try_select_white_ball()

	if Input.is_action_just_released("click") and cue.is_aiming:
		cue.shoot()
		GameState.can_local_player_move = false
		_waiting_for_balls_stop = true

	if Input.is_action_just_pressed("right_click"):
		cue.cancel()

func _try_select_white_ball() -> void:
	var mouse_pos := get_global_mouse_position()
	for ball in get_tree().get_nodes_in_group("balls"):
		if ball.ball_type != 1:
			continue
		if ball.global_position.distance_to(mouse_pos) <= ball.RADIUS and not ball.is_moving():
			cue.aim_at(ball)
			return

# ---------------------------------------------------------------------------
# Ball stop detection
# ---------------------------------------------------------------------------

func _check_balls_stopped() -> void:
	if not _waiting_for_balls_stop:
		return
	var any_moving := false
	for ball in get_tree().get_nodes_in_group("balls"):
		if ball.is_moving():
			any_moving = true
			break
	if not any_moving:
		_waiting_for_balls_stop = false
		stop_timer.start()

func _on_stop_timer_timeout() -> void:
	# Client tells server all balls have stopped → server advances turn
	NetworkManager.rpc_report_balls_stopped.rpc_id(1)

# ---------------------------------------------------------------------------
# Server: spawn balls (only runs on the server)
# ---------------------------------------------------------------------------

func spawn_balls() -> void:
	assert(multiplayer.is_server(), "spawn_balls() must run on server only")

	# White ball
	_spawn_ball(0, WHITE_BALL_SPAWN)

	# Rack balls 1-15
	for i in range(1, 16):
		_spawn_ball(i, BALL_SPAWN_POSITIONS[i - 1])

func _spawn_ball(ball_id: int, spawn_pos: Vector2) -> void:
	var ball: RigidBody2D = _ball_scene.instantiate()
	ball.ball_id = ball_id
	ball.ball_type = BALL_TYPE_MAP.get(ball_id, 2)
	ball.name = "Ball_%d" % ball_id
	ball.position = spawn_pos
	balls_container.add_child(ball, true)  # true = use node name as network sync key

# ---------------------------------------------------------------------------
# Server: periodic ball state broadcast to all clients (~20 Hz)
# ---------------------------------------------------------------------------

func _server_sync_balls() -> void:
	if not multiplayer.is_server():
		return
	_sync_tick += 1
	if _sync_tick % 3 != 0:   # every 3 physics frames ≈ 20 Hz at 60 Hz
		return
	for ball in get_tree().get_nodes_in_group("balls"):
		if ball.is_moving():
			NetworkManager.rpc_sync_ball.rpc(
				ball.ball_id, ball.position, ball.linear_velocity, ball.angular_velocity
			)

# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_connected_to_server() -> void:
	connection_panel.hide()
	_refresh_hud_players()

func _on_turn_changed(active_player_id: int) -> void:
	if active_player_id == GameState.local_player_id:
		hud_turn_label.text = "Your Turn!"
		hud_turn_label.modulate = Color.GREEN
	else:
		hud_turn_label.text = "Player %d's turn" % active_player_id
		hud_turn_label.modulate = Color.WHITE
	_refresh_hud_players()

func _on_player_joined(_id: int) -> void:
	_refresh_hud_players()
	# Server starts the game when 2 players are connected
	if multiplayer.is_server() and GameState.players_list.size() == 2:
		spawn_balls()
		NetworkManager.rpc_set_turn.rpc(0)

func _on_player_left(_id: int) -> void:
	_refresh_hud_players()

func _refresh_hud_players() -> void:
	for child in hud_players.get_children():
		child.queue_free()
	for i in range(GameState.players_list.size()):
		var pid := GameState.players_list[i]
		var lbl := Label.new()
		lbl.text = "P%d: %s%s" % [
			i + 1,
			"You" if pid == GameState.local_player_id else str(pid),
			" ◀" if i == GameState.player_turn else "",
		]
		lbl.modulate = Color.YELLOW if i == GameState.player_turn else Color.WHITE
		hud_players.add_child(lbl)
