extends SceneTree
# IA4 W04 CAMP006 block06, pure Milcery predicate unit tests.
# Every spin event here is SYNTHETIC test input, NOT gameplay evidence.
const Resolver = preload("res://modules/creatures/progression/milcery_spin_resolver_w04.gd")
var checks := 0
var errors: Array[String] = []
var closed := false

func _initialize() -> void:
    call_deferred("_run")
    create_timer(180.0).timeout.connect(func():
        if not closed:
            check(false, "watchdog")
            finish())

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        errors.append(label)
        push_error(label)

func check_inspect(
    record: EvolutionRecord,
    held_item_id: StringName,
    spin_event: Dictionary,
    canonical_forms: Array,
    expected_ok: bool,
    expected_reason: String,
    label: String,
    source_id: StringName = &"milcery",
    consumed: bool = false,
) -> void:
    var initial_record: Dictionary = record.to_dict()
    var initial_event: Dictionary = spin_event.duplicate(true)
    var initial_forms: Array = canonical_forms.duplicate(true)
    var result: Dictionary = Resolver.inspect(
        record, source_id, held_item_id, consumed, spin_event, canonical_forms)
    check(result.get("preconditions_valid") == expected_ok and
        result.get("reason") == expected_reason and
        result.get("evolution_ready") == false and
        result.get("scope") == "PURE_SPIN_PRECONDITIONS_ONLY" and
        result.get("mutates") == false, label + "/semantic_result")
    check(record.to_dict() == initial_record and spin_event == initial_event and
        canonical_forms == initial_forms, label + "/immutable_input")

