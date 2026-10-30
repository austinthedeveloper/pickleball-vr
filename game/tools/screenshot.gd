## A screenshot of the game, as it renders:
##   godot --path game --resolution 1280x720 -s res://tools/screenshot.gd -- <lobby|demo|play|machine|lesson|partner|online|online_guest|watch> <frames> <out.png> [doubles | lesson number | cross | hands | resets | drill=CALL_THE_SPOT...] [venue=NAME] [passthrough] [time=60] [cam=x,y,z look=x,y,z] [focus=0..0.88] [page=NAME (lobby)] [tick=N] [prank=ball:duck,paddle:pan,weather:snow,antic:dance,face,confetti]
extends SceneTree

var frames := 240
var out := "shot.png"
var n := 0
var _focus := -1.0
var _tick := -1                      ## tick=N: shoot when the sim reaches it
var _view: MatchView
var _prank_items := PackedStringArray()   ## put on once the scene is built
## online / online_guest (ADR-027): the other end, a Bot on its own session.
var _other: OnlineSession
var _other_bot: Bot
## watch (ADR-028): the player's drill a Bot plays, streamed to the view.
var _player: Sim
var _player_bot: Bot
var _feed: Watch.Feed


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
		for a in args:
			if a.begins_with("time="):
				st.partner_time = Drill.TIMES.find(int(a.trim_prefix("time=")))
		cfg.drill = st.partner_config().drill
	elif mode == "machine":
		cfg.drill = Drill.new()
		cfg.drill.zone = Drill.ZONE_DEEP
	elif mode == "lesson":
		cfg.drill = Lessons.drill(int(args[3]) if args.size() > 3 else 0)
	view.partner_model = "rb_male_01" if args.has("rocketbox") else ("rb_female_12" if args.has("rocketbox_f") else "")
	view.passthrough = args.has("passthrough")      # the court-only world (no headset: black behind)
	if mode == "online" or mode == "online_guest":
		_online(view, mode == "online_guest", cfg.venue)
	elif mode == "watch":
		var st := Settings.new()
		_player = Sim.new(st.partner_config())
		_player_bot = Bot.new(_player, 0)
		_feed = Watch.Feed.new()
		var w := Watch.new()
		w.on_message(_feed.start(_player, {"player": "ALEX"}))
		view.setup(w.sim.config, false, true, true, null, w)
		for a in args:
			if a.begins_with("view="):
				view.cam_view = int(a.trim_prefix("view="))
		view.flat.set_help("WATCHING ALEX: DINKS     1-4 CAMERA   TAB PANEL   ESC MENU")
		if args.has("panel"):
			# The coach's controls (VR-80), as a player's headset would fill them.
			var rc := RemoteCoach.new(null, null)
			rc.on_json({"type": "state", "where": "playing", "player": "ALEX",
				"setup": {"drill": 0, "drills": Drill.KIND_NAMES, "level": 1, "levels": Drill.PACE_NAMES},
				"run": {"name": "DINKS", "score": 7, "streak": 7, "good": 9, "timed": false},
				"machine": {"speed": 8.0, "spin": 0.0, "clear": 0.4, "every": 3.0, "on": false},
				"tunes": []})
			for i in 9:
				rc.on_json({"type": "shot", "good": i % 4 != 0, "side": "FH" if i % 3 else "BH", "clear": 0.1 + 0.03 * i,
					"x": -1.0 + 0.25 * i, "z": -1.2 - 0.1 * (i % 3), "speed": 4.5})
			rc.main = null
			view.show_coach_panel(rc)
	else:
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
	for a in args:
		if a.begins_with("prank="):
			_prank_items = a.trim_prefix("prank=").split(",")
	var cam = _vec(args, "cam")
	if cam != null and view.flat:
		view.flat.pin(cam, _vec(args, "look") if _vec(args, "look") != null else Vector3.ZERO)


## Pranks (ADR-025) on for the shot. The face is a drawn smiley, not a
## photo of anyone.
static func _pranks(view: MatchView, items: PackedStringArray) -> void:
	for it in items:
		var kv := it.split(":")
		match kv[0]:
			"ball": view.pranks.set_ball(kv[1])
			"paddle": view.pranks.set_paddle(kv[1])
			"weather": view.pranks.set_weather(kv[1])
			"confetti": view.pranks.confetti()
			"antic":
				for av in view.avatars:
					av.antic(kv[1], 999.0)
			"face":
				var img := Image.create(128, 128, false, Image.FORMAT_RGB8)
				img.fill(Color(0.3, 0.6, 0.95))
				for y in 128:
					for x in 128:
						var d := Vector2(x - 64, y - 64)
						if d.length() < 58:
							img.set_pixel(x, y, Color(1.0, 0.82, 0.2))
						if (Vector2(x - 44, y - 50).length() < 8 or Vector2(x - 84, y - 50).length() < 8) \
								or (d.length() > 30 and d.length() < 38 and y > 72):
							img.set_pixel(x, y, Color(0.15, 0.1, 0.05))
				view.pranks.set_face(img.save_jpg_to_buffer())


## FRIENDLY DINK online over a loopback: the view is the host (or the
## guest), and the other end is a Bot on its own session, stepped as the
## view steps.
func _online(view: MatchView, guest: bool, venue: int) -> void:
	var links := LoopbackLink.pair(6)
	var host := OnlineSession.new(links[0], true)
	var other := OnlineSession.new(links[1], false)
	for s in [host, other]:
		s.my_hello = OnlineSession.hello()
	for i in 30:
		host.poll()
		other.poll()
	var cfg := OnlineSession.friendly_config()
	cfg.venue = venue
	host.begin({"cfg": OnlineSession.config_to_dict(cfg), "venue": venue})
	for i in 30:
		host.poll()
		other.poll()
	var mine := other if guest else host
	_other = host if guest else other
	view.setup(mine.rollback.pred.config, false, true, false, mine)
	_other_bot = Bot.new(_other.rollback.pred, _other.slot())


## cam=x,y,z and look=x,y,z (metres) pin the camera for a close-up.
static func _vec(args: PackedStringArray, key: String) -> Variant:
	for a in args:
		if a.begins_with(key + "="):
			var p := a.trim_prefix(key + "=").split(",")
			return Vector3(float(p[0]), float(p[1]), float(p[2]))
	return null


func _process(_delta: float) -> bool:
	n += 1
	if _player:
		# The player keeps a little ahead of the replay, as over the line.
		while _player.tick < _view.sim.tick + Watch.LEAD + Watch.BATCH:
			var h := _player_bot.input()
			_player.step([h])
			_feed.add([_player.tick, h.to_array(), [], _player.state_hash() if _player.tick % Watch.HASH_EVERY == 0 else 0])
		var m := _feed.take()
		while not m.is_empty():
			_view.watch.on_message(m)
			m = _feed.take()
	if _other:
		while _other.rollback.predicted < _view.session.rollback.predicted:
			_other.tick(_other_bot.input())
		_other.poll()
	if n == 3 and _view and not _prank_items.is_empty():
		_pranks(_view, _prank_items)
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
