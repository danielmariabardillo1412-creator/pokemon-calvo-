extends SceneTree

const Backend = preload("res://modules/battle/backends/showdown/showdown_backend.gd")
const Adapter = preload("res://modules/battle/backends/showdown/event_adapter.gd")
const OUT := "res://.godot/item_verification_v3/"
const STATS := {"atk": "attack", "def": "defense", "spa": "special_attack", "spd": "special_defense", "spe": "speed", "accuracy": "accuracy", "evasion": "evasion"}
var checks := 0
var errors: Array[String] = []
var results: Array = []
var active: RefCounted
var done := false


func _initialize() -> void: call_deferred("_run")


func check(label: String, ok: bool) -> bool:
	checks += 1
	if not ok: errors.append(label); push_error(label)
	return ok


func _run() -> void:
	create_timer(300).timeout.connect(func():
		if done: return
		if active != null: active.stop_now()
		check("watchdog", false); _finish())
	var catalogs := GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string(OUT + "cases.json"))
	var live_ids: Dictionary = {}
	var preferred: Dictionary = {}
	var activated: Dictionary = {}
	var native: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUT + "native.json"))
	for row: Dictionary in native.results:
		if not preferred.has(row.id): preferred[row.id] = row.case_id
		if row.get("branch") == "activated" and not activated.has(row.id):
			preferred[row.id] = row.case_id; activated[row.id] = true
	active = Backend.new(catalogs, "gen9calvounifiedv1")
	for row: Dictionary in rows:
		active._origin = row.origin
		var before: Dictionary = row.before
		var supported := true
		var after: Dictionary = row.steps[-1]
		for step_index: int in row.steps.size():
			var step: Dictionary = row.steps[step_index]
			var projection: Dictionary = Adapter.project(before, step, active._moves, active._policy, active._species)
			if not projection.ok:
				results.append({"id": row.id, "family": row.family, "case_id": row.case_id, "status": "PENDING_GODOT_PROTOCOL", "step": step_index, "unknown": projection.unknown})
				supported = false; break
			if row.id == "ability_shield":
				var notices: Array = projection.events.filter(func(value): return value.kind == BattleEvent.ITEM_TRIGGERED and value.metadata.get("reason") == "ability_protected")
				check("shield item block notification " + row.case_id, notices.size() == 1 and notices[0].actor_id == &"actor" and notices[0].target_id == &"actor" and notices[0].metadata.get("item_id") == "ability_shield")
				var malformed: Dictionary = step.duplicate(true)
				malformed.snapshot.native.log.append("|-block|p1a: calvo_p1_0|item: Unknown Item")
				check("unknown block rejected " + row.case_id, not Adapter.project(before, malformed, active._moves, active._policy, active._species).ok)
			var state: BattleState = active._mirror(step)
			if state == null:
				results.append({"id": row.id, "family": row.family, "case_id": row.case_id, "status": "PENDING_GODOT_MIRROR", "step": step_index, "reason": active.last_error})
				supported = false; break
			for side: Dictionary in step.roster:
				for pokemon: Dictionary in side.pokemon:
					var creature := state.creature(StringName(pokemon.instance_id))
					var label: String = row.case_id + "/" + str(step_index) + "/" + pokemon.instance_id
					check("HP/item/status " + label, creature != null and creature.current_hp == int(pokemon.hp) and (creature.held_item_consumed or creature.held_item_id == &"") == String(pokemon.item).is_empty() and String(creature.status_state.persistent_id) == String(pokemon.status_id))
					if creature != null:
						if not String(pokemon.item).is_empty(): check("item identity " + label, Adapter.normalized(String(creature.held_item_id)) == String(pokemon.item) or String(active._items.get(String(pokemon.item), "")) == String(creature.held_item_id))
						for stat: String in STATS: check("stage " + label + "/" + stat, creature.stat_stages.get_stage(StringName(STATS[stat])) == int(pokemon.boosts.get(stat, 0)))
						check("PP slot count " + label, creature.moveset.size() == pokemon.moves.size())
						for slot_index: int in creature.moveset.size():
							var slot: BattleMoveSlot = creature.moveset[slot_index]
							var native_slot: Dictionary = pokemon.moves[slot_index]
							check("PP value " + label + "/" + str(slot_index), slot.current_pp == int(native_slot.pp) and slot.max_pp == int(native_slot.max_pp) and String(slot.move_id) == String(active._moves.get(String(native_slot.id), "")))
			before = step
		if not supported: continue
		# Replay every native scenario through the projection. One live worker per item
		# exercises IPC without restarting an OS process for every RNG/control variant.
		if live_ids.has(row.id) or String(preferred[row.id]) != String(row.case_id):
			results.append({"id": row.id, "family": row.family, "case_id": row.case_id, "status": "NATIVE_AND_GODOT_MIRROR_PASS", "live_ipc": false})
			if results.size() % 40 == 0: print("ITEM_EFFECT_GODOT_PROGRESS ", results.size(), "/", rows.size())
			continue
		live_ids[row.id] = true
		var player: Array[CreatureInstance] = []; var opponent: Array[CreatureInstance] = []
		for creature: Dictionary in row.origin.p1: player.append(CreatureInstance.from_dict(creature))
		for creature: Dictionary in row.origin.p2: opponent.append(CreatureInstance.from_dict(creature))
		var opened: bool = await active.open(self, player, opponent, [int(row.seed), 2, 3, 4])
		var good := check("IPC opens " + row.case_id, opened)
		if opened:
			for command: Dictionary in row.commands:
				good = check("IPC item action " + row.case_id, (await active._submit_choices(command)).accepted) and good
			good = check("IPC exact final hash " + row.case_id, active._checkpoint.state_hash == after.state_hash) and good
			good = check("no early input mutation " + row.case_id, player[0].to_dict() == CreatureInstance.from_dict(row.origin.p1[0]).to_dict()) and good
		await active.close()
		results.append({"id": row.id, "family": row.family, "case_id": row.case_id, "status": "NATIVE_AND_GODOT_SCENARIO_PASS" if good else "FAIL_LIVE_REPLAY", "live_ipc": true, "activated_rng_branch": activated.has(row.id)})
		if results.size() % 40 == 0: print("ITEM_EFFECT_GODOT_PROGRESS ", results.size(), "/", rows.size())
	_finish()


func _finish() -> void:
	if done: return
	done = true
	var pending := results.filter(func(row): return String(row.status).begins_with("PENDING_GODOT_")).size()
	var file := FileAccess.open(OUT + "godot.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"status": "PASS_WITH_EXPLICIT_PENDING" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors, "pending_protocol_cases": pending, "results": results}, "  ")); file.close()
	print("ITEM_EFFECT_GODOT_V3 ", "PASS" if errors.is_empty() else "FAIL", " checks=", checks, " cases=", results.size(), " pending=", pending)
	quit(0 if errors.is_empty() else 1)
