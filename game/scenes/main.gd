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
	if Settings.dev_tools():
		Tune.load_saved()
	if OS.get_cmdline_user_args().has("coach"):
		settings.coach = true
	_coach_on(settings.coach)
	var args := OS.get_cmdline_user_args()
	if args.has("demo") or args.has("play") or args.has("doubles"):
		if args.has("doubles"):
			settings.doubles = true
		_start(settings.match_config(), args.has("demo"))
	else:
		lobby()


var _rig_t := Transform3D()          ## the XR play space the last view left
var _rig_from_lobby := false
var _has_rig := false


func _new_view() -> MatchView:
	_has_rig = false
	if view:
		if view.xr:
			_rig_t = view.xr.global_transform
			_rig_from_lobby = view.spectate
			_has_rig = true
		view.queue_free()
		remove_child(view)
	menu = null
	view = MatchView.new()
	view.left_handed = settings.left_handed
	view.passthrough = settings.passthrough
	var pose := settings.paddle_pose()
	view.paddle_tilt = pose[0]
	view.paddle_twist = pose[1]
	view.paddle_reach = pose[2]
	view.paddle_turn = pose[3]
	add_child(view)
	view.shot_done.connect(desk.on_shot)
	desk.on_new_view(view)
	return view


## The lobby on page `to` (or the page it's on): a demo behind, the menu
## beside you.
func lobby(to := "") -> void:
	var selected: String = menu.rows[menu.selected]["id"] if menu and to == "" else ""
	if to != "":
		page = to
	lesson = -1
	var demo_cfg := settings.match_config()
	if page == "machine":
		demo_cfg = settings.machine_config()
	elif page == "partner":
		demo_cfg = settings.partner_config()
	if demo_cfg.drill:
		demo_cfg.drill.time_limit = 0    # the lobby's demo plays on (ADR-022)
	_new_view().setup(demo_cfg, use_xr, true, true)
	_inherit()
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
			m.add_row("targets", "TARGETS", OFF_ON, 1 if settings.machine_targets else 0)
			m.add_row("assist", "SHOT ASSIST", ASSISTS, settings.assist)
			m.add_row("mtime", "MODE", Drill.TIME_NAMES, settings.machine_time)
			m.add_row("start", "START")
			m.add_row("to_records", "RECORDS")
			m.add_row("back", "BACK")
		"partner":
			m.title = "PRACTICE PARTNER   BEST %d" % settings.partner_best
			m.add_row("drill", "DRILL", Settings.PARTNER_DRILLS, settings.partner_drill)
			if settings.partner_drill == Drill.KIND_LANES:
				m.add_row("lane", "LANE", Drill.LANE_NAMES, settings.partner_lane)
			m.add_row("level", "DIFFICULTY", Drill.PACE_NAMES, settings.partner_level)
			m.add_row("side", "PARTNER", ["ACROSS", "CROSS COURT"], 1 if settings.partner_cross else 0)
			m.add_row("spread", "SPREAD", Drill.SPREAD_NAMES, settings.partner_spread)
			m.add_row("ptargets", "TARGETS", OFF_ON, 1 if settings.partner_targets else 0)
			m.add_row("assist", "SHOT ASSIST", ASSISTS, settings.assist)
			m.add_row("ptime", "MODE", Drill.TIME_NAMES, settings.partner_time)
			m.add_row("pstart", "START")
			m.add_row("to_records", "RECORDS")
			m.add_row("back", "BACK")
		"paddle":
			# Paddle profiles (ADR-015): DEFAULT is the angle you had; the
			# others fit an accessory, live in your hand as you change them.
			m.title = "PADDLE"
			m.add_row("profile", "PROFILE", Settings.PROFILE_NAMES, settings.paddle_profile)
			m.add_row("hand", "PADDLE HAND", HANDS, 1 if settings.left_handed else 0)
			var p: Variant = settings.profile()
			if p == null:
				m.add_row("angle", "ANGLE", ANGLES, settings.paddle_angle)
			else:
				m.add_row("angle", "ANGLE", _degrees(Settings.PROFILE_ANGLES),
					maxi(Settings.PROFILE_ANGLES.find(p["angle"]), 0))
				m.add_row("turn", "TURN", _degrees(Settings.PROFILE_TURNS),
					maxi(Settings.PROFILE_TURNS.find(p["turn"]), 0))
				m.add_row("twist", "TWIST", _degrees(Settings.PROFILE_TWISTS),
					maxi(Settings.PROFILE_TWISTS.find(p["twist"]), 0))
				m.add_row("reach", "REACH", Settings.PROFILE_REACHES.map(func(c: int) -> String: return "%d CM" % c),
					maxi(Settings.PROFILE_REACHES.find(p["reach"]), 0))
				m.add_row("reset", "RESET TO DEFAULT")
			m.add_row("back", "BACK")
		"lessons":
			m.title = "HOW TO PLAY"
			for i in Lessons.count():
				var l := Lessons.lesson(i)
				var done: bool = settings.lessons_done.has(l["id"])
				m.add_row("lesson_%d" % i, "%d  %s%s" % [i + 1, l["title"], "   - DONE" if done else ""])
			m.add_row("back", "BACK")
		"records":
			m = _records_menu()
		"coach":
			m.title = "COACH"
			m.add_row("coach", "COACH MODE", OFF_ON, 1 if settings.coach else 0)
			if coach and coach.listening():
				var at := Coach.addresses()
				m.add_row("info_open", "ON A PHONE ON THIS WI-FI, OPEN")
				m.add_row("info_url", "HTTP://%s:%d" % [at[0] if at.size() > 0 else "THIS-HEADSET", Coach.PORT])
				m.add_row("info_code", "CODE   %s" % coach.code)
				m.add_row("info_n", "COACHES CONNECTED   %d" % coach.coaches())
			elif settings.coach:
				m.add_row("info_err", "CAN'T START: NO NETWORK?")
			m.add_row("back", "BACK")
		"tune":
			m = _tune_menu("")
		_ when id.begins_with("tune_"):
			m = _tune_menu(id.trim_prefix("tune_"))
		_:
			m.title = "PICKLEBALL '94 VR"
			m.add_row("to_match", "PLAY A MATCH")
			m.add_row("to_partner", "PRACTICE PARTNER")
			m.add_row("to_machine", "BALL MACHINE")
			m.add_row("to_lessons", "HOW TO PLAY")
			m.add_row("to_paddle", "PADDLE")
			m.add_row("passthrough", "PASSTHROUGH", OFF_ON, 1 if settings.passthrough else 0)
			m.add_row("to_coach", "COACH")
			if Settings.dev_tools():
				m.add_row("to_tune", "TUNING")
			if not use_xr:
				m.add_row("quit", "QUIT")
	return m


