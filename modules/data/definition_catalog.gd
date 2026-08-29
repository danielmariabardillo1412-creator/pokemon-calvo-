class_name DefinitionCatalog
extends RefCounted

# Battle-runtime catalog facade. Aggregates the focused, injectable catalogs
# (SpeciesCatalog, MoveCatalog, TypeCatalog, StatusCatalog) so existing battle
# code keeps calling catalog.species(id) / catalog.move(id) / catalog.type_multiplier(...).
# It is itself RefCounted and passed explicitly (never an autoload).

var species_catalog := SpeciesCatalog.new()
var move_catalog := MoveCatalog.new()
var type_catalog := TypeCatalog.new()
var status_catalog := StatusCatalog.new()

func add_species(def: CreatureSpecies) -> void:
	species_catalog.add(def)

func add_move(def: MoveDefinition) -> void:
	move_catalog.add(def)

func add_type(def: TypeDefinition) -> void:
	type_catalog.add(def)

func add_status(def: StatusDefinition) -> void:
	status_catalog.add(def)

func species(id: StringName) -> CreatureSpecies:
	return species_catalog.get_by_id(id)

func move(id: StringName) -> MoveDefinition:
	return move_catalog.get_by_id(id)

func type(id: StringName) -> TypeDefinition:
	return type_catalog.get_by_id(id)

func status(id: StringName) -> StatusDefinition:
	return status_catalog.get_by_id(id)

func type_multiplier(attack_type_id: StringName, defender_type_id: StringName) -> float:
	var attack_type := type_catalog.get_by_id(attack_type_id)
	return attack_type.multiplier_against(defender_type_id) if attack_type != null else 1.0
