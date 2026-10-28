extends SceneTree

# Read-only broad integration audit. Uses the SAME mirror and event adapter as
# gameplay, offline in bounded batches rather than thousands of IPC round trips.
const Backend = preload("res://modules/battle/backends/showdown/showdown_backend.gd")
const Adapter = preload("res://modules/battle/backends/showdown/event_adapter.gd")
const OUT := "res://.godot/move_functional_audit/"
var catalog: DefinitionCatalog
var audit_dir := OUT


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	catalog = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	var args := OS.get_cmdline_user_args()
	if "--contexts" in args: audit_dir = "res://.godot/showdown_context_checks/"
	if not OS.get_environment("CALVO_AUDIT_OUT").is_empty(): audit_dir = OS.get_environment("CALVO_AUDIT_OUT").replace("\\", "/").trim_suffix("/") + "/"
	if "--export" in args:
		_export(); quit(); return
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(audit_dir + "manifest.json"))
	var backend := Backend.new(catalog)
	var output := FileAccess.open(audit_dir + "godot.jsonl", FileAccess.WRITE)
	var total := 0
	var blocked := 0
	for filename: String in manifest.batches:
		var rows: Array = JSON.parse_string(FileAccess.get_file_as_string(audit_dir + filename))
		for row: Dictionary in rows:
			backend.format_id = String(row.get("format", "gen9customgame"))
			backend._origin = row.origin
			var problems: Array = []
			var translated := 0
			var successful := 0
			var hp_events := 0
			var actor_actions := 0
			var before: Dictionary = row.before
			var source_copy := JSON.stringify(row.origin)
			var initial := backend._mirror(before)
			if initial == null: problems.append({"step": -1, "kind": "initial_mirror", "reason": backend.last_error})
			for i in row.steps.size():
				var after: Dictionary = row.steps[i]
				actor_actions += _actor_actions(before, after, String(row.id), backend._moves)
				var mirrored := backend._mirror(after)
				var events := Adapter.project(before, after, backend._moves, backend._policy, backend._species)
				if mirrored == null: problems.append({"step": i, "kind": "mirror", "reason": backend.last_error})
				if not events.ok: problems.append({"step": i, "kind": "protocol", "reason": events.unknown})
				if mirrored != null and events.ok:
					successful += 1
					for side: Dictionary in after.roster:
						for p: Dictionary in side.pokemon:
							var creature := mirrored.creature(StringName(p.instance_id))
							if creature == null or creature.current_hp != int(p.hp) or String(creature.status_state.persistent_id) != String(p.status_id): problems.append({"step": i, "kind": "state_mismatch", "reason": p.instance_id})
							elif creature.moveset.size() == p.moves.size():
								for slot in p.moves.size():
									if creature.moveset[slot].current_pp != int(p.moves[slot].pp): problems.append({"step": i, "kind": "pp_mismatch", "reason": p.instance_id})
					translated += events.events.size()
					for event: BattleEvent in events.events:
						if event.kind in [BattleEvent.DAMAGE_APPLIED, BattleEvent.STATUS_DAMAGE, BattleEvent.HP_RECOVERED]: hp_events += 1
				before = after
			if JSON.stringify(row.origin) != source_copy: problems.append({"kind": "source_mutation"})
			var result := {"case_id": row.case_id, "id": row.id, "seed": row.seed, "scenario": row.scenario, "issues": problems, "steps": row.steps.size(), "accepted_steps": successful, "events": translated, "hp_events": hp_events, "successful_actor_actions": actor_actions}
			output.store_line(JSON.stringify(result))
			total += 1
			if not problems.is_empty(): blocked += 1
		print("MOVE_AUDIT_GODOT batch=", filename, " cases=", total, " with_issues=", blocked)
		await process_frame
	output.close()
	print("MOVE_AUDIT_GODOT_COMPLETE cases=", total, " with_issues=", blocked)
	quit()


func _actor_actions(before: Dictionary, after: Dictionary, id: String, move_map: Dictionary) -> int:
	var count := 0
	var own_action := false
	var failed := false
	var log: Array = after.snapshot.native.log
	for i in range(before.snapshot.native.log.size(), log.size()):
		var line := String(log[i])
		if line.begins_with("|move|"):
			if own_action and not failed: count += 1
			var fields := line.split("|")
			own_action = fields.size() > 3 and String(fields[2]).contains("calvo_p1_0") and move_map.get(Adapter.normalized(String(fields[3])), "") == id
			failed = false
		elif own_action and (line.begins_with("|-fail|") or line.begins_with("|-miss|") or line.begins_with("|-immune|")):
			failed = true
	if own_action and not failed: count += 1
	return count


func _export() -> void:
	DirAccess.make_dir_recursive_absolute(audit_dir)
	var prototypes := {}
	for id: StringName in [&"mew", &"snorlax", &"ditto", &"charizard", &"gengar", &"pikachu", &"toxapex", &"morpeko", &"darkrai", &"hoopa"]:
		var rng := RandomNumberGenerator.new(); rng.seed = 41
		var ivs := {}
		for key: String in ["hp", "attack", "defense", "special_attack", "special_defense", "speed"]: ivs[key] = 31
		ivs["hp"] = 30 # Even HP for unambiguous independent half-HP fixtures.
		var creature := CreatureFactory.create(catalog.species(id), 50, catalog, ProgressionRuleset.new(), rng, {"instance_id": &"prototype", "moves": [&"tackle"], "nature_id": &"hardy", "ivs": ivs})
		creature.ability_id = &""
		prototypes[String(id)] = creature.to_dict()
	var file := FileAccess.open(audit_dir + "prototypes.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(prototypes)); file.close()
	print("MOVE_AUDIT_PROTOTYPES ", prototypes.size())
