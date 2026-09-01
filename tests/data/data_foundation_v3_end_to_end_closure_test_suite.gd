class_name DataFoundationV3EndToEndClosureTestSuite
extends RefCounted

# Final cross-domain DATA Foundation V3 certification guard. Domain-specific suites
# remain authoritative for mechanic detail; this suite freezes the shared structural,
# provenance, identity and runtime-boundary contracts before returning to Trainer AI.
const EXPECTED_SCHEMA_VERSION := 2
const EXPECTED_DATASET_VERSION := "3.0.0"
const EXPECTED_SOURCE := "pokeapi/v2-snapshot"
const EXPECTED_SOURCE_COMMIT := "2f218ec3765c01c894a42bbbd074f15ddf3f32d1"
const EXPECTED_API_TREE := "8349ea1ce75716897fe96e02a15950d19edba6c3"
const EXPECTED_SCHEMA_TREE := "02e031e1928d7e9456bf6f7486daacc4b8946c84"
const EXPECTED_RULESET := "latest_conventional_mainline_per_species_v1"

const EXPECTED_TYPE_COUNT := 18
const EXPECTED_SPECIES_COUNT := 1025
const EXPECTED_MOVE_COUNT := 919
const EXPECTED_ABILITY_COUNT := 373
const EXPECTED_ITEM_COUNT := 2222
const EXPECTED_LEARNSET_COUNT := 61102
const EXPECTED_EVOLUTION_COUNT := 554
const EXPECTED_FORM_COUNT := 326
const EXPECTED_EXCLUDED_SHADOW_MOVES := 18

const EXPECTED_MOVE_CLASSES := {
	"RUNTIME_SUPPORTED": 590,
	"PARTIAL_RUNTIME": 71,
	"DATA_ONLY": 246,
	"UNSUPPORTED": 12,
}
const EXPECTED_ABILITY_CLASSES := {
	"RUNTIME_SUPPORTED": 21,
	"PARTIAL_RUNTIME": 14,
	"DATA_ONLY": 338,
}
const EXPECTED_EVOLUTION_CLASSES := {
	EvolutionSystem.RUNTIME_SUPPORTED: 391,
	EvolutionSystem.PARTIAL: 0,
	EvolutionSystem.DATA_ONLY: 149,
	EvolutionSystem.UNSUPPORTED: 14,
}
const EXPECTED_HELD_RUNTIME_IDS := [&"leftovers", &"sitrus_berry"]
const EXPECTED_TRAINER_ITEM_IDS := [
	&"full_restore", &"hyper_potion", &"max_potion", &"potion", &"super_potion",
]


