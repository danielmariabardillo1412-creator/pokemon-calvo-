class_name TrainerRoleLoadoutGenerator
extends RefCounted

const MODEL_ID := "trainer_role_loadout_generator_v1"

var _catalog: DefinitionCatalog
var _registry := BattleEffectRegistry.new()


func _init(catalog: DefinitionCatalog) -> void:
	_catalog = catalog


func generate(
	species_id: StringName,
	level: int,
	role_id: StringName,
	quality_id: StringName,
) -> TrainerPokemonLoadout:
	if _catalog == null:
		return null
	var species := _catalog.species(species_id)
	if species == null:
		return null
	if not TrainerPokemonLoadout.ROLES.has(role_id):
		return null
	if not TrainerPokemonLoadout.QUALITIES.has(quality_id):
		return null

	var loadout := TrainerPokemonLoadout.new()
	loadout.species_id = species_id
	loadout.level = clampi(level, ProgressionRuleset.MIN_LEVEL, ProgressionRuleset.MAX_LEVEL)
	loadout.role_id = role_id
	loadout.quality_id = quality_id
	loadout.source_id = &"generated_role_v1"
	loadout.ivs = _ivs_for_quality(quality_id)
	loadout.evs = _evs_for_role(role_id, quality_id)
	loadout.move_ids = _moves_for_role(species, loadout.level, role_id)
	var damage_profile := _damage_profile(loadout.move_ids)
	loadout.nature_id = _nature_for_role(role_id, damage_profile)
	loadout.ability_id = _supported_ability(species)
	loadout.held_item_id = _held_item_for_role(role_id)
	return loadout


func _ivs_for_quality(quality_id: StringName) -> Dictionary:
	var value := 15
	if quality_id == TrainerPokemonLoadout.QUALITY_TRAINED:
		value = 25
	elif quality_id == TrainerPokemonLoadout.QUALITY_EXPERT:
		value = 31
	var out: Dictionary = {}
	for key in ProgressionRuleset.STAT_KEYS:
		out[key] = value
	return out


func _evs_for_role(role_id: StringName, quality_id: StringName) -> Dictionary:
	var out: Dictionary = {}
	for key in ProgressionRuleset.STAT_KEYS:
		out[key] = 0
	if quality_id == TrainerPokemonLoadout.QUALITY_BASIC:
		return out
	var primary := 128 if quality_id == TrainerPokemonLoadout.QUALITY_TRAINED else 252
	var secondary := 128 if quality_id == TrainerPokemonLoadout.QUALITY_TRAINED else 252
	var tail := 4
	match role_id:
		TrainerPokemonLoadout.ROLE_PHYSICAL_ATTACKER:
			out["attack"] = primary
			out["speed"] = secondary
			out["hp"] = tail
		TrainerPokemonLoadout.ROLE_SPECIAL_ATTACKER:
			out["special_attack"] = primary
			out["speed"] = secondary
			out["hp"] = tail
		TrainerPokemonLoadout.ROLE_FAST_ATTACKER:
			out["speed"] = primary
			out["attack"] = secondary
			out["hp"] = tail
		TrainerPokemonLoadout.ROLE_BULKY_PHYSICAL:
			out["hp"] = primary
			out["defense"] = secondary
			out["special_defense"] = tail
		TrainerPokemonLoadout.ROLE_BULKY_SPECIAL:
			out["hp"] = primary
			out["special_defense"] = secondary
			out["defense"] = tail
		TrainerPokemonLoadout.ROLE_SUPPORT:
			if quality_id == TrainerPokemonLoadout.QUALITY_TRAINED:
				out["hp"] = 128
				out["defense"] = 64
				out["special_defense"] = 64
			else:
				out["hp"] = 252
				out["defense"] = 128
				out["special_defense"] = 128
		_:
			var even := 42 if quality_id == TrainerPokemonLoadout.QUALITY_TRAINED else 84
			for key in ProgressionRuleset.STAT_KEYS:
				out[key] = even
	return out


