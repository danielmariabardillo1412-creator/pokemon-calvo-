extends RefCounted
# W04 CONTINUOUS V2 B02: independent, pure regional item-evolution contract.
# This helper is NOT a bag/consumption/evolution executor and grants no L3.
const CanonicalForm = preload("res://modules/creatures/progression/canonical_form_identity_w04.gd")
const ROUTES := {
    &"darumaka_galar": {&"ice_stone": &"darmanitan_galar_standard"},
    &"growlithe_hisui": {&"fire_stone": &"arcanine_hisui"},
    &"sandshrew_alola": {&"ice_stone": &"sandslash_alola"},
    &"slowpoke_galar": {&"galarica_cuff": &"slowbro_galar", &"galarica_wreath": &"slowking_galar"},
    &"voltorb_hisui": {&"leaf_stone": &"electrode_hisui"},
    &"vulpix_alola": {&"ice_stone": &"ninetales_alola"},
}

static func inspect(source: CreatureInstance, item_id: StringName,
        catalogs: DefinitionCatalog, expected_target: StringName = &"") -> Dictionary:
    if source == null or catalogs == null:
        return {"ok": false, "reason": "missing_source_or_catalog"}
    if not ROUTES.has(source.species_id):
        return {"ok": false, "reason": "source_has_no_authorized_item_route"}
    var source_species: CreatureSpecies = catalogs.species(source.species_id)
    if source_species == null:
        return {"ok": false, "reason": "missing_source_species"}
    var canonical_source: StringName = CanonicalForm.from_factory_source(source_species, catalogs)
    if canonical_source == &"" or source.form_id != canonical_source:
        return {"ok": false, "reason": "source_form_not_canonical"}
    var allowed: Dictionary = ROUTES[source.species_id]
    if not allowed.has(item_id):
        return {"ok": false, "reason": "wrong_item"}
    if catalogs.item_catalog == null or not catalogs.item_catalog.has(item_id):
        return {"ok": false, "reason": "item_missing_from_catalog"}
    var target_id: StringName = allowed[item_id]
    if expected_target != &"" and expected_target != target_id:
        return {"ok": false, "reason": "wrong_target"}
    var target_species: CreatureSpecies = catalogs.species(target_id)
    if target_species == null:
        return {"ok": false, "reason": "missing_target_species"}
    var target_form: StringName = CanonicalForm.from_factory_source(target_species, catalogs)
    if target_form == &"" or target_form == canonical_source:
        return {"ok": false, "reason": "target_form_not_canonical"}
    var matching: EvolutionRecord = null
    for entry in source_species.evolutions:
        if not (entry is EvolutionRecord):
            continue
        var record: EvolutionRecord = entry
        if record.trigger != &"use_item" or record.item_id != item_id or record.species_id != target_id:
            continue
        if EvolutionSystem.classify_record(record, catalogs, source_species.id) != EvolutionSystem.RUNTIME_SUPPORTED:
            return {"ok": false, "reason": "record_not_runtime_compatible"}
        if not record.conditions.is_empty():
            return {"ok": false, "reason": "record_has_unhandled_conditions"}
        if matching != null:
            return {"ok": false, "reason": "ambiguous_records"}
        matching = record
    if matching == null:
        return {"ok": false, "reason": "missing_canonical_record"}
    var eligible: Array = EvolutionSystem.evolution_candidates(source_species,
        {"item_id": item_id, "level": source.level, "traded": false}, catalogs)
    if not eligible.has(matching):
        return {"ok": false, "reason": "not_eligible"}
    return {
        "ok": true, "source_species_id": String(source.species_id),
        "source_form_id": String(canonical_source), "item_id": String(item_id),
        "target_species_id": String(target_id), "target_form_id": String(target_form),
        "trigger": "use_item", "version_group": String(matching.version_group),
        "level": source.level, "status": "L2_CONTRACT_ONLY",
    }
