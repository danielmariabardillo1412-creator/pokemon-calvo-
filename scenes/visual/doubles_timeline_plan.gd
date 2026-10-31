extends RefCounted


static func projection(snapshot: Dictionary) -> Dictionary:
	var result := {"units": {}, "slots": snapshot.slots.duplicate(true)}
	for row: Dictionary in snapshot.battle.participants:
		var unit := {"id": String(row.instance_id), "species": String(row.species_id), "name": String(row.species_id).capitalize(),
			"hp": int(row.current_hp), "max_hp": int(row.stats.max_hp)}
		for side: String in result.slots:
			var position: int = result.slots[side].find(unit.id)
			if position >= 0:
				unit["side"] = side
				unit["position"] = position
		result.units[unit.id] = unit
	return result


static func build(events: Array[BattleEvent], before: Dictionary) -> Array[Dictionary]:
	var frame := before.duplicate(true)
	var sequence: Array[Dictionary] = []
	for event: BattleEvent in events:
		if event.kind in [BattleEvent.PP_CHANGED, BattleEvent.TURN_ENDED]: continue
		var old := frame.duplicate(true)
		var duration := 0.22
		if event.kind == BattleEvent.ALLY_POSITIONS_SWAPPED:
			var side := String(event.metadata.side_id)
			frame.slots[side] = event.metadata.after.duplicate()
			for slot in 2: frame.units[String(frame.slots[side][slot])].position = slot
			duration = 1.5 # Source 15-frame fade out, mirrored back in at 20 fps.
		elif event.kind in [BattleEvent.DAMAGE_APPLIED, BattleEvent.STATUS_DAMAGE]:
			frame.units[String(event.target_id)].hp = maxi(0, int(frame.units[String(event.target_id)].hp) - event.amount)
			duration = 0.55
		elif event.kind == BattleEvent.KNOCKED_OUT:
			frame.units[String(event.target_id)].hp = 0
		sequence.append({"before": old, "after": frame.duplicate(true), "event": event.to_dict(), "duration": duration})
	return sequence
