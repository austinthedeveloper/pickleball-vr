## A paddle: a handle along +z, the face above it along -z, the face's
## normal along +x (the grip pose's palm axis, ADR-003). The face's centre
## is at FACE_CENTER.
class_name PaddleMesh
extends Node3D

const FACE_CENTER := Vector3(0, 0, -0.2)

var color := Color(0.85, 0.15, 0.2)


func _ready() -> void:
	var face := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.014, 0.2, 0.26)
	face.mesh = bm
	face.material_override = World.material(color)
	face.position = FACE_CENTER
	add_child(face)
	var edge := MeshInstance3D.new()
	var em := BoxMesh.new()
	em.size = Vector3(0.018, 0.21, 0.012)
	edge.mesh = em
	edge.material_override = World.material(Color(0.1, 0.1, 0.1))
	edge.position = FACE_CENTER + Vector3(0, 0, -0.13)
	add_child(edge)
	var grip := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.016
	cm.bottom_radius = 0.016
	cm.height = 0.14
	grip.mesh = cm
	grip.material_override = World.material(Color(0.12, 0.12, 0.12))
	grip.rotation.x = PI / 2
	grip.position = Vector3(0, 0, 0.0)
	add_child(grip)


## The paddle placed so its face centre is at `center` with normal `n`
## (the handle hangs below the face).
func pose(center: Vector3, n: Vector3) -> void:
	var x := n.normalized()
	var up := Vector3.UP
	if absf(x.dot(up)) > 0.95:
		up = Vector3.FORWARD
	# -z (handle to face) points up as far as the normal allows.
	var nz := -(up - x * x.dot(up)).normalized()
	var y := nz.cross(x)
	var b := Basis(x, y, nz)
	transform = Transform3D(b, center - b * FACE_CENTER)
