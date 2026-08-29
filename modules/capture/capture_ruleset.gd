class_name CaptureRuleset
extends RefCounted

# Deterministic capture configuration for calvo_capture_v1.
# Pure domain rules: no UI, no animation, no autoload. All randomness is injected (RandomSource).

const ID := &"calvo_capture_v1"
const SCHEMA_VERSION := 2

# Roster-style limit reuse is intentional; capture decision is independent of party internals.
const MAX_PARTY := 6

# --- Ball definitions (canonical, versioned) ----------------------------
# PokéAPI items carry no structured capture multiplier, so this table is the source of truth.
# Multipliers follow the classic family: poke 1.0, great 1.5, ultra 2.0; master = guaranteed.
var BALLS := {
	&"poke_ball": CaptureBallDefinition.new(&"poke_ball", 1.0, false),
	&"great_ball": CaptureBallDefinition.new(&"great_ball", 1.5, false),
	&"ultra_ball": CaptureBallDefinition.new(&"ultra_ball", 2.0, false),
	&"master_ball": CaptureBallDefinition.new(&"master_ball", 1.0, true),
}

# --- Status bonus (persistent status only) ------------------------------
# Sleep/freeze are the strong modifiers; poison/burn/paralysis/badly_poisoned are the weak ones.
# Volatile statuses (flinch/confusion) never affect capture.
const STATUS_BONUS := {
	&"sleep": 2.0,
	&"freeze": 2.0,
	&"poison": 1.5,
	&"badly_poisoned": 1.5,
	&"burn": 1.5,
	&"paralysis": 1.5,
}

# Capturing a KO'd target is disallowed by default in calvo_capture_v1.
const ALLOW_CAPTURE_KO := false

# Canonical capture_rate range (Pokémon species datum).
const CAPTURE_RATE_MIN := 1
const CAPTURE_RATE_MAX := 255


func ball(ball_id: StringName) -> CaptureBallDefinition:
	return BALLS.get(ball_id, null)


func is_known_ball(ball_id: StringName) -> bool:
	return BALLS.has(ball_id)


func status_bonus(persistent_status_id: StringName) -> float:
	if persistent_status_id == &"":
		return 1.0
	return STATUS_BONUS.get(persistent_status_id, 1.0)


# Capturability of a species datum (range check). 0/absent means uncatchable in calvo_capture_v1.
static func is_valid_capture_rate(capture_rate: int) -> bool:
	return capture_rate >= CAPTURE_RATE_MIN and capture_rate <= CAPTURE_RATE_MAX


# Deterministic catch probability in [0, 1].
# p = (capture_rate/255) * ball_mult * status_mult * hp_factor
#   hp_factor = (3*max_hp - 2*current_hp) / (3*max_hp)   # 1.0 at 0 HP, 1/3 at full HP
# Master ball returns 1.0 (guaranteed elsewhere). Guaranteed balls bypass the RNG.
func catch_probability(
	capture_rate: int,
	ball_mult: float,
	status_mult: float,
	max_hp: int,
	current_hp: int,
) -> float:
	var rate := clampf(float(capture_rate) / 255.0, 0.0, 1.0)
	var hp := maxi(1, maxi(0, max_hp))
	var cur := clampi(int(current_hp), 0, hp)
	var hp_factor := float(3 * hp - 2 * cur) / float(3 * hp)
	var p := rate * ball_mult * status_mult * hp_factor
	return clampf(p, 0.0, 1.0)
