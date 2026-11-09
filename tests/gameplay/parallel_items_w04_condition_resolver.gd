extends SceneTree
# Pure L2 resolver pilot: synthetic facts are injected ONLY in this unit runner.
# This is not evidence of world clock, persisted gender, full moon or evolution L3.
const Resolver = preload("res://modules/creatures/progression/evolution_condition_resolver_w04.gd")
var checks := 0
var errors: Array[String] = []
var done := false

func _initialize() -> void:
    call_deferred("_run")
    create_timer(180.0).timeout.connect(func():
        if not done:
            check(false, "watchdog")
            finish())

func check(value: bool, label: String) -> void:
    checks += 1
    if not value:
        errors.append(label)
        push_error(label)

func assert_result(record: EvolutionRecord, event: Dictionary, facts: Dictionary,
        expected: bool, reason: String, label: String) -> void:
    var record_before := record.to_dict()
    var event_before := event.duplicate(true)
    var facts_before := facts.duplicate(true)
    var result: Dictionary = Resolver.evaluate(record, event, facts)
    check(result.get("eligible", not expected) == expected and
        result.get("reason", "") == reason and
        result.get("scope", "") == "RESOLVER_ONLY" and
        result.get("mutates", true) == false, label + "/result")
    check(record.to_dict() == record_before and event == event_before and facts == facts_before,
        label + "/pure_no_mutation")

func _record(catalog: DefinitionCatalog, source: StringName, target: StringName,
        trigger: StringName, item_id: StringName) -> EvolutionRecord:
    var species: CreatureSpecies = catalog.species(source)
    check(species != null, String(source) + "/source_exists")
    if species == null:
        return null
    var found: EvolutionRecord = null
    var count := 0
    for record: EvolutionRecord in species.evolutions:
        if record.species_id != target or record.trigger != trigger:
            continue
        if trigger == &"use_item" and record.item_id != item_id:
            continue
        if trigger == &"level_up" and StringName(str(record.conditions.get("held_item", ""))) != item_id:
            continue
        found = record
        count += 1
    check(count == 1 and found != null, String(source) + "/one_canonical_record")
    if found != null:
        check(EvolutionSystem.classify_record(found, catalog, source) == EvolutionSystem.DATA_ONLY,
            String(source) + "/still_data_only_in_production")
    return found

