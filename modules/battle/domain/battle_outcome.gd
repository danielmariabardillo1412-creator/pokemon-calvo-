class_name BattleOutcome
extends RefCounted

# Result object produced by the Battle Core after a battle finishes. This is the ONLY
# contract the Progression Core consumes: it never inspects battle internals, RNG or
# triggers. Pure data so it serializes for savegames/networking.
#
# participants : winning-side creatures (Array[Dictionary] with creature_id, species_id, side_id, level, fainted)
# defeated     : enemy creatures that fainted (Array[Dictionary] with species_id, level, base_experience)
# winner_side_id : the winning side id (side_a / side_b)

var winner_side_id: StringName = &""
var participants: Array = []
var defeated: Array = []


func to_dict() -> Dictionary:
	return {
		"winner_side_id": String(winner_side_id),
		"participants": participants,
		"defeated": defeated,
	}


static func from_dict(data: Dictionary) -> BattleOutcome:
	var o := BattleOutcome.new()
	o.winner_side_id = StringName(data.get("winner_side_id", ""))
	o.participants = data.get("participants", [])
	o.defeated = data.get("defeated", [])
	return o


# Build an outcome by observing a finished BattleState (read-only). Does not mutate the battle.
static func from_battle_state(state: BattleState, catalogs) -> BattleOutcome:
	var o := BattleOutcome.new()
	var winner_creature_id: StringName = state.winner_id
	# Determine winning side.
	var winning_side: BattleSide = null
	for side in state.sides:
		if side.owns(winner_creature_id):
			winning_side = side
			break
	if winning_side == null and state.sides.size() > 0:
		winning_side = state.sides[0]
	if winning_side != null:
		o.winner_side_id = winning_side.side_id
		for cid in winning_side.party_ids:
			var c: CreatureInstance = state.creature(cid)
			if c == null:
				continue
			o.participants.append({
				"creature_id": String(c.instance_id),
				"species_id": String(c.species_id),
				"side_id": String(winning_side.side_id),
				"level": c.level,
				"fainted": c.is_knocked_out(),
			})
	# Defeated = creatures on the other side that are knocked out.
	for side in state.sides:
		if side == winning_side:
			continue
		for cid in side.party_ids:
			var c: CreatureInstance = state.creature(cid)
			if c == null:
				continue
			if c.is_knocked_out():
				var species: CreatureSpecies = catalogs.species_catalog.get_by_id(c.species_id) if catalogs != null else null
				o.defeated.append({
					"species_id": String(c.species_id),
					"level": c.level,
					"base_experience": species.base_experience if species != null else 0,
				})
	return o
