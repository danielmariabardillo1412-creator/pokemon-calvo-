extends RefCounted

# Pure extensions to calvo_capture_v1, using the pinned Essentials ball handlers.
# Does not replace the project's capture probability, status bonuses or RNG.
const IDS: Array[StringName] = [&"nest_ball", &"fast_ball", &"dream_ball", &"heal_ball", &"premier_ball"]

static func multiplier(id: StringName, target: CreatureInstance, species: CreatureSpecies) -> float:
	match id:
		&"nest_ball": return maxf((41.0 - target.level) / 10.0, 1.0)
		# The reference caps Fast Ball's modified catch rate BEFORE the status
		# bonus/HP factor. Express that cap as a multiplier, preserving V1's API.
		&"fast_ball": return minf(4.0, 255.0 / species.capture_rate) if species.base_speed >= 100 else 1.0
		&"dream_ball": return 4.0 if target.status_state.persistent_id == &"sleep" else 1.0
	return 1.0

static func validation_error(id: StringName, target: CreatureInstance) -> String:
	if not IDS.has(id): return ""
	if target.level < 1 or target.level > 100 or target.stats == null or target.stats.max_hp < 1 or target.current_hp > target.stats.max_hp or target.status_state == null:
		return "invalid_ball_target_state"
	if id == &"heal_ball":
		for slot: BattleMoveSlot in target.moveset:
			if slot == null or slot.max_pp < 1 or slot.current_pp < 0 or slot.current_pp > slot.max_pp: return "invalid_ball_pp_state"
	return ""

static func on_catch(id: StringName, target: CreatureInstance) -> void:
	if id != &"heal_ball": return
	target.current_hp = target.stats.max_hp
	target.status_state.clear_persistent()
	target.status_ids.clear()
	for slot: BattleMoveSlot in target.moveset: slot.current_pp = slot.max_pp
