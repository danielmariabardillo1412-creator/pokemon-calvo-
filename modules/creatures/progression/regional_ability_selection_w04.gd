extends RefCounted
# W04 TANDA04. Pure selection: use only existing NORMAL canonical slots
# from an actual regional CreatureSpecies. Never invent a hidden ability.
const ELIGIBLE := {
    &"ponyta_galar": &"pastel_veil",
    &"rapidash_galar": &"pastel_veil",
    &"voltorb_hisui": &"static",
    &"electrode_hisui": &"static",
}

static func select_normal(species: CreatureSpecies, policy: RefCounted) -> StringName:
    if species == null or policy == null or not policy.valid:
        return &""
    if not ELIGIBLE.has(species.id):
        return &""
    if species.ability_slots.is_empty():
        return &""
    var expected: StringName = ELIGIBLE[species.id]
    var first_normal: StringName = &""
    var fallback: StringName = &""
    var sorted_slots: Array[Dictionary] = species.ability_slots.duplicate(true)
    sorted_slots.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return int(a.get("slot", 99)) < int(b.get("slot", 99)))
    for row: Dictionary in sorted_slots:
        if bool(row.get("is_hidden", true)):
            continue
        var candidate := StringName(row.get("ability_id", ""))
        if candidate == &"" or not species.ability_ids.has(candidate):
            continue
        if first_normal == &"":
            first_normal = candidate
        if policy.ability_allowed(String(candidate)) and fallback == &"":
            fallback = candidate
    if first_normal == &"" or policy.ability_allowed(String(first_normal)):
        return &"" # Only alter a regional first ability excluded by policy.
    if fallback != expected:
        return &"" # Defend the exact IA6 four-species whitelist.
    return fallback
