class_name TrainerGameReadyHardeningTestSuite
extends TrainerBattleSessionAutonomousSideBSubmissionApiAuditTestSuite

const GAME_READY_AUDIT_ID := "trainer_ai_game_ready_hardening_v1"
const VALIDATED := "TRAINER_AI_GAME_READY_HARDENING_VALIDATED"
const GAME_READY_POTION := &"potion"
const GAME_READY_SUPER_POTION := &"super_potion"
const MAX_BATTLE_TURNS := 30
const MAX_DECISION_MS_CI := 5000

var _gr_check: Callable


func run(check_callback: Callable) -> void:
	_gr_check = check_callback
	var catalog := _c3fae_catalog()
	_gr_check.call("game_ready_catalog_available", catalog != null)
	if catalog == null:
		return

	var tie_bundle := _build_valid_tie_bundle(catalog)
	_gr_check.call("game_ready_valid_tie_fixture_available", not tie_bundle.is_empty())
	if tie_bundle.is_empty():
		return

	var resolver_report := _test_resolver_contract(tie_bundle)
	var runtime_report := _test_runtime_tie_resolution(catalog, tie_bundle)
	var blocked_report := _test_incomplete_and_stale_ties(catalog, tie_bundle)
	var unique_report := _test_unique_path_unchanged(catalog)
	var adversarial_report := _run_adversarial_matrix(catalog)
	var benchmark_report := _run_decision_benchmark(catalog)

	var status := VALIDATED if (
		bool(resolver_report.get("ok", false))
		and bool(runtime_report.get("ok", false))
		and bool(blocked_report.get("ok", false))
		and bool(unique_report.get("ok", false))
		and bool(adversarial_report.get("ok", false))
		and bool(benchmark_report.get("ok", false))
	) else "BLOCKED"
	var report := {
		"audit_id": GAME_READY_AUDIT_ID,
		"tranche_status": status,
		"resolver": resolver_report,
		"runtime_tie": runtime_report,
		"blocked_ties": blocked_report,
		"unique_path": unique_report,
		"adversarial": adversarial_report,
		"benchmark": benchmark_report,
		"player_current_action_used_by_tiebreak": false,
		"trainer_brain_integration_authorized": false,
		"selected_scheduler_id": null,
		"selected_shared_budget": null,
		"shared_660_reopened": false,
		"fase34_open": false,
	}
	_gr_check.call("game_ready_aggregate_validated", status == VALIDATED)
	_gr_check.call("game_ready_report_json", JSON.parse_string(JSON.stringify(report)) is Dictionary)
	print("\n=== TRAINER AI GAME-READY HARDENING ===")
	print(JSON.stringify(report))


func _build_valid_tie_bundle(catalog: DefinitionCatalog) -> Dictionary:
	var source := _c3faf_started_session(catalog, &"c3fam_auto", 913601)
	if source == null or source.battle_state() == null:
		return {}
	var proposal := source.trainer_action_proposal_report_for_side(&"side_b")
	var legal := TrainerActionSpace.from_server(source._battle_server, &"side_b")
	if String(proposal.get("proposal_status", "")) != TrainerItemAwareActionProposal.PROPOSAL_READY or legal.size() < 2:
		return {}
	var first_id := _game_ready_root_id(legal[0])
	var second_id := _game_ready_root_id(legal[1])
	if first_id.is_empty() or second_id.is_empty() or first_id == second_id:
		return {}
	var scores := (proposal.get("root_scores", {}) as Dictionary).duplicate(true)
	for key in scores.keys():
		scores[key] = -1000000
	scores[first_id] = 500000
	scores[second_id] = 500000
	proposal["root_scores"] = scores
	proposal["best_root_ids"] = [first_id, second_id]
	var kinds: Array[String] = [_game_ready_kind(legal[0]), _game_ready_kind(legal[1])]
	kinds.sort()
	proposal["best_kinds"] = kinds
	proposal["proposal_status"] = TrainerItemAwareActionProposal.TIE_UNRESOLVED
	proposal["resolution_outcome"] = TrainerItemAwareActionProposal.TIE_UNRESOLVED
	proposal["selected_root_id"] = ""
	proposal["selected_kind"] = ""
	proposal["proposal_action"] = null
	proposal["proposal_action_detached"] = false
	return {
		"proposal": proposal,
		"legal_actions": legal,
		"best_root_ids": [first_id, second_id],
	}


