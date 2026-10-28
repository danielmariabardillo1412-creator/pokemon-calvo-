extends SceneTree

const Variants = preload("res://modules/creatures/progression/pokemon_variant_catalog.gd")
const Sprites = preload("res://scenes/visual/battle_sprite_catalog.gd")
const Transform = preload("res://modules/battle/application/transform_rules.gd")
const Arena = preload("res://scenes/visual/battle_art.gd")
const Layout = preload("res://scenes/visual/battle_sprite_layout.gd")
var checks := 0
var errors: Array[String] = []
var captures: Array[Dictionary] = []
var gpu := false
var completed := false
var catalog: DefinitionCatalog


func _initialize() -> void:
	gpu = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	call_deferred("_run")
	create_timer(180).timeout.connect(func():
		if not completed:
			push_error("VARIANT_TEST aborted or timed out")
			quit(2))


func check(label: String, condition: bool) -> void:
	checks += 1
	if not condition:
		errors.append(label)
		push_error("FAIL " + label)


func _rng(value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = value
	return rng


func _creature(id: StringName, identity: StringName, shiny: bool = false) -> CreatureInstance:
	return CreatureFactory.create(catalog.species(id), 30, catalog, ProgressionRuleset.new(), _rng(11),
		{"instance_id": identity, "is_shiny": shiny})


func _run() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Variants.CANONICAL))
	var canonical_hash := FileAccess.get_sha256(Variants.CANONICAL)
	var data := GameData.from_dict(raw)
	catalog = data.to_definition_catalog()
	check("canonical species count before overlay", catalog.species_catalog.size() == 1025)
	check("regional overlay validates", Variants.apply(catalog))
	check("57 runtime regional forms", catalog.species_catalog.size() == 1082)
	check("canonical aggregate is not mutated", data.species_catalog.size() == 1025)
	check("1068 shiny pairs", catalog.shiny_species_ids.size() == 1068)
	check("six excluded base species stay out of encounter pool", catalog.variant_allowed_species.size() == 1076)
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Variants.CONFIG))
	for id: String in config.regional_species:
		var c := _creature(StringName(id), StringName("regional_" + id), true)
		check(id + " has correct species/shiny identity", c.species_id == StringName(id) and c.is_shiny and String(c.appearance_id()) == id + "__shiny")
		check(id + " initialized own stats/PP", c.stats.max_hp > 0 and not c.moveset.is_empty() and c.moveset[0].current_pp > 0)
		check(id + " JSON restoration", CreatureInstance.from_dict(JSON.parse_string(JSON.stringify(c.to_dict()))).to_dict() == c.to_dict())
		check(id + " base species ownership", raw.species.has(String(catalog.species(c.species_id).source_metadata.base_species_id)))
	var vulpix := catalog.species(&"vulpix_alola")
	check("Alolan Vulpix is Ice rather than Fire", vulpix.has_type(&"ice") and not vulpix.has_type(&"fire"))
	check("Alolan Ninetales is Ice/Fairy", catalog.species(&"ninetales_alola").has_type(&"fairy"))
	check("Paldean Tauros breeds have distinct typing", catalog.species(&"tauros_paldea_blaze_breed").has_type(&"fire") and catalog.species(&"tauros_paldea_aqua_breed").has_type(&"water"))
	var ordinary := data.to_definition_catalog()
	var r1 := _rng(8877)
	var r2 := _rng(8877)
	var n := CreatureFactory.create(ordinary.species(&"vulpix"), 30, ordinary, ProgressionRuleset.new(), r1, {"instance_id": &"same"})
	var s := CreatureFactory.create(catalog.species(&"vulpix"), 30, catalog, ProgressionRuleset.new(), r2, {"instance_id": &"same"})
	var s_dict := s.to_dict()
	s_dict.erase("is_shiny")
	check("cosmetic choice leaves all mechanical fields unchanged", n.to_dict() == s_dict)
	check("cosmetic choice does not advance injected RNG", r1.state == r2.state)
	var hits := 0
	for i in 32768:
		if Variants.choose_shiny(&"vulpix", catalog, r2, StringName("sample_%d" % i)): hits += 1
	check("deterministic shiny sampling has rare real outcomes", hits > 0 and hits < 30)
	check("sampling leaves mechanics RNG unchanged", r1.state == r2.state)
	for id: String in config.shiny_unavailable_base_species:
		check(id + " has no fabricated shiny", not Sprites.has_shiny(StringName(id)) and not Variants.choose_shiny(StringName(id), catalog, r2, &"forced", true))
	check("old snapshots omit optional shiny field", not n.to_dict().has("is_shiny") and not CreatureInstance.from_dict(n.to_dict()).is_shiny)
	_evolutions()
	_transform()
	_storage_capture()
	await _all_assets()
	await _game_flow()
	check("canonical dataset unchanged", FileAccess.get_sha256(Variants.CANONICAL) == canonical_hash)
	var report := {"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors,
		"regional_forms": 57, "base_shiny_pairs": 1011, "regional_shiny_pairs": 57,
		"visual_entries_validated": 1125, "captures": captures, "sample_shiny_count": hits,
		"canonical_sha256": canonical_hash, "variant_manifest_sha256": FileAccess.get_sha256(Sprites.VARIANT_MANIFEST)}
	DirAccess.make_dir_recursive_absolute("res://.godot/pokemon_variant_checks")
	var file := FileAccess.open("res://.godot/pokemon_variant_checks/" + ("gpu.json" if gpu else "headless.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	completed = true
	print("POKEMON_VARIANTS ", report.status, " checks=", checks, " captures=", captures.size(), " shiny_sample=", hits, " errors=", errors)
	quit(0 if errors.is_empty() else 1)


func _evolutions() -> void:
	var choices := EvolutionSystem.evolution_candidates(catalog.species(&"vulpix_alola"), {"item_id": &"ice_stone"}, catalog)
	check("Alolan Vulpix evolves with Ice Stone to its own form", choices.size() == 1 and choices[0].species_id == &"ninetales_alola")
	check("Alolan Vulpix cannot use ordinary Fire Stone path", EvolutionSystem.evolution_candidates(catalog.species(&"vulpix_alola"), {"item_id": &"fire_stone"}, catalog).is_empty())
	check("night requirement is preserved rather than bypassed", EvolutionSystem.evolution_candidates(catalog.species(&"rattata_alola"), {"level": 100}, catalog).is_empty())
	var c := _creature(&"vulpix_alola", &"evolving", true)
	var evolved := EvolutionSystem.apply_evolution(c, &"ninetales_alola", catalog, ProgressionRuleset.new())
	check("evolution retains identity, shiny, PP and nature", evolved.instance_id == c.instance_id and evolved.is_shiny and evolved.moveset[0].to_dict() == c.moveset[0].to_dict() and evolved.nature_id == c.nature_id)
	check("evolved shiny has both views", not Sprites.animation(evolved.appearance_id(), "front").is_empty() and not Sprites.animation(evolved.appearance_id(), "back").is_empty())


func _transform() -> void:
	for shiny_user: bool in [false, true]:
		var ditto := _creature(&"ditto", &"ditto", shiny_user)
		var target := _creature(&"vulpix_alola", &"target", not shiny_user)
		var state := BattleState.create_with_parties(&"shiny_transform", [ditto], [target], 77, BattleRuleset.ID)
		var events: Array[BattleEvent] = []
		check("Transform copies regional appearance/color", Transform.apply(state, ditto, target, catalog, events) and ditto.appearance_id() == target.appearance_id())
		var restored := CreatureInstance.from_dict(JSON.parse_string(JSON.stringify(ditto.to_dict())))
		restored.restore_battle_transform()
		check("Transform snapshot restores original color", restored.species_id == &"ditto" and restored.is_shiny == shiny_user)
		Transform.restore(state, ditto, events, "test")
		check("Transform restoration emits actual appearance", ditto.species_id == &"ditto" and ditto.is_shiny == shiny_user and events[-1].metadata.appearance_id == String(ditto.appearance_id()))


func _all_assets() -> void:
	check("gallery contains base and regional forms", Sprites.species_rows().size() == 1082)
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Sprites.VARIANT_MANIFEST))
	var count := 0
	for id: String in manifest.entries:
		for side: String in ["front", "back"]:
			var clip := Sprites.animation(StringName(id), side)
			check(id + "/" + side + " valid atlas/regions/durations", not clip.is_empty())
			if clip.is_empty(): continue
			check(id + "/" + side + " full timing", Sprites.frame_index(clip, float(clip.seconds) - 0.00001) == clip.regions.size() - 1)
			var bounds := Sprites.presentation_bounds(StringName(id), side, clip)
			check(id + "/" + side + " measured envelope", bounds.size.x > 0 and bounds.size.y > 0)
			for arena_size: Vector2 in [Vector2(338, 120), Vector2(674, 359), Vector2(960, 540)]:
				var placement := Layout.placement(arena_size, side, bounds)
				var projected := Rect2(Vector2(placement.anchor) + bounds.position * float(placement.gain), bounds.size * float(placement.gain))
				check(id + "/" + side + " all-frame envelope stays inside arena", Rect2(Vector2.ZERO, arena_size).grow(0.001).encloses(projected))
		count += 1
		if count % 100 == 0:
			print("VARIANT_ASSETS ", count, "/1125")
			await process_frame
	check("all expected variant entries checked", count == 1125)
	check("bounded texture cache", Sprites.cache_stats().entries <= 8 and Sprites.cache_stats().bytes <= 128 * 1024 * 1024)


