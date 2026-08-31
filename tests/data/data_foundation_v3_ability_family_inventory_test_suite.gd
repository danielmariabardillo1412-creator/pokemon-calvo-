class_name DataFoundationV3AbilityFamilyInventoryTestSuite
extends RefCounted

# Certified #76 ability IDs are excluded so this inventory remains anchored to the
# exact 367-record DATA_ONLY frontier that existed at the start of family work.
const PARENT_AUDITED_IDS := [
	"blaze", "intimidate", "levitate", "overgrow", "static", "torrent",
]

# Explicit promotions made after the #76 frontier. Keeping this list narrow makes
# the inventory fail if a future adapter change silently upgrades a whole family.
const EXPLICITLY_PROMOTED_FRONTIER_IDS := [
	"dragons_maw", "fire_mane", "rocky_payload", "steelworker", "swarm",
]

const EXPECTED_COUNTS := {
	"contact_reactive": 11,
	"faint_dependent": 6,
	"form_identity": 12,
	"immunity_absorb_prevention": 53,
	"item_transaction": 13,
	"misc_unresolved": 26,
	"move_property_control": 38,
	"pinch_type_boost": 1,
	"source_text_missing": 60,
	"stat_damage_modifier": 78,
	"status_dependent": 25,
	"switch_party": 11,
	"weather_terrain": 33,
}

const CONTACT_REACTIVE_IDS := [
	"cute_charm", "effect_spore", "flame_body", "gooey", "iron_barbs", "mummy",
	"pickpocket", "poison_point", "poison_touch", "rough_skin", "wandering_spirit",
]


func run(check: Callable) -> void:
	var raw := _load_json("res://data/raw/pokemon_api.json")
	var abilities: Array = raw.get("abilities", [])
	var counts := {}
	var ids_by_family := {}
	var baseline_records := 0

	for raw_ability in abilities:
		if not (raw_ability is Dictionary):
			continue
		var ability: Dictionary = raw_ability
		var ability_id := str(ability.get("id", ""))
		if PARENT_AUDITED_IDS.has(ability_id):
			continue
		baseline_records += 1
		var family := _primary_family(str(ability.get("description", "")))
		counts[family] = int(counts.get(family, 0)) + 1
		if not ids_by_family.has(family):
			ids_by_family[family] = []
		(ids_by_family[family] as Array).append(ability_id)

	for family in ids_by_family:
		(ids_by_family[family] as Array).sort()

	check.call("data_v3_ability_family_inventory_total", baseline_records == 367)
	check.call(
		"data_v3_ability_family_inventory_partition",
		_counts_match(counts, EXPECTED_COUNTS),
	)
	check.call(
		"data_v3_ability_family_inventory_pinch_exact",
		(ids_by_family.get("pinch_type_boost", []) as Array) == ["swarm"],
	)
	check.call(
		"data_v3_ability_family_inventory_contact_exact",
		(ids_by_family.get("contact_reactive", []) as Array) == CONTACT_REACTIVE_IDS,
	)

	# Missing source prose is an explicit blocker, never a reason to infer support.
	var missing_text_safe := true
	for ability_id in ids_by_family.get("source_text_missing", []):
		var record := _find_by_id(abilities, str(ability_id))
		missing_text_safe = missing_text_safe and str(record.get("classification", "")) == "DATA_ONLY"
	check.call("data_v3_ability_family_inventory_missing_text_stays_data_only", missing_text_safe)

	# Every member of the #76 DATA_ONLY frontier must remain DATA_ONLY unless it is
	# named in the explicit post-#76 promotion allowlist above.
	var no_mass_promotion := true
	for raw_ability in abilities:
		if not (raw_ability is Dictionary):
			continue
		var ability: Dictionary = raw_ability
		var ability_id := str(ability.get("id", ""))
		if PARENT_AUDITED_IDS.has(ability_id) or EXPLICITLY_PROMOTED_FRONTIER_IDS.has(ability_id):
			continue
		no_mass_promotion = no_mass_promotion and str(ability.get("classification", "")) == "DATA_ONLY"
	check.call("data_v3_ability_family_inventory_no_mass_promotion", no_mass_promotion)


func _primary_family(description: String) -> String:
	var text := description.strip_edges().to_lower()
	if text.is_empty():
		return "source_text_missing"
	if text.contains("strengthens ") and text.contains("1.5× damage at 1/3 max hp or less"):
		return "pinch_type_boost"
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


func _find_by_id(records: Array, wanted_id: String) -> Dictionary:
	for record in records:
		if record is Dictionary and str(record.get("id", "")) == wanted_id:
			return record
	return {}


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	return JSON.parse_string(file.get_as_text()) as Dictionary
