class_name TrainerDualSideBattleMemoryOwner
extends RefCounted

# Trusted C3f-ae wiring seam. It owns one TrainerBattleMemory per battle side from
# battle start, fans the same authoritative event batch into both side-specific
# projections, and only exposes detached snapshots. It deliberately contains no
# brain, search, policy, sampler or action-selection logic.

const SIDE_A := &"side_a"
const SIDE_B := &"side_b"

var battle_id: StringName = &""
var _memories: Dictionary = {}


func begin(state: BattleState) -> bool:
	clear()
	if not _state_has_both_sides(state):
		return false
	var memory_a := TrainerBattleMemory.new()
	var memory_b := TrainerBattleMemory.new()
	if not memory_a.begin(state, SIDE_A):
		return false
	if not memory_b.begin(state, SIDE_B):
		return false
	battle_id = state.battle_id
	_memories[SIDE_A] = memory_a
	_memories[SIDE_B] = memory_b
	return true


func clear() -> void:
	for value in _memories.values():
		var memory := value as TrainerBattleMemory
		if memory != null:
			memory.clear()
	_memories.clear()
	battle_id = &""


func is_ready(state: BattleState = null) -> bool:
	if battle_id == &"":
		return false
	if state != null:
		if state.battle_id != battle_id or not _state_has_both_sides(state):
			return false
	var memory_a := _memory_for_side(SIDE_A)
	var memory_b := _memory_for_side(SIDE_B)
	return (
		memory_a != null
		and memory_b != null
		and memory_a.battle_id == battle_id
		and memory_b.battle_id == battle_id
		and memory_a.observer_side_id == SIDE_A
		and memory_b.observer_side_id == SIDE_B
	)


# Atomic fan-out: both side projections are advanced on detached clones first. The
# live owner swaps them in only after both projections accept the same trusted batch.
func observe_authoritative(events: Array[BattleEvent], state: BattleState) -> bool:
	if not is_ready(state):
		return false
	var next_a := _clone_for_side(SIDE_A)
	var next_b := _clone_for_side(SIDE_B)
	if next_a == null or next_b == null:
		return false
	if not next_a.observe_events(events, state):
		return false
	if not next_b.observe_events(events, state):
		return false
	_memories[SIDE_A] = next_a
	_memories[SIDE_B] = next_b
	return true


# Search/decision callers receive a clone, never the owner's mutable live memory.
func snapshot_for_side(state: BattleState, side_id: StringName) -> TrainerBattleMemory:
	if not _valid_side(side_id) or not is_ready(state):
		return null
	return _clone_for_side(side_id)


# Branch events are projected only after cloning the requested side's live history.
# The branch snapshot is disposable and can never mutate the live owner.
func branch_snapshot_for_side(
	side_id: StringName,
	events: Array[BattleEvent],
	branch_state: BattleState,
) -> TrainerBattleMemory:
	if not _valid_side(side_id) or branch_state == null:
		return null
	if branch_state.battle_id != battle_id or not is_ready():
		return null
	var branch_memory := _clone_for_side(side_id)
	if branch_memory == null:
		return null
	if not branch_memory.observe_events(events, branch_state):
		return null
	return branch_memory


func _clone_for_side(side_id: StringName) -> TrainerBattleMemory:
	var memory := _memory_for_side(side_id)
	if memory == null:
		return null
	return TrainerBattleMemory.from_dict(memory.to_dict().duplicate(true))


func _memory_for_side(side_id: StringName) -> TrainerBattleMemory:
	return _memories.get(side_id, null) as TrainerBattleMemory


func _valid_side(side_id: StringName) -> bool:
	return side_id == SIDE_A or side_id == SIDE_B


func _state_has_both_sides(state: BattleState) -> bool:
	return (
		state != null
		and state.battle_id != &""
		and state.active_for_side(SIDE_A) != null
		and state.active_for_side(SIDE_B) != null
	)
