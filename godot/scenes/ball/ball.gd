extends RigidBody2D

@export var ball_id: int = 0
## 0=undef  1=white  2=solid  3=stripe  4=black
@export var ball_type: int = 0

const RADIUS := 26.0
const STOP_THRESHOLD := 6.0

# Стандартные цвета бильярдных шаров (индекс = номер шара 1-7, 8)
const BALL_COLORS: Array[Color] = [
	Color(0.96, 0.96, 0.96),   # 0  — белый (cue ball)
	Color(0.96, 0.77, 0.00),   # 1  — жёлтый
	Color(0.00, 0.27, 0.68),   # 2  — синий
	Color(0.80, 0.08, 0.08),   # 3  — красный
	Color(0.55, 0.00, 0.55),   # 4  — фиолетовый
	Color(0.89, 0.35, 0.00),   # 5  — оранжевый
	Color(0.00, 0.45, 0.20),   # 6  — зелёный
	Color(0.50, 0.08, 0.08),   # 7  — бордовый
	Color(0.10, 0.10, 0.10),   # 8  — чёрный
]

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _pocketed: bool = false

# ---------------------------------------------------------------------------
func _ready() -> void:
	add_to_group("balls")
	gravity_scale = 0.0
	linear_damp = 1.2
	angular_damp = 1.5
	contact_monitor = true
	max_contacts_reported = 4

	var mat := PhysicsMaterial.new()
	mat.bounce = 0.80
	mat.friction = 0.05
	physics_material_override = mat

# ---------------------------------------------------------------------------
func apply_shot(force: float, direction_deg: float) -> void:
	var impulse := Vector2.from_angle(deg_to_rad(direction_deg)) * force
	apply_central_impulse(impulse)

func on_pocketed(pocket_id: int) -> void:
	_pocketed = true
	if ball_type == 1:
		_respot()
	else:
		hide()
		collision_shape.set_deferred("disabled", true)
	queue_redraw()

func _respot() -> void:
	position = Vector2(320.0, 360.0)
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0

# ---------------------------------------------------------------------------
func is_moving() -> bool:
	return linear_velocity.length() > STOP_THRESHOLD

func _physics_process(_delta: float) -> void:
	if linear_velocity.length() < STOP_THRESHOLD and linear_velocity.length() > 0.3:
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0
	if is_moving():
		queue_redraw()

# ---------------------------------------------------------------------------
func _draw() -> void:
	if _pocketed and ball_type != 1:
		return

	var base_color := _get_base_color()

	# Тень
	draw_circle(Vector2(4, 5), RADIUS, Color(0, 0, 0, 0.18))

	if ball_type == 3:
		# Стрип: белый шар + цветная полоса по горизонтали
		draw_circle(Vector2.ZERO, RADIUS, Color.WHITE)
		draw_rect(Rect2(-RADIUS, -RADIUS * 0.42, RADIUS * 2.0, RADIUS * 0.84), base_color)
	else:
		draw_circle(Vector2.ZERO, RADIUS, base_color)

	# Обводка
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 48, Color(0, 0, 0, 0.35), 1.2)

	# Белый кружок с номером (только для шаров 1-15)
	if ball_id >= 1:
		draw_circle(Vector2.ZERO, RADIUS * 0.36, Color.WHITE)
		var font := ThemeDB.fallback_font
		var num := str(ball_id)
		var font_size := 11 if ball_id < 10 else 9
		var text_offset := Vector2(-4 if ball_id < 10 else -6, 5)
		draw_string(font, text_offset, num, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.BLACK)

	# Обводка выделения
	if GameState.selected_ball == self:
		draw_arc(Vector2.ZERO, RADIUS + 5.0, 0.0, TAU, 48, Color(0.3, 0.75, 1.0, 0.9), 2.5)

func _get_base_color() -> Color:
	if ball_type == 1:
		return BALL_COLORS[0]
	if ball_type == 4:
		return BALL_COLORS[8]
	# Для солидов и страйпов — цвет по номеру (1-7 повторяются)
	var color_idx := ((ball_id - 1) % 7) + 1
	return BALL_COLORS[color_idx]
