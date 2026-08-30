class_name PokemonTypeChart
extends RefCounted

# Canonical modern (Gen VI+) Pokémon battle type chart.
# Stable internal IDs stay in English because they are persistence/data keys.
# Player-facing names are Spanish.
const MODEL_ID := "pokemon_type_chart_modern_v1"

const STANDARD_TYPE_IDS: Array[StringName] = [
	&"normal", &"fire", &"water", &"electric", &"grass", &"ice",
	&"fighting", &"poison", &"ground", &"flying", &"psychic", &"bug",
	&"rock", &"ghost", &"dragon", &"dark", &"steel", &"fairy",
]

const SPANISH_NAMES := {
	"normal": "Normal",
	"fire": "Fuego",
	"water": "Agua",
	"electric": "Eléctrico",
	"grass": "Planta",
	"ice": "Hielo",
	"fighting": "Lucha",
	"poison": "Veneno",
	"ground": "Tierra",
	"flying": "Volador",
	"psychic": "Psíquico",
	"bug": "Bicho",
	"rock": "Roca",
	"ghost": "Fantasma",
	"dragon": "Dragón",
	"dark": "Siniestro",
	"steel": "Acero",
	"fairy": "Hada",
}

# Only non-neutral relations are stored; unspecified pairs are exactly 1x.
const EFFECTIVENESS := {
	"normal": {"rock": 0.5, "ghost": 0.0, "steel": 0.5},
	"fire": {"fire": 0.5, "water": 0.5, "grass": 2.0, "ice": 2.0, "bug": 2.0, "rock": 0.5, "dragon": 0.5, "steel": 2.0},
	"water": {"fire": 2.0, "water": 0.5, "grass": 0.5, "ground": 2.0, "rock": 2.0, "dragon": 0.5},
	"electric": {"water": 2.0, "electric": 0.5, "grass": 0.5, "ground": 0.0, "flying": 2.0, "dragon": 0.5},
	"grass": {"fire": 0.5, "water": 2.0, "grass": 0.5, "poison": 0.5, "ground": 2.0, "flying": 0.5, "bug": 0.5, "rock": 2.0, "dragon": 0.5, "steel": 0.5},
	"ice": {"fire": 0.5, "water": 0.5, "grass": 2.0, "ice": 0.5, "ground": 2.0, "flying": 2.0, "dragon": 2.0, "steel": 0.5},
	"fighting": {"normal": 2.0, "ice": 2.0, "poison": 0.5, "flying": 0.5, "psychic": 0.5, "bug": 0.5, "rock": 2.0, "ghost": 0.0, "dark": 2.0, "steel": 2.0, "fairy": 0.5},
	"poison": {"grass": 2.0, "poison": 0.5, "ground": 0.5, "rock": 0.5, "ghost": 0.5, "steel": 0.0, "fairy": 2.0},
	"ground": {"fire": 2.0, "electric": 2.0, "grass": 0.5, "poison": 2.0, "flying": 0.0, "bug": 0.5, "rock": 2.0, "steel": 2.0},
	"flying": {"electric": 0.5, "grass": 2.0, "fighting": 2.0, "bug": 2.0, "rock": 0.5, "steel": 0.5},
	"psychic": {"fighting": 2.0, "poison": 2.0, "psychic": 0.5, "dark": 0.0, "steel": 0.5},
	"bug": {"fire": 0.5, "grass": 2.0, "fighting": 0.5, "poison": 0.5, "flying": 0.5, "psychic": 2.0, "ghost": 0.5, "dark": 2.0, "steel": 0.5, "fairy": 0.5},
	"rock": {"fire": 2.0, "ice": 2.0, "fighting": 0.5, "ground": 0.5, "flying": 2.0, "bug": 2.0, "steel": 0.5},
	"ghost": {"normal": 0.0, "psychic": 2.0, "ghost": 2.0, "dark": 0.5},
	"dragon": {"dragon": 2.0, "steel": 0.5, "fairy": 0.0},
	"dark": {"fighting": 0.5, "psychic": 2.0, "ghost": 2.0, "dark": 0.5, "fairy": 0.5},
	"steel": {"fire": 0.5, "water": 0.5, "electric": 0.5, "ice": 2.0, "rock": 2.0, "steel": 0.5, "fairy": 2.0},
	"fairy": {"fire": 0.5, "fighting": 2.0, "poison": 0.5, "dragon": 2.0, "dark": 2.0, "steel": 0.5},
}


static func definition(type_id: StringName) -> TypeDefinition:
	if not STANDARD_TYPE_IDS.has(type_id):
		return null
	var out := TypeDefinition.new()
	out.id = type_id
	out.display_name = String(SPANISH_NAMES[String(type_id)])
	out.effectiveness = (EFFECTIVENESS.get(String(type_id), {}) as Dictionary).duplicate(true)
	return out


static func apply_to_catalog(catalog: TypeCatalog) -> void:
	if catalog == null:
		return
	for type_id in STANDARD_TYPE_IDS:
		catalog.add(definition(type_id))


static func validate_catalog(catalog: TypeCatalog) -> Dictionary:
	var missing: Array[String] = []
	var mismatches: Array[String] = []
	if catalog == null:
		return {"valid": false, "missing": ["catalog"], "mismatches": [], "model": MODEL_ID}
	for attack_id in STANDARD_TYPE_IDS:
		var attack := catalog.get_by_id(attack_id)
		if attack == null:
			missing.append(String(attack_id))
			continue
		for defend_id in STANDARD_TYPE_IDS:
			var expected := float((EFFECTIVENESS.get(String(attack_id), {}) as Dictionary).get(String(defend_id), 1.0))
			var actual := attack.multiplier_against(defend_id)
			if not is_equal_approx(actual, expected):
				mismatches.append("%s>%s:%s!=%s" % [attack_id, defend_id, actual, expected])
	return {
		"valid": missing.is_empty() and mismatches.is_empty(),
		"missing": missing,
		"mismatches": mismatches,
		"model": MODEL_ID,
	}
