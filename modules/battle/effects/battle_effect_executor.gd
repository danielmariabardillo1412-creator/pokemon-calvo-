class_name BattleEffectExecutor
extends RefCounted

const Substitute = preload("res://modules/battle/application/substitute_rules.gd")
const Weather = preload("res://modules/battle/application/weather_rules.gd")
const StageMoves = preload("res://modules/battle/application/stat_stage_move_rules.gd")
const VariableMoves = preload("res://modules/battle/application/variable_power_move_rules.gd")
const Bindings = preload("res://modules/battle/application/binding_move_rules.gd")

var _damage_calculator := DamageCalculator.new()
var _status_system := StatusSystem.new()
var _trigger_system := BattleTriggerSystem.new()


func execute_all(
	specs: Array[BattleEffectSpec],
	context: BattleEffectContext,
	registry: BattleEffectRegistry,
) -> Array[BattleEffectResult]:
	var results: Array[BattleEffectResult] = []
	for spec in specs:
		results.append(execute(spec, context, registry))
	return results


func execute(
	spec: BattleEffectSpec,
	context: BattleEffectContext,
	registry: BattleEffectRegistry,
) -> BattleEffectResult:
	var recipient := context.resolve_target(spec.target)
	if Substitute.effect_blocked(spec, context):
		if not context.substitute_block_reported:
			context.substitute_block_reported = true
			context.events.append(BattleEvent.new(BattleEvent.SUBSTITUTE_BLOCKED, context.state.turn,
				context.actor.instance_id, recipient.instance_id, context.move.id))
		return BattleEffectResult.new(false, 0, &"substitute")
	match spec.kind:
		BattleEffectSpec.DAMAGE:
			return _damage(context, registry)
		BattleEffectSpec.HEAL:
			var requested := spec.value
			if spec.ratio_basis_points > 0:
				requested = recipient.stats.max_hp * spec.ratio_basis_points / 10000
			var healed := recipient.recover_hp(maxi(1, requested))
			if healed > 0:
				context.events.append(BattleEvent.new(
					BattleEvent.HP_RECOVERED,
					context.state.turn,
					context.actor.instance_id,
					recipient.instance_id,
					context.move.id if context.move != null else &"",
					healed,
				))
			return BattleEffectResult.new(healed > 0, healed, &"" if healed > 0 else &"full_hp")
		BattleEffectSpec.RECOIL:
			if context.last_damage <= 0:
				return BattleEffectResult.new(false, 0, &"no_damage")
			var recoil := maxi(1, context.last_damage * spec.ratio_basis_points / 10000)
			var recoil_applied := recipient.apply_damage(recoil)
			context.events.append(BattleEvent.new(
				BattleEvent.RECOIL_DAMAGE,
				context.state.turn,
				context.actor.instance_id,
				recipient.instance_id,
				context.move.id,
				recoil_applied,
			))
			return BattleEffectResult.new(recoil_applied > 0, recoil_applied)
		BattleEffectSpec.DRAIN:
			if context.last_damage <= 0:
				return BattleEffectResult.new(false, 0, &"no_damage")
			var drain := maxi(1, context.last_damage * spec.ratio_basis_points / 10000)
			var drained := recipient.recover_hp(drain)
			if drained > 0:
				context.events.append(BattleEvent.new(
					BattleEvent.HP_RECOVERED,
					context.state.turn,
					context.actor.instance_id,
					recipient.instance_id,
					context.move.id if context.move != null else &"",
					drained,
					{"cause": "drain"},
				))
			return BattleEffectResult.new(drained > 0, drained)
		BattleEffectSpec.INFLICT_STATUS:
			return _status_system.try_apply(
				context.state,
				context.actor,
				recipient,
				spec.status_id,
				context.catalog,
				context.rng,
				context.events,
				context.ruleset,
			)
		BattleEffectSpec.CURE_STATUS:
			return _status_system.cure_persistent(
				context.state, context.actor, recipient, context.events
			)
		BattleEffectSpec.MODIFY_STAT_STAGE:
			var before := recipient.stat_stages.get_stage(spec.stat_id)
			var changed := recipient.stat_stages.change(spec.stat_id, spec.value)
			context.events.append(BattleEvent.new(
				BattleEvent.STAT_STAGE_CHANGED,
				context.state.turn,
				context.actor.instance_id,
				recipient.instance_id,
				context.move.id if context.move != null else &"",
				changed,
				{
					"stat_id": String(spec.stat_id),
					"before": before,
					"after": recipient.stat_stages.get_stage(spec.stat_id),
				},
			))
			return BattleEffectResult.new(changed != 0, changed, &"stage_cap" if changed == 0 else &"")
		BattleEffectSpec.CHANCE:
			if not context.rng.roll_basis_points(spec.chance_basis_points):
				return BattleEffectResult.new(false, 0, &"chance_failed")
			var any_applied := false
			for child in spec.children:
				any_applied = execute(child, context, registry).applied or any_applied
			return BattleEffectResult.new(any_applied)
		BattleEffectSpec.FLINCH:
			return _status_system.try_apply(
				context.state,
				context.actor,
				recipient,
				StatusSystem.FLINCH,
				context.catalog,
				context.rng,
				context.events,
				context.ruleset,
			)
		BattleEffectSpec.FIXED_DAMAGE:
			var fixed := Substitute.damage(context, recipient, spec.value, {"fixed": true})
			context.last_damage = fixed
			return BattleEffectResult.new(fixed > 0, fixed)
		BattleEffectSpec.MAX_HP_DAMAGE:
			var requested := maxi(1, recipient.stats.max_hp * spec.ratio_basis_points / 10000)
			var max_hp_damage := Substitute.damage(context, recipient, requested,
				{"cause": "max_hp_fraction", "ratio_basis_points": spec.ratio_basis_points})
			if context.state.substitute_rules_enabled and not context.is_trigger:
				context.last_damage = max_hp_damage
			return BattleEffectResult.new(max_hp_damage > 0, max_hp_damage)
		BattleEffectSpec.MULTI_HIT:
			if spec.max_hits <= spec.min_hits:
				spec.max_hits = spec.min_hits
			var hits := spec.min_hits
			if spec.max_hits > spec.min_hits:
				hits = spec.min_hits + context.rng.next_index(spec.max_hits - spec.min_hits + 1)
			var total := 0
			var total_damage := 0
			var completed_hits := 0
			var any_applied := false
			for i in hits:
				if context.state.substitute_rules_enabled and context.target.is_knocked_out(): break
				completed_hits += 1
				var dmg_result := _damage(context, registry)
				total += dmg_result.amount
				total_damage += dmg_result.amount
				any_applied = dmg_result.applied or any_applied
				for child in spec.children:
					var cr := execute(child, context, registry)
					total += cr.amount
					any_applied = cr.applied or any_applied
			if context.state.substitute_rules_enabled: context.last_damage = total_damage
			context.events.append(BattleEvent.new(
				BattleEvent.MULTI_HIT,
				context.state.turn,
				context.actor.instance_id,
				context.target.instance_id,
				context.move.id,
				completed_hits if context.state.substitute_rules_enabled else hits,
			))
			return BattleEffectResult.new(any_applied, total, &"" if any_applied else &"no_damage")
	return BattleEffectResult.new(false, 0, &"unsupported_effect")


