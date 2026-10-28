## A screenshot of the game, as it renders:
##   godot --path game --resolution 1280x720 -s res://tools/screenshot.gd -- <lobby|demo|play|machine|lesson|partner> <frames> <out.png> [doubles | lesson number | cross | hands | resets | drill=CALL_THE_SPOT...] [venue=NAME] [cam=x,y,z look=x,y,z] [focus=0..0.88] [page=NAME (lobby)] [tick=N]
extends SceneTree

var frames := 240
var out := "shot.png"
var n := 0
var _focus := -1.0
var _tick := -1                      ## tick=N: shoot when the sim reaches it
var _view: MatchView


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var demo := args.size() < 1 or args[0] == "demo"
	if args.size() > 1:
		frames = int(args[1])
	if args.size() > 2:
		out = args[2]
	if args.size() > 0 and args[0] == "lobby":
		Settings.default_path = "user://screenshot_settings.cfg"
		var main: Node = load("res://scenes/main.tscn").instantiate()
		root.add_child(main)
		for a in args:
			if a.begins_with("page="):
				main.page = a.trim_prefix("page=")
				if a == "page=paddle":
					main.settings.paddle_profile = 1     # show a profile's rows
				main.lobby.call_deferred()
		return
	var view := MatchView.new()
	root.add_child(view)
	var cfg := SimTypes.MatchConfig.new()
	cfg.doubles = args.has("doubles")
	var mode: String = args[0] if args.size() > 0 else "demo"
	for a in args:
		if a.begins_with("venue="):
			cfg.venue = Venues.NAMES.find(a.trim_prefix("venue="))
	if mode == "partner":
		var st := Settings.new()
		st.partner_targets = true
		st.partner_cross = args.has("cross")
		st.partner_hands = args.has("hands")
		for a in args:
			if a.begins_with("drill="):
				st.partner_drill = Drill.KIND_NAMES.find(a.trim_prefix("drill=").replace("_", " "))
		if args.has("resets"):
			st.partner_drill = 2
		cfg.drill = st.partner_config().drill
	elif mode == "machine":
		cfg.drill = Drill.new()
		cfg.drill.zone = Drill.ZONE_DEEP
	elif mode == "lesson":
		cfg.drill = Lessons.drill(int(args[3]) if args.size() > 3 else 0)
	view.setup(cfg, false, demo or mode in ["machine", "lesson", "partner"])
	if mode == "lesson":
		var l := Lessons.lesson(int(args[3]) if args.size() > 3 else 0)
		view.show_lesson(String(l["title"]), l["lines"])
	for a in args:
		if a.begins_with("tick="):
			_tick = int(a.trim_prefix("tick="))
		if a.begins_with("focus="):
			_focus = float(a.trim_prefix("focus="))
	_view = view
	var cam = _vec(args, "cam")
	if cam != null and view.flat:
		view.flat.pin(cam, _vec(args, "look") if _vec(args, "look") != null else Vector3.ZERO)


## cam=x,y,z and look=x,y,z (metres) pin the camera for a close-up.
static func _vec(args: PackedStringArray, key: String) -> Variant:
	for a in args:
		if a.begins_with(key + "="):
			var p := a.trim_prefix(key + "=").split(",")
			return Vector3(float(p[0]), float(p[1]), float(p[2]))
	return null


func _process(_delta: float) -> bool:
	n += 1
	if n == 5 and _focus >= 0.0 and _view:
		_view.world.set_focus(_focus)       # once the scene is built
		_view.crowd.set_focus(_focus)
	if _tick >= 0:
		if _view == null or _view.sim.tick < _tick:
			return false
		frames = n                       # tick=N: the moment the sim reaches it
		_tick = -1
	if n == frames:
		var img := root.get_viewport().get_texture().get_image()
		img.save_png(out)
		print("saved ", out)
		return true
	return false