func _on_changed(id: String, index: int) -> void:
	if id.begins_with("tune:"):
		var t := id.trim_prefix("tune:")
		Tune.set_value(t, _tune_steps[t][index])
		Tune.save()
		return
	match id:
		"mode": settings.doubles = index == 1
		"vs": settings.opponent = index
		"venue": settings.venue = index
		"difficulty": settings.difficulty = index
		"assist": settings.assist = index
		"points": settings.points = index
		"win_by_2": settings.win_by_2 = index == 1
		"hand": settings.left_handed = index == 1
		"passthrough": settings.passthrough = index == 1
		"coach":
			settings.coach = index == 1
			_coach_on(settings.coach)
			settings.save()
			lobby.call_deferred("coach")     # the address and code
			return
		"angle":
			if settings.profile() == null:
				settings.paddle_angle = index
			else:
				settings.profile()["angle"] = Settings.PROFILE_ANGLES[index]
		"profile": settings.paddle_profile = index
		"twist": settings.profile()["twist"] = Settings.PROFILE_TWISTS[index]
		"turn": settings.profile()["turn"] = Settings.PROFILE_TURNS[index]
		"reach": settings.profile()["reach"] = Settings.PROFILE_REACHES[index]
		"shot": settings.machine_shot = index
		"target": settings.machine_target = index
		"rate": settings.machine_rate = index
		"speed": settings.machine_speed = index
		"machine_at": settings.machine_at = index
		"zone": settings.machine_zone = index
		"targets": settings.machine_targets = index == 1
		"level": settings.partner_level = index
		"ptargets": settings.partner_targets = index == 1
		"side": settings.partner_cross = index == 1
		"spread": settings.partner_spread = index
		"drill": settings.partner_drill = index
		"lane": settings.partner_lane = index
		"ptime": settings.partner_time = index
		"mtime": settings.machine_time = index
	settings.save()
	if id in ["mode", "vs", "venue", "hand", "passthrough", "angle", "profile", "twist", "turn", "reach", "shot", "target", "zone", "machine_at", "speed",
			"targets", "level", "ptargets", "side", "spread", "drill", "lane"]:
		lobby.call_deferred()        # the demo shows the new setup


