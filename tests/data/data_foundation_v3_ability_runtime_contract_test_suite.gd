class_name DataFoundationV3AbilityRuntimeContractTestSuite
extends RefCounted

const FULL_IDS := [
	"blaze", "dragons_maw", "fire_mane", "flare_boost", "fur_coat", "huge_power",
	"ice_scales", "multiscale", "overgrow", "pure_power", "rocky_payload", "steelworker",
	"swarm", "thick_fat", "torrent", "tough_claws", "toxic_boost",
]
const PARTIAL_IDS := [
	"flame_body", "gooey", "heatproof", "intimidate", "iron_barbs", "levitate",
	"poison_point", "reckless", "stamina", "static",
]
const IMPLEMENTED_IDS := [
	"blaze", "dragons_maw", "fire_mane", "flame_body", "flare_boost", "fur_coat",
	"gooey", "heatproof", "huge_power", "ice_scales", "intimidate", "iron_barbs",
	"levitate", "multiscale", "overgrow", "poison_point", "pure_power", "reckless",
	"rocky_payload", "stamina", "static", "steelworker", "swarm", "thick_fat", "torrent",
	"tough_claws", "toxic_boost",
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
		(classes.get("DATA_ONLY", []) as Array).size() == 346,
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

	var registry := BattleEffectRegistry.new()
	var registry_ids: Array[String] = []
	for ability_id in registry.implemented_ability_ids():
		registry_ids.append(String(ability_id))
	registry_ids.sort()
	check.call("data_v3_ability_contract_registry_exact", registry_ids == IMPLEMENTED_IDS)

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

	var offensive_stat_specs_ok := true
	var offensive_expected := {
		"huge_power": {"physical": true, "special": false, "multiplier": 20000, "statuses": []},
		"pure_power": {"physical": true, "special": false, "multiplier": 20000, "statuses": []},
		"toxic_boost": {
			"physical": true,
			"special": false,
			"multiplier": 15000,
			"statuses": ["poison", "badly_poisoned"],
		},
		"flare_boost": {
			"physical": false,
			"special": true,
			"multiplier": 15000,
			"statuses": ["burn"],
		},
	}
	for ability_id in offensive_expected:
		var expected: Dictionary = offensive_expected[ability_id]
		var specs := registry.triggers_for_ability(StringName(ability_id), BattleTriggerSpec.MODIFY_DAMAGE)
		if specs.size() != 1:
			offensive_stat_specs_ok = false
			continue
		var spec: BattleTriggerSpec = specs[0]
		var statuses: Array = spec.conditions.get("required_persistent_status_ids", [])
		offensive_stat_specs_ok = offensive_stat_specs_ok and (
			spec.source_kind == &"ability"
			and String(spec.source_id) == ability_id
			and bool(spec.conditions.get("requires_physical", false)) == bool(expected.physical)
			and bool(spec.conditions.get("requires_special", false)) == bool(expected.special)
			and int(spec.conditions.get("offensive_stat_multiplier_bp", 0)) == int(expected.multiplier)
			and statuses == (expected.statuses as Array)
			and not spec.conditions.has("multiplier_bp")
			and spec.effect.kind == BattleEffectSpec.DAMAGE
		)
	check.call("data_v3_ability_contract_offensive_stat_modifiers_exact", offensive_stat_specs_ok)

	var tough_record: Dictionary = by_id.get("tough_claws", {})
	check.call(
		"data_v3_ability_contract_tough_claws_text_corrected",
		str(tough_record.get("description", "")) == "Boosts the power of moves that make contact by 30%."
		and str(tough_record.get("effect_summary", "")) == "Boosts the power of moves that make contact by 30%.",
	)
	var tough_specs := registry.triggers_for_ability(&"tough_claws", BattleTriggerSpec.MODIFY_DAMAGE)
	var tough_ok := tough_specs.size() == 1
	if tough_ok:
		var tough: BattleTriggerSpec = tough_specs[0]
		tough_ok = (
			tough.source_kind == &"ability"
			and tough.source_id == &"tough_claws"
			and bool(tough.conditions.get("requires_contact", false))
			and int(tough.conditions.get("multiplier_bp", 0)) == 13000
			and not tough.conditions.has("requires_physical")
			and not tough.conditions.has("move_type_id")
			and tough.effect.kind == BattleEffectSpec.DAMAGE
		)
	check.call("data_v3_ability_contract_tough_claws_trigger_exact", tough_ok)

	var reckless_specs := registry.triggers_for_ability(&"reckless", BattleTriggerSpec.MODIFY_DAMAGE)
	var reckless_ok := reckless_specs.size() == 1
	if reckless_ok:
		var reckless: BattleTriggerSpec = reckless_specs[0]
		reckless_ok = (
			reckless.source_kind == &"ability"
			and reckless.source_id == &"reckless"
			and bool(reckless.conditions.get("requires_recoil", false))
			and int(reckless.conditions.get("multiplier_bp", 0)) == 12000
			and reckless.effect.kind == BattleEffectSpec.DAMAGE
		)
	check.call("data_v3_ability_contract_reckless_partial_trigger_exact", reckless_ok)

	var fur_specs := registry.triggers_for_ability(&"fur_coat", BattleTriggerSpec.MODIFY_DAMAGE)
	var fur_ok := fur_specs.size() == 1
	if fur_ok:
		var fur: BattleTriggerSpec = fur_specs[0]
		fur_ok = (
			fur.source_kind == &"ability"
			and fur.source_id == &"fur_coat"
			and bool(fur.conditions.get("requires_physical", false))
			and int(fur.conditions.get("multiplier_bp", 0)) == 5000
			and not fur.conditions.has("move_type_id")
			and not fur.conditions.has("requires_contact")
			and fur.effect.kind == BattleEffectSpec.DAMAGE
		)
	check.call("data_v3_ability_contract_fur_coat_trigger_exact", fur_ok)

	var thick_specs := registry.triggers_for_ability(&"thick_fat", BattleTriggerSpec.MODIFY_DAMAGE)
	var thick_types := {}
	var thick_ok := thick_specs.size() == 2
	for spec in thick_specs:
		thick_types[String(spec.conditions.get("move_type_id", ""))] = int(
			spec.conditions.get("multiplier_bp", 0)
		)
		thick_ok = thick_ok and (
			spec.source_kind == &"ability"
			and spec.source_id == &"thick_fat"
			and not spec.conditions.has("requires_physical")
			and not spec.conditions.has("requires_contact")
			and spec.effect.kind == BattleEffectSpec.DAMAGE
		)
	check.call(
		"data_v3_ability_contract_thick_fat_trigger_exact",
		thick_ok and thick_types == {"fire": 5000, "ice": 5000},
	)

	var ice_specs := registry.triggers_for_ability(&"ice_scales", BattleTriggerSpec.MODIFY_DAMAGE)
	var ice_ok := ice_specs.size() == 1
	if ice_ok:
		var ice: BattleTriggerSpec = ice_specs[0]
		ice_ok = (
			ice.source_kind == &"ability"
			and ice.source_id == &"ice_scales"
			and bool(ice.conditions.get("requires_special", false))
			and int(ice.conditions.get("multiplier_bp", 0)) == 5000
			and not ice.conditions.has("requires_physical")
			and not ice.conditions.has("move_type_id")
			and ice.effect.kind == BattleEffectSpec.DAMAGE
		)
	check.call("data_v3_ability_contract_ice_scales_trigger_exact", ice_ok)

	var multi_specs := registry.triggers_for_ability(&"multiscale", BattleTriggerSpec.MODIFY_DAMAGE)
	var multi_ok := multi_specs.size() == 1
	if multi_ok:
		var multi: BattleTriggerSpec = multi_specs[0]
		multi_ok = (
			multi.source_kind == &"ability"
			and multi.source_id == &"multiscale"
			and bool(multi.conditions.get("requires_full_hp", false))
			and int(multi.conditions.get("multiplier_bp", 0)) == 5000
			and not multi.conditions.has("move_type_id")
			and multi.effect.kind == BattleEffectSpec.DAMAGE
		)
	check.call("data_v3_ability_contract_multiscale_trigger_exact", multi_ok)

	var heat_specs := registry.triggers_for_ability(&"heatproof", BattleTriggerSpec.MODIFY_DAMAGE)
	var heat_ok := heat_specs.size() == 1
	if heat_ok:
		var heat: BattleTriggerSpec = heat_specs[0]
		heat_ok = (
			heat.source_kind == &"ability"
			and heat.source_id == &"heatproof"
			and String(heat.conditions.get("move_type_id", "")) == "fire"
			and int(heat.conditions.get("multiplier_bp", 0)) == 5000
			and heat.effect.kind == BattleEffectSpec.DAMAGE
		)
	check.call("data_v3_ability_contract_heatproof_partial_trigger_exact", heat_ok)

	var contact_status_specs_ok := true
	for pair in [["flame_body", "burn"], ["poison_point", "poison"]]:
		var ability_id := String(pair[0])
		var status_id := String(pair[1])
		var specs := registry.triggers_for_ability(StringName(ability_id), BattleTriggerSpec.AFTER_DAMAGE)
		if specs.size() != 1:
			contact_status_specs_ok = false
			continue
		var spec: BattleTriggerSpec = specs[0]
		var effect := spec.effect
		var child_ok := effect.children.size() == 1
		if child_ok:
			var child: BattleEffectSpec = effect.children[0]
			child_ok = (
				child.kind == BattleEffectSpec.INFLICT_STATUS
				and child.target == BattleEffectSpec.OPPONENT
				and String(child.status_id) == status_id
			)
		contact_status_specs_ok = contact_status_specs_ok and (
			spec.source_kind == &"ability"
			and String(spec.source_id) == ability_id
			and bool(spec.conditions.get("requires_contact", false))
			and effect.kind == BattleEffectSpec.CHANCE
			and effect.chance_basis_points == 3000
			and child_ok
		)
	check.call("data_v3_ability_contract_contact_status_partials_exact", contact_status_specs_ok)

	var gooey_specs := registry.triggers_for_ability(&"gooey", BattleTriggerSpec.AFTER_DAMAGE)
	var gooey_ok := gooey_specs.size() == 1
	if gooey_ok:
		var gooey: BattleTriggerSpec = gooey_specs[0]
		gooey_ok = (
			gooey.source_kind == &"ability"
			and gooey.source_id == &"gooey"
			and bool(gooey.conditions.get("requires_contact", false))
			and gooey.effect.kind == BattleEffectSpec.MODIFY_STAT_STAGE
			and gooey.effect.target == BattleEffectSpec.OPPONENT
			and gooey.effect.value == -1
			and gooey.effect.stat_id == StatStages.SPEED
		)
	check.call("data_v3_ability_contract_gooey_partial_trigger_exact", gooey_ok)

	var iron_specs := registry.triggers_for_ability(&"iron_barbs", BattleTriggerSpec.AFTER_DAMAGE)
	var iron_ok := iron_specs.size() == 1
	if iron_ok:
		var iron: BattleTriggerSpec = iron_specs[0]
		iron_ok = (
			iron.source_kind == &"ability"
			and iron.source_id == &"iron_barbs"
			and bool(iron.conditions.get("requires_contact", false))
			and iron.effect.kind == BattleEffectSpec.MAX_HP_DAMAGE
			and iron.effect.target == BattleEffectSpec.OPPONENT
			and iron.effect.ratio_basis_points == 1250
		)
	check.call("data_v3_ability_contract_iron_barbs_partial_trigger_exact", iron_ok)

	check.call(
		"data_v3_ability_contract_rough_skin_stays_data_only",
		str((by_id.get("rough_skin", {}) as Dictionary).get("classification", "")) == "DATA_ONLY"
		and registry.triggers_for_ability(&"rough_skin", BattleTriggerSpec.AFTER_DAMAGE).is_empty(),
	)

	check.call(
		"data_v3_ability_contract_fluffy_stays_data_only",
		str((by_id.get("fluffy", {}) as Dictionary).get("classification", "")) == "DATA_ONLY"
		and registry.triggers_for_ability(&"fluffy", BattleTriggerSpec.MODIFY_DAMAGE).is_empty(),
	)

	var super_effective_blockers_safe := true
	for ability_id in ["filter", "solid_rock"]:
		super_effective_blockers_safe = super_effective_blockers_safe and (
			str((by_id.get(ability_id, {}) as Dictionary).get("classification", "")) == "DATA_ONLY"
			and registry.triggers_for_ability(StringName(ability_id), BattleTriggerSpec.MODIFY_DAMAGE).is_empty()
		)
	check.call(
		"data_v3_ability_contract_super_effective_reducers_stay_data_only",
		super_effective_blockers_safe,
	)

	var move_property_blockers_safe := true
	for ability_id in [
		"long_reach", "technician", "iron_fist", "strong_jaw", "mega_launcher", "sharpness",
	]:
		move_property_blockers_safe = move_property_blockers_safe and (
			str((by_id.get(ability_id, {}) as Dictionary).get("classification", "")) == "DATA_ONLY"
			and registry.triggers_for_ability(StringName(ability_id), BattleTriggerSpec.MODIFY_DAMAGE).is_empty()
			and registry.triggers_for_ability(StringName(ability_id), BattleTriggerSpec.AFTER_DAMAGE).is_empty()
		)
	check.call("data_v3_ability_contract_move_property_blockers_stay_data_only", move_property_blockers_safe)

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

	check.call(
		"data_v3_ability_contract_water_compaction_stays_data_only",
		str((by_id.get("water_compaction", {}) as Dictionary).get("classification", "")) == "DATA_ONLY",
	)
	check.call(
		"data_v3_ability_contract_weak_armor_stays_data_only",
		str((by_id.get("weak_armor", {}) as Dictionary).get("classification", "")) == "DATA_ONLY",
	)
	check.call(
		"data_v3_ability_contract_transistor_stays_data_only",
		str((by_id.get("transistor", {}) as Dictionary).get("classification", "")) == "DATA_ONLY",
	)

	var report := _load_json("res://data/reports/unsupported_mechanics.json")
	var summary: Dictionary = report.get("summary", {}).get("abilities", {})
	check.call(
		"data_v3_ability_contract_report_counts",
		int(summary.get("DATA_READY", -1)) == 373
		and int(summary.get("RUNTIME_SUPPORTED", -1)) == 17
		and int(summary.get("PARTIAL_RUNTIME", -1)) == 10
		and int(summary.get("DATA_ONLY", -1)) == 346,
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
