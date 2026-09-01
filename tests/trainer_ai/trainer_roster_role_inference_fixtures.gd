class_name TrainerRosterRoleInferenceFixtures
extends RefCounted

const SPECIES := &"role_fixture_species"
const MOVE_PHYSICAL := &"role_fixture_physical"
const MOVE_SPECIAL := &"role_fixture_special"
const MOVE_PRIORITY := &"role_fixture_priority"
const MOVE_CONTROL := &"role_fixture_control"
const MOVE_SETUP := &"role_fixture_setup"
const MOVE_SUSTAIN := &"role_fixture_sustain"
const MOVE_PARTIAL := &"role_fixture_partial"
const MOVE_DATA_ONLY := &"role_fixture_data_only"
const MOVE_UNSUPPORTED := &"role_fixture_unsupported"

const CLASS_RUNTIME_SUPPORTED := "RUNTIME_SUPPORTED"
const CLASS_PARTIAL_RUNTIME := "PARTIAL_RUNTIME"
const CLASS_DATA_ONLY := "DATA_ONLY"
const CLASS_UNSUPPORTED := "UNSUPPORTED"


static func build_catalog() -> DefinitionCatalog:
	var catalog := DefinitionCatalog.new()
	catalog.add_move(_move(MOVE_PHYSICAL, "physical", 100, CLASS_RUNTIME_SUPPORTED))
	catalog.add_move(_move(MOVE_SPECIAL, "special", 100, CLASS_RUNTIME_SUPPORTED))
	catalog.add_move(_move(MOVE_PRIORITY, "physical", 40, CLASS_RUNTIME_SUPPORTED, [], 1))
	catalog.add_move(_move(
		MOVE_CONTROL,
		"status",
		0,
		CLASS_RUNTIME_SUPPORTED,
		[BattleEffectSpec.new(
			BattleEffectSpec.MODIFY_STAT_STAGE,
			BattleEffectSpec.OPPONENT,
			-1,
			0,
			10000,
			&"",
			StatStages.ATTACK,
		)],
	))
	catalog.add_move(_move(
		MOVE_SETUP,
		"status",
		0,
		CLASS_RUNTIME_SUPPORTED,
		[BattleEffectSpec.new(
			BattleEffectSpec.MODIFY_STAT_STAGE,
			BattleEffectSpec.SELF,
			2,
			0,
			10000,
			&"",
			StatStages.ATTACK,
		)],
	))
	catalog.add_move(_move(
		MOVE_SUSTAIN,
		"status",
		0,
		CLASS_RUNTIME_SUPPORTED,
		[BattleEffectSpec.new(
			BattleEffectSpec.HEAL,
			BattleEffectSpec.SELF,
			0,
			5000,
		)],
	))
	catalog.add_move(_move(MOVE_PARTIAL, "physical", 120, CLASS_PARTIAL_RUNTIME))
	catalog.add_move(_move(MOVE_DATA_ONLY, "physical", 130, CLASS_DATA_ONLY))
	catalog.add_move(_move(MOVE_UNSUPPORTED, "physical", 140, CLASS_UNSUPPORTED))

	var species := CreatureSpecies.new()
	species.id = SPECIES
	species.display_name = "Role Inference Fixture Species"
	species.primary_type_id = &"normal"
	species.type_ids = [&"normal"]
	species.base_hp = 100
	species.base_attack = 100
	species.base_defense = 100
	species.base_speed = 100
	species.base_special_attack = 100
	species.base_special_defense = 100
	catalog.add_species(species)
	return catalog


static func member_view(
	catalog: DefinitionCatalog,
	instance_id: StringName,
	move_ids: Array,
	stats: StatBlock = null,
	current_hp: int = -1,
	zero_pp_move_id: StringName = &"",
) -> Dictionary:
	var typed_moves: Array[StringName] = []
	for move_id in move_ids:
		typed_moves.append(StringName(move_id))
	var actual_stats := stats if stats != null else StatBlock.new(200, 100, 100, 100, 100, 100)
	var creature := CreatureInstance.new(instance_id, SPECIES, 50, actual_stats, typed_moves)
	creature.initialize_move_pp(catalog)
	if current_hp >= 0:
		creature.current_hp = clampi(current_hp, 0, actual_stats.max_hp)
	if zero_pp_move_id != &"":
		var slot := creature.move_slot(zero_pp_move_id)
		if slot != null:
			slot.current_pp = 0
	return creature.to_dict().duplicate(true)


static func _move(
	id: StringName,
	damage_class: String,
	power: int,
	classification: String,
	effects: Array = [],
	priority: int = 0,
) -> MoveDefinition:
	var move := MoveDefinition.new()
	move.id = id
	move.display_name = String(id)
	move.type_id = &"normal"
	move.damage_class = damage_class
	move.power = power
	move.priority = priority
	move.accuracy = 100
	move.pp = 20
	move.classification = classification
	for effect in effects:
		if effect is BattleEffectSpec:
			move.effect_specs.append(effect as BattleEffectSpec)
	return move
