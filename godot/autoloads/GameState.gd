extends Node

# --- Mode ---
var is_solo: bool = false

# --- Player state ---
var players_list: Array[int] = []
var player_turn: int = 0
var local_player_id: int = -1
var can_local_player_move: bool = false

# --- Ball state ---
var selected_ball: RigidBody2D = null

# --- Game phase ---
enum Phase { LOBBY, WAITING_FOR_PLAYERS, PLAYING, GAME_OVER }
var phase: Phase = Phase.LOBBY

# --- Signals ---
signal turn_changed(active_player_id: int)
signal player_joined(player_id: int)
signal player_left(player_id: int)
signal phase_changed(new_phase: Phase)

# ---------------------------------------------------------------------------
func add_player(player_id: int) -> void:
	if player_id not in players_list:
		players_list.append(player_id)
	player_joined.emit(player_id)

func remove_player(player_id: int) -> void:
	players_list.erase(player_id)
	# Keep turn index in bounds
	if not players_list.is_empty():
		player_turn = player_turn % players_list.size()
	else:
		player_turn = 0
	player_left.emit(player_id)

func next_turn() -> void:
	if players_list.is_empty():
		return
	player_turn = (player_turn + 1) % players_list.size()
	_refresh_local_move_permission()
	turn_changed.emit(players_list[player_turn])

func set_turn(turn_index: int) -> void:
	if players_list.is_empty():
		return
	player_turn = clamp(turn_index, 0, players_list.size() - 1)
	_refresh_local_move_permission()
	turn_changed.emit(players_list[player_turn])

func is_local_turn() -> bool:
	if players_list.is_empty():
		return false
	return players_list[player_turn] == local_player_id

func current_player_id() -> int:
	if players_list.is_empty():
		return -1
	return players_list[player_turn]

func _refresh_local_move_permission() -> void:
	can_local_player_move = is_local_turn()

func set_phase(new_phase: Phase) -> void:
	phase = new_phase
	phase_changed.emit(new_phase)