func _probe(catalog: DefinitionCatalog) -> void:
    var oval := _record(catalog, &"happiny", &"chansey", &"level_up", &"oval_stone")
    var kirlia := _record(catalog, &"kirlia", &"gallade", &"use_item", &"dawn_stone")
    var snorunt := _record(catalog, &"snorunt", &"froslass", &"use_item", &"dawn_stone")
    var peat := _record(catalog, &"ursaring", &"ursaluna", &"use_item", &"peat_block")
    if oval == null or kirlia == null or snorunt == null or peat == null:
        return
    check(oval.conditions.has("held_item") and oval.conditions.has("time_of_day")
        and String(oval.conditions["held_item"]) == "oval_stone"
        and String(oval.conditions["time_of_day"]) == "day", "oval/canonical_held_day")
    check(kirlia.conditions.get("gender") == 2 and snorunt.conditions.get("gender") == 1,
        "dawn/canonical_male_female")
    check(String(peat.conditions.get("time_of_day", "")).replace("-", "_") == "full_moon",
        "peat/canonical_full_moon")
    var use_dawn := {"trigger": "use_item", "item_id": "dawn_stone"}
    var use_peat := {"trigger": "use_item", "item_id": "peat_block"}
    # 39->40 below is a test of the transition interface, NOT a chosen
    # minimum level for Happiny or any item evolution.
    var level_up := {"trigger": "level_up", "previous_level": 39, "new_level": 40}
    var facts_oval := {"held_item_id": "oval_stone", "held_item_consumed": false, "daypart": "day"}
    var facts_male := {"gender": 2}
    var facts_female := {"gender": 1}
    var facts_full := {"moon_phase": "full"}

    assert_result(oval, level_up, facts_oval, true, "conditions_match", "oval/held_day_on_actual_level_event")
    assert_result(kirlia, use_dawn, facts_male, true, "conditions_match", "dawn/kirlia_male")
    assert_result(snorunt, use_dawn, facts_female, true, "conditions_match", "dawn/snorunt_female")
    assert_result(peat, use_peat, facts_full, true, "conditions_match", "peat/full_moon")

    # Positive checks do NOT turn into actual evolution candidates or spend items.
    check(EvolutionSystem.evolution_candidates(catalog.species(&"happiny"),
        {"level": 40, "held_item_id": &"oval_stone", "time_of_day": "day"}, catalog).is_empty(),
        "oval/production_evolution_not_connected")
    check(EvolutionSystem.evolution_candidates(catalog.species(&"kirlia"),
        {"item_id": &"dawn_stone", "gender": 2}, catalog).is_empty(),
        "dawn/production_evolution_not_connected")
    check(EvolutionSystem.evolution_candidates(catalog.species(&"ursaring"),
        {"item_id": &"peat_block", "moon_phase": "full"}, catalog).is_empty(),
        "peat/production_evolution_not_connected")

    assert_result(oval, level_up, {}, false, "wrong_held_item", "oval/no_held")
    assert_result(oval, level_up, {"held_item_id": "other", "daypart": "day"},
        false, "wrong_held_item", "oval/wrong_held")
    assert_result(oval, level_up, {"held_item_id": "oval_stone", "held_item_consumed": true, "daypart": "day"},
        false, "held_item_already_consumed", "oval/consumed_held")
    assert_result(oval, level_up, {"held_item_id": "oval_stone", "held_item_consumed": false},
        false, "missing_world_daypart", "oval/day_missing")
    assert_result(oval, level_up, {"held_item_id": "oval_stone", "daypart": "day"},
        false, "missing_held_consumed_state", "oval/held_consumption_unverified")
    assert_result(oval, level_up, {"held_item_id": "oval_stone", "held_item_consumed": false, "daypart": "night"},
        false, "wrong_world_daypart", "oval/night")
    assert_result(oval, level_up, {"held_item_id": "oval_stone", "held_item_consumed": false, "daypart": "full_moon"},
        false, "wrong_world_daypart", "oval/moon_not_day")
    assert_result(oval, {"trigger": "use_item", "item_id": "oval_stone"}, facts_oval,
        false, "wrong_trigger", "oval/bag_is_not_level_up")
    assert_result(oval, {"trigger": "level_up"}, facts_oval,
        false, "missing_level_transition", "oval/no_transition")
    assert_result(oval, {"trigger": "level_up", "previous_level": 40, "new_level": 40}, facts_oval,
        false, "invalid_level_transition", "oval/no_actual_gain")
    assert_result(oval, {"trigger": "level_up", "previous_level": 40, "new_level": 39}, facts_oval,
        false, "invalid_level_transition", "oval/reversed_level")
    assert_result(oval, {"trigger": "level_up", "previous_level": "39", "new_level": 40}, facts_oval,
        false, "invalid_level_transition", "oval/invalid_level_type")
    assert_result(oval, {"trigger": "level_up", "previous_level": 99, "new_level": 101}, facts_oval,
        false, "invalid_level_transition", "oval/above_level_cap")

    assert_result(kirlia, use_dawn, {}, false, "missing_individual_gender", "dawn/kirlia_unknown_gender")
    assert_result(kirlia, use_dawn, facts_female, false, "wrong_gender", "dawn/kirlia_female")
    assert_result(kirlia, use_dawn, {"gender": "2"}, false, "missing_individual_gender", "dawn/no_string_gender")
    assert_result(kirlia, use_dawn, {"gender": 0}, false, "wrong_gender", "dawn/unknown_enum")
    assert_result(kirlia, {"trigger": "use_item", "item_id": "other"}, facts_male,
        false, "wrong_item", "dawn/wrong_item")
    assert_result(kirlia, {"trigger": "level_up", "previous_level": 39, "new_level": 40},
        facts_male, false, "wrong_trigger", "dawn/not_on_level_up")
    assert_result(snorunt, use_dawn, {}, false, "missing_individual_gender", "dawn/snorunt_unknown_gender")
    assert_result(snorunt, use_dawn, facts_male, false, "wrong_gender", "dawn/snorunt_male")
    assert_result(snorunt, {"trigger": "use_item"}, facts_female,
        false, "wrong_item", "dawn/snorunt_no_item")

    assert_result(peat, use_peat, {}, false, "missing_world_moon_phase", "peat/no_moon_source")
    assert_result(peat, use_peat, {"daypart": "night"}, false, "missing_world_moon_phase", "peat/night_not_moon")
    assert_result(peat, use_peat, {"moon_phase": "not_full"}, false, "not_full_moon", "peat/not_full")
    assert_result(peat, use_peat, {"moon_phase": "FULL"}, false, "not_full_moon", "peat/no_fake_enum")
    assert_result(peat, {"trigger": "use_item", "item_id": "other"}, facts_full,
        false, "wrong_item", "peat/wrong_item")
    assert_result(peat, {"trigger": "level_up", "previous_level": 40, "new_level": 41}, facts_full,
        false, "wrong_trigger", "peat/not_level_up")

    var foreign := EvolutionRecord.new(&"gallade", 0, &"use_item", &"dawn_stone",
        &"", true, {"gender": 2, "friendship": 220})
    assert_result(foreign, use_dawn, facts_male, false, "unsupported_condition", "guard/unknown_extra_condition")
    var trade := EvolutionRecord.new(&"kingdra", 0, &"trade", &"", &"", true, {"held_item": "dragon_scale"})
    assert_result(trade, {"trigger": "trade"}, {"held_item_id": "dragon_scale"}, false,
        "unsupported_trigger", "guard/no_trade_level_shortcut")
    var plain := EvolutionRecord.new(&"gallade", 0, &"use_item", &"dawn_stone")
    assert_result(plain, use_dawn, facts_male, false, "not_conditional_route", "guard/not_unconditional_fallback")
    var invalid := Resolver.evaluate(null, use_dawn, facts_male)
    check(not invalid.get("eligible", true) and invalid.get("reason") == "invalid_record",
        "guard/null_record_fails_closed")

    print("CAMP006_W04_CONDITION_RESOLVER cases=4 positives=4 status=PURE_L2_NOT_GAMEPLAY_L3 completed=3 last_executed=06 deferred=04")

func _run() -> void:
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(
        "res://data/normalized/pokemon_api.json"))
    check(parsed is Dictionary, "normalized_pokemon_api_available")
    if parsed is Dictionary:
        var catalog: DefinitionCatalog = GameData.from_dict(parsed).to_definition_catalog()
        check(catalog != null, "real_definition_catalog")
        if catalog != null:
            _probe(catalog)
    finish()

func finish() -> void:
    if done:
        return
    done = true
    if errors.is_empty():
        print("CAMP006_W04_RESOLVER_L2 PASS completed=3 last_executed=06 deferred=04 checks=", checks)
    else:
        print("CAMP006_W04_RESOLVER_L2 FAIL errors=", JSON.stringify(errors))
    quit(0 if errors.is_empty() else 1)
