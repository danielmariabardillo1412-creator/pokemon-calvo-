class_name CreatureSpecies
extends Resource

# SpeciesDefinition: shared, immutable species data (canonical data layer).
# The live, mutable creature is CreatureInstance (see modules/creatures/domain/creature_instance.gd).
@export var id: StringName
@export var display_name: String
@export var primary_type_id: StringName = &"normal"
@export var secondary_type_id: StringName = &""
@export var type_ids: Array[StringName] = []
@export var base_hp: int = 1
@export var base_attack: int = 1
@export var base_defense: int = 1
@export var base_speed: int = 1
# Extended base stats (data only; Battle Core V2 will use them via StatBlock).
@export var base_special_attack: int = 1
@export var base_special_defense: int = 1
@export var ability_ids: Array[StringName] = []
@export var base_experience: int = 0
var learnset: Array = []      # Array[LearnSetEntry]
var evolutions: Array = []    # Array[EvolutionRecord]

func type_ids_resolved() -> Array[StringName]:
	if not type_ids.is_empty():
		return type_ids
	var resolved: Array[StringName] = []
	if primary_type_id != &"":
		resolved.append(primary_type_id)
	if secondary_type_id != &"":
		resolved.append(secondary_type_id)
	return resolved

func has_type(t: StringName) -> bool:
	return type_ids_resolved().has(t)

func stats_for_level(level: int) -> StatBlock:
	var safe_level := maxi(1, level)
	return StatBlock.new(
		base_hp + safe_level * 2,
		base_attack + safe_level,
		base_defense + safe_level,
		base_speed + safe_level,
		base_special_attack + safe_level,
		base_special_defense + safe_level,
	)

func to_dict() -> Dictionary:
	var ls: Array[Dictionary] = []
	for e in learnset:
		if e is LearnSetEntry:
			ls.append((e as LearnSetEntry).to_dict())
	var ev: Array[Dictionary] = []
	for e in evolutions:
		if e is EvolutionRecord:
			ev.append((e as EvolutionRecord).to_dict())
	return {
		"id": String(id),
		"display_name": display_name,
		"primary_type_id": String(primary_type_id),
		"secondary_type_id": String(secondary_type_id),
		"type_ids": _sn_to_str(type_ids),
		"base_hp": base_hp,
		"base_attack": base_attack,
		"base_defense": base_defense,
		"base_speed": base_speed,
		"base_special_attack": base_special_attack,
		"base_special_defense": base_special_defense,
		"ability_ids": _sn_to_str(ability_ids),
		"base_experience": base_experience,
		"learnset": ls,
		"evolutions": ev,
	}

static func from_dict(d: Dictionary) -> CreatureSpecies:
	var s := CreatureSpecies.new()
	s.id = StringName(d.get("id", ""))
	s.display_name = d.get("display_name", "")
	s.primary_type_id = StringName(d.get("primary_type_id", "normal"))
	s.secondary_type_id = StringName(d.get("secondary_type_id", ""))
	if d.has("type_ids"):
		s.type_ids = _str_to_sn(d.get("type_ids", []))
	elif d.has("types"):
		s.type_ids = _str_to_sn(d.get("types", []))
	s.base_hp = int(d.get("base_hp", 1))
	s.base_attack = int(d.get("base_attack", 1))
	s.base_defense = int(d.get("base_defense", 1))
	s.base_speed = int(d.get("base_speed", 1))
	s.base_special_attack = int(d.get("base_special_attack", 1))
	s.base_special_defense = int(d.get("base_special_defense", 1))
	s.ability_ids = _str_to_sn(d.get("ability_ids", []))
	s.base_experience = int(d.get("base_experience", 0))
	for le in d.get("learnset", []):
		s.learnset.append(LearnSetEntry.from_dict(le))
	for ev in d.get("evolutions", []):
		s.evolutions.append(EvolutionRecord.from_dict(ev))
	return s

static func _sn_to_str(a: Array[StringName]) -> Array[String]:
	var out: Array[String] = []
	for x in a:
		out.append(String(x))
	return out

static func _str_to_sn(a: Array) -> Array[StringName]:
	var out: Array[StringName] = []
	for x in a:
		out.append(StringName(x))
	return out
