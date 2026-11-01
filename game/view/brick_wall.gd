## BRICK BREAK's wall (ADR-030): the bricks across the far court (one draw,
## a MultiMesh), the dark wall behind them with the launcher's ring, glass
## either side of their half, and the level, balls and score over the top.
## A brick flashes when it's hit and bursts when it breaks; the glass
## glows where a ball comes off it. Display only: it reads the sim.
class_name BrickWall
extends Node3D

## A brick's colour by row, bottom up (a 1-hit brick); 2 and 3 hits are
## silver and gold, steel is dark.
const ROW_COLORS := [Color(1.0, 0.3, 0.28), Color(1.0, 0.55, 0.15), Color(0.4, 0.88, 0.3),
	Color(0.2, 0.78, 0.9), Color(0.35, 0.48, 1.0), Color(0.75, 0.4, 0.95)]
const SILVER := Color(0.66, 0.7, 0.78)
const GOLD := Color(1.0, 0.88, 0.25)
const STEEL_COLOR := Color(0.44, 0.46, 0.52)
const BACK := Color(0.06, 0.08, 0.16)
const GLASS := Color(0.55, 0.85, 1.0, 0.1)
const DEPTH := 0.18                  ## a brick's thickness, m
const GAP := 0.035                   ## between bricks, m
const FLASH := 0.14                  ## s: a hit brick's white flash
const BREAK := 0.18                  ## s: a broken brick shrinking away
const BURSTS := 4

var _mm: MultiMesh
var _shown: Array[int] = []          ## the hits each brick was last drawn with
var _flash: Array[float] = []        ## seconds of flash left, per brick
var _going: Array[float] = []        ## seconds of breaking left, per brick
var _glass: Array[MeshInstance3D] = []
var _glass_glow := [0.0, 0.0]
var _bursts: Array[CPUParticles3D] = []
var _next_burst := 0
var _ring: MeshInstance3D
var label: Label3D
var _t := 0.0


static func wall_z() -> float:
	return Breakout.WALL_Z / float(K.M)


func _ready() -> void:
	var hw := K.COURT_HALF_WIDTH / float(K.M)
	var top := Breakout.WALL_TOP / float(K.M)
	var z := wall_z()
	var back := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(hw * 2 + 0.2, top, 0.12)
	back.mesh = bm
	back.material_override = World.material(BACK)
	back.position = Vector3(0, top / 2, z - DEPTH - 0.06)
	add_child(back)
	# The launcher: a glowing ring in the wall, where each new ball shows.
	_ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.11
	tm.outer_radius = 0.15
	_ring.mesh = tm
	_ring.rotation_degrees = Vector3(90, 0, 0)
	_ring.position = Vector3(0, Breakout.LAUNCH_Y / float(K.M), z - 0.01)
	_ring.material_override = _glow(Color(0.4, 1.0, 0.9))
	add_child(_ring)
	# The glass, either side of their half, from the net to the wall.
	for s in [-1, 1]:
		var g := MeshInstance3D.new()
		var gm := BoxMesh.new()
		gm.size = Vector3(0.03, top, -z)
		g.mesh = gm
		var mat := _glow(GLASS)
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		g.material_override = mat
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g.position = Vector3(s * (hw + 0.015), top / 2, z / 2)
		add_child(g)
		_glass.append(g)
		var rail := MeshInstance3D.new()
		var rm := BoxMesh.new()
		rm.size = Vector3(0.06, 0.06, -z)
		rail.mesh = rm
		rail.material_override = World.material(Color(0.75, 0.8, 0.85))
		rail.position = Vector3(s * (hw + 0.015), top, z / 2)
		add_child(rail)
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	var brick := BoxMesh.new()
	brick.size = Vector3(Breakout.BRICK_W / float(K.M) - GAP, Breakout.BRICK_H / float(K.M) - GAP, DEPTH)
	_mm.mesh = brick
	_mm.instance_count = Breakout.COLS * Breakout.ROWS
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _mm
	var m := World.material(Color.WHITE)
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.45
	m.metallic = 0.15
	mmi.material_override = m
	add_child(mmi)
	for i in _mm.instance_count:
		_shown.append(0)
		_flash.append(0.0)
		_going.append(0.0)
		_place(i, 0.0)
	for i in BURSTS:
		var p := CPUParticles3D.new()
		p.emitting = false
		p.one_shot = true
		p.amount = 14
		p.lifetime = 0.7
		p.explosiveness = 1.0
		p.direction = Vector3(0, 0.3, 1)
		p.spread = 70.0
		p.initial_velocity_min = 1.5
		p.initial_velocity_max = 3.5
		p.gravity = Vector3(0, -9.8, 0)
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p.emission_box_extents = Vector3(Breakout.BRICK_W / float(K.M) / 2, Breakout.BRICK_H / float(K.M) / 2, 0.05)
		var cube := BoxMesh.new()
		cube.size = Vector3(0.07, 0.05, 0.05)
		p.mesh = cube
		var pm := World.material(Color.WHITE)
		pm.vertex_color_use_as_albedo = true
		p.material_override = pm
		add_child(p)
		_bursts.append(p)
	label = Label3D.new()
	label.font_size = 160
	label.pixel_size = 0.004
	label.outline_size = 20
	label.modulate = Color(1, 0.9, 0.4)
	label.outline_modulate = Color(0, 0, 0, 0.8)
	label.position = Vector3(0, top + 0.45, z - 0.1)
	add_child(label)


