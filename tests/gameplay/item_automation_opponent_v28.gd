extends "res://modules/gameplay/showdown_adventure_session.gd"

# Fixture input only. Native submit/prepare/commit, rules and RNG are inherited.
var scripted_foe_choice := "move 1"

func opponent_choice() -> String:
	return scripted_foe_choice
