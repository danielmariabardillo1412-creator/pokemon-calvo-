extends Node

const Session = preload("res://modules/gameplay/field_native_session.gd")
const Presentation = preload("res://scenes/visual/field_native_presentation.gd")
const Saves = preload("res://modules/save/field_native_save.gd")
var field: Node2D
var view: Control
var busy := false
var kind := ""
var clocks := {}
var format_id := "gen9calvounifiedv1"
var last_error := ""
var save_path := "user://pokemon_calvo_field.json"
var saves := Saves.new()


func configure(world: Node2D) -> void:
	field = world
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--battle-format=") and arg.get_slice("=", 1) in ["gen8customgame", "gen9customgame", "gen9calvounifiedv1"]: format_id = arg.get_slice("=", 1)
	view = Presentation.new(); view.catalogs = field._catalogs; view.owner_bridge = self
	field.get_node("CanvasLayer").add_child(view)
	view.return_requested.connect(leave_battle)
	view.diagnostic_event.connect(func(entry: Dictionary):
		if kind == "trainer": field._on_trainer_diagnostic_event(entry)
		else: field._on_wild_diagnostic_event(entry))


func occupied() -> bool:
	return busy or view != null and view.visible


func _world_overlay_open() -> bool:
	return field.test_panel.is_panel_open() or field._pokemon_gallery != null and field._pokemon_gallery.visible or field._item_bag != null and field._item_bag.visible or field._doubles_demo != null and field._doubles_demo.visible


func on_step(position: Vector2) -> void:
	if occupied() or field.traversal_is_busy() or _world_overlay_open(): return
	var zone: StringName = field.zone_at_position(position)
	field._metrics.note_step(zone)
	field._recorder.record(&"overworld", &"step_completed", {"x": position.x, "y": position.y, "zone_id": String(zone), "backend": "native"})
	if field.trainer_trigger_contains(position) and start_trainer(): return
	if zone == &"" or not field._director.has_zone(zone): return
	if not field._session.player.party.get_creatures().any(func(c): return not c.is_knocked_out()): return
	var staged := RandomNumberGenerator.new(); staged.state = field._director._encounter_rng.state
	var encounter := WildEncounterSystem.resolve(field._director._tables[zone], staged, field._catalogs, ProgressionRuleset.new())
	field._metrics.note_encounter_roll(encounter.status == WildEncounterResult.ENCOUNTER, encounter.status, encounter.reason)
	if encounter.status == WildEncounterResult.NONE:
		field._director._encounter_rng.state = staged.state; return
	if encounter.status != WildEncounterResult.ENCOUNTER: notify("Encuentro rechazado: " + encounter.reason); return
	if field._session.force_shiny_encounters and field._catalogs.shiny_species_ids.has(String(encounter.creature.species_id)): encounter.creature.is_shiny = true
	busy = true; kind = "wild"; _lock_world()
	await _open(encounter.creature, staged.state)


func start_trainer() -> bool:
	if occupied() or field.traversal_is_busy() or _world_overlay_open() or not field._trainer_campaign_owner.is_ready(): return false
	if not field._trainer_campaign_owner.roster_for_battle().any(func(c): return not c.is_knocked_out()): return false
	if not field._session.player.party.get_creatures().any(func(c): return not c.is_knocked_out()): return false
	busy = true; kind = "trainer"; _lock_world()
	_open.call_deferred(null, -1)
	return true


func _open(wild: CreatureInstance, next_rng: int) -> void:
	var owner: TrainerCampaignRosterOwner = field._trainer_campaign_owner if kind == "trainer" else null
	var session := Session.new(field._catalogs, field._session.player, clocks, format_id, owner)
	view.session = session; view.player = field._session.player; view._working = true
	view._z_toggle.set_pressed_no_signal(false); view._dynamax_toggle.set_pressed_no_signal(false)
	view._event_log.text = "Comienza el combate."; _show_battle()
	var seed_value: int = field._director._next_battle_seed
	var seed_parts := [seed_value, 12004, 12006, 1]
	var ok: bool
	if kind == "wild": ok = await session.begin_wild(get_tree(), wild, seed_parts, seed_value)
	else: ok = await session.begin_trainer(get_tree(), owner.trainer_id, owner.roster_for_battle(), seed_parts)
	view._working = false; busy = false
	if not ok:
		last_error = session.last_error; await session.close(); view.hide(); kind = ""
		_unlock_world(); notify("No se pudo iniciar el combate: " + last_error); return
	if next_rng != -1: field._director._encounter_rng.state = next_rng
	field._director._next_battle_seed += 1
	field._metrics.note_battle_started(StringName(kind))
	field._recorder.record(StringName(kind), &"battle_started", {"backend": "native", "format": format_id, "seed": seed_value})
	view.diagnostic_event.emit({"event": "battle_opened"}); view._refresh_view()


