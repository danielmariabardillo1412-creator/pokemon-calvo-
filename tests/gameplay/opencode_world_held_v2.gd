extends "res://tests/gameplay/showdown_adventure_test_runner.gd"

# O120 batch runner: Smoke Ball at the real Run boundary, the validated
# encounter-rate copy for Cleanse Tag/Pure Incense, and the real map scene.
const OUT_HELD := "res://.godot/opencode_world_held_v2/"
const Modifiers = preload("res://modules/gameplay/encounter_item_modifiers.gd")
const HeldRule = preload("res://modules/gameplay/held_escape_items.gd")
const FieldService = preload("res://modules/inventory/field_item_service.gd")
var capture := false
var scene: Node2D


func _initialize() -> void:
	capture = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	call_deferred("_run")
	create_timer(420).timeout.connect(func():
		if not done:
			if active != null: active.stop_now()
			push_error("OPENCODE_WORLD_HELD_V2 timeout"); quit(2))


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_HELD)
	catalogs = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	pure_rules()
	if not capture:
		await smoke_ball_cases()
		await smoke_ball_suppression()
		await smoke_ball_boundaries()
		await encounter_copy_cases()
	await map_smoke_ball()
	await map_encounter_modifiers()
	var report := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors, "gpu": capture}
	var file := FileAccess.open(OUT_HELD + ("gpu.json" if capture else "godot.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ")); file.close()
	print("OPENCODE_WORLD_HELD_V2 ", report.status, " checks=", checks, " GPU=", capture)
	done = true; quit(0 if errors.is_empty() else 1)


func pure_rules() -> void:
	check("only cleanse tag and pure incense modify the rate", Modifiers.supports(&"cleanse_tag") and Modifiers.supports(&"pure_incense") and not Modifiers.supports(&"smoke_ball") and not Modifiers.supports(&"amulet_coin"))
	check("disabled tables stay disabled", Modifiers.modified_chance_bp(0) == 0)
	check("full tables become two thirds", Modifiers.modified_chance_bp(10000) == 6667)
	check("rounding keeps a positive chance", Modifiers.modified_chance_bp(1) == 1 and Modifiers.modified_chance_bp(2) == 1 and Modifiers.modified_chance_bp(3) == 2 and Modifiers.modified_chance_bp(100) == 67)
	var leader: CreatureInstance = creature("rule_leader")
	check("leader item without a party is empty", Modifiers.leader_item([]) == &"")
	check("leader item reads the first member", Modifiers.leader_item([leader]) == &"")
	leader.held_item_id = &"cleanse_tag"
	check("leader item with the tag", Modifiers.leader_item([leader]) == &"cleanse_tag")
	leader.held_item_consumed = true
	check("consumed leader item is not active", Modifiers.leader_item([leader]) == &"")
	var table := WildEncounterTable.new(&"unit_zone", 10000)
	table.add_slot(WildEncounterSlot.new(&"slot_a", &"pidgey", 3, 2, 4))
	leader.held_item_consumed = false
	var prepared := Modifiers.prepare_table(table, [leader])
	check("prepared copy is a distinct validated object", prepared != table and prepared.validate(catalogs).ok and prepared.encounter_chance_bp == 6667 and table.encounter_chance_bp == 10000)
	var untouched := Modifiers.prepare_table(table, [])
	check("no item returns the original table object", untouched == table)
	var consumed_leader: CreatureInstance = creature("rule_consumed")
	consumed_leader.held_item_id = &"pure_incense"; consumed_leader.held_item_consumed = true
	check("consumed incense returns the original", Modifiers.prepare_table(table, [consumed_leader]) == table)
	check("held escape rule only accepts the active smoke ball", HeldRule.guaranteed(&"smoke_ball", true) and not HeldRule.guaranteed(&"smoke_ball", false) and not HeldRule.guaranteed(&"oran_berry", true))


func escape_failure_seed(odds: int) -> int:
	for candidate in 5000:
		var probe := RandomNumberGenerator.new(); probe.seed = candidate + 1
		if probe.randi_range(0, WildEscapeRuleset.ROLL_MAX) >= odds: return candidate + 1
	return 0


