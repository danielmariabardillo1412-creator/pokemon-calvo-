extends "res://tests/gameplay/item_closure_v3_test_runner.gd"

# Test orchestration only. All combat still runs through the pinned native session.
const DESCRIPTORS := "res://tests/fixtures/item_automation_v28/choice_items.json"
const EffectAssertions = preload("res://tests/gameplay/item_automation_effects_v28.gd")
const EntryScenarios = preload("res://tests/gameplay/item_automation_entry_v28.gd")
var automation: Dictionary
var destination: String
var automation_rows: Array = []
var current_case := "bootstrap"
var automation_errors: Array = []
var descriptor_hashes := {}

func _initialize() -> void:
	capture = false
	call_deferred("_run_automation")
	create_timer(360.0).timeout.connect(func():
		if not done:
			push_error("ITEM_AUTOMATION_V28 timeout")
			quit(2))

func check(label: String, valid: bool) -> void:
	super.check(current_case + ": " + label, valid)
	if not valid: automation_errors.append({"scenario": current_case, "error": label})

func _write_evidence(name: String, value: Dictionary) -> String:
	var path := destination + "/" + name + ".json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	check("evidence opens " + name, file != null)
	if file == null: return ""
	file.store_string(JSON.stringify(value, "  ")); file.close()
	return FileAccess.get_sha256(path)

func _row(item: String, scenario: String, initial: int, failures: int, observed: Dictionary) -> void:
	automation_rows.append({"id": item, "scenario": scenario,
		"status": "SCOPED_VERIFIED" if errors.size() == failures else "FAILED",
		"checks": checks - initial, "errors": errors.slice(failures), "observed": observed})

func _run_automation() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1 or not String(args[0]).begins_with(".godot/item_automation_v28/runs/"):
		push_error("Expected isolated automation output directory"); quit(2); return
	destination = "res://" + String(args[0])
	DirAccess.make_dir_recursive_absolute(destination)
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(destination + "/inputs.json"))
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("existing regional overlay", Variants.apply(catalogs))
	var item_count := 0
	for header: Dictionary in meta.descriptors:
		automation = JSON.parse_string(FileAccess.get_file_as_string("res://" + String(header.path)))
		var actual_hash := FileAccess.get_sha256("res://" + String(header.path))
		descriptor_hashes[header.path] = actual_hash
		check("descriptor agrees with validated input " + String(header.path), actual_hash == header.sha256)
		item_count += automation.items.size()
		match String(automation.family):
			"choice_held_items": await _run_choice_items()
			"passive_reactive_held_items": await _run_passive_items()
			"entry_hazard_items": await EntryScenarios.run(self, automation)
			_: check("unknown family", false)
	var report := {"status": "SCOPED_VERIFIED" if errors.is_empty() else "FAILED",
		"checks": checks, "errors": automation_errors, "items": item_count,
		"scenarios": automation_rows, "descriptor_sha256": FileAccess.get_sha256(DESCRIPTORS),
		"descriptor_hashes": descriptor_hashes,
		"functional_sha": meta.functional_sha, "checkout_sha": meta.checkout_sha, "run_url": meta.run_url,
		"limits": ["Headless, no GPU/manual approval", "Empty abilities; no ability interactions",
			"Map Caterpie battle checks physical persistence/settlement, not every effect trigger",
			"No Trick/Knock Off/suppression timing certification; no new item mechanics"]}
	var report_file := FileAccess.open(destination + "/godot.json", FileAccess.WRITE)
	if report_file == null: push_error("Cannot write final automation report"); quit(2); return
	report_file.store_string(JSON.stringify(report, "  ")); report_file.close()
	done = true
	print("ITEM_AUTOMATION_V28 ", "PASS" if errors.is_empty() else "FAIL", " checks=", checks, " ids=", item_count, " scenarios=", automation_rows.size(), " errors=", errors.size())
	quit(0 if errors.is_empty() and automation_rows.size() == int(meta.expected_rows) and checks >= int(meta.minimum_checks) else 1)

