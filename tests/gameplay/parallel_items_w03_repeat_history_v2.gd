extends "res://tests/gameplay/item_capture_v11.gd"
## W03 AUTORUN V2 real adventure success-routing, persistent ledger, native save and Repeat Ball.
const History = preload("res://modules/capture/caught_species_history_w03.gd")
func _initialize() -> void:
	call_deferred("_run_history")

func _run_history() -> void:
	var source: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))
	catalogs = GameData.from_dict(source).to_definition_catalog()
	check("canonical catalog available", catalogs.species(&"caterpie") != null)
	var owner := PlayerCollection.new()
	owner.party.add_creature(_mon(&"bulbasaur", 50, &"w03_leader"))
	check("stock master", owner.inventory.add(&"master_ball", 2))
	check("stock repeat", owner.inventory.add(&"repeat_ball", 2))
	check("history initially empty, not inferred from party", owner.caught_base_species_ids.is_empty()
		and not owner.has_previously_caught(&"bulbasaur", catalogs))
	check("helper valid base species", History.canonical_id(&"caterpie", catalogs) == &"caterpie")
	var table := WildEncounterTable.new(&"history_route", 10000)
	check("real encounter table", table.add_slot(WildEncounterSlot.new(&"single", &"caterpie", 1, 8, 8)))
	var session := WildAdventureSession.new(owner, catalogs, ProgressionRuleset.new())
	var encounter_rng := RandomNumberGenerator.new()
	encounter_rng.seed = 1102
	var encountered := session.begin_encounter(table, encounter_rng, 5501)
	check("real encounter first", encountered.status == WildEncounterResult.ENCOUNTER
		and session.has_active_battle())
	var capture_rng := RandomNumberGenerator.new()
	capture_rng.seed = 99
	var first := session.capture_current(&"master_ball", capture_rng)
	check("first capture routed and successful", first.resolution != null
		and first.resolution.result.status == CaptureResult.SUCCESS
		and first.routing != null and first.routing.routed and first.session_completed)
	check("ledger exactly one base and party-owned", owner.caught_base_species_ids == [&"caterpie"]
		and owner.has_previously_caught(&"caterpie", catalogs) and owner.party.size() == 2)
	check("successful capture spends one master", owner.inventory.quantity(&"master_ball") == 1)
	check("duplicate record idempotent", owner.record_successful_capture(&"caterpie", catalogs)
		and owner.caught_base_species_ids.size() == 1)
	var filename := "user://w03_history_repeat_test.json"
	check("manual adventure save", session.save_game(filename).ok)
	var old_owner := owner
	var loaded := session.load_game(filename)
	check("adventure reloaded ledger", loaded.ok
		and session.player != old_owner
		and session.player.caught_base_species_ids == [&"caterpie"]
		and session.player.inventory.quantity(&"repeat_ball") == 2)
	check("other species does not trigger bonus", not session.player.has_previously_caught(&"pikachu", catalogs))
	var ctx := CaptureBattleContext.new()
	ctx.previously_caught_base_species = session.player.has_previously_caught(&"caterpie", catalogs)
	var target := _mon(&"caterpie", 8, &"w03_second_target")
	var species: CreatureSpecies = catalogs.species(&"caterpie")
	check("repeat bonus from true ledger", CaptureRuleset.new().is_known_ball(&"repeat_ball")
		and is_equal_approx(CaptureRuleset.ContextBallEffects.multiplier(&"repeat_ball", target, species, ctx), 3.5))
	ctx.previously_caught_base_species = session.player.has_previously_caught(&"pikachu", catalogs)
	check("different species neutral bonus", is_equal_approx(
		CaptureRuleset.ContextBallEffects.multiplier(&"repeat_ball", target, species, ctx), 1.0))
	var second_rng := RandomNumberGenerator.new()
	second_rng.seed = 1103
	var second_encounter := session.begin_encounter(table, second_rng, 5502)
	check("second live encounter", second_encounter.status == WildEncounterResult.ENCOUNTER
		and session.has_active_battle())
	var current := session.current_wild()
	var second_context := CaptureBattleContext.new()
	second_context.previously_caught_base_species = session.player.has_previously_caught(current.base_species_id(), catalogs)
	check("live context ledger before attempt", second_context.previously_caught_base_species)
	var attempt_rng := RandomNumberGenerator.new()
	attempt_rng.seed = 111
	var second := session.capture_current(&"repeat_ball", attempt_rng)
	check("repeat processed through real battle and spent", second.resolution != null
		and second.resolution.result.status == CaptureResult.SUCCESS
		and second.resolution.result.probability > 0.0
		and session.player.inventory.quantity(&"repeat_ball") == 1
		and session.player.caught_base_species_ids == [&"caterpie"])
	var legacy := SaveGameData.build(session.player.party, session.player.storage, session.player.inventory).to_dict()
	legacy.erase("caught_base_species_ids")
	var old_load := SaveGameRepository.new().decode_snapshot(legacy)
	check("legacy absent ledger accepted empty", old_load.ok and old_load.caught_base_species_ids.is_empty())
	var bad := legacy.duplicate(true)
	bad["caught_base_species_ids"] = {"schema_version": 1, "ids": ["caterpie", "caterpie"]}
	var bad_load := SaveGameRepository.new().decode_snapshot(bad)
	check("duplicate caught ids rejected before publishing", not bad_load.ok
		and bad_load.party == null and bad_load.inventory == null)
	bad["caught_base_species_ids"] = {"schema_version": 1, "ids": [false]}
	check("invalid shape rejected", not SaveGameRepository.new().decode_snapshot(bad).ok)
	# Negative: a real unsuccessful battle capture consumes its ball but never appends ledger.
	var failed_owner := PlayerCollection.new()
	failed_owner.party.add_creature(_mon(&"bulbasaur", 50, &"w03_failure_leader"))
	check("stock low-chance ball", failed_owner.inventory.add(&"poke_ball", 2))
	var mewtwo_table := WildEncounterTable.new(&"history_failure", 10000)
	check("low-rate real encounter table", mewtwo_table.add_slot(
		WildEncounterSlot.new(&"mewtwo_single", &"mewtwo", 1, 8, 8)))
	var failed_session := WildAdventureSession.new(failed_owner, catalogs, ProgressionRuleset.new())
	var failure_enc_rng := RandomNumberGenerator.new()
	failure_enc_rng.seed = 2191
	check("failed-path encounter started", failed_session.begin_encounter(
		mewtwo_table, failure_enc_rng, 5555).status == WildEncounterResult.ENCOUNTER)
	var fail_rng := RandomNumberGenerator.new()
	fail_rng.seed = 6413
	var fail_probe := RandomNumberGenerator.new()
	fail_probe.seed = 6413
	check("failure seed is above maximum low-rate threshold", fail_probe.randf() > 0.05)
	var failed_capture := failed_session.capture_current(&"poke_ball", fail_rng)
	check("actual failed capture has no ledger entry", failed_capture.resolution != null
		and failed_capture.resolution.result.status == CaptureResult.FAILED
		and failed_owner.caught_base_species_ids.is_empty()
		and failed_owner.inventory.quantity(&"poke_ball") == 1)
	var bag_before := session.player.inventory.quantity(&"repeat_ball")
	var extra_capture := session.capture_current(&"repeat_ball", attempt_rng)
	check("cannot double capture a closed encounter", extra_capture.resolution == null
		and session.player.inventory.quantity(&"repeat_ball") == bag_before
		and session.player.caught_base_species_ids == [&"caterpie"])

	# The native save owns a different battle transport, but must still preserve the player ledger.
	var scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	check("native field demo ready", scene.is_demo_ready())
	if scene.is_demo_ready():
		var native_owner: PlayerCollection = scene.field_collection()
		check("native owner records base after real capture ledger import",
			native_owner.record_successful_capture(&"caterpie", catalogs))
		var native_path := "user://w03_repeat_ledger_native.json"
		scene._native_battles.save_path = native_path
		check("native world manual save includes ledger", scene._native_battles.save_game())
		var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(native_path))
		check("embedded native collection has the original ledger",
			envelope.payload.collection.get("caught_base_species_ids", {}).get("ids", []) == ["caterpie"])
		check("native manual reload retains caught ledger", await scene._native_battles.load_game()
			and scene.field_collection().caught_base_species_ids == [&"caterpie"])
		var legacy_envelope := envelope.duplicate(true)
		legacy_envelope.payload.collection.erase("caught_base_species_ids")
		legacy_envelope["sha256"] = JSON.stringify(legacy_envelope.payload).sha256_text()
		var out := FileAccess.open(native_path, FileAccess.WRITE)
		check("write native legacy fixture", out != null)
		if out != null:
			out.store_string(JSON.stringify(legacy_envelope))
			out.close()
			check("native legacy load restores empty caught ledger",
				await scene._native_battles.load_game()
				and scene.field_collection().caught_base_species_ids.is_empty())
		var corrupt := envelope.duplicate(true)
		corrupt.payload.collection["caught_base_species_ids"] = {
			"schema_version": 1, "ids": ["not_a_real_pokemon"]}
		corrupt["sha256"] = JSON.stringify(corrupt.payload).sha256_text()
		out = FileAccess.open(native_path, FileAccess.WRITE)
		check("write corrupt native ledger fixture", out != null)
		if out != null:
			out.store_string(JSON.stringify(corrupt))
			out.close()
			var preserved_owner: PlayerCollection = scene.field_collection()
			var preserved_world: Vector2 = scene.player.global_position
			check("native corrupted ledger rejects before state publication",
				not await scene._native_battles.load_game()
				and is_same(scene.field_collection(), preserved_owner)
				and scene.player.global_position.is_equal_approx(preserved_world))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(native_path))
	scene.queue_free()
	await process_frame

	DirAccess.remove_absolute(ProjectSettings.globalize_path(filename))
	# Pinned baseline result, not a promise about native Showdown capture which remains protected.
	done = true
	if errors.is_empty():
		print("W03_REPEAT_V2_GODOT PASS checks=" + str(checks) + " native_capture_l3=false")
		quit(0)
	else:
		print("W03_REPEAT_V2_GODOT FAIL checks=" + str(checks) + " errors=" + JSON.stringify(errors))
		quit(1)
