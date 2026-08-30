class_name TrainerMultiTurnSearch
extends RefCounted

const SEARCH_MODEL_ID := "simultaneous_depth_budget_v1"
const ACTION_SAMPLING_MODEL := "kind_stratified_round_robin_v1"

var _catalog: DefinitionCatalog
var _profile: TrainerProfile
var _budget: TrainerSearchBudget
var _world_factory: TrainerPlausibleWorldFactory


func _init(
	catalog: DefinitionCatalog,
	profile: TrainerProfile = null,
	budget: TrainerSearchBudget = null,
) -> void:
	_catalog = catalog
	_profile = profile if profile != null else TrainerProfile.balanced()
	_budget = budget.duplicate_budget() if budget != null else TrainerSearchBudget.depth_two_default()
	_world_factory = TrainerPlausibleWorldFactory.new(catalog)


func evaluate(context: TrainerDecisionContext, root_action: BattleAction) -> Dictionary:
	var active_budget := _budget.normalized()
	var empty := _empty_result(active_budget)
	if context == null or context.observation == null or root_action == null or _catalog == null:
		return empty
	var worlds := _world_factory.build(context, active_budget.max_worlds)
	if worlds.is_empty():
		return empty

	var entries: Array[Dictionary] = []
	for world in worlds:
		var root_fork := BattleSimulationFork.from_state(world.state, _catalog)
		if root_fork == null or root_fork.server == null:
			continue
		var opponent_actions := _bounded_actions(
			TrainerActionSpace.from_server(root_fork.server, context.observation.opponent_side_id),
			active_budget.max_actions_per_side,
		)
		if opponent_actions.is_empty():
			continue
		entries.append({
			"world": world,
			"opponent_actions": opponent_actions,
			"branches": [],
			"rejections": 0,
		})
	if entries.is_empty():
		return empty

	var simulations_used := 0
	var budget_exhausted := false
	var root_branch_count := 0
	var max_root_responses := 0
	for entry in entries:
		max_root_responses = maxi(max_root_responses, (entry.opponent_actions as Array).size())

	# Root responses are expanded response-index first across worlds. If a tight budget
	# is used, every world gets its first response before any world gets a second one.
	for response_index in max_root_responses:
		for entry in entries:
			var opponent_actions := entry.opponent_actions as Array
			if response_index >= opponent_actions.size():
				continue
			if simulations_used >= active_budget.max_simulations:
				budget_exhausted = true
				break
			var world := entry.world as TrainerPlausibleWorld
			var fork := BattleSimulationFork.from_state(world.state, _catalog)
			if fork == null:
				continue
			var before := BattleState.from_dict(fork.state().to_dict().duplicate(true))
			var own := _normalize_action(
				root_action,
				fork.state(),
				context.observation.observer_side_id,
			)
			var opponent := _normalize_action(
				opponent_actions[response_index] as BattleAction,
				fork.state(),
				context.observation.opponent_side_id,
			)
			if own == null or opponent == null:
				entry.rejections = int(entry.rejections) + 1
				continue
			var actions: Array[BattleAction] = [own, opponent]
			var events := fork.submit_turn(actions)
			simulations_used += 1
			if _has_rejection(events):
				entry.rejections = int(entry.rejections) + 1
				continue
			var root_eval := TrainerSearchStateEvaluator.evaluate(
				before,
				fork.state(),
				context.observation.observer_side_id,
			)
			(entry.branches as Array).append({
				"fork": fork,
				"root_before": before,
				"root_score": int(root_eval.get("score", 0)),
				"score": int(root_eval.get("score", 0)),
				"depth_used": 1,
				"opponent_action_key": _action_key(opponent),
				"best_followup_action_key": "",
				"expected_pairs": 0,
				"processed_pairs": 0,
				"valid_pairs": 0,
				"pair_plan": [],
				"continuation_scores": {},
			})
			root_branch_count += 1
		if budget_exhausted:
			break

	var root_complete_worlds := 0
	for entry in entries:
		var expected := (entry.opponent_actions as Array).size()
		var actual := (entry.branches as Array).size()
		entry["root_matrix_complete"] = actual == expected and int(entry.rejections) == 0
		if bool(entry.root_matrix_complete):
			root_complete_worlds += 1

	var expandable_branches: Array[Dictionary] = []
	if active_budget.depth_turns >= 2:
		for entry in entries:
			if not bool(entry.root_matrix_complete):
				continue
			for branch in entry.branches as Array:
				var fork := branch.fork as BattleSimulationFork
				if fork == null or fork.state() == null:
					continue
				if fork.state().phase != BattleState.WAITING_FOR_ACTIONS:
					continue
				var own_actions := _bounded_actions(
					TrainerActionSpace.from_server(fork.server, context.observation.observer_side_id),
					active_budget.max_actions_per_side,
				)
				var opponent_actions := _bounded_actions(
					TrainerActionSpace.from_server(fork.server, context.observation.opponent_side_id),
					active_budget.max_actions_per_side,
				)
				if own_actions.is_empty() or opponent_actions.is_empty():
					continue
				var plan := _joint_plan(own_actions, opponent_actions)
				branch["pair_plan"] = plan
				branch["expected_pairs"] = plan.size()
				expandable_branches.append(branch)

	# Continuations are round-robined across root branches. Partial matrices never
	# influence a decision: a branch adopts depth-2 value only after every joint
	# response in its bounded matrix has been evaluated successfully.
	var max_pair_plan := 0
	for branch in expandable_branches:
		max_pair_plan = maxi(max_pair_plan, (branch.pair_plan as Array).size())
	for pair_index in max_pair_plan:
		for branch in expandable_branches:
			var plan := branch.pair_plan as Array
			if pair_index >= plan.size():
				continue
			if simulations_used >= active_budget.max_simulations:
				budget_exhausted = true
				break
			var parent_fork := branch.fork as BattleSimulationFork
			var child := parent_fork.fork() if parent_fork != null else null
			if child == null:
				continue
			var pair := plan[pair_index] as Dictionary
			var own := BattleAction.from_dict((pair.own_action as BattleAction).to_dict())
			var opponent := BattleAction.from_dict((pair.opponent_action as BattleAction).to_dict())
			var actions: Array[BattleAction] = [own, opponent]
			var events := child.submit_turn(actions)
			simulations_used += 1
			branch.processed_pairs = int(branch.processed_pairs) + 1
			if _has_rejection(events):
				continue
			branch.valid_pairs = int(branch.valid_pairs) + 1
			var leaf := TrainerSearchStateEvaluator.evaluate(
				branch.root_before as BattleState,
				child.state(),
				context.observation.observer_side_id,
			)
			var own_key := String(pair.own_action_key)
			var score_map := branch.continuation_scores as Dictionary
			var values: Array = score_map.get(own_key, [])
			values.append(int(leaf.get("score", 0)))
			score_map[own_key] = values
			branch.continuation_scores = score_map
		if budget_exhausted:
			break

	var completed_depth_two_branches := 0
	for branch in expandable_branches:
		if (
			int(branch.expected_pairs) <= 0
			or int(branch.processed_pairs) != int(branch.expected_pairs)
			or int(branch.valid_pairs) != int(branch.expected_pairs)
		):
			continue
		var best := _best_continuation(branch.continuation_scores as Dictionary)
		if not bool(best.get("complete", false)):
			continue
		branch.score = int(best.get("score", branch.root_score))
		branch.depth_used = 2
		branch.best_followup_action_key = String(best.get("action_key", ""))
		completed_depth_two_branches += 1

	var risk_weight := _risk_weight_basis_points()
	var weighted_total := 0
	var used_weight := 0
	var world_records: Array[Dictionary] = []
	var complete_world_count := 0
	for entry in entries:
		if not bool(entry.root_matrix_complete):
			continue
		var branches := entry.branches as Array
		if branches.is_empty():
			continue
		var scores: Array[int] = []
		var branch_records: Array[Dictionary] = []
		for branch in branches:
			scores.append(int(branch.score))
			branch_records.append({
				"opponent_action_key": String(branch.opponent_action_key),
				"score": int(branch.score),
				"depth_used": int(branch.depth_used),
				"best_followup_action_key": String(branch.best_followup_action_key),
			})
		var mean := _mean(scores)
		var worst := _minimum(scores)
		var robust := mean * (10000 - risk_weight) / 10000 + worst * risk_weight / 10000
		var world := entry.world as TrainerPlausibleWorld
		weighted_total += robust * world.weight_basis_points
		used_weight += world.weight_basis_points
		complete_world_count += 1
		world_records.append({
			"world_id": String(world.world_id),
			"weight_basis_points": world.weight_basis_points,
			"mean_score": mean,
			"worst_score": worst,
			"robust_score": robust,
			"branches": branch_records,
		})

	if used_weight <= 0:
		var no_coverage := _empty_result(active_budget)
		no_coverage.metadata["simulations_used"] = simulations_used
		no_coverage.metadata["budget_exhausted"] = budget_exhausted
		no_coverage.metadata["root_branch_count"] = root_branch_count
		return no_coverage

	var score := weighted_total / used_weight
	var world_coverage_bp := complete_world_count * 10000 / maxi(1, worlds.size())
	var depth_two_coverage_bp := 0
	if not expandable_branches.is_empty():
		depth_two_coverage_bp = completed_depth_two_branches * 10000 / expandable_branches.size()
	var confidence := world_coverage_bp
	if active_budget.depth_turns >= 2 and not expandable_branches.is_empty():
		confidence = confidence * (7000 + depth_two_coverage_bp * 3000 / 10000) / 10000
	var fully_completed_depth := 1
	if (
		active_budget.depth_turns >= 2
		and not expandable_branches.is_empty()
		and completed_depth_two_branches == expandable_branches.size()
	):
		fully_completed_depth = 2
	var max_depth_reached := 2 if completed_depth_two_branches > 0 else 1
	return {
		"score": score,
		"confidence_basis_points": clampi(confidence, 0, 10000),
		"reasons": [
			"bounded_simultaneous_search",
			"depth_%d_requested" % active_budget.depth_turns,
			"simulation_budget_enforced",
		],
		"metadata": {
			"search_model": SEARCH_MODEL_ID,
			"budget": active_budget.to_dict(),
			"simulations_used": simulations_used,
			"budget_exhausted": budget_exhausted,
			"world_count": worlds.size(),
			"complete_world_count": complete_world_count,
			"world_coverage_basis_points": world_coverage_bp,
			"root_branch_count": root_branch_count,
			"expandable_branch_count": expandable_branches.size(),
			"completed_depth_two_branch_count": completed_depth_two_branches,
			"depth_two_coverage_basis_points": depth_two_coverage_bp,
			"max_depth_reached": max_depth_reached,
			"fully_completed_depth": fully_completed_depth,
			"risk_weight_basis_points": risk_weight,
			"action_sampling_model": ACTION_SAMPLING_MODEL,
			"worlds": world_records,
		},
	}


