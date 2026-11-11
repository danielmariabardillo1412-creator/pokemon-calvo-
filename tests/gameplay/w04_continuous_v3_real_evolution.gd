extends SceneTree
# W04 CONTINUOUS V3: real FieldItemService evolution, not Factory destination.
const Overlay = preload("res://modules/creatures/progression/pokemon_variant_catalog.gd")
const Contract = preload("res://modules/creatures/progression/regional_item_evolution_contract_w04_v2.gd")
const Service = preload("res://modules/inventory/field_item_service.gd")
const FailService = preload("res://tests/gameplay/w04_continuous_v3_fail_publish_service.gd")
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
var checks := 0
var positives := 0
var rollback_verified := 0

func _initialize() -> void: call_deferred("_run")

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        errors.append(label)
        push_error("W04_V3_FAIL " + label)

func make_mon(c: DefinitionCatalog, species: StringName, name: StringName) -> CreatureInstance:
    var rng := RandomNumberGenerator.new()
    rng.seed = 20261111
    return CreatureFactory.create(c.species(species), 30, c, ProgressionRuleset.new(), rng,
        {"instance_id": name, "nature_id": &"hardy", "moves": [&"tackle"]})

func snapshot(c: PlayerCollection) -> String:
    return JSON.stringify(SaveGameData.build(c.party, c.storage, c.inventory).to_dict())

func _case(catalog: DefinitionCatalog, source_id: StringName, item: StringName,
        target_id: StringName, in_storage: bool) -> void:
    var tag: String = String(source_id) + "_" + String(item) + ("_STORAGE" if in_storage else "_PARTY")
    var owner := PlayerCollection.new()
    var mon := make_mon(catalog, source_id, StringName("w04_v3_" + tag))
    var wrong := make_mon(catalog, &"pikachu", StringName("w04_v3_other_" + tag))
    check(owner.party.add_creature(mon) and owner.party.add_creature(wrong), tag + "_owned")
    if in_storage:
        check(owner.deposit(mon.instance_id), tag + "_deposited")
    check(owner.inventory.set_quantity(item, 2), tag + "_stock")
    var service := Service.new()
    check(service.configure(owner, catalog, func() -> bool: return true), tag + "_configured")
    var evidence: Dictionary = Contract.inspect(mon, item, catalog, target_id)
    check(evidence.get("ok", false), tag + "_canonical")
    check(service.evolution_options(item, mon.instance_id) == [target_id], tag + "_options")
    var initial := snapshot(owner)
    check(service.evolution_options(&"potion", mon.instance_id).is_empty(), tag + "_wrong_item_options")
    check(not service.evolve(item, wrong.instance_id, target_id).get("accepted", false)
        and snapshot(owner) == initial, tag + "_wrong_species_no_spend")
    check(not service.evolve(item, mon.instance_id, &"pikachu").get("accepted", false)
        and snapshot(owner) == initial, tag + "_wrong_target_no_spend")
    var invalid := CreatureInstance.from_dict(mon.to_dict())
    invalid.form_id = &"slowpoke-galar" if source_id != &"slowpoke_galar" else &"slowbro-galar"
    check(not Contract.inspect(invalid, item, catalog, target_id).get("ok", false), tag + "_wrong_form_rejected")
    var before := mon.to_dict()
    var applied: Dictionary = service.evolve(item, mon.instance_id, target_id)
    check(applied.get("accepted", false) and StringName(applied.get("species_id", "")) == target_id,
        tag + "_real_field_evolution")
    var evolved: CreatureInstance = owner.owned_creature(mon.instance_id)
    check(evolved != null and evolved.species_id == target_id and evolved.instance_id == mon.instance_id,
        tag + "_stable_identity")
    if evolved == null:
        return
    check(evolved.form_id == StringName(evidence.get("target_form_id", "")),
        tag + "_exact_destination_form")
    check(evolved.form_id != mon.form_id, tag + "_form_not_inherited")
    check(owner.inventory.quantity(item) == 1, tag + "_exactly_one_consumed")
    check(owner.location_of(mon.instance_id) == (&"STORAGE" if in_storage else &"PARTY"),
        tag + "_original_location")
    check(evolved.nature_id == mon.nature_id and evolved.ivs == mon.ivs and evolved.evs == mon.evs
        and evolved.experience == mon.experience and evolved.move_ids == mon.move_ids,
        tag + "_persistent_values")
    check(owner.owned_creature(wrong.instance_id) == wrong, tag + "_other_creature_not_changed")
    var committed := snapshot(owner)
    check(not service.evolve(item, mon.instance_id, target_id).get("accepted", false)
        and snapshot(owner) == committed, tag + "_repeat_denied_no_spend")
    var save_path := "user://w04_v3_" + tag + ".json"
    var repository := SaveGameRepository.new()
    check(repository.save_collection(save_path, owner).ok, tag + "_save")
    var loaded := repository.load(save_path)
    check(loaded.ok, tag + "_load")
    if loaded.ok:
        var persisted: CreatureInstance = loaded.storage.get_creature(mon.instance_id) if in_storage else loaded.party.get_creature(mon.instance_id)
        check(persisted != null and persisted.to_dict() == evolved.to_dict(), tag + "_savev2_identity")
        check(loaded.inventory.quantity(item) == 1, tag + "_savev2_consumption")
    DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
    positives += 1

