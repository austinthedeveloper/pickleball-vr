## Integer maths for the sim: square roots, unit vectors in Q14, the seeded
## generator. Everything rounds the same on every platform (ADR-002).
class_name Fx
extends RefCounted


## Below 2^50 the double's correctly rounded sqrt never rounds up across
## an integer (the gap below k is 1/2k, wider than half a double's spacing
## there), so int(sqrt(n)) is already floor(sqrt(n)): no fix-up loops on
## the hot path (ADR-009).
const SQRT_EXACT := 1 << 50

## floor(sqrt(n)). The float sqrt is IEEE correctly rounded; the loops make
## it exact for any n a sim can produce.
static func isqrt(n: int) -> int:
	if n <= 0:
		return 0
	var r := int(sqrt(float(n)))
	if n < SQRT_EXACT:
		return r                     # exact here: see SQRT_EXACT
	while r * r > n:
		r -= 1
	while (r + 1) * (r + 1) <= n:
		r += 1
	return r


static func length(x: int, y: int, z: int) -> int:
	return isqrt(x * x + y * y + z * z)


## (a * b) >> s, rounded toward zero, so a sign flip flips the result.
static func mul_shift(a: int, b: int, s: int) -> int:
	var p := a * b
	if p < 0:
		return -((-p) >> s)
	return p >> s


## Air drag on one velocity component, at total speed `speed`.
static func drag(v: int, speed: int) -> int:
	return mul_shift(v * speed, K.DRAG_Q32, 32)


## The unit vector along (x, y, z), Q14; [0, Q14, 0] for a zero vector.
static func unit_q14(x: int, y: int, z: int) -> Array[int]:
	var n := length(x, y, z)
	if n == 0:
		return [0, K.Q14, 0]
	return [x * K.Q14 / n, y * K.Q14 / n, z * K.Q14 / n]


## v . n with n in Q14: a length in v's units.
static func dot_q14(vx: int, vy: int, vz: int, n: Array[int]) -> int:
	return (vx * n[0] + vy * n[1] + vz * n[2]) / K.Q14


## The next state of the generator (glibc's constants, 31 bits).
static func lcg(state: int) -> int:
	return (state * 1103515245 + 12345) & 0x7fffffff


## 15 bits from a state.
static func lcg_bits(state: int) -> int:
	return (state >> 16) & 0x7fff
