extends Node

const DEFAULT_PORT := 7777
const MAX_PLAYERS := 4

var _peer: WebSocketMultiplayerPeer = null
var is_server: bool = false

# --- Signals (mirror of MultiplayerAPI events for external listeners) ---
signal connected_to_server()
signal connection_failed()
signal server_disconnected()
signal player_connected(id: int)
signal player_disconnected(id: int)

# ---------------------------------------------------------------------------
func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# --- Server startup (headless) ---
func start_server(port: int = DEFAULT_PORT) -> Error:
	_peer = WebSocketMultiplayerPeer.new()
	var err := _peer.create_server(port)
	if err != OK:
		push_error("[Network] Server start failed on port %d: %s" % [port, error_string(err)])
		return err
	multiplayer.multiplayer_peer = _peer
	is_server = true
	GameState.local_player_id = 1  # Server is always peer 1
	print("[Network] Server listening on port %d" % port)
	return OK

# --- Client connect (browser-safe WebSocket) ---
func connect_to_server(url: String) -> Error:
	_peer = WebSocketMultiplayerPeer.new()
	var err := _peer.create_client(url)
	if err != OK:
		push_error("[Network] Connect to %s failed: %s" % [url, error_string(err)])
		return err
	multiplayer.multiplayer_peer = _peer
	is_server = false
	print("[Network] Connecting to %s" % url)
	return OK

func disconnect_from_server() -> void:
	if _peer:
		_peer.close()
		_peer = null
	multiplayer.multiplayer_peer = null

# ---------------------------------------------------------------------------
# RPCs — naming convention: rpc_<verb>_<subject>
# ---------------------------------------------------------------------------

# Client → Server: request a shot
@rpc("any_peer", "reliable")
func rpc_request_shot(force: float, direction_deg: float, ball_id: int) -> void:
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	# Validate it's the current player's turn
	if sender_id != GameState.current_player_id():
		push_warning("[Network] Shot from wrong player %d (expected %d)" % [sender_id, GameState.current_player_id()])
		return
	# Apply authoritatively on all clients
	rpc_apply_shot.rpc(force, direction_deg, ball_id)

# Server → All: apply shot
@rpc("authority", "reliable", "call_local")
func rpc_apply_shot(force: float, direction_deg: float, ball_id: int) -> void:
	var ball := _find_ball(ball_id)
	if ball:
		ball.apply_shot(force, direction_deg)

# Server → All: change turn
@rpc("authority", "reliable", "call_local")
func rpc_set_turn(turn_index: int) -> void:
	GameState.set_turn(turn_index)

# Client → Server: signal that all balls stopped after turn
@rpc("any_peer", "reliable")
func rpc_report_balls_stopped() -> void:
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id != GameState.current_player_id():
		return
	var next_turn := (GameState.player_turn + 1) % GameState.players_list.size()
	rpc_set_turn.rpc(next_turn)

# Server → All: sync ball physics (unreliable, called every N frames)
@rpc("authority", "unreliable")
func rpc_sync_ball(ball_id: int, pos: Vector2, vel: Vector2, ang_vel: float) -> void:
	# Clients only — server is authoritative
	if multiplayer.is_server():
		return
	var ball := _find_ball(ball_id)
	if ball:
		ball.position = pos
		ball.linear_velocity = vel
		ball.angular_velocity = ang_vel

# Server → All: announce player joined
@rpc("authority", "reliable", "call_local")
func rpc_player_joined(player_id: int) -> void:
	GameState.add_player(player_id)

# Server → All: announce player left
@rpc("authority", "reliable", "call_local")
func rpc_player_left(player_id: int) -> void:
	GameState.remove_player(player_id)

# Server → All: ball pocketed
@rpc("authority", "reliable", "call_local")
func rpc_ball_pocketed(ball_id: int, pocket_id: int) -> void:
	var ball := _find_ball(ball_id)
	if ball:
		ball.on_pocketed(pocket_id)

# ---------------------------------------------------------------------------
# MultiplayerAPI callbacks
# ---------------------------------------------------------------------------

func _on_peer_connected(id: int) -> void:
	print("[Network] Peer connected: %d" % id)
	if multiplayer.is_server():
		# Tell the newcomer about all existing players first
		for existing_id in GameState.players_list:
			rpc_player_joined.rpc_id(id, existing_id)
		# Then announce the new player to everyone (including themselves)
		GameState.add_player(id)
		rpc_player_joined.rpc(id)
	player_connected.emit(id)

func _on_peer_disconnected(id: int) -> void:
	print("[Network] Peer disconnected: %d" % id)
	if multiplayer.is_server():
		GameState.remove_player(id)
		rpc_player_left.rpc(id)
	player_disconnected.emit(id)

func _on_connected_to_server() -> void:
	GameState.local_player_id = multiplayer.get_unique_id()
	print("[Network] Connected! My peer ID: %d" % GameState.local_player_id)
	connected_to_server.emit()

func _on_connection_failed() -> void:
	push_error("[Network] Connection failed!")
	connection_failed.emit()

func _on_server_disconnected() -> void:
	push_error("[Network] Server disconnected!")
	server_disconnected.emit()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _find_ball(ball_id: int) -> Node:
	for ball in get_tree().get_nodes_in_group("balls"):
		if ball.ball_id == ball_id:
			return ball
	return null
