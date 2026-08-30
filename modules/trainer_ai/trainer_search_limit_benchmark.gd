class_name TrainerSearchLimitBenchmark
extends RefCounted

const SCHEMA_VERSION := 1
const MODEL_ID := "segmented_search_limit_probe_v1"


static func run(
	catalog: DefinitionCatalog,
	scenarios: Array[Dictionary],
	planner_factory: Callable,
) -> Dictionary:
	var records: Array[Dictionary] = []
	var totals := {
		"planner_wins": 0,
		"planner_losses": 0,
		"planner_draws": 0,
		"planner_invalid": 0,
		"oracle_wins": 0,
		"oracle_losses": 0,
		"oracle_draws": 0,
		"oracle_invalid": 0,
		"planner_matches": 0,
		"oracle_matches": 0,
	}
	for scenario in scenarios:
		var candidate_roster := scenario.get("candidate_roster", []) as Array[CreatureInstance]
		var reference_roster := scenario.get("reference_roster", []) as Array[CreatureInstance]
		var reference_factory := scenario.get("reference_factory", Callable()) as Callable
		var scenario_planner_factory := scenario.get("planner_factory", planner_factory) as Callable
		if not scenario_planner_factory.is_valid():
			scenario_planner_factory = planner_factory
		var oracle_factory := scenario.get("oracle_factory", Callable()) as Callable
		var seeds := _int_array(scenario.get("seeds", []))
		var max_turns := maxi(1, int(scenario.get("max_turns", 40)))
		var planner := _run_policy(
			catalog,
			candidate_roster,
			reference_roster,
			scenario_planner_factory,
			reference_factory,
			seeds,
			max_turns,
			String(scenario.get("id", "scenario")),
			"planner",
		)
		var oracle: Dictionary = {}
		if oracle_factory.is_valid():
			oracle = _run_policy(
				catalog,
				candidate_roster,
				reference_roster,
				oracle_factory,
				reference_factory,
				seeds,
				max_turns,
				String(scenario.get("id", "scenario")),
				"oracle",
			)
		var record := {
			"id": String(scenario.get("id", "scenario")),
			"family": String(scenario.get("family", "unspecified")),
			"expected_limit": String(scenario.get("expected_limit", "unspecified")),
			"seed_count": seeds.size(),
			"planner": _summary(planner),
			"planner_matches": (planner.get("matches", []) as Array).duplicate(true),
			"oracle_available": not oracle.is_empty(),
			"oracle": _summary(oracle) if not oracle.is_empty() else {},
			"oracle_matches": (oracle.get("matches", []) as Array).duplicate(true) if not oracle.is_empty() else [],
		}
		records.append(record)
		_accumulate(totals, planner, "planner")
		if not oracle.is_empty():
			_accumulate(totals, oracle, "oracle")
	var out := {
		"schema_version": SCHEMA_VERSION,
		"evaluation_model": MODEL_ID,
		"scenario_count": records.size(),
		"scenarios": records,
		"totals": totals,
	}
	out["signature"] = _signature(out)
	return out


static func _run_policy(
	catalog: DefinitionCatalog,
	candidate_roster: Array[CreatureInstance],
	reference_roster: Array[CreatureInstance],
	candidate_factory: Callable,
	reference_factory: Callable,
	seeds: Array[int],
	max_turns: int,
	scenario_id: String,
	policy_id: String,
) -> Dictionary:
	var summary := {
		"wins": 0,
		"losses": 0,
		"draws": 0,
		"invalid": 0,
		"total_turns": 0,
		"matches": [],
	}
	if not candidate_factory.is_valid() or not reference_factory.is_valid():
		summary.invalid = seeds.size() * 2
		return summary
	for seed in seeds:
		var normal := TrainerSelfPlayMatch.new(max_turns).run(
			catalog,
			candidate_roster,
			candidate_factory.call(catalog) as TrainerBrain,
			reference_roster,
			reference_factory.call(catalog) as TrainerBrain,
			seed,
			StringName("limit_%s_%s_%d_a" % [scenario_id, policy_id, seed]),
		)
		_record(summary, normal, &"side_a", false)
		var mirrored := TrainerSelfPlayMatch.new(max_turns).run(
			catalog,
			reference_roster,
			reference_factory.call(catalog) as TrainerBrain,
			candidate_roster,
			candidate_factory.call(catalog) as TrainerBrain,
			seed,
			StringName("limit_%s_%s_%d_b" % [scenario_id, policy_id, seed]),
		)
		_record(summary, mirrored, &"side_b", true)
	return summary


static func _record(
	summary: Dictionary,
	result: Dictionary,
	candidate_side_id: StringName,
	mirrored: bool,
) -> void:
	summary.total_turns = int(summary.total_turns) + int(result.get("turn_count", 0))
	var outcome := "invalid"
	if not bool(result.get("ok", false)):
		summary.invalid = int(summary.invalid) + 1
	elif bool(result.get("draw", false)):
		summary.draws = int(summary.draws) + 1
		outcome = "draw"
	elif StringName(result.get("winner_side_id", "")) == candidate_side_id:
		summary.wins = int(summary.wins) + 1
		outcome = "win"
	else:
		summary.losses = int(summary.losses) + 1
		outcome = "loss"
	(summary.matches as Array).append({
		"seed": int(result.get("seed", 0)),
		"mirrored": mirrored,
		"candidate_side_id": String(candidate_side_id),
		"outcome": outcome,
		"result": result.duplicate(true),
	})


static func _summary(data: Dictionary) -> Dictionary:
	if data.is_empty():
		return {}
	return {
		"wins": int(data.get("wins", 0)),
		"losses": int(data.get("losses", 0)),
		"draws": int(data.get("draws", 0)),
		"invalid": int(data.get("invalid", 0)),
		"total_turns": int(data.get("total_turns", 0)),
		"match_count": (data.get("matches", []) as Array).size(),
	}


static func _accumulate(totals: Dictionary, data: Dictionary, prefix: String) -> void:
	for key in ["wins", "losses", "draws", "invalid"]:
		totals["%s_%s" % [prefix, key]] = int(totals.get("%s_%s" % [prefix, key], 0)) + int(data.get(key, 0))
	totals["%s_matches" % prefix] = int(totals.get("%s_matches" % prefix, 0)) + (data.get("matches", []) as Array).size()


static func _int_array(values: Array) -> Array[int]:
	var out: Array[int] = []
	for value in values:
		out.append(int(value))
	return out


static func _signature(result: Dictionary) -> String:
	var totals := result.get("totals", {}) as Dictionary
	var parts: Array[String] = []
	for value in result.get("scenarios", []):
		var record := value as Dictionary
		var planner := record.get("planner", {}) as Dictionary
		var oracle := record.get("oracle", {}) as Dictionary
		parts.append("%s:p%d-%d:o%d-%d" % [
			String(record.get("id", "")),
			int(planner.get("wins", 0)),
			int(planner.get("losses", 0)),
			int(oracle.get("wins", 0)),
			int(oracle.get("losses", 0)),
		])
	return "pm:%d|pw:%d|pl:%d|om:%d|ow:%d|ol:%d|%s" % [
		int(totals.get("planner_matches", 0)),
		int(totals.get("planner_wins", 0)),
		int(totals.get("planner_losses", 0)),
		int(totals.get("oracle_matches", 0)),
		int(totals.get("oracle_wins", 0)),
		int(totals.get("oracle_losses", 0)),
		"|".join(parts),
	]
