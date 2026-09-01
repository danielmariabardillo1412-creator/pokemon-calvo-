class_name BattleEffectRegistry
extends RefCounted

const TRAINER_ITEM_TARGET_ALIVE := &"alive"
const TRAINER_ITEM_TARGET_FAINTED := &"fainted"

var _move_specs: Dictionary = {}
var _ability_specs: Dictionary = {}
var _item_specs: Dictionary = {} # held-item triggers
var _trainer_item_specs: Dictionary = {} # explicit bag-item actions
var _trainer_item_target_modes: Dictionary = {}


func _init() -> void:
	_register_moves()
	_register_abilities()
	_register_items()
	_register_trainer_items()


func effects_for_move(move: MoveDefinition) -> Array[BattleEffectSpec]:
	var result: Array[BattleEffectSpec] = []
	var has_multi_hit := false
	for spec in move.effect_specs:
		if spec.kind == BattleEffectSpec.MULTI_HIT:
			has_multi_hit = true
	if move.power > 0 and not has_multi_hit:
		result.append(BattleEffectSpec.new(BattleEffectSpec.DAMAGE))
	for spec in move.effect_specs:
		result.append(spec)
	if move.effect_specs.is_empty():
		var added_damage := false
		for spec in _move_specs.get(move.id, []):
			if not added_damage and move.power > 0:
				result.append(BattleEffectSpec.new(BattleEffectSpec.DAMAGE))
				added_damage = true
			result.append(spec)
	return result


func triggers_for_ability(ability_id: StringName, trigger: StringName) -> Array[BattleTriggerSpec]:
	return _filter_triggers(_ability_specs.get(ability_id, []), trigger)


func triggers_for_item(item_id: StringName, trigger: StringName) -> Array[BattleTriggerSpec]:
	return _filter_triggers(_item_specs.get(item_id, []), trigger)


func effects_for_trainer_item(item_id: StringName) -> Array[BattleEffectSpec]:
	var out: Array[BattleEffectSpec] = []
	for raw_spec in _trainer_item_specs.get(item_id, []):
		if raw_spec is BattleEffectSpec:
			out.append(BattleEffectSpec.from_dict((raw_spec as BattleEffectSpec).to_dict()))
	return out


func trainer_item_target_mode(item_id: StringName) -> StringName:
	return StringName(_trainer_item_target_modes.get(item_id, TRAINER_ITEM_TARGET_ALIVE))


func is_trainer_item_supported(item_id: StringName) -> bool:
	return _trainer_item_specs.has(item_id)


func runtime_supported_trainer_item_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for raw_id in _trainer_item_specs.keys():
		out.append(StringName(raw_id))
	out.sort_custom(func(a, b): return String(a) < String(b))
	return out


func has_explicit_move_mapping(move_id: StringName) -> bool:
	return _move_specs.has(move_id) or [&"tackle", &"water_gun", &"quick_attack"].has(move_id)


func runtime_supported_move_ids() -> Array[StringName]:
	return [
		&"double_edge", &"ember", &"growl", &"mega_drain", &"quick_attack",
		&"recover", &"sleep_powder", &"swords_dance", &"tackle", &"thunder",
		&"thunder_punch", &"thunder_wave", &"toxic", &"water_gun", &"will_o_wisp",
	]


func runtime_supported_ability_ids() -> Array[StringName]:
	# Frozen Battle V2 compatibility surface. DATA V3 ability reliability uses
	# implemented_ability_ids() plus its stricter semantic classifications.
	return [&"blaze", &"intimidate", &"levitate", &"overgrow", &"static", &"torrent"]


func implemented_ability_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for raw_id in _ability_specs.keys():
		out.append(StringName(raw_id))
	out.sort_custom(func(a, b): return String(a) < String(b))
	return out


func runtime_supported_item_ids() -> Array[StringName]:
	# Held-item runtime coverage only. Trainer bag items are intentionally reported
	# separately so historical item coverage contracts remain stable.
	return [&"leftovers", &"sitrus_berry"]


