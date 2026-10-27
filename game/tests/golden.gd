## Regenerates the golden traces (only when a change is meant to alter play):
##   godot --headless --path game -s res://tests/golden.gd
## Each line: tick, then the sim's snapshot hash, every 60 ticks of a bot
## vs CPU match.
extends SceneTree

const CASES := {"singles_1994": [1994, 1], "singles_7_hard": [7, 2], "singles_42_easy": [42, 0]}
const TICKS := 24000
const EVERY := 60


static func trace(seed: int, difficulty: int) -> PackedStringArray:
	var cfg := SimTypes.MatchConfig.new()
	cfg.seed = seed
	cfg.difficulty = difficulty
	var sim := Sim.new(cfg)
	var bot := Bot.new(sim, 0)
	var lines := PackedStringArray()
	for i in TICKS:
		sim.step([bot.input()])
		if sim.tick % EVERY == 0:
			lines.append("%d %d" % [sim.tick, sim.state_hash()])
	return lines


func _initialize() -> void:
	for name in CASES:
		var c: Array = CASES[name]
		var f := FileAccess.open("res://tests/golden/%s.txt" % name, FileAccess.WRITE)
		f.store_string("\n".join(trace(c[0], c[1])) + "\n")
		print("wrote ", name)
	quit()
