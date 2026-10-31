extends RefCounted

# Pure extensions to calvo_capture_v1, using the pinned Essentials ball handlers.
# Does not replace the project's capture probability, status bonuses or RNG.
const IDS: Array[StringName] = [&"nest_ball", &"fast_ball", &"dream_ball", &"heal_ball", &"premier_ball",
	&"friend_ball", &"safari_ball", &"sport_ball", &"cherish_ball", &"beast_ball"]

# Fuente: Bulbapedia Beast Ball / lista Ultra Beasts (Gen VII+).
# IDs base de los once ultraentes; Cosmog/Solgaleo/Lunala/Necrozma no se
# clasifican como ultraentes para este modificador.
const ULTRA_BEASTS: Array[StringName] = [
	&"nihilego", &"buzzwole", &"pheromosa", &"xurkitree",
	&"celesteela", &"kartana", &"guzzlord", &"poipole",
	&"naganadel", &"stakataka", &"blacephalon",
]

static func multiplier(id: StringName, target: CreatureInstance, species: CreatureSpecies) -> float:
	match id:
		# Gen VII+: x5 para ultraentes, 410/4096 para cualquier otro.
		# El resto de la fórmula sigue siendo calvo_capture_v1.
		&"beast_ball": return 5.0 if ULTRA_BEASTS.has(target.base_species_id()) else 410.0 / 4096.0
		&"nest_ball": return maxf((41.0 - target.level) / 10.0, 1.0)
		# The reference caps Fast Ball's modified catch rate BEFORE the status
		# bonus/HP factor. Express that cap as a multiplier, preserving V1's API.
		&"fast_ball": return minf(4.0, 255.0 / species.capture_rate) if species.base_speed >= 100 else 1.0
		&"dream_ball": return 4.0 if target.status_state.persistent_id == &"sleep" else 1.0
		&"safari_ball", &"sport_ball": return 1.5
	return 1.0

static func validation_error(id: StringName, target: CreatureInstance) -> String:
	if not IDS.has(id): return ""
	if target.level < 1 or target.level > 100 or target.stats == null or target.stats.max_hp < 1 or target.current_hp > target.stats.max_hp or target.status_state == null:
		return "invalid_ball_target_state"
	if id == &"friend_ball" and (target.friendship < 0 or target.friendship > 255): return "invalid_ball_friendship_state"
	if id == &"heal_ball":
		for slot: BattleMoveSlot in target.moveset:
			if slot == null or slot.max_pp < 1 or slot.current_pp < 0 or slot.current_pp > slot.max_pp: return "invalid_ball_pp_state"
	return ""

static func on_catch(id: StringName, target: CreatureInstance) -> void:
	# Pinned Essentials profile with happiness soft cap disabled: SET to 200,
	# including when the previous value was higher. Failure never calls this.
	if id == &"friend_ball": target.friendship = 200
	if id != &"heal_ball": return
	target.current_hp = target.stats.max_hp
	target.status_state.clear_persistent()
	target.status_ids.clear()
	for slot: BattleMoveSlot in target.moveset: slot.current_pp = slot.max_pp
