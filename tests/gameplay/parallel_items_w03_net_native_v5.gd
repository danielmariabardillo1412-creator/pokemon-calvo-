extends SceneTree

## W03 TANDA 05: genuinely native Net Ball, canonical Water/Normal/Bug/Water+Bug,
## full Party + full single PC box with auto-expansion, actual owner and SaveV2.
## Encounter targets are built by WildEncounterSystem from the live map table.
var errors: Array[String] = []
var checks := 0
var scene: Node2D
var bridge: Node
var view: Control
const SAVE := "user://w03_net_native_v5.json"

func ck(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		errors.append(label)
		push_error("W03_NET_NATIVE_V5: " + label)

func _initialize() -> void:
	call_deferred("_run")

func _mon(id: StringName) -> CreatureInstance:
	var rng := RandomNumberGenerator.new()
	rng.seed = 501005
	var creature := CreatureFactory.create(scene._catalogs.species(&"mew"), 40, scene._catalogs, ProgressionRuleset.new(), rng,
		{"instance_id": id, "moves": ["tackle"], "nature_id": &"hardy"})
	creature.ability_id = &""
	return creature

func _target_species(species: StringName) -> bool:
	var zone: StringName = scene.TECHNICAL_ZONE_ID
	var built: Dictionary = TechnicalEncounterPoolBuilder.build(scene._catalogs, zone, 100, 5, 5, species)
	if not bool(built.get("ok", false)):
		return false
	scene._director._tables[zone] = built.table
	return true

func _encounter() -> bool:
	scene.player.global_position = Vector2(420, 150)
	await scene._on_player_step_completed(scene.player.global_position)
	if view.session != null and view.session.has_active_battle():
		view._playback.set_process(false)
		return true
	print("W03_NET_NATIVE_V5_DIAG zone=", scene.field_note_native_step(scene.player.global_position),
		" native_error=", bridge.last_error, " kind=", bridge.kind, " occupied=", bridge.occupied(),
		" active_config=", scene._active_config.get("wild_species_id", ""),
		" field_ready=", scene.is_demo_ready(), " player_party=", scene.field_collection().party.size())
	return false

func _finish_battle_if_caught() -> void:
	if view._playback.is_playing():
		view._playback.set_process(false)
		var count := 0
		while view._playback.is_playing() and count < 200:
			view._playback.advance(0.5)
			count += 1
	if view.session != null and not view.session.has_active_battle():
		await bridge.leave_battle()

func _cancel_still_active() -> void:
	if view.session != null:
		view._playback.cancel()
		await view.session.close()
	view.hide()
	bridge.busy = false
	bridge.kind = ""
	bridge._unlock_world()

func _write(envelope: Dictionary) -> bool:
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(envelope))
	f.close()
	return true

