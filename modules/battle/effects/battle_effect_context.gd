class_name BattleEffectContext
extends RefCounted

var state: BattleState
var actor: CreatureInstance
var target: CreatureInstance
var move: MoveDefinition
var catalog: DefinitionCatalog
var ruleset: BattleRuleset
var rng: SeededRandomSource
var events: Array[BattleEvent]
var last_damage: int = 0


func _init(
	p_state: BattleState,
	p_actor: CreatureInstance,
	p_target: CreatureInstance,
	p_move: MoveDefinition,
	p_catalog: DefinitionCatalog,
	p_ruleset: BattleRuleset,
	p_rng: SeededRandomSource,
	p_events: Array[BattleEvent],
) -> void:
	state = p_state
	actor = p_actor
	target = p_target
	move = p_move
	catalog = p_catalog
	ruleset = p_ruleset
	rng = p_rng
	events = p_events


func resolve_target(selector: StringName) -> CreatureInstance:
	return actor if selector == BattleEffectSpec.SELF else target
