class_name BattleEffectRegistry
extends RefCounted

var _move_specs: Dictionary = {}
var _ability_specs: Dictionary = {}
var _item_specs: Dictionary = {}


func _init() -> void:
	_register_moves()
	_register_abilities()
	_register_items()


func effects_for_move(move: MoveDefinition) -> Array[BattleEffectSpec]:
	var result: Array[BattleEffectSpec] = []
	if move.power > 0:
		result.append(BattleEffectSpec.new(BattleEffectSpec.DAMAGE))
	for spec in _move_specs.get(move.id, []):
		result.append(spec)
	return result


func triggers_for_ability(ability_id: StringName, trigger: StringName) -> Array[BattleTriggerSpec]:
	return _filter_triggers(_ability_specs.get(ability_id, []), trigger)


func triggers_for_item(item_id: StringName, trigger: StringName) -> Array[BattleTriggerSpec]:
	return _filter_triggers(_item_specs.get(item_id, []), trigger)


func has_explicit_move_mapping(move_id: StringName) -> bool:
	return _move_specs.has(move_id) or [
		&"tackle", &"water_gun", &"quick_attack",
	].has(move_id)


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
	for pair in [[&"blaze", &"fire"], [&"torrent", &"water"], [&"overgrow", &"grass"]]:
		_ability_specs[pair[0]] = [BattleTriggerSpec.new(
			BattleTriggerSpec.MODIFY_DAMAGE,
			&"ability",
			pair[0],
			BattleEffectSpec.new(BattleEffectSpec.DAMAGE),
			0,
			{"move_type_id": String(pair[1]), "hp_at_or_below_divisor": 3, "multiplier_bp": 15000},
		)]
	_ability_specs[&"levitate"] = [BattleTriggerSpec.new(
		BattleTriggerSpec.MODIFY_DAMAGE,
		&"ability",
		&"levitate",
		BattleEffectSpec.new(BattleEffectSpec.DAMAGE),
		0,
		{"immune_type_id": "ground"},
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
		{"requires_physical": true},
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