func _run_choice_items() -> void:
	for spec: Dictionary in automation.items:
		for scenario: String in ["physical_damage", "special_damage", "speed_order"]:
			current_case = String(spec.id) + "/" + scenario
			var initial := checks; var failures := errors.size()
			var observed := {}
			for mode: String in automation.variants:
				observed[mode] = await _probe(spec, scenario, mode)
			var actual: Dictionary = observed.active
			var plain: Dictionary = observed.none
			var misplaced: Dictionary = observed.reserve
			check("all isolated variants ran", actual.get("valid", false) and plain.get("valid", false) and misplaced.get("valid", false))
			if actual.get("valid", false) and plain.get("valid", false) and misplaced.get("valid", false):
				if scenario == "speed_order":
					check("control first actor is faster opponent", plain.first_actor == "foe")
					check("reserve item cannot affect active speed", misplaced.first_actor == plain.first_actor)
					check("declared turn-order effect", actual.first_actor == ("own" if spec.speed_order == "reversed" else "foe"))
				else:
					check("control actually inflicted damage", int(plain.damage) > 0)
					check("reserve item cannot boost another owner", misplaced.damage == plain.damage)
					var expected: String = spec[scenario]
					check("declared category-specific damage", int(actual.damage) > int(plain.damage) if expected == "greater" else actual.damage == plain.damage)
			_row(spec.id, scenario, initial, failures, observed)
		current_case = String(spec.id) + "/lock_restore_switch"
		var initial := checks; var failures := errors.size(); var locks := {}
		for mode: String in automation.variants: locks[mode] = await _lock_probe(spec, mode)
		_row(spec.id, "lock_restore_switch", initial, failures, locks)
		current_case = String(spec.id) + "/map_bag_owner_save"
		initial = checks; failures = errors.size()
		var physical: Dictionary = await _map_probe(StringName(spec.id))
		_row(spec.id, "map_bag_owner_save", initial, failures, physical)

func _run_passive_items() -> void:
	for spec: Dictionary in automation.items:
		for contract: Dictionary in spec.cases:
			current_case = String(spec.id) + "/" + String(contract.id)
			var initial := checks; var failures := errors.size(); var observed := {}; var valid := true
			for mode: String in automation.variants:
				observed[mode] = await _effect_probe(spec, contract, mode)
				valid = valid and observed[mode].get("valid", false)
			check("all isolated variants executed", valid)
			if valid:
				for expectation: Array in EffectAssertions.expectations(spec, contract, observed):
					check(String(expectation[0]), bool(expectation[1]))
			_row(spec.id, contract.id, initial, failures, observed)
		current_case = String(spec.id) + "/map_bag_owner_save"
		var initial := checks; var failures := errors.size()
		var physical: Dictionary = await _map_probe(StringName(spec.id))
		_row(spec.id, "map_bag_owner_save", initial, failures, physical)

func _fixture(spec: Dictionary, scenario: String, mode: String) -> Dictionary:
	var move: String = automation.physical_move
	if scenario == "special_damage": move = automation.special_move
	if scenario == "speed_order": move = automation.speed_move
	var own := _mon(StringName(automation.actor_species), int(automation.level), &"own", [move, "reflect"])
	var reserve := _mon(StringName(automation.actor_species), int(automation.level), &"reserve", ["reflect"])
	var species: String = automation.speed_target if scenario == "speed_order" else automation.damage_target
	var foe := _mon(StringName(species), int(automation.level), &"foe", ["amnesia"])
	var owner := PlayerCollection.new()
	check("fresh party actor", owner.party.add_creature(own))
	check("fresh party reserve", owner.party.add_creature(reserve))
	var item := StringName(spec.id)
	owner.inventory.add(item, 2)
	var service := Service.new()
	check("existing field item authority", service.configure(owner, catalogs, func(): return true))
	if mode != "none":
		var target := &"own" if mode == "active" else &"reserve"
		check("service equip correct owner", service.equip(item, target).accepted)
	check("abilities deliberately empty", own.ability_id == &"" and foe.ability_id == &"" and reserve.ability_id == &"")
	check("two physical units before battle", _units(owner, item) == 2)
	return {"owner": owner, "foe": foe, "service": service}

