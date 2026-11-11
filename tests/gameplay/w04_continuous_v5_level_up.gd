extends SceneTree
# W04 V5: actual ProgressionSystem gain_experience -> EVOLUTION_AVAILABLE ->
# ProgressionSystem.apply_evolution, Party/Storage replacement, SaveV2.
const Overlay = preload("res://modules/creatures/progression/pokemon_variant_catalog.gd")
const Canonical = preload("res://modules/creatures/progression/canonical_form_identity_w04.gd")
const ROUTES := [
    [&"diglett_alola", &"dugtrio_alola", 26],
    [&"geodude_alola", &"graveler_alola", 25],
    [&"grimer_alola", &"muk_alola", 38],
    [&"meowth_galar", &"perrserker", 28],
    [&"ponyta_galar", &"rapidash_galar", 40],
    [&"mr_mime_galar", &"mr_rime", 42],
    [&"corsola_galar", &"cursola", 38],
    [&"zigzagoon_galar", &"linoone_galar", 20],
    [&"zorua_hisui", &"zoroark_hisui", 30],
    [&"wooper_paldea", &"clodsire", 20],
]
var checks := 0
var failures: Array[String] = []
var events_found := 0
var persisted := 0

func _initialize() -> void: call_deferred("_run")

func check(ok: bool, tag: String) -> void:
    checks += 1
    if not ok:
        failures.append(tag)
        push_error("W04_V5_FAIL " + tag)

func make_mon(catalog: DefinitionCatalog, source: StringName, id: StringName,
        level: int, rules: ProgressionRuleset) -> CreatureInstance:
    var rng := RandomNumberGenerator.new()
    rng.seed = 14122026
    return CreatureFactory.create(catalog.species(source), level, catalog, rules, rng,
        {"instance_id": id, "nature_id": &"hardy", "moves": [&"tackle"]})

func evo_event(events: Array, target: StringName) -> ProgressionEvent:
    for ev in events:
        if ev.kind == ProgressionEvent.EVOLUTION_AVAILABLE and StringName(ev.data.get("species_id", "")) == target:
            return ev
    return null

func expected_form(catalog: DefinitionCatalog, target: StringName) -> StringName:
    if not Canonical.SOURCES.has(String(target)):
        return &""
    return Canonical.from_factory_source(catalog.species(target), catalog)

