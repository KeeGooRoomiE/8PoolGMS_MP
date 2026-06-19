extends Node2D

# Стандартный треугольник — 15 шаров (ball_id 1..15)
const RACK: Array[Vector2] = [
	Vector2(860, 360),
	Vector2(915, 332), Vector2(915, 388),
	Vector2(970, 304), Vector2(970, 360), Vector2(970, 416),
	Vector2(1025, 276), Vector2(1025, 332), Vector2(1025, 388), Vector2(1025, 444),
	Vector2(1080, 248), Vector2(1080, 304), Vector2(1080, 360), Vector2(1080, 416), Vector2(1080, 472),
]

# ball_id → ball_type: 2=солид, 3=страйп, 4=восьмёрка
const BALL_TYPE_MAP: Dictionary = {
	1:2, 2:3, 3:2, 4:3, 5:2,
	6:4,                        # 8-ball в центре треугольника (позиция 5)
	7:3, 8:2, 9:3, 10:2,
	11:3, 12:2, 13:3, 14:2, 15:3,
}
const WHITE_SPAWN := Vector2(320.0, 360.0)

# Ноды
@onready var balls_node:    Node2D          = $Balls
@onready var cue:           Node2D          = $Cue
@onready var stop_timer:    Timer           = $AllBallsStoppedTimer
@onready var turn_label:    Label           = $HUD/TurnLabel
@onready var players_vbox:  VBoxContainer   = $HUD/PlayersContainer
@onready var conn_panel:    Control         = $HUD/ConnectionPanel
@onready var url_edit:      LineEdit        = $HUD/ConnectionPanel/VBox/ServerUrlEdit
@onready var btn_connect:   Button          = $HUD/ConnectionPanel/VBox/BtnConnect
@onready var btn_solo:      Button          = $HUD/ConnectionPanel/VBox/BtnSolo
@onready var status_lbl:    Label           = $HUD/ConnectionPanel/VBox/StatusLabel

var _ball_scene: PackedScene = preload("res://scenes/ball/ball.tscn")
var _waiting_stop: bool = false
var _sync_tick: int = 0

# ---------------------------------------------------------------------------
func _ready() -> void:
	GameState.turn_changed.connect(_on_turn_changed)
	GameState.player_joined.connect(_on_player_joined)
	GameState.player_left.connect(_on_player_left)
	NetworkManager.connected_to_server.connect(_on_net_connected)
	NetworkManager.connection_failed.connect(func():
		status_lbl.text = "Не удалось подключиться"
		btn_connect.disabled = false
	)

	stop_timer.one_shot = true
	stop_timer.wait_time = 0.7
	stop_timer.timeout.connect(_on_stop_timer)

	btn_connect.pressed.connect(_on_connect_pressed)
	btn_solo.pressed.connect(_on_solo_pressed)
	conn_panel.show()

	# Подключаем Area2D луз к обработчику
	for pocket in $Pockets.get_children():
		if pocket is Area2D:
			pocket.body_entered.connect(_on_ball_pocketed.bind(pocket))

# ---------------------------------------------------------------------------
# Ввод
# ---------------------------------------------------------------------------

func _physics_process(_delta: float) -> void:
	if GameState.can_local_player_move:
		_handle_input()
	_check_balls_stopped()
	if not GameState.is_solo:
		_server_broadcast_balls()

func _handle_input() -> void:
	if Input.is_action_just_pressed("click"):
		_try_aim()
	if Input.is_action_just_released("click") and cue.is_aiming:
		cue.shoot()
		GameState.can_local_player_move = false
		_waiting_stop = true
	if Input.is_action_just_pressed("right_click"):
		cue.cancel()

func _try_aim() -> void:
	var mp := get_global_mouse_position()
	for ball in get_tree().get_nodes_in_group("balls"):
		if ball.ball_type == 1 and not ball.is_moving():
			if ball.global_position.distance_to(mp) <= ball.RADIUS + 8.0:
				cue.aim_at(ball)
				return

# ---------------------------------------------------------------------------
# Остановка шаров
# ---------------------------------------------------------------------------

func _check_balls_stopped() -> void:
	if not _waiting_stop:
		return
	for ball in get_tree().get_nodes_in_group("balls"):
		if ball.is_moving():
			return
	_waiting_stop = false
	stop_timer.start()

