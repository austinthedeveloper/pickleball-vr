## Base for test suites: assertions report to the runner and keep going.
class_name TestSuite
extends RefCounted

var runner
var asserts := 0


func check(cond: bool, msg: String = "check failed") -> bool:
	asserts += 1
	if not cond:
		runner.fail(msg)
	return cond


func eq(actual, expected, msg: String = "") -> bool:
	asserts += 1
	if actual != expected:
		runner.fail("%s expected %s, got %s" % [msg, str(expected), str(actual)])
		return false
	return true


## |actual - expected| <= tol
func near(actual: int, expected: int, tol: int, msg: String = "") -> bool:
	asserts += 1
	if absi(actual - expected) > tol:
		runner.fail("%s expected %d +/- %d, got %d" % [msg, expected, tol, actual])
		return false
	return true


## A singles sim with the bot playing slot 0.
static func bot_match(seed := 1994, assist := K.ASSIST_MID) -> Array:
	var cfg := SimTypes.MatchConfig.new()
	cfg.seed = seed
	cfg.assist = assist
	var sim := Sim.new(cfg)
	var bot := Bot.new(sim, 0)
	return [sim, bot]


## Steps sim (with the bot's input) until cond or limit; returns ticks or -1.
static func run_until(sim: Sim, bot: Bot, cond: Callable, limit := 40000) -> int:
	for i in limit:
		if cond.call():
			return i
		sim.step([bot.input() if bot else null])
	return -1
