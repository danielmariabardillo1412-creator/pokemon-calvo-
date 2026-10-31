extends RefCounted

## Presentation only. Native roster/requests, never a second rules engine.
static func projection(packet: Dictionary, catalog: DefinitionCatalog) -> Dictionary:
	var frame := {"units": {}, "slots": {"side_a": [], "side_b": []}}
	for side: Dictionary in packet.roster:
		var label := "side_a" if side.id == "p1" else "side_b"
		frame.slots[label] = side.active_ids.duplicate()
		for i in side.active_ids.size():
			var id := String(side.active_ids[i])
			for p: Dictionary in side.pokemon:
				if p.instance_id != id: continue
				var species := String(p.species_id)
				# Native IDs omit underscores; the imported origin identity is stable.
				for key: StringName in catalog.species_catalog.all_ids():
					if String(key).replace("_", "") == species: species = String(key); break
				frame.units[id] = {"id": id, "species": species, "name": catalog.species(StringName(species)).display_name if catalog.species(StringName(species)) != null else species,
					"hp": int(p.hp), "max_hp": int(p.max_hp), "side": label, "position": i}
	return frame


static func build(events: Array[BattleEvent], before: Dictionary, final: Dictionary) -> Array[Dictionary]:
	var frame := before.duplicate(true)
	var sequence: Array[Dictionary] = []
	for event: BattleEvent in events:
		if event.kind in [BattleEvent.PP_CHANGED, BattleEvent.TURN_ENDED]: continue
		var old := frame.duplicate(true)
		var id := String(event.target_id)
		var duration := 0.22
		if event.kind == BattleEvent.ALLY_POSITIONS_SWAPPED:
			var side := String(event.metadata.side_id)
			frame.slots[side] = event.metadata.after.duplicate()
			for slot in 2:
				if frame.units.has(String(frame.slots[side][slot])): frame.units[String(frame.slots[side][slot])].position = slot
			duration = 1.5
		elif event.kind == BattleEvent.SWITCHED and final.units.has(id):
			var side := String(event.metadata.side_id)
			var slot := int(event.metadata.active_slot)
			frame.units.erase(String(frame.slots[side][slot])); frame.slots[side][slot] = id
			frame.units[id] = final.units[id].duplicate(true)
		elif frame.units.has(id):
			if event.kind in [BattleEvent.DAMAGE_APPLIED, BattleEvent.STATUS_DAMAGE]: frame.units[id].hp = maxi(0, int(frame.units[id].hp) - event.amount); duration = 0.55
			elif event.kind == BattleEvent.HP_RECOVERED: frame.units[id].hp = mini(int(frame.units[id].max_hp), int(frame.units[id].hp) + event.amount)
			elif event.kind == BattleEvent.KNOCKED_OUT: frame.units[id].hp = 0
		sequence.append({"before": old, "after": frame.duplicate(true), "event": event.to_dict(), "duration": duration})
	sequence.append({"before": final, "after": final, "event": {}, "duration": 0.01})
	return sequence
