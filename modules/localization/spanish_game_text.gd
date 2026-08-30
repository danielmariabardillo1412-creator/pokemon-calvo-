class_name SpanishGameText
extends RefCounted

# Spanish is the product default. Internal IDs deliberately remain stable English keys.
const LOCALE_ID := &"es"

const CORE_MOVE_NAMES := {
	"tackle": "Placaje",
	"growl": "Gruñido",
	"scratch": "Arañazo",
	"ember": "Ascuas",
	"vine_whip": "Látigo Cepa",
	"poison_powder": "Polvo Veneno",
	"sleep_powder": "Somnífero",
	"take_down": "Derribo",
	"razor_leaf": "Hoja Afilada",
	"sweet_scent": "Dulce Aroma",
	"growth": "Desarrollo",
	"seed_bomb": "Bomba Germen",
	"thunder_shock": "Impactrueno",
	"tail_whip": "Látigo",
	"quick_attack": "Ataque Rápido",
	"electro_ball": "Bola Voltio",
	"thunder_wave": "Onda Trueno",
	"feint": "Amago",
	"double_team": "Doble Equipo",
	"spark": "Chispa",
	"nuzzle": "Moflete Estático",
	"slam": "Atizar",
	"thunderbolt": "Rayo",
	"agility": "Agilidad",
	"wild_charge": "Voltio Cruel",
	"light_screen": "Pantalla Luz",
	"thunder": "Trueno",
}

const ITEM_NAMES := {
	"poke_ball": "Poké Ball",
	"great_ball": "Super Ball",
	"ultra_ball": "Ultra Ball",
	"master_ball": "Master Ball",
	"potion": "Poción",
	"super_potion": "Superpoción",
	"hyper_potion": "Hiperpoción",
	"max_potion": "Poción Máxima",
	"full_restore": "Restaurar Todo",
	"sitrus_berry": "Baya Zidra",
	"leftovers": "Restos",
}

const STATUS_NAMES := {
	"burn": "quemado",
	"poison": "envenenado",
	"badly_poisoned": "gravemente envenenado",
	"paralysis": "paralizado",
	"sleep": "dormido",
	"freeze": "congelado",
	"confusion": "confuso",
	"flinch": "amedrentado",
}


static func type_name(type_id: StringName) -> String:
	return String(PokemonTypeChart.SPANISH_NAMES.get(String(type_id), _prettify(type_id)))


static func move_name(move_id: StringName, catalog: DefinitionCatalog = null) -> String:
	var key := String(move_id)
	if CORE_MOVE_NAMES.has(key):
		return String(CORE_MOVE_NAMES[key])
	if catalog != null:
		var definition := catalog.move(move_id)
		if definition != null and not definition.display_name.is_empty():
			return definition.display_name
	return _prettify(move_id)


static func species_name(species_id: StringName, catalog: DefinitionCatalog = null) -> String:
	if catalog != null:
		var definition := catalog.species(species_id)
		if definition != null and not definition.display_name.is_empty():
			return definition.display_name
	return _prettify(species_id)


static func item_name(item_id: StringName, catalog: DefinitionCatalog = null) -> String:
	var key := String(item_id)
	if ITEM_NAMES.has(key):
		return String(ITEM_NAMES[key])
	if catalog != null:
		var definition := catalog.item(item_id)
		if definition != null and not definition.display_name.is_empty():
			return definition.display_name
	return _prettify(item_id)


static func status_name(status_id: StringName) -> String:
	return String(STATUS_NAMES.get(String(status_id), _prettify(status_id)))


static func effectiveness_text(multiplier: float) -> String:
	if multiplier <= 0.0:
		return "No afecta al objetivo."
	if multiplier >= 2.0:
		return "¡Es supereficaz!"
	if multiplier < 1.0:
		return "No es muy eficaz..."
	return ""


static func completion_reason(reason: StringName) -> String:
	match reason:
		&"captured":
			return "captura"
		&"escaped":
			return "huida"
		&"victory":
			return "victoria"
		&"defeat":
			return "derrota"
		_:
			return _prettify(reason).to_lower()


static func _prettify(value: StringName) -> String:
	var words := String(value).replace("_", " ").split(" ", false)
	var out: Array[String] = []
	for word in words:
		out.append(word.capitalize())
	return " ".join(out)
