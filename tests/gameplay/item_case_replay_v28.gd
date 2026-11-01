extends "res://tests/gameplay/item_automation_v28.gd"

# Replays original V2/V3 DTOs/commands; there are no item-effect rules here.
const Controlled = preload("res://tests/gameplay/item_automation_opponent_v28.gd")

func _initialize() -> void:
	call_deferred("_run_replay")
	create_timer(360).timeout.connect(func(): if not done: quit(2))

func _run_replay() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1 or not String(args[0]).begins_with(".godot/item_automation_v28/runs/"): quit(2); return
	destination = "res://" + args[0]
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(destination + "/inputs.json"))
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	automation = {"format":"gen9calvounifiedv1"}
	var rows: Array = []; var maps := {}
	for source: Dictionary in meta.sources:
		for row: Dictionary in JSON.parse_string(FileAccess.get_file_as_string("res://" + String(source.cases))):
			if row.id not in meta.ids: continue
			current_case = row.case_id
			var start := checks; var failed := errors.size()
			var observed: Dictionary = await _replay(row)
			rows.append({"case_id":row.case_id,"id":row.id,"checks":checks-start,"errors":errors.slice(failed),"observed":observed})
	for id: String in meta.ids:
		current_case = id + "/map_bag_owner_save"
		maps[id] = await _map_probe(StringName(id))
	done = true
	_write_evidence("godot", {"status":"REPLAY_INTEGRATION_PASS" if errors.is_empty() else "FAIL","checks":checks+1,"errors":automation_errors,"cases":rows,"maps":maps,"full_item_certification":false})
	print("ITEM_CASE_REPLAY_V28 ", "PASS" if errors.is_empty() else "FAIL", " checks=",checks," cases=",rows.size())
	quit(0 if errors.is_empty() and rows.size() == int(meta.case_count) else 1)

func _replay(row: Dictionary) -> Dictionary:
	check("single wild opponent supported", row.origin.p2.size() == 1)
	var owner := PlayerCollection.new(); var equipment := {}
	for record: Dictionary in row.origin.p1:
		var c := CreatureInstance.from_dict(record)
		if c.held_item_id != &"": equipment[c.instance_id] = c.held_item_id
		c.held_item_id = &""; c.held_item_consumed = false
		check("party DTO imported", owner.party.add_creature(c))
	var service := Service.new()
	check("existing equipment authority", service.configure(owner,catalogs,func(): return true))
	for cid: StringName in equipment:
		owner.inventory.add(equipment[cid],2)
		check("original holder equipped", service.equip(equipment[cid],cid).accepted)
	owner.inventory.add(&"poke_doll",1)
	var session = Controlled.new(catalogs,owner,automation.format)
	var ok: bool = await session.begin_wild(self,CreatureInstance.from_dict(row.origin.p2[0]),[int(row.seed),2,3,4])
	check("real session opens",ok)
	if not ok: await session.close(); return {"valid":false}
	check("original initial native hash",session._checkpoint.state_hash == row.before.state_hash)
	var name: String = row.case_id.replace("/","_")
	var frozen := JSON.stringify(_owner_data(owner))
	var stale: Dictionary = await session.submit(row.commands[0].p1,session.revision+1)
	check("stale rejected",not stale.accepted and session._checkpoint.state_hash == row.before.state_hash)
	for i in row.commands.size():
		session.scripted_foe_choice=row.commands[i].p2
		var result: Dictionary = await session.submit(row.commands[i].p1,session.revision)
		check("original command accepted",result.accepted)
		check("exact asserted native step",session._checkpoint.state_hash == row.steps[i].state_hash)
		check("campaign unpublished",JSON.stringify(_owner_data(owner)) == frozen)
	var matched_hash: String = session._checkpoint.state_hash
	var restored: Dictionary = await _restore_probe(session,owner,name+"_final","replay",Controlled)
	if not restored.valid: return {"valid":false}
	session=restored.session;owner=restored.owner
	check("complete restored native state matches original",session._checkpoint.snapshot == row.steps[-1].snapshot)
	var expected := {}; var units: int = owner.inventory.quantity(StringName(row.id))
	for c: CreatureInstance in owner.party.get_creatures():
		var projected: CreatureInstance = session.battle_state().creature(c.instance_id)
		expected[String(c.instance_id)] = projected.to_dict()
		if projected.held_item_id == StringName(row.id) and not projected.held_item_consumed: units+=1
	var checkpoint: Dictionary = session.snapshot()
	var native_hash: String = session._checkpoint.state_hash
	var active_id: StringName = session.battle_state().active_for_side(&"side_a").instance_id
	var finish: Dictionary = await session.use_item(&"poke_doll",active_id,session.revision)
	check("existing terminal publication FLED",finish.accepted and session.completion_reason == "FLED")
	var published := _owner_data(owner)
	check("repeated publication rejected",not (await session.use_item(&"poke_doll",active_id,session.revision)).accepted and _owner_data(owner) == published)
	check("held stock matches actual native projection",_units(owner,StringName(row.id)) == units and owner.inventory.quantity(StringName(row.id)) == 1)
	var saved := SaveGameRepository.new().decode_snapshot(published)
	check("existing owner decoder",saved.ok)
	if saved.ok:
		var decoded := PlayerCollection.new();decoded.party=saved.party;decoded.storage=saved.storage;decoded.inventory=saved.inventory
		check("physical stock persists",_units(decoded,StringName(row.id)) == units)
		for cid: String in expected:
			for c: CreatureInstance in [owner.owned_creature(StringName(cid)),decoded.owned_creature(StringName(cid))]:
				check("HP/equipment/removal/status persist",c.current_hp == int(expected[cid].current_hp) and String(c.held_item_id) == expected[cid].held_item_id and c.held_item_consumed == expected[cid].held_item_consumed and String(c.status_state.persistent_id) == expected[cid].status_state.persistent_id)
	var hash := _write_evidence(name,{"checkpoint":checkpoint,"matched_replay_hash":matched_hash,"after_restore_native_hash":native_hash,"owner_after":published,"physical_units":units})
	await session.close()
	return {"valid":true,"evidence":name+".json","sha256":hash,"final_hash":matched_hash,"physical_units":units}