func _test_resolver_contract(bundle: Dictionary) -> Dictionary:
	var report := (bundle.get("proposal", {}) as Dictionary).duplicate(true)
	var legal: Array[BattleAction] = []
	for value in bundle.get("legal_actions", []) as Array:
		var action := value as BattleAction
		if action != null:
			legal.append(BattleAction.from_dict(action.to_dict()))
	var reversed: Array[BattleAction] = []
	for index in range(legal.size() - 1, -1, -1):
		reversed.append(BattleAction.from_dict(legal[index].to_dict()))
	var battle_id := StringName(String(report.get("battle_id", "")))
	var turn := int(report.get("turn", -1))
	var resolver := TrainerGameReadyTieResolver.new()
	var first := resolver.resolve(report, legal, battle_id, turn, &"side_b")
	var second := resolver.resolve(report, legal, battle_id, turn, &"side_b")
	var reversed_result := resolver.resolve(report, reversed, battle_id, turn, &"side_b")
	var selected := String(first.get("selected_root_id", ""))
	var best := bundle.get("best_root_ids", []) as Array
	var reproducible := selected == String(second.get("selected_root_id", ""))
	var order_invariant := selected == String(reversed_result.get("selected_root_id", ""))
	var selected_is_best := best.has(selected)
	var no_hidden_priority := (
		not bool(first.get("lexical_priority_used", true))
		and not bool(first.get("input_order_priority_used", true))
		and not bool(first.get("kind_priority_used", true))
		and not bool(first.get("live_rng_used", true))
		and not bool(first.get("player_current_action_used", true))
	)

	var seen := {}
	var diversity_ok := true
	for i in range(32):
		var variant := report.duplicate(true)
		var variant_id := StringName("trainer_battle_game_ready_diversity_%d" % i)
		variant["battle_id"] = String(variant_id)
		var result := resolver.resolve(variant, legal, variant_id, turn, &"side_b")
		if String(result.get("tie_resolution_status", "")) != TrainerGameReadyTieResolver.TIE_RESOLVED:
			diversity_ok = false
			break
		seen[String(result.get("selected_root_id", ""))] = true
	diversity_ok = diversity_ok and seen.size() >= 2

	_gr_check.call("game_ready_tie_resolver_resolves", String(first.get("tie_resolution_status", "")) == TrainerGameReadyTieResolver.TIE_RESOLVED)
	_gr_check.call("game_ready_tie_selected_from_exact_best", selected_is_best)
	_gr_check.call("game_ready_tie_reproducible", reproducible)
	_gr_check.call("game_ready_tie_order_invariant", order_invariant)
	_gr_check.call("game_ready_tie_no_hidden_priority", no_hidden_priority)
	_gr_check.call("game_ready_tie_seed_scope_excludes_player_action", String(first.get("seed_scope", "")) == TrainerGameReadyTieResolver.SEED_SCOPE)
	_gr_check.call("game_ready_tie_diversity_not_fixed_first", diversity_ok)
	return {
		"ok": String(first.get("tie_resolution_status", "")) == TrainerGameReadyTieResolver.TIE_RESOLVED and selected_is_best and reproducible and order_invariant and no_hidden_priority and diversity_ok,
		"selected_root_id": selected,
		"selection_seed": int(first.get("selection_seed", -1)),
		"diversity_selected_root_count": seen.size(),
	}