func _filter_triggers(source: Array, trigger: StringName) -> Array[BattleTriggerSpec]:
	var result: Array[BattleTriggerSpec] = []
	for spec in source:
		if spec.trigger == trigger:
			result.append(spec)
	return result


func _register_moves() -> void:
	_move_specs[&"thunder_punch"] = [_chance(1000, _status(&"paralysis"))]
	_move_specs[&"ember"] = [_chance(1000, _status(&"burn"))]
	_move_specs[&"thunder"] = [_chance(3000, _status(&"paralysis"))]
	_move_specs[&"growl"] = [_stage(BattleEffectSpec.OPPONENT, StatStages.ATTACK, -1)]
	_move_specs[&"swords_dance"] = [_stage(BattleEffectSpec.SELF, StatStages.ATTACK, 2)]
	_move_specs[&"recover"] = [BattleEffectSpec.new(BattleEffectSpec.HEAL, BattleEffectSpec.SELF, 0, 5000)]
	_move_specs[&"double_edge"] = [BattleEffectSpec.new(BattleEffectSpec.RECOIL, BattleEffectSpec.SELF, 0, 3333)]
	_move_specs[&"mega_drain"] = [BattleEffectSpec.new(BattleEffectSpec.DRAIN, BattleEffectSpec.SELF, 0, 5000)]
	_move_specs[&"thunder_wave"] = [_status(&"paralysis")]
	_move_specs[&"will_o_wisp"] = [_status(&"burn")]
	_move_specs[&"toxic"] = [_status(&"badly_poisoned")]
	_move_specs[&"sleep_powder"] = [_status(&"sleep")]


