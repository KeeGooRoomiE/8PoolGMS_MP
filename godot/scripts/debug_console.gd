extends CanvasLayer

const MAX_LINES := 18

@onready var label: RichTextLabel = $Panel/RichTextLabel

var _lines: PackedStringArray = []
var _visible: bool = true

func _ready() -> void:
	layer = 100

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):
		_visible = !_visible
		$Panel.visible = _visible

## Appends a line to the on-screen console and prints to stdout.
func log_msg(text: String) -> void:
	print(text)
	_lines.append(text)
	if _lines.size() > MAX_LINES:
		_lines.remove_at(0)
	label.text = "\n".join(_lines)
