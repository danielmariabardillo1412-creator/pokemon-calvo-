class_name DataFoundationV3AbilityRuntimeContractTestSuite
extends RefCounted

const FULL_IDS := [
	"blaze", "defeatist", "dragons_maw", "fire_mane", "flare_boost", "fur_coat",
	"huge_power", "ice_scales", "multiscale", "overgrow", "pure_power", "rocky_payload",
	"steelworker", "swarm", "thick_fat", "torrent", "tough_claws", "toxic_boost",
]
const PARTIAL_IDS := [
	"dry_skin", "flame_body", "gooey", "guts", "heatproof", "hustle", "intimidate",
	"iron_barbs", "levitate", "poison_point", "reckless", "stamina", "static", "water_bubble",
]
const IMPLEMENTED_IDS := [
	"blaze", "defeatist", "dragons_maw", "dry_skin", "fire_mane", "flame_body",
	"flare_boost", "fur_coat", "gooey", "guts", "heatproof", "huge_power", "hustle",
	"ice_scales", "intimidate", "iron_barbs", "levitate", "multiscale", "overgrow",
	"poison_point", "pure_power", "reckless", "rocky_payload", "stamina", "static",
	"steelworker", "swarm", "thick_fat", "torrent", "tough_claws", "toxic_boost",
	"water_bubble",
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
		(classes.get("DATA_ONLY", []) as Array).size() == 341,
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

	# Every ability MODIFY_DAMAGE spec must now be explicitly directional. Missing
	# roles are fail-safe inert in BattleTriggerSystem rather than applying both ways.
	var damage_roles_explicit := true
	var damage_spec_count := 0
	for ability_id in IMPLEMENTED_IDS:
		for spec in registry.triggers_for_ability(StringName(ability_id), BattleTriggerSpec.MODIFY_DAMAGE):
			damage_spec_count += 1
			var role := String(spec.conditions.get("damage_role", ""))
			damage_roles_explicit = damage_roles_explicit and role in ["actor", "target"]
	check.call(
		"data_v3_ability_contract_damage_roles_explicit",
		damage_spec_count > 0 and damage_roles_explicit,
	)

	# Swarm remains the fourth member of the tested pinch-damage primitive.
	var swarm_specs := registry.triggers_for_ability(&"swarm", BattleTriggerSpec.MODIFY_DAMAGE)
	var swarm_ok := swarm_specs.size() == 1
	if swarm_ok:
		var swarm: BattleTriggerSpec = swarm_specs[0]
		swarm_ok = (
			swarm.source_kind == &"ability"
			and swarm.source_id == &"swarm"
			and String(swarm.conditions.get("damage_role", "")) == "actor"
			and String(swarm.conditions.get("move_type_id", "")) == "bug"
			and int(swarm.conditions.get("hp_at_or_below_divisor", 0)) == 3
			and int(swarm.conditions.get("multiplier_bp", 0)) == 15000
			and swarm.effect.kind == BattleEffectSpec.DAMAGE
		)
	check.call("data_v3_ability_contract_swarm_trigger_exact", swarm_ok)

	# Unconditional type boosts must use only actor role + move type + 1.5x. In
	# particular, they must not inherit the pinch HP condition or another state gate.
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
			and String(spec.conditions.get("damage_role", "")) == "actor"
			and String(spec.conditions.get("move_type_id", "")) == TYPE_BOOSTS[ability_id]
			and int(spec.conditions.get("multiplier_bp", 0)) == 15000
			and not spec.conditions.has("hp_at_or_below_divisor")
			and spec.effect.kind == BattleEffectSpec.DAMAGE
		)
	check.call("data_v3_ability_contract_unconditional_type_boosts_exact", type_boosts_ok)

	# Offensive-stat abilities must never masquerade as final-damage multipliers.
	# Huge/Pure double Attack; Toxic Boost raises Attack 1.5x under either poison
	# state; Flare Boost raises Special Attack 1.5x under burn.
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
			and String(spec.conditions.get("damage_role", "")) == "actor"
			and bool(spec.conditions.get("requires_physical", false)) == bool(expected.physical)
			and bool(spec.conditions.get("requires_special", false)) == bool(expected.special)
			and int(spec.conditions.get("offensive_stat_multiplier_bp", 0)) == int(expected.multiplier)
			and statuses == (expected.statuses as Array)
			and not spec.conditions.has("multiplier_bp")
			and spec.effect.kind == BattleEffectSpec.DAMAGE
		)
	check.call("data_v3_ability_contract_offensive_stat_modifiers_exact", offensive_stat_specs_ok)

	# Defeatist is fully expressible as two mutually-exclusive class predicates that
	# halve the actual offensive stat at or below half HP, before the damage formula.
	var defeatist_specs := registry.triggers_for_ability(&"defeatist", BattleTriggerSpec.MODIFY_DAMAGE)
	var defeatist_ok := defeatist_specs.size() == 2
	var defeatist_classes := {}
	for spec in defeatist_specs:
		var class_id := "physical" if bool(spec.conditions.get("requires_physical", false)) else (
			"special" if bool(spec.conditions.get("requires_special", false)) else ""
		)
		defeatist_classes[class_id] = int(spec.conditions.get("offensive_stat_multiplier_bp", 0))
		defeatist_ok = defeatist_ok and (
			spec.source_kind == &"ability"
			and spec.source_id == &"defeatist"
			and String(spec.conditions.get("damage_role", "")) == "actor"
			and int(spec.conditions.get("hp_at_or_below_divisor", 0)) == 2
			and int(spec.conditions.get("offensive_stat_multiplier_bp", 0)) == 5000
			and not spec.conditions.has("multiplier_bp")
			and spec.effect.kind == BattleEffectSpec.DAMAGE
		)
	check.call(
		"data_v3_ability_contract_defeatist_trigger_exact",
		defeatist_ok and defeatist_classes == {"physical": 5000, "special": 5000},
	)

	# Guts is deliberately partial. The safe current subset is paralysis and both
	# poison representations. Burn is excluded because its source also suppresses the
	# normal burn Attack cut; sleep is excluded because pinned history is version-sensitive.
	var guts_specs := registry.triggers_for_ability(&"guts", BattleTriggerSpec.MODIFY_DAMAGE)
	var guts_ok := guts_specs.size() == 1
	if guts_ok:
		var guts: BattleTriggerSpec = guts_specs[0]
		var guts_statuses: Array = guts.conditions.get("required_persistent_status_ids", [])
		guts_ok = (
			guts.source_kind == &"ability"
			and guts.source_id == &"guts"
			and String(guts.conditions.get("damage_role", "")) == "actor"
			and bool(guts.conditions.get("requires_physical", false))
			and not bool(guts.conditions.get("requires_special", false))
			and guts_statuses == ["paralysis", "poison", "badly_poisoned"]
			and not guts_statuses.has("burn")
			and not guts_statuses.has("sleep")
			and int(guts.conditions.get("offensive_stat_multiplier_bp", 0)) == 15000
			and not guts.conditions.has("multiplier_bp")
			and guts.effect.kind == BattleEffectSpec.DAMAGE
		)
	check.call("data_v3_ability_contract_guts_partial_trigger_exact", guts_ok)

	# Hustle is partial: regular physical damage gets the exact 1.5x final-damage
	# transaction, while the source-required 0.8x accuracy mechanic is absent.
	var hustle_specs := registry.triggers_for_ability(&"hustle", BattleTriggerSpec.MODIFY_DAMAGE)
	var hustle_ok := hustle_specs.size() == 1
	if hustle_ok:
		var hustle: BattleTriggerSpec = hustle_specs[0]
		hustle_ok = (
			hustle.source_kind == &"ability"
			and hustle.source_id == &"hustle"
			and String(hustle.conditions.get("damage_role", "")) == "actor"
			and bool(hustle.conditions.get("requires_physical", false))
			and int(hustle.conditions.get("multiplier_bp", 0)) == 15000
			and not hustle.conditions.has("offensive_stat_multiplier_bp")
			and hustle.effect.kind == BattleEffectSpec.DAMAGE
		)
	check.call("data_v3_ability_contract_hustle_partial_trigger_exact", hustle_ok)

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
			and String(tough.conditions.get("damage_role", "")) == "actor"
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
			and String(reckless.conditions.get("damage_role", "")) == "actor"
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
			and String(fur.conditions.get("damage_role", "")) == "target"
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
			and String(spec.conditions.get("damage_role", "")) == "target"
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
			and String(ice.conditions.get("damage_role", "")) == "target"
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
			and String(multi.conditions.get("damage_role", "")) == "target"
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
			and String(heat.conditions.get("damage_role", "")) == "target"
			and String(heat.conditions.get("move_type_id", "")) == "fire"
			and int(heat.conditions.get("multiplier_bp", 0)) == 5000
			and heat.effect.kind == BattleEffectSpec.DAMAGE
		)
	check.call("data_v3_ability_contract_heatproof_partial_trigger_exact", heat_ok)

	# Dry Skin's Fire vulnerability is exact; weather and Water absorption are still
	# absent, so the ability remains partial.
	var dry_specs := registry.triggers_for_ability(&"dry_skin", BattleTriggerSpec.MODIFY_DAMAGE)
	var dry_ok := dry_specs.size() == 1
	if dry_ok:
		var dry: BattleTriggerSpec = dry_specs[0]
		dry_ok = (
			dry.source_kind == &"ability"
			and dry.source_id == &"dry_skin"
			and String(dry.conditions.get("damage_role", "")) == "target"
			and String(dry.conditions.get("move_type_id", "")) == "fire"
			and int(dry.conditions.get("multiplier_bp", 0)) == 12500
			and dry.effect.kind == BattleEffectSpec.DAMAGE
		)
	check.call("data_v3_ability_contract_dry_skin_partial_trigger_exact", dry_ok)

	# Water Bubble uses two opposite-direction specs. Role isolation is required so
	# outgoing Water x2 cannot become incoming Water x2 and incoming Fire x0.5 cannot
	# halve the holder's own Fire attacks. Burn prevention/cure remains absent.
	var bubble_specs := registry.triggers_for_ability(&"water_bubble", BattleTriggerSpec.MODIFY_DAMAGE)
	var bubble_ok := bubble_specs.size() == 2
	var bubble_actor_ok := false
	var bubble_target_ok := false
	for spec in bubble_specs:
		var role := String(spec.conditions.get("damage_role", ""))
		if role == "actor":
			bubble_actor_ok = (
				String(spec.conditions.get("move_type_id", "")) == "water"
				and int(spec.conditions.get("multiplier_bp", 0)) == 20000
				and spec.effect.kind == BattleEffectSpec.DAMAGE
			)
		elif role == "target":
			bubble_target_ok = (
				String(spec.conditions.get("move_type_id", "")) == "fire"
				and int(spec.conditions.get("multiplier_bp", 0)) == 5000
				and spec.effect.kind == BattleEffectSpec.DAMAGE
			)
		else:
			bubble_ok = false
		bubble_ok = bubble_ok and spec.source_kind == &"ability" and spec.source_id == &"water_bubble"
	check.call(
		"data_v3_ability_contract_water_bubble_partial_triggers_exact",
		bubble_ok and bubble_actor_ok and bubble_target_ok,
	)

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

	# Iron Barbs reuses defender AFTER_DAMAGE but its payload is a generic max-HP
	# fraction damage effect targeted at the attacker. It remains partial because
	# current AFTER_DAMAGE is neither per-strike for multi-hit nor faint-safe for the owner.
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

	# Rough Skin has the same current 1/8 prose but the pinned source preserves a
	# historical 1/16 battle value. Until ability runtime contracts are version-aware,
	# it must not inherit Iron Barbs' universal 1/8 mapping.
	check.call(
		"data_v3_ability_contract_rough_skin_stays_data_only",
		str((by_id.get("rough_skin", {}) as Dictionary).get("classification", "")) == "DATA_ONLY"
		and registry.triggers_for_ability(&"rough_skin", BattleTriggerSpec.AFTER_DAMAGE).is_empty(),
	)

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

	# The pinned snapshot has no numeric boost value for either record. Guard them as
	# DATA_ONLY rather than importing an external multiplier into canonical DATA V3.
	var prose_only_boosts_safe := true
	for ability_id in ["gorilla_tactics", "steely_spirit"]:
		prose_only_boosts_safe = prose_only_boosts_safe and (
			str((by_id.get(ability_id, {}) as Dictionary).get("classification", "")) == "DATA_ONLY"
			and registry.triggers_for_ability(StringName(ability_id), BattleTriggerSpec.MODIFY_DAMAGE).is_empty()
		)
	check.call("data_v3_ability_contract_prose_only_boosts_stay_data_only", prose_only_boosts_safe)

	var report := _load_json("res://data/reports/unsupported_mechanics.json")
	var summary: Dictionary = report.get("summary", {}).get("abilities", {})
	check.call(
		"data_v3_ability_contract_report_counts",
		int(summary.get("DATA_READY", -1)) == 373
		and int(summary.get("RUNTIME_SUPPORTED", -1)) == 18
		and int(summary.get("PARTIAL_RUNTIME", -1)) == 14
		and int(summary.get("DATA_ONLY", -1)) == 341,
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
