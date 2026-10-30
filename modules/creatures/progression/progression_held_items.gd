extends RefCounted

# Post-battle / level-up effects only. No battle engine, inventory, UI, IO or RNG.
# Essentials 8c5911e: Lucky Egg exp * 3 / 2, current item then initial item fallback.
static func active_item(creature: CreatureInstance, item_id: StringName) -> bool:
	return creature!=null and creature.held_item_id==item_id and not creature.held_item_consumed

static func blocks_level_evolution(creature: CreatureInstance) -> bool:
	return active_item(creature,&"everstone")

static func starting_items_from_records(rows: Array) -> Dictionary:
	var items: Dictionary={}
	for row: Dictionary in rows:
		if not bool(row.get("held_item_consumed",false)):
			items[String(row.instance_id)]=String(row.get("held_item_id",""))
	return items

static func starting_items_from_creatures(creatures: Array) -> Dictionary:
	var rows: Array=[]
	for c: CreatureInstance in creatures:
		rows.append({"instance_id":String(c.instance_id),"held_item_id":String(c.held_item_id),"held_item_consumed":c.held_item_consumed})
	return starting_items_from_records(rows)

static func battle_reward_amount(base_amount: int, creature: CreatureInstance, starting_items: Dictionary, maximum_exp: int) -> int:
	var amount:=maxi(0,base_amount)
	if active_item(creature,&"lucky_egg") or StringName(starting_items.get(String(creature.instance_id),""))==&"lucky_egg":
		amount=amount*3/2
	# Report only XP actually granted, including a final partial award at level 100.
	return mini(amount,maxi(0,maximum_exp-creature.experience))