func _joint_plan(
	own_actions: Array[BattleAction],
	opponent_actions: Array[BattleAction],
) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	# Opponent-response layers come first so every own continuation is tested against
	# response 0 before any receives response 1 under a constrained budget.
	for opponent in opponent_actions:
		for own in own_actions:
			out.append({
				"own_action": BattleAction.from_dict(own.to_dict()),
				"opponent_action": BattleAction.from_dict(opponent.to_dict()),
				"own_action_key": _action_key(own),
				"opponent_action_key": _action_key(opponent),
			})
	return out


func _best_continuation(score_map: Dictionary) -> Dictionary:
	if score_map.is_empty():
		return {"complete": false}
	var keys := score_map.keys()
	keys.sort()
	var best_key := ""
	var best_score := -2147483648
	for raw_key in keys:
		var key := String(raw_key)
		var values_raw := score_map.get(key, []) as Array
		if values_raw.is_empty():
			continue
		var values: Array[int] = []
		for value in values_raw:
			values.append(int(value))
		var mean := _mean(values)
		var worst := _minimum(values)
		var risk_weight := _risk_weight_basis_points()
		var robust := mean * (10000 - risk_weight) / 10000 + worst * risk_weight / 10000
		if robust > best_score or (robust == best_score and (best_key.is_empty() or key < best_key)):
			best_score = robust
			best_key = key
	if best_key.is_empty():
		return {"complete": false}
	return {"complete": true, "action_key": best_key, "score": best_score}