func _units(owner: PlayerCollection, item: StringName) -> int:
	var total := owner.inventory.quantity(item)
	for c: CreatureInstance in owner.party.get_creatures() + owner.storage.get_all_creatures():
		if c.held_item_id == item and not c.held_item_consumed: total += 1
	return total

func _owner_data(owner: PlayerCollection) -> Dictionary:
	return SaveGameData.build(owner.party, owner.storage, owner.inventory).to_dict()

func _equipment(session: RefCounted, owner: PlayerCollection, item: StringName, mode: String) -> void:
	for cid: StringName in [&"own", &"reserve"]:
		var expected := &""
		if mode == "active" and cid == &"own" or mode == "reserve" and cid == &"reserve": expected = item
		var c: CreatureInstance = session.battle_state().creature(cid)
		check("equipment owner " + String(cid), c != null and c.held_item_id == expected and not c.held_item_consumed)
	check("physical units retained", _units(owner, item) == 2)

func _probe(spec: Dictionary, scenario: String, mode: String) -> Dictionary:
	var f := _fixture(spec, scenario, mode)
	var owner: PlayerCollection = f.owner
	var frozen := JSON.stringify(_owner_data(owner))
	var session := Native.new(catalogs, owner, automation.format)
	var opened: bool = await session.begin_wild(self, f.foe, automation.seed)
	check(mode + " native session opens", opened)
	if not opened: await session.close(); return {"valid": false}
	var before := session.snapshot()
	var hp: int = session.battle_state().creature(&"foe").current_hp
	var result: Dictionary = await session.submit("move 1", session.revision)
	check(mode + " actual command accepted", result.accepted)
	if not result.accepted: await session.close(); return {"valid": false}
	_equipment(session, owner, StringName(spec.id), mode)
	check(mode + " campaign not published early", JSON.stringify(_owner_data(owner)) == frozen)
	var first_actor := ""
	for event: BattleEvent in result.events:
		if event.kind == BattleEvent.ACTION_USED:
			first_actor = String(event.actor_id); break
	var damage: int = hp - session.battle_state().creature(&"foe").current_hp
	var evidence := current_case.replace("/", "_") + "_" + mode
	var evidence_hash := _write_evidence(evidence, {"before": before, "after": session.snapshot()})
	await session.close()
	return {"valid": true, "damage": damage, "first_actor": first_actor,
		"evidence": evidence + ".json", "sha256": evidence_hash, "owner": "own" if mode == "active" else mode}

func _lock_probe(spec: Dictionary, mode: String) -> Dictionary:
	var f := _fixture(spec, "physical_damage", mode)
	var owner: PlayerCollection = f.owner
	var own: CreatureInstance = owner.owned_creature(&"own")
	own.moveset.clear(); own.move_ids.clear()
	for move: String in [automation.physical_move, automation.special_move]: own.add_move(StringName(move), catalogs)
	var session := Native.new(catalogs, owner, automation.format)
	var opened: bool = await session.begin_wild(self, f.foe, automation.seed)
	check(mode + " lock session opens", opened)
	if not opened: await session.close(); return {"valid": false}
	var result: Dictionary = await session.submit("move 1", session.revision)
	check(mode + " first move accepted", result.accepted)
	var path := current_case.replace("/", "_") + "_" + mode
	var reopened: Dictionary = await _restore_probe(session, owner, path, mode)
	if not reopened.valid: return {"valid": false}
	owner = reopened.owner; session = reopened.session
	var restored: bool = reopened.restored
	var frozen := JSON.stringify(_owner_data(owner))
	var boundary := session.snapshot()
	var stale: Dictionary = await session.submit("move 1", session.revision + 1)
	check(mode + " stale rejected without mutation", not stale.accepted and session.snapshot() == boundary)
	var disabled: bool = session._checkpoint.views.p1.request.active[0].moves[1].disabled
	check(mode + " native restriction belongs to active holder", disabled == (mode == "active"))
	var alternate: Dictionary = await session.submit("move 2", session.revision)
	if mode == "active":
		check("alternate choice rejected without mutation", not alternate.accepted and session.snapshot() == boundary)
		check("chosen move still usable", (await session.submit("move 1", session.revision)).accepted)
	else: check(mode + " alternative actually accepted", alternate.accepted)
	check(mode + " switch to reserve", (await session.submit(_switch_choice(session, &"reserve"), session.revision)).accepted)
	check(mode + " switch back", (await session.submit(_switch_choice(session, &"own"), session.revision)).accepted)
	var unlocked: Dictionary = await session.submit("move 2", session.revision)
	check(mode + " switch clears old choice", unlocked.accepted)
	_equipment(session, owner, StringName(spec.id), mode)
	check(mode + " owner data unchanged before settlement", JSON.stringify(_owner_data(owner)) == frozen)
	var after_hash := _write_evidence(path + "_after", {"checkpoint": session.snapshot(), "disabled_before_switch": disabled,
		"alternate_accepted": alternate.accepted, "unlocked_after_switch": unlocked.accepted})
	await session.close()
	return {"valid": true, "restored": restored, "disabled": disabled, "alternate_accepted": alternate.accepted,
		"unlocked_after_switch": unlocked.accepted, "evidence": path + "_after.json", "sha256": after_hash}

