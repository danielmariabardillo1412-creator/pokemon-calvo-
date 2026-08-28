class_name DefinitionCatalog
extends RefCounted

var _species: Dictionary = {}
var _moves: Dictionary = {}
var _types: Dictionary = {}
var _statuses: Dictionary = {}


func add_species(definition: CreatureSpecies) -> void:
	_species[definition.id] = definition


func add_move(definition: MoveDefinition) -> void:
	_moves[definition.id] = definition


func add_type(definition: TypeDefinition) -> void:
	_types[definition.id] = definition


func add_status(definition: Resource) -> void:
	_statuses[definition.get("id")] = definition


func species(id: StringName) -> CreatureSpecies:
	return _species.get(id) as CreatureSpecies


func move(id: StringName) -> MoveDefinition:
	return _moves.get(id) as MoveDefinition


func type(id: StringName) -> TypeDefinition:
	return _types.get(id) as TypeDefinition


func status(id: StringName) -> Resource:
	return _statuses.get(id) as Resource


func type_multiplier(attack_type_id: StringName, defender_type_id: StringName) -> float:
	var attack_type := type(attack_type_id)
	return attack_type.multiplier_against(defender_type_id) if attack_type != null else 1.0

