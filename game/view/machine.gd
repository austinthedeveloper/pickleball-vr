## The ball machine on the far baseline (ADR-007): a cart with a hopper
## of balls and a nozzle that turns toward the next feed and kicks back
## when it fires. Display only.
class_name Machine
extends Node3D

var nozzle: Node3D
var _kick := 0.0
var _yaw := 0.0


func _ready() -> void:
	position = World.m(0, 0, Drill.BASELINE_Z)
	_box(Vector3(0, 0.35, 0), Vector3(0.55, 0.5, 0.45), Color(0.25, 0.3, 0.38))
	_box(Vector3(0, 0.7, 0.05), Vector3(0.5, 0.22, 0.4), Color(0.85, 0.82, 0.2))   # the hopper
	for i in 9:
		var ball := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = K.BALL_RADIUS / float(K.M)
		sm.height = sm.radius * 2
		ball.mesh = sm
		ball.material_override = World.material(Color(0.88, 1.0, 0.12))
		ball.position = Vector3(-0.15 + 0.15 * (i % 3), 0.83, -0.08 + 0.13 * (i / 3))
		add_child(ball)
	for s in [-1, 1]:
		var wheel := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.1
		cm.bottom_radius = 0.1
		cm.height = 0.05
		wheel.mesh = cm
		wheel.material_override = World.material(Color(0.1, 0.1, 0.1))
		wheel.rotation.z = PI / 2
		wheel.position = Vector3(s * 0.3, 0.1, 0.1)
		add_child(wheel)
	nozzle = Node3D.new()
	nozzle.position = Vector3(0, 0.9, -0.1)
	add_child(nozzle)
	var tube := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.06
	tm.bottom_radius = 0.08
	tm.height = 0.35
	tube.mesh = tm
	tube.material_override = World.material(Color(0.15, 0.15, 0.18))
	tube.rotation.x = PI / 2 - 0.25
	tube.position = Vector3(0, 0.02, 0.15)
	nozzle.add_child(tube)


func _box(at: Vector3, size: Vector3, c: Color) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = World.material(c)
	mi.position = at
	add_child(mi)


## Turn toward the drill's aim; kick on a feed.
func show_from(sim: Sim, delta: float) -> void:
	var d := sim.drill
	position.z = d.machine_z / float(K.M)          # the baseline, or the kitchen line
	var target := atan2(d.aim_x / float(K.M), absf(d.machine_z) / float(K.M) * 1.5)
	_yaw = lerpf(_yaw, target, clampf(delta * 6.0, 0.0, 1.0))
	_kick = maxf(_kick - delta * 5.0, 0.0)
	nozzle.rotation.y = -_yaw
	nozzle.position.z = -0.1 - 0.08 * _kick


func kick() -> void:
	_kick = 1.0
