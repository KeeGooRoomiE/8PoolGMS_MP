extends RigidBody2D

# --- Config (set in editor or via spawn) ---
@export var ball_id: int = 0
## 0=undefined  1=white  2=solid  3=stripe  4=black
@export var ball_type: int = 0
@export var ball_color: Color = Color.WHITE

const RADIUS := 32.0
const STOP_THRESHOLD := 8.0   # px/s — velocity below this snaps to zero

@onready var sprite_shadow: Sprite2D = $SpriteShadow
@onready var sprite_base: Sprite2D = $SpriteBase
@onready var sprite_stripe: Sprite2D = $SpriteStripe
@onready var sprite_highlight: Sprite2D = $SpriteHighlight
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _pocketed: bool = false

# ---------------------------------------------------------------------------
func _ready() -> void:
	add_to_group("balls")
	gravity_scale = 0.0
	linear_damp = 0.9
	angular_damp = 2.0
	contact_monitor = true
	max_contacts_reported = 4

	var mat := PhysicsMaterial.new()
	mat.bounce = 0.85
	mat.friction = 0.04
	physics_material_override = mat

	sprite_stripe.visible = (ball_type == 3)
	sprite_base.modulate = ball_color
	queue_redraw()

# ---------------------------------------------------------------------------
func apply_shot(force: float, direction_deg: float) -> void:
	var impulse := Vector2.from_angle(deg_to_rad(direction_deg)) * force
	apply_central_impulse(impulse)

func on_pocketed(pocket_id: int) -> void:
	_pocketed = true
	if ball_type == 1:
		# White ball fouled: respot it
		_respot()
	else:
		hide()
		collision_shape.set_deferred("disabled", true)

func _respot() -> void:
	position = Vector2(320.0, 360.0)
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0

# ---------------------------------------------------------------------------
func is_moving() -> bool:
	return linear_velocity.length() > STOP_THRESHOLD

func _physics_process(_delta: float) -> void:
	# Snap to rest when nearly stopped
	if linear_velocity.length() < STOP_THRESHOLD and linear_velocity.length() > 0.5:
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0

	# Rotate sprite to visualise spin
	if is_moving():
		var spin_deg := rad_to_deg(angular_velocity) * 0.016
		sprite_base.rotation_degrees += spin_deg
		sprite_stripe.rotation_degrees += spin_deg

# ---------------------------------------------------------------------------
func _draw() -> void:
	if GameState.selected_ball == self:
		draw_arc(Vector2.ZERO, RADIUS + 5.0, 0.0, TAU, 32, Color(0.3, 0.7, 1.0, 0.8), 2.5)
