class_name TrainerSearchBudget
extends RefCounted

const SCHEMA_VERSION := 1

var depth_turns: int = 2
var max_worlds: int = 4
var max_simulations: int = 220
var max_actions_per_side: int = 3


static func depth_two_default() -> TrainerSearchBudget:
	return TrainerSearchBudget.new()


static func depth_one_compat() -> TrainerSearchBudget:
	var budget := TrainerSearchBudget.new()
	budget.depth_turns = 1
	budget.max_worlds = TrainerPlausibleWorldFactory.DEFAULT_MAX_WORLDS
	budget.max_simulations = 256
	budget.max_actions_per_side = 6
	return budget


static func constrained(
	p_depth_turns: int,
	p_max_worlds: int,
	p_max_simulations: int,
	p_max_actions_per_side: int,
) -> TrainerSearchBudget:
	var budget := TrainerSearchBudget.new()
	budget.depth_turns = clampi(p_depth_turns, 1, 2)
	budget.max_worlds = maxi(1, p_max_worlds)
	budget.max_simulations = maxi(1, p_max_simulations)
	budget.max_actions_per_side = maxi(1, p_max_actions_per_side)
	return budget


func normalized() -> TrainerSearchBudget:
	return TrainerSearchBudget.constrained(
		depth_turns,
		max_worlds,
		max_simulations,
		max_actions_per_side,
	)


func duplicate_budget() -> TrainerSearchBudget:
	return normalized()


func to_dict() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"depth_turns": clampi(depth_turns, 1, 2),
		"max_worlds": maxi(1, max_worlds),
		"max_simulations": maxi(1, max_simulations),
		"max_actions_per_side": maxi(1, max_actions_per_side),
		"timing_model": "deterministic_simulation_count_v1",
	}
