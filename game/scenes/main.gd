## The first scene: starts the headset if there is one (else flat mode,
## ADR-001) and a singles match against the CPU. `-- doubles` plays
## doubles with a CPU partner; `-- demo` plays DEMO: the bot in your
## place, the camera on the bot.
extends Node3D

var view: MatchView


func _ready() -> void:
	var use_xr := false
	var xr := XRServer.find_interface("OpenXR")
	if xr and xr.is_initialized():
		get_viewport().use_xr = true
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		use_xr = true
	var args := OS.get_cmdline_user_args()
	var cfg := SimTypes.MatchConfig.new()
	cfg.doubles = args.has("doubles")
	view = MatchView.new()
	add_child(view)
	view.setup(cfg, use_xr, args.has("demo"))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		get_tree().quit()