func _register_abilities() -> void:
	_ability_specs[&"intimidate"] = [BattleTriggerSpec.new(
		BattleTriggerSpec.ON_SWITCH_IN,
		&"ability",
		&"intimidate",
		_stage(BattleEffectSpec.OPPONENT, StatStages.ATTACK, -1),
	)]
	for pair in [
		[&"blaze", &"fire"],
		[&"torrent", &"water"],
		[&"overgrow", &"grass"],
		[&"swarm", &"bug"],
	]:
		_ability_specs[pair[0]] = [BattleTriggerSpec.new(
			BattleTriggerSpec.MODIFY_DAMAGE,
			&"ability",
			pair[0],
			BattleEffectSpec.new(BattleEffectSpec.DAMAGE),
			0,
			{"move_type_id": String(pair[1]), "hp_at_or_below_divisor": 3, "multiplier_bp": 15000},
		)]
	for pair in [
		[&"steelworker", &"steel"],
		[&"dragons_maw", &"dragon"],
		[&"rocky_payload", &"rock"],
		[&"fire_mane", &"fire"],
	]:
		_ability_specs[pair[0]] = [BattleTriggerSpec.new(
			BattleTriggerSpec.MODIFY_DAMAGE,
			&"ability",
			pair[0],
			BattleEffectSpec.new(BattleEffectSpec.DAMAGE),
			0,
			{"move_type_id": String(pair[1]), "multiplier_bp": 15000},
		)]
	for ability_id in [&"huge_power", &"pure_power"]:
		_ability_specs[ability_id] = [BattleTriggerSpec.new(
			BattleTriggerSpec.MODIFY_DAMAGE,
			&"ability",
			ability_id,
			BattleEffectSpec.new(BattleEffectSpec.DAMAGE),
			0,
			{"requires_physical": true, "offensive_stat_multiplier_bp": 20000},
		)]
	_ability_specs[&"toxic_boost"] = [BattleTriggerSpec.new(
		BattleTriggerSpec.MODIFY_DAMAGE,
		&"ability",
		&"toxic_boost",
		BattleEffectSpec.new(BattleEffectSpec.DAMAGE),
		0,
		{
			"requires_physical": true,
			"required_persistent_status_ids": ["poison", "badly_poisoned"],
			"offensive_stat_multiplier_bp": 15000,
		},
	)]
	_ability_specs[&"flare_boost"] = [BattleTriggerSpec.new(
		BattleTriggerSpec.MODIFY_DAMAGE,
		&"ability",
		&"flare_boost",
		BattleEffectSpec.new(BattleEffectSpec.DAMAGE),
		0,
		{
			"requires_special": true,
			"required_persistent_status_ids": ["burn"],
			"offensive_stat_multiplier_bp": 15000,
		},
	)]
	_ability_specs[&"defeatist"] = [
		BattleTriggerSpec.new(
			BattleTriggerSpec.MODIFY_DAMAGE,
			&"ability",
			&"defeatist",
			BattleEffectSpec.new(BattleEffectSpec.DAMAGE),
			0,
			{
				"requires_physical": true,
				"hp_at_or_below_divisor": 2,
				"offensive_stat_multiplier_bp": 5000,
			},
		),
		BattleTriggerSpec.new(
			BattleTriggerSpec.MODIFY_DAMAGE,
			&"ability",
			&"defeatist",
			BattleEffectSpec.new(BattleEffectSpec.DAMAGE),
			0,
			{
				"requires_special": true,
				"hp_at_or_below_divisor": 2,
				"offensive_stat_multiplier_bp": 5000,
			},
		),
	]
	# Partial runtime: paralysis and poison variants receive the faithful Attack x1.5.
	# Burn is excluded because DamageCalculator would still apply the normal burn cut;
	# sleep is excluded because the pinned source preserves version-sensitive history.
	_ability_specs[&"guts"] = [BattleTriggerSpec.new(
		BattleTriggerSpec.MODIFY_DAMAGE,
		&"ability",
		&"guts",
		BattleEffectSpec.new(BattleEffectSpec.DAMAGE),
		0,
		{
			"requires_physical": true,
			"required_persistent_status_ids": ["paralysis", "poison", "badly_poisoned"],
			"offensive_stat_multiplier_bp": 15000,
		},
	)]
	# Partial runtime: the regular physical-damage x1.5 subset is exact. Hustle's
	# required 0.8x accuracy modifier is not represented by the current trigger path.
	_ability_specs[&"hustle"] = [BattleTriggerSpec.new(
		BattleTriggerSpec.MODIFY_DAMAGE,
		&"ability",
		&"hustle",
		BattleEffectSpec.new(BattleEffectSpec.DAMAGE),
		0,
		{"requires_physical": true, "multiplier_bp": 15000},
	)]
	_ability_specs[&"tough_claws"] = [BattleTriggerSpec.new(
		BattleTriggerSpec.MODIFY_DAMAGE,
		&"ability",
		&"tough_claws",
		BattleEffectSpec.new(BattleEffectSpec.DAMAGE),
		0,
		{"requires_contact": true, "multiplier_bp": 13000},
	)]
	# Partial runtime contract: structured recoil moves get the faithful 1.2x boost.
	# Crash-on-miss moves are not represented by a RECOIL effect spec yet, so that
	# source-required Reckless subset remains deliberately absent.
	_ability_specs[&"reckless"] = [BattleTriggerSpec.new(
		BattleTriggerSpec.MODIFY_DAMAGE,
		&"ability",
		&"reckless",
		BattleEffectSpec.new(BattleEffectSpec.DAMAGE),
		0,
		{"requires_recoil": true, "multiplier_bp": 12000},
	)]
	_ability_specs[&"fur_coat"] = [BattleTriggerSpec.new(
		BattleTriggerSpec.MODIFY_DAMAGE,
		&"ability",
		&"fur_coat",
		BattleEffectSpec.new(BattleEffectSpec.DAMAGE),
		0,
		{"requires_physical": true, "multiplier_bp": 5000},
	)]
	_ability_specs[&"thick_fat"] = [
		BattleTriggerSpec.new(
			BattleTriggerSpec.MODIFY_DAMAGE,
			&"ability",
			&"thick_fat",
			BattleEffectSpec.new(BattleEffectSpec.DAMAGE),
			0,
			{"move_type_id": "fire", "multiplier_bp": 5000},
		),
		BattleTriggerSpec.new(
			BattleTriggerSpec.MODIFY_DAMAGE,
			&"ability",
			&"thick_fat",
			BattleEffectSpec.new(BattleEffectSpec.DAMAGE),
			0,
			{"move_type_id": "ice", "multiplier_bp": 5000},
		),
	]
	_ability_specs[&"ice_scales"] = [BattleTriggerSpec.new(
		BattleTriggerSpec.MODIFY_DAMAGE,
		&"ability",
		&"ice_scales",
		BattleEffectSpec.new(BattleEffectSpec.DAMAGE),
		0,
		{"requires_special": true, "multiplier_bp": 5000},
	)]
	_ability_specs[&"multiscale"] = [BattleTriggerSpec.new(
		BattleTriggerSpec.MODIFY_DAMAGE,
		&"ability",
		&"multiscale",
		BattleEffectSpec.new(BattleEffectSpec.DAMAGE),
		0,
		{"requires_full_hp": true, "multiplier_bp": 5000},
	)]
	# Partial runtime contract: Fire-move damage is exact, but burn residual damage
	# is still computed directly by StatusSystem and has no ability modifier hook.
	_ability_specs[&"heatproof"] = [BattleTriggerSpec.new(
		BattleTriggerSpec.MODIFY_DAMAGE,
		&"ability",
		&"heatproof",
		BattleEffectSpec.new(BattleEffectSpec.DAMAGE),
		0,
		{"move_type_id": "fire", "multiplier_bp": 5000},
	)]
	_ability_specs[&"levitate"] = [BattleTriggerSpec.new(
		BattleTriggerSpec.MODIFY_DAMAGE,
		&"ability",
		&"levitate",
		BattleEffectSpec.new(BattleEffectSpec.DAMAGE),
		0,
		{"immune_type_id": "ground"},
	)]
	# Partial runtime contract: an ordinary surviving damaging move raises Defense
	# once. Battle Core currently emits AFTER_DAMAGE once per completed move and not
	# for a fainted owner, so multi-hit and fatal-hit Stamina semantics remain absent.
	_ability_specs[&"stamina"] = [BattleTriggerSpec.new(
		BattleTriggerSpec.AFTER_DAMAGE,
		&"ability",
		&"stamina",
		_stage(BattleEffectSpec.SELF, StatStages.DEFENSE, 1),
	)]
	# Defender-owned contact reactions share the same partial boundary as Static:
	# TurnExecutor requests AFTER_DAMAGE only after positive damage and only while
	# the defender survives, so a contact hit that KOs the owner cannot trigger yet.
	_ability_specs[&"flame_body"] = [BattleTriggerSpec.new(
		BattleTriggerSpec.AFTER_DAMAGE,
		&"ability",
		&"flame_body",
		_chance(3000, BattleEffectSpec.new(
			BattleEffectSpec.INFLICT_STATUS,
			BattleEffectSpec.OPPONENT,
			0,
			0,
			10000,
			&"burn",
		)),
		0,
		{"requires_contact": true},
	)]
	_ability_specs[&"poison_point"] = [BattleTriggerSpec.new(
		BattleTriggerSpec.AFTER_DAMAGE,
		&"ability",
		&"poison_point",
		_chance(3000, BattleEffectSpec.new(
			BattleEffectSpec.INFLICT_STATUS,
			BattleEffectSpec.OPPONENT,
			0,
			0,
			10000,
			&"poison",
		)),
		0,
		{"requires_contact": true},
	)]
	_ability_specs[&"gooey"] = [BattleTriggerSpec.new(
		BattleTriggerSpec.AFTER_DAMAGE,
		&"ability",
		&"gooey",
		_stage(BattleEffectSpec.OPPONENT, StatStages.SPEED, -1),
		0,
		{"requires_contact": true},
	)]
	# Partial runtime contract: ordinary surviving single-hit contact inflicts the
	# source-faithful 1/8 of the attacker's maximum HP. Per-strike multihit and the
	# defender-faints-on-contact case remain outside current AFTER_DAMAGE semantics.
	_ability_specs[&"iron_barbs"] = [BattleTriggerSpec.new(
		BattleTriggerSpec.AFTER_DAMAGE,
		&"ability",
		&"iron_barbs",
		BattleEffectSpec.new(
			BattleEffectSpec.MAX_HP_DAMAGE,
			BattleEffectSpec.OPPONENT,
			0,
			1250,
		),
		0,
		{"requires_contact": true},
	)]
	_ability_specs[&"static"] = [BattleTriggerSpec.new(
		BattleTriggerSpec.AFTER_DAMAGE,
		&"ability",
		&"static",
		_chance(3000, BattleEffectSpec.new(
			BattleEffectSpec.INFLICT_STATUS,
			BattleEffectSpec.OPPONENT,
			0,
			0,
			10000,
			&"paralysis",
		)),
		0,
		{"requires_contact": true},
	)]


