class_name DataFoundationV3AbilityRuntimeContractTestSuite
extends RefCounted

const FULL_IDS := ["blaze", "overgrow", "swarm", "torrent"]
const PARTIAL_IDS := ["intimidate", "levitate", "static"]
const IMPLEMENTED_IDS := ["blaze", "intimidate", "levitate", "overgrow", "static", "swarm", "torrent"]


func run(check: Callable) -> void:
	var raw := _load_json("res://data/raw/pokemon_api.json")
	var abilities: Array = raw.get("abilities", [])
	var by_id := _by_id(abilities)
	var classes := _ids_by_classification(abilities)

	check.call("data_v3_ability_contract_total", abilities.size() == 373)
	check.call(
		"data_v3_ability_contract_runtime_supported_exact",
		classes.get("RUNTIME_SUPPORTED", []) == FULL_IDS,
	)
	check.call(
		"data_v3_ability_contract_partial_exact",
		classes.get("PARTIAL_RUNTIME", []) == PARTIAL_IDS,
	)
	check.call(
		"data_v3_ability_contract_data_only_count",
		(classes.get("DATA_ONLY", []) as Array).size() == 366,
	)
	check.call(
		"data_v3_ability_contract_partition",
		(classes.get("RUNTIME_SUPPORTED", []) as Array).size()
		+ (classes.get("PARTIAL_RUNTIME", []) as Array).size()
		+ (classes.get("DATA_ONLY", []) as Array).size() == 373,
	)
	check.call(
		"data_v3_ability_contract_no_unexpected_class",
		classes.keys().all(func(key): return key in ["RUNTIME_SUPPORTED", "PARTIAL_RUNTIME", "DATA_ONLY"]),
	)

	var audited_present := true
	for ability_id in IMPLEMENTED_IDS:
		audited_present = audited_present and by_id.has(ability_id)
	check.call("data_v3_ability_contract_audited_ids_present", audited_present)

	# The old runtime_supported_ability_ids() API remains frozen for the historical
	# Battle V2 fixture. DATA V3 uses the actual trigger registry inventory instead.
	var registry := BattleEffectRegistry.new()
	var registry_ids: Array[String] = []
	for ability_id in registry.implemented_ability_ids():
		registry_ids.append(String(ability_id))
	registry_ids.sort()
	check.call("data_v3_ability_contract_registry_exact", registry_ids == IMPLEMENTED_IDS)

	# Swarm is the fourth member of the already-tested pinch-damage primitive. Its
	# trigger must be exactly Bug + <=1/3 HP + 1.5x and must not invent a new path.
	var swarm_specs := registry.triggers_for_ability(&"swarm", BattleTriggerSpec.MODIFY_DAMAGE)
	var swarm_ok := swarm_specs.size() == 1
	if swarm_ok:
		var swarm: BattleTriggerSpec = swarm_specs[0]
		swarm_ok = (
			swarm.source_kind == &"ability"
			and swarm.source_id == &"swarm"
			and String(swarm.conditions.get("move_type_id", "")) == "bug"
			and int(swarm.conditions.get("hp_at_or_below_divisor", 0)) == 3
			and int(swarm.conditions.get("multiplier_bp", 0)) == 15000
			and swarm.effect.kind == BattleEffectSpec.DAMAGE
		)
	check.call("data_v3_ability_contract_swarm_trigger_exact", swarm_ok)

	var report := _load_json("res://data/reports/unsupported_mechanics.json")
	var summary: Dictionary = report.get("summary", {}).get("abilities", {})
	check.call(
		"data_v3_ability_contract_report_counts",
		int(summary.get("DATA_READY", -1)) == 373
		and int(summary.get("RUNTIME_SUPPORTED", -1)) == 4
		and int(summary.get("PARTIAL_RUNTIME", -1)) == 3
		and int(summary.get("DATA_ONLY", -1)) == 366,
	)
	var report_classes: Dictionary = report.get("ability_runtime_classification", {})
	check.call(
		"data_v3_ability_contract_report_ids",
		(report_classes.get("RUNTIME_SUPPORTED", []) as Array) == FULL_IDS
		and (report_classes.get("PARTIAL_RUNTIME", []) as Array) == PARTIAL_IDS,
	)


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	return JSON.parse_string(file.get_as_text()) as Dictionary


func _by_id(records: Array) -> Dictionary:
	var result := {}
	for record in records:
		if record is Dictionary:
			result[str(record.get("id", ""))] = record
	return result


func _ids_by_classification(records: Array) -> Dictionary:
	var result := {}
	for record in records:
		if not (record is Dictionary):
			continue
		var classification := str(record.get("classification", ""))
		if not result.has(classification):
			result[classification] = []
		(result[classification] as Array).append(str(record.get("id", "")))
	for classification in result:
		(result[classification] as Array).sort()
	return result