func _run() -> void:
    var api: Variant = JSON.parse_string(
        FileAccess.get_file_as_string("res://data/api/v2/pokemon/869/index.json"))
    var normalized: Variant = JSON.parse_string(
        FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))
    check(api is Dictionary and normalized is Dictionary, "PokeAPI_resources_present")
    if not (api is Dictionary and normalized is Dictionary):
        finish()
        return
    var catalog: DefinitionCatalog = GameData.from_dict(normalized).to_definition_catalog()
    check(catalog != null and catalog.species(&"milcery") != null and
        catalog.species(&"alcremie") != null, "canonical_species_available")
    if catalog == null or catalog.species(&"milcery") == null:
        finish()
        return
    var actual: Array = []
    for ev: EvolutionRecord in catalog.species(&"milcery").evolutions:
        if ev.species_id == &"alcremie" and ev.trigger == &"spin":
            actual.append(ev)
    check(actual.size() == 1, "single_real_Milcery_to_Alcremie_spin")
    if actual.size() != 1:
        finish()
        return
    var record: EvolutionRecord = actual[0]
    check(record.item_id == &"" and record.conditions.is_empty() and
        record.min_level == 0 and String(record.version_group) == "sword_shield",
        "spin_original_has_no_item_no_level_or_embedded_cream_rule")
    check(EvolutionSystem.classify_record(record, catalog, &"milcery") ==
        EvolutionSystem.UNSUPPORTED, "spin_unsupported_in_live_evolution_system")
    var form_rows: Array = api.get("forms", [])
    var form_names: Array = []
    for row: Dictionary in form_rows:
        form_names.append(String(row.get("name", "")))
    check(form_names.size() == 63 and form_names.size() ==
        form_names.duplicate().size(), "canonical_63_Alcremie_forms")
    var unique_forms: Dictionary = {}
    for name: String in form_names:
        unique_forms[name] = true
    check(unique_forms.size() == 63, "canonical_forms_distinct")
    var sweets := [
        &"berry_sweet", &"clover_sweet", &"flower_sweet", &"love_sweet",
        &"ribbon_sweet", &"star_sweet", &"strawberry_sweet",
    ]
    var spin := {
        "trigger": "spin", "completed": true, "direction": "clockwise",
        "duration_ms": 1250, "world_daypart": "day",
    }
    # 1250 ms is a synthetic TEST FIXTURE, NOT a gameplay threshold or formula.
    var total_candidates := 0
    for sweet: StringName in sweets:
        var compatible: Array = Resolver.candidate_forms(sweet, form_names)
        check(compatible.size() == 9, String(sweet) + "/nine_real_forms")
        for name: String in compatible:
            check(unique_forms.has(name) and
                name.ends_with("-" + String(sweet).replace("_", "-")),
                String(sweet) + "/real_form_matches_held_sweet")
        total_candidates += compatible.size()
        check_inspect(record, sweet, spin, form_names, true,
            "authoritative_cream_selection_missing", String(sweet) + "/valid_test_preconditions")
        var info: Dictionary = Resolver.inspect(record, &"milcery", sweet,
            false, spin, form_names)
        check(not info["evolution_ready"] and
            info["candidate_forms"].size() == 9, String(sweet) + "/never_permission_to_evolve")
        var chosen: String = compatible[0]
        var candidate: Dictionary = Resolver.validate_candidate(chosen, sweet, form_names)
        check(candidate.get("candidate_valid") == true and
            candidate.get("evolution_ready") == false and
            candidate.get("reason") == "authoritative_cream_selection_missing" and
            candidate.get("form_id") == chosen,
            String(sweet) + "/form_name_valid_NOT_selected_by_spin")
        var other_sweet: StringName = &"love_sweet" if sweet != &"love_sweet" else &"berry_sweet"
        var wrong: Dictionary = Resolver.validate_candidate(chosen, other_sweet, form_names)
        check(wrong.get("reason") == "form_sweet_mismatch" and
            wrong.get("evolution_ready") == false,
            String(sweet) + "/reject_wrong_sweet_decoration")
    check(total_candidates == 63, "all_seven_sweets_have_9_variants_each")
    var example: StringName = &"berry_sweet"
    check_inspect(record, example, {}, form_names, false, "not_spin_event",
        "negative/no_trigger")
    check_inspect(record, example, {"trigger": "use_item"}, form_names, false, "not_spin_event",
        "negative/bag_use_is_not_spin")
    check_inspect(record, example, {"trigger": "spin", "completed": false}, form_names,
        false, "spin_not_completed", "negative/incomplete_spin")
    check_inspect(record, example, {"trigger": "spin", "completed": "true"}, form_names,
        false, "spin_not_completed", "negative/untyped_completion")
    check_inspect(record, example, {"trigger": "spin", "completed": true}, form_names,
        false, "missing_spin_direction", "negative/no_direction")
    check_inspect(record, example, {"trigger": "spin", "completed": true,
        "direction": "up"}, form_names, false, "missing_spin_direction",
        "negative/bad_direction")
    check_inspect(record, example, {"trigger": "spin", "completed": true,
        "direction": "clockwise"}, form_names, false, "missing_spin_duration",
        "negative/no_duration")
    check_inspect(record, example, {"trigger": "spin", "completed": true,
        "direction": "clockwise", "duration_ms": 0}, form_names, false,
        "missing_spin_duration", "negative/zero_duration")
    check_inspect(record, example, {"trigger": "spin", "completed": true,
        "direction": "clockwise", "duration_ms": 1250}, form_names, false,
        "missing_world_daypart", "negative/no_daypart")
    check_inspect(record, example, {"trigger": "spin", "completed": true,
        "direction": "clockwise", "duration_ms": 1250, "world_daypart": "full_moon"}, form_names,
        false, "missing_world_daypart", "negative/moon_not_daypart")
    check_inspect(record, example, spin, form_names, false,
        "wrong_evolution_route", "negative/not_Milcery", &"eevee")
    check_inspect(record, &"oval_stone", spin, form_names, false,
        "missing_or_invalid_held_sweet", "negative/wrong_held_item")
    check_inspect(record, example, spin, form_names, false,
        "held_sweet_already_consumed", "negative/already_consumed", &"milcery", true)
    check_inspect(record, example, spin, [], false,
        "canonical_form_catalog_incomplete", "negative/no_canonical_forms")
    var dup_forms := form_names.duplicate()
    dup_forms.append(Resolver.candidate_forms(example, form_names)[0])
    check_inspect(record, example, spin, dup_forms, false,
        "canonical_form_catalog_incomplete", "negative/duplicated_real_form")
    var different: EvolutionRecord = EvolutionRecord.new(
        &"alcremie", 0, &"use_item", &"berry_sweet")
    check_inspect(different, example, spin, form_names, false,
        "record_not_canonical_spin", "negative/not_use_item")
    var invented: EvolutionRecord = EvolutionRecord.new(
        &"alcremie", 0, &"spin", &"", &"", true, {"night_only": true})
    check_inspect(invented, example, spin, form_names, false,
        "record_not_canonical_spin", "negative/no_unknown_rules")
    var bogus: Dictionary = Resolver.validate_candidate(
        "alcremie-not-a-real-cream-berry-sweet", example, form_names)
    check(bogus.get("reason") == "form_not_in_canonical_catalog" and
        bogus.get("evolution_ready") == false, "negative/reject_invented_form")
    var no_form: Dictionary = Resolver.validate_candidate("", example, form_names)
    check(no_form.get("reason") == "invalid_form_or_sweet" and
        no_form.get("evolution_ready") == false, "negative/reject_empty_form")
    # An even successful test predicate does not mutate or authorize evolution.
    check(EvolutionSystem.evolution_candidates(catalog.species(&"milcery"),
        {"trigger": "spin", "item_id": &"berry_sweet"}, catalog).is_empty(),
        "not_connected_to_live_gameplay")
    print("CAMP006_W04_MILCERY_RESOLVER sweets=7 canonical_forms=63 pure_precondition_positives=7 status=NOT_L3 completed=3 deferred=04 blocked=05,06")
    finish()

func finish() -> void:
    if closed:
        return
    closed = true
    if errors.is_empty():
        print("CAMP006_W04_MILCERY_L2 PASS completed=3 last_executed=06 deferred=04 blocked=05,06 checks=", checks)
    else:
        print("CAMP006_W04_MILCERY_L2 FAIL errors=", JSON.stringify(errors))
    quit(0 if errors.is_empty() else 1)