func _game_flow() -> void:
	var scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	check("normal game boots with regional overlay", scene.is_demo_ready() and scene._catalogs.species(&"vulpix_alola") != null)
	var config: Dictionary = scene.test_panel.current_configuration().duplicate(true)
	config.player_team = [{"species_id": "vulpix_alola__shiny", "level": 30}]
	config.trainer_team = [{"species_id": "sandshrew_alola__shiny", "level": 30}]
	config.wild_species_id = "sandshrew_alola__shiny"
	config.wild_min_level = 30; config.wild_max_level = 30; config.encounter_chance_percent = 100
	check("F1 accepts regional and shiny team IDs", scene._bootstrap_demo(config))
	scene._configure_presentations()
	var outcome = scene._director.on_step(scene.TECHNICAL_ZONE_ID)
	check("real regional encounter starts", outcome.battle_started)
	if not outcome.battle_started: return
	var ui = scene.battle_presentation
	ui.open_for_active_battle()
	await process_frame
	var wild: CreatureInstance = scene._session.current_wild()
	var player: CreatureInstance = scene._session.player_active()
	check("regional shiny identity is authoritative", wild.species_id == &"sandshrew_alola" and wild.is_shiny and player.is_shiny)
	check("battle sprites use true regional shiny views", ui._arena.player_species == player.appearance_id() and ui._arena.enemy_species == wild.appearance_id())
	check("UI marks shinies", "★" in ui._player_label.text and "★" in ui._enemy_label.text)
	await _capture("regional_shiny_battle")
	# Real damage and a native library clip must retain the selected appearance.
	player.moveset.clear(); player.move_ids.clear(); player.add_move(&"tackle", scene._catalogs)
	wild.moveset.clear(); wild.move_ids.clear(); wild.add_move(&"tackle", scene._catalogs)
	ui._playback.set_process(false)
	var events: Array[BattleEvent] = ui.submit_player_move(&"tackle")
	check("regional shiny executes a real combat turn", not events.is_empty())
	for step: Dictionary in ui._playback._sequence:
		for side: String in ["back", "front"]:
			check("timeline keeps shiny color", String(step.views.get(side, {}).get("species", "")).ends_with("__shiny"))
	var steps := 0
	while ui._playback.is_playing() and steps < 400:
		ui._playback._process(0.05)
		steps += 1
	check("attack playback completes", not ui._playback.is_playing())
	check("combat leaves regional/shiny identity intact", wild.is_shiny and player.is_shiny)
	await _capture("regional_shiny_after_attack")
	var wild_id := wild.instance_id
	var result = ui.submit_capture_ball(&"master_ball")
	check("real capture succeeds", result.accepted and result.session_completed)
	while ui._playback.is_playing() and steps < 800:
		ui._playback._process(0.05)
		steps += 1
	var owned: CreatureInstance = scene._session.player.owned_creature(wild_id)
	check("capture retains same instance and regional shiny", owned == wild and owned.species_id == &"sandshrew_alola" and owned.is_shiny)
	var repository := SaveGameRepository.new()
	var path := "res://.godot/pokemon_variant_checks/capture_save.json"
	check("save real captured collection", repository.save_collection(path, scene._session.player).ok)
	var loaded := repository.load(path)
	check("load real captured collection", loaded.ok)
	if loaded.ok:
		var reloaded: CreatureInstance = loaded.party.get_creature(wild_id)
		check("save preserves region/color/PP/stats", reloaded != null and reloaded.to_dict() == owned.to_dict())
	check("capture returns to exploration", ui.continue_after_completion())
	# The ordinary gallery exposes the same new resources.
	scene.toggle_pokemon_gallery()
	await process_frame
	var gallery = scene._pokemon_gallery
	gallery._filter("vulpix_alola")
	gallery._shiny.button_pressed = true
	check("F3 toggles real shiny views", gallery._arena.player_species == &"vulpix_alola__shiny" and gallery._arena.enemy_species == &"vulpix_alola__shiny")
	await _capture("regional_shiny_gallery")
	gallery.close_requested.emit()
	check("real trainer battle starts with regional shinies", scene.start_demo_trainer_battle())
	var trainer = scene.trainer_battle_presentation
	check("trainer renderer uses regional shiny front/back", trainer._arena.player_species == &"vulpix_alola__shiny" and trainer._arena.enemy_species == &"sandshrew_alola__shiny")
	await _capture("regional_shiny_trainer")
	for actor: CreatureInstance in [trainer.session.player_active(), trainer.session.opponent_active()]:
		actor.moveset.clear(); actor.move_ids.clear(); actor.add_move(&"tackle", scene._catalogs)
	trainer._playback.set_process(false)
	var trainer_events: Array[BattleEvent] = trainer.submit_player_move(&"tackle")
	check("trainer AI resolves real turn with regional team", not trainer_events.is_empty())
	steps = 0
	while trainer._playback.is_playing() and steps < 400:
		trainer._playback._process(0.05)
		steps += 1
	check("trainer playback retains color/form", not trainer._playback.is_playing() and trainer._arena.enemy_species == &"sandshrew_alola__shiny")
	scene.queue_free()
	await process_frame