func run(check: Callable) -> void:
	var raw := _load_json("res://data/raw/pokemon_api.json")
	var normalized := _load_json("res://data/normalized/pokemon_api.json")
	var manifest := _load_json("res://data/manifests/pokemon_api_manifest.json")
	var unsupported := _load_json("res://data/reports/unsupported_mechanics.json")
	var audit := _load_json("res://data/reports/pokeapi_v3_audit.json")
	var forms := _load_json("res://data/reports/forms_policy_report.json")

	var raw_types: Array = raw.get("types", [])
	var raw_species: Array = raw.get("species", [])
	var raw_moves: Array = raw.get("moves", [])
	var raw_abilities: Array = raw.get("abilities", [])
	var raw_items: Array = raw.get("items", [])
	var raw_learnset_count := 0
	var raw_evolution_count := 0
	for raw_species_record in raw_species:
		if raw_species_record is Dictionary:
			raw_learnset_count += raw_species_record.get("learnset", []).size()
			raw_evolution_count += raw_species_record.get("evolutions", []).size()

	# This suite runs before authoritative normalization in CI. Therefore structural
	# invariants here use regenerated raw data + pre-normalization adapter reports.
	# Post-import rejected-definition checks are certified from the tested artifact.
	var structural_counts_ok: bool = (
		raw_types.size() == EXPECTED_TYPE_COUNT
		and raw_species.size() == EXPECTED_SPECIES_COUNT
		and raw_moves.size() == EXPECTED_MOVE_COUNT
		and raw_abilities.size() == EXPECTED_ABILITY_COUNT
		and raw_items.size() == EXPECTED_ITEM_COUNT
		and raw_learnset_count == EXPECTED_LEARNSET_COUNT
		and raw_evolution_count == EXPECTED_EVOLUTION_COUNT
		and int(forms.get("forms_total", -1)) == EXPECTED_FORM_COUNT
		and int(forms.get("species_total", -1)) == EXPECTED_SPECIES_COUNT
		and audit.get("broken_references", []).is_empty()
	)
	check.call("data_v3_end_to_end_exact_structural_contract", structural_counts_ok)

	var provenance: Dictionary = manifest.get("provenance", {}) as Dictionary
	var normalized_manifest: Dictionary = normalized.get("manifest", {}) as Dictionary
	var normalized_provenance: Dictionary = normalized_manifest.get("provenance", {}) as Dictionary
	var provenance_ok: bool = (
		int(manifest.get("schema_version", -1)) == EXPECTED_SCHEMA_VERSION
		and str(manifest.get("dataset_version", "")) == EXPECTED_DATASET_VERSION
		and str(manifest.get("source", "")) == EXPECTED_SOURCE
		and str(manifest.get("ruleset", "")) == EXPECTED_RULESET
		and str(provenance.get("source_commit", "")) == EXPECTED_SOURCE_COMMIT
		and str(provenance.get("source_snapshot_commit", "")) == EXPECTED_SOURCE_COMMIT
		and str(provenance.get("source_api_tree", "")) == EXPECTED_API_TREE
		and str(provenance.get("source_schema_tree", "")) == EXPECTED_SCHEMA_TREE
		and int(normalized_manifest.get("schema_version", -1)) == EXPECTED_SCHEMA_VERSION
		and str(normalized_manifest.get("dataset_version", "")) == EXPECTED_DATASET_VERSION
		and str(normalized_manifest.get("source", "")) == EXPECTED_SOURCE
		and str(normalized_manifest.get("ruleset", "")) == EXPECTED_RULESET
		and str(normalized_provenance.get("source_commit", "")) == EXPECTED_SOURCE_COMMIT
		and str(normalized_provenance.get("source_snapshot_commit", "")) == EXPECTED_SOURCE_COMMIT
		and str(normalized_provenance.get("source_api_tree", "")) == EXPECTED_API_TREE
		and str(normalized_provenance.get("source_schema_tree", "")) == EXPECTED_SCHEMA_TREE
	)
	check.call("data_v3_end_to_end_exact_source_provenance", provenance_ok)

	var raw_normalized_identity_ok: bool = (
		_same_id_set(raw_types, normalized.get("types", {}))
		and _same_id_set(raw_species, normalized.get("species", {}))
		and _same_id_set(raw_moves, normalized.get("moves", {}))
		and _same_id_set(raw_abilities, normalized.get("abilities", {}))
		and _same_id_set(raw_items, normalized.get("items", {}))
	)
	check.call("data_v3_end_to_end_raw_normalized_identity_sets_match", raw_normalized_identity_ok)

	var type_ids := _id_set(raw_types)
	var species_ids := _id_set(raw_species)
	var move_ids := _id_set(raw_moves)
	var ability_ids := _id_set(raw_abilities)
	var item_ids := _id_set(raw_items)
	var broken_cross_refs := 0
	var learnset_count := 0
	var evolution_count := 0
	for raw_species_record in raw_species:
		if not (raw_species_record is Dictionary):
			broken_cross_refs += 1
			continue
		var species_record: Dictionary = raw_species_record
		for type_id in species_record.get("types", []):
			if not type_ids.has(str(type_id)):
				broken_cross_refs += 1
		for ability_id in species_record.get("ability_ids", []):
			if not ability_ids.has(str(ability_id)):
				broken_cross_refs += 1
		for raw_learnset in species_record.get("learnset", []):
			learnset_count += 1
			if not (raw_learnset is Dictionary) or not move_ids.has(str(raw_learnset.get("move_id", ""))):
				broken_cross_refs += 1
		for raw_evolution in species_record.get("evolutions", []):
			evolution_count += 1
			if not (raw_evolution is Dictionary):
				broken_cross_refs += 1
				continue
			var evolution: Dictionary = raw_evolution
			if not species_ids.has(str(evolution.get("species_id", ""))):
				broken_cross_refs += 1
			var evolution_item := str(evolution.get("item_id", ""))
			if not evolution_item.is_empty() and not item_ids.has(evolution_item):
				broken_cross_refs += 1
	for raw_move in raw_moves:
		if not (raw_move is Dictionary) or not type_ids.has(str(raw_move.get("type_id", ""))):
			broken_cross_refs += 1
	check.call(
		"data_v3_end_to_end_cross_domain_references_are_closed",
		broken_cross_refs == 0
		and learnset_count == EXPECTED_LEARNSET_COUNT
		and evolution_count == EXPECTED_EVOLUTION_COUNT,
	)

	var move_classes := _classification_counts(raw_moves)
	check.call(
		"data_v3_end_to_end_move_boundary_frozen",
		_counts_match(move_classes, EXPECTED_MOVE_CLASSES),
	)
	var ability_classes := _classification_counts(raw_abilities)
	check.call(
		"data_v3_end_to_end_ability_boundary_frozen",
		_counts_match(ability_classes, EXPECTED_ABILITY_CLASSES),
	)

	var evolution_classes := {
		EvolutionSystem.RUNTIME_SUPPORTED: 0,
		EvolutionSystem.PARTIAL: 0,
		EvolutionSystem.DATA_ONLY: 0,
		EvolutionSystem.UNSUPPORTED: 0,
	}
	var conditioned_data_only_executable := false
	for raw_species_record in raw_species:
		if not (raw_species_record is Dictionary):
			continue
		var species_record: Dictionary = raw_species_record
		var source_id := StringName(str(species_record.get("id", "")))
		for raw_evolution in species_record.get("evolutions", []):
			if not (raw_evolution is Dictionary):
				continue
			var record := EvolutionRecord.from_dict(raw_evolution)
			var cls := EvolutionSystem.classify_record(record, null, source_id)
			evolution_classes[cls] = int(evolution_classes.get(cls, 0)) + 1
			if cls == EvolutionSystem.DATA_ONLY and not record.conditions.is_empty():
				var species := CreatureSpecies.new()
				species.id = source_id
				species.evolutions.append(record)
				var candidates := EvolutionSystem.evolution_candidates(
					species,
					{"level": 100, "item_id": record.item_id, "traded": true},
					null,
				)
				conditioned_data_only_executable = conditioned_data_only_executable or not candidates.is_empty()
	check.call(
		"data_v3_end_to_end_evolution_boundary_frozen",
		_counts_match(evolution_classes, EXPECTED_EVOLUTION_CLASSES)
		and not conditioned_data_only_executable,
	)

	var registry := BattleEffectRegistry.new()
	check.call(
		"data_v3_end_to_end_item_runtime_surfaces_frozen",
		registry.runtime_supported_item_ids() == EXPECTED_HELD_RUNTIME_IDS
		and registry.runtime_supported_trainer_item_ids() == EXPECTED_TRAINER_ITEM_IDS,
	)

	var data_only_move_exec := false
	for raw_move in raw_moves:
		if raw_move is Dictionary and str(raw_move.get("classification", "")) == "DATA_ONLY":
			data_only_move_exec = data_only_move_exec or not raw_move.get("effect_specs", []).is_empty()
	var implemented_abilities := registry.implemented_ability_ids()
	var data_only_ability_exec := false
	for raw_ability in raw_abilities:
		if raw_ability is Dictionary and str(raw_ability.get("classification", "")) == "DATA_ONLY":
			data_only_ability_exec = data_only_ability_exec or implemented_abilities.has(StringName(str(raw_ability.get("id", ""))))
	check.call(
		"data_v3_end_to_end_no_data_only_hidden_execution",
		not data_only_move_exec and not data_only_ability_exec,
	)

	var unsupported_summary: Dictionary = unsupported.get("summary", {}) as Dictionary
	var unsupported_moves: Dictionary = unsupported_summary.get("moves", {}) as Dictionary
	check.call(
		"data_v3_end_to_end_shadow_exclusion_and_reports_frozen",
		int(unsupported_moves.get("EXCLUDED_NON_STANDARD_TYPE", -1)) == EXPECTED_EXCLUDED_SHADOW_MOVES
		and int(audit.get("species_total", -1)) == EXPECTED_SPECIES_COUNT
		and int(audit.get("forms_total", -1)) == EXPECTED_FORM_COUNT
		and int(audit.get("types_total", -1)) == EXPECTED_TYPE_COUNT
		and int(audit.get("moves_total", -1)) == EXPECTED_MOVE_COUNT
		and int(audit.get("abilities_total", -1)) == EXPECTED_ABILITY_COUNT
		and int(forms.get("forms_total", -1)) == EXPECTED_FORM_COUNT
		and int(forms.get("species_total", -1)) == EXPECTED_SPECIES_COUNT,
	)


func _classification_counts(records: Array) -> Dictionary:
	var counts := {}
	for raw_record in records:
		if not (raw_record is Dictionary):
			continue
		var classification := str(raw_record.get("classification", ""))
		counts[classification] = int(counts.get(classification, 0)) + 1
	return counts


func _id_set(records: Array) -> Dictionary:
	var out := {}
	for raw_record in records:
		if raw_record is Dictionary:
			out[str(raw_record.get("id", ""))] = true
	return out


func _same_id_set(raw_records: Array, normalized_records) -> bool:
	if not (normalized_records is Dictionary):
		return false
	var raw_ids := _id_set(raw_records)
	var normalized_dict: Dictionary = normalized_records
	if raw_ids.size() != normalized_dict.size():
		return false
	for record_id in raw_ids.keys():
		if not normalized_dict.has(record_id):
			return false
	return true


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
