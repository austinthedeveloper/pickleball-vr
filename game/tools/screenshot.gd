## A screenshot of the game, as it renders:
##   godot --path game --resolution 1280x720 -s res://tools/screenshot.gd -- <lobby|demo|play> <frames> <out.png> [doubles]
extends SceneTree

var frames := 240
var out := "shot.png"
var n := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var demo := args.size() < 1 or args[0] == "demo"
	if args.size() > 1:
		frames = int(args[1])
	if args.size() > 2:
		out = args[2]
	if args.size() > 0 and args[0] == "lobby":
		Settings.default_path = "user://screenshot_settings.cfg"
		root.add_child(load("res://scenes/main.tscn").instantiate())
		return
	var view := MatchView.new()
	root.add_child(view)
	var cfg := SimTypes.MatchConfig.new()
	cfg.doubles = args.has("doubles")
	view.setup(cfg, false, demo)


func _process(_delta: float) -> bool:
	n += 1
	if n == frames:
		var img := root.get_viewport().get_texture().get_image()
		img.save_png(out)
		print("saved ", out)
		return true
	return false
