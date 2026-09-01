class_name DataFoundationV3ItemClosureTestSuite
extends RefCounted

# Final bounded capability boundary for the Items V3 phase after certified #92.
# Canonical DATA V3 item presence is metadata/provenance only; executable support
# remains an explicit BattleEffectRegistry concern.
const EXPECTED_ITEM_COUNT := 2222
const EXPECTED_ITEM_KEYS := ["category", "description", "display_name", "id"]
const EXPECTED_HELD_RUNTIME_IDS := [&"leftovers", &"sitrus_berry"]
const EXPECTED_TRAINER_ITEM_IDS := [
	&"full_restore", &"hyper_potion", &"max_potion", &"potion", &"super_potion",
]


func run(check: Callable) -> void:
	var raw := _load_json("res://data/raw/pokemon_api.json")
	var items: Array = raw.get("items", [])
	var item_ids: Array[String] = []
	var exact_schema := true
	var categories := {}

	for raw_item in items:
		if not (raw_item is Dictionary):
			exact_schema = false
			continue
		var item: Dictionary = raw_item
		var keys := item.keys()
		keys.sort()
		exact_schema = exact_schema and keys == EXPECTED_ITEM_KEYS
		var item_id := str(item.get("id", ""))
		item_ids.append(item_id)
		var category := str(item.get("category", ""))
		categories[category] = int(categories.get(category, 0)) + 1

	var unique_ids := {}
	for item_id in item_ids:
		unique_ids[item_id] = true

	check.call("data_v3_item_closure_exact_canonical_count", items.size() == EXPECTED_ITEM_COUNT)
	check.call("data_v3_item_closure_unique_canonical_ids", unique_ids.size() == EXPECTED_ITEM_COUNT)
	check.call("data_v3_item_closure_exact_metadata_schema", exact_schema)
	check.call(
		"data_v3_item_closure_categories_are_explicit_and_nonempty",
		not categories.has("") and not categories.is_empty(),
	)

	var registry := BattleEffectRegistry.new()
	check.call(
		"data_v3_item_closure_exact_held_runtime_frontier",
		registry.runtime_supported_item_ids() == EXPECTED_HELD_RUNTIME_IDS,
	)
	check.call(
		"data_v3_item_closure_exact_trainer_bag_runtime_frontier",
		registry.runtime_supported_trainer_item_ids() == EXPECTED_TRAINER_ITEM_IDS,
	)

	var every_runtime_id_is_canonical := true
	for item_id in EXPECTED_HELD_RUNTIME_IDS + EXPECTED_TRAINER_ITEM_IDS:
		every_runtime_id_is_canonical = every_runtime_id_is_canonical and unique_ids.has(String(item_id))
	check.call("data_v3_item_closure_all_runtime_ids_exist_in_data_v3", every_runtime_id_is_canonical)

	# Calvo V1 execution semantics are intentionally explicit and version-pinned.
	# They must not be reconstructed from PokeAPI's historical effect_entry prose.
	check.call(
		"data_v3_item_closure_trainer_healing_contract_20_60_120_full",
		_fixed_heal_amount(registry, &"potion") == 20
		and _fixed_heal_amount(registry, &"super_potion") == 60
		and _fixed_heal_amount(registry, &"hyper_potion") == 120
		and _full_heal(registry, &"max_potion"),
	)
	check.call(
		"data_v3_item_closure_full_restore_is_full_heal_plus_status_cure",
		_full_heal(registry, &"full_restore") and _has_status_cure(registry, &"full_restore"),
	)

	var super_description := _description_for(items, "super_potion")
	var hyper_description := _description_for(items, "hyper_potion")
	check.call(
		"data_v3_item_closure_historical_metadata_must_not_define_runtime_healing",
		super_description.contains("50")
		and hyper_description.contains("200")
		and _fixed_heal_amount(registry, &"super_potion") == 60
		and _fixed_heal_amount(registry, &"hyper_potion") == 120,
	)

	# Oran Berry is source-compatible with existing primitives but deliberately
	# deferred from the certified runtime frontier until held-item selection/loadouts
	# are reopened. Presence in DATA V3 must not silently make it executable.
	check.call(
		"data_v3_item_closure_oran_berry_deliberately_deferred",
		unique_ids.has("oran_berry")
		and not registry.runtime_supported_item_ids().has(&"oran_berry")
		and registry.triggers_for_item(&"oran_berry", BattleTriggerSpec.AFTER_DAMAGE).is_empty(),
	)


func _fixed_heal_amount(registry: BattleEffectRegistry, item_id: StringName) -> int:
	for spec in registry.effects_for_trainer_item(item_id):
		if spec.kind == BattleEffectSpec.HEAL:
			return spec.value
	return -1


func _full_heal(registry: BattleEffectRegistry, item_id: StringName) -> bool:
	for spec in registry.effects_for_trainer_item(item_id):
		if spec.kind == BattleEffectSpec.HEAL:
			return spec.value == 0 and spec.ratio_basis_points == 10000
	return false


func _has_status_cure(registry: BattleEffectRegistry, item_id: StringName) -> bool:
	for spec in registry.effects_for_trainer_item(item_id):
		if spec.kind == BattleEffectSpec.CURE_STATUS:
			return true
	return false


func _description_for(items: Array, item_id: String) -> String:
	for raw_item in items:
		if raw_item is Dictionary and str(raw_item.get("id", "")) == item_id:
			return str(raw_item.get("description", ""))
	return ""


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	return JSON.parse_string(file.get_as_text()) as Dictionary