static func _glow(c: Color) -> StandardMaterial3D:
	var m := World.material(c)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


## A brick's colour with `hits` left (and on row `row`).
static func color_of(hits: int, row: int) -> Color:
	match hits:
		Breakout.STEEL: return STEEL_COLOR
		2: return SILVER
		3: return GOLD
	return ROW_COLORS[row % ROW_COLORS.size()]


## Brick `i` drawn as it is now; `shrink` 0..1 as it breaks away.
func _place(i: int, shrink: float) -> void:
	var at := Breakout.brick_at(i)
	var s := 1.0 - shrink
	var t := Transform3D(Basis.from_scale(Vector3(s, s, s)),
		Vector3(at[0] / float(K.M), at[1] / float(K.M), wall_z() - DEPTH / 2))
	var h := _shown[i]
	if h == 0 and _going[i] <= 0.0:
		t = Transform3D(Basis.from_scale(Vector3.ZERO), t.origin)
	_mm.set_instance_transform(i, t)
	var c := color_of(h, i / Breakout.COLS) if h != 0 else Color(1, 1, 1)
	if _flash[i] > 0.0:
		c = c.lerp(Color.WHITE, _flash[i] / FLASH)
	_mm.set_instance_color(i, c)


## A brick hit: a flash, or (broken) a burst of its colour.
func hit(i: int, hits_left: int) -> void:
	if i < 0 or i >= _flash.size():
		return
	_flash[i] = FLASH
	if hits_left == 0:
		var row := i / Breakout.COLS
		var c := color_of(_shown[i] if _shown[i] > 0 else 1, row)
		_going[i] = BREAK
		var p := _bursts[_next_burst]
		_next_burst = (_next_burst + 1) % _bursts.size()
		var at := Breakout.brick_at(i)
		p.position = Vector3(at[0] / float(K.M), at[1] / float(K.M), wall_z())
		p.color = c
		p.restart()


## A ball off the glass on side `s` (the sign of x).
func glass_hit(s: int) -> void:
	_glass_glow[0 if s < 0 else 1] = 1.0


func show_from(sim: Sim, delta: float) -> void:
	var bo := sim.breakout
	_t += delta
	for i in bo.hp.size():
		var was_flash := _flash[i] > 0.0
		var was_going := _going[i] > 0.0
		_flash[i] = maxf(_flash[i] - delta, 0.0)
		_going[i] = maxf(_going[i] - delta, 0.0)
		if bo.hp[i] != _shown[i] and _going[i] <= 0.0:
			_shown[i] = bo.hp[i]
			_place(i, 0.0)
		elif was_flash or was_going:
			_place(i, 1.0 - _going[i] / BREAK if _going[i] > 0.0 else 0.0)
	for k in 2:
		_glass_glow[k] = maxf(_glass_glow[k] - delta * 3.0, 0.0)
		var mat: StandardMaterial3D = _glass[k].material_override
		mat.albedo_color = Color(GLASS, GLASS.a + 0.35 * _glass_glow[k])
	# The launcher glows while a ball waits in it.
	var waiting := bo.stage == Breakout.SERVE
	_ring.scale = Vector3.ONE * (1.0 + (0.12 * sin(_t * 8.0) if waiting else 0.0))
	(_ring.material_override as StandardMaterial3D).albedo_color = Color(0.4, 1.0, 0.9) if waiting else Color(0.2, 0.45, 0.45)
	var balls := ""
	for k in maxi(bo.lives, 0):
		balls += " o"
	match bo.stage:
		Breakout.OVER:
			label.text = "GAME OVER   %d" % bo.score
		Breakout.CLEAR:
			label.text = "LEVEL %d CLEAR!   %d" % [bo.level + 1, bo.score]
		_:
			label.text = "LEVEL %d   BALLS%s   %d" % [bo.level + 1, balls, bo.score]
