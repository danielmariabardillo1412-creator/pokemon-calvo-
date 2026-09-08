class_name GameCampaignState
extends RefCounted

# Pure campaign/world-progress authority introduced by Game Foundation V1.
#
# This object deliberately does NOT own CreatureInstance, party, storage, inventory, BattleState,
# scenes, Nodes or file IO. Those domains already have their own authorities. Save V3 will later
# persist this object's deterministic DTO alongside PlayerCollection without moving ownership here.

const SCHEMA_VERSION := 1
const RULESET_ID := &"calvo_game_campaign_v1"

var campaign_id: StringName = &""
var current_map_id: StringName = &""
var current_spawn_id: StringName = &""
var starter_species_id: StringName = &""
var campaign_stage: int = 0

var _story_flags: Dictionary = {}
var _defeated_trainers: Dictionary = {}


func initialize_new(
	new_campaign_id: StringName,
	initial_map_id: StringName,
	initial_spawn_id: StringName,
) -> bool:
	if is_initialized():
		return false
	if new_campaign_id == &"" or initial_map_id == &"" or initial_spawn_id == &"":
		return false

	# Validate first, publish second: initialization is all-or-nothing.
	campaign_id = new_campaign_id
	current_map_id = initial_map_id
	current_spawn_id = initial_spawn_id
	starter_species_id = &""
	campaign_stage = 0
	_story_flags.clear()
	_defeated_trainers.clear()
	return true


func is_initialized() -> bool:
	return campaign_id != &"" and current_map_id != &"" and current_spawn_id != &""


# Map and spawn form one location identity. Never publish only half a transition.
func set_location(map_id: StringName, spawn_id: StringName) -> bool:
	if not is_initialized() or map_id == &"" or spawn_id == &"":
		return false
	current_map_id = map_id
	current_spawn_id = spawn_id
	return true


# Starter choice is write-once. Repeating the same choice is idempotent; rebinding to another
# species fails closed. Species existence is a catalog/application concern, not this pure state.
func choose_starter(species_id: StringName) -> bool:
	if not is_initialized() or species_id == &"":
		return false
	if starter_species_id == &"":
		starter_species_id = species_id
		return true
	return starter_species_id == species_id


func has_starter() -> bool:
	return starter_species_id != &""


# Story flags are positive boolean facts. false removes the fact; there is no tri-state hidden
# semantics. This keeps the DTO deterministic and lets event logic ask only `has_story_flag()`.
func set_story_flag(flag_id: StringName, enabled: bool = true) -> bool:
	if not is_initialized() or flag_id == &"":
		return false
	if enabled:
		_story_flags[flag_id] = true
	else:
		_story_flags.erase(flag_id)
	return true


func has_story_flag(flag_id: StringName) -> bool:
	return flag_id != &"" and _story_flags.has(flag_id)


# Defeat is monotonic and idempotent. Rematches can be modeled later as a different event/policy;
# they must not silently erase the campaign fact that this trainer was defeated once.
func mark_trainer_defeated(trainer_id: StringName) -> bool:
	if not is_initialized() or trainer_id == &"":
		return false
	_defeated_trainers[trainer_id] = true
	return true


func is_trainer_defeated(trainer_id: StringName) -> bool:
	return trainer_id != &"" and _defeated_trainers.has(trainer_id)


# Minimal coarse campaign progress. It is intentionally monotonic; detailed branching belongs to
# flags/events in GF1-C rather than encoding a quest engine into this integer.
func advance_campaign_stage(next_stage: int) -> bool:
	if not is_initialized() or next_stage < campaign_stage or next_stage < 0:
		return false
	campaign_stage = next_stage
	return true


func story_flag_ids() -> Array[StringName]:
	return _sorted_ids(_story_flags)


func defeated_trainer_ids() -> Array[StringName]:
	return _sorted_ids(_defeated_trainers)


# Detached, deterministic DTO seam for future Save V3. Arrays are newly allocated and sorted, so
# callers cannot mutate authoritative dictionaries through the returned snapshot.
func to_dict() -> Dictionary:
	var flags: Array[String] = []
	for id in story_flag_ids():
		flags.append(String(id))
	var trainers: Array[String] = []
	for id in defeated_trainer_ids():
		trainers.append(String(id))
	return {
		"schema_version": SCHEMA_VERSION,
		"ruleset_id": String(RULESET_ID),
		"campaign_id": String(campaign_id),
		"current_map_id": String(current_map_id),
		"current_spawn_id": String(current_spawn_id),
		"starter_species_id": String(starter_species_id),
		"campaign_stage": campaign_stage,
		"story_flags": flags,
		"defeated_trainers": trainers,
	}


# Live-domain validation. Save V3 will add hostile-payload shape validation at its serialization
# boundary; this method protects invariants of an already constructed campaign authority.
func validate() -> Dictionary:
	if campaign_id == &"":
		return {"ok": false, "reason": "missing_campaign_id"}
	if current_map_id == &"":
		return {"ok": false, "reason": "missing_current_map_id"}
	if current_spawn_id == &"":
		return {"ok": false, "reason": "missing_current_spawn_id"}
	if campaign_stage < 0:
		return {"ok": false, "reason": "negative_campaign_stage"}
	for flag_id in _story_flags.keys():
		if StringName(flag_id) == &"" or _story_flags[flag_id] != true:
			return {"ok": false, "reason": "invalid_story_flag"}
	for trainer_id in _defeated_trainers.keys():
		if StringName(trainer_id) == &"" or _defeated_trainers[trainer_id] != true:
			return {"ok": false, "reason": "invalid_defeated_trainer"}
	return {"ok": true, "reason": ""}


func _sorted_ids(source: Dictionary) -> Array[StringName]:
	var strings: Array[String] = []
	for raw_id in source.keys():
		strings.append(String(raw_id))
	strings.sort()
	var out: Array[StringName] = []
	for text in strings:
		out.append(StringName(text))
	return out
