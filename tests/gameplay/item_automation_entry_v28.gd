extends RefCounted

const Controlled = preload("res://tests/gameplay/item_automation_opponent_v28.gd")

static func run(h: SceneTree, descriptor: Dictionary) -> void:
	for spec: Dictionary in descriptor.items:
		for c: Dictionary in spec.cases:
			h.current_case = String(spec.id) + "/" + String(c.id)
			var start: int = h.checks; var failures: int = h.errors.size(); var observed := {}
			for mode: String in descriptor.variants: observed[mode] = await probe(h, spec, c, mode)
			h._row(spec.id, c.id, start, failures, observed)
		h.current_case = String(spec.id) + "/map_bag_owner_save"
		var start: int = h.checks; var failures: int = h.errors.size()
		var physical: Dictionary = await h._map_probe(StringName(spec.id), spec.consumption == "on_damaging_hit")
		h._row(spec.id, "map_bag_owner_save", start, failures, physical)

static func frame(s: RefCounted) -> Dictionary:
	var out := {"hazards": s._checkpoint.snapshot.native.sides[0].sideConditions.duplicate(true),
		"active_id": String(s.battle_state().active_for_side(&"side_a").instance_id)}
	for id: StringName in [&"own", &"reserve"]:
		var c: CreatureInstance = s.battle_state().creature(id)
		var native: Dictionary = s.Adapter.roster_row(s._checkpoint, String(id))
		out[String(id)] = {"hp": c.current_hp, "max_hp": c.stats.max_hp, "status": String(c.status_state.persistent_id),
			"spe": c.stat_stages.get_stage(&"speed"), "item": String(native.item), "consumed": c.held_item_consumed}
	return out

static func assertions(h: SceneTree, spec: Dictionary, c: Dictionary, mode: String, index: int, before: Dictionary, after: Dictionary, logs: Array) -> void:
	if c.op == "balloon_transition":
		var lost: int = int(before.own.hp) - int(after.own.hp)
		var phase: String = c.phases[index]
		var held: bool = before.own.item == "airballoon"
		if phase == "ground": h.check(mode + " actual Earthquake immunity/loss", lost == 0 if held else lost > 0)
		elif phase == "status": h.check(mode + " status does not damage", lost == 0)
		else: h.check(mode + " breaking hit actually damaged", lost > 0)
		var should_break: bool = phase == "break" and held
		h.check(mode + " exact item transition", after.own.item == ("" if should_break else before.own.item))
		if should_break:
			var notification := false
			for line: String in logs:
				if line.begins_with("|-enditem|p1a:") and line.contains("|Air Balloon"): notification = true
			h.check(mode + " real pop notification", notification and after.own.consumed)
	else:
		var hazard: String = c.hazard
		h.check(mode + " hazards really placed/preserved", after.hazards.has(hazard) if not hazard.is_empty() else after.hazards.is_empty())
		if index == 0: return
		var incoming: String = "reserve" if index in [1,3] else "own"
		h.check(mode + " intended reentry owner", after.active_id == incoming)
		var a: Dictionary = before[incoming]; var b: Dictionary = after[incoming]
		var protected: bool = a.item == "heavydutyboots"
		if hazard.is_empty() or protected:
			h.check(mode + " no hazard effects", a.hp == b.hp and b.status == "" and int(b.spe) == 0)
		elif hazard in ["stealthrock","spikes"]:
			h.check(mode + " actual entry HP damage", int(a.hp) - int(b.hp) == int(a.max_hp) / 8)
		elif hazard == "toxicspikes": h.check(mode + " actual entry poison", b.status == "poison" and int(b.hp) < int(a.hp))
		else: h.check(mode + " actual entry speed reduction", int(b.spe) == -1 and b.hp == a.hp)
		h.check(mode + " Boots retained by correct owner", after.own.item == before.own.item and after.reserve.item == before.reserve.item)

