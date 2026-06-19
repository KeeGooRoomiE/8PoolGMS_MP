extends Area2D

@export var pocket_id: int = 0

const WHITE_BALL_SPAWN := Vector2(320.0, 360.0)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = 0
	collision_mask = 1   # balls are on layer 1

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("balls"):
		return
	# Only server decides what happens to pocketed balls
	if multiplayer.is_server():
		NetworkManager.rpc_ball_pocketed.rpc(body.ball_id, pocket_id)
