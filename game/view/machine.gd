## The ball machine (ADR-007, ADR-012), facing you from its spot on the
## baseline or their kitchen line. Display only:
## - a wheeled base with a handle, and a clear hopper whose balls empty
##   one per feed (and refill);
## - a launch head on a turret that turns and tilts along each feed's line,
##   its two throwing wheels spinning with SPEED;
## - just before a feed, a ball rolls down from the hopper into the head;
##   on the feed the head kicks back;
## - a light on top counts down to the next feed (green, then blinking),
##   and turns red when a lesson is done.
class_name Machine
extends Node3D

const BODY := Color(0.18, 0.2, 0.24)
const ACCENT := Color(0.98, 0.62, 0.12)
const CAPACITY := 40
const LOAD_TIME := 0.35              ## seconds the next ball takes from hopper to head
const MOUTH_Z := 0.36                ## the mouth, in front of the model's centre

var turret: Node3D                   ## yaws
var head: Node3D                     ## pitches; the ball leaves along its -z... toward you (+z)
var nozzle: Node3D                   ## kept for the old name: the head
var _wheels: Array[MeshInstance3D] = []
var _light: MeshInstance3D
var _light_m: StandardMaterial3D
var _balls: MultiMeshInstance3D
var _loading: MeshInstance3D
var _kick := 0.0
var _yaw := 0.0
var _pitch := 0.15
var _want_yaw := 0.0
var _want_pitch := 0.15
var _spin := 0.0
var _feeds_seen := -1
var _t := 0.0


func _ready() -> void:
	position = World.m(0, 0, Drill.BASELINE_Z)
	var body_m := _mat(BODY, 0.5)
	# The base, with an accent band and a vent grille.
	_box(Vector3(0, 0.27, 0), Vector3(0.5, 0.3, 0.56), body_m)
	_box(Vector3(0, 0.3, 0.282), Vector3(0.46, 0.06, 0.006), _mat(ACCENT, 0.5))
	for s in [-1, 1]:
		_box(Vector3(s * 0.252, 0.3, 0), Vector3(0.006, 0.06, 0.5), _mat(ACCENT, 0.5))
		for k in 4:
			_box(Vector3(s * 0.253, 0.2, -0.15 + k * 0.1), Vector3(0.004, 0.08, 0.02), _mat(Color(0.08, 0.08, 0.1), 0.8))
	# Wheels at the back, casters at the front, the handle up behind.
	for s in [-1, 1]:
		var w := _cyl(Vector3(s * 0.27, 0.12, -0.18), 0.12, 0.05, _mat(Color(0.07, 0.07, 0.08), 0.9))
		w.rotation.z = PI / 2
		var hub := _cyl(Vector3(s * 0.297, 0.12, -0.18), 0.045, 0.012, _mat(Color(0.7, 0.7, 0.72), 0.3))
		hub.rotation.z = PI / 2
		_cyl(Vector3(s * 0.18, 0.04, 0.2), 0.035, 0.08, _mat(Color(0.1, 0.1, 0.1), 0.9))
		_cyl(Vector3(s * 0.2, 0.42, -0.27), 0.014, 0.55, _mat(Color(0.75, 0.76, 0.78), 0.3))
	var bar := _cyl(Vector3(0, 0.95, -0.27), 0.016, 0.42, _mat(Color(0.75, 0.76, 0.78), 0.3))
	bar.rotation.z = PI / 2
	var grip := _cyl(Vector3(0, 0.95, -0.27), 0.022, 0.24, _mat(Color(0.1, 0.1, 0.1), 0.9))
	grip.rotation.z = PI / 2
	# The hopper: a clear, open bin on top, wider at the rim.
	var clear := _mat(Color(0.75, 0.85, 0.95, 0.22), 0.1)
	clear.cull_mode = BaseMaterial3D.CULL_DISABLED
	var rim := _mat(Color(0.85, 0.87, 0.9), 0.4)
	for s in [-1, 1]:
		var side := _box(Vector3(s * 0.235, 0.6, -0.05), Vector3(0.008, 0.3, 0.46), clear)
		side.rotation.z = s * -0.12
		var end := _box(Vector3(0, 0.6, -0.05 + s * 0.225), Vector3(0.46, 0.3, 0.008), clear)
		end.rotation.x = s * 0.12
		_box(Vector3(s * 0.255, 0.755, -0.05), Vector3(0.02, 0.02, 0.5), rim)
		_box(Vector3(0, 0.755, -0.05 + s * 0.245), Vector3(0.52, 0.02, 0.02), rim)
	_balls = MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _ball_mesh()
	mm.instance_count = CAPACITY
	_balls.multimesh = mm
	_balls.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_balls)
	var r := K.BALL_RADIUS / float(K.M)
	for i in CAPACITY:                 # packed in layers, the top ones first to go
		var layer := i / 16
		var k := i % 16
		var at := Vector3(-0.15 + (k % 4) * 0.1 + (layer % 2) * 0.04, 0.47 + layer * r * 1.7, -0.2 + (k / 4) * 0.1)
		mm.set_instance_transform(CAPACITY - 1 - i, Transform3D(Basis(), at))
	# The turret and the launch head, at the front above the base.
	turret = Node3D.new()
	turret.position = Vector3(0, 0.82, 0.2)       # the mouth at the sim's release height, 0.9 m
	add_child(turret)
	_cyl(Vector3(0, 0.6, 0.2), 0.03, 0.42, body_m)  # the post up to it
	_cyl_on(turret, Vector3(0, -0.04, 0), 0.07, 0.06, body_m)
	head = Node3D.new()
	head.position = Vector3(0, 0.08, 0)
	turret.add_child(head)
	nozzle = head
	_box_on(head, Vector3(0, 0, 0), Vector3(0.24, 0.13, 0.22), _mat(ACCENT, 0.45))
	_box_on(head, Vector3(0, 0.068, -0.02), Vector3(0.2, 0.01, 0.16), body_m)
	for s in [-1, 1]:                  # the throwing wheels, either side of the throat
		var w := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.075
		cm.bottom_radius = 0.075
		cm.height = 0.035
		cm.radial_segments = 14
		w.mesh = cm
		w.material_override = _mat(Color(0.25, 0.25, 0.28), 0.8)
		w.position = Vector3(s * 0.06, 0, 0.1)
		head.add_child(w)
		_wheels.append(w)
		_box_on(w, Vector3(0.05, 0.018, 0), Vector3(0.03, 0.002, 0.015), _mat(Color(0.95, 0.95, 0.95), 0.5))   # a mark, to see it spin
	var mouth := _cyl_on(head, Vector3(0, 0, 0.16), 0.045, 0.06, _mat(Color(0.05, 0.05, 0.06), 0.9))
	mouth.rotation.x = PI / 2
	_light = MeshInstance3D.new()
	var lm := SphereMesh.new()
	lm.radius = 0.022
	lm.height = 0.03
	_light.mesh = lm
	_light_m = _mat(Color(0.2, 1.0, 0.3), 0.3)
	_light_m.emission_enabled = true
	_light_m.emission = Color(0.2, 1.0, 0.3)
	_light.material_override = _light_m
	_light.position = Vector3(0.08, 0.08, -0.06)
	head.add_child(_light)
	_loading = MeshInstance3D.new()
	_loading.mesh = _ball_mesh()
	add_child(_loading)
	_loading.visible = false


