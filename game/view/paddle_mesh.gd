## A paddle: a handle along +z, the face above it along -z, the face's
## normal along +x (the grip pose's palm axis, ADR-003). The face's centre
## is at FACE_CENTER. A rounded face with an edge guard, a wrapped grip and
## an end cap (ADR-012); the sim's contact disc is unchanged.
class_name PaddleMesh
extends Node3D

const FACE_CENTER := Vector3(0, 0, -0.2)
const FACE_W := 0.198                ## 7.8 in
const FACE_H := 0.26
const FACE_T := 0.013
const CORNER := 0.05
const HANDLE := 0.13

var color := Color(0.85, 0.15, 0.2)
var accent := Color(0.98, 0.95, 0.9)


func _ready() -> void:
	var face := MeshInstance3D.new()
	face.mesh = _rounded_slab(FACE_W, FACE_H, FACE_T, CORNER)
	face.material_override = _mat(color, 0.55)
	face.position = FACE_CENTER
	add_child(face)
	# A stripe across each face, the paddle's "graphic".
	for s in [-1, 1]:
		var stripe := MeshInstance3D.new()
		stripe.mesh = _rounded_slab(FACE_W * 0.82, 0.03, 0.001, 0.012)
		stripe.material_override = _mat(accent, 0.6)
		stripe.position = FACE_CENTER + Vector3(s * (FACE_T / 2 + 0.0006), 0, 0.03)
		add_child(stripe)
	var guard := MeshInstance3D.new()
	guard.mesh = _rounded_ring(FACE_W + 0.006, FACE_H + 0.006, FACE_T + 0.006, CORNER + 0.003, 0.007)
	guard.material_override = _mat(Color(0.1, 0.1, 0.11), 0.4)
	guard.position = FACE_CENTER
	add_child(guard)
	# The grip: a wrapped handle from the face's base to the end cap.
	var grip := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0155
	cm.bottom_radius = 0.017
	cm.height = HANDLE
	cm.radial_segments = 10
	grip.mesh = cm
	grip.material_override = _mat(Color(0.12, 0.12, 0.13), 0.9)
	grip.rotation.x = PI / 2
	grip.position = Vector3(0, 0, FACE_CENTER.z + FACE_H / 2 + HANDLE / 2 - 0.01)
	add_child(grip)
	for k in 4:                          # the wrap's ridges
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.0155
		tm.outer_radius = 0.0185
		tm.rings = 10
		ring.mesh = tm
		ring.material_override = _mat(Color(0.2, 0.2, 0.22), 0.9)
		ring.rotation.x = PI / 2
		ring.position = grip.position + Vector3(0, 0, -HANDLE / 2 + 0.02 + k * 0.03)
		add_child(ring)
	var cap := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.019
	sm.height = 0.022
	cap.mesh = sm
	cap.material_override = _mat(color.darkened(0.3), 0.5)
	cap.position = grip.position + Vector3(0, 0, HANDLE / 2)
	add_child(cap)


static func _mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := World.material(c)
	m.roughness = rough
	return m


## The rounded rectangle's outline in the face's plane (y across, z along),
## counter-clockwise.
static func _outline(w: float, h: float, r: float, seg := 6) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var cx := w / 2 - r
	var cz := h / 2 - r
	for corner in [[cx, cz, 0.0], [-cx, cz, PI / 2], [-cx, -cz, PI], [cx, -cz, 1.5 * PI]]:
		for i in seg + 1:
			var a: float = corner[2] + PI / 2 * i / seg
			pts.append(Vector2(corner[0] + cos(a) * r, corner[1] + sin(a) * r))
	return pts


## A slab of thickness t (along x) with that outline.
static func _rounded_slab(w: float, h: float, t: float, r: float) -> ArrayMesh:
	var o := _outline(w, h, r)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := o.size()
	for side in [-1.0, 1.0]:
		st.set_normal(Vector3(side, 0, 0))
		for i in n:
			var a := o[i]
			var b := o[(i + 1) % n]
			var verts := [Vector3(side * t / 2, 0, 0), Vector3(side * t / 2, a.x, a.y), Vector3(side * t / 2, b.x, b.y)]
			if side < 0:
				verts = [verts[0], verts[2], verts[1]]
			for v in verts:
				st.add_vertex(v)
	for i in n:                          # the rim
		var a := o[i]
		var b := o[(i + 1) % n]
		var nrm := Vector3(0, (a.x + b.x) / 2, (a.y + b.y) / 2).normalized()
		st.set_normal(nrm)
		for v in [Vector3(-t / 2, a.x, a.y), Vector3(t / 2, a.x, a.y), Vector3(t / 2, b.x, b.y),
				Vector3(-t / 2, a.x, a.y), Vector3(t / 2, b.x, b.y), Vector3(-t / 2, b.x, b.y)]:
			st.add_vertex(v)
	return st.commit()


## The edge guard: a band `band` wide around the outline.
static func _rounded_ring(w: float, h: float, t: float, r: float, band: float) -> ArrayMesh:
	var outer := _outline(w, h, r)
	var inner := _outline(w - band * 2, h - band * 2, maxf(r - band, 0.005))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := outer.size()
	for i in n:
		var a := outer[i]
		var b := outer[(i + 1) % n]
		var c := inner[(i + 1) % n]
		var d := inner[i]
		var nrm := Vector3(0, (a.x + b.x) / 2, (a.y + b.y) / 2).normalized()
		st.set_normal(nrm)
		for v in [Vector3(-t / 2, a.x, a.y), Vector3(t / 2, a.x, a.y), Vector3(t / 2, b.x, b.y),
				Vector3(-t / 2, a.x, a.y), Vector3(t / 2, b.x, b.y), Vector3(-t / 2, b.x, b.y)]:
			st.add_vertex(v)
		for side in [-1.0, 1.0]:
			st.set_normal(Vector3(side, 0, 0))
			var q := [Vector3(side * t / 2, a.x, a.y), Vector3(side * t / 2, b.x, b.y), Vector3(side * t / 2, c.x, c.y),
				Vector3(side * t / 2, a.x, a.y), Vector3(side * t / 2, c.x, c.y), Vector3(side * t / 2, d.x, d.y)]
			if side < 0:
				q = [q[0], q[2], q[1], q[3], q[5], q[4]]
			for v in q:
				st.add_vertex(v)
	return st.commit()


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


## The paddle held at `hand` (the grip's middle), pointing along `along`
## (hand to face), its face turned toward `n` as far as `along` allows.
func pose_grip(hand: Vector3, along: Vector3, n: Vector3) -> void:
	var nz := -along.normalized()
	var x := n - nz * n.dot(nz)
	if x.length() < 0.01:
		x = nz.cross(Vector3.UP)
	x = x.normalized()
	var y := nz.cross(x)
	var b := Basis(x, y, nz)
	var grip_mid := Vector3(0, 0, FACE_CENTER.z + FACE_H / 2 + HANDLE / 2 - 0.01)
	transform = Transform3D(b, hand - b * grip_mid)
