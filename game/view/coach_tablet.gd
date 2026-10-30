## The coach tablet (design/COACHING.md C-22): the companion page's core,
## in the headset, standing beside PAUSED. It shows the run, the court with
## this session's shots and the target, what the numbers say, and the
## drill's own controls: in a partner drill, its pace and size, with taps
## for the target and the partner's next ball; at the ball machine, the
## machine's speed, spin, height and timing, with taps for where it stands
## and where its balls bounce. It does all of it through its source, as
## the phone does: CoachDesk in the headset, or RemoteCoach in a coach's
## game watching a player (COACH VIEW, ADR-028), which also gets the
## session's own controls: the drill and level, START, PAUSE, RESTART,
## MENU and the cues.
##
## A 2D panel (Controls in a SubViewport) on a quad. The laser or the mouse
## points at it like a menu: the hit is turned into the panel's own mouse
## events, so its buttons behave as buttons. With `overlay` (a coach
## watching on a Mac) the same panel is drawn on the screen instead, at
## the right, and the mouse uses it directly.
class_name CoachTablet
extends Node3D

const PX := Vector2i(1000, 1150)
const SIZE := Vector2(0.96, 1.1)    ## metres
const REFRESH := 0.25
const BG := Color(0.08, 0.106, 0.192)
const PANEL := Color(0.106, 0.141, 0.251)
const LINE := Color(0.165, 0.208, 0.353)
const TEXT := Color(0.91, 0.925, 0.973)
const DIM := Color(0.557, 0.604, 0.753)
const GOLD := Color(0.949, 0.761, 0.188)
const GOOD := Color(0.239, 0.863, 0.518)
const BAD := Color(1.0, 0.42, 0.353)
const COURT := Color(0.184, 0.435, 0.839)
const MINE := Color(0.114, 0.247, 0.525)
const KITCHEN := Color(0.141, 0.267, 0.561)
const MODES := ["TARGET", "FEED", "MACHINE", "BOUNCE"]
## What each tap button says it does.
const MODE_TEXT := {"TARGET": "TARGET", "FEED": "NEXT BALL", "MACHINE": "MACHINE", "BOUNCE": "BOUNCE"}
## The taps each kind of drill offers.
const PARTNER_MODES := ["TARGET", "FEED"]
const MACHINE_MODES := ["TARGET", "MACHINE", "BOUNCE"]
const MAX_SLIDERS := 5
const HINTS := {"TARGET": "TAP THEIR SIDE: A TARGET THERE, STAYING PUT",
	"FEED": "TAP YOUR SIDE: THE PARTNER'S NEXT BALL LANDS THERE",
	"MACHINE": "TAP THEIR SIDE: THE MACHINE STANDS THERE", "BOUNCE": "TAP YOUR SIDE: ITS BALLS BOUNCE THERE"}
## What a tap did, said back.
const DONE := {"TARGET": "TARGET PINNED THERE: RESUME AND AIM FOR IT", "FEED": "THE NEXT BALL GOES THERE: RESUME",
	"MACHINE": "THE MACHINE MOVES THERE", "BOUNCE": "ITS BALLS BOUNCE THERE NOW"}
const WRONG := {"TARGET": "THE TARGET GOES ON THEIR SIDE: TAP ABOVE THE NET", "FEED": "THE NEXT BALL LANDS ON YOUR SIDE: TAP BELOW THE NET",
	"MACHINE": "THE MACHINE STANDS ON THEIR SIDE: TAP ABOVE THE NET", "BOUNCE": "ITS BALLS BOUNCE ON YOUR SIDE: TAP BELOW THE NET"}
## The machine's steppers: key, label, step, min, max.
const MACHINE := [["speed", "SPEED", 0.5, 3.0, 20.0], ["spin", "SPIN", 10.0, -100.0, 100.0],
	["clear", "OVER THE NET", 0.05, 0.05, 3.0], ["every", "A BALL EVERY", 0.25, 1.25, 8.0]]

