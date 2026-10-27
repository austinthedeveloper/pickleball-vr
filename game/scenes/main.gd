## The first scene: starts the headset if there is one (else flat mode,
## ADR-001), then the lobby: a demo to watch and a menu beside you (MAIN,
## MATCH SETUP, BALL MACHINE, HOW TO PLAY). A match, a drill or a lesson
## then plays; the menu button (Esc) pauses it. On the command line,
## `-- play`, `-- doubles` and `-- demo` skip the lobby.
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
var page := "main"
var use_xr := false
var lesson := -1                     ## the lesson playing, or -1


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
		_start(settings.match_config(), args.has("demo"))
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


## The lobby on page `to` (or the page it's on): a demo behind, the menu
## beside you.
func lobby(to := "") -> void:
	var selected: String = menu.rows[menu.selected]["id"] if menu and to == "" else ""
	if to != "":
		page = to
	lesson = -1
	var demo_cfg := settings.machine_config() if page == "machine" else settings.match_config()
	_new_view().setup(demo_cfg, use_xr, true, true)
	menu = _page(page)
	menu.changed.connect(_on_changed)
	menu.pressed.connect(_on_pressed)
	view.show_menu(menu)
	if selected != "":
		menu.select(selected)


func _page(id: String) -> Menu3D:
	var m := Menu3D.new()
	match id:
		"match":
			m.title = "MATCH SETUP"
			m.add_row("mode", "MODE", MODES, 1 if settings.doubles else 0)
			m.add_row("vs", "VS", Opponents.names(), settings.opponent)
			m.add_row("venue", "VENUE", ["HOME"] + Venues.NAMES, settings.venue)
			m.add_row("difficulty", "DIFFICULTY", DIFFICULTIES, settings.difficulty)
			m.add_row("assist", "SHOT ASSIST", ASSISTS, settings.assist)
			m.add_row("points", "POINTS", POINTS, settings.points)
			m.add_row("win_by_2", "WIN BY 2", OFF_ON, 1 if settings.win_by_2 else 0)
			m.add_row("hand", "PADDLE HAND", HANDS, 1 if settings.left_handed else 0)
			if use_xr:
				m.add_row("angle", "PADDLE ANGLE", ANGLES, settings.paddle_angle)
			m.add_row("play", "PLAY")
			m.add_row("back", "BACK")
		"machine":
			m.title = "BALL MACHINE   BEST %d" % settings.machine_best
			m.add_row("shot", "SHOT", Drill.SHOT_NAMES.slice(0, 4), settings.machine_shot)
			m.add_row("speed", "SPEED", Drill.SPEED_NAMES, settings.machine_speed)
			m.add_row("target", "TARGET", Drill.TARGET_NAMES, settings.machine_target)
			m.add_row("machine_at", "MACHINE AT", Drill.AT_NAMES, settings.machine_at)
			m.add_row("rate", "RATE", Drill.RATE_NAMES, settings.machine_rate)
			m.add_row("zone", "RETURN TO", Drill.ZONE_NAMES, settings.machine_zone)
			m.add_row("assist", "SHOT ASSIST", ASSISTS, settings.assist)
			m.add_row("start", "START")
			m.add_row("back", "BACK")
		"lessons":
			m.title = "HOW TO PLAY"
			for i in Lessons.count():
				var l := Lessons.lesson(i)
				var done: bool = settings.lessons_done.has(l["id"])
				m.add_row("lesson_%d" % i, "%d  %s%s" % [i + 1, l["title"], "   - DONE" if done else ""])
			m.add_row("back", "BACK")
		_:
			m.title = "PICKLEBALL '94 VR"
			m.add_row("to_match", "PLAY A MATCH")
			m.add_row("to_machine", "BALL MACHINE")
			m.add_row("to_lessons", "HOW TO PLAY")
			if not use_xr:
				m.add_row("quit", "QUIT")
	return m