func _restore_probe(session: RefCounted, owner: PlayerCollection, path: String, label: String, constructor: Script = null) -> Dictionary:
	var checkpoint: Dictionary = session.snapshot()
	_write_evidence(path, {"owner": _owner_data(owner), "checkpoint": checkpoint})
	await session.close()
	var disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(destination + "/" + path + ".json"))
	var decoded := SaveGameRepository.new().decode_snapshot(disk.owner)
	check(label + " existing SaveV2 owner decoder", decoded.ok)
	if not decoded.ok: return {"valid": false}
	owner = PlayerCollection.new()
	owner.party = decoded.party; owner.storage = decoded.storage; owner.inventory = decoded.inventory
	var session_script: Script = Native if constructor == null else constructor
	session = session_script.new(catalogs, owner, automation.format)
	var restored: bool = await session.restore_saved(self, disk.checkpoint)
	check(label + " disk checkpoint restored", restored)
	if not restored: await session.close(); return {"valid": false}
	check(label + " restored exact snapshot", session.snapshot() == checkpoint)
	return {"valid": true, "owner": owner, "session": session, "restored": restored}

func _set_effect_moves(c: CreatureInstance, move: String) -> void:
	c.moveset.clear(); c.move_ids.clear(); c.add_move(StringName(move), catalogs)

func _effect_frame(session: RefCounted, contract: Dictionary) -> Dictionary:
	var state: BattleState = session.battle_state()
	var target: CreatureInstance = state.creature(StringName(contract.target))
	var foe: CreatureInstance = state.creature(&"foe")
	return {"target_hp": target.current_hp, "target_max_hp": target.stats.max_hp,
		"foe_hp": foe.current_hp, "foe_max_hp": foe.stats.max_hp,
		"active_id": String(state.active_for_side(&"side_a").instance_id)}