func _on_pressed(id: String) -> void:
	if id == "to_tune" or id.begins_with("tune"):
		_tune_pressed(id)
		return
	if id.begins_with("lesson_"):
		_start_lesson.call_deferred(int(id.trim_prefix("lesson_")))
		return
	match id:
		"to_match": lobby.call_deferred("match")
		"to_machine": lobby.call_deferred("machine")
		"to_partner": lobby.call_deferred("partner")
		"pstart": _start.call_deferred(settings.partner_config(), false)
		"to_lessons": lobby.call_deferred("lessons")
		"to_paddle": lobby.call_deferred("paddle")
		"to_coach": lobby.call_deferred("coach")
		"to_records":
			_records_from = page
			lobby.call_deferred("records")
		"records_back": lobby.call_deferred(_records_from)
		"reset":
			# The profile back to the DEFAULT paddle: its angle, no twist or reach.
			settings.profile()["angle"] = int(settings.tilt())
			settings.profile()["twist"] = 0
			settings.profile()["turn"] = 0
			settings.profile()["reach"] = 0
			settings.save()
			lobby.call_deferred()
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
			lobby.call_deferred(_back_page())


func _start(cfg: SimTypes.MatchConfig, demo: bool) -> void:
	_new_view().setup(cfg, use_xr, demo)
	_inherit()
	view.match_over.connect(_on_match_over)
	view.drill_done.connect(_on_drill_done)
	view.time_up.connect(_on_time_up)
	view.time_up.connect(desk.on_time_up)
	view.pause_requested.connect(_on_pause)


func _start_lesson(i: int) -> void:
	_start(settings.lesson_config(clampi(i, 0, Lessons.count() - 1)), false)
	lesson = clampi(i, 0, Lessons.count() - 1)
	var l := Lessons.lesson(lesson)
	view.show_lesson(String(l["title"]), l["lines"])


## Hand the play space on to the new view: no turn, and no move at all
## when the lobby rebuilds itself.
func _inherit() -> void:
	if _has_rig:
		view.inherit_rig(_rig_t, _rig_from_lobby and view.spectate)


## The page a session goes back to.
func _back_page() -> String:
	if lesson >= 0:
		return "lessons"
	if view.sim.drill:
		return "partner" if view.sim.drill.partner else "machine"
	return "main"


## The ball machine's best streak and the partner's best rally, kept.
func _keep_best() -> void:
	if view == null or view.sim.drill == null or view.sim.drill.goal > 0:
		return
	var d := view.sim.drill
	if d.partner and d.best > settings.partner_best:
		settings.partner_best = d.best
	elif not d.partner and d.best > settings.machine_best:
		settings.machine_best = d.best
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


# --- The coach companion (ADR-023, design/COACHING.md) ---------------------------------

var desk: CoachDesk                  ## the coach's side: CoachDesk does the work
var coach: Coach:
	get: return desk.coach if desk else null


func _coach_on(on: bool) -> void:
	if desk == null:
		desk = CoachDesk.new(self)
		add_child(desk)
	desk.set_on(on)


func coach_state() -> Dictionary:
	return desk.state()


func _on_coach(msg: Dictionary) -> void:
	desk.handle(msg)


# --- Timed runs and records (ADR-022) ----------------------------------------------------

var _records_from := "partner"       ## the page RECORDS goes back to


## The clock ran out: the score kept, where it places, and the last few.
func _on_time_up(score: int, good: int, best_streak: int) -> void:
	var name := Settings.run_name(view.sim.drill)
	var place := settings.add_run(name, score, good, best_streak, Time.get_datetime_string_from_system().replace("T", " ").left(16))
	settings.save()
	var m := Menu3D.new()
	m.title = "TIME!   SCORE %d" % score
	if place[0] == 1 and place[1] > 1:
		m.add_row("info_best", "NEW BEST!")
	else:
		m.add_row("info_best", "BEST %d" % int(settings.best_runs(name, 1)[0][0]) + ("" if place[1] == 1 else "   YOU PLACED %d OF %d" % place))
	m.add_row("info_good", "%d GOOD   LONGEST STREAK %d" % [good, best_streak])
	m.add_row("info_recent", "LAST RUNS   " + "  ".join(settings.recent_scores(name).map(func(v: int) -> String: return str(v))))
	m.add_row("again", "AGAIN")
	m.add_row("lobby", "MENU")
	m.pressed.connect(_on_pressed)
	view.show_menu(m)


