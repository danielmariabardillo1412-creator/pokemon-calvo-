class_name TrainerItemAwareWorldFactory
extends TrainerCoverageAwareWorldFactory

const RESOURCE_MODEL := "own_exact_opponent_unmodeled_battle_items_v1"


func _build_world(
	context: TrainerDecisionContext,
	active_ability_id: StringName,
	ability_confidence_bp: int,
	active_speed: int,
	rng_seed: int,
	world_index: int,
) -> TrainerPlausibleWorld:
	var world := super._build_world(
		context,
		active_ability_id,
		ability_confidence_bp,
		active_speed,
		rng_seed,
		world_index,
	)
	if world == null or world.state == null or context == null or context.observation == null:
		return world
	var observation := context.observation
	if not observation.own_item_inventory.is_empty():
		world.state.set_item_inventory_for_side(
			observation.observer_side_id,
			BattleSideItemInventory.from_dict(observation.own_item_inventory),
		)
	world.assumptions.append("own_battle_item_inventory_exact")
	world.assumptions.append("opponent_battle_item_inventory_unmodeled")
	world.metadata["battle_item_resource_model"] = RESOURCE_MODEL
	return world