func _effect_probe(spec: Dictionary, contract: Dictionary, mode: String) -> Dictionary:
	var f := _fixture(spec, "physical_damage", mode)
	var owner: PlayerCollection = f.owner
	for cid: StringName in [&"own", &"reserve"]:
		var c := owner.owned_creature(cid)
		_set_effect_moves(c, contract.own_move)
		if contract.hp == "half": c.current_hp = c.stats.max_hp / 2
		elif contract.hp == "near_full": c.current_hp = c.stats.max_hp - 1
	f.foe = _mon(StringName(contract.foe_species), int(automation.level), &"foe", [String(contract.foe_move)])
	var session := Native.new(catalogs, owner, automation.format)
	var opened: bool = await session.begin_wild(self, f.foe, automation.seed)
	check(mode + " native effect session opens", opened)
	if not opened: await session.close(); return {"valid": false}
	var path := current_case.replace("/", "_") + "_" + mode
	var reopened: Dictionary = await _restore_probe(session, owner, path + "_initial", mode)
	if not reopened.valid: return {"valid": false}
	owner = reopened.owner; session = reopened.session
	var frozen := JSON.stringify(_owner_data(owner))
	var before: Dictionary = session.snapshot()
	var stale: Dictionary = await session.submit("move 1", session.revision + 1)
	check(mode + " stale rejected without mutation", not stale.accepted and session.snapshot() == before)
	var frames: Array = []
	for index in contract.commands.size():
		var command: String = contract.commands[index]
		if command == "switch_to_reserve": command = _switch_choice(session, &"reserve")
		var prior := _effect_frame(session, contract)
		var action: Dictionary = await session.submit(command, session.revision)
		check(mode + " effect command " + str(index), action.accepted)
		if not action.accepted: await session.close(); return {"valid": false}
		frames.append({"before": prior, "after": _effect_frame(session, contract), "command": contract.commands[index]})
		_equipment(session, owner, StringName(spec.id), mode)
		check(mode + " campaign not published early " + str(index), JSON.stringify(_owner_data(owner)) == frozen)
		reopened = await _restore_probe(session, owner, path + "_turn_" + str(index), mode)
		if not reopened.valid: return {"valid": false}
		owner = reopened.owner; session = reopened.session
	var hash := _write_evidence(path, {"before": before, "after": session.snapshot(), "frames": frames})
	await session.close()
	return {"valid": true, "restored": true, "frames": frames, "evidence": path + ".json", "sha256": hash}

func _bag_target(bag: Control, cid: StringName) -> void:
	for index in bag._targets.item_count:
		if bag._targets.get_item_metadata(index) == String(cid): bag._targets.select(index); return
	check("bag target exists " + String(cid), false)

func _switch_choice(session: RefCounted, cid: StringName) -> String:
	# Showdown swaps active and bench slots; command indices are not identities.
	var roster: Array = session._checkpoint.roster[0].pokemon
	for index in roster.size():
		if String(roster[index].instance_id) == String(cid): return "switch " + str(index + 1)
	check("switch identity exists " + String(cid), false)
	return "switch 99"

