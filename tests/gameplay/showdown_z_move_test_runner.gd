extends SceneTree

const Backend = preload("res://modules/battle/backends/showdown/showdown_backend.gd")
const Session = preload("res://modules/gameplay/showdown_adventure_session.gd")
const Adapter = preload("res://modules/battle/backends/showdown/event_adapter.gd")
const OUT := "res://.godot/showdown_z_checks/"
var catalog: DefinitionCatalog
var checks := 0
var errors: Array[String] = []
var active: RefCounted
var done := false


func _initialize() -> void:
	call_deferred("_run")


func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		errors.append(label); push_error(label)
		if active != null: printerr(active.last_error)


func mon(id: String, species: String, moves: Array, item: String = "", level: int = 50) -> CreatureInstance:
	var rng := RandomNumberGenerator.new(); rng.seed = 8
	var c := CreatureFactory.create(catalog.species(StringName(species)), level, catalog, ProgressionRuleset.new(), rng, {"instance_id": StringName(id), "moves": moves, "nature_id": &"hardy"})
	c.ability_id = &""; c.held_item_id = StringName(item)
	return c


func _run() -> void:
	catalog = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	check("existing regional overlay valid", preload("res://modules/creatures/progression/pokemon_variant_catalog.gd").apply(catalog))
	var descriptors: Array = JSON.parse_string(FileAccess.get_file_as_string(OUT + "cases.json"))
	if "--export" in OS.get_cmdline_user_args():
		var prototypes := {"target": mon("target", "mew", ["reflect"], "", 100).to_dict()}
		for row: Dictionary in descriptors:
			if catalog.species(StringName(row.species)) != null:
				prototypes[row.id] = mon("actor", row.species, [row.base, "protect", "tackle"], row.item).to_dict()
		var f := FileAccess.open(OUT + "prototypes.json", FileAccess.WRITE)
		f.store_string(JSON.stringify(prototypes)); f.close()
		print("Z_PROTOTYPES ", prototypes.size()); quit(); return
	create_timer(180).timeout.connect(func():
		if not done:
			if active != null: active.stop_now()
			check("watchdog", false); _finish())
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUT + "manifest.json"))
	var output := FileAccess.open(OUT + "godot.jsonl", FileAccess.WRITE)
	active = Backend.new(catalog)
	for filename: String in manifest.batches:
		var rows: Array = JSON.parse_string(FileAccess.get_file_as_string(OUT + filename))
		for row: Dictionary in rows:
			if row.status != "PLAYABLE":
				output.store_line(JSON.stringify({"case_id": row.case_id, "id": row.id, "status": row.status})); continue
			active.format_id = row.format; active._origin = row.origin
			var before: BattleState = active._mirror(row.before)
			var after: BattleState = active._mirror(row.after)
			var translated := Adapter.project(row.before, row.after, active._moves, active._policy, active._species)
			var ok: bool = before != null and after != null and translated.ok
			if ok:
				ok = translated.events.any(func(e): return e.kind == BattleEvent.ACTION_USED and String(e.move_id) == row.id and e.actor_id == &"actor")
			check("Z projection " + row.case_id + " " + str(translated.unknown), ok)
			if after != null:
				for side: Dictionary in row.after.roster:
					for p: Dictionary in side.pokemon:
						var creature := after.creature(StringName(p.instance_id))
						check("Z HP and PP " + row.case_id + "/" + p.instance_id, creature.current_hp == int(p.hp) and creature.moveset[0].current_pp == int(p.moves[0].pp))
			output.store_line(JSON.stringify({"case_id": row.case_id, "id": row.id, "status": "PASS" if ok else "FAIL", "unknown": translated.unknown}))
		await process_frame
	output.close()
	for row: Dictionary in descriptors:
		if row.status != "PLAYABLE": continue
		active = Backend.new(catalog)
		var own := mon("actor", row.species, [row.base, "protect", "tackle"], row.item)
		var enemy := mon("target", "mew", ["reflect"], "", 100)
		var source := own.to_dict()
		check("live Z opens " + row.id, await active.open(self, [own] as Array[CreatureInstance], [enemy] as Array[CreatureInstance]))
		check("native offer maps " + row.id, active.z_move_id(0) == row.id)
		var result: Dictionary = await active.submit("move 1 zmove", active.revision)
		check("live Z resolves " + row.id, result.accepted and result.events.any(func(e): return e.kind == BattleEvent.ACTION_USED and String(e.move_id) == row.id))
		check("live Z preserves original collection " + row.id, own.to_dict() == source)
		check("used Z disappears " + row.id, active.z_move_id(0).is_empty())
		await active.close()
	await _boundaries()
	_finish()


