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

const _POCKET_POSITIONS: Array[Vector2] = [
	Vector2(52, 72), Vector2(640, 54), Vector2(1228, 72),
	Vector2(52, 648), Vector2(640, 666), Vector2(1228, 648),
]

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

# Буфер событий за текущий ход (сбрасывается в _reset_turn_tracking)
var _turn_pocketed_types: Array[int] = []
var _turn_white_in: bool = false
var _turn_eight_in: bool = false

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

	# В браузере сервера нет — сразу запускаем соло
	if OS.get_name() == "Web":
		call_deferred("_on_solo_pressed")

	# Подключаем Area2D луз к обработчику
	for pocket in $Pockets.get_children():
		if pocket is Area2D:
			pocket.body_entered.connect(_on_ball_pocketed.bind(pocket))

	queue_redraw()

# ---------------------------------------------------------------------------
# Стол: бортики и лузы
# ---------------------------------------------------------------------------

func _draw() -> void:
	var bumper_col := Color(0.35, 0.22, 0.05)
	var pocket_col := Color(0.04, 0.04, 0.04)

	for pos in _POCKET_POSITIONS:
		draw_circle(pos, 30.0, pocket_col)

	draw_rect(Rect2(70,   54,  1140, 16), bumper_col)  # top
	draw_rect(Rect2(70,  650,  1140, 16), bumper_col)  # bottom
	draw_rect(Rect2(34,   50,    16, 620), bumper_col)  # left
	draw_rect(Rect2(1230,  50,   16, 620), bumper_col)  # right

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
	var pid := GameState.current_player_id()

	# --- Восьмёрка в лузе: конец игры ---
	if _turn_eight_in:
		if _turn_white_in or not GameState.can_pocket_eight(pid):
			_end_game_lose(pid)
		else:
			_end_game_win(pid)
		_reset_turn_tracking()
		return

	# --- Фол (белый в лузе без восьмёрки) ---
	if _turn_white_in:
		_show_toast("Фол!", Color(1.0, 0.35, 0.1))
		if GameState.is_solo:
			GameState.can_local_player_move = true
		else:
			GameState.next_turn()
			NetworkManager.rpc_set_turn.rpc(GameState.player_turn)
		_reset_turn_tracking()
		return

	# --- Назначаем группы при первом пополнении ---
	if not _turn_pocketed_types.is_empty() and not GameState.groups_assigned:
		GameState.assign_groups(_turn_pocketed_types[0], pid)

	# --- Продолжение / смена хода ---
	if not _turn_pocketed_types.is_empty():
		# Есть пополнение → продолжает тот же игрок
		if GameState.is_solo:
			GameState.can_local_player_move = true
		else:
			GameState.can_local_player_move = GameState.is_local_turn()
	else:
		# Нет пополнения → смена хода
		if GameState.is_solo:
			# В соло противника нет — просто даём следующий удар
			GameState.can_local_player_move = true
		else:
			GameState.next_turn()
			NetworkManager.rpc_set_turn.rpc(GameState.player_turn)

	_reset_turn_tracking()

func _reset_turn_tracking() -> void:
	_turn_pocketed_types.clear()
	_turn_white_in = false
	_turn_eight_in = false

# ---------------------------------------------------------------------------
# Конец игры
# ---------------------------------------------------------------------------

func _end_game_win(pid: int) -> void:
	GameState.can_local_player_move = false
	var is_local := pid == GameState.local_player_id
	_show_overlay(
		"Победа!" if is_local else "Игрок %d победил!" % pid,
		Color(0.2, 0.9, 0.3)
	)

func _end_game_lose(pid: int) -> void:
	GameState.can_local_player_move = false
	var is_local := pid == GameState.local_player_id
	_show_overlay(
		"Поражение!\n8-шар забит досрочно." if is_local else "Игрок %d проиграл!" % pid,
		Color(0.9, 0.2, 0.2)
	)

# ---------------------------------------------------------------------------
# HUD: тосты и оверлей конца игры
# ---------------------------------------------------------------------------

func _show_toast(text: String, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 30)
	lbl.modulate = color
	lbl.position = Vector2(560, 300)
	$HUD.add_child(lbl)
	var tween := create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.6)
	tween.tween_callback(lbl.queue_free)

func _show_overlay(text: String, color: Color) -> void:
	var vp := get_viewport().get_visible_rect().size

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.position = Vector2.ZERO
	bg.size = vp
	$HUD.add_child(bg)

	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 40)
	lbl.modulate = color
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.size = Vector2(600, 120)
	lbl.position = vp / 2.0 - Vector2(300, 90)
	$HUD.add_child(lbl)

	var btn := Button.new()
	btn.text = "Начать заново"
	btn.size = Vector2(240, 48)
	btn.position = vp / 2.0 - Vector2(120, -50)
	$HUD.add_child(btn)
	btn.pressed.connect(func():
		bg.queue_free()
		lbl.queue_free()
		btn.queue_free()
		_restart_game()
	)

func _restart_game() -> void:
	GameState.reset_rules()
	_reset_turn_tracking()
	GameState.can_local_player_move = true
	_spawn_all_balls()

# ---------------------------------------------------------------------------
# Спавн
# ---------------------------------------------------------------------------

func _spawn_all_balls() -> void:
	for child in balls_node.get_children():
		child.queue_free()

	GameState.reset_rules()
	_reset_turn_tracking()

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

	# Физика: скрыть/респавн шара
	if GameState.is_solo:
		body.on_pocketed(pocket.get_index())
	elif multiplayer.is_server():
		NetworkManager.rpc_ball_pocketed.rpc(body.ball_id, pocket.get_index())

	# Учёт для правил текущего хода
	match body.ball_type:
		1:  # белый
			_turn_white_in = true
		4:  # восьмёрка
			_turn_eight_in = true
		_:  # солид или страйп
			_turn_pocketed_types.append(body.ball_type)
			GameState.pocketed_by_type[body.ball_type] = \
				GameState.pocketed_by_type.get(body.ball_type, 0) + 1

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
	turn_label.hide()
	players_vbox.hide()
	_spawn_all_balls()

func _on_net_connected() -> void:
	conn_panel.hide()
	_refresh_hud()

# ---------------------------------------------------------------------------
# HUD (мультиплеер)
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
