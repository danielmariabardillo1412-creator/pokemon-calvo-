extends SceneTree

## IA3/W03 TANDA04 QA03/QA08. Real native RNG failure and atomic
## SaveV2 ledger corruption/legacy recovery, preserving session identity.
var errors: Array[String] = []
var checks := 0
var scene: Node2D
var bridge: Node
var view: Control
const SAVE := "user://w03_repeat_native_v4_negatives.json"

func ck(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		errors.append(label)
		push_error("W03_REPEAT_NATIVE_V4_NEG: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _write_envelope(data: Dictionary) -> bool:
	var file := FileAccess.open(SAVE, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	return true

func _run() -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	bridge = scene._native_battles
	view = bridge.view
	bridge.save_path = SAVE
	ck("native field demo available", scene.is_demo_ready())
	if not scene.is_demo_ready():
		await _finish()
		return
	scene.player.set_physics_process(false)
	var config: Dictionary = scene._active_config.duplicate(true)
	config.wild_species_id = "mewtwo"
	config.wild_min_level = 5
	config.wild_max_level = 5
	config.encounter_chance_percent = 100
	scene._on_configuration_applied(config)
	var owner: PlayerCollection = scene.field_collection()
	owner.party = CreatureParty.new()
	var factory_rng := RandomNumberGenerator.new()
	factory_rng.seed = 43004
	var lead := CreatureFactory.create(scene._catalogs.species(&"mew"), 50, scene._catalogs, ProgressionRuleset.new(), factory_rng,
		{"instance_id": &"w03v4_failure_lead", "moves": ["tackle", "protect"], "nature_id": &"hardy"})
	lead.ability_id = &""
	ck("strong native lead for real low-probability capture", owner.party.add_creature(lead))
	ck("two real Poké Balls in owned inventory", owner.inventory.add(&"poke_ball", 2))
	scene.player.global_position = Vector2(420, 150)
	await scene._on_player_step_completed(scene.player.global_position)
	ck("Mewtwo wild battle opens via ordinary field", view.session != null and view.session.has_active_battle())
	if view.session == null or not view.session.has_active_battle():
		await _finish()
		return
	view._playback.set_process(false)
	view.session._capture_rng.seed = 6413
	var reference_rng := RandomNumberGenerator.new()
	reference_rng.seed = 6413
	ck("failure seed probes above maximum capture probability", reference_rng.randf() > 0.05)
	var before_rng: int = view.session._capture_rng.state
	var before_stock: int = owner.inventory.quantity(&"poke_ball")
	var before_ledger := owner.caught_base_species_ids.duplicate()
	var response: Dictionary = await view.session.capture(&"poke_ball", view.session.revision)
	var outcome: Dictionary = response.get("capture_result", {})
	ck("native Poké Ball fails using real RNG",
		bool(response.get("accepted", false))
		and outcome.get("status", "") == String(CaptureResult.FAILED)
		and float(outcome.get("probability", 1.0)) < 0.05)
	ck("failed capture consumes only staged inventory and advances RNG",
		view.session.inventory.quantity(&"poke_ball") == before_stock - 1
		and owner.inventory.quantity(&"poke_ball") == before_stock
		and view.session._capture_rng.state != before_rng)
	ck("failed capture never writes a base ledger nor routes a creature",
		owner.caught_base_species_ids == before_ledger
		and owner.party.size() == 1
		and owner.storage.get_all_creatures().is_empty())
	ck("native fight remains active after failed capture", view.session.has_active_battle())
	view._playback.set_process(false)
	var active_snapshot: Dictionary = view.session.snapshot()
	var spent_rng: int = view.session._capture_rng.state
	ck("failed-turn native save is accepted", bridge.save_game())
	var good_bytes: PackedByteArray = FileAccess.get_file_as_bytes(SAVE)
	ck("failed-turn checkpoint reloads with staged consumption",
		await bridge.load_game()
		and view.session != null and view.session.has_active_battle()
		and view.session.snapshot() == active_snapshot
		and view.session._capture_rng.state == spent_rng
		and view.session.inventory.quantity(&"poke_ball") == before_stock - 1
		and scene.field_collection().caught_base_species_ids.is_empty())
	view._playback.set_process(false)
	var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	ck("canonical native SaveV2 envelope exists", envelope is Dictionary)
	if envelope is Dictionary:
		var corrupt: Dictionary = envelope.duplicate(true)
		corrupt.payload.collection["caught_base_species_ids"] = {"schema_version": 1, "ids": ["pidgey", "pidgey"]}
		corrupt.sha256 = JSON.stringify(corrupt.payload).sha256_text()
		ck("write valid-checksum, invalid-ledger fixture", _write_envelope(corrupt))
		var original_owner: PlayerCollection = scene.field_collection()
		var original_snapshot: Dictionary = view.session.snapshot()
		ck("corrupted ledger rejects without state publication",
			not await bridge.load_game()
			and is_same(scene.field_collection(), original_owner)
			and view.session.snapshot() == original_snapshot
			and view.session._capture_rng.state == spent_rng
			and scene.field_collection().caught_base_species_ids.is_empty())
		var file := FileAccess.open(SAVE, FileAccess.WRITE)
		ck("restore original native bytes", file != null)
		if file != null:
			file.store_buffer(good_bytes)
			file.close()
		ck("original save remains loadable after corrupt rejection",
			await bridge.load_game() and scene.field_collection().caught_base_species_ids.is_empty())
		var legacy: Dictionary = envelope.duplicate(true)
		legacy.payload.collection.erase("caught_base_species_ids")
		legacy.sha256 = JSON.stringify(legacy.payload).sha256_text()
		ck("write legacy fixture without history ledger", _write_envelope(legacy))
		ck("legacy native save restores empty ledger and active battle",
			await bridge.load_game()
			and scene.field_collection().caught_base_species_ids.is_empty()
			and view.session != null and view.session.has_active_battle())
	await _finish()

func _finish() -> void:
	if view != null and view.session != null:
		await view.session.close()
	if scene != null:
		scene.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	if errors.is_empty():
		print("W03_REPEAT_NATIVE_V4_NEG PASS checks=" + str(checks))
		quit(0)
	else:
		print("W03_REPEAT_NATIVE_V4_NEG FAIL checks=" + str(checks) + " errors=" + JSON.stringify(errors))
		quit(1)