func _boundaries() -> void:
	for row: Array in [["mew", "conversion", "normalium_z_held"], ["mew", "protect", "firium_z_held"], ["eevee", "last_resort", "eevium_z_held"], ["mew", "flamethrower", "waterium_z_held"], ["pikachu", "thunderbolt", "pikashunium_z_held"]]:
		active = Backend.new(catalog)
		check("negative Z fixture opens " + str(row), await active.open(self, [mon("actor", row[0], [row[1]], row[2])] as Array[CreatureInstance], [mon("target", "snorlax", ["reflect"])] as Array[CreatureInstance]))
		var before: Dictionary = active.snapshot()
		check("forbidden/unavailable Z rejected " + str(row), not (await active.submit("move 1 zmove", active.revision)).accepted and active.snapshot() == before and active.z_move_id(0).is_empty())
		if row[1] == "conversion":
			check("ordinary status remains usable", (await active.submit("move 1", active.revision)).accepted)
		await active.close()
	active = Backend.new(catalog)
	check("Z cannot be imported as learned move", not await active.open(self, [mon("actor", "mew", ["inferno_overdrive_special"])] as Array[CreatureInstance], [mon("target", "snorlax", ["reflect"])] as Array[CreatureInstance]) and active.last_error == "move_policy")
	await active.close()
	var player := PlayerCollection.new()
	var own := mon("owned", "mew", ["flamethrower", "tackle"], "firium_z_held")
	player.party.add_creature(own); player.party.add_creature(mon("reserve", "mew", ["surf"], "waterium_z_held")); player.inventory.add(&"master_ball", 1)
	active = Session.new(catalog, player)
	check("Z adventure opens", await active.begin_wild(self, mon("wild", "snorlax", ["reflect"], "", 100)))
	check("Z adventure resolves", (await active.submit("move 1 zmove", active.revision)).accepted)
	var saved: Dictionary = active.snapshot()
	var restored := Session.new(catalog, player)
	check("Z checkpoint preserves RNG and spent battle allowance", await restored.restore_saved(self, saved) and restored.snapshot() == saved and restored.z_move_id(0).is_empty())
	check("reloaded Z reuse rejected without mutation", not (await restored.submit("move 1 zmove", restored.revision)).accepted and restored.snapshot() == saved)
	await restored.close()
	check("reserve may enter", (await active.submit("switch 2", active.revision)).accepted)
	check("second crystal shares spent Z allowance", active.z_move_id(0).is_empty() and not (await active.submit("move 1 zmove", active.revision)).accepted)
	check("capture settles paid base PP and retains crystal", (await active.capture(&"master_ball", active.revision)).accepted and own.moveset[0].current_pp == own.moveset[0].max_pp - 1 and own.held_item_id == &"firium_z_held" and not own.held_item_consumed)
	await active.close()


func _finish() -> void:
	if done: return
	done = true
	var f := FileAccess.open(OUT + "gameplay.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors}, "  ")); f.close()
	print("SHOWDOWN_Z_MOVES ", "PASS" if errors.is_empty() else "FAIL", " checks=", checks, " errors=", errors.size())
	quit(0 if errors.is_empty() else 1)