func smoke_ball_cases() -> void:
	var player := collection()
	var leader: CreatureInstance = player.party.get_creature(&"own_0")
	leader.held_item_id = &"smoke_ball"; leader.held_item_consumed = false
	player.inventory.add(&"smoke_ball", 1)
	active = Session.new(catalogs, player, "gen9calvounifiedv1")
	check("smoke ball wild opens", await active.begin_wild(self, creature("smoke_enemy", "mew", 100, [&"mean_look"])))
	check("native reports the real active held item", active._checkpoint.roster[0].pokemon[0].held_item_active and active._checkpoint.roster[0].pokemon[0].item == "smokeball")
	var before: Dictionary = active.snapshot()
	var result: Dictionary = await active.flee(active.revision)
	check("smoke ball guarantees the escape", result.accepted and active.completion_reason == "FLED" and result.get("smoke_ball", false))
	check("smoke ball consumes no RNG or attempt", active.snapshot().adventure.escape_rng == before.adventure.escape_rng and active.snapshot().adventure.capture_rng == before.adventure.capture_rng and active.escape_attempts == 0 and result.escape_resolution.rng_consumed == false)
	check("smoke ball runs no native turn", active.snapshot().native == before.native and result.events.is_empty())
	check("smoke ball is not consumed", player.party.get_creature(&"own_0").held_item_id == &"smoke_ball" and not player.party.get_creature(&"own_0").held_item_consumed and player.inventory.quantity(&"smoke_ball") == 1)
	await active.close()
	# Trapped by Mean Look: the guarantee still happens before trapping.
	player = collection()
	player.party.get_creature(&"own_0").held_item_id = &"smoke_ball"
	active = Session.new(catalogs, player, "gen9calvounifiedv1")
	check("trapped smoke fixture opens", await active.begin_wild(self, creature("smoke_trap_enemy", "mew", 100, [&"mean_look"])))
	check("real native trapping turn", (await active.submit("move 1", active.revision)).accepted and active._checkpoint.roster[0].pokemon[0].trapped)
	check("smoke ball escapes while trapped", (await active.flee(active.revision)).accepted and active.completion_reason == "FLED")
	await active.close()


func smoke_ball_suppression() -> void:
	# Consumed through a real Fling: the next Run is the ordinary rule.
	var player := collection()
	var leader: CreatureInstance = player.party.get_creature(&"own_0")
	leader.held_item_id = &"smoke_ball"
	leader.current_hp = 150
	_configure_moves(leader, [&"fling", &"tackle"])
	var wild := creature("smoke_fling_enemy", "mew", 100, [&"tackle"])
	wild.current_hp = 200
	active = Session.new(catalogs, player, "gen9calvounifiedv1")
	check("fling fixture opens", await active.begin_wild(self, wild))
	check("fling consumes the smoke ball", (await active.submit("move 1", active.revision)).accepted and not active._checkpoint.roster[0].pokemon[0].held_item_active and active._checkpoint.roster[0].pokemon[0].item == "")
	var speeds := _speeds()
	var odds := WildEscapeRuleset.new().odds(speeds.x, speeds.y, 1)
	var working := escape_failure_seed(odds)
	active._escape_rng.seed = working
	var result: Dictionary = await active.flee(active.revision)
	check("consumed smoke ball falls back to the ordinary rule", not result.get("smoke_ball", false) and active.escape_attempts == 1 and active.has_active_battle())
	await active.close()
	# Held only in the bag: no guarantee at all.
	player = collection(); player.inventory.add(&"smoke_ball", 3)
	active = Session.new(catalogs, player, "gen9calvounifiedv1")
	check("bag-only fixture opens", await active.begin_wild(self, creature("smoke_bag_enemy", "mew", 100, [&"tackle"])))
	var bag_result: Dictionary = await active.flee(active.revision)
	check("bag-only smoke ball never guarantees", not bag_result.get("smoke_ball", false) and active.escape_attempts == 1 and player.inventory.quantity(&"smoke_ball") == 3)
	await active.close()


func _speeds() -> Vector2i:
	var own: CreatureInstance = active.battle_state().active_for_side(&"side_a")
	var wild: CreatureInstance = active.battle_state().active_for_side(&"side_b")
	return Vector2i(own.stats.speed, wild.stats.speed)


func _configure_moves(own: CreatureInstance, moves: Array) -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = 14
	var prepared := CreatureFactory.create(catalogs.species(own.species_id), own.level, catalogs, ProgressionRuleset.new(), rng, {"instance_id": own.instance_id, "moves": moves})
	own.moveset = prepared.moveset
	own.move_ids = prepared.move_ids