func _nature_for_role(role_id: StringName, damage_profile: Dictionary) -> StringName:
	match role_id:
		TrainerPokemonLoadout.ROLE_PHYSICAL_ATTACKER:
			return &"adamant"
		TrainerPokemonLoadout.ROLE_SPECIAL_ATTACKER:
			return &"modest"
		TrainerPokemonLoadout.ROLE_FAST_ATTACKER:
			return &"timid" if int(damage_profile.get("special", 0)) > int(damage_profile.get("physical", 0)) else &"jolly"
		TrainerPokemonLoadout.ROLE_BULKY_PHYSICAL:
			return &"impish"
		TrainerPokemonLoadout.ROLE_BULKY_SPECIAL:
			return &"careful"
		TrainerPokemonLoadout.ROLE_SUPPORT:
			return &"bold"
		_:
			return ProgressionRuleset.NEUTRAL_NATURE


func _supported_ability(species: CreatureSpecies) -> StringName:
	for ability_id in species.ability_ids:
		if _catalog.ability(ability_id) != null and _registry.runtime_supported_ability_ids().has(ability_id):
			return ability_id
	return &""


func _held_item_for_role(role_id: StringName) -> StringName:
	var preferred := &"sitrus_berry"
	if role_id in [
		TrainerPokemonLoadout.ROLE_BULKY_PHYSICAL,
		TrainerPokemonLoadout.ROLE_BULKY_SPECIAL,
		TrainerPokemonLoadout.ROLE_SUPPORT,
	]:
		preferred = &"leftovers"
	if _catalog.item(preferred) != null and _registry.runtime_supported_item_ids().has(preferred):
		return preferred
	return &""


func _moves_for_role(
	species: CreatureSpecies,
	level: int,
	role_id: StringName,
) -> Array[StringName]:
	var candidates: Array[Dictionary] = []
	var seen: Dictionary = {}
	for raw_entry in species.learnset:
		if not (raw_entry is LearnSetEntry):
			continue
		var entry := raw_entry as LearnSetEntry
		if entry.move_id == &"" or seen.has(entry.move_id):
			continue
		var compatible := false
		if entry.method == LearnsetSystem.LEVEL_UP:
			compatible = entry.level <= level
		elif TrainerPublicCoverageBeliefInference.is_supported_coverage_method(entry.method):
			compatible = true
		if not compatible:
			continue
		var move := _catalog.move(entry.move_id)
		if move == null:
			continue
		seen[entry.move_id] = true
		candidates.append({
			"move_id": entry.move_id,
			"score": _move_role_score(move, species, role_id),
		})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary):
		var ascore := int(a.get("score", 0))
		var bscore := int(b.get("score", 0))
		if ascore == bscore:
			return String(a.get("move_id", "")) < String(b.get("move_id", ""))
		return ascore > bscore
	)
	var out: Array[StringName] = []
	for candidate in candidates:
		out.append(StringName(candidate.get("move_id", "")))
		if out.size() >= ProgressionRuleset.MOVE_SLOTS_MAX:
			break
	return out


func _move_role_score(
	move: MoveDefinition,
	species: CreatureSpecies,
	role_id: StringName,
) -> int:
	var damage := maxi(0, move.power) * 100
	if species.has_type(move.type_id):
		damage = damage * 3 / 2
	var utility := 0
	if move.power <= 0:
		utility += 3000
	if not move.effect_specs.is_empty():
		utility += 2500 + move.effect_specs.size() * 400
	match role_id:
		TrainerPokemonLoadout.ROLE_PHYSICAL_ATTACKER:
			return damage * (3 if move.damage_class == "physical" else 1) + utility / 3
		TrainerPokemonLoadout.ROLE_SPECIAL_ATTACKER:
			return damage * (3 if move.damage_class == "special" else 1) + utility / 3
		TrainerPokemonLoadout.ROLE_FAST_ATTACKER:
			return damage * 2 + move.priority * 2000 + utility / 4
		TrainerPokemonLoadout.ROLE_SUPPORT:
			return utility * 4 + damage / 2
		TrainerPokemonLoadout.ROLE_BULKY_PHYSICAL, TrainerPokemonLoadout.ROLE_BULKY_SPECIAL:
			return utility * 2 + damage
		_:
			return damage + utility


func _damage_profile(move_ids: Array[StringName]) -> Dictionary:
	var physical := 0
	var special := 0
	for move_id in move_ids:
		var move := _catalog.move(move_id)
		if move == null:
			continue
		if move.damage_class == "physical":
			physical += maxi(0, move.power)
		elif move.damage_class == "special":
			special += maxi(0, move.power)
	return {"physical": physical, "special": special}