func _lock_world() -> void:
	field.player.movement_enabled = false; field.player.velocity = Vector2.ZERO


func _show_battle() -> void:
	field.get_window().content_scale_size = Vector2i(1280, 720)
	view.show(); field._hud.hide()


func _unlock_world() -> void:
	field.get_window().content_scale_size = Vector2i(960, 540)
	field.player.reset_step_meter()
	field.player.movement_enabled = not field.test_panel.is_panel_open()


func leave_battle() -> void:
	if busy or view.session == null or view.session.has_active_battle() or view._playback.is_playing(): return
	busy = true
	view._working = true
	var reason := String(view.session.completion_reason)
	await view.session.close()
	view.hide(); view._medicine_popup.hide(); view._working = false; busy = false; kind = ""
	_unlock_world(); notify({"CAPTURED": "Pokémon capturado.", "FLED": "Has escapado.", "VICTORY": "¡Victoria!", "DEFEAT": "Tu equipo se ha debilitado.", "DRAW": "Empate."}.get(reason, "Combate terminado."))
	field._recorder.record(&"native", &"battle_closed", {"reason": reason})


func notify(message: String) -> void:
	last_error = message
	if field._notice_label != null: field._notice_label.text = message
	if view != null and view.visible: view._event_log.append_text("\n" + message)


func _idle_boundary() -> bool:
	return not busy and not field.traversal_is_busy() and not _world_overlay_open() and not (view != null and (view._working or view._playback.is_playing() or view.session != null and view.session.busy))


func save_game() -> bool:
	if not _idle_boundary(): return false
	if not view.visible and not field.player.movement_enabled: return false
	var battle := {}
	if view.session != null and view.session.has_active_battle(): battle = view.session.snapshot()
	var world := {"position": [field.player.global_position.x, field.player.global_position.y], "region": String(field.technical_region_id()),
		"config": field._active_config.duplicate(true), "rng": str(field._director._encounter_rng.state), "next_seed": field._director._next_battle_seed, "format": format_id}
	for id: String in clocks.keys():
		var c: CreatureInstance = field._session.player.owned_creature(StringName(id))
		if c == null: c = field._trainer_campaign_owner.owned_creature(StringName(id))
		if c == null or c.status_state.persistent_id != &"sleep": clocks.erase(id)
	var ok := saves.write(save_path, field._session.player, world, field._trainer_campaign_owner, clocks, battle, field._catalogs)
	notify("Partida guardada." if ok else "No se pudo guardar: " + saves.last_error)
	return ok


