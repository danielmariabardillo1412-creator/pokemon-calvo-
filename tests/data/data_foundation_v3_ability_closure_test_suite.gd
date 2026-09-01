class_name DataFoundationV3AbilityClosureTestSuite
extends RefCounted

# Final honest capability boundary for the Ability V3 phase after certified #91.
# These buckets are deterministic planning partitions of the remaining DATA_ONLY
# frontier; they are not permission to auto-promote anything by prose heuristic.
const EXPECTED_DATA_ONLY_COUNT := 338
const EXPECTED_BUCKET_COUNTS := {
	"contact_reactive": 7,
	"faint_dependent": 6,
	"form_identity": 12,
	"immunity_absorb_prevention": 52,
	"item_transaction": 13,
	"misc_unresolved": 26,
	"move_property_control": 36,
	"source_text_missing": 60,
	"stat_damage_modifier": 64,
	"status_dependent": 18,
	"switch_party": 11,
	"weather_terrain": 33,
}

# High-value abilities that are deliberately deferred because their complete
# semantics require architecture not present in the current battle model. Keeping
# them here prevents a later broad registry edit from silently crossing the
# certified Ability V3 boundary.
const DEFERRED_SENTINELS := [
	"battle_armor", "shell_armor",
	"rain_dish", "ice_body",
	"rivalry", "stakeout",
	"shed_skin", "poison_heal",
	"gorilla_tactics", "steely_spirit",
	"rough_skin", "transistor",
	"filter", "solid_rock",
	"water_compaction", "weak_armor",
	"long_reach", "technician",
	"fluffy",
]


func run(check: Callable) -> void:
	var raw := _load_json("res://data/raw/pokemon_api.json")
	var abilities: Array = raw.get("abilities", [])
	var data_only_ids: Array[String] = []
	var counts := {}

	for raw_ability in abilities:
		if not (raw_ability is Dictionary):
			continue
		var ability: Dictionary = raw_ability
		if str(ability.get("classification", "")) != "DATA_ONLY":
			continue
		var ability_id := str(ability.get("id", ""))
		data_only_ids.append(ability_id)
		var family := _primary_family(str(ability.get("description", "")))
		counts[family] = int(counts.get(family, 0)) + 1

	data_only_ids.sort()
	check.call(
		"data_v3_ability_closure_exact_data_only_frontier",
		data_only_ids.size() == EXPECTED_DATA_ONLY_COUNT,
	)
	check.call(
		"data_v3_ability_closure_exact_bucket_partition",
		_counts_match(counts, EXPECTED_BUCKET_COUNTS),
	)

	# Strong execution invariant: DATA_ONLY is not merely a report label. No
	# remaining DATA_ONLY ability may already have an executable registry mapping.
	var implemented: Array[StringName] = BattleEffectRegistry.new().implemented_ability_ids()
	var hidden_runtime := false
	for ability_id in data_only_ids:
		if implemented.has(StringName(ability_id)):
			hidden_runtime = true
			break
	check.call("data_v3_ability_closure_no_hidden_data_only_runtime", not hidden_runtime)

	var sentinels_preserved := true
	var sentinels_unmapped := true
	for ability_id in DEFERRED_SENTINELS:
		sentinels_preserved = sentinels_preserved and data_only_ids.has(ability_id)
		sentinels_unmapped = sentinels_unmapped and not implemented.has(StringName(ability_id))
	check.call("data_v3_ability_closure_deferred_sentinels_stay_data_only", sentinels_preserved)
	check.call("data_v3_ability_closure_deferred_sentinels_have_no_registry_mapping", sentinels_unmapped)

	# Provenance remains the largest single blocker family. Empty source prose is
	# never a license to infer mechanics from the English ability name.
	check.call(
		"data_v3_ability_closure_missing_source_frontier_exact",
		int(counts.get("source_text_missing", -1)) == 60,
	)


func _primary_family(description: String) -> String:
	var text := description.strip_edges().to_lower()
	if text.is_empty():
		return "source_text_missing"
	if text.contains(" on contact") or text.contains(" upon contact"):
		return "contact_reactive"
	if text.begins_with("prevents ") or _contains_any(text, [
		"immune to", "protects against", "absorbs ",
	]):
		return "immunity_absorb_prevention"
	if _contains_any(text, [
		"rain", "sunlight", "sunny", "sandstorm", "hail", "snow", "weather", "terrain",
	]):
		return "weather_terrain"
	if _contains_any(text, [" item", "item ", "berry", "berries", "held "]):
		return "item_transaction"
	if _contains_any(text, [
		"switch", "leaves battle", "enters battle", "party", "sent out", "fleeing",
	]):
		return "switch_party"
	if _contains_any(text, [
		" form", "forme", "transform", "disguise", "appearance", "changes type",
	]):
		return "form_identity"
	if _contains_any(text, ["faint", "knock out", "knocked out", "defeated"]):
		return "faint_dependent"
	if _contains_any(text, [
		"normal moves", "moves become", "moves are ", "move's type", "move immediately",
		"priority attacks", "pp cost", "all moves", "dance move", "slicing moves", "punch",
		"biting moves", "recoil moves", "base power", "extra effects", "critical hits",
		"move first", "move last", "accuracy", "draw in moves", "sound-based moves",
		"healing moves", "multi-hit", "two-to-five-hit", "triple kick", "move used",
		"copies", "copy ", "reflects most non-damaging moves",
	]):
		return "move_property_control"
	if _contains_any(text, [
		"status", "poison", "burn", "paralysis", "paralyzed", "sleep", "asleep",
		"confusion", "infatuation", "flinch", "freeze", "freezing",
	]):
		return "status_dependent"
	if _contains_any(text, [
		"attack", "defense", "speed", "evasion", "damage", "power", "stat", "stage",
	]):
		return "stat_damage_modifier"
	return "misc_unresolved"


func _contains_any(text: String, needles: Array) -> bool:
	for needle in needles:
		if text.contains(str(needle)):
			return true
	return false


func _counts_match(actual: Dictionary, expected: Dictionary) -> bool:
	if actual.size() != expected.size():
		return false
	for family in expected:
		if int(actual.get(family, -1)) != int(expected[family]):
			return false
	return true


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	return JSON.parse_string(file.get_as_text()) as Dictionary