static func _ball_mesh() -> SphereMesh:
	var sm := SphereMesh.new()
	sm.radius = K.BALL_RADIUS / float(K.M)
	sm.height = sm.radius * 2
	sm.radial_segments = 10
	sm.rings = 5
	sm.material = Look.ball_material()
	return sm


static func _mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := World.material(c)
	m.roughness = rough
	return m


func _box(at: Vector3, size: Vector3, m: Material) -> MeshInstance3D:
	return _box_on(self, at, size, m)


func _box_on(parent: Node3D, at: Vector3, size: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	if size.length() < 0.2 or (m as BaseMaterial3D).albedo_color.a < 1.0:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.material_override = m
	mi.position = at
	parent.add_child(mi)
	return mi


func _cyl(at: Vector3, r: float, h: float, m: Material) -> MeshInstance3D:
	return _cyl_on(self, at, r, h, m)


func _cyl_on(parent: Node3D, at: Vector3, r: float, h: float, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = 14
	mi.mesh = cm
	mi.material_override = m
	mi.position = at
	parent.add_child(mi)
	return mi


func show_from(sim: Sim, delta: float) -> void:
	var d := sim.drill
	_t += delta
	position.z = d.machine_z / float(K.M) - MOUTH_Z  # the ball leaves the mouth where the sim releases it
	# A new feed: aim the head along the ball's way out, and kick.
	if d.feeds != _feeds_seen:
		if _feeds_seen >= 0 and d.stage == Drill.FLY:
			var v := Vector3(sim.ball.vx, sim.ball.vy, sim.ball.vz)
			_want_yaw = atan2(v.x, v.z)
			_want_pitch = atan2(v.y, Vector2(v.x, v.z).length())
			_kick = 1.0
			_spin += 1.5                  # the wheels bite
		_feeds_seen = d.feeds
		_refill(d.feeds)
	_yaw = lerp_angle(_yaw, _want_yaw, clampf(delta * 7.0, 0.0, 1.0))
	_pitch = lerpf(_pitch, clampf(_want_pitch, -0.2, 1.1), clampf(delta * 7.0, 0.0, 1.0))
	_kick = maxf(_kick - delta * 6.0, 0.0)
	turret.rotation.y = _yaw
	head.rotation.x = -_pitch
	head.position.z = -0.04 * _kick
	# The throwing wheels spin with SPEED, in opposite directions.
	var rate := 18.0 + 10.0 * d.speed + 40.0 * _kick
	for i in _wheels.size():
		_wheels[i].rotation.y += (1 if i == 0 else -1) * rate * delta
	# The next ball rolls down into the head; the light counts it down.
	var until := (d.next_feed - sim.tick) / float(K.TICK_HZ)
	var waiting := d.stage == Drill.WAIT and until >= 0.0
	_loading.visible = waiting and until < LOAD_TIME
	if _loading.visible:
		var f := 1.0 - until / LOAD_TIME
		var from := Vector3(0, 0.62, -0.05)
		var to := turret.position + Vector3(0, 0.08, 0.0)
		_loading.position = from.lerp(to, f) + Vector3(0, 0.05 * sin(f * PI), 0)
	var c := Color(0.2, 1.0, 0.3)
	if d.stage == Drill.DONE:
		c = Color(1.0, 0.2, 0.15)
	elif waiting and until < 1.0 and fmod(_t, 0.25) < 0.12:
		c = Color(0.05, 0.25, 0.08)         # blinking: here it comes
	_light_m.albedo_color = c
	_light_m.emission = c


## The hopper empties a ball a feed; empty, it's refilled.
func _refill(feeds: int) -> void:
	var left := CAPACITY - (feeds % CAPACITY)
	_balls.multimesh.visible_instance_count = left


func kick() -> void:
	_kick = 1.0
