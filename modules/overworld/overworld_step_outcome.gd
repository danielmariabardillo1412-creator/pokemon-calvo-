class_name OverworldStepOutcome
extends RefCounted

# Semantic result of one completed overworld movement step. The overworld layer reports whether
# the step was eligible for an encounter and whether it actually started the existing wild battle
# vertical slice; it never duplicates encounter/battle rules here.

var zone_id: StringName = &""
var rolled: bool = false
var battle_started: bool = false
var reason: String = ""
var encounter: WildEncounterResult = null
