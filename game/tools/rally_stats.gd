## Rally statistics, bot against CPU, as the game plays them:
##   godot --headless --path game -s res://tools/rally_stats.gd -- [matches] [difficulty] [singles|doubles]
extends SceneTree


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var matches := int(args[0]) if args.size() > 0 else 4
	var diff := int(args[1]) if args.size() > 1 else 1
	var doubles := args.size() > 2 and args[2] == "doubles"
	var points := 0
	var shots := 0
	var faults := {}
	var wins := [0, 0]
	var longest := 0
	for m in matches:
		var cfg := SimTypes.MatchConfig.new()
		cfg.seed = 100 + m
		cfg.difficulty = diff
		cfg.doubles = doubles
		var sim := Sim.new(cfg)
		var bot := Bot.new(sim, 0)
		for i in 200000:
			sim.step([bot.input()])
			for e in sim.drain_events():
				if e[0] == K.EVENT_POINT:
					points += 1
					shots += sim.shots
					longest = maxi(longest, sim.shots)
					var f := K.fault_text(sim.last_fault)
					var key := "%s by %s" % [f if f != "" else "WINNER", "BOT" if e[1] == 1 else "CPU"]
					faults[key] = faults.get(key, 0) + 1
			if sim.phase == K.PHASE_MATCH_RESULT:
				wins[sim.match_winner] += 1
				break
	print("matches %d  bot %d cpu %d  points %d  mean rally %.1f  longest %d" % [
		matches, wins[0], wins[1], points, float(shots) / maxi(points, 1), longest])
	print(faults)
	quit()