func _register_items() -> void:
	_item_specs[&"leftovers"] = [BattleTriggerSpec.new(
		BattleTriggerSpec.END_TURN,
		&"item",
		&"leftovers",
		BattleEffectSpec.new(BattleEffectSpec.HEAL, BattleEffectSpec.SELF, 0, 625),
		0,
		{"requires_missing_hp": true},
	)]
	_item_specs[&"sitrus_berry"] = [BattleTriggerSpec.new(
		BattleTriggerSpec.AFTER_DAMAGE,
		&"item",
		&"sitrus_berry",
		BattleEffectSpec.new(BattleEffectSpec.HEAL, BattleEffectSpec.SELF, 0, 2500),
		0,
		{"hp_at_or_below_divisor": 2, "requires_missing_hp": true},
		true,
	)]


func _register_trainer_items() -> void:
	# Calvo V1 trainer-bag rules. These are explicit project mechanics rather than
	# text parsed from PokeAPI descriptions, which keeps battle math deterministic.
	# Every currently enabled item targets a living own creature. The target-mode
	# contract already supports future FAINTED-only items (Revive), but none are
	# registered in V1; special NPCs may later receive exactly one such resource.
	_register_trainer_item(
		&"potion",
		[BattleEffectSpec.new(BattleEffectSpec.HEAL, BattleEffectSpec.OPPONENT, 20)],
	)
	_register_trainer_item(
		&"super_potion",
		[BattleEffectSpec.new(BattleEffectSpec.HEAL, BattleEffectSpec.OPPONENT, 60)],
	)
	_register_trainer_item(
		&"hyper_potion",
		[BattleEffectSpec.new(BattleEffectSpec.HEAL, BattleEffectSpec.OPPONENT, 120)],
	)
	_register_trainer_item(
		&"max_potion",
		[BattleEffectSpec.new(BattleEffectSpec.HEAL, BattleEffectSpec.OPPONENT, 0, 10000)],
	)
	_register_trainer_item(
		&"full_restore",
		[
			BattleEffectSpec.new(BattleEffectSpec.HEAL, BattleEffectSpec.OPPONENT, 0, 10000),
			BattleEffectSpec.new(BattleEffectSpec.CURE_STATUS, BattleEffectSpec.OPPONENT),
		],
	)


func _register_trainer_item(
	item_id: StringName,
	specs: Array,
	target_mode: StringName = TRAINER_ITEM_TARGET_ALIVE,
) -> void:
	_trainer_item_specs[item_id] = specs
	_trainer_item_target_modes[item_id] = target_mode


func _chance(chance_bp: int, child: BattleEffectSpec) -> BattleEffectSpec:
	return BattleEffectSpec.new(
		BattleEffectSpec.CHANCE, BattleEffectSpec.OPPONENT, 0, 0, chance_bp
	).with_child(child)


func _status(status_id: StringName) -> BattleEffectSpec:
	return BattleEffectSpec.new(
		BattleEffectSpec.INFLICT_STATUS,
		BattleEffectSpec.OPPONENT,
		0,
		0,
		10000,
		status_id,
	)


func _stage(target: StringName, stat_id: StringName, amount: int) -> BattleEffectSpec:
	return BattleEffectSpec.new(
		BattleEffectSpec.MODIFY_STAT_STAGE, target, amount, 0, 10000, &"", stat_id
	)