func smoke_ball_boundaries() -> void:
	var player := collection()
	player.party.get_creature(&"own_0").held_item_id = &"smoke_ball"
	active = Session.new(catalogs, player)
	check("trainer smoke fixture opens", await active.begin_trainer(self, &"route_smoke_trainer", [creature("smoke_trainer_enemy")] as Array[CreatureInstance]))
	var before: Dictionary = active.snapshot()
	check("trainer Run is rejected with the held smoke ball", not (await active.flee(active.revision)).accepted and active.snapshot() == before and active.has_active_battle())
	await active.close()
	# Save/load keeps the real activity and the guarantee after restore.
	player = collection()
	player.party.get_creature(&"own_0").held_item_id = &"smoke_ball"
	player.inventory.add(&"smoke_ball", 1)
	active = Session.new(catalogs, player, "gen9calvounifiedv1")
	check("smoke reload fixture opens", await active.begin_wild(self, creature("smoke_reload_enemy", "mew", 100, [&"tackle"])))
	var saved: Dictionary = active.snapshot()
	await active.close()
	active = Session.new(catalogs, player, "gen9calvounifiedv1")
	check("smoke snapshot restores", await active.restore_saved(self, saved))
	check("restored activity is real", active._checkpoint.roster[0].pokemon[0].held_item_active)
	check("restored smoke ball still guarantees", (await active.flee(active.revision)).accepted and active.completion_reason == "FLED" and player.party.get_creature(&"own_0").held_item_id == &"smoke_ball")
	await active.close()


func encounter_copy_cases() -> void:
	var base := WildEncounterTable.new(&"copy_zone", 10000)
	base.add_slot(WildEncounterSlot.new(&"slot_a", &"pidgey", 3, 2, 4))
	base.add_slot(WildEncounterSlot.new(&"slot_b", &"rattata", 1, 2, 4))
	var leader: CreatureInstance = creature("copy_leader")
	leader.held_item_id = &"cleanse_tag"
	var prepared := Modifiers.prepare_table(base, [leader])
	# Same seed without an item must be byte-identical; with the item the rate is
	# legitimately different, and the authored table never moves.
	var rng_a := RandomNumberGenerator.new(); rng_a.seed = 4242
	var rng_b := RandomNumberGenerator.new(); rng_b.seed = 4242
	var plain := WildEncounterSystem.resolve(base, rng_a, catalogs)
	var no_item := WildEncounterSystem.resolve(Modifiers.prepare_table(base, []), rng_b, catalogs)
	check("no-item resolution and RNG state are identical", plain.status == no_item.status and plain.reason == no_item.reason and rng_a.state == rng_b.state)
	var base_before := base.to_dict()
	var misses := 0
	for seed in 40:
		var probe := RandomNumberGenerator.new(); probe.seed = seed + 1
		var modified := WildEncounterSystem.resolve(prepared, probe, catalogs)
		if modified.status == WildEncounterResult.NONE: misses += 1
	check("modified copy can miss where the authored table cannot", misses > 0 and base.to_dict() == base_before)
	check("copy keeps the slots and only the rate changed", prepared.slots.size() == base.slots.size() and prepared.encounter_chance_bp == 6667)


func select_bag_item(bag: Control, id: StringName) -> bool:
	for i: int in bag._items.item_count:
		if String(bag._items.get_item_metadata(i)) == String(id):
			bag._items.select(i)
			bag._refresh_choices()
			return true
	return false


