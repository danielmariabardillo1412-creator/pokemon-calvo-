extends SceneTree

const Backend = preload("res://modules/battle/backends/showdown/showdown_backend.gd")
const Adapter = preload("res://modules/battle/backends/showdown/event_adapter.gd")
const Adventure = preload("res://modules/gameplay/showdown_adventure_session.gd")
const FORMAT := "gen9calvounifiedv1"
const OUT := "res://.godot/item_audit_v1/"
var catalog: DefinitionCatalog
var checks := 0
var errors: Array[String] = []
var projections: Array = []
var active: RefCounted
var done := false


func _initialize() -> void: call_deferred("_run")


func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok: errors.append(label); push_error(label); printerr(active.last_error if active != null else "")


func _run() -> void:
	create_timer(240).timeout.connect(func():
		if not done:
			if active != null: active.stop_now()
			check("watchdog", false); _finish())
	catalog = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string(OUT + "held_cases.json"))
	active = Backend.new(catalog, FORMAT)
	for row: Dictionary in rows:
		active._origin = row.origin
		var before: Dictionary = row.before
		var unknown: Array = []
		var mirrored := true
		check("initial held-item mirror " + row.case_id, active._mirror(before) != null)
		for after: Dictionary in row.steps:
			var state: BattleState = active._mirror(after)
			var result := Adapter.project(before, after, active._moves, active._policy, active._species)
			unknown.append_array(result.unknown); mirrored = mirrored and state != null
			check("item projection " + row.case_id + " " + str(result.unknown), result.ok and state != null)
			if state != null:
				for side: Dictionary in after.roster:
					for p: Dictionary in side.pokemon:
						var c := state.creature(StringName(p.instance_id))
						check("exact HP and item " + row.case_id + "/" + p.instance_id, c.current_hp == int(p.hp) and (c.held_item_consumed or c.held_item_id == &"") == String(p.item).is_empty())
			before = after
		projections.append({"id": row.id, "case_id": row.case_id, "mirror_ok": mirrored, "unknown": unknown})
	var output := FileAccess.open(OUT + "held_projection.json", FileAccess.WRITE); output.store_string(JSON.stringify(projections)); output.close()
	# Do not spend turns or publish unsupported protocol changes in the real IPC path.
	if errors.is_empty():
		for row: Dictionary in rows:
			var a: Array[CreatureInstance] = []; var b: Array[CreatureInstance] = []
			for c: Dictionary in row.origin.p1: a.append(CreatureInstance.from_dict(c))
			for c: Dictionary in row.origin.p2: b.append(CreatureInstance.from_dict(c))
			active = Backend.new(catalog, FORMAT)
			check("live held fixture opens " + row.case_id, await active.open(self, a, b, [int(row.seed), 2, 3, 4]))
			for command: Dictionary in row.commands:
				check("live item action " + row.case_id, (await active._submit_choices(command)).accepted)
			check("live native hash " + row.case_id, active._checkpoint.state_hash == row.steps[-1].state_hash)
			check("input collection not mutated " + row.case_id, a[0].to_dict() == CreatureInstance.from_dict(row.origin.p1[0]).to_dict())
			await active.close()
		await _settlement(rows)
	_finish()


func _settlement(rows: Array) -> void:
	var row: Dictionary = rows.filter(func(r): return r.id == "sitrus_berry" and r.seed == 1)[0]
	var player := PlayerCollection.new()
	var source := CreatureInstance.from_dict(row.origin.p1[0])
	player.party.add_creature(source); player.inventory.add(&"master_ball", 1)
	var original := source.to_dict()
	var foe := CreatureInstance.from_dict(row.origin.p2[0])
	active = Adventure.new(catalog, player, FORMAT)
	check("owned berry battle opens", await active.begin_wild(self, foe, [1, 2, 3, 4]))
	check("native initial berry is consumed without early campaign write", active.battle_state().creature(&"actor").held_item_consumed and source.to_dict() == original)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(active.snapshot()))
	var saved_native_hash: String = JSON.stringify(saved.native).sha256_text()
	await active.close()
	var restored := Adventure.new(catalog, player, FORMAT)
	var loaded: bool = await restored.restore_saved(self, saved)
	# JSON numbers are floats in Godot; compare the same serialized domain and
	# canonical native JSON, not dictionary numeric tags or insertion-order hashes.
	var restored_data: Dictionary = JSON.parse_string(JSON.stringify(restored.snapshot())) if loaded else {}
	check("consumed-item checkpoint preserves complete JSON state", loaded and restored_data == saved and JSON.stringify(restored_data.native).sha256_text() == saved_native_hash)
	active = restored
	check("capture settles consumed held item", (await active.capture(&"master_ball", active.revision)).accepted and source.held_item_consumed and source.held_item_id == &"sitrus_berry" and source.current_hp > int(original.current_hp))
	var published := player.party.to_dict()
	check("repeat action cannot duplicate consumption or capture", not (await active.capture(&"master_ball", active.revision)).accepted and player.party.to_dict() == published and player.inventory.quantity(&"master_ball") == 0)
	await active.close()


func _finish() -> void:
	if done: return
	done = true
	var output := FileAccess.open(OUT + "held_godot.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors}, "  ")); output.close()
	print("HELD_PILOT_GODOT ", "PASS" if errors.is_empty() else "FAIL", " checks=", checks, " errors=", errors.size()); quit(0 if errors.is_empty() else 1)