func _test_runtime_tie_resolution(catalog: DefinitionCatalog, bundle: Dictionary) -> Dictionary:
	var tie_report := (bundle.get("proposal", {}) as Dictionary).duplicate(true)
	var session := _c3fam_started_override_session(catalog, tie_report)
	if session == null or session.battle_state() == null:
		_gr_check.call("game_ready_runtime_tie_fixture", false)
		return {"ok": false}
	# The source tie fixture comes from _c3faf_started_session(), whose certified
	# action space includes Potion + Hyper Potion on both sides. The override helper
	# intentionally starts a bare battle, so restore that same certified inventory
	# before validating full live-root coverage. Do not weaken the resolver guard.
	_c3faf_install_items(session)
	var runtime_legal := TrainerActionSpace.from_server(session._battle_server, &"side_b")
	var expected_live_count := int(tie_report.get("legal_action_count", -1))
	var live_root_coverage_matches := runtime_legal.size() == expected_live_count
	_gr_check.call("game_ready_runtime_fixture_live_root_coverage", live_root_coverage_matches)
	if not live_root_coverage_matches:
		return {"ok": false, "live_root_count": runtime_legal.size(), "expected_live_root_count": expected_live_count}
	var pair := _c3fae_actions(session.battle_state())
	if pair.is_empty():
		_gr_check.call("game_ready_runtime_tie_player_action", false)
		return {"ok": false}
	var before := session.battle_state().turn
	var events := session.submit_player_action_with_autonomous_trainer(pair[0])
	var source_proposal := session.last_trainer_action_proposal_report.duplicate(true)
	var tie := session.last_trainer_game_ready_tie_report.duplicate(true)
	var substitution := session.last_trainer_action_substitution_report.duplicate(true)
	var selected := String(tie.get("selected_root_id", ""))
	var best := bundle.get("best_root_ids", []) as Array
	var ok := (
		not events.is_empty()
		and session.last_error.is_empty()
		and session.battle_state() != null
		and session.battle_state().turn == before + 1
		and String(source_proposal.get("proposal_status", "")) == TrainerItemAwareActionProposal.TIE_UNRESOLVED
		and String(tie.get("tie_resolution_status", "")) == TrainerGameReadyTieResolver.TIE_RESOLVED
		and best.has(selected)
		and String(substitution.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_READY
		and String(substitution.get("submitted_root_id", "")) == selected
		and bool(substitution.get("game_ready_tiebreak_used", false))
		and substitution.get("caller_action", "sentinel") == null
		and not bool(substitution.get("caller_fallback_used", true))
	)
	_gr_check.call("game_ready_runtime_tie_advances_turn", not events.is_empty() and session.battle_state() != null and session.battle_state().turn == before + 1)
	_gr_check.call("game_ready_runtime_preserves_tie_telemetry", String(source_proposal.get("proposal_status", "")) == TrainerItemAwareActionProposal.TIE_UNRESOLVED)
	_gr_check.call("game_ready_runtime_tie_substitution_ready", String(substitution.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_READY)
	_gr_check.call("game_ready_runtime_tie_no_caller_fallback", substitution.get("caller_action", "sentinel") == null and not bool(substitution.get("caller_fallback_used", true)))
	return {"ok": ok, "selected_root_id": selected, "turn_after": session.battle_state().turn if session.battle_state() != null else -1}


func _test_incomplete_and_stale_ties(catalog: DefinitionCatalog, bundle: Dictionary) -> Dictionary:
	var base := (bundle.get("proposal", {}) as Dictionary).duplicate(true)
	var incomplete := base.duplicate(true)
	incomplete["common_depth"] = 1
	var incomplete_session := _c3fam_started_override_session(catalog, incomplete)
	var incomplete_ok := false
	if incomplete_session != null and incomplete_session.battle_state() != null:
		var actions := _c3fae_actions(incomplete_session.battle_state())
		if not actions.is_empty():
			var before := incomplete_session.battle_state().turn
			var events := incomplete_session.submit_player_action_with_autonomous_trainer(actions[0])
			var tie := incomplete_session.last_trainer_game_ready_tie_report
			incomplete_ok = (
				events.is_empty()
				and incomplete_session.battle_state().turn == before
				and String(tie.get("tie_resolution_status", "")) == TrainerGameReadyTieResolver.BLOCKED
				and String(tie.get("blocked_reason", "")) == "proposal_depth_incomplete"
			)

	var legal: Array[BattleAction] = []
	for value in bundle.get("legal_actions", []) as Array:
		var action := value as BattleAction
		if action != null:
			legal.append(BattleAction.from_dict(action.to_dict()))
	var resolver := TrainerGameReadyTieResolver.new()
	var stale := resolver.resolve(base, legal, &"trainer_battle_wrong", int(base.get("turn", 0)), &"side_b")
	var stale_ok := String(stale.get("tie_resolution_status", "")) == TrainerGameReadyTieResolver.BLOCKED and String(stale.get("blocked_reason", "")) == "proposal_battle_mismatch"

	var missing_legal: Array[BattleAction] = []
	for i in range(maxi(0, legal.size() - 1)):
		missing_legal.append(BattleAction.from_dict(legal[i].to_dict()))
	var illegal := resolver.resolve(base, missing_legal, StringName(String(base.get("battle_id", ""))), int(base.get("turn", 0)), &"side_b")
	var illegal_ok := String(illegal.get("tie_resolution_status", "")) == TrainerGameReadyTieResolver.BLOCKED

	_gr_check.call("game_ready_incomplete_tie_still_blocks", incomplete_ok)
	_gr_check.call("game_ready_stale_tie_still_blocks", stale_ok)
	_gr_check.call("game_ready_missing_live_tied_root_blocks", illegal_ok)
	return {"ok": incomplete_ok and stale_ok and illegal_ok}


func _test_unique_path_unchanged(catalog: DefinitionCatalog) -> Dictionary:
	var session := _c3faf_started_session(catalog, &"game_ready_unique", 913611)
	if session == null or session.battle_state() == null:
		_gr_check.call("game_ready_unique_fixture", false)
		return {"ok": false}
	var pair := _c3fae_actions(session.battle_state())
	if pair.is_empty():
		return {"ok": false}
	var events := session.submit_player_action_with_autonomous_trainer(pair[0])
	var proposal := session.last_trainer_action_proposal_report
	var substitution := session.last_trainer_action_substitution_report
	var ok := (
		not events.is_empty()
		and session.last_error.is_empty()
		and String(proposal.get("proposal_status", "")) == TrainerItemAwareActionProposal.PROPOSAL_READY
		and String(substitution.get("substitution_status", "")) == TrainerBattleSession.SUBSTITUTION_READY
		and session.last_trainer_game_ready_tie_report.is_empty()
		and not bool(substitution.get("game_ready_tiebreak_used", false))
	)
	_gr_check.call("game_ready_unique_max_path_unchanged", ok)
	return {"ok": ok}


func _run_adversarial_matrix(catalog: DefinitionCatalog) -> Dictionary:
	var policies := ["damage_greedy", "switch_bait", "sacrifice", "item_heal"]
	var results: Array[Dictionary] = []
	var all_ok := true
	var total_tie_resolutions := 0
	var item_policy_used_item := false
	for i in range(policies.size()):
		var result := _run_policy_battle(String(policies[i]), catalog, 914000 + i)
		results.append(result)
		all_ok = all_ok and bool(result.get("finished", false)) and not bool(result.get("deadlock", true))
		total_tie_resolutions += int(result.get("tie_resolutions", 0))
		if String(policies[i]) == "item_heal":
			item_policy_used_item = int(result.get("player_item_actions", 0)) > 0
		_gr_check.call("game_ready_adversarial_%s_finishes" % String(policies[i]), bool(result.get("finished", false)) and not bool(result.get("deadlock", true)))
	_gr_check.call("game_ready_adversarial_item_policy_exercises_item", item_policy_used_item)
	return {
		"ok": all_ok and item_policy_used_item,
		"policies": results,
		"total_tie_resolutions": total_tie_resolutions,
	}


func _run_policy_battle(policy: String, catalog: DefinitionCatalog, seed: int) -> Dictionary:
	var session := _c3faf_started_session(catalog, StringName("game_ready_%s" % policy), seed)
	if session == null or session.battle_state() == null:
		return {"policy": policy, "finished": false, "deadlock": true}
	var state := session.battle_state()
	_shorten_battle_for_adversarial_gate(state)
	var player_inventory := BattleSideItemInventory.new()
	player_inventory.set_quantity(GAME_READY_POTION, 2)
	state.set_item_inventory_for_side(&"side_a", player_inventory)
	var trainer_inventory := BattleSideItemInventory.new()
	trainer_inventory.set_quantity(GAME_READY_POTION, 1)
	state.set_item_inventory_for_side(&"side_b", trainer_inventory)
	if policy == "item_heal":
		var active := state.active_for_side(&"side_a")
		if active != null:
			active.current_hp = maxi(1, active.stats.max_hp / 4)
	if policy == "sacrifice":
		var active := state.active_for_side(&"side_a")
		var side := state.side_for_creature(active.instance_id) if active != null else null
		if side != null:
			for instance_id in side.party_ids:
				if instance_id != side.active_id:
					var candidate := state.creature(instance_id)
					if candidate != null and not candidate.is_knocked_out():
						candidate.current_hp = 1
						break

	var turns := 0
	var deadlock := false
	var tie_resolutions := 0
	var item_actions := 0
	while session.has_active_battle() and turns < MAX_BATTLE_TURNS:
		state = session.battle_state()
		if state == null:
			break
		if state.phase == BattleState.FINISHED:
			break
		var legal := TrainerActionSpace.from_server(session._battle_server, &"side_a")
		var action := _select_policy_action(policy, legal, state, turns, catalog)
		if action == null:
			deadlock = true
			break
		if action.action_type == BattleAction.ITEM:
			item_actions += 1
		var before := state.turn
		var events := session.submit_player_action_with_autonomous_trainer(action)
		if String(session.last_trainer_game_ready_tie_report.get("tie_resolution_status", "")) == TrainerGameReadyTieResolver.TIE_RESOLVED:
			tie_resolutions += 1
		if events.is_empty() and not session.last_error.is_empty():
			deadlock = true
			break
		var after_state := session.battle_state()
		if after_state != null and after_state.phase != BattleState.FINISHED and after_state.turn <= before:
			deadlock = true
			break
		turns += 1

	var finished := false
	var reason := ""
	if session.has_active_battle() and session.battle_state() != null and session.battle_state().phase == BattleState.FINISHED:
		var settlement := session.settle_finished_battle()
		finished = settlement != null and settlement.ok and session.status == TrainerBattleSession.COMPLETED
		reason = String(session.completion_reason)
	return {
		"policy": policy,
		"finished": finished,
		"deadlock": deadlock,
		"turns": turns,
		"completion_reason": reason,
		"tie_resolutions": tie_resolutions,
		"player_item_actions": item_actions,
	}


func _shorten_battle_for_adversarial_gate(state: BattleState) -> void:
	if state == null:
		return
	for side_id in [&"side_a", &"side_b"]:
		var active := state.active_for_side(side_id)
		var side := state.side_for_creature(active.instance_id) if active != null else null
		if side == null:
			continue
		for instance_id in side.party_ids:
			var creature := state.creature(instance_id)
			if creature != null and not creature.is_knocked_out():
				creature.current_hp = maxi(2, creature.stats.max_hp / 2)


func _select_policy_action(
	policy: String,
	legal: Array[BattleAction],
	state: BattleState,
	turn_index: int,
	catalog: DefinitionCatalog,
) -> BattleAction:
	if legal.is_empty():
		return null
	var moves: Array[BattleAction] = []
	var switches: Array[BattleAction] = []
	var items: Array[BattleAction] = []
	for action in legal:
		if action == null:
			continue
		match action.action_type:
			BattleAction.MOVE:
				moves.append(action)
			BattleAction.SWITCH:
				switches.append(action)
			BattleAction.ITEM:
				items.append(action)
	if policy == "switch_bait" and turn_index < 4 and not switches.is_empty():
		return BattleAction.from_dict(switches[turn_index % switches.size()].to_dict())
	if policy == "sacrifice" and turn_index == 0 and not switches.is_empty():
		var chosen := switches[0]
		var lowest_hp := 2147483647
		for action in switches:
			var target := state.creature(action.switch_instance_id)
			if target != null and target.current_hp < lowest_hp:
				lowest_hp = target.current_hp
				chosen = action
		return BattleAction.from_dict(chosen.to_dict())
	if policy == "item_heal" and not items.is_empty():
		var active := state.active_for_side(&"side_a")
		if active != null and active.current_hp * 100 < active.stats.max_hp * 75:
			for action in items:
				if action.target_id == active.instance_id:
					return BattleAction.from_dict(action.to_dict())
	return _best_damage_move(moves, legal, catalog)


func _best_damage_move(moves: Array[BattleAction], fallback: Array[BattleAction], catalog: DefinitionCatalog) -> BattleAction:
	if moves.is_empty():
		return BattleAction.from_dict(fallback[0].to_dict()) if not fallback.is_empty() else null
	var best := moves[0]
	var best_power := -1
	for action in moves:
		var move := catalog.move(action.move_id) if catalog != null else null
		var power := move.power if move != null else 0
		if power > best_power:
			best_power = power
			best = action
	return BattleAction.from_dict(best.to_dict())


func _run_decision_benchmark(catalog: DefinitionCatalog) -> Dictionary:
	var samples_ms: Array[float] = []
	var root_counts: Array[int] = []
	for i in range(5):
		var session := _c3faf_started_session(catalog, StringName("game_ready_bench_%d" % i), 915000 + i)
		if session == null or session.battle_state() == null:
			return {"ok": false}
		var inventory := BattleSideItemInventory.new()
		inventory.set_quantity(GAME_READY_POTION, 1)
		inventory.set_quantity(GAME_READY_SUPER_POTION, 1)
		session.battle_state().set_item_inventory_for_side(&"side_b", inventory)
		var started := Time.get_ticks_usec()
		var proposal := session.trainer_action_proposal_report_for_side(&"side_b")
		var elapsed_ms := float(Time.get_ticks_usec() - started) / 1000.0
		if not [TrainerItemAwareActionProposal.PROPOSAL_READY, TrainerItemAwareActionProposal.TIE_UNRESOLVED].has(String(proposal.get("proposal_status", ""))):
			return {"ok": false, "failed_status": String(proposal.get("proposal_status", ""))}
		samples_ms.append(elapsed_ms)
		root_counts.append(int(proposal.get("legal_action_count", 0)))
	samples_ms.sort()
	var median := samples_ms[samples_ms.size() / 2]
	var p95_index := mini(samples_ms.size() - 1, int(ceil(float(samples_ms.size()) * 0.95)) - 1)
	var p95 := samples_ms[p95_index]
	var maximum := samples_ms[samples_ms.size() - 1]
	var ok := maximum <= MAX_DECISION_MS_CI
	_gr_check.call("game_ready_benchmark_five_samples", samples_ms.size() == 5)
	_gr_check.call("game_ready_benchmark_positive_times", median > 0.0 and p95 > 0.0 and maximum > 0.0)
	_gr_check.call("game_ready_benchmark_ci_guard_under_5s", ok)
	return {
		"ok": ok,
		"samples_ms": samples_ms,
		"root_counts": root_counts,
		"median_ms": median,
		"p95_ms": p95,
		"max_ms": maximum,
		"ci_guard_ms": MAX_DECISION_MS_CI,
		"scope": "CI reference; not a direct measurement of the user PC",
	}


func _game_ready_root_id(action: BattleAction) -> String:
	if action == null:
		return ""
	if action.action_type == BattleAction.SWITCH:
		return "switch:%s" % String(action.switch_instance_id)
	if action.action_type == BattleAction.ITEM:
		return "item:%s:%s" % [String(action.item_id), String(action.target_id)]
	if action.action_type == BattleAction.MOVE:
		return "move:%s" % String(action.move_id)
	return ""


func _game_ready_kind(action: BattleAction) -> String:
	if action == null:
		return ""
	match action.action_type:
		BattleAction.MOVE:
			return "MOVE"
		BattleAction.SWITCH:
			return "SWITCH"
		BattleAction.ITEM:
			return "ITEM"
	return ""
