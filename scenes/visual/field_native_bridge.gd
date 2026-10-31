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
	view = Presentation.new(); view.catalogs = field.field_definitions(); view.owner_bridge = self
	field.field_attach_battle_view(view)
	view.return_requested.connect(leave_battle)
	view.diagnostic_event.connect(func(entry: Dictionary):
		field.field_forward_battle_diagnostic(kind, entry))


func occupied() -> bool:
	return busy or view != null and view.visible


func _world_overlay_open() -> bool:
	return field.field_has_world_overlay()


func on_step(position: Vector2) -> void:
	if occupied() or field.traversal_is_busy() or _world_overlay_open(): return
	var zone: StringName = field.field_note_native_step(position)
	if field.trainer_trigger_contains(position) and start_trainer(): return
	var prepared: Dictionary = field.field_prepare_native_encounter(zone)
	if prepared.is_empty(): return
	var encounter := prepared.get("result") as WildEncounterResult
	if encounter == null or encounter.status == WildEncounterResult.NONE: return
	if encounter.status != WildEncounterResult.ENCOUNTER: notify("Encuentro rechazado: " + encounter.reason); return
	busy = true; kind = "wild"; _lock_world()
	await _open(encounter.creature, int(prepared.get("next_rng", -1)))


func start_trainer() -> bool:
	if occupied() or field.traversal_is_busy() or _world_overlay_open(): return false
	var owner: TrainerCampaignRosterOwner = field.field_trainer_owner()
	if owner == null or not owner.is_ready(): return false
	if not owner.roster_for_battle().any(func(c): return not c.is_knocked_out()): return false
	if not field.field_has_living_party(): return false
	busy = true; kind = "trainer"; _lock_world()
	_open.call_deferred(null, -1)
	return true


func _open(wild: CreatureInstance, next_rng: int) -> void:
	var collection: PlayerCollection = field.field_collection()
	var owner: TrainerCampaignRosterOwner = field.field_trainer_owner() if kind == "trainer" else null
	var session := Session.new(field.field_definitions(), collection, clocks, format_id, owner)
	view.session = session; view.player = collection; view._working = true
	view._z_toggle.set_pressed_no_signal(false); view._dynamax_toggle.set_pressed_no_signal(false)
	view._event_log.text = "Comienza el combate."; _show_battle()
	var seed_value: int = field.field_native_seed()
	var seed_parts := [seed_value, 12004, 12006, 1]
	var ok: bool
	if kind == "wild": ok = await session.begin_wild(get_tree(), wild, seed_parts, seed_value)
	else: ok = await session.begin_trainer(get_tree(), owner.trainer_id, owner.roster_for_battle(), seed_parts)
	view._working = false; busy = false
	if not ok:
		last_error = session.last_error; await session.close(); view.hide(); kind = ""
		_unlock_world(); notify("No se pudo iniciar el combate: " + last_error); return
	field.field_commit_native_battle_start(next_rng, StringName(kind), format_id)
	view.diagnostic_event.emit({"event": "battle_opened"}); view._refresh_view()


func _lock_world() -> void:
	field.field_lock_battle_world()


func _show_battle() -> void:
	field.field_show_battle_view(view)


func _unlock_world() -> void:
	field.field_unlock_battle_world()


func leave_battle() -> void:
	if busy or view.session == null or view.session.has_active_battle() or view._playback.is_playing(): return
	busy = true
	view._working = true
	var reason := String(view.session.completion_reason)
	await view.session.close()
	view.hide(); view._medicine_popup.hide(); view._working = false; busy = false; kind = ""
	_unlock_world(); notify({"CAPTURED": "Pokémon capturado.", "FLED": "Has escapado.", "VICTORY": "¡Victoria!", "DEFEAT": "Tu equipo se ha debilitado.", "DRAW": "Empate."}.get(reason, "Combate terminado."))
	field.field_record_native_battle_closed(reason)