static func probe(h: SceneTree, spec: Dictionary, c: Dictionary, mode: String) -> Dictionary:
	var f: Dictionary = h._fixture(spec, "physical_damage", mode)
	var owner: PlayerCollection = f.owner
	for id: StringName in [&"own", &"reserve"]:
		var creature := owner.owned_creature(id)
		creature.moveset.clear(); creature.move_ids.clear()
		for move: String in spec.own_moves: creature.add_move(StringName(move), h.catalogs)
	var foe: CreatureInstance = h._mon(&"mew", 100, &"foe", c.foe_moves)
	var s = Controlled.new(h.catalogs, owner, h.automation.format)
	var opened: bool = await s.begin_wild(h, foe, h.automation.seed)
	h.check(mode + " native encounter opens", opened)
	if not opened: await s.close(); return {"valid":false}
	var path: String = String(h.current_case).replace("/", "_") + "_" + mode
	var restored: Dictionary = await h._restore_probe(s, owner, path + "_start", mode, Controlled)
	if not restored.valid: return {"valid":false}
	s = restored.session; owner = restored.owner
	var frozen: String = JSON.stringify(h._owner_data(owner))
	var initial: Dictionary = s.snapshot()
	var p1: Array = c.get("p1", ["move 1","switch_reserve","switch_own","switch_reserve","switch_own"])
	var p2: Array = c.get("p2", ["move 1","move 2","move 2","move 2","move 2"])
	var frames: Array = []
	var stale: Dictionary = await s.submit("move 1", s.revision + 1)
	h.check(mode + " stale revision unchanged", not stale.accepted and s.snapshot() == initial)
	for index in p1.size():
		var command: String = p1[index]
		if command.begins_with("switch_"): command = h._switch_choice(s, StringName(command.trim_prefix("switch_")))
		s.scripted_foe_choice = p2[index]
		var before := frame(s)
		var start: int = s._checkpoint.snapshot.native.log.size()
		var result: Dictionary = await s.submit(command, s.revision)
		h.check(mode + " real legal turn " + str(index) + " " + str(result.get("error", "")), result.accepted)
		if not result.accepted: await s.close(); return {"valid":false}
		var after := frame(s)
		var logs: Array = s._checkpoint.snapshot.native.log.slice(start)
		assertions(h, spec, c, mode, index, before, after, logs)
		h.check(mode + " campaign remains unpublished", JSON.stringify(h._owner_data(owner)) == frozen and h._units(owner, StringName(spec.id)) == 2)
		frames.append({"before":before,"after":after,"p1":p1[index],"p2":p2[index],"log":logs,"checkpoint":s.snapshot()})
		if index in [0,2,p1.size()-1]:
			restored = await h._restore_probe(s, owner, path + "_step_" + str(index), mode, Controlled)
			if not restored.valid: return {"valid":false}
			s = restored.session; owner = restored.owner
	var after_actions: Dictionary = s.snapshot()
	# End by real damage, then use the application's existing settlement authority.
	for turn in 5:
		if s.phase() == "finished": break
		s.scripted_foe_choice = "move 3"
		var hit: Dictionary = await s.submit("move 2", s.revision)
		h.check(mode + " terminal battle move", hit.accepted)
	h.check(mode + " actual terminal victory", s.phase() == "finished")
	var native_hp: int = s.battle_state().creature(&"own").current_hp
	var terminal: Dictionary = s.snapshot()
	var expected_consumed: bool = frame(s).own.consumed
	var finished: Dictionary = s.settle_finished_battle()
	h.check(mode + " real settlement", finished.accepted)
	var settled: Dictionary = h._owner_data(owner)
	h.check(mode + " consumed/retained campaign matches native", owner.owned_creature(&"own").held_item_consumed == expected_consumed)
	var total: int = 1 if expected_consumed else 2
	h.check(mode + " physical stock after publication", h._units(owner, StringName(spec.id)) == total)
	h.check(mode + " repeated settlement rejected", not s.settle_finished_battle().accepted and h._owner_data(owner) == settled)
	await s.close()
	var disk_hash: String = h._write_evidence(path + "_owner", {"owner":settled})
	var decoded := SaveGameRepository.new().decode_snapshot(JSON.parse_string(FileAccess.get_file_as_string(h.destination + "/" + path + "_owner.json")).owner)
	h.check(mode + " campaign decodes after settlement", decoded.ok)
	if not decoded.ok: return {"valid":false}
	var saved := PlayerCollection.new(); saved.party=decoded.party; saved.storage=decoded.storage; saved.inventory=decoded.inventory
	h.check(mode + " saved consumed/retained units and HP", h._units(saved, StringName(spec.id)) == total and saved.owned_creature(&"own").current_hp == native_hp and saved.owned_creature(&"own").held_item_consumed == expected_consumed)
	var hash: String = h._write_evidence(path, {"before":initial,"after":after_actions,"terminal":terminal,"frames":frames,"owner_after":settled,"expected_units":total})
	return {"valid":true,"restored":true,"frames":frames,"evidence":path+".json","sha256":hash,
		"settled_units":total,"consumed":expected_consumed,"owner_evidence":path+"_owner.json","owner_sha256":disk_hash}
