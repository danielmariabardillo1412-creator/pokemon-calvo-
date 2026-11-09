extends RefCounted
# W04 isolated, pure evolution-condition predicate. NOT registered with gameplay.
# Inputs are injected observations, not acquired or authenticated by this module.
# The production caller must select the canonical EvolutionRecord from its real
# source species and provide persistent creature/world facts.
# No mutation, inventory operations, evolution, SaveV2 or event generation.

const LEVEL_UP := &"level_up"
const USE_ITEM := &"use_item"
const _SUPPORTED := ["held_item", "gender", "time_of_day"]

static func _result(ok: bool, reason: String) -> Dictionary:
    return {"eligible": ok, "reason": reason, "scope": "RESOLVER_ONLY", "mutates": false}

static func evaluate(record: EvolutionRecord, event: Dictionary, facts: Dictionary) -> Dictionary:
    if record == null or record.species_id == &"":
        return _result(false, "invalid_record")
    if not (record.trigger == LEVEL_UP or record.trigger == USE_ITEM):
        return _result(false, "unsupported_trigger")
    if record.conditions.is_empty():
        return _result(false, "not_conditional_route")
    var needs_supported := false
    for key: Variant in record.conditions.keys():
        if typeof(key) != TYPE_STRING or not _SUPPORTED.has(String(key)):
            return _result(false, "unsupported_condition")
        needs_supported = true
    if not needs_supported:
        return _result(false, "not_conditional_route")
    if not event.has("trigger") or StringName(str(event["trigger"])) != record.trigger:
        return _result(false, "wrong_trigger")
    if record.trigger == USE_ITEM:
        if record.item_id == &"" or not event.has("item_id") or StringName(str(event["item_id"])) != record.item_id:
            return _result(false, "wrong_item")
    else:
        # Never treat mere possession, a bag click or a level snapshot as level-up.
        if not event.has("previous_level") or not event.has("new_level"):
            return _result(false, "missing_level_transition")
        var previous: Variant = event["previous_level"]
        var current: Variant = event["new_level"]
        if typeof(previous) != TYPE_INT or typeof(current) != TYPE_INT:
            return _result(false, "invalid_level_transition")
        if int(previous) < 1 or int(current) > 100 or int(current) <= int(previous):
            return _result(false, "invalid_level_transition")
        if record.min_level > 0 and int(current) < record.min_level:
            return _result(false, "below_required_level")
    if record.conditions.has("held_item"):
        var held: Variant = record.conditions["held_item"]
        if not (held is String or held is StringName) or String(held).is_empty():
            return _result(false, "invalid_held_rule")
        if not facts.has("held_item_id") or StringName(str(facts["held_item_id"])) != StringName(held):
            return _result(false, "wrong_held_item")
        if not facts.has("held_item_consumed") or typeof(facts["held_item_consumed"]) != TYPE_BOOL:
            return _result(false, "missing_held_consumed_state")
        if facts["held_item_consumed"]:
            return _result(false, "held_item_already_consumed")
    if record.conditions.has("gender"):
        var required: Variant = record.conditions["gender"]
        # Godot JSON.parse_string may decode canonical integer-valued numbers
        # as TYPE_FLOAT. Accept only exact 1/2; reject strings and fractions.
        if not (typeof(required) == TYPE_INT or typeof(required) == TYPE_FLOAT):
            return _result(false, "unsupported_gender_rule")
        if float(required) != floor(float(required)) or int(required) not in [1, 2]:
            return _result(false, "unsupported_gender_rule")
        if not facts.has("gender") or typeof(facts["gender"]) != TYPE_INT:
            return _result(false, "missing_individual_gender")
        if int(facts["gender"]) != int(required):
            return _result(false, "wrong_gender")
    if record.conditions.has("time_of_day"):
        var required_time: Variant = record.conditions["time_of_day"]
        if not (required_time is String or required_time is StringName):
            return _result(false, "unsupported_time_rule")
        var condition := String(required_time).replace("-", "_")
        match condition:
            "day", "night":
                if not facts.has("daypart") or typeof(facts["daypart"]) != TYPE_STRING:
                    return _result(false, "missing_world_daypart")
                if facts["daypart"] != condition:
                    return _result(false, "wrong_world_daypart")
            "full_moon":
                # The API encodes a moon condition in time_of_day; this is NOT a
                # daytime constraint and must come from a world moon-phase source.
                if not facts.has("moon_phase") or typeof(facts["moon_phase"]) != TYPE_STRING:
                    return _result(false, "missing_world_moon_phase")
                if facts["moon_phase"] != "full":
                    return _result(false, "not_full_moon")
            _:
                return _result(false, "unsupported_time_rule")
    return _result(true, "conditions_match")