func load_game() -> bool:
	if not _idle_boundary(): return false
	busy = true; view._working = true; _lock_world(); view._refresh_view()
	var loaded := saves.read(save_path, field._catalogs)
	if not loaded.ok: return _load_failed(saves.last_error)
	var world: Dictionary = loaded.world
	if not world.get("position") is Array or world.position.size() != 2 or not world.get("config") is Dictionary or world.get("format") not in ["gen8customgame", "gen9customgame", "gen9calvounifiedv1"] or not world.get("rng") is String or not world.rng.is_valid_int() or not (world.get("next_seed") is int or world.get("next_seed") is float): return _load_failed("world_shape")
	for v: Variant in world.position:
		if not (v is int or v is float) or not is_finite(v): return _load_failed("world_position")
	var position := Vector2(world.position[0], world.position[1])
	if position.x < 16 or position.x > 1280 or position.y < 16 or position.y > 850 or String(field._region_at_position(position)) != world.get("region") or not field.traversal_controller._destination_is_clear(position): return _load_failed("world_position")
	if world.next_seed != int(world.next_seed) or world.next_seed < 1 or world.next_seed > 2147483646: return _load_failed("world_seed")
	var tables := _tables_for(world.config)
	if tables.is_empty(): return _load_failed("world_encounters")
	var candidate: RefCounted
	if not loaded.battle.is_empty():
		var is_trainer: bool = loaded.battle.get("adventure", {}).get("kind") == "trainer"
		candidate = Session.new(field._catalogs, loaded.collection, loaded.clocks, world.format, loaded.trainer if is_trainer else null)
		if not await candidate.restore_saved(get_tree(), loaded.battle):
			var reason: String = candidate.last_error; await candidate.close(); return _load_failed(reason)
	if view.session != null: await view.session.close()
	# Candidate state is fully validated, including its worker. Publish synchronously.
	field._session = WildAdventureSession.new(loaded.collection, field._catalogs, ProgressionRuleset.new())
	field._trainer_session = TrainerBattleSession.new(loaded.collection, field._catalogs, ProgressionRuleset.new())
	field._trainer_campaign_owner = loaded.trainer
	field._active_config = world.config.duplicate(true)
	field.test_panel.restore_configuration(world.config)
	field._trainer_profile_id = StringName(world.config.get("trainer_profile_id", "balanced"))
	field._trainer_expertise_id = StringName(world.config.get("trainer_expertise_id", "full"))
	field._session.force_shiny_encounters = String(world.config.get("wild_species_id", "")).ends_with("__shiny")
	field._director.session = field._session; field._director._tables = tables
	field._director._encounter_rng.state = int(world.rng); field._director._next_battle_seed = int(world.next_seed)
	field.player.global_position = position; field.player.reset_step_meter()
	clocks = loaded.clocks; format_id = world.format
	view._playback.cancel(); view._medicine_popup.hide(); view.session = candidate; view.player = loaded.collection
	view._settlement_error = false; view._working = false
	view._z_toggle.set_pressed_no_signal(false); view._dynamax_toggle.set_pressed_no_signal(false)
	field._configure_presentations()
	busy = false; kind = String(candidate.battle_kind) if candidate != null else ""
	if candidate != null:
		_show_battle(); view._event_log.text = "Combate recuperado."; view.diagnostic_event.emit({"event": "battle_opened"}); view._refresh_view()
	else: view.hide(); _unlock_world()
	notify("Partida recuperada.")
	return true


func _tables_for(config: Dictionary) -> Dictionary:
	var tables := {}
	for key: String in ["player_team", "trainer_team"]:
		if not config.get(key) is Array or config[key].is_empty() or config[key].size() > 6: return {}
		for row: Variant in config[key]:
			if not row is Dictionary or not row.get("species_id") is String or not (row.get("level") is int or row.get("level") is float) or row.level != int(row.level) or row.level < 1 or row.level > 100: return {}
	if not config.get("wild_species_id") is String: return {}
	for key: String in ["wild_min_level", "wild_max_level", "cave_min_level", "cave_max_level", "encounter_chance_percent"]:
		if not (config.get(key) is float or config.get(key) is int) or int(config[key]) != config[key] or config[key] < 0 or config[key] > 100: return {}
	var species := String(config.get("wild_species_id", "")).trim_suffix("__shiny")
	if String(config.get("wild_species_id", "")).ends_with("__shiny") and not field._catalogs.shiny_species_ids.has(species): return {}
	for row: Array in [[field.TECHNICAL_ZONE_ID, "wild_min_level", "wild_max_level"], [field.TECHNICAL_CAVE_ZONE_ID, "cave_min_level", "cave_max_level"]]:
		if config[row[1]] < 1 or config[row[2]] < config[row[1]]: return {}
		var built := TechnicalEncounterPoolBuilder.build(field._catalogs, row[0], int(config.encounter_chance_percent), int(config[row[1]]), int(config[row[2]]), StringName(species))
		if not built.ok: return {}
		tables[row[0]] = built.table
	return tables


func _load_failed(reason: String) -> bool:
	busy = false
	view._working = false
	if view.visible: _lock_world()
	else: _unlock_world()
	notify("No se pudo cargar: " + reason); view._refresh_view()
	return false


func recover_battle() -> bool:
	if not _idle_boundary() or view.session == null or not view.session.needs_recovery: return false
	busy = true
	view._working = true; view._refresh_view()
	var old: RefCounted = view.session
	var replacement := Session.new(field._catalogs, field._session.player, clocks, format_id, field._trainer_campaign_owner if kind == "trainer" else null)
	var ok: bool = await replacement.restore_saved(get_tree(), old.snapshot())
	if ok:
		await old.close(); view.session = replacement; view.diagnostic_event.emit({"event": "battle_opened"})
	else: await replacement.close()
	busy = false; view._working = false; view._refresh_view()
	return ok


func _exit_tree() -> void:
	if view != null and view.session != null: view.session.stop_now()
