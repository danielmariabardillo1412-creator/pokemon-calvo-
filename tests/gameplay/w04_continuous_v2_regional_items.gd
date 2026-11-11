extends SceneTree
# W04 CONTINUOUS V2 B02. Tests pure contracts, NEVER item consumption.
const Overlay = preload("res://modules/creatures/progression/pokemon_variant_catalog.gd")
const Contract = preload("res://modules/creatures/progression/regional_item_evolution_contract_w04_v2.gd")
const ROUTES := [
    [&"darumaka_galar", &"ice_stone", &"darmanitan_galar_standard"],
    [&"growlithe_hisui", &"fire_stone", &"arcanine_hisui"],
    [&"sandshrew_alola", &"ice_stone", &"sandslash_alola"],
    [&"slowpoke_galar", &"galarica_cuff", &"slowbro_galar"],
    [&"slowpoke_galar", &"galarica_wreath", &"slowking_galar"],
    [&"voltorb_hisui", &"leaf_stone", &"electrode_hisui"],
    [&"vulpix_alola", &"ice_stone", &"ninetales_alola"],
]
var failures: Array[String] = []
var checks := 0
var positive := 0
var blocked := 0

func _initialize() -> void:
    call_deferred("_run")

func check(value: bool, name: String) -> void:
    checks += 1
    if not value:
        failures.append(name)
        push_error("W04_V2_B02_FAIL " + name)

func make_mon(catalog: DefinitionCatalog, species_id: StringName, uid: StringName) -> CreatureInstance:
    var rng := RandomNumberGenerator.new()
    rng.seed = 20261111
    return CreatureFactory.create(catalog.species(species_id), 30, catalog, ProgressionRuleset.new(), rng,
        {"instance_id": uid, "nature_id": &"hardy", "moves": [&"tackle"]})

func _run() -> void:
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(Overlay.CANONICAL))
    check(parsed is Dictionary, "canonical_data")
    if not (parsed is Dictionary):
        finish()
        return
    var catalog: DefinitionCatalog = GameData.from_dict(parsed).to_definition_catalog()
    check(Overlay.apply(catalog), "regional_overlay")
    for route in ROUTES:
        var origin: StringName = route[0]
        var item: StringName = route[1]
        var target: StringName = route[2]
        var source := make_mon(catalog, origin, StringName("w04_v2_" + String(origin)))
        var before: Dictionary = source.to_dict()
        var tag := String(origin) + "_" + String(item)
        var result: Dictionary = Contract.inspect(source, item, catalog, target)
        if catalog.item_catalog.has(item):
            check(bool(result.get("ok", false)), tag + "_L2_positive")
            if bool(result.get("ok", false)):
                positive += 1
                check(StringName(result.get("target_species_id", "")) == target,
                    tag + "_target_species")
                var dest := make_mon(catalog, target, StringName("dest_" + tag))
                check(StringName(result.get("target_form_id", "")) == dest.form_id
                    and dest.form_id != &"" and dest.form_id != source.form_id,
                    tag + "_target_form")
                check(result.get("status", "") == "L2_CONTRACT_ONLY", tag + "_no_L3_claim")
        else:
            blocked += 1
            check(not bool(result.get("ok", false))
                and result.get("reason", "") == "item_missing_from_catalog", tag + "_missing_item_block")
        check(not Contract.inspect(source, &"potion", catalog).get("ok", false), tag + "_wrong_item")
        check(not Contract.inspect(source, item, catalog, &"pikachu").get("ok", false),
            tag + "_wrong_target")
        var corrupt := CreatureInstance.from_dict(before)
        corrupt.form_id = &"slowpoke-galar" if origin != &"slowpoke_galar" else &"slowbro-galar"
        check(not Contract.inspect(corrupt, item, catalog).get("ok", false), tag + "_bad_form")
        check(source.to_dict() == before, tag + "_pure_no_mutation")
    check(positive + blocked == ROUTES.size(), "all_routes_examined")
    print("W04_V2_B02_RESULT checks=", checks, " routes=", ROUTES.size(),
        " L2=", positive, " blocked=", blocked, " L3=0")
    finish()

func finish() -> void:
    if failures.is_empty():
        print("W04_V2_B02 PASS checks=", checks, " L3=0")
        quit(0)
    else:
        print("W04_V2_B02 FAIL ", JSON.stringify(failures))
        quit(1)
