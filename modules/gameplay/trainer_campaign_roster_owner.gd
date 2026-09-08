class_name TrainerCampaignRosterOwner
extends RefCounted

# Persistent trainer-side ownership boundary outside BattleState/TrainerBattleSession.
# The owner preserves exact CreatureInstance identity and only copies Array containers.
# Battle consequences remain on those live objects until an explicit inter-battle policy
# (such as recover_creature_full) changes them.

var trainer_id: StringName = &""
var last_error: String = ""

var _roster: Array[CreatureInstance] = []


func configure(p_trainer_id: StringName, p_roster: Array[CreatureInstance]) -> bool:
	last_error = ""
	if p_trainer_id == &"":
		last_error = "trainer_id_required"
		return false
	var roster_error := _roster_validation_error(p_roster)
	if not roster_error.is_empty():
		last_error = roster_error
		return false

	# Validate first, then replace atomically. The container is detached while every
	# CreatureInstance reference remains exactly the caller-owned object.
	var next_roster: Array[CreatureInstance] = []
	for creature in p_roster:
		next_roster.append(creature)
	trainer_id = p_trainer_id
	_roster = next_roster
	return true


func is_ready() -> bool:
	return trainer_id != &"" and _roster_validation_error(_roster).is_empty()


func roster_size() -> int:
	return _roster.size()


func roster_for_battle() -> Array[CreatureInstance]:
	var result: Array[CreatureInstance] = []
	if not is_ready():
		return result
	for creature in _roster:
		result.append(creature)
	return result


func owned_creature(instance_id: StringName) -> CreatureInstance:
	if instance_id == &"":
		return null
	var found: CreatureInstance = null
	for creature in _roster:
		if creature.instance_id != instance_id:
			continue
		if found != null:
			# Corrupt/ambiguous ownership fails closed instead of choosing a copy.
			return null
		found = creature
	return found


# Explicit inter-battle full recovery policy. Nothing invokes this automatically.
# Reconciliation clears battle-only state; full recovery then restores persistent
# HP/PP and clears the persistent status on the same CreatureInstance object.
func recover_creature_full(instance_id: StringName) -> bool:
	last_error = ""
	if not is_ready():
		last_error = "owner_not_ready"
		return false
	var creature := owned_creature(instance_id)
	if creature == null:
		last_error = "creature_not_owned"
		return false

	creature.reconcile_post_battle()
	creature.current_hp = creature.stats.max_hp
	for raw_slot in creature.moveset:
		var slot := raw_slot as BattleMoveSlot
		if slot != null:
			slot.current_pp = slot.max_pp
	if creature.status_state != null:
		creature.status_state.clear_persistent()
	return true


# Explicit campaign replacement outside Battle Core. A replacement may introduce a
# new stable identity, but an existing instance_id can never be rebound to another object.
func replace_member(current_instance_id: StringName, replacement: CreatureInstance) -> bool:
	last_error = ""
	if not is_ready():
		last_error = "owner_not_ready"
		return false
	if current_instance_id == &"":
		last_error = "current_instance_id_required"
		return false
	if replacement == null:
		last_error = "replacement_required"
		return false
	if replacement.instance_id == &"":
		last_error = "replacement_identity_required"
		return false

	var current_index := -1
	for i in _roster.size():
		if _roster[i].instance_id == current_instance_id:
			if current_index >= 0:
				last_error = "ambiguous_current_ownership"
				return false
			current_index = i
	if current_index < 0:
		last_error = "current_creature_not_owned"
		return false

	var current := _roster[current_index]
	if replacement == current:
		return true
	if replacement.instance_id == current.instance_id:
		last_error = "identity_rebind_forbidden"
		return false

	for i in _roster.size():
		if i != current_index and _roster[i].instance_id == replacement.instance_id:
			last_error = "duplicate_creature_identity"
			return false

	# All validation is complete before the single mutation.
	_roster[current_index] = replacement
	return true


func _roster_validation_error(roster: Array[CreatureInstance]) -> String:
	if roster.is_empty():
		return "roster_required"
	var seen: Dictionary = {}
	for creature in roster:
		if creature == null:
			return "null_creature"
		if creature.instance_id == &"":
			return "creature_identity_required"
		if seen.has(creature.instance_id):
			return "duplicate_creature_identity"
		seen[creature.instance_id] = true
	return ""
