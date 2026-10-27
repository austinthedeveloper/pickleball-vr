## Headless test runner:
##   godot --headless --path game -s res://tests/run_tests.gd [-- filter]
## Runs every tests/test_*.gd suite (methods named test_*), prints a
## summary, and exits non-zero on any failure.
extends SceneTree

var failures := 0
var passes := 0
var current := ""


var _ran := false


## On the first frame, not in _initialize: the root is in the tree by
## then, so views the suites build get their _ready.
func _process(_delta: float) -> bool:
	if not _ran:
		_ran = true
		_run()
	return false


func _run() -> void:
	Settings.default_path = "user://test_settings.cfg"   # never the player's
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.default_path))
	var filter := ""
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		filter = args[0]
	var files: Array = []
	for f in DirAccess.open("res://tests").get_files():
		if f.begins_with("test_") and f.ends_with(".gd"):
			files.append(f)
	files.sort()
	var t0 := Time.get_ticks_msec()
	for f in files:
		var script: GDScript = load("res://tests/" + f)
		if script == null or not script.can_instantiate():
			current = f
			fail("suite failed to load (parse/compile error)")
			continue
		var suite = script.new()
		suite.set("runner", self)
		var methods: Array = []
		for m in script.get_script_method_list():
			if String(m.name).begins_with("test_"):
				methods.append(String(m.name))
		methods.sort()
		for m in methods:
			current = f.get_basename() + "." + m
			if filter != "" and current.find(filter) < 0:
				continue
			var before := failures
			suite.set("asserts", 0)
			suite.call(m)
			if int(suite.get("asserts")) == 0:
				fail("no assertions ran (script error?)")
			if failures == before:
				passes += 1
				print("  ok   ", current)
	print("\n%d passed, %d failed (%d ms)" % [passes, failures, Time.get_ticks_msec() - t0])
	quit(1 if failures > 0 else 0)


func fail(msg: String) -> void:
	failures += 1
	print("  FAIL ", current, ": ", msg)
