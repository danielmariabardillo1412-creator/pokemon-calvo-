extends RefCounted

const SwitchRules = preload("res://modules/battle/application/switch_move_rules.gd")
const WeatherRules = preload("res://modules/battle/application/weather_rules.gd")
const SubRules = preload("res://modules/battle/application/substitute_rules.gd")
const TransformRules = preload("res://modules/battle/application/transform_rules.gd")
const StageRules = preload("res://modules/battle/application/stat_stage_move_rules.gd")
const FixedRules = preload("res://modules/battle/application/fixed_damage_move_rules.gd")
const VariableRules = preload("res://modules/battle/application/variable_power_move_rules.gd")
const BindingRules = preload("res://modules/battle/application/binding_move_rules.gd")
const HealingRules = preload("res://modules/battle/application/healing_move_rules.gd")
const ContentPolicy = preload("res://modules/gameplay/randomlock_content_policy.gd")
static var _content: RefCounted


static func apply(state: BattleState) -> void:
	state.live_moves_enabled = true
	state.switch_move_rules_enabled = true
	state.weather_rules_enabled = true
	state.substitute_rules_enabled = true
	state.transform_rules_enabled = true


static func reason(move: MoveDefinition) -> String:
	if move == null: return "unknown_move"
	if move.id == &"ally_switch": return "requires_doubles"
	if _content == null:
		_content = ContentPolicy.new()
		_content.load_local()
	if not _content.move_allowed(String(move.id)): return "content_" + _content.move_state(String(move.id))
	if StageRules.TYPES.has(move.id): return "" if StageRules.supports(move) else "mechanics_contract_mismatch"
	if FixedRules.CONTRACTS.has(move.id): return "" if FixedRules.supports(move) else "mechanics_contract_mismatch"
	if VariableRules.CONTRACTS.has(move.id): return "" if VariableRules.supports(move) else "mechanics_contract_mismatch"
	if BindingRules.CONTRACTS.has(move.id): return "" if BindingRules.supports(move) else "mechanics_contract_mismatch"
	if HealingRules.CONTRACTS.has(move.id): return "" if HealingRules.supports(move) else "mechanics_contract_mismatch"
	if SwitchRules.supports(move) or WeatherRules.supports(move) or SubRules.supports(move) or TransformRules.supports(move): return ""
	if move.classification == "RUNTIME_SUPPORTED": return ""
	if move.id == &"tera_blast" and move.power == 80 and move.type_id == &"normal" and move.damage_class == "special" and move.effect_specs.is_empty(): return ""
	return "mechanics_" + move.classification.to_lower()


static func moves(actor: CreatureInstance, catalog: DefinitionCatalog) -> Array[StringName]:
	var ids: Array[StringName] = []
	for slot: BattleMoveSlot in actor.moveset:
		if slot.current_pp > 0 and reason(catalog.move(slot.move_id)).is_empty(): ids.append(slot.move_id)
	if ids.is_empty(): ids.append(&"struggle")
	return ids


static func forced_struggle(actor: CreatureInstance, catalog: DefinitionCatalog) -> bool:
	for slot: BattleMoveSlot in actor.moveset:
		if slot.current_pp > 0 and reason(catalog.move(slot.move_id)).is_empty(): return false
	return true


static func replacement(state: BattleState, side: StringName, catalog: DefinitionCatalog) -> StringName:
	var candidates := SwitchRules.replacements(state, side)
	var opponent := state.opponent_of(state.active_for_side(side).instance_id)
	var best: StringName = &""
	var best_score := -2147483648
	for value: String in candidates:
		var creature := state.creature(StringName(value))
		var score := int(1000.0 * creature.current_hp / creature.stats.max_hp)
		var best_attack := 0
		for id: StringName in moves(creature, catalog):
			var move := catalog.move(id)
			if move != null and move.power > 0 and opponent != null:
				var multiplier := 1.0
				for type: StringName in catalog.species(opponent.species_id).type_ids_resolved():
					multiplier *= catalog.type(move.type_id).multiplier_against(type)
				best_attack = maxi(best_attack, mini(500, int(move.power * multiplier)))
		score += best_attack
		if score > best_score:
			best_score = score
			best = creature.instance_id
	return best
