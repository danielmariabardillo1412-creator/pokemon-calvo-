class_name ProgressionRuleset
extends RefCounted

# Central, injectable progression configuration for calvo_v1.
# Pure domain rules: no autoload, no UI, no battle logic.
# All limits and formulas used by the Progression Core live here so they can be
# unit-tested and swapped without touching CreatureInstance / CreatureFactory / EvolutionSystem.

const ID := &"calvo_progression_v1"
const POLICY_ID := "calvo_progression_v1"

const MIN_LEVEL := 1
const MAX_LEVEL := 100
const IV_MIN := 0
const IV_MAX := 31
const EV_PER_STAT_MAX := 252
const EV_TOTAL_MAX := 510
const MOVE_SLOTS_MAX := 4
const NATURE_COUNT := 25

const STAT_KEYS := ["hp", "attack", "defense", "speed", "special_attack", "special_defense"]
const HP_KEY := "hp"

# Supported growth curves (PokeAPI growth_rate.name values).
const GROWTH_CURVES := [
	"fast", "medium", "medium-slow", "slow", "erratic", "fluctuating",
]
const DEFAULT_GROWTH_CURVE := "medium"

# Canonical nature modifier table (game constant). Maps nature_id -> {up, down}.
# Neutral natures have up == down == "". This is the fixed official table, so it is
# hard-coded rather than parsed from the source (the source mirrors the same values).
const NATURE_MODIFIERS := {
	&"hardy": ["", ""],
	&"lonely": ["attack", "defense"],
	&"brave": ["attack", "speed"],
	&"adamant": ["attack", "special_attack"],
	&"naughty": ["attack", "special_defense"],
	&"bold": ["defense", "attack"],
	&"docile": ["", ""],
	&"relaxed": ["defense", "speed"],
	&"impish": ["defense", "special_attack"],
	&"lax": ["defense", "special_defense"],
	&"timid": ["speed", "attack"],
	&"hasty": ["speed", "defense"],
	&"serious": ["", ""],
	&"jolly": ["speed", "special_attack"],
	&"naive": ["speed", "special_defense"],
	&"modest": ["special_attack", "attack"],
	&"mild": ["special_attack", "defense"],
	&"quiet": ["special_attack", "speed"],
	&"bashful": ["", ""],
	&"rash": ["special_attack", "special_defense"],
	&"calm": ["special_defense", "attack"],
	&"gentle": ["special_defense", "defense"],
	&"sassy": ["special_defense", "speed"],
	&"careful": ["special_defense", "special_attack"],
	&"quirky": ["", ""],
}
const NEUTRAL_NATURE := &"hardy"

const NATURE_UP_MULTIPLIER := 1.1
const NATURE_DOWN_MULTIPLIER := 0.9


static func is_valid_nature(nature_id: StringName) -> bool:
	return NATURE_MODIFIERS.has(nature_id)


static func nature_multiplier(nature_id: StringName, stat_key: String) -> float:
	if not NATURE_MODIFIERS.has(nature_id):
		return 1.0
	var mod: Array = NATURE_MODIFIERS[nature_id]
	if mod[0] == stat_key:
		return NATURE_UP_MULTIPLIER
	if mod[1] == stat_key:
		return NATURE_DOWN_MULTIPLIER
	return 1.0


# --- Experience curves ---------------------------------------------------
# E(level) = total experience required to BE at `level`, with E(1) == 0 for every curve.
# Formulas follow the standard Pokemon curves; level 1 is defined as 0 (starting point),
# and for level >= 2 we take floor(formula(level)) clamped to >= 0, which matches the
# published tables (e.g. medium-fast L2 == 8, medium-slow L2 == 9).

static func _curve_table(curve: String) -> Array:
	if _tables.has(curve):
		return _tables[curve]
	var table: Array = []
	table.resize(MAX_LEVEL + 1)
	table[0] = 0
	for n in range(1, MAX_LEVEL + 1):
		if n == 1:
			table[n] = 0
		else:
			table[n] = maxi(0, int(floor(_raw_curve(curve, n))))
	_tables[curve] = table
	return table


