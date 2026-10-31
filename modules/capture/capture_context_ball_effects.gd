extends RefCounted

# Context supplied by the owning session, never by a UI or saved extra counter.
# Essentials reference uses completed turns (zero before the first action).
const IDS: Array[StringName] = [&"quick_ball", &"timer_ball", &"level_ball"]
const Basic = preload("res://modules/capture/capture_ball_effects.gd")

static func validation_error(id: StringName, target: CreatureInstance, context: CaptureBattleContext) -> String:
	if not IDS.has(id): return ""
	# Nest's branch contains only the common target-state preflight, with no
	# move-slot/PP-specific checks or effects. Reuse it for these three balls.
	var error := Basic.validation_error(&"nest_ball", target)
	if error != "": return error
	if id in [&"quick_ball", &"timer_ball"] and context.completed_turns < 0: return "capture_turn_context_missing"
	if id == &"level_ball" and (context.catcher_level < 1 or context.catcher_level > 100): return "capture_active_level_context_missing"
	return ""

static func multiplier(id: StringName, target: CreatureInstance, species: CreatureSpecies, context: CaptureBattleContext) -> float:
	match id:
		&"quick_ball": return 5.0 if context.completed_turns == 0 else 1.0
		&"timer_ball": return minf(1.0 + 0.3 * context.completed_turns, 4.0)
		&"level_ball":
			var factor := 1.0
			if context.catcher_level >= target.level * 4: factor = 8.0
			elif context.catcher_level >= target.level * 2: factor = 4.0
			elif context.catcher_level > target.level: factor = 2.0
			return minf(factor, 255.0 / species.capture_rate)
	return 1.0