## The source: handle(msg), state(), run_shots(), pending, machine_settings(),
## current_view(), remote. CoachDesk or RemoteCoach.
var desk
var overlay := false
var mode := "TARGET"
var lock := Menu3D.SWITCH_LOCK
var _vp: SubViewport
var _quad: MeshInstance3D
var _court: Control
var _labels := {}                    ## name -> Label
var _mode_buttons := {}
var _machine_box: VBoxContainer      ## the ball machine's controls
var _partner_box: VBoxContainer      ## a partner drill's pace and size
var _slider_rows: Array = []         ## [HBoxContainer, name Label, value Label], reused
var _slider_ids: Array = []
var _machine := false                ## the drill under way is the ball machine
var _t := 0.0
var _state := {}
var _holder: Control                 ## overlay: the panel on the screen
var _slider_vals: Array = []         ## the sliders' values, as the source says them


func _ready() -> void:
	if overlay:
		var layer := CanvasLayer.new()
		add_child(layer)
		_holder = Control.new()
		_holder.size = PX
		layer.add_child(_holder)
		_build(_holder)
		_fit()
		get_viewport().size_changed.connect(_fit)
		refresh()
		return
	_vp = SubViewport.new()
	_vp.size = PX
	_vp.disable_3d = true
	_vp.transparent_bg = false
	_vp.gui_embed_subwindows = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	_build(_vp)
	_quad = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = SIZE
	_quad.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_texture = _vp.get_texture()
	_quad.material_override = m
	_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_quad)
	refresh()


## Overlay: the panel at the screen's right, as tall as it fits.
func _fit() -> void:
	var win := get_viewport().get_visible_rect().size
	var k := clampf(win.y * 0.96 / PX.y, 0.4, 1.0)
	_holder.scale = Vector2(k, k)
	_holder.position = Vector2(win.x - PX.x * k - win.y * 0.02, win.y * 0.02)


## Overlay: how much of the screen's width the panel takes (the view keeps
## the action in the rest).
func overlay_share() -> float:
	if _holder == null or not _holder.visible:
		return 0.0
	return (PX.x * _holder.scale.x) / maxf(get_viewport().get_visible_rect().size.x, 1.0)


func show_overlay(on: bool) -> void:
	if _holder:
		_holder.visible = on


# --- The panel ---------------------------------------------------------------------

func _build(parent: Node) -> void:
	var bg := Panel.new()
	bg.size = PX
	bg.add_theme_stylebox_override("panel", _box(BG, 0))
	parent.add_child(bg)
	var root := VBoxContainer.new()
	root.position = Vector2(24, 20)
	root.size = Vector2(PX.x - 48, PX.y - 40)
	root.add_theme_constant_override("separation", 12)
	parent.add_child(root)
	var head := HBoxContainer.new()
	root.add_child(head)
	head.add_child(_label("title", "COACH", 36, GOLD))
	var run := _label("run", "", 30, TEXT)
	run.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	run.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(run)
	if desk and desk.remote:
		_build_session(root)
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 10)
	root.add_child(stats)
	for k in [["score", "SCORE"], ["time", "TIME LEFT"], ["good", "GOOD"], ["clear", "NET +CM"]]:
		var box := PanelContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_theme_stylebox_override("panel", _box(PANEL, 10))
		var v := VBoxContainer.new()
		box.add_child(v)
		var big := _label(k[0], "-", 48, GOLD)
		big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(big)
		var small := _label(k[0] + "_l", k[1], 22, DIM)
		small.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(small)
		stats.add_child(box)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	# Left: the court and how a tap on it is read.
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(400, 0)
	left.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	body.add_child(left)
	left.add_child(_label("h_tap", "PICK ONE, THEN TAP THE COURT TO PLACE IT:", 18, DIM))
	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", 6)
	left.add_child(modes)
	for m in MODES:
		var b := _button(MODE_TEXT[m], 18, func() -> void: _set_mode(m))
		b.clip_text = true
		b.custom_minimum_size = Vector2(90, 0)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		modes.add_child(b)
		_mode_buttons[m] = b
	_court = Control.new()
	_court.custom_minimum_size = Vector2(400, 560 if desk and desk.remote else 760)
	_court.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_court.mouse_filter = Control.MOUSE_FILTER_STOP
	_court.draw.connect(_draw_court)
	_court.gui_input.connect(_court_input)
	left.add_child(_court)
	var hint := _label("hint", "", 20, GOLD)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # never wider than the court
	hint.custom_minimum_size = Vector2(400, 52)
	left.add_child(hint)
	# Right: what the numbers say, the breakdown, the machine.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	body.add_child(right)
	right.add_child(_label("h_ins", "WHAT THE NUMBERS SAY", 22, DIM))
	var ins := _label("insights", "", 27, TEXT)
	ins.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ins.custom_minimum_size = Vector2(500, 270)
	right.add_child(ins)
	right.add_child(_label("split", "", 24, TEXT))
	_partner_box = VBoxContainer.new()
	_partner_box.add_theme_constant_override("separation", 10)
	right.add_child(_partner_box)
	_partner_box.add_child(_label("h_part", "PACE AND SIZE", 22, DIM))
	for i in MAX_SLIDERS:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		var name := _label("s_%d_n" % i, "", 24, TEXT)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(name)
		var at := i
		h.add_child(_button("-", 32, func() -> void: _tune(at, -1)))
		var val := _label("s_%d" % i, "", 26, GOLD)
		val.custom_minimum_size = Vector2(150, 0)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		h.add_child(val)
		h.add_child(_button("+", 32, func() -> void: _tune(at, 1)))
		_partner_box.add_child(h)
		_slider_rows.append(h)
	_machine_box = VBoxContainer.new()
	_machine_box.add_theme_constant_override("separation", 10)
	right.add_child(_machine_box)
	_machine_box.add_child(_label("h_mach", "BALL MACHINE", 22, DIM))
	for row in MACHINE:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		var name := _label("m_" + row[0] + "_n", row[1], 24, TEXT)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(name)
		var k: String = row[0]
		h.add_child(_button("-", 32, func() -> void: _step(k, -1)))
		var val := _label("m_" + row[0], "", 26, GOLD)
		val.custom_minimum_size = Vector2(150, 0)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		h.add_child(val)
		h.add_child(_button("+", 32, func() -> void: _step(k, 1)))
		_machine_box.add_child(h)
	var go := _button("START THE MACHINE", 28, func() -> void: desk.handle({"type": "machine_start"}))
	go.add_theme_stylebox_override("normal", _box(GOLD, 10))
	go.add_theme_color_override("font_color", Color(0.1, 0.08, 0.0))
	_labels["go"] = go
	_machine_box.add_child(go)
	_set_mode(mode)