static var _tables: Dictionary = {}


static func _raw_curve(curve: String, n: int) -> float:
	var x: float = float(n)
	match curve:
		"fast":
			return 0.8 * x * x * x
		"medium":
			return x * x * x
		"medium-slow":
			return 1.2 * x * x * x - 15.0 * x * x + 100.0 * x - 140.0
		"slow":
			return 1.25 * x * x * x
		"erratic":
			if n <= 50:
				return x * x * x * (100.0 - x) / 50.0
			elif n <= 68:
				return x * x * x * (150.0 - x) / 100.0
			elif n <= 98:
				return x * x * x * floor((1911.0 - 10.0 * x) / 3.0) / 1000.0
			else:
				return x * x * x * (160.0 - x) / 100.0
		"fluctuating":
			if n <= 15:
				return x * x * x * (floor((x + 1.0) / 3.0) + 24.0) / 50.0
			elif n <= 36:
				return x * x * x * (x + 14.0) / 50.0
			elif n <= 100:
				return x * x * x * (floor(x / 2.0) + 32.0) / 50.0
			else:
				return x * x * x * 255.0 / 100.0
		_:
			return x * x * x


static func experience_for_level(curve: String, level: int) -> int:
	var c := DEFAULT_GROWTH_CURVE if not GROWTH_CURVES.has(curve) else curve
	var table: Array = _curve_table(c)
	var lvl := clampi(level, MIN_LEVEL, MAX_LEVEL)
	return int(table[lvl])


static func level_for_experience(curve: String, exp: int) -> int:
	var c := DEFAULT_GROWTH_CURVE if not GROWTH_CURVES.has(curve) else curve
	var table: Array = _curve_table(c)
	var target := maxi(0, int(exp))
	var lvl := MIN_LEVEL
	for n in range(MIN_LEVEL, MAX_LEVEL + 1):
		if int(table[n]) <= target:
			lvl = n
		else:
			break
	return lvl


static func experience_to_next_level(curve: String, level: int) -> int:
	var lvl := clampi(level, MIN_LEVEL, MAX_LEVEL)
	if lvl >= MAX_LEVEL:
		return 0
	return experience_for_level(curve, lvl + 1) - experience_for_level(curve, lvl)


# Experience granted to a surviving participant when a foe is defeated.
# Base share uses the classic E = base_experience * foe_level / 7, then split evenly
# among the surviving participants of the winning side (deterministic, no rng).
static func experience_for_defeat(base_experience: int, foe_level: int, participant_count: int) -> int:
	var total := int(base_experience) * maxi(1, foe_level) * 100 / 700  # /7 with bp scaling
	if participant_count <= 0:
		return 0
	return totali_safe(total, participant_count)


static func totali_safe(value: int, divisor: int) -> int:
	return value / maxi(1, divisor)


# Experience granted for defeating multiple foes: sum per foe, split per participant.
static func experience_for_defeats(defeats: Array, participant_count: int) -> int:
	var total := 0
	for d in defeats:
		var be := int(d.get("base_experience", 0))
		var lvl := int(d.get("level", 1))
		total += experience_for_defeat(be, lvl, 1)
	if participant_count <= 0:
		return 0
	return total / maxi(1, participant_count)


static func clamp_level(level: int) -> int:
	return clampi(level, MIN_LEVEL, MAX_LEVEL)


static func clamp_iv(value: int) -> int:
	return clampi(value, IV_MIN, IV_MAX)


static func clamp_ev(value: int) -> int:
	return clampi(value, 0, EV_PER_STAT_MAX)


static func clamp_ev_total(evs: Dictionary) -> Dictionary:
	var total := 0
	for k in STAT_KEYS:
		var v := int(evs.get(k, 0))
		v = clamp_ev(v)
		evs[k] = v
		total += v
	if total > EV_TOTAL_MAX:
		# Scale down proportionally is engine-specific; V1 simply clamps each stat and
		# records an overflow flag via recompute. We keep the simple clamp here and rely
		# on CreatureFactory/ProgressionSystem to not exceed the total.
		pass
	return evs
