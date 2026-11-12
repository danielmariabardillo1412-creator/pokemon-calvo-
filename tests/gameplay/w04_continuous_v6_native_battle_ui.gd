extends SceneTree
# W04 V6: native Showdown battle -> actual Victory XP -> field presentation
# _settle -> visible GrowthChoices -> accept/decline -> current PlayerCollection.
const Overlay = preload("res://modules/creatures/progression/pokemon_variant_catalog.gd")
const Session = preload("res://modules/gameplay/field_native_session.gd")
const View = preload("res://scenes/visual/field_native_presentation.gd")
const CASES := [
    [&"diglett_alola", &"dugtrio_alola", 26],
    [&"meowth_galar", &"perrserker", 28],
]
var checks := 0
var errors: Array[String] = []
var accepted := 0
var declined := 0

func _initialize() -> void: call_deferred("_run")

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok: errors.append(label); push_error("W04_V6_NATIVE_FAIL " + label)

func create(catalog: DefinitionCatalog, id: StringName, level: int,
        name: StringName) -> CreatureInstance:
    var rng := RandomNumberGenerator.new()
    rng.seed = 20261112
    return CreatureFactory.create(catalog.species(id), level, catalog, ProgressionRuleset.new(), rng,
        {"instance_id": name, "nature_id": &"hardy", "moves": [&"quick_attack"]})

func one(catalog: DefinitionCatalog, source: StringName, target: StringName,
        min_level: int, accept: bool) -> void:
    var label := String(source) + ("_accept" if accept else "_decline")
    var rules := ProgressionRuleset.new()
    var owner := PlayerCollection.new()
    var mon := create(catalog, source, min_level - 1, StringName("w04_v6_native_" + label))
    check(mon != null and mon.form_id != &"", label + "_regional_mon")
    if mon == null: return
    # Still legally at level N-1, but within 1 EXP of required threshold.
    mon.experience = rules.experience_for_level(catalog.species(source).growth_rate, min_level) - 1
    # Native Showdown import currently checks stats against natal nature, not
    # minted nature (hardy -> adamant yields stat import mismatch). Keep the native
    # pilot honest; W02 mint preservation is tested in the independent consumer
    # suite, and the native stats discrepancy requires an IA6/W02 integration seam.
    mon.effective_nature_id = &"hardy"
    mon.recalculate_stats(catalog.species(source), rules)
    check(owner.party.add_creature(mon), label + "_added")
    var foe := create(catalog, &"caterpie", 50, StringName("w04_v6_foe_" + label))
    foe.current_hp = 1
    print("W04_V6_NATIVE_STAGE ", label, " session_new")
    var session := Session.new(catalog, owner, {}, "gen9calvounifiedv1")
    var opened: bool = await session.begin_wild(self, foe, [23, 19, 29, 43])
    check(opened, label + "_native_battle_opens_" + session.last_error)
    if not opened: await session.close(); return
    print("W04_V6_NATIVE_STAGE ", label, " opened")
    var view: Control = View.new()
    view.catalogs = catalog
    get_root().add_child(view)
    await process_frame
    view.session = session
    view.player = owner
    print("W04_V6_NATIVE_STAGE ", label, " submitting")
    check((await session.submit("move 1", session.revision)).get("accepted", false)
        and session.phase() == "finished", label + "_native_kill")
    if session.phase() != "finished":
        view.queue_free(); await session.close(); return
    check(mon.level == min_level - 1, label + "_xp_staged_before_settle")
    print("W04_V6_NATIVE_STAGE ", label, " settling")
    view._settle()
    print("W04_V6_NATIVE_STAGE ", label, " settled")
    check(session.completion_reason == "VICTORY" and mon.level == min_level,
        label + "_actual_post_battle_xp")
    check(view.has_pending_evolution_w04(), label + "_real_pending_choice")
    check(view._evolution_choices_w04.visible and view._continue_button.disabled,
        label + "_visible_ui_and_return_locked")
    check(owner.owned_creature(mon.instance_id) == mon, label + "_no_automatic_evolution")
    print("W04_V6_NATIVE_STAGE ", label, " deciding")
    if accept:
        view._evolution_choices_w04.chosen.emit(String(target))
        accepted += 1
    else:
        view._evolution_choices_w04.cancelled.emit()
        declined += 1
    var resulting: CreatureInstance = owner.owned_creature(mon.instance_id)
    check(not view.has_pending_evolution_w04(), label + "_prompt_consumed_once")
    check(resulting != null and resulting.species_id == (target if accept else source),
        label + "_decision_applied_to_owner")
    if resulting != null and accept:
        check(resulting.instance_id == mon.instance_id and resulting.form_id != mon.form_id,
            label + "_correct_form_not_inherited")
        check(resulting.effective_nature_id == &"hardy" and resulting.experience == mon.experience,
            label + "_effective_nature_and_exp")
    check(not session.settle_finished_battle().get("accepted", false),
        label + "_no_second_settlement")
    var path := "user://w04_v6_native_" + label + ".json"
    var repo := SaveGameRepository.new()
    check(repo.save_collection(path, owner).ok, label + "_save")
    var loaded := repo.load(path)
    check(loaded.ok, label + "_load")
    if loaded.ok and resulting != null:
        check(loaded.party.get_creature(mon.instance_id).to_dict() == resulting.to_dict(),
            label + "_savev2_identity")
    DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    print("W04_V6_NATIVE_STAGE ", label, " closing")
    view.queue_free()
    await session.close()
    print("W04_V6_NATIVE_STAGE ", label, " closed")

func _run() -> void:
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(Overlay.CANONICAL))
    check(parsed is Dictionary, "canonical")
    if not parsed is Dictionary: finish(); return
    var catalog: DefinitionCatalog = GameData.from_dict(parsed).to_definition_catalog()
    check(Overlay.apply(catalog), "overlay")
    for row in CASES:
        await one(catalog, row[0], row[1], row[2], true)
        await one(catalog, row[0], row[1], row[2], false)
    finish()

func finish() -> void:
    if errors.is_empty() and accepted == 2 and declined == 2:
        print("W04_V6_NATIVE PASS checks=", checks, " pilots=2 accepted=2 declined=2")
        quit(0)
    else:
        print("W04_V6_NATIVE FAIL errors=", JSON.stringify(errors))
        quit(1)
