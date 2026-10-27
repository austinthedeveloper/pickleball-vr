## A menu panel standing in the world: rows by id, each a label and
## (optionally) values to step through, driven by move/change/press (the
## sticks, the keys) or by pointing (a controller's laser, the mouse) and
## clicking. Tests select rows by id (port kit playbook §4.8).
class_name Menu3D
extends Node3D

const ROW_H := 0.13
const WIDTH := 1.5
const PANEL := Color(0.07, 0.09, 0.16)
const HILITE := Color(0.95, 0.75, 0.15)
## A new page ignores pointing and the sticks this long: the click that
## opened it mustn't press a row too (port kit playbook rule 9).
const SWITCH_LOCK := 0.3

signal pressed(id: String)
signal changed(id: String, index: int)

var title := ""
var rows: Array = []                 ## {id, label, values: Array[String], index}
var selected := 0
var lock := SWITCH_LOCK
var _labels: Array[Label3D] = []
var _values: Array[Label3D] = []
var _bar: MeshInstance3D
var _panel: MeshInstance3D
var _title: Label3D


func add_row(id: String, label: String, values: Array = [], index := 0) -> void:
	rows.append({"id": id, "label": label, "values": values, "index": index})


func _ready() -> void:
	var h := (rows.size() + 1.6) * ROW_H
	_panel = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(WIDTH, h, 0.02)
	_panel.mesh = bm
	_panel.material_override = World.material(PANEL)
	_panel.position = Vector3(0, -h / 2 + ROW_H * 0.8, -0.012)
	add_child(_panel)
	_bar = MeshInstance3D.new()
	var bb := BoxMesh.new()
	bb.size = Vector3(WIDTH - 0.06, ROW_H * 0.86, 0.004)
	_bar.mesh = bb
	var bmat := World.material(Color(HILITE, 0.28))
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_bar.material_override = bmat
	add_child(_bar)
	_title = _text(Vector3(0, ROW_H * 0.55, 0.002), 64, HILITE, HORIZONTAL_ALIGNMENT_CENTER)
	_title.text = title
	for i in rows.size():
		var y := -ROW_H * (i + 0.9)
		_labels.append(_text(Vector3(-WIDTH / 2 + 0.07, y, 0.002), 44, Color(0.9, 0.93, 1.0),
			HORIZONTAL_ALIGNMENT_LEFT))
		_values.append(_text(Vector3(WIDTH / 2 - 0.07, y, 0.002), 44, Color(1, 1, 1),
			HORIZONTAL_ALIGNMENT_RIGHT))
	refresh()


func _text(at: Vector3, size: int, c: Color, align: HorizontalAlignment) -> Label3D:
	var l := Label3D.new()
	l.font_size = size
	l.pixel_size = 0.0018
	l.modulate = c
	l.outline_size = 8
	l.outline_modulate = Color(0, 0, 0, 0.7)
	l.horizontal_alignment = align
	l.position = at
	l.double_sided = false
	add_child(l)
	return l


func refresh() -> void:
	if _labels.is_empty():
		return
	for i in rows.size():
		var r: Dictionary = rows[i]
		_labels[i].text = r["label"]
		var vals: Array = r["values"]
		_values[i].text = "< %s >" % vals[r["index"]] if vals.size() > 0 else ""
		_labels[i].modulate = HILITE if i == selected else Color(0.9, 0.93, 1.0)
	_bar.position = Vector3(0, -ROW_H * (selected + 0.9) + 0.012, 0.0)


func row(id: String) -> Dictionary:
	for r in rows:
		if r["id"] == id:
			return r
	return {}


func value(id: String) -> int:
	return row(id).get("index", 0)


func select(id: String) -> void:
	for i in rows.size():
		if rows[i]["id"] == id:
			selected = i
	refresh()


func move(d: int) -> void:
	selected = posmod(selected + d, rows.size())
	refresh()


## Step the selected row's value (wrapping), or nothing on an action row.
func change(d: int) -> void:
	var r: Dictionary = rows[selected]
	var vals: Array = r["values"]
	if vals.is_empty():
		return
	r["index"] = posmod(int(r["index"]) + d, vals.size())
	refresh()
	changed.emit(r["id"], r["index"])


## The selected row: an action row is pressed, a value row steps on.
func press() -> void:
	var r: Dictionary = rows[selected]
	if (r["values"] as Array).is_empty():
		pressed.emit(r["id"])
	else:
		change(1)


## The row a ray from `origin` along `dir` (world) points at, or -1.
func row_at(origin: Vector3, dir: Vector3) -> int:
	var inv := global_transform.affine_inverse()
	var o := inv * origin
	var d := inv.basis * dir
	if absf(d.z) < 0.0001:
		return -1
	var t := -o.z / d.z
	if t <= 0.0:
		return -1
	var hit := o + d * t
	if absf(hit.x) > WIDTH / 2:
		return -1
	var i := int(floor(-hit.y / ROW_H - 0.4))
	return i if i >= 0 and i < rows.size() else -1


func _process(delta: float) -> void:
	lock = maxf(lock - delta, 0.0)


func locked() -> bool:
	return lock > 0.0


## Pointing: hover selects; a click presses.
func point(origin: Vector3, dir: Vector3, click: bool) -> void:
	if locked():
		return
	var i := row_at(origin, dir)
	if i < 0:
		return
	if i != selected:
		selected = i
		refresh()
	if click:
		press()
