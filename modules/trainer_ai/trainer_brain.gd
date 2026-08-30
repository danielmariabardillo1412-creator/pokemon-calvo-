class_name TrainerBrain
extends RefCounted

# Replaceable strategy boundary. Concrete heuristic, search, neural, ensemble or
# teacher-assisted brains must consume TrainerDecisionContext instead of live BattleState.

var brain_id: StringName = &"trainer_brain_base"


func choose_action(_context: TrainerDecisionContext) -> BattleAction:
	return null
