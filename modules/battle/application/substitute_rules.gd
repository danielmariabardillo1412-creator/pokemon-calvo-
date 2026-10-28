extends RefCounted

# Explicit singles pilot. The canonical move dataset is kept frozen.
# Sound/bypasssub IDs pinned from Pokemon Showdown data/moves.ts, 2026-10-26:
# SHA256 43b516fdc01721f53f01de555479dd3d248e5e29d2a6f5072a7bd4a3585a5027.
const BYPASS_IDS := "afteryou alluringvoice aromaticmist attract bestow boomburst bugbuzz chatter clangingscales clangoroussoul clangoroussoulblaze coaching confide conversion2 curse defog destinybond disable disarmingvoice dragoncheer echoedvoice eeriespell encore fairylock foresight gearup grasswhistle growl grudge guardswap haze healbell heartswap helpinghand holdhands howl hyperspacefury hyperspacehole hypervoice imprison instruct junglehealing lifedew magneticflux mefirst metalsound mimic miracleeye nobleroar odorsleuth overdrive partingshot perishsong playnice powder powerswap psychicnoise psychup reflecttype relicsong roar roleplay round screech sing sketch skillswap snarl snatch snore sparklingaria spectralthief speedswap spite supersonic taunt teatime torchsong torment uproar whirlwind"


static func supports(move: MoveDefinition) -> bool:
	return move != null and move.id in [&"substitute", &"shed_tail"] and move.power == 0 \
		and move.type_id == &"normal" and move.damage_class == "status" and move.target == "user" \
		and move.priority == 0 and move.accuracy == -1 and move.effect_specs.is_empty()


static func hp(creature: CreatureInstance) -> int:
	return maxi(0, int(creature.status_state.volatile.get(&"substitute", {}).get("hp", 0)))


static func record(creature: CreatureInstance) -> Dictionary:
	return {"hp": hp(creature), "max_hp": int(creature.status_state.volatile.get(&"substitute", {}).get("max_hp", hp(creature)))}


static func bypasses(context: BattleEffectContext, recipient: CreatureInstance) -> bool:
	return not context.state.substitute_rules_enabled or context.is_trigger or context.move == null \
		or recipient == context.actor or context.actor.ability_id == &"infiltrator" \
		or String(context.move.id).replace("_", "") in BYPASS_IDS.split(" ")


static func blocks(context: BattleEffectContext, recipient: CreatureInstance) -> bool:
	return not bypasses(context, recipient) and (hp(recipient) > 0 or context.last_hit_substitute)


static func effect_blocked(spec: BattleEffectSpec, context: BattleEffectContext) -> bool:
	if spec.kind == BattleEffectSpec.CHANCE:
		if spec.children.is_empty(): return false
		for child in spec.children:
			if not effect_blocked(child, context): return false
		return true
	return spec.kind in [BattleEffectSpec.INFLICT_STATUS, BattleEffectSpec.MODIFY_STAT_STAGE,
		BattleEffectSpec.FLINCH, BattleEffectSpec.HEAL, BattleEffectSpec.CURE_STATUS] \
		and blocks(context, context.resolve_target(spec.target))


static func damage(context: BattleEffectContext, recipient: CreatureInstance, requested: int, metadata: Dictionary = {}) -> int:
	context.last_hit_substitute = false
	if not bypasses(context, recipient) and hp(recipient) > 0:
		var before := hp(recipient)
		var applied := mini(before, maxi(0, requested))
		var doll := record(recipient)
		doll.hp = before - applied
		recipient.status_state.add_volatile(&"substitute", doll)
		context.last_hit_substitute = true
		context.substitute_intercepted = true
		context.events.append(BattleEvent.new(BattleEvent.SUBSTITUTE_DAMAGED, context.state.turn,
			context.actor.instance_id, recipient.instance_id, context.move.id, applied,
			{"hp": doll.hp, "max_hp": doll.max_hp, "damage": metadata.duplicate(true)}))
		if doll.hp == 0:
			recipient.status_state.remove_volatile(&"substitute")
			context.events.append(BattleEvent.new(BattleEvent.SUBSTITUTE_BROKEN, context.state.turn,
				context.actor.instance_id, recipient.instance_id, context.move.id))
		return applied
	var applied := recipient.apply_damage(requested)
	if recipient == context.target: context.body_damage += applied
	if applied > 0:
		context.events.append(BattleEvent.new(BattleEvent.DAMAGE_APPLIED, context.state.turn,
			context.actor.instance_id, recipient.instance_id, context.move.id if context.move != null else &"", applied, metadata))
	return applied


static func create(state: BattleState, actor: CreatureInstance, move: MoveDefinition, events: Array[BattleEvent]) -> bool:
	var cost := int(ceil(actor.stats.max_hp / 2.0)) if move.id == &"shed_tail" else int(actor.stats.max_hp / 4.0)
	var doll_hp := int(actor.stats.max_hp / 4.0)
	var reason := ""
	if actor.status_state.has_volatile(&"substitute"): reason = "already_substitute"
	elif actor.current_hp <= cost or doll_hp <= 0: reason = "insufficient_hp"
	elif move.id == &"shed_tail":
		if not state.switch_move_rules_enabled: reason = "switch_rules_required"
		elif preload("res://modules/battle/application/switch_move_rules.gd").replacements(state, state.side_for_creature(actor.instance_id).side_id).is_empty(): reason = "no_reserve"
	if not reason.is_empty():
		events.append(BattleEvent.new(BattleEvent.SUBSTITUTE_FAILED, state.turn, actor.instance_id,
			actor.instance_id, move.id, 0, {"reason": reason}))
		return false
	actor.apply_damage(cost)
	actor.status_state.add_volatile(&"substitute", {"hp": doll_hp, "max_hp": doll_hp})
	events.append(BattleEvent.new(BattleEvent.HP_COST, state.turn, actor.instance_id, actor.instance_id, move.id, cost))
	events.append(BattleEvent.new(BattleEvent.SUBSTITUTE_CREATED, state.turn, actor.instance_id,
		actor.instance_id, move.id, doll_hp, record(actor)))
	events.append(BattleEvent.new(BattleEvent.MOVE_EFFECT_RESOLVED, state.turn, actor.instance_id, actor.instance_id, move.id))
	return true
