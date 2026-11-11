extends SceneTree
# W04 CONTINUOUS V2 B03: persistence of real Factory regional identities.
# Never claim a successful native evolution from a Factory-created destination.
const Overlay = preload("res://modules/creatures/progression/pokemon_variant_catalog.gd")
const Canonical = preload("res://modules/creatures/progression/canonical_form_identity_w04.gd")
const Contract = preload("res://modules/creatures/progression/regional_item_evolution_contract_w04_v2.gd")
const NativeSave = preload("res://modules/save/field_native_save.gd")
const ROUTES := [
    [&"darumaka_galar", &"ice_stone", &"darmanitan_galar_standard"],
    [&"growlithe_hisui", &"fire_stone", &"arcanine_hisui"],
    [&"sandshrew_alola", &"ice_stone", &"sandslash_alola"],
    [&"slowpoke_galar", &"galarica_cuff", &"slowbro_galar"],
    [&"slowpoke_galar", &"galarica_wreath", &"slowking_galar"],
    [&"voltorb_hisui", &"leaf_stone", &"electrode_hisui"],
    [&"vulpix_alola", &"ice_stone", &"ninetales_alola"],
]
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, name: String) -> void:
    checks += 1
    if not ok:
        failures.append(name)
        push_error("W04_V2_B03_FAIL " + name)

func make_mon(catalog: DefinitionCatalog, species_id: StringName, mon_id: StringName) -> CreatureInstance:
    var rng := RandomNumberGenerator.new()
    rng.seed = 20261111
    return CreatureFactory.create(catalog.species(species_id), 30, catalog, ProgressionRuleset.new(), rng,
        {"instance_id": mon_id, "nature_id": &"hardy", "moves": [&"tackle"]})

func roundtrip(mon: CreatureInstance, catalog: DefinitionCatalog, tag: String) -> void:
    var policy = preload("res://modules/gameplay/randomlock_content_policy.gd").new()
    check(policy.load_local(), tag + "_policy")
    check(Canonical.valid_persistent_form(mon, catalog, policy), tag + "_real_source_form")
    check(NativeSave.new()._valid_creature(mon, catalog, policy), tag + "_native_guard")
    var bag := PlayerCollection.new()
    check(bag.party.add_creature(mon), tag + "_party")
    var before := mon.to_dict()
    var snapshot := SaveGameData.build(bag.party, bag.storage, bag.inventory)
    check(snapshot.validate().ok, tag + "_valid_savev2")
    var corrupt := snapshot.to_dict().duplicate(true)
    corrupt["creatures"][0]["form_id"] = "slowpoke-galar" if mon.species_id != &"slowpoke_galar" else "slowbro-galar"
    check(not SaveGameData.from_dict(corrupt).validate().ok, tag + "_cross_species_corrupt_reject")
    var legacy := snapshot.to_dict().duplicate(true)
    legacy["creatures"][0].erase("form_id")
    check(SaveGameData.from_dict(legacy).validate().ok, tag + "_legacy_optional_form")
    var save_path: String = "user://w04_v2_b03_" + tag + ".json"
    var repo := SaveGameRepository.new()
    check(repo.save_collection(save_path, bag).ok, tag + "_party_save")
    var loaded := repo.load(save_path)
    check(loaded.ok and loaded.party.get_creature(mon.instance_id) != null
        and loaded.party.get_creature(mon.instance_id).to_dict() == before, tag + "_party_load")
    check(bag.deposit(mon.instance_id), tag + "_deposit")
    check(repo.save_collection(save_path, bag).ok, tag + "_storage_save")
    loaded = repo.load(save_path)
    check(loaded.ok and loaded.storage.get_creature(mon.instance_id) != null
        and loaded.storage.get_creature(mon.instance_id).to_dict() == before, tag + "_storage_load")


func _run() -> void:
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(Overlay.CANONICAL))
    check(parsed is Dictionary, "canonical_dataset")
    if not parsed is Dictionary:
        finish()
        return
    var catalog: DefinitionCatalog = GameData.from_dict(parsed).to_definition_catalog()
    check(Overlay.apply(catalog), "regional_overlay")
    var checked_sources: Dictionary = {}
    var checked_targets: Dictionary = {}
    for route in ROUTES:
        var origin: StringName = route[0]
        var item: StringName = route[1]
        var destination: StringName = route[2]
        var source := make_mon(catalog, origin, StringName("w04_b03_origin_" + String(origin)))
        var target := make_mon(catalog, destination, StringName("w04_b03_dest_" + String(destination)))
        var contract: Dictionary = Contract.inspect(source, item, catalog, destination)
        check(contract.get("ok", false), String(origin) + "_contract_" + String(item))
        if contract.get("ok", false):
            check(target.form_id == StringName(contract.get("target_form_id", "")),
                String(destination) + "_canonical_target")
            check(target.form_id != source.form_id,
                String(destination) + "_not_inherited_form")
        if not checked_sources.has(origin):
            roundtrip(source, catalog, "source_" + String(origin))
            checked_sources[origin] = true
        if not checked_targets.has(destination):
            roundtrip(target, catalog, "factory_target_" + String(destination))
            checked_targets[destination] = true
    print("W04_V2_B03_FACTORY_SOURCE_TARGET_COUNT=", checked_sources.size(), "+", checked_targets.size(),
        " native_evolution_L3=0")
    finish()

func finish() -> void:
    if failures.is_empty():
        print("W04_V2_B03 PASS checks=", checks, " L3=0")
        quit(0)
    else:
        print("W04_V2_B03 FAIL ", JSON.stringify(failures))
        quit(1)