func _bounded_actions(actions: Array[BattleAction], limit: int) -> Array[BattleAction]:
	var moves: Array[BattleAction] = []
	var switches: Array[BattleAction] = []
	for action in actions:
		var clone := BattleAction.from_dict(action.to_dict())
		if action.action_type == BattleAction.SWITCH:
			switches.append(clone)
		else:
			moves.append(clone)
	var out: Array[BattleAction] = []
	var index := 0
	while out.size() < limit:
		var added := false
		if index < moves.size() and out.size() < limit:
			out.append(moves[index])
			added = true
		if index < switches.size() and out.size() < limit:
			out.append(switches[index])
			added = true
		if not added:
			break
		index += 1
	return out


func _normalize_action(
	action: BattleAction,
	state: BattleState,
	side_id: StringName,
) -> BattleAction:
	if action == null or state == null:
		return null
	var actor := state.active_for_side(side_id)
	if actor == null or actor.is_knocked_out():
		return null
	if action.action_type == BattleAction.SWITCH:
		return BattleAction.new(
			state.turn + 1,
			actor.instance_id,
			&"",
			&"",
			BattleAction.SWITCH,
			side_id,
			action.switch_instance_id,
		)
	var target := state.opponent_of(actor.instance_id)
	if target == null:
		return null
	return BattleAction.new(
		state.turn + 1,
		actor.instance_id,
		action.move_id,
		target.instance_id,
		BattleAction.MOVE,
		side_id,
	)


