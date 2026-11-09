extends RefCounted
# IA4/W04 isolated and PURE Milcery spin precondition resolver.
# The world does NOT currently supply an authentic spin or a canonical cream
# selector. This module must never be used as permission to evolve/spend items.
# Candidate form validation is not a rule for CHOOSING a form.
const SWEETS := [
    &"berry_sweet", &"clover_sweet", &"flower_sweet", &"love_sweet",
    &"ribbon_sweet", &"star_sweet", &"strawberry_sweet",
]
const SOURCE := &"milcery"
const TARGET := &"alcremie"
const SPIN := &"spin"

static func _deny(reason: String) -> Dictionary:
    return {
        "preconditions_valid": false, "evolution_ready": false,
        "candidate_forms": [], "reason": reason,
        "scope": "PURE_SPIN_PRECONDITIONS_ONLY", "mutates": false,
    }

static func _sweet_suffix(item_id: StringName) -> String:
    return "-" + String(item_id).replace("_", "-")

# These names MUST originate from an imported canonical pokemon-form list.
# No world time/direction/duration => cream selector exists in this module.
static func candidate_forms(item_id: StringName, canonical_forms: Array) -> Array:
    if not SWEETS.has(item_id):
        return []
    var suffix := _sweet_suffix(item_id)
    var prefix := "alcremie-"
    var results: Array = []
    var seen: Dictionary = {}
    for value: Variant in canonical_forms:
        if not (value is String or value is StringName):
            return []
        var form := String(value)
        if not form.begins_with(prefix) or not form.ends_with(suffix):
            continue
        var cream := form.substr(prefix.length(), form.length() - prefix.length() - suffix.length())
        if cream.is_empty() or seen.has(form):
            return []
        seen[form] = true
        results.append(form)
    results.sort()
    return results

# Inputs are injected facts, NOT authenticated by this resolver.
# A real future world producer must vouch for a completed spin event, direction,
# duration, actual daypart and a version-specific mapping to the cream variant.
# An allowed event shape/held sweet is necessary but never sufficient to evolve.
static func inspect(
    record: EvolutionRecord,
    source_species_id: StringName,
    held_item_id: StringName,
    held_item_consumed: bool,
    spin_event: Dictionary,
    canonical_forms: Array,
) -> Dictionary:
    if record == null or source_species_id != SOURCE or record.species_id != TARGET:
        return _deny("wrong_evolution_route")
    if record.trigger != SPIN or record.item_id != &"" or not record.conditions.is_empty():
        return _deny("record_not_canonical_spin")
    if not SWEETS.has(held_item_id):
        return _deny("missing_or_invalid_held_sweet")
    if held_item_consumed:
        return _deny("held_sweet_already_consumed")
    if not spin_event.has("trigger") or StringName(str(spin_event["trigger"])) != SPIN:
        return _deny("not_spin_event")
    # This field is a future event schema requirement, NOT authentication.
    if not spin_event.has("completed") or typeof(spin_event["completed"]) != TYPE_BOOL or not spin_event["completed"]:
        return _deny("spin_not_completed")
    if not spin_event.has("direction") or not (
        String(spin_event["direction"]) in ["clockwise", "counterclockwise"]
    ):
        return _deny("missing_spin_direction")
    if not spin_event.has("duration_ms") or typeof(spin_event["duration_ms"]) != TYPE_INT or int(spin_event["duration_ms"]) <= 0:
        return _deny("missing_spin_duration")
    if not spin_event.has("world_daypart") or not (
        String(spin_event["world_daypart"]) in ["day", "night"]
    ):
        return _deny("missing_world_daypart")
    var forms: Array = candidate_forms(held_item_id, canonical_forms)
    # PokeAPI ships nine creams for each of the seven sweets. Fail closed
    # if the canonical form list is incomplete/duplicated/unknown.
    if forms.size() != 9:
        return _deny("canonical_form_catalog_incomplete")
    return {
        "preconditions_valid": true, "evolution_ready": false,
        "candidate_forms": forms,
        "reason": "authoritative_cream_selection_missing",
        "scope": "PURE_SPIN_PRECONDITIONS_ONLY", "mutates": false,
    }

# Validates only that a proposed form belongs to the original canonical
# catalogue and uses the same sweet. It NEVER chooses/approves a cream variant.
static func validate_candidate(form_id: String, held_item_id: StringName, canonical_forms: Array) -> Dictionary:
    if form_id.is_empty() or not SWEETS.has(held_item_id):
        return _deny("invalid_form_or_sweet")
    if not canonical_forms.has(form_id):
        return _deny("form_not_in_canonical_catalog")
    if not candidate_forms(held_item_id, canonical_forms).has(form_id):
        return _deny("form_sweet_mismatch")
    return {
        "candidate_valid": true, "evolution_ready": false,
        "form_id": form_id, "reason": "authoritative_cream_selection_missing",
        "scope": "PURE_FORM_CANDIDATE_ONLY", "mutates": false,
    }
