class_name DataFoundationV3EvolutionClosureTestSuite
extends RefCounted

# Honest capability boundary for Evolutions V3. Source conditions are preserved
# verbatim, but only mechanics proven executable by EvolutionSystem may become
# runtime candidates.
const EXPECTED_EVOLUTION_COUNT := 554
const EXPECTED_CONDITIONED_COUNT := 165
const EXPECTED_CLASS_COUNTS := {
	EvolutionSystem.RUNTIME_SUPPORTED: 391,
	EvolutionSystem.PARTIAL: 0,
	EvolutionSystem.DATA_ONLY: 149,
	EvolutionSystem.UNSUPPORTED: 14,
}
const EXPECTED_TRIGGER_COUNTS := {
	"agile_style_move": 1,
	"gimmighoul_coins": 1,
	"level_up": 438,
	"other": 1,
	"recoil_damage": 1,
	"shed": 1,
	"spin": 1,
	"strong_style_move": 1,
	"take_damage": 1,
	"three_critical_hits": 1,
	"three_defeated_bisharp": 1,
	"tower_of_darkness": 1,
	"tower_of_waters": 1,
	"trade": 30,
	"use_item": 72,
	"use_move": 2,
}
const EXPECTED_CONDITION_KEY_COUNTS := {
	"base_form": 58,
	"evolved_form": 40,
	"gender": 6,
	"held_item": 20,
	"known_move": 15,
	"known_move_type": 2,
	"location": 25,
	"min_affection": 1,
	"min_beauty": 2,
	"min_damage_taken": 2,
	"min_happiness": 20,
	"min_move_count": 4,
	"min_steps": 3,
	"near_special_rock": 10,
	"needs_multiplayer": 1,
	"needs_overworld_rain": 2,
	"party_species": 1,
	"party_type": 1,
	"region": 13,
	"relative_physical_stats": 2,
	"time_of_day": 22,
	"trade_species": 2,
	"turn_upside_down": 1,
	"used_move": 4,
}


func run(check: Callable) -> void:
	var raw := _load_json("res://data/raw/pokemon_api.json")
	var species: Array = raw.get("species", [])
	var items: Array = raw.get("items", [])
	var species_ids := {}
	var item_ids := {}
	for raw_species in species:
		if raw_species is Dictionary:
			species_ids[str(raw_species.get("id", ""))] = true
	for raw_item in items:
		if raw_item is Dictionary:
			item_ids[str(raw_item.get("id", ""))] = true

	var total := 0
	var conditioned := 0
	var trigger_counts := {}
	var condition_key_counts := {}
	var class_counts := {
		EvolutionSystem.RUNTIME_SUPPORTED: 0,
		EvolutionSystem.PARTIAL: 0,
		EvolutionSystem.DATA_ONLY: 0,
		EvolutionSystem.UNSUPPORTED: 0,
	}
	var broken_targets := 0
	var broken_items := 0
	var conditioned_runtime_violation := false
	var redundant_base_form_runtime := 0

	for raw_species in species:
		if not (raw_species is Dictionary):
			continue
		var source_id := str(raw_species.get("id", ""))
		for raw_evolution in raw_species.get("evolutions", []):
			if not (raw_evolution is Dictionary):
				continue
			var evolution: Dictionary = raw_evolution
			total += 1
			var trigger := str(evolution.get("trigger", ""))
			trigger_counts[trigger] = int(trigger_counts.get(trigger, 0)) + 1
			var conditions: Dictionary = evolution.get("conditions", {}) as Dictionary
			if not conditions.is_empty():
				conditioned += 1
				for key in conditions.keys():
					var key_text := str(key)
					condition_key_counts[key_text] = int(condition_key_counts.get(key_text, 0)) + 1

			if not species_ids.has(str(evolution.get("species_id", ""))):
				broken_targets += 1
			if trigger == "use_item":
				var item_id := str(evolution.get("item_id", ""))
				if item_id.is_empty() or not item_ids.has(item_id):
					broken_items += 1

			var record := EvolutionRecord.from_dict(evolution)
			var cls := EvolutionSystem.classify_record(record, null, StringName(source_id))
			class_counts[cls] = int(class_counts.get(cls, 0)) + 1
			if cls == EvolutionSystem.RUNTIME_SUPPORTED and not conditions.is_empty():
				var redundant := (
					conditions.size() == 1
					and conditions.has("base_form")
					and str(conditions.get("base_form", "")) == source_id
				)
				conditioned_runtime_violation = conditioned_runtime_violation or not redundant
				if redundant:
					redundant_base_form_runtime += 1

	check.call("data_v3_evolution_closure_exact_record_count", total == EXPECTED_EVOLUTION_COUNT)
	check.call("data_v3_evolution_closure_exact_trigger_partition", _counts_match(trigger_counts, EXPECTED_TRIGGER_COUNTS))
	check.call("data_v3_evolution_closure_exact_conditioned_count", conditioned == EXPECTED_CONDITIONED_COUNT)
	check.call("data_v3_evolution_closure_exact_condition_key_inventory", _counts_match(condition_key_counts, EXPECTED_CONDITION_KEY_COUNTS))
	check.call("data_v3_evolution_closure_no_broken_target_species", broken_targets == 0)
	check.call("data_v3_evolution_closure_no_broken_use_item_refs", broken_items == 0)
	check.call("data_v3_evolution_closure_exact_runtime_boundary_391_149_14", _counts_match(class_counts, EXPECTED_CLASS_COUNTS))
	check.call("data_v3_evolution_closure_no_real_condition_silently_executes", not conditioned_runtime_violation)
	check.call("data_v3_evolution_closure_exact_redundant_base_form_exceptions", redundant_base_form_runtime == 7)
	check.call("data_v3_evolution_closure_normalized_exotic_triggers_unsupported", _all_exotic_triggers_unsupported())
	check.call("data_v3_evolution_closure_candidates_gate_data_only_conditions", _candidate_gate_is_honest())


