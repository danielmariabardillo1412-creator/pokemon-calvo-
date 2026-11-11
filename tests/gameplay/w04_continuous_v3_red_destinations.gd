extends SceneTree
# W04 V3 phase A RED test: this must fail on V2 unmodified EvolutionSystem.
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
var errors: Array[String] = []
func _initialize() -> void: call_deferred("_run")
func check(ok: bool, name: String) -> void:
    if not ok:
        errors.append(name)
        push_error("W04_V3_RED " + name)
func _run() -> void:
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(Overlay.CANONICAL))
    if not (parsed is Dictionary):
        push_error("bad_catalog")
        quit(1)
        return
    var catalogs: DefinitionCatalog = GameData.from_dict(parsed).to_definition_catalog()
    check(Overlay.apply(catalogs), "overlay")
    for row in ROUTES:
        var source_id: StringName = row[0]
        var item_id: StringName = row[1]
        var target_id: StringName = row[2]
        var rng := RandomNumberGenerator.new()
        rng.seed = 20261111
        var source := CreatureFactory.create(catalogs.species(source_id), 30, catalogs,
            ProgressionRuleset.new(), rng, {"instance_id": StringName("w04_red_" + String(item_id)),
            "nature_id": &"hardy", "moves": [&"tackle"]})
        var contract: Dictionary = Contract.inspect(source, item_id, catalogs, target_id)
        check(contract.get("ok", false), String(source_id) + "_contract")
        var evolved := EvolutionSystem.apply_evolution(source, target_id, catalogs, ProgressionRuleset.new())
        check(evolved != null and evolved.form_id == StringName(contract.get("target_form_id", "")),
            String(source_id) + "_" + String(item_id) + "_target_form_lost")
    if errors.is_empty():
        print("W04_V3_A PASS seven_real_destinations")
        quit(0)
    else:
        print("W04_V3_A RED missing_destinations=", errors.size())
        quit(1)