func _rollback_case(catalog: DefinitionCatalog, source_id: StringName, item_id: StringName,
        target_id: StringName, in_storage: bool) -> void:
    var tag := String(source_id) + ("_rollback_storage" if in_storage else "_rollback_party")
    var owner := PlayerCollection.new()
    var mon := make_mon(catalog, source_id, StringName("w04_v3_fault_" + tag))
    check(owner.party.add_creature(mon), tag + "_party")
    if in_storage:
        check(owner.deposit(mon.instance_id), tag + "_storage")
    check(owner.inventory.set_quantity(item_id, 2), tag + "_stock")
    var service := FailService.new()
    check(service.configure(owner, catalog, func() -> bool: return true), tag + "_configured")
    var before := snapshot(owner)
    var location := owner.location_of(mon.instance_id)
    var result: Dictionary = service.evolve(item_id, mon.instance_id, target_id)
    var unchanged: bool = not result.get("accepted", false) and result.get("reason", "") == "evolution_commit_failed"
    unchanged = unchanged and snapshot(owner) == before and owner.inventory.quantity(item_id) == 2
    unchanged = unchanged and owner.location_of(mon.instance_id) == location
    unchanged = unchanged and is_same(owner.owned_creature(mon.instance_id), mon)
    check(unchanged, tag + "_failed_after_owner_replace_atomic_rollback")
    if unchanged:
        rollback_verified += 1

func _run() -> void:
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(Overlay.CANONICAL))
    check(parsed is Dictionary, "canonical")
    if not (parsed is Dictionary):
        finish()
        return
    var catalog: DefinitionCatalog = GameData.from_dict(parsed).to_definition_catalog()
    check(Overlay.apply(catalog), "overlay")
    for row in ROUTES:
        _case(catalog, row[0], row[1], row[2], false)
        _case(catalog, row[0], row[1], row[2], true)
    _rollback_case(catalog, &"slowpoke_galar", &"galarica_cuff", &"slowbro_galar", false)
    _rollback_case(catalog, &"vulpix_alola", &"ice_stone", &"ninetales_alola", true)
    print("W04_V3_ROLLBACK_RESULT cases=", rollback_verified, " expected=2")
    print("W04_V3_L3_RESULT routes=", ROUTES.size(), " ownership_cases=", positives,
        " checks=", checks, " L3=", positives / 2)
    finish()

func finish() -> void:
    if errors.is_empty() and positives == ROUTES.size() * 2 and rollback_verified == 2:
        print("W04_V3_L3 PASS checks=", checks, " routes=7 ownership=14 rollback=2")
        quit(0)
    else:
        print("W04_V3_L3 FAIL errors=", JSON.stringify(errors))
        quit(1)