func _storage_capture() -> void:
	var collection := PlayerCollection.new()
	for i in 6: collection.party.add_creature(_creature(&"pikachu", StringName("full_party_%d" % i)))
	collection.inventory.add(&"master_ball", 1)
	var session := WildAdventureSession.new(collection, catalog, ProgressionRuleset.new())
	session.live_moves_enabled = true
	session.force_shiny_encounters = true
	var table := WildEncounterTable.new(&"regional_storage", 10000)
	table.add_slot(WildEncounterSlot.new(&"regional", &"vulpix_alola", 1, 30, 30))
	var encounter := session.begin_encounter(table, _rng(101), 111)
	check("full-party regional encounter", encounter.status == WildEncounterResult.ENCOUNTER)
	var wild := encounter.creature
	var reaction := SimpleBattleOpponentPolicy.choose_move_action(session.battle_state(), &"side_b", catalog)
	var result := session.submit_player_command(WildBattleCommand.capture(session.battle_state().turn + 1, &"side_a", &"master_ball"), _rng(10), reaction)
	check("shiny capture routes to PC retaining real instance", result.accepted and result.session_completed and collection.storage.get_creature(wild.instance_id) == wild and wild.is_shiny)
	var repository := SaveGameRepository.new()
	var path := "res://.godot/pokemon_variant_checks/storage_save.json"
	check("save captured PC shiny", repository.save_collection(path, collection).ok)
	var loaded := repository.load(path)
	check("load PC retains form/color/identity", loaded.ok and loaded.storage.get_creature(wild.instance_id).to_dict() == wild.to_dict())


func _capture(label: String) -> void:
	if not gpu: return
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://.godot/pokemon_variant_checks/" + label + ".png"
	check("capture " + label, root.get_texture().get_image().save_png(path) == OK)
	captures.append({"path": path, "sha256": FileAccess.get_sha256(path)})