func run_one(catalog: DefinitionCatalog, source: StringName, target: StringName,
        minimum: int, stored: bool) -> void:
    var tag := String(source) + ("_storage" if stored else "_party")
    var rules := ProgressionRuleset.new()
    var spec := catalog.species(source)
    check(spec != null and catalog.species(target) != null, tag + "_species")
    if spec == null or catalog.species(target) == null: return
    var rec_found := false
    for rec: EvolutionRecord in spec.evolutions:
        if rec.trigger == &"level_up" and rec.species_id == target and rec.min_level == minimum and rec.conditions.is_empty():
            rec_found = true
    check(rec_found, tag + "_record_unconditional")
    var owner := PlayerCollection.new()
    var mon := make_mon(catalog, source, StringName("w04_v5_" + tag), minimum - 1, rules)
    check(mon != null and mon.form_id != &"", tag + "_regional_source")
    if mon == null: return
    mon.effective_nature_id = &"adamant"
    mon.recalculate_stats(spec, rules)
    if not mon.moveset.is_empty():
        mon.moveset[0].current_pp = maxi(0, mon.moveset[0].max_pp - 2)
    check(owner.party.add_creature(mon), tag + "_party_added")
    if stored: check(owner.deposit(mon.instance_id), tag + "_stored")
    check(EvolutionSystem.evolution_candidates(spec, EvolutionSystem.level_up_context(mon), catalog).is_empty(),
        tag + "_below_threshold")
    var before_level := mon.level
    var required := rules.experience_for_level(spec.growth_rate, minimum) - mon.experience
    check(required > 0, tag + "_positive_real_xp")
    var events := ProgressionSystem.gain_experience(mon, required, spec, catalog, rules)
    check(mon.level == minimum and mon.level > before_level, tag + "_real_level_up")
    var ev := evo_event(events, target)
    check(ev != null, tag + "_available_event")
    if ev == null: return
    events_found += 1
    var before := mon.to_dict()
    var evolved := ProgressionSystem.apply_evolution(mon, ev, catalog, rules)
    check(evolved != null and evolved.instance_id == mon.instance_id and evolved.species_id == target,
        tag + "_authentic_apply")
    if evolved == null: return
    var canonical := expected_form(catalog, target)
    check(evolved.form_id == canonical and (canonical != &"" or not Canonical.SOURCES.has(String(target))),
        tag + "_destination_form")
    check(evolved.form_id != mon.form_id, tag + "_not_inherit_source_form")
    check(evolved.effective_nature_id == mon.effective_nature_id
        and evolved.nature_id == mon.nature_id and evolved.ivs == mon.ivs and evolved.evs == mon.evs
        and evolved.experience == mon.experience, tag + "_progression_preserved")
    check(evolved.to_dict().get("moveset", []) == before.get("moveset", []),
        tag + "_pp_preserved")
    check(evolved.stats.to_dict() == StatCalculator.compute(catalog.species(target).base_stat_block(),
        evolved.ivs, evolved.evs, evolved.effective_nature_id, evolved.level).to_dict(),
        tag + "_effective_stats")
    check(owner.replace_owned_same_identity(evolved), tag + "_actual_owner_replace")
    check(owner.owned_creature(mon.instance_id) == evolved
        and owner.location_of(mon.instance_id) == (&"STORAGE" if stored else &"PARTY"),
        tag + "_location_preserved")
    var path := "user://w04_v5_" + tag + ".json"
    var repo := SaveGameRepository.new()
    check(repo.save_collection(path, owner).ok, tag + "_save")
    var restored := repo.load(path)
    check(restored.ok, tag + "_load")
    if restored.ok:
        var saved: CreatureInstance = restored.storage.get_creature(mon.instance_id) if stored else restored.party.get_creature(mon.instance_id)
        check(saved != null and saved.to_dict() == evolved.to_dict(), tag + "_savev2_roundtrip")
        persisted += 1
    DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func run_everstone(catalog: DefinitionCatalog, source: StringName, target: StringName, threshold: int) -> void:
    var rules := ProgressionRuleset.new()
    var spec := catalog.species(source)
    var mon := make_mon(catalog, source, StringName("w04_v5_everstone_" + String(source)), threshold - 1, rules)
    mon.held_item_id = &"everstone"
    var required := rules.experience_for_level(spec.growth_rate, threshold) - mon.experience
    var events := ProgressionSystem.gain_experience(mon, required, spec, catalog, rules)
    check(mon.level == threshold and evo_event(events, target) == null,
        String(source) + "_everstone_prevents_event")

func run_negative_records(catalog: DefinitionCatalog) -> void:
    var excluded := [&"rattata_alola", &"meowth_alola", &"linoone_galar", &"qwilfish_hisui",
        &"sneasel_hisui", &"sliggoo_hisui"]
    for id in excluded:
        var species := catalog.species(id)
        check(species != null, String(id) + "_conditional_species")
        if species == null: continue
        for rec: EvolutionRecord in species.evolutions:
            if rec.trigger != &"level_up": continue
            check(not rec.conditions.is_empty() and EvolutionSystem.classify_record(rec, catalog, id) == EvolutionSystem.DATA_ONLY,
                String(id) + "_condition_not_simplified")
            var mon := make_mon(catalog, id, StringName("w04_v5_cond_" + String(id)), maxi(1, rec.min_level), ProgressionRuleset.new())
            check(EvolutionSystem.evolution_candidates(species, EvolutionSystem.level_up_context(mon), catalog).is_empty(),
                String(id) + "_condition_not_available")

func _run() -> void:
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(Overlay.CANONICAL))
    check(parsed is Dictionary, "canonical")
    if not parsed is Dictionary: finish(); return
    var catalog: DefinitionCatalog = GameData.from_dict(parsed).to_definition_catalog()
    check(Overlay.apply(catalog), "regional_overlay")
    for row in ROUTES:
        run_one(catalog, row[0], row[1], row[2], false)
        run_one(catalog, row[0], row[1], row[2], true)
        run_everstone(catalog, row[0], row[1], row[2])
    run_negative_records(catalog)
    print("W04_V5_RESULT routes=10 events=", events_found, " saved=", persisted, " checks=", checks)
    finish()

func finish() -> void:
    if failures.is_empty() and events_found == 20 and persisted == 20:
        print("W04_V5 PASS checks=", checks, " routes=10 owners=20")
        quit(0)
    else:
        print("W04_V5 FAIL errors=", JSON.stringify(failures))
        quit(1)
