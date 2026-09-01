class_name DataFoundationV3AbilityRuntimeContractTestSuite
extends RefCounted

const FULL_IDS := [
	"blaze", "dragons_maw", "fire_mane", "fur_coat", "ice_scales", "multiscale",
	"overgrow", "rocky_payload", "steelworker", "swarm", "thick_fat", "torrent",
	"tough_claws",
]
const PARTIAL_IDS := [
	"flame_body", "gooey", "heatproof", "intimidate", "levitate", "poison_point",
	"reckless", "stamina", "static",
]
const IMPLEMENTED_IDS := [
	"blaze", "dragons_maw", "fire_mane", "flame_body", "fur_coat", "gooey",
	"heatproof", "ice_scales", "intimidate", "levitate", "multiscale", "overgrow",
	"poison_point", "reckless", "rocky_payload", "stamina", "static", "steelworker",
	"swarm", "thick_fat", "torrent", "tough_claws",
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
		(classes.get("DATA_ONLY", []) as Array).size() == 351,
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

	# Unconditional type boosts must use only move type + 1.5x. In particular,
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

	# Tough Claws has an explicit DATA V3 semantic correction: the pinned PokeAPI
	# snapshot says 1.33x, while audited current main-series mechanics are +30%.
	# Canonical data and runtime must therefore agree on the corrected 1.30x contract.
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

	# Reckless is deliberately PARTIAL_RUNTIME: a structured RECOIL effect is a
	# trustworthy runtime property and gets the exact 1.2x boost, while crash-on-miss
	# moves are not yet represented by that transaction and therefore remain absent.
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

	# Defensive damage reducers use the same target-owned MODIFY_DAMAGE transaction.
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

	# Heatproof is deliberately partial: the Fire-move half-damage subset is exact,
	# while burn residual currently bypasses the ability trigger system entirely.
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

	# Defender-owned contact reactions are deliberately partial for the same reason
	# as Static: AFTER_DAMAGE is not requested for a defender that fainted from the
	# contact hit. Their ordinary surviving-hit transactions are exact and explicit.
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

	# Fluffy is deliberately blocked even though its two numeric predicates are
	# individually expressible. A Fire contact move satisfies both rules at once;
	# the current multi-spec registry would emit two ABILITY_TRIGGERED events for one
	# ability activation. Keep it non-executable until modifier composition/event
	# aggregation is modeled explicitly.
	check.call(
		"data_v3_ability_contract_fluffy_stays_data_only",
		str((by_id.get("fluffy", {}) as Dictionary).get("classification", "")) == "DATA_ONLY"
		and registry.triggers_for_ability(&"fluffy", BattleTriggerSpec.MODIFY_DAMAGE).is_empty(),
	)

	# Filter and Solid Rock need a super-effective predicate. Type effectiveness is
	# produced later by DamageCalculator, after damage_modifiers() currently runs, so
	# duplicating type-chart logic here would be a new subsystem rather than a safe
	# predicate extension.
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

	# Huge Power and Pure Power double the Attack stat; they do not simply multiply
	# every physical move's final damage. Until Battle Core has an offensive-stat
	# multiplier primitive, both remain deliberately non-executable DATA_ONLY.
	var attack_doublers_safe := true
	for ability_id in ["huge_power", "pure_power"]:
		var record: Dictionary = by_id.get(ability_id, {})
		attack_doublers_safe = attack_doublers_safe and (
			str(record.get("classification", "")) == "DATA_ONLY"
			and str(record.get("description", "")) == "Doubles Attack in battle."
			and registry.triggers_for_ability(StringName(ability_id), BattleTriggerSpec.MODIFY_DAMAGE).is_empty()
		)
	check.call("data_v3_ability_contract_attack_doublers_stay_data_only", attack_doublers_safe)

	# Adjacent move-property abilities are explicit blockers. Long Reach needs the
	# attacking creature to be available while evaluating defender-owned contact
	# triggers; Technician needs resolved/variable power rather than a static field;
	# punch/bite/pulse/slicing categories are not retained in MoveDefinition today.
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
		and int(summary.get("RUNTIME_SUPPORTED", -1)) == 13
		and int(summary.get("PARTIAL_RUNTIME", -1)) == 9
		and int(summary.get("DATA_ONLY", -1)) == 351,
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