func _on_changed(id: String, index: int) -> void:
	match id:
		"mode": settings.doubles = index == 1
		"vs": settings.opponent = index
		"venue": settings.venue = index
		"difficulty": settings.difficulty = index
		"assist": settings.assist = index
		"points": settings.points = index
		"win_by_2": settings.win_by_2 = index == 1
		"hand": settings.left_handed = index == 1
		"angle": settings.paddle_angle = index
		"shot": settings.machine_shot = index
		"target": settings.machine_target = index
		"rate": settings.machine_rate = index
		"speed": settings.machine_speed = index
		"machine_at": settings.machine_at = index
		"zone": settings.machine_zone = index
	settings.save()
	if id in ["mode", "vs", "venue", "hand", "angle", "shot", "target", "zone", "machine_at", "speed"]:
		lobby.call_deferred()        # the demo shows the new setup


func _on_pressed(id: String) -> void:
	if id.begins_with("lesson_"):
		_start_lesson.call_deferred(int(id.trim_prefix("lesson_")))
		return
	match id:
		"to_match": lobby.call_deferred("match")
		"to_machine": lobby.call_deferred("machine")
		"to_lessons": lobby.call_deferred("lessons")
		"back": lobby.call_deferred("main")
		"play": _start.call_deferred(settings.match_config(), false)
		"start": _start.call_deferred(settings.machine_config(), false)
		"quit": get_tree().quit()
		"resume":
			view.hide_menu()
			view.paused = false
		"rematch", "again":
			view.hide_menu()
			view.paused = false
			view.command([K.CMD_NEW_MATCH])
		"next": _start_lesson.call_deferred(lesson + 1)
		"lobby":
			_keep_best()
			lobby.call_deferred("lessons" if lesson >= 0 else ("machine" if view.sim.drill else "main"))


func _start(cfg: SimTypes.MatchConfig, demo: bool) -> void:
	_new_view().setup(cfg, use_xr, demo)
	view.match_over.connect(_on_match_over)
	view.drill_done.connect(_on_drill_done)
	view.pause_requested.connect(_on_pause)


func _start_lesson(i: int) -> void:
	_start(settings.lesson_config(clampi(i, 0, Lessons.count() - 1)), false)
	lesson = clampi(i, 0, Lessons.count() - 1)
	var l := Lessons.lesson(lesson)
	view.show_lesson(String(l["title"]), l["lines"])


## The ball machine's best streak, kept.
func _keep_best() -> void:
	if view and view.sim.drill and view.sim.drill.goal == 0 and view.sim.drill.best > settings.machine_best:
		settings.machine_best = view.sim.drill.best
		settings.save()


func _on_match_over(winner: int) -> void:
	var m := Menu3D.new()
	m.title = "YOU WIN!" if winner == 0 else "%s WIN" % view.them
	m.add_row("rematch", "REMATCH")
	m.add_row("lobby", "MENU")
	m.pressed.connect(_on_pressed)
	view.show_menu(m)


func _on_drill_done() -> void:
	var id: String = Lessons.lesson(lesson)["id"]
	if not settings.lessons_done.has(id):
		settings.lessons_done.append(id)
		settings.save()
	var m := Menu3D.new()
	m.title = "LESSON COMPLETE!"
	if lesson + 1 < Lessons.count():
		m.add_row("next", "NEXT: " + String(Lessons.lesson(lesson + 1)["title"]))
	m.add_row("again", "AGAIN")
	m.add_row("lobby", "MENU")
	m.pressed.connect(_on_pressed)
	view.show_menu(m)


func _on_pause() -> void:
	view.paused = true
	var m := Menu3D.new()
	m.title = "PAUSED"
	m.add_row("resume", "RESUME")
	m.add_row("again", "RESTART")
	m.add_row("lobby", "MENU")
	m.pressed.connect(_on_pressed)
	view.show_menu(m)
