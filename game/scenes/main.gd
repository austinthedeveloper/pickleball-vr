## The first scene: starts the headset if there is one (else flat mode,
## ADR-001), then the lobby: a demo match to watch and MATCH SETUP beside
## you. PLAY starts the match; at its end, REMATCH or back to the lobby.
## On the command line, `-- play`, `-- doubles` and `-- demo` skip the lobby.
extends Node3D

const MODES := ["SINGLES", "DOUBLES"]
const DIFFICULTIES := ["EASY", "NORMAL", "HARD"]
const ASSISTS := ["OFF", "LOW", "MID", "FULL"]
const POINTS := ["5", "7", "11", "15"]
const OFF_ON := ["OFF", "ON"]
const HANDS := ["RIGHT", "LEFT"]
const ANGLES := ["0", "15", "30", "45"]

var settings := Settings.new()
var view: MatchView
var menu: Menu3D
var use_xr := false


func _ready() -> void:
	var xr := XRServer.find_interface("OpenXR")
	if xr and xr.is_initialized():
		get_viewport().use_xr = true
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		use_xr = true
	settings.load_settings()
	var args := OS.get_cmdline_user_args()
	if args.has("demo") or args.has("play") or args.has("doubles"):
		if args.has("doubles"):
			settings.doubles = true
		_start(args.has("demo"))
	else:
		lobby()


func _new_view() -> MatchView:
	if view:
		view.queue_free()
		remove_child(view)
	menu = null
	view = MatchView.new()
	view.left_handed = settings.left_handed
	view.paddle_tilt = settings.tilt()
	add_child(view)
	return view


## The lobby: watch a demo of the chosen match, set it up, PLAY.
func lobby() -> void:
	var selected: String = menu.rows[menu.selected]["id"] if menu else "play"
	_new_view().setup(settings.match_config(), use_xr, true, true)
	menu = Menu3D.new()
	menu.title = "PICKLEBALL '94 VR"
	menu.add_row("mode", "MODE", MODES, 1 if settings.doubles else 0)
	menu.add_row("vs", "VS", Opponents.names(), settings.opponent)
	menu.add_row("difficulty", "DIFFICULTY", DIFFICULTIES, settings.difficulty)
	menu.add_row("assist", "SHOT ASSIST", ASSISTS, settings.assist)
	menu.add_row("points", "POINTS", POINTS, settings.points)
	menu.add_row("win_by_2", "WIN BY 2", OFF_ON, 1 if settings.win_by_2 else 0)
	menu.add_row("hand", "PADDLE HAND", HANDS, 1 if settings.left_handed else 0)
	if use_xr:
		menu.add_row("angle", "PADDLE ANGLE", ANGLES, settings.paddle_angle)
	menu.add_row("play", "PLAY")
	if not use_xr:
		menu.add_row("quit", "QUIT")
	menu.changed.connect(_on_changed)
	menu.pressed.connect(_on_pressed)
	view.show_menu(menu)
	menu.select(selected)


func _on_changed(id: String, index: int) -> void:
	match id:
		"mode": settings.doubles = index == 1
		"vs": settings.opponent = index
		"difficulty": settings.difficulty = index
		"assist": settings.assist = index
		"points": settings.points = index
		"win_by_2": settings.win_by_2 = index == 1
		"hand": settings.left_handed = index == 1
		"angle": settings.paddle_angle = index
	settings.save()
	if id == "mode" or id == "vs" or id == "hand" or id == "angle":
		lobby.call_deferred()        # the demo shows the new match


func _on_pressed(id: String) -> void:
	match id:
		"play": _start.call_deferred(false)
		"quit": get_tree().quit()
		"rematch":
			view.hide_menu()
			view.command([K.CMD_NEW_MATCH])
		"lobby": lobby.call_deferred()


func _start(demo: bool) -> void:
	_new_view().setup(settings.match_config(), use_xr, demo)
	view.match_over.connect(_on_match_over)


func _on_match_over(winner: int) -> void:
	var m := Menu3D.new()
	m.title = "YOU WIN!" if winner == 0 else "%s WIN" % view.them
	m.add_row("rematch", "REMATCH")
	m.add_row("lobby", "MATCH SETUP")
	m.pressed.connect(_on_pressed)
	view.show_menu(m)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		get_tree().quit()