func _map_probe(item: StringName, consume_after_hit: bool = false) -> Dictionary:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene); await process_frame; await physics_frame
	var config: Dictionary = scene._active_config.duplicate(true)
	config.encounter_chance_percent = 100; config.wild_species_id = "pidgey" if consume_after_hit else "caterpie"
	config.wild_min_level = 1; config.wild_max_level = 1
	scene._on_configuration_applied(config)
	var owner: PlayerCollection = scene.field_collection()
	var own_id: StringName = owner.party.get_creatures()[0].instance_id
	var own := _mon(&"mew", 50, own_id, ["quick_attack", "growl"])
	check("map real owner", owner.replace_owned_same_identity(own))
	var other_id := StringName("recipient_" + String(item))
	check("map second owner", owner.party.add_creature(_mon(&"mew", 50, other_id, ["growl"])))
	owner.inventory.add(item, 2)
	check("map real bag opens", scene.toggle_item_bag())
	var bag = scene._item_bag
	_select(bag, String(item)); _bag_target(bag, own_id)
	check("map bag equips first owner", bag._apply("equip").accepted)
	check("first owner physical equipment", owner.owned_creature(own_id).held_item_id == item and _units(owner, item) == 2)
	check("bag removes from first owner", bag._apply("unequip").accepted)
	_select(bag, String(item)); _bag_target(bag, other_id)
	check("bag equips second owner", bag._apply("equip").accepted)
	check("equipment moves to selected owner only", owner.owned_creature(own_id).held_item_id == &"" and owner.owned_creature(other_id).held_item_id == item and _units(owner, item) == 2)
	check("bag removes from second owner", bag._apply("unequip").accepted)
	_select(bag, String(item)); _bag_target(bag, own_id)
	check("bag returns item to battle owner", bag._apply("equip").accepted)
	bag.hide(); await process_frame
	var bridge = scene._native_battles
	bridge.save_path = destination + "/map_" + String(item) + ".json"
	check("map save before battle", bridge.save_game())
	check("map reload before battle", await bridge.load_game())
	owner = scene.field_collection()
	check("map correct owner after disk reload", owner.owned_creature(own_id).held_item_id == item and owner.owned_creature(other_id).held_item_id == &"" and _units(owner, item) == 2)
	scene.player.global_position = Vector2(420, 150)
	await scene._on_player_step_completed(scene.player.global_position)
	var view = bridge.view
	view._playback.set_process(false)
	var opened: bool = view.session != null and view.session.battle_state() != null
	check("map actual native encounter " + String(bridge.last_error), opened)
	if not opened:
		scene.queue_free(); await process_frame; return {"valid": false}
	check("map item on actual active owner", view.session.battle_state().active_for_side(&"side_a").instance_id == own_id and view.session.battle_state().creature(own_id).held_item_id == item)
	check("map active save", bridge.save_game())
	check("map active reload", await bridge.load_game())
	view._playback.set_process(false)
	check("map active equipment survived reload", view.session.battle_state().creature(own_id).held_item_id == item)
	var observed_consumption := false
	var breaking_evidence := {}
	if consume_after_hit:
		var before_snapshot: Dictionary = view.session.snapshot()
		var hp_before: int = view.session.battle_state().creature(own_id).current_hp
		var before: bool = view.session.battle_state().creature(own_id).held_item_consumed
		var hit: Dictionary = await view.choose("move 2")
		check("map real breaking hit turn", hit.accepted)
		await _drain_view(view)
		observed_consumption = not before and view.session.battle_state().creature(own_id).held_item_consumed
		var break_name := "map_" + String(item) + "_break"
		breaking_evidence = {"evidence": break_name + ".json", "sha256": _write_evidence(break_name, {"before": before_snapshot, "after": view.session.snapshot(), "owner": String(own_id)})}
		check("map real loss and item transition", observed_consumption and view.session.battle_state().creature(own_id).current_hp < hp_before)
		check("map campaign not consumed early", not scene.field_collection().owned_creature(own_id).held_item_consumed)
		check("map popped battle saves", bridge.save_game())
		check("map popped battle reloads", await bridge.load_game())
		view._playback.set_process(false)
		check("map popped state survived restore", view.session.battle_state().creature(own_id).held_item_consumed)
	var result: Dictionary = await view.choose("move 1")
	check("map actual attack accepted", result.accepted)
	if result.accepted:
		await _drain_view(view)
		check("map victory", view.session.completion_reason == "VICTORY")
		var final_hp: int = view.session.battle_state().creature(own_id).current_hp
		await bridge.leave_battle()
		owner = scene.field_collection()
		check("map actual HP published to owner", owner.owned_creature(own_id).current_hp == final_hp)
		var frozen := JSON.stringify(_owner_data(owner))
		await bridge.leave_battle()
		check("map repeated close no duplicate award", JSON.stringify(_owner_data(scene.field_collection())) == frozen)
		check("map final save", bridge.save_game())
		check("map final reload", await bridge.load_game())
		owner = scene.field_collection()
		check("map actual HP retained after disk reload", owner.owned_creature(own_id).current_hp == final_hp)
		check("map expected consumed/retained state after settlement", owner.owned_creature(own_id).held_item_id == item and owner.owned_creature(own_id).held_item_consumed == consume_after_hit)
		check("map other owner untouched", owner.owned_creature(other_id).held_item_id == &"")
		check("map physical units match observed transition", _units(owner, item) == (1 if consume_after_hit else 2) and owner.inventory.quantity(item) == 1)
	var hash := FileAccess.get_sha256(bridge.save_path)
	if view.session != null: await view.session.close()
	scene.queue_free(); await process_frame
	return {"valid": result.accepted, "map_save": "map_" + String(item) + ".json", "sha256": hash,
		"battle_owner": String(own_id), "second_owner": String(other_id), "physical_units": _units(owner, item), "consumed_transition": observed_consumption, "breaking_evidence": breaking_evidence}
