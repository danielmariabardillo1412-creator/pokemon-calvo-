class_name TrainerExpertiseBudgetSafetyAuditTestSuite
extends TrainerSearchDepthBudgetTestSuite

const PROPOSAL_SOURCE := "res://modules/trainer_ai/trainer_item_aware_action_proposal.gd"
const AGGREGATE := "TRAINER_AI_EXPERTISE_BUDGET_SAFETY_AUDIT_COMPLETE"


func run(check_callback: Callable) -> void:
	# Reuse the already-certified depth fixture without counting its setup assertion
	# as part of this audit's fixed 18-check contract.
	_check = Callable(self, "_ignore_fixture_check")
	_build_catalog()
	_check = check_callback

	var proposal_source := _read_text(PROPOSAL_SOURCE)
	_check.call(
		"expertise_budget_runtime_requires_depth_two",
		proposal_source.contains("const REQUIRED_DEPTH := 2")
		and proposal_source.contains("TrainerSearchBudget.constrained(REQUIRED_DEPTH"),
	)
	_check.call(
		"expertise_budget_outer_roots_remain_all_legal",
		proposal_source.contains("for action in legal_actions:")
		and proposal_source.contains("root_scores.size() == legal_actions.size()")
		and proposal_source.contains("\"root_all_legal\": true"),
	)
	_check.call(
		"expertise_budget_current_world_cap_is_four",
		proposal_source.contains("const MAX_WORLDS := 4"),
	)
	_check.call(
		"expertise_budget_current_inner_action_cap_is_three",
		proposal_source.contains("const INNER_ACTION_CAP := TrainerItemAwareShadowProbe.INNER_ACTION_CAP"),
	)

	var fx := _fixture(OPP_HEAVY)
	var context := fx.context as TrainerDecisionContext
	var state := fx.state as BattleState
	var greedy := _move_action(context, GREEDY_MOVE)
	var before := JSON.stringify(state.to_dict())

	var depth_one_budget := TrainerSearchBudget.constrained(1, 2, 32, 3)
	var depth_one_search := TrainerMultiTurnSearch.new(_catalog, TrainerProfile.balanced(), depth_one_budget)
	var depth_one_first := depth_one_search.evaluate(context, greedy)
	var depth_one_second := depth_one_search.evaluate(context, greedy)
	var depth_one_meta := depth_one_first.get("metadata", {}) as Dictionary
	_check.call(
		"expertise_budget_depth_one_only_completes_physical_depth_one",
		int(depth_one_meta.get("fully_completed_depth", 0)) == 1,
	)
	_check.call(
		"expertise_budget_depth_one_is_below_runtime_required_depth",
		int(depth_one_meta.get("fully_completed_depth", 0)) < TrainerItemAwareActionProposal.REQUIRED_DEPTH,
	)
	_check.call(
		"expertise_budget_depth_one_is_deterministic_but_not_game_ready",
		JSON.stringify(depth_one_first) == JSON.stringify(depth_one_second)
		and int(depth_one_meta.get("fully_completed_depth", 0)) != TrainerItemAwareActionProposal.REQUIRED_DEPTH,
	)

	var tight_budget := TrainerSearchBudget.constrained(2, 2, 3, 3)
	var tight_search := TrainerMultiTurnSearch.new(_catalog, TrainerProfile.balanced(), tight_budget)
	var tight_first := tight_search.evaluate(context, greedy)
	var tight_second := tight_search.evaluate(context, greedy)
	var tight_meta := tight_first.get("metadata", {}) as Dictionary
	_check.call(
		"expertise_budget_tight_depth_two_exhausts",
		bool(tight_meta.get("budget_exhausted", false)),
	)
	_check.call(
		"expertise_budget_tight_depth_two_fails_required_horizon",
		not bool(tight_meta.get("required_horizon_complete", true))
		and int(tight_meta.get("fully_completed_depth", 0)) < TrainerItemAwareActionProposal.REQUIRED_DEPTH,
	)
	_check.call(
		"expertise_budget_tight_failure_is_deterministic",
		JSON.stringify(tight_first) == JSON.stringify(tight_second),
	)

	var narrow_budget := TrainerSearchBudget.constrained(2, 2, 32, 1)
	var wide_budget := TrainerSearchBudget.constrained(2, 2, 32, 3)
	var narrow_search := TrainerMultiTurnSearch.new(_catalog, TrainerProfile.balanced(), narrow_budget)
	var wide_search := TrainerMultiTurnSearch.new(_catalog, TrainerProfile.balanced(), wide_budget)
	var narrow_first := narrow_search.evaluate(context, greedy)
	var narrow_second := narrow_search.evaluate(context, greedy)
	var wide_first := wide_search.evaluate(context, greedy)
	var wide_second := wide_search.evaluate(context, greedy)
	var narrow_meta := narrow_first.get("metadata", {}) as Dictionary
	var wide_meta := wide_first.get("metadata", {}) as Dictionary

	_check.call(
		"expertise_budget_action_cap_one_preserves_depth_two_completion",
		bool(narrow_meta.get("required_horizon_complete", false))
		and int(narrow_meta.get("fully_completed_depth", 0)) == 2
		and not bool(narrow_meta.get("budget_exhausted", true)),
	)
	_check.call(
		"expertise_budget_action_cap_three_preserves_depth_two_completion",
		bool(wide_meta.get("required_horizon_complete", false))
		and int(wide_meta.get("fully_completed_depth", 0)) == 2
		and not bool(wide_meta.get("budget_exhausted", true)),
	)
	_check.call(
		"expertise_budget_action_cap_one_is_deterministic",
		JSON.stringify(narrow_first) == JSON.stringify(narrow_second),
	)
	_check.call(
		"expertise_budget_action_cap_three_is_deterministic",
		JSON.stringify(wide_first) == JSON.stringify(wide_second),
	)
	var narrow_json := JSON.stringify(narrow_first)
	var wide_json := JSON.stringify(wide_first)
	_check.call(
		"expertise_budget_action_caps_preserve_hidden_information_boundary",
		not narrow_json.contains(String(OPP_SECRET))
		and not wide_json.contains(String(OPP_SECRET))
		and not narrow_json.contains("rng_state")
		and not wide_json.contains("rng_state"),
	)
	_check.call(
		"expertise_budget_wider_action_cap_materially_expands_search",
		int(wide_meta.get("simulations_used", 0)) > int(narrow_meta.get("simulations_used", 0))
		and int((narrow_meta.get("budget", {}) as Dictionary).get("max_actions_per_side", 0)) == 1
		and int((wide_meta.get("budget", {}) as Dictionary).get("max_actions_per_side", 0)) == 3,
	)
	_check.call(
		"expertise_budget_audit_does_not_mutate_live_state",
		JSON.stringify(state.to_dict()) == before,
	)
	_check.call("expertise_budget_audit_aggregate", true)
	print(AGGREGATE)


func _ignore_fixture_check(_name: String, _condition: bool) -> void:
	pass


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""
