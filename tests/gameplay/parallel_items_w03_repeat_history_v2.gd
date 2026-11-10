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
	DirAccess.remove_absolute(ProjectSettings.globalize_path(filename))
	# Pinned baseline result, not a promise about native Showdown capture which remains protected.
	done = true
	if errors.is_empty():
		print("W03_REPEAT_V2_GODOT PASS checks=" + str(checks) + " native_capture_l3=false")
		quit(0)
	else:
		print("W03_REPEAT_V2_GODOT FAIL checks=" + str(checks) + " errors=" + JSON.stringify(errors))
		quit(1)
