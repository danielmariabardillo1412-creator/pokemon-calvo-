extends RefCounted
# IA4/W04 TANDA05: pure L2 contract, NOT a gameplay evolution executor.
# An eligible record is never permission to consume an item or replace a party mon.
const CanonicalForm = preload("res://modules/creatures/progression/canonical_form_identity_w04.gd")
const EXACT := {
    &"galarica_cuff": &"slowbro_galar",
    &"galarica_wreath": &"slowking_galar",
}

static func inspect(source: CreatureInstance, item_id: StringName,
        catalogs: DefinitionCatalog, expected_target: StringName = &"") -> Dictionary:
    if source == null or catalogs == null:
        return {"ok": false, "reason": "missing_source_or_catalog"}
    if source.species_id != &"slowpoke_galar" or source.form_id != &"slowpoke-galar":
        return {"ok": false, "reason": "wrong_source_species_or_form"}
    if not EXACT.has(item_id):
        return {"ok": false, "reason": "unrecognized_item"}
    var target_id: StringName = EXACT[item_id]
    if expected_target != &"" and expected_target != target_id:
        return {"ok": false, "reason": "target_mismatch"}
    var species: CreatureSpecies = catalogs.species(source.species_id)
    var target: CreatureSpecies = catalogs.species(target_id)
    if species == null or target == null:
        return {"ok": false, "reason": "missing_canonical_species"}
    var source_form := CanonicalForm.from_factory_source(species, catalogs)
    var target_form := CanonicalForm.from_factory_source(target, catalogs)
    if source_form != source.form_id or target_form == &"" or target_form == source_form:
        return {"ok": false, "reason": "invalid_canonical_form_pair"}
    if catalogs.item_catalog == null or not catalogs.item_catalog.has(item_id):
        return {"ok": false, "reason": "item_absent_from_catalog"}
    var matched: EvolutionRecord = null
    for entry in species.evolutions:
        if not (entry is EvolutionRecord):
            continue
        var record: EvolutionRecord = entry
        if record.trigger != &"use_item" or record.item_id != item_id or record.species_id != target_id:
            continue
        if EvolutionSystem.classify_record(record, catalogs, species.id) != EvolutionSystem.RUNTIME_SUPPORTED:
            return {"ok": false, "reason": "record_data_only_or_unsupported"}
        if not record.conditions.is_empty():
            return {"ok": false, "reason": "record_has_unresolved_conditions"}
        if matched != null:
            return {"ok": false, "reason": "ambiguous_canonical_records"}
        matched = record
    if matched == null:
        return {"ok": false, "reason": "no_matching_runtime_record"}
    var eligible: Array = EvolutionSystem.evolution_candidates(species,
        {"level": source.level, "item_id": item_id, "traded": false}, catalogs)
    if not eligible.has(matched):
        return {"ok": false, "reason": "runtime_eligibility_denied"}
    return {"ok": true, "reason": "", "source_species_id": String(source.species_id),
        "source_form_id": String(source.form_id), "item_id": String(item_id),
        "target_species_id": String(target_id), "target_form_id": String(target_form),
        "trigger": String(matched.trigger), "version_group": String(matched.version_group),
        "level": source.level,
        "status": "L2_CONTRACT_ONLY_NO_NATIVE_CONSUMER"}