func _all_exotic_triggers_unsupported() -> bool:
	for trigger in EvolutionSystem.UNSUPPORTED_TRIGGERS:
		var record := EvolutionRecord.new(&"target", 0, trigger)
		if EvolutionSystem.classify_record(record, null, &"source") != EvolutionSystem.UNSUPPORTED:
			return false
	return EvolutionSystem.UNSUPPORTED_TRIGGERS.size() == 13


func _candidate_gate_is_honest() -> bool:
	var species := CreatureSpecies.new()
	species.id = &"eevee"
	# Real conditions that the current runtime cannot evaluate must never degrade to
	# simple level/trade eligibility.
	species.evolutions.append(EvolutionRecord.new(
		&"espeon", 0, EvolutionSystem.TRIGGER_LEVEL_UP, &"", &"", true,
		{"min_happiness": 160, "time_of_day": "day", "base_form": "eevee"},
	))
	species.evolutions.append(EvolutionRecord.new(
		&"scizor", 0, EvolutionSystem.TRIGGER_TRADE, &"", &"", true,
		{"held_item": "metal_coat"},
	))
	# A sole selector naming the base species already being evaluated is redundant
	# and remains executable.
	species.evolutions.append(EvolutionRecord.new(
		&"vaporeon", 0, EvolutionSystem.TRIGGER_USE_ITEM, &"water_stone", &"", true,
		{"base_form": "eevee"},
	))
	var candidates := EvolutionSystem.evolution_candidates(
		species,
		{"level": 100, "item_id": &"water_stone", "traded": true},
		null,
	)
	return (
		candidates.size() == 1
		and (candidates[0] as EvolutionRecord).species_id == &"vaporeon"
	)


func _counts_match(actual: Dictionary, expected: Dictionary) -> bool:
	if actual.size() != expected.size():
		return false
	for key in expected.keys():
		if int(actual.get(key, -1)) != int(expected[key]):
			return false
	return true


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	return JSON.parse_string(file.get_as_text()) as Dictionary
