class_name StatCalculator
extends RefCounted

# Deterministic persistent stat computation from base stats, IVs, EVs and nature.
# Uses the standard Generation III+ formulas. No battle modifiers (stat stages)
# are applied here; those live in the Battle Core.

const HP_KEY := "hp"


static func compute(
	base: StatBlock,
	ivs: Dictionary,
	evs: Dictionary,
	nature_id: StringName,
	level: int,
) -> StatBlock:
	var lvl := maxi(1, level)
	var out := StatBlock.new()
	out.max_hp = _hp(base.max_hp, _iv(ivs, HP_KEY), _ev(evs, HP_KEY), lvl)
	out.attack = _other("attack", base.attack, _iv(ivs, "attack"), _ev(evs, "attack"), nature_id, lvl)
	out.defense = _other("defense", base.defense, _iv(ivs, "defense"), _ev(evs, "defense"), nature_id, lvl)
	out.speed = _other("speed", base.speed, _iv(ivs, "speed"), _ev(evs, "speed"), nature_id, lvl)
	out.special_attack = _other("special_attack", base.special_attack, _iv(ivs, "special_attack"), _ev(evs, "special_attack"), nature_id, lvl)
	out.special_defense = _other("special_defense", base.special_defense, _iv(ivs, "special_defense"), _ev(evs, "special_defense"), nature_id, lvl)
	return out


static func _iv(ivs: Dictionary, key: String) -> int:
	return clampi(int(ivs.get(key, 0)), 0, 31)


static func _ev(evs: Dictionary, key: String) -> int:
	return clampi(int(evs.get(key, 0)), 0, 252)


static func _hp(base: int, iv: int, ev: int, level: int) -> int:
	var trained := (2 * base + iv + (ev / 4)) * level
	var value := trained / 100 + level + 10
	return maxi(1, value)


static func _other(key: String, base: int, iv: int, ev: int, nature_id: StringName, level: int) -> int:
	var trained := (2 * base + iv + (ev / 4)) * level
	var value := trained / 100 + 5
	var mult := ProgressionRuleset.nature_multiplier(nature_id, key)
	value = int(floor(value * mult))
	return maxi(1, value)
