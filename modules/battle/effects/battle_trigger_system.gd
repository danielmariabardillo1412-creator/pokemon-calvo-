class_name BattleTriggerSystem
extends RefCounted


func specs_for_creature(
	creature: CreatureInstance,
	trigger: StringName,
	registry: BattleEffectRegistry,
) -> Array[BattleTriggerSpec]:
	var result: Array[BattleTriggerSpec] = []
	if creature.ability_id != &"":
		result.append_array(registry.triggers_for_ability(creature.ability_id, trigger))
	if creature.held_item_id != &"" and not creature.held_item_consumed:
		result.append_array(registry.triggers_for_item(creature.held_item_id, trigger))
	return result


func damage_modifiers(
	context: BattleEffectContext,
	registry: BattleEffectRegistry,
) -> Dictionary:
	var multiplier_bp := 10000
	var offensive_stat_multiplier_bp := 10000
	var immune := false
	for spec in registry.triggers_for_ability(
		context.actor.ability_id, BattleTriggerSpec.MODIFY_DAMAGE
	):
		if not _damage_condition_matches(spec, context.actor, context.move):
			continue
		var applied_modifier := false
		if spec.conditions.has("multiplier_bp"):
			multiplier_bp = multiplier_bp * int(spec.conditions.get("multiplier_bp", 10000)) / 10000
			applied_modifier = true
		if spec.conditions.has("offensive_stat_multiplier_bp"):
			offensive_stat_multiplier_bp = (
				offensive_stat_multiplier_bp
				* int(spec.conditions.get("offensive_stat_multiplier_bp", 10000))
				/ 10000
			)
			applied_modifier = true
		if applied_modifier:
			_emit_trigger(context, spec)
	for spec in registry.triggers_for_ability(
		context.target.ability_id, BattleTriggerSpec.MODIFY_DAMAGE
	):
		var immune_type := StringName(spec.conditions.get("immune_type_id", ""))
		if immune_type != &"" and immune_type == context.move.type_id:
			immune = true
			_emit_trigger(context, spec, context.target)
			continue
		if (
			spec.conditions.has("multiplier_bp")
			and _damage_condition_matches(spec, context.target, context.move)
		):
			multiplier_bp = multiplier_bp * int(spec.conditions.get("multiplier_bp", 10000)) / 10000
			_emit_trigger(context, spec, context.target)
	return {
		"multiplier_basis_points": multiplier_bp,
		"offensive_stat_multiplier_basis_points": offensive_stat_multiplier_bp,
		"immune": immune,
	}


func conditions_met(
	spec: BattleTriggerSpec,
	owner: CreatureInstance,
	move: MoveDefinition,
) -> bool:
	if bool(spec.conditions.get("requires_physical", false)) and (
		move == null or move.damage_class != "physical"
	):
		return false
	if bool(spec.conditions.get("requires_special", false)) and (
		move == null or move.damage_class != "special"
	):
		return false
	if bool(spec.conditions.get("requires_contact", false)) and (
		move == null or not move.makes_contact
	):
		return false
	if bool(spec.conditions.get("requires_recoil", false)) and not _move_has_effect_kind(
		move, BattleEffectSpec.RECOIL
	):
		return false
	if bool(spec.conditions.get("requires_full_hp", false)) and owner.current_hp != owner.stats.max_hp:
		return false
	if bool(spec.conditions.get("requires_missing_hp", false)) and owner.current_hp >= owner.stats.max_hp:
		return false
	var required_statuses: Array = spec.conditions.get("required_persistent_status_ids", [])
	if (
		not required_statuses.is_empty()
		and not required_statuses.has(String(owner.status_state.persistent_id))
	):
		return false
	var divisor := int(spec.conditions.get("hp_at_or_below_divisor", 0))
	if divisor > 0 and owner.current_hp * divisor > owner.stats.max_hp:
		return false
	return true


func emit_source_triggered(
	context: BattleEffectContext,
	spec: BattleTriggerSpec,
	owner: CreatureInstance,
) -> void:
	_emit_trigger(context, spec, owner)


func _damage_condition_matches(
	spec: BattleTriggerSpec,
	owner: CreatureInstance,
	move: MoveDefinition,
) -> bool:
	var required_type := StringName(spec.conditions.get("move_type_id", ""))
	if required_type != &"" and required_type != move.type_id:
		return false
	return conditions_met(spec, owner, move)


func _move_has_effect_kind(move: MoveDefinition, wanted_kind: StringName) -> bool:
	if move == null:
		return false
	for spec in move.effect_specs:
		if _effect_spec_has_kind(spec, wanted_kind):
			return true
	return false


func _effect_spec_has_kind(spec: BattleEffectSpec, wanted_kind: StringName) -> bool:
	if spec.kind == wanted_kind:
		return true
	for child in spec.children:
		if _effect_spec_has_kind(child, wanted_kind):
			return true
	return false


func _emit_trigger(
	context: BattleEffectContext,
	spec: BattleTriggerSpec,
	owner: CreatureInstance = null,
) -> void:
	var source := owner if owner != null else context.actor
	var event_kind := (
		BattleEvent.ABILITY_TRIGGERED if spec.source_kind == &"ability" else BattleEvent.ITEM_TRIGGERED
	)
	context.events.append(BattleEvent.new(
		event_kind,
		context.state.turn,
		source.instance_id,
		context.target.instance_id,
		context.move.id if context.move != null else &"",
		0,
		{"source_id": String(spec.source_id), "trigger": String(spec.trigger)},
	))
