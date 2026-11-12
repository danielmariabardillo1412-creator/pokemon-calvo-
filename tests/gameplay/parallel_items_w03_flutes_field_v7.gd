extends SceneTree
# W03 V7 staging integration: real field, real bag, real authored table, native world persistence.
# Map-ID lifetime is NOT certified by this test.
var checks := 0
var failures: Array[String] = []
const SAVE := "user://w03_flutes_field_v7.json"

func ck(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error("W03_FLUTE_FIELD_V7 FAIL " + label)

func _initialize() -> void:
	call_deferred("_run")

func _choose(bag: Control, id: StringName) -> bool:
	for i in bag._items.item_count:
		if String(bag._items.get_item_metadata(i)) == String(id):
			bag._items.select(i)
			bag._refresh_choices()
			return true
	return false

func _run() -> void:
	var scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	ck("demo booted", scene.is_demo_ready())
	if not scene.is_demo_ready():
		await _finish(scene)
		return
	scene.player.set_physics_process(false)
	var owner: PlayerCollection = scene.field_collection()
	var bag: Control = scene._item_bag
	var zone: StringName = scene.TECHNICAL_ZONE_ID
	var cave: StringName = scene.TECHNICAL_CAVE_ZONE_ID
	var grass_position: Vector2 = scene.get_node("EncounterZone").global_position
	var cave_position: Vector2 = scene.get_node("CaveEncounterZone").global_position
	ck("two authored physical zones", scene.zone_at_position(grass_position) == zone and scene.zone_at_position(cave_position) == cave)
	ck("two inventory additions", owner.inventory.add(&"black_flute", 1) and owner.inventory.add(&"white_flute", 1))
	var black_before: int = owner.inventory.quantity(&"black_flute")
	var white_before: int = owner.inventory.quantity(&"white_flute")
	ck("real bag opens", bag.open_bag())
	ck("real bag selects black", _choose(bag, &"black_flute"))
	ck("world use enabled without creature", not bag._use.disabled)
	var black_result: Dictionary = bag._apply("use")
	ck("black use accepted and not consumed", bool(black_result.get("accepted", false)) and not bool(black_result.get("consumed", true)) and owner.inventory.quantity(&"black_flute") == black_before)
	ck("black active on world", scene._flute_effect.active_id == &"black_flute")
	ck("real bag selects white", _choose(bag, &"white_flute"))
	var white_result: Dictionary = bag._apply("use")
	ck("white replaces black without spend", bool(white_result.get("accepted", false)) and scene._flute_effect.active_id == &"white_flute" and owner.inventory.quantity(&"white_flute") == white_before)
	bag.hide()
	await process_frame
	var table: WildEncounterTable = scene._director._tables[zone]
	var cave_table: WildEncounterTable = scene._director._tables[cave]
	var old_bp: int = table.encounter_chance_bp
	var old_cave_bp: int = cave_table.encounter_chance_bp
	var chance_expected: int = mini(10000, roundi(float(old_bp) * 1.5))
	ck("real authored grass chance copied, not mutated", scene._flute_effect.prepare_table(table, scene.FLUTE_PROFILE).encounter_chance_bp == chance_expected and table.encounter_chance_bp == old_bp)
	ck("real authored cave chance copied, not mutated", scene._flute_effect.prepare_table(cave_table, scene.FLUTE_PROFILE).encounter_chance_bp == mini(10000, roundi(float(old_cave_bp) * 1.5)) and cave_table.encounter_chance_bp == old_cave_bp)
	var saved: Dictionary = scene.field_native_world_snapshot("gen9calvounifiedv1")
	ck("flute saved with no map claim", saved.get("flute", {}).get("active_id", "") == "white_flute")
	ck("valid world accepted", bool(scene.field_validate_native_loaded_world(saved).get("ok", false)))
	var broken: Dictionary = saved.duplicate(true)
	broken["flute"] = {"schema_version": 1, "active_id": "red_flute"}
	ck("corrupt world rejected without mutation", not bool(scene.field_validate_native_loaded_world(broken).get("ok", false)) and scene._flute_effect.active_id == &"white_flute")
	var legacy: Dictionary = saved.duplicate(true)
	legacy.erase("flute")
	ck("legacy save accepted", bool(scene.field_validate_native_loaded_world(legacy).get("ok", false)))
	scene._native_battles.save_path = SAVE
	ck("manual SaveV2 commit", scene._native_battles.save_game())
	scene._flute_effect.clear()
	ck("manually cleared before load", scene._flute_effect.active_id == &"")
	ck("manual SaveV2 restore", await scene._native_battles.load_game() and scene._flute_effect.active_id == &"white_flute")
	owner = scene.field_collection()
	ck("stock survives SaveV2 without spending", owner.inventory.quantity(&"black_flute") == black_before and owner.inventory.quantity(&"white_flute") == white_before)
	ck("repel still exists", scene._repel_effect != null)
	ck("original tables still authored", scene._director._tables.has(zone) and scene._director._tables.has(cave))
	await _finish(scene)

func _finish(scene: Node) -> void:
	if scene != null:
		if scene._native_battles != null and scene._native_battles.view != null and scene._native_battles.view.session != null:
			await scene._native_battles.view.session.close()
		scene.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	if failures.is_empty():
		print("W03_FLUTE_FIELD_V7 PASS checks=%d bag=true savev2=true map_lifetime=false" % checks)
		quit(0)
	else:
		print("W03_FLUTE_FIELD_V7 FAIL checks=%d errors=%s" % [checks, JSON.stringify(failures)])
		quit(1)