func map_smoke_ball() -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate(); root.add_child(scene)
	await process_frame; await physics_frame
	var config: Dictionary = scene._active_config.duplicate(true); config.encounter_chance_percent = 100
	scene._on_configuration_applied(config)
	var owner: PlayerCollection = scene.field_collection()
	owner.inventory.add(&"smoke_ball", 1)
	check("map bag opens for smoke ball", scene.toggle_item_bag())
	var bag: Control = scene._item_bag
	check("map bag selects the smoke ball", select_bag_item(bag, &"smoke_ball"))
	if capture:
		await process_frame; await process_frame; await RenderingServer.frame_post_draw
		check("GPU field bag capture", root.get_texture().get_image().save_png(OUT_HELD + "smoke_ball_bag.png") == OK)
	check("map equip uses the field service", bag._apply("equip").accepted)
	bag.hide(); await process_frame
	var leader: CreatureInstance = scene._session.player.party.get_creatures()[0]
	check("map leader really holds the smoke ball", leader.held_item_id == &"smoke_ball" and owner.inventory.quantity(&"smoke_ball") == 0)
	if capture:
		await process_frame; await process_frame; await RenderingServer.frame_post_draw
		check("GPU bag capture", root.get_texture().get_image().save_png(OUT_HELD + "smoke_ball_equipped.png") == OK)
	var bridge = scene._native_battles; bridge.save_path = OUT_HELD + ("gpu_" if capture else "headless_") + "smoke_ball.json"
	check("map save before encounter", bridge.save_game())
	scene.player.global_position = Vector2(420, 150); await scene._on_player_step_completed(scene.player.global_position)
	var view: Control = bridge.view; view._playback.set_process(false)
	check("map smoke encounter opened", view.session != null and view.session.has_active_battle())
	check("map native activity is real", view.session._checkpoint.roster[0].pokemon[0].held_item_active)
	var result: Dictionary = await view.adventure_command("flee")
	check("map Run flees with the real smoke ball " + JSON.stringify(result), result.accepted and view.session.completion_reason == "FLED" and result.get("smoke_ball", false))
	check("map smoke ball spends no RNG and keeps the item", view.session.escape_attempts == 0 and scene.field_collection().party.get_creatures()[0].held_item_id == &"smoke_ball" and scene.field_collection().inventory.quantity(&"smoke_ball") == 0)
	for i: int in 2000:
		if not view._playback.is_playing(): break
		view._playback.advance(0.25)
	await process_frame
	await bridge.leave_battle()
	check("map returns after the smoke escape", not bridge.busy and not view.visible)
	check("map final save", bridge.save_game())
	check("map final load", await bridge.load_game())
	check("equipped smoke ball persists", scene.field_collection().party.get_creatures()[0].held_item_id == &"smoke_ball")
	scene.queue_free(); await process_frame


func map_encounter_modifiers() -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate(); root.add_child(scene)
	await process_frame; await physics_frame
	var config: Dictionary = scene._active_config.duplicate(true); config.encounter_chance_percent = 100
	scene._on_configuration_applied(config)
	var zone: StringName = scene.zone_at_position(Vector2(420, 150))
	check("grass zone is registered", zone != &"" and scene._director.has_zone(zone))
	var table: WildEncounterTable = scene._director._tables.get(zone)
	var authored: Dictionary = table.to_dict()
	var baseline_misses := 0
	for seed in 24:
		scene._director._encounter_rng.seed = 500000 + seed
		var prepared: Dictionary = scene.field_prepare_native_encounter(zone)
		if prepared.result.status == WildEncounterResult.NONE: baseline_misses += 1
	check("authored full-chance table never misses", baseline_misses == 0)
	check("authored table and director slot untouched", table.to_dict() == authored and scene._director._tables.get(zone) == table)
	var leader: CreatureInstance = scene._session.player.party.get_creatures()[0]
	leader.held_item_id = &"pure_incense"; leader.held_item_consumed = false
	var modified_misses := 0
	var first_miss_seed := 0
	for seed in 24:
		scene._director._encounter_rng.seed = 500000 + seed
		var prepared: Dictionary = scene.field_prepare_native_encounter(zone)
		if prepared.result.status == WildEncounterResult.NONE:
			modified_misses += 1
			if first_miss_seed == 0: first_miss_seed = 500000 + seed
	check("held pure incense really lowers the map rate", modified_misses > 0)
	check("director still keeps the authored rate", scene._director._tables.get(zone).encounter_chance_bp == authored.encounter_chance_bp and scene._director._tables.get(zone) == table)
	scene._director._encounter_rng.seed = first_miss_seed
	var first: Dictionary = scene.field_prepare_native_encounter(zone)
	scene._director._encounter_rng.seed = first_miss_seed
	var second: Dictionary = scene.field_prepare_native_encounter(zone)
	check("same state and context is reproducible", first.result.status == second.result.status and first.next_rng == second.next_rng)
	leader.held_item_consumed = true
	scene._director._encounter_rng.seed = first_miss_seed
	var consumed: Dictionary = scene.field_prepare_native_encounter(zone)
	check("consumed item restores the authored rate", consumed.result.status == WildEncounterResult.ENCOUNTER and first.result.status == WildEncounterResult.NONE)
	leader.held_item_consumed = false
	# A reserve holding the item never counts; only the first party member does.
	leader.held_item_id = &""; leader.held_item_consumed = false
	if scene._session.player.party.size() > 1:
		var reserve: CreatureInstance = scene._session.player.party.get_creatures()[1]
		reserve.held_item_id = &"cleanse_tag"; reserve.held_item_consumed = false
		scene._director._encounter_rng.seed = first_miss_seed
		check("reserve item does not modify the rate", scene.field_prepare_native_encounter(zone).result.status == WildEncounterResult.ENCOUNTER)
		reserve.held_item_id = &""
	scene.queue_free(); await process_frame
