class_name StatusSystem
extends RefCounted


func process_end_turn(state: BattleState, catalog: DefinitionCatalog) -> Array[BattleEvent]:
	var events: Array[BattleEvent] = []
	for creature_id in state.active_ids:
		var creature := state.creature(creature_id)
		if creature.is_knocked_out():
			continue
		for status_id in creature.status_ids:
			var definition := catalog.status(status_id) as StatusDefinition
			if definition == null:
				continue
			var applied := creature.apply_damage(definition.end_turn_damage(creature.stats.max_hp))
			if applied <= 0:
				continue
			events.append(BattleEvent.new(
				BattleEvent.STATUS_DAMAGE,
				state.turn,
				creature.instance_id,
				creature.instance_id,
				&"",
				applied,
				{"status_id": String(status_id)},
			))
			if creature.is_knocked_out():
				var opponent := state.opponent_of(creature.instance_id)
				var winner_id := opponent.instance_id if opponent != null else &""
				events.append(BattleEvent.new(
					BattleEvent.KNOCKED_OUT,
					state.turn,
					winner_id,
					creature.instance_id,
					&"",
					0,
					{"cause": "status", "status_id": String(status_id)},
				))
				state.phase = BattleState.FINISHED
				state.winner_id = winner_id
				events.append(BattleEvent.new(BattleEvent.BATTLE_ENDED, state.turn, winner_id))
				return events
	return events