func _has_rejection(events: Array[BattleEvent]) -> bool:
	for event in events:
		if event.kind == BattleEvent.ACTION_REJECTED:
			return true
	return false


func _risk_weight_basis_points() -> int:
	match String(_profile.profile_id):
		"aggressive":
			return 2500
		"cautious":
			return 6500
		"technical":
			return 5000
		_:
			return 4000


func _mean(values: Array[int]) -> int:
	if values.is_empty():
		return 0
	var total := 0
	for value in values:
		total += value
	return total / values.size()


func _minimum(values: Array[int]) -> int:
	if values.is_empty():
		return 0
	var value := values[0]
	for candidate in values:
		value = mini(value, candidate)
	return value


func _action_key(action: BattleAction) -> String:
	if action == null:
		return "null"
	if action.action_type == BattleAction.SWITCH:
		return "switch:%s" % String(action.switch_instance_id)
	return "move:%s" % String(action.move_id)


func _empty_result(budget: TrainerSearchBudget) -> Dictionary:
	return {
		"score": 0,
		"confidence_basis_points": 0,
		"reasons": ["no_search_scenarios"],
		"metadata": {
			"search_model": SEARCH_MODEL_ID,
			"budget": budget.to_dict(),
			"simulations_used": 0,
			"budget_exhausted": false,
			"world_count": 0,
			"complete_world_count": 0,
			"max_depth_reached": 0,
			"fully_completed_depth": 0,
			"action_sampling_model": ACTION_SAMPLING_MODEL,
			"worlds": [],
		},
	}