## COACH VIEW: the session's controls the phone page has, for a coach
## watching from another game: the drill and level, START, PAUSE or
## RESUME, RESTART, MENU, and a cue to say.
func _build_session(root: VBoxContainer) -> void:
	var pick := HBoxContainer.new()
	pick.add_theme_constant_override("separation", 8)
	root.add_child(pick)
	for k in [["drill", "drills"], ["level", "levels"]]:
		var key: String = k[0]
		var list: String = k[1]
		if key == "level":
			var gap := Control.new()
			gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			pick.add_child(gap)
		pick.add_child(_button("<", 24, func() -> void: _pick(key, list, -1)))
		var l := _label("set_" + key, "", 24, TEXT)
		l.custom_minimum_size = Vector2(180 if key == "drill" else 120, 0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.clip_text = true
		pick.add_child(l)
		pick.add_child(_button(">", 24, func() -> void: _pick(key, list, 1)))
	var go := HBoxContainer.new()
	go.add_theme_constant_override("separation", 8)
	root.add_child(go)
	for k in [["s_start", "START"], ["s_pause", "PAUSE"], ["s_restart", "RESTART"], ["s_menu", "MENU"]]:
		var key: String = k[0]
		var b := _button(k[1], 24, func() -> void: _session(key))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		go.add_child(b)
		_labels[key] = b
	var cues := HFlowContainer.new()
	cues.add_theme_constant_override("h_separation", 6)
	cues.add_theme_constant_override("v_separation", 6)
	root.add_child(cues)
	for c in CoachDesk.CUES:
		var text: String = c
		cues.add_child(_button(text, 18, func() -> void: desk.handle({"type": "cue", "text": text})))


## A step through the drills or levels the player's headset offers.
func _pick(key: String, list: String, dir: int) -> void:
	var setup: Dictionary = _state.get("setup", {})
	var names: Array = setup.get(list, [])
	if names.is_empty():
		return
	desk.handle({"type": "set", "key": key, "value": posmod(int(setup.get(key, 0)) + dir, names.size())})


func _session(key: String) -> void:
	match key:
		"s_start": desk.handle({"type": "start"})
		"s_pause": desk.handle({"type": "resume" if String(_state.get("where", "")) == "paused" else "pause"})
		"s_restart": desk.handle({"type": "restart"})
		"s_menu": desk.handle({"type": "menu"})


func _label(key: String, text: String, size: int, c: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", c)
	_labels[key] = l
	return l


func _button(text: String, size: int, on: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_stylebox_override("normal", _box(PANEL, 10))
	b.add_theme_stylebox_override("hover", _box(LINE, 10))
	b.add_theme_stylebox_override("pressed", _box(LINE, 10))
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(on)
	return b


static func _box(c: Color, r: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(r)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s


func _set_mode(m: String) -> void:
	mode = m
	for k in _mode_buttons:
		(_mode_buttons[k] as Button).add_theme_stylebox_override("normal", _box(LINE if k == m else PANEL, 10))
	(_labels["hint"] as Label).text = HINTS[m]


## A partner drill's pace or size (C-11's sliders), a step either way.
func _tune(i: int, dir: int) -> void:
	if i >= _slider_ids.size():
		return
	var id: String = _slider_ids[i]
	var e := Tune.entry(id)
	var now: int = _slider_vals[i] if i < _slider_vals.size() else Tune.value(id)
	desk.handle({"type": "tune", "id": id, "value": clampi(now + dir * int(e[7]), e[8], e[9])})
	refresh()


func _step(key: String, dir: int) -> void:
	for row in MACHINE:
		if row[0] == key:
			var m: Dictionary = desk.machine_settings()
			var v := clampf(float(m[key]) + dir * float(row[2]), float(row[3]), float(row[4]))
			desk.handle({"type": "machine_set", key: snappedf(v, 0.01)})
	refresh()


# --- The court ---------------------------------------------------------------------

func _geom() -> Dictionary:
	var hw := K.COURT_HALF_WIDTH / 1e6
	var hl := K.COURT_HALF_LENGTH / 1e6
	var m := 0.4
	var sz := _court.size
	var s := minf(sz.x / (2 * hw + 2 * m), sz.y / (2 * hl + 2 * m))
	var off := Vector2((sz.x - (2 * hw + 2 * m) * s) / 2, (sz.y - (2 * hl + 2 * m) * s) / 2)
	return {"hw": hw, "hl": hl, "m": m, "s": s, "off": off}


## Court metres (x, z) to the panel's pixels: their side up.
func _px(g: Dictionary, x: float, z: float) -> Vector2:
	return g["off"] + Vector2(x + g["hw"] + g["m"], z + g["hl"] + g["m"]) * float(g["s"])


func _draw_court() -> void:
	var g := _geom()
	var hw: float = g["hw"]
	var hl: float = g["hl"]
	var kd := K.KITCHEN_DEPTH / 1e6
	var s: float = g["s"]
	_court.draw_rect(Rect2(_px(g, -hw, -hl), Vector2(2 * hw, hl) * s), COURT)
	_court.draw_rect(Rect2(_px(g, -hw, 0), Vector2(2 * hw, hl) * s), MINE)
	_court.draw_rect(Rect2(_px(g, -hw, -kd), Vector2(2 * hw, 2 * kd) * s), KITCHEN)
	var w := maxf(s * 0.05, 1.5)
	_court.draw_rect(Rect2(_px(g, -hw, -hl), Vector2(2 * hw, 2 * hl) * s), TEXT, false, w)
	for z in [-kd, kd]:
		_court.draw_line(_px(g, -hw, z), _px(g, hw, z), TEXT, w)
	_court.draw_line(_px(g, 0, -kd), _px(g, 0, -hl), TEXT, w)
	_court.draw_line(_px(g, 0, kd), _px(g, 0, hl), TEXT, w)
	_court.draw_line(_px(g, -hw - 0.2, 0), _px(g, hw + 0.2, 0), TEXT, w * 2.5)
	var t: Dictionary = _state.get("target", {})
	if t.get("lit", false):
		var rings: Array = t.get("rings", [100, 66, 33])
		for i in rings.size():
			_court.draw_circle(_px(g, t["x"], t["z"]), float(t["r"]) * s * float(rings[i]) / 100.0,
				Color(GOLD, 0.15 + 0.15 * i))
	var mc: Dictionary = _state.get("machine", {})
	if _machine and (mc.get("on", false) or mode in ["MACHINE", "BOUNCE"]):
		var a := _px(g, mc.get("x", 0.0), mc.get("z", -7.0))
		var b := _px(g, mc.get("bx", 0.0), mc.get("bz", 4.0))
		_court.draw_dashed_line(a, b, Color(GOLD, 0.8), w, s * 0.15)
		_court.draw_rect(Rect2(a - Vector2(14, 11), Vector2(28, 22)), Color(0.82, 0.84, 0.9))
		_court.draw_arc(b, s * 0.22, 0, TAU, 24, GOLD, w * 1.4)
	var f: Dictionary = _state.get("feed", {})
	if not f.is_empty():
		var p := _px(g, f["x"], f["z"])
		_court.draw_line(p - Vector2(9, 9), p + Vector2(9, 9), GOLD, 3)
		_court.draw_line(p + Vector2(9, -9), p - Vector2(9, -9), GOLD, 3)
	var shots: Array = desk.run_shots() if desk else []
	var pend: Dictionary = desk.pending if desk else {}
	if pend.has("target"):
		var at := _px(g, pend["target"][0], pend["target"][1])
		var r := Drill.TARGET_RADIUS / 1e6 * s
		for k in 3:
			_court.draw_arc(at, r * (1.0 - 0.33 * k), 0, TAU, 32, GOLD, w * 1.5)
	if pend.has("feed"):
		var p := _px(g, pend["feed"][0], pend["feed"][1])
		_court.draw_line(p - Vector2(12, 12), p + Vector2(12, 12), GOLD, 4)
		_court.draw_line(p + Vector2(12, -12), p - Vector2(12, -12), GOLD, 4)
	for i in shots.size():
		var sh: Dictionary = shots[i]
		if not sh.has("x"):
			continue
		var c := GOLD if int(sh.get("ring", 0)) > 0 else (GOOD if sh.get("good", false) else BAD)
		_court.draw_circle(_px(g, sh["x"], sh["z"]), 9.0 if i == shots.size() - 1 else 6.0, c)


func _court_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
		return
	var g := _geom()
	var p: Vector2 = (e.position - g["off"]) / float(g["s"]) - Vector2(g["hw"] + g["m"], g["hl"] + g["m"])
	tap(clampf(p.x, -g["hw"], g["hw"]), clampf(p.y, -g["hl"], g["hl"]))


## A tap on the court at (x, z) metres, as the mode reads it.
func tap(x: float, z: float) -> void:
	var their := z < -0.3
	var yours := z > 0.3
	var ok := their if mode in ["TARGET", "MACHINE"] else yours
	(_labels["hint"] as Label).text = DONE[mode] if ok else WRONG[mode]
	if not ok:
		return
	match mode:
		"TARGET":
			if their:
				desk.handle({"type": "target", "x": x, "z": z})
		"FEED":
			if yours:
				desk.handle({"type": "feed", "x": x, "z": z})
		"MACHINE":
			if their:
				desk.handle({"type": "machine_set", "x": x, "z": z})
		"BOUNCE":
			if yours:
				desk.handle({"type": "machine_set", "bx": x, "bz": z})
	refresh()


# --- Keeping it current ------------------------------------------------------------

func _process(delta: float) -> void:
	lock = maxf(lock - delta, 0.0)
	if not visible:
		return
	_t += delta
	if _t >= REFRESH:
		_t = 0.0
		refresh()


func refresh() -> void:
	if desk == null or _court == null:
		return
	_state = desk.state()
	var r: Dictionary = _state.get("run", {})
	(_labels["run"] as Label).text = String(r.get("name", "")) if not r.is_empty() else ""
	var timed: bool = r.get("timed", false)
	(_labels["score"] as Label).text = str(r.get("score" if timed else "streak", "-")) if not r.is_empty() else "-"
	(_labels["score_l"] as Label).text = "SCORE" if timed else "STREAK"
	var left := int(r.get("left", 0))
	(_labels["time"] as Label).text = ("%d:%02d" % [left / 60, left % 60]) if timed else "-"
	var shots: Array = desk.run_shots()        # this drill's: switching drills starts it clean
	var good := shots.filter(func(s: Dictionary) -> bool: return s.get("good", false)).size()
	(_labels["good"] as Label).text = "%d%%" % roundi(100.0 * good / shots.size()) if not shots.is_empty() else "-"
	var cl := shots.filter(func(s: Dictionary) -> bool: return s.has("clear") and float(s["clear"]) >= 0.0)
	var mean := 0.0
	for s in cl:
		mean += float(s["clear"])
	(_labels["clear"] as Label).text = str(roundi(100 * mean / cl.size())) if not cl.is_empty() else "-"
	(_labels["insights"] as Label).text = "\n".join(CoachDesk.insights(shots).map(func(t: String) -> String: return "- " + t))
	(_labels["split"] as Label).text = CoachDesk.split_line(shots).replace("   ", "\n")
	var mc: Dictionary = _state.get("machine", {})
	for row in MACHINE:
		var v := float(mc.get(row[0], 0.0))
		var t := ""
		match String(row[0]):
			"speed": t = "%.1f M/S" % v
			"spin": t = ("TOP %d%%" % v) if v > 0 else (("BACK %d%%" % -v) if v < 0 else "FLAT")
			"clear": t = "%d CM" % roundi(v * 100)
			"every": t = "%.2f S" % v
		(_labels["m_" + row[0]] as Label).text = t
	(_labels["go"] as Button).text = "RESTART THE MACHINE" if mc.get("on", false) else "START THE MACHINE"
	if _labels.has("s_pause"):
		var setup: Dictionary = _state.get("setup", {})
		for k in [["drill", "drills"], ["level", "levels"]]:
			var names: Array = setup.get(k[1], [])
			var at := int(setup.get(k[0], 0))
			(_labels["set_" + k[0]] as Label).text = String(names[at]) if at < names.size() else "-"
		var where := String(_state.get("where", ""))
		(_labels["s_pause"] as Button).text = "RESUME" if where == "paused" else "PAUSE"
		(_labels["s_pause"] as Button).disabled = where == "lobby"
		(_labels["s_restart"] as Button).disabled = where == "lobby"
	_show_context()
	_court.queue_redraw()


## The drill's own controls: the machine's, or a partner drill's.
func _show_context() -> void:
	var v: MatchView = desk.current_view()
	_machine = v != null and v.sim != null and v.sim.drill != null and not v.sim.drill.partner
	_machine_box.visible = _machine
	_partner_box.visible = not _machine
	var allowed: Array = MACHINE_MODES if _machine else PARTNER_MODES
	for k in _mode_buttons:
		(_mode_buttons[k] as Button).visible = allowed.has(k)
	if not allowed.has(mode):
		_set_mode(allowed[0])
	var tunes: Array = _state.get("tunes", [])
	_slider_ids = []
	_slider_vals = []
	for i in MAX_SLIDERS:
		var row: HBoxContainer = _slider_rows[i]
		row.visible = i < tunes.size()
		if i < tunes.size():
			var t: Dictionary = tunes[i]
			_slider_ids.append(t["id"])
			_slider_vals.append(int(t["value"]))
			(_labels["s_%d_n" % i] as Label).text = String(t["label"])
			(_labels["s_%d" % i] as Label).text = String(t["text"]) + (" *" if t["value"] != t["default"] else "")


## Lays the panel out now, not next frame (tests: like a menu's settle()).
func settle() -> void:
	for i in 2:
		for c in (_holder if overlay else _vp).find_children("*", "Container", true, false):
			c.notification(Container.NOTIFICATION_SORT_CHILDREN)


# --- Pointing ----------------------------------------------------------------------

## Where a ray meets the panel, in its pixels; null if it misses.
func hit_px(origin: Vector3, dir: Vector3) -> Variant:
	var inv := global_transform.affine_inverse()
	var o := inv * origin
	var d := inv.basis * dir
	if absf(d.z) < 0.0001:
		return null
	var t := -o.z / d.z
	if t <= 0.0:
		return null
	var h := o + d * t
	if absf(h.x) > SIZE.x / 2 or absf(h.y) > SIZE.y / 2:
		return null
	return Vector2((h.x / SIZE.x + 0.5) * PX.x, (0.5 - h.y / SIZE.y) * PX.y)


## The laser or the mouse: hover moves the panel's pointer; a click clicks
## there. Returns whether it's on the panel.
func point(origin: Vector3, dir: Vector3, click: bool) -> bool:
	if overlay:
		return false                     # on the screen: the mouse uses it directly
	var p: Variant = hit_px(origin, dir)
	if p == null:
		return false
	var mv := InputEventMouseMotion.new()
	mv.position = p
	mv.global_position = p
	_vp.push_input(mv)
	if click and lock <= 0.0:
		for down in [true, false]:
			var b := InputEventMouseButton.new()
			b.button_index = MOUSE_BUTTON_LEFT
			b.pressed = down
			b.position = p
			b.global_position = p
			_vp.push_input(b)
	return true
