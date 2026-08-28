class_name TurnExecutor
extends RefCounted

var _resolver := TurnResolver.new()
var _damage_calculator := DamageCalculator.new()


func execute(
	state: BattleState,
	actions: Array[BattleAction],
	catalog: DefinitionCatalog,
	rng: SeededRandomSource,
) -> Array[BattleEvent]:
	state.turn += 1
	var events: Array[BattleEvent] = []
	var ordered_actions := _resolver.resolve_order(actions, state, catalog, rng)
	for action in ordered_actions:
		var actor := state.creature(action.actor_id)
		var target := state.creature(action.target_id)
		if actor.is_knocked_out() or target.is_knocked_out():
			continue
		var move := catalog.move(action.move_id)
		events.append(BattleEvent.new(
			BattleEvent.ACTION_USED, state.turn, actor.instance_id, target.instance_id, move.id
		))
		var result := _damage_calculator.calculate(actor, target, move, catalog, rng)
		if result.amount > 0:
			var applied := target.apply_damage(result.amount)
			events.append(BattleEvent.new(
				BattleEvent.DAMAGE_APPLIED,
				state.turn,
				actor.instance_id,
				target.instance_id,
				move.id,
				applied,
				result,
			))
		if target.is_knocked_out():
			events.append(BattleEvent.new(
				BattleEvent.KNOCKED_OUT, state.turn, actor.instance_id, target.instance_id
			))
			_finish_battle(state, actor.instance_id, events)
			state.rng_state = rng.state()
			return events
	events.append(BattleEvent.new(BattleEvent.TURN_ENDED, state.turn))
	state.rng_state = rng.state()
	return events


func _finish_battle(state: BattleState, winner_id: StringName, events: Array[BattleEvent]) -> void:
	state.phase = BattleState.FINISHED
	state.winner_id = winner_id
	events.append(BattleEvent.new(BattleEvent.BATTLE_ENDED, state.turn, winner_id))