## RECORDS: the drill and level set on the page you came from, each timed
## MODE's best runs and its last few scores.
func _records_menu() -> Menu3D:
	var m := Menu3D.new()
	var cfg := settings.machine_config() if _records_from == "machine" else settings.partner_config()
	var d: Drill = cfg.drill
	m.title = "RECORDS: " + d.mode_name() + (" TARGETS" if d.targets else "")
	var any := false
	for t in range(1, Drill.TIMES.size()):
		d.time_limit = Drill.TIMES[t] * K.TICK_HZ
		var name := Settings.run_name(d)
		var best := settings.best_runs(name, 3)
		if best.is_empty():
			continue
		any = true
		var tops := "  ".join(best.map(func(r: Array) -> String: return str(int(r[0]))))
		m.add_row("info_%d" % t, "%s   BEST %s" % [Drill.TIME_NAMES[t], tops])
		var recent := settings.recent_scores(name)
		m.add_row("info_r%d" % t, "      LAST %s   (%d RUNS)" % ["  ".join(recent.map(func(v: int) -> String: return str(v))),
			(settings.records[name] as Array).size()])
	if not any:
		m.add_row("info_none", "NO TIMED RUNS YET: SET MODE TO 1, 2 OR 3 MIN")
	m.add_row("records_back", "BACK")
	return m


func _on_pause() -> void:
	view.paused = true
	var m := Menu3D.new()
	m.title = "PAUSED"
	m.add_row("resume", "RESUME")
	m.add_row("again", "RESTART")
	if Settings.dev_tools():
		m.add_row("to_tune", "TUNING")
	m.add_row("lobby", "MENU")
	m.pressed.connect(_on_pressed)
	view.show_menu(m)


# --- Developer tuning (ADR-020) --------------------------------------------------------

var _tune_steps := {}                ## tunable id -> the raw values its row steps through


## The TUNING pages: the groups (`group` ""), or one group's numbers. A
## value with a * differs from the source's.
func _tune_menu(group: String) -> Menu3D:
	var m := Menu3D.new()
	if group == "":
		m.title = "TUNING"
		for g in Tune.GROUPS:
			var n := Tune.in_group(g).filter(func(e: Array) -> bool: return Tune.changed(e[0])).size()
			m.add_row("tune_" + g, g + ("   *%d" % n if n > 0 else ""))
		m.add_row("tune_reset:", "RESET ALL")
	else:
		m.title = "TUNING: " + group
		for e in Tune.in_group(group):
			var steps := Tune.steps(e[0])
			_tune_steps[e[0]] = steps
			var dflt := Tune.default_of(e[0])
			var names := steps.map(func(v: int) -> String: return Tune.text(e[0], v) + ("" if v == dflt else " *"))
			m.add_row("tune:" + e[0], e[2], names, steps.find(Tune.value(e[0])))
		m.add_row("tune_reset:" + group, "RESET " + group)
	if _playing():
		m.add_row("resume", "RESUME")
	m.add_row("tune_back:" + group, "BACK")
	return m


## A match or drill is on (paused), not the lobby.
func _playing() -> bool:
	return view != null and not view.spectate


func _tune_pressed(id: String) -> void:
	var to := ""                     # the TUNING page to show next
	if id.begins_with("tune_reset:"):
		var g := id.trim_prefix("tune_reset:")
		Tune.reset(g)
		Tune.save()
		to = "tune_" + g if g != "" else "tune"
	elif id.begins_with("tune_back:"):
		if id == "tune_back:":
			if _playing():
				_on_pause()
			else:
				lobby.call_deferred("main")
			return
		to = "tune"
	else:
		to = id                      # "to_tune" or "tune_GROUP"
		if to == "to_tune":
			to = "tune"
	if _playing():
		var m := _page(to)
		m.changed.connect(_on_changed)
		m.pressed.connect(_on_pressed)
		view.show_menu(m)
	else:
		lobby.call_deferred(to)


static func _degrees(values: Array) -> Array:
	return values.map(func(d: int) -> String: return str(d))
