## The golden traces: play is unchanged unless a change means to change it
## (regenerate with tests/golden.gd and say why in the commit).
extends "res://tests/suite.gd"

const Golden := preload("res://tests/golden.gd")


func test_golden_traces() -> void:
	for name in Golden.CASES:
		var c: Array = Golden.CASES[name]
		var want := FileAccess.get_file_as_string("res://tests/golden/%s.txt" % name).strip_edges().split("\n")
		var got := Golden.trace(c[0], c[1])
		var first := -1
		for i in mini(want.size(), got.size()):
			if want[i] != got[i]:
				first = i
				break
		check(first < 0 and want.size() == got.size(),
			"%s diverges at line %d (%s vs %s)" % [name, first, want[first] if first >= 0 else "", got[first] if first >= 0 else ""])