func _run() -> void:
	scene = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	bridge = scene._native_battles
	view = bridge.view
	bridge.save_path = SAVE
	ck("native field demo ready", scene.is_demo_ready())
	if not scene.is_demo_ready():
		await _done()
		return
	scene.player.set_physics_process(false)
	var config: Dictionary = scene._active_config.duplicate(true)
	config.wild_species_id = "goldeen"
	config.wild_min_level = 5
	config.wild_max_level = 5
	config.encounter_chance_percent = 100
	scene._on_configuration_applied(config)
	var owner: PlayerCollection = scene.field_collection()
	ck("Net Ball is known and owned inventory accepts stock",
		CaptureRuleset.new().is_known_ball(&"net_ball") and owner.inventory.add(&"net_ball", 8))
	for i in 8:
		if owner.party.is_full(): break
		ck("party fill %d" % i, owner.party.add_creature(_mon(StringName("w03v5_party_%d" % i))))
	ck("party truly 6/6", owner.party.is_full() and owner.party.size() == 6)
	# One entire box full: next captured mon must create a new box. Global
	# STORAGE-full is impossible by the established unlimited-box policy.
	for i in 30:
		ck("first storage box slot %d" % i,
			owner.storage.add_creature(_mon(StringName("w03v5_box_%d" % i))))
	ck("first PC box is exactly full", owner.storage.box_count() == 1
		and owner.storage.get_all_creatures().size() == 30)
	var type_cases: Array[Dictionary] = [
		{"species": &"goldeen", "expected": 3.5, "water": true, "bug": false},
		{"species": &"pidgey", "expected": 1.0, "water": false, "bug": false},
		{"species": &"caterpie", "expected": 3.5, "water": false, "bug": true},
		{"species": &"surskit", "expected": 3.5, "water": true, "bug": true},
	]
	for test_case: Dictionary in type_cases:
		var species_id: StringName = test_case.species
		var species: CreatureSpecies = scene._catalogs.species(species_id)
		ck("catalog species with expected canonical type " + String(species_id),
			species != null and species.has_type(&"water") == bool(test_case.water)
			and species.has_type(&"bug") == bool(test_case.bug))
		ck("living map table targets " + String(species_id), _target_species(species_id))
		ck("wild native Showdown battle for " + String(species_id), await _encounter())
		if view.session == null or not view.session.has_active_battle():
			break
		var target: CreatureInstance = view.session.battle_state().active_for_side(&"side_b")
		ck("actual native target species is " + String(species_id), target != null
			and target.base_species_id() == species_id)
		var expected_prob := CaptureRuleset.new().catch_probability(species.capture_rate,
			float(test_case.expected), 1.0, target.stats.max_hp, target.current_hp)
		ck("Net Ball type profile exact multiplier " + String(species_id),
			is_equal_approx(CaptureRuleset.BallEffects.multiplier(&"net_ball", target, species),
				float(test_case.expected)))
		var starting_qty := owner.inventory.quantity(&"net_ball")
		var starting_storage := owner.storage.get_all_creatures().size()
		var native_seed := 51005 + checks
		view.session._capture_rng.seed = native_seed
		var attempt: Dictionary = await view.session.capture(&"net_ball", view.session.revision)
		var resolution: Dictionary = attempt.get("capture_outcome", {}).get("capture", {})
		var result: Dictionary = resolution.get("result", {})
		ck("native Net attempt actually processed " + String(species_id),
			bool(attempt.get("accepted", false))
			and result.get("status", "") in [String(CaptureResult.SUCCESS), String(CaptureResult.FAILED)]
			and is_equal_approx(float(result.get("probability", -1.0)), expected_prob))
		ck("Net attempt spends one in staged/settled native inventory " + String(species_id),
			view.session.inventory.quantity(&"net_ball") == starting_qty - 1)
		if result.get("status", "") == String(CaptureResult.SUCCESS):
			var target_id: StringName = target.instance_id
			ck("success commits one real owned storage identity " + String(species_id),
				owner.inventory.quantity(&"net_ball") == starting_qty - 1
				and owner.party.size() == 6
				and owner.storage.get_all_creatures().size() == starting_storage + 1
				and owner.location_of(target_id) == &"STORAGE"
				and owner.caught_base_species_ids.has(species_id))
			if species_id == &"goldeen":
				ck("full PC box auto-expands on first real Net capture",
					owner.storage.box_count() == 2 and owner.storage.get_all_creatures().size() == 31)
				ck("first Net Ball settlement persists native owner via SaveV2",
					bridge.save_game())
			await _finish_battle_if_caught()
		else:
			ck("RNG failure never records caught species " + String(species_id),
				not owner.caught_base_species_ids.has(species_id)
				and owner.storage.get_all_creatures().size() == starting_storage
				and owner.inventory.quantity(&"net_ball") == starting_qty)
			await _cancel_still_active()
		# Re-open another native encounter on the same owner, without reconfig.
		if species_id == &"goldeen":
			ck("post-capture SaveV2 keeps PC boxes stock and Water ledger",
				await bridge.load_game() and scene.field_collection().storage.box_count() == 2
				and scene.field_collection().inventory.quantity(&"net_ball") == 7
				and scene.field_collection().caught_base_species_ids.has(&"goldeen"))
			owner = scene.field_collection()
	ck("manual native settled save after all type cases", bridge.save_game())
	var good_bytes: PackedByteArray = FileAccess.get_file_as_bytes(SAVE)
	var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	ck("genuine native SaveV2 envelope", envelope is Dictionary)
	if envelope is Dictionary:
		var bad: Dictionary = envelope.duplicate(true)
		bad.payload.collection["caught_base_species_ids"] = {"schema_version": 1, "ids": ["goldeen", "goldeen"]}
		bad.sha256 = JSON.stringify(bad.payload).sha256_text()
		ck("adversarial valid-hash duplicated base ledger written", _write(bad))
		var live_owner: PlayerCollection = scene.field_collection()
		var live_qty := live_owner.inventory.quantity(&"net_ball")
		var live_pc := live_owner.storage.to_dict()
		ck("corrupt SaveV2 is rejected atomically with owner and stock intact",
			not await bridge.load_game()
			and is_same(scene.field_collection(), live_owner)
			and live_owner.inventory.quantity(&"net_ball") == live_qty
			and live_owner.storage.to_dict() == live_pc)
		var f := FileAccess.open(SAVE, FileAccess.WRITE)
		ck("restore original valid SaveV2", f != null)
		if f != null:
			f.store_buffer(good_bytes)
			f.close()
			ck("original SaveV2 recovers real Net owner", await bridge.load_game()
				and scene.field_collection().caught_base_species_ids.has(&"goldeen")
				and scene.field_collection().storage.get_all_creatures().size() >= 31)
	await _done()

func _done() -> void:
	if view != null and view.session != null:
		await view.session.close()
	if scene != null: scene.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	if errors.is_empty():
		print("W03_NET_NATIVE_V5 PASS checks=" + str(checks))
		quit(0)
	else:
		print("W03_NET_NATIVE_V5 FAIL checks=" + str(checks) + " errors=" + JSON.stringify(errors))
		quit(1)