func notify(message: String) -> void:
	last_error = message
	field.field_show_notice(message)
	if view != null and view.visible: view._event_log.append_text("\n" + message)


func _idle_boundary() -> bool:
	return not busy and not field.traversal_is_busy() and not _world_overlay_open() and not (view != null and (view._working or view._playback.is_playing() or view.session != null and view.session.busy))


func save_game() -> bool:
	if not _idle_boundary(): return false
	if not view.visible and not field.field_player_movement_enabled(): return false
	var battle := {}
	if view.session != null and view.session.has_active_battle(): battle = view.session.snapshot()
	var collection: PlayerCollection = field.field_collection()
	var owner: TrainerCampaignRosterOwner = field.field_trainer_owner()
	var world: Dictionary = field.field_native_world_snapshot(format_id)
	for id: String in clocks.keys():
		var c: CreatureInstance = collection.owned_creature(StringName(id)) if collection != null else null
		if c == null: c = owner.owned_creature(StringName(id)) if owner != null else null
		if c == null or c.status_state.persistent_id != &"sleep": clocks.erase(id)
	var ok := saves.write(save_path, collection, world, owner, clocks, battle, field.field_definitions())
	notify("Partida guardada." if ok else "No se pudo guardar: " + saves.last_error)
	return ok


func load_game() -> bool:
	if not _idle_boundary(): return false
	busy = true; view._working = true; _lock_world(); view._refresh_view()
	var loaded := saves.read(save_path, field.field_definitions())
	if not loaded.ok: return _load_failed(saves.last_error)
	var world: Dictionary = loaded.world
	var validated: Dictionary = field.field_validate_native_loaded_world(world)
	if not bool(validated.get("ok", false)): return _load_failed(String(validated.get("error", "world_shape")))
	var position: Vector2 = validated.position
	var tables: Dictionary = validated.tables
	var candidate: RefCounted
	if not loaded.battle.is_empty():
		var is_trainer: bool = loaded.battle.get("adventure", {}).get("kind") == "trainer"
		candidate = Session.new(field.field_definitions(), loaded.collection, loaded.clocks, world.format, loaded.trainer if is_trainer else null)
		if not await candidate.restore_saved(get_tree(), loaded.battle):
			var reason: String = candidate.last_error; await candidate.close(); return _load_failed(reason)
	if view.session != null: await view.session.close()
	# Candidate state is fully validated, including its worker. Publish synchronously.
	field.field_publish_native_loaded_world(loaded.collection, loaded.trainer, world, position, tables)
	clocks = loaded.clocks; format_id = world.format
	view._playback.cancel(); view._medicine_popup.hide(); view.session = candidate; view.player = loaded.collection
	view._settlement_error = false; view._working = false
	view._z_toggle.set_pressed_no_signal(false); view._dynamax_toggle.set_pressed_no_signal(false)
	field.field_refresh_legacy_presentations()
	busy = false; kind = String(candidate.battle_kind) if candidate != null else ""
	if candidate != null:
		_show_battle(); view._event_log.text = "Combate recuperado."; view.diagnostic_event.emit({"event": "battle_opened"}); view._refresh_view()
	else: view.hide(); _unlock_world()
	notify("Partida recuperada.")
	return true


func _tables_for(config: Dictionary) -> Dictionary:
	return field.field_build_native_encounter_tables(config)


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
	var replacement := Session.new(field.field_definitions(), field.field_collection(), clocks, format_id, field.field_trainer_owner() if kind == "trainer" else null)
	var ok: bool = await replacement.restore_saved(get_tree(), old.snapshot())
	if ok:
		await old.close(); view.session = replacement; view.diagnostic_event.emit({"event": "battle_opened"})
	else: await replacement.close()
	busy = false; view._working = false; view._refresh_view()
	return ok


func _exit_tree() -> void:
	if view != null and view.session != null: view.session.stop_now()