func _on_stop_timer() -> void:
	if GameState.is_solo:
		# В соло-режиме просто разрешаем следующий удар
		GameState.can_local_player_move = true
	else:
		NetworkManager.rpc_report_balls_stopped.rpc_id(1)

# ---------------------------------------------------------------------------
# Спавн
# ---------------------------------------------------------------------------

func _spawn_all_balls() -> void:
	for child in balls_node.get_children():
		child.queue_free()

	var white := _make_ball(0, WHITE_SPAWN, 1)
	balls_node.add_child(white)

	for i in range(1, 16):
		var b := _make_ball(i, RACK[i - 1], BALL_TYPE_MAP.get(i, 2))
		balls_node.add_child(b)

func _make_ball(bid: int, pos: Vector2, btype: int) -> RigidBody2D:
	var b: RigidBody2D = _ball_scene.instantiate()
	b.ball_id   = bid
	b.ball_type = btype
	b.name      = "Ball_%d" % bid
	b.position  = pos
	return b

# ---------------------------------------------------------------------------
# Луза
# ---------------------------------------------------------------------------

func _on_ball_pocketed(body: Node2D, pocket: Area2D) -> void:
	if not body.is_in_group("balls"):
		return
	if GameState.is_solo:
		body.on_pocketed(pocket.get_index())
	elif multiplayer.is_server():
		NetworkManager.rpc_ball_pocketed.rpc(body.ball_id, pocket.get_index())

# ---------------------------------------------------------------------------
# Синхронизация (только сервер, только сетевой режим)
# ---------------------------------------------------------------------------

func _server_broadcast_balls() -> void:
	if not multiplayer.is_server():
		return
	_sync_tick += 1
	if _sync_tick % 3 != 0:
		return
	for ball in get_tree().get_nodes_in_group("balls"):
		if ball.is_moving():
			NetworkManager.rpc_sync_ball.rpc(
				ball.ball_id, ball.position, ball.linear_velocity, ball.angular_velocity
			)

# ---------------------------------------------------------------------------
# Кнопки подключения
# ---------------------------------------------------------------------------

func _on_connect_pressed() -> void:
	var url := url_edit.text.strip_edges()
	if url.is_empty():
		url = "ws://localhost:7777"
	status_lbl.text = "Подключение..."
	btn_connect.disabled = true
	btn_solo.disabled = true
	NetworkManager.connect_to_server(url)

func _on_solo_pressed() -> void:
	GameState.is_solo = true
	GameState.local_player_id = 1
	GameState.add_player(1)
	GameState.can_local_player_move = true
	conn_panel.hide()
	_spawn_all_balls()
	turn_label.text = "Соло — твой ход!"
	turn_label.modulate = Color.GREEN

func _on_net_connected() -> void:
	conn_panel.hide()
	_refresh_hud()

# ---------------------------------------------------------------------------
# HUD
# ---------------------------------------------------------------------------

func _on_turn_changed(pid: int) -> void:
	if pid == GameState.local_player_id:
		turn_label.text = "Твой ход!"
		turn_label.modulate = Color.GREEN
	else:
		turn_label.text = "Ход игрока %d" % pid
		turn_label.modulate = Color.WHITE
	_refresh_hud()

func _on_player_joined(_id: int) -> void:
	_refresh_hud()
	if not GameState.is_solo and multiplayer.is_server() and GameState.players_list.size() == 2:
		_spawn_all_balls()
		NetworkManager.rpc_set_turn.rpc(0)

func _on_player_left(_id: int) -> void:
	_refresh_hud()

func _refresh_hud() -> void:
	for c in players_vbox.get_children():
		c.queue_free()
	for i in range(GameState.players_list.size()):
		var pid := GameState.players_list[i]
		var lbl := Label.new()
		var you := pid == GameState.local_player_id
		lbl.text = "P%d: %s%s" % [i + 1, "Ты" if you else str(pid),
								   " ◀" if i == GameState.player_turn else ""]
		lbl.modulate = Color.YELLOW if i == GameState.player_turn else Color.WHITE
		players_vbox.add_child(lbl)
