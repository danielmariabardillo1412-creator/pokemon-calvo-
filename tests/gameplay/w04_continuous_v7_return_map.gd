extends SceneTree
# W04 V7 genuine field demo -> native battle -> XP evolution choice ->
# FieldNativeBridge.leave_battle -> movement restored -> SaveV2 -> second battle.
const SCENE = preload("res://scenes/visual/field_demo.tscn")
const ROUTES := [
    [&"diglett_alola", &"dugtrio_alola", 26, true],
    [&"meowth_galar", &"perrserker", 28, false],
]
var errors: Array[String] = []
var checks := 0
var closed := 0

func _initialize() -> void: call_deferred("_run")

func check(ok: bool, name: String) -> void:
    checks += 1
    if not ok: errors.append(name); push_error("W04_V7_MAP_FAIL " + name)

func _mon(catalog: DefinitionCatalog, sid: StringName, lvl: int,
        id: StringName) -> CreatureInstance:
    var rng := RandomNumberGenerator.new()
    rng.seed = 20261112
    var mon := CreatureFactory.create(catalog.species(sid), lvl, catalog,
        ProgressionRuleset.new(), rng,
        {"instance_id": id, "nature_id": &"hardy", "moves": [&"quick_attack"]})
    mon.experience = ProgressionRuleset.new().experience_for_level(
        catalog.species(sid).growth_rate, lvl + 1) - 1
    return mon

func _closed_count(scene: Node) -> int:
    var count := 0
    for row in scene._recorder._entries:
        if row.get("category", "") == "native" and row.get("event", "") == "battle_closed":
            count += 1
    return count

func _cycle(scene: Node, sid: StringName, target: StringName,
        level: int, accept: bool) -> void:
    var tag := String(sid) + ("_accept" if accept else "_decline")
    print("W04_V7_MAP_STAGE ", tag, " set_owner")
    var owner: PlayerCollection = scene.field_collection()
    var id: StringName = owner.party.get_creatures()[0].instance_id
    var candidate := _mon(scene.field_definitions(), sid, level - 1, id)
    check(candidate != null and candidate.form_id != &"", tag + "_regional_owner")
    if candidate == null: return
    check(owner.replace_owned_same_identity(candidate), tag + "_replace_owner")
    var bridge: Node = scene._native_battles
    check(bridge != null and scene.field_player_movement_enabled(), tag + "_ready_map")
    print("W04_V7_MAP_STAGE ", tag, " trigger_step")
    scene.player.global_position = Vector2(420, 150)
    await scene._on_player_step_completed(scene.player.global_position)
    var view: Control = bridge.view
    check(view.visible and view.session != null and view.session.has_active_battle(),
        tag + "_native_battle_open")
    if not view.visible or view.session == null or not view.session.has_active_battle(): return
    view._playback.set_process(false)
    print("W04_V7_MAP_STAGE ", tag, " native_attack")
    var attack: Dictionary = await view.choose("move 1")
    check(bool(attack.get("accepted", false)), tag + "_attack_accepted")
    for frame in 2000:
        if not view._playback.is_playing(): break
        view._playback.advance(0.25)
    await process_frame
    await process_frame
    if view.session.completion_reason.is_empty() and view.session.phase() == "finished":
        view._settle()
    check(view.session.completion_reason == "VICTORY", tag + "_victory_settled")
    check(view.has_pending_evolution_w04() and view._evolution_choices_w04.visible,
        tag + "_choice_presented")
    check(not scene.field_player_movement_enabled() and not bridge.save_game(),
        tag + "_pending_world_locked_and_no_save")
    check(_closed_count(scene) == closed, tag + "_no_premature_closed_event")
    if not view.has_pending_evolution_w04(): return
    if accept: view._evolution_choices_w04.chosen.emit(String(target))
    else: view._evolution_choices_w04.cancelled.emit()
    var current: CreatureInstance = scene.field_collection().owned_creature(id)
    check(not view.has_pending_evolution_w04(), tag + "_decision_consumed_once")
    check(current != null and current.species_id == (target if accept else sid),
        tag + "_owner_post_decision")
    print("W04_V7_MAP_STAGE ", tag, " leave_battle")
    await bridge.leave_battle()
    print("W04_V7_MAP_STAGE ", tag, " returned_to_map")
    check(not bridge.busy and not view.visible and bridge.kind == "",
        tag + "_bridge_cleared_and_view_hidden")
    check(scene.field_player_movement_enabled(), tag + "_movement_restored")
    closed += 1
    check(_closed_count(scene) == closed, tag + "_battle_closed_exactly_once")
    check(bridge.save_game(), tag + "_save_after_return")
    check(await bridge.load_game(), tag + "_load_after_return")
    var saved: CreatureInstance = scene.field_collection().owned_creature(id)
    check(saved != null and current != null and saved.to_dict() == current.to_dict(),
        tag + "_savev2_identity_form_roundtrip")
    check(not bridge.busy and not bridge.view.visible and scene.field_player_movement_enabled(),
        tag + "_return_after_load")
    print("W04_V7_MAP_STAGE ", tag, " complete")

func _run() -> void:
    var scene: Node = SCENE.instantiate()
    get_root().add_child(scene)
    await process_frame
    await physics_frame
    check(scene.is_demo_ready(), "map_booted")
    var config: Dictionary = scene._active_config.duplicate(true)
    config["encounter_chance_percent"] = 100
    config["wild_species_id"] = "caterpie"
    config["wild_min_level"] = 1
    config["wild_max_level"] = 1
    scene._on_configuration_applied(config)
    scene._native_battles.save_path = "user://w04_v7_return_map.json"
    for row in ROUTES:
        await _cycle(scene, row[0], row[1], row[2], row[3])
    DirAccess.remove_absolute(ProjectSettings.globalize_path(
        scene._native_battles.save_path))
    scene.queue_free()
    await process_frame
    if errors.is_empty() and closed == 2:
        print("W04_V7_MAP PASS checks=", checks, " cycles=2 closed=2")
        quit(0)
    else:
        print("W04_V7_MAP FAIL errors=", JSON.stringify(errors), " closed=", closed)
        quit(1)
