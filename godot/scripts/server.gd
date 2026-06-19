extends Node

## Entry point for headless server mode.
## Launch with: godot --headless --scene res://scenes/server.tscn
## Optional args: --port 7777

func _ready() -> void:
	var port := _parse_port_arg()
	var err := NetworkManager.start_server(port)
	if err != OK:
		get_tree().quit(1)
		return
	print("[Server] Ready. Waiting for players on port %d" % port)

func _parse_port_arg() -> int:
	var args := OS.get_cmdline_args()
	var idx := args.find("--port")
	if idx != -1 and idx + 1 < args.size():
		var val := args[idx + 1].to_int()
		if val > 0:
			return val
	return NetworkManager.DEFAULT_PORT
