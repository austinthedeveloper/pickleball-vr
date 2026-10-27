## The sim's records: a human's input for one tick, the match's config,
## a player.
class_name SimTypes
extends RefCounted


## What a human gives the sim each tick (ADR-003): where their head is on
## the ground, the paddle face's centre and normal, the free hand, and
## whether they let go of the ball this tick. All world um / Q14.
class HumanInput:
	extends RefCounted
	var head_x := 0
	var head_z := 0
	var paddle_x := 0
	var paddle_y := 0
	var paddle_z := 0
	var normal: Array[int] = [0, 0, K.Q14]
	var hand_x := 0
	var hand_y := 0
	var hand_z := 0
	var toss := false

	func to_array() -> Array:
		return [head_x, head_z, paddle_x, paddle_y, paddle_z, normal[0], normal[1], normal[2],
			hand_x, hand_y, hand_z, 1 if toss else 0]

	static func from_array(a: Array) -> HumanInput:
		var h := HumanInput.new()
		h.head_x = a[0]
		h.head_z = a[1]
		h.paddle_x = a[2]
		h.paddle_y = a[3]
		h.paddle_z = a[4]
		h.normal = [a[5], a[6], a[7]]
		h.hand_x = a[8]
		h.hand_y = a[9]
		h.hand_z = a[10]
		h.toss = a[11] != 0
		return h


## A CPU's personality (port ADR-023's idea, re-cut for 3D): data, not code.
class CpuStyle:
	extends RefCounted
	var speed := 36000               ## um/tick, 4.3 m/s
	var reaction := 20               ## ticks after the other side's hit
	var error := 350000              ## um of aim scatter at difficulty 1
	var net_rush := 50               ## percent: goes up to the kitchen line
	var dink := 55                   ## percent: dinks back a ball at the kitchen
	var lob := 10                    ## percent: lobs a player at the kitchen
	var drive_pace := 135000         ## um/tick, 16 m/s
	var serve_pace := 100000

	func copy() -> CpuStyle:
		var c := CpuStyle.new()
		c.speed = speed
		c.reaction = reaction
		c.error = error
		c.net_rush = net_rush
		c.dink = dink
		c.lob = lob
		c.drive_pace = drive_pace
		c.serve_pace = serve_pace
		return c


class MatchConfig:
	extends RefCounted
	var doubles := false
	var humans := 1                  ## slot 0 (and up) are humans
	var points_to_win := K.POINTS_TO_WIN
	var win_by_2 := false
	var assist := K.ASSIST_MID
	var difficulty := 1              ## 0 easy, 1 normal, 2 hard
	var seed := 1994
	var first_server := 0            ## team
	var style := CpuStyle.new()


class Player:
	extends RefCounted
	var slot := 0
	var team := 0
	var cpu := false
	## Body (head) on the ground.
	var x := 0
	var z := 0
	## Paddle face this tick and last.
	var px := 0
	var py := 0
	var pz := 0
	var qx := 0
	var qy := 0
	var qz := 0
	var normal: Array[int] = [0, 0, K.Q14]
	var hand_x := 0
	var hand_y := 0
	var hand_z := 0
	var hand_qx := 0
	var hand_qy := 0
	var hand_qz := 0
	var cooldown := 0
	## CPU plan: where to stand, when the ball should be there.
	var goal_x := 0
	var goal_z := 0
	var plan_tick := -1
	var think_at := 0
	var swing_tick := -1             ## the view's cue for a CPU's swing
	var let_go := false              ## the ball's going out: leave it
	var court_right := true          ## doubles: in the right court (as they face the net)