func _damage(
	context: BattleEffectContext,
	registry: BattleEffectRegistry,
) -> BattleEffectResult:
	context.last_hit_substitute = false
	var modifiers := _trigger_system.damage_modifiers(context, registry)
	if modifiers.immune:
		context.events.append(BattleEvent.new(
			BattleEvent.TYPE_EFFECTIVENESS,
			context.state.turn,
			context.actor.instance_id,
			context.target.instance_id,
			context.move.id,
			0,
			{"category": "immune", "multiplier_basis_points": 0},
		))
		return BattleEffectResult.new(false, 0, &"immune")
	if context.state.live_moves_enabled and not context.is_trigger and context.move.id == &"spectral_thief" and StageMoves.supports(context.move):
		var effective := 1.0
		for id: StringName in context.catalog.species(context.target.species_id).type_ids_resolved():
			effective *= context.catalog.type(context.move.type_id).multiplier_against(id)
		if effective > 0: StageMoves.steal(context)
	var result := _damage_calculator.calculate(
		context.actor,
		context.target,
		context.move,
		context.catalog,
		context.rng,
		context.ruleset,
		int(modifiers.multiplier_basis_points) * Weather.damage_multiplier(context.state, context.move) / 10000,
		int(modifiers.force_critical),
		int(modifiers.offensive_stat_multiplier_basis_points),
		Weather.defense_multiplier(context.state, context.target, context.move, context.catalog),
		context.state.live_moves_enabled and context.move.id == &"struggle",
	)
	if context.state.live_moves_enabled and not context.is_trigger and VariableMoves.supports(context.catalog.move(context.move.id)) and int(result.effectiveness_basis_points) > 0:
		result["resolved_power"] = context.move.power
		result["resolved_contact"] = context.move.makes_contact
	if result.critical:
		context.events.append(BattleEvent.new(
			BattleEvent.CRITICAL_HIT,
			context.state.turn,
			context.actor.instance_id,
			context.target.instance_id,
			context.move.id,
		))
	var effectiveness_bp := int(result.effectiveness_basis_points)
	if effectiveness_bp != 10000:
		var category := "immune" if effectiveness_bp == 0 else (
			"super_effective" if effectiveness_bp > 10000 else "not_very_effective"
		)
		context.events.append(BattleEvent.new(
			BattleEvent.TYPE_EFFECTIVENESS,
			context.state.turn,
			context.actor.instance_id,
			context.target.instance_id,
			context.move.id,
			0,
			{"category": category, "multiplier_basis_points": effectiveness_bp},
		))
	var applied := Substitute.damage(context, context.target, int(result.amount), result)
	context.last_damage = applied
	if context.state.live_moves_enabled and not context.is_trigger and Bindings.supports(context.catalog.move(context.move.id)):
		Bindings.after_damage(context)
	if context.state.live_moves_enabled and not context.is_trigger and context.move.id == &"clear_smog" and StageMoves.supports(context.move):
		StageMoves.clear_smog(context)
	return BattleEffectResult.new(applied > 0, applied, &"immune" if applied == 0 else &"", result)
