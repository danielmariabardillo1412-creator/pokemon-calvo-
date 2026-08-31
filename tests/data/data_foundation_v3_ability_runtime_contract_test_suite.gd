class_name DataFoundationV3AbilityRuntimeContractTestSuite
extends RefCounted

const FULL_IDS := [
	"blaze", "dragons_maw", "fire_mane", "overgrow", "rocky_payload",
	"steelworker", "swarm", "torrent",
]
const PARTIAL_IDS := ["intimidate", "levitate", "stamina", "static"]
const IMPLEMENTED_IDS := [
	"blaze", "dragons_maw", "fire_mane", "intimidate", "levitate", "overgrow",
	"rocky_payload", "stamina", "static", "steelworker", "swarm", "torrent",
]
const TYPE_BOOSTS := {
	"steelworker": "steel",
	"dragons_maw": "dragon",
	"rocky_payload": "rock",
	"fire_mane": "fire",
}


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
		(classes.get("DATA_ONLY", []) as Array).size() == 361,
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

	# Swarm remains the fourth member of the tested pinch-damage primitive.
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

	# New unconditional type boosts must use only move type + 1.5x. In particular,
	# they must not inherit the pinch HP condition or another hidden state gate.
	var type_boosts_ok := true
	for ability_id in TYPE_BOOSTS:
		var specs := registry.triggers_for_ability(StringName(ability_id), BattleTriggerSpec.MODIFY_DAMAGE)
		if specs.size() != 1:
			type_boosts_ok = false
			continue
		var spec: BattleTriggerSpec = specs[0]
		type_boosts_ok = type_boosts_ok and (
			spec.source_kind == &"ability"
			and String(spec.source_id) == ability_id
			and String(spec.conditions.get("move_type_id", "")) == TYPE_BOOSTS[ability_id]
			and int(spec.conditions.get("multiplier_bp", 0)) == 15000
			and not spec.conditions.has("hp_at_or_below_divisor")
			and spec.effect.kind == BattleEffectSpec.DAMAGE
		)
	check.call("data_v3_ability_contract_unconditional_type_boosts_exact", type_boosts_ok)

	# Stamina is deliberately PARTIAL_RUNTIME. For an ordinary surviving damaging
	# move, the existing AFTER_DAMAGE transaction is exactly Defense +1 with no
	# contact/physical/type gate. Multi-hit per-strike and fatal-hit triggering are
	# not represented by the current executor, which is why this is not full support.
	var stamina_specs := registry.triggers_for_ability(&"stamina", BattleTriggerSpec.AFTER_DAMAGE)
	var stamina_ok := stamina_specs.size() == 1
	if stamina_ok:
		var stamina: BattleTriggerSpec = stamina_specs[0]
		stamina_ok = (
			stamina.source_kind == &"ability"
			and stamina.source_id == &"stamina"
			and stamina.conditions.is_empty()
			and stamina.effect.kind == BattleEffectSpec.MODIFY_STAT_STAGE
			and stamina.effect.target == BattleEffectSpec.SELF
			and stamina.effect.value == 1
			and stamina.effect.stat_id == StatStages.DEFENSE
		)
	check.call("data_v3_ability_contract_stamina_partial_trigger_exact", stamina_ok)

	# These adjacent hit-reaction abilities are explicit blockers, not forgotten
	# candidates. Water Compaction needs a Water-move AFTER_DAMAGE predicate; Weak
	# Armor needs a dual stat transaction plus per-hit/version-aware semantics.
	check.call(
		"data_v3_ability_contract_water_compaction_stays_data_only",
		str((by_id.get("water_compaction", {}) as Dictionary).get("classification", "")) == "DATA_ONLY",
	)
	check.call(
		"data_v3_ability_contract_weak_armor_stays_data_only",
		str((by_id.get("weak_armor", {}) as Dictionary).get("classification", "")) == "DATA_ONLY",
	)

	# Transistor remains DATA_ONLY because its version-sensitive multiplier is not
	# represented honestly by one universal source contract in the pinned snapshot.
	check.call(
		"data_v3_ability_contract_transistor_stays_data_only",
		str((by_id.get("transistor", {}) as Dictionary).get("classification", "")) == "DATA_ONLY",
	)

	var report := _load_json("res://data/reports/unsupported_mechanics.json")
	var summary: Dictionary = report.get("summary", {}).get("abilities", {})
	check.call(
		"data_v3_ability_contract_report_counts",
		int(summary.get("DATA_READY", -1)) == 373
		and int(summary.get("RUNTIME_SUPPORTED", -1)) == 8
		and int(summary.get("PARTIAL_RUNTIME", -1)) == 4
		and int(summary.get("DATA_ONLY", -1)) == 361,
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
