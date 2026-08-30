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

const EXACT_RUNTIME_MESSAGES := {
	"No active battle.": "No hay ningún combate activo.",
	"Battle state is incomplete.": "El estado del combate está incompleto.",
	"That move is not currently usable.": "Ese movimiento no se puede usar ahora mismo.",
	"Battle ownership is incomplete.": "No se ha podido determinar correctamente a quién pertenece cada Pokémon.",
	"Opponent has no supported usable action.": "El rival no tiene ninguna acción compatible disponible.",
	"Opponent has no supported usable response.": "El rival no tiene ninguna respuesta compatible disponible.",
	"Battle command returned no result.": "La orden de combate no devolvió ningún resultado.",
	"Switch command returned no result.": "La orden de cambio no devolvió ningún resultado.",
	"Capture is unavailable in this presentation.": "La captura no está disponible en esta pantalla.",
	"Capture command returned no result.": "La orden de captura no devolvió ningún resultado.",
	"Party full: captured Pokémon was routed to storage.": "El equipo está lleno: el Pokémon capturado se ha enviado al almacenamiento.",
	"The wild Pokémon broke free.": "¡El Pokémon salvaje se ha liberado!",
	"Capture command completed with an unknown result.": "La captura terminó con un resultado desconocido.",
	"Run command returned no result.": "La orden de huida no devolvió ningún resultado.",
	"Got away safely.": "¡Has escapado sin problemas!",
	"Couldn't get away.": "¡No has podido escapar!",
	"Run command completed with an unknown result.": "La huida terminó con un resultado desconocido.",
	"Victory. Progression has been reconciled.": "¡Victoria! El progreso se ha actualizado correctamente.",
	"Defeat. Persistent battle state has been reconciled.": "Derrota. El estado persistente del combate se ha actualizado correctamente.",
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


static func translate_runtime_message(text: String) -> String:
	if EXACT_RUNTIME_MESSAGES.has(text):
		return String(EXACT_RUNTIME_MESSAGES[text])
	if text.begins_with("A wild ") and text.ends_with(" appeared."):
		var middle := text.substr(7, text.length() - 17)
		return "¡Ha aparecido un %s salvaje!" % middle.replace("Lv.", "Nv.")
	if text.begins_with("Action rejected: "):
		return "Acción rechazada: %s" % text.trim_prefix("Action rejected: ")
	if text.begins_with("Switch rejected: "):
		return "Cambio rechazado: %s" % text.trim_prefix("Switch rejected: ")
	if text.begins_with("Capture rejected: "):
		return "Captura rechazada: %s" % text.trim_prefix("Capture rejected: ")
	if text.begins_with("Run rejected: "):
		return "Huida rechazada: %s" % text.trim_prefix("Run rejected: ")
	if text.begins_with("Captured the wild Pokémon with "):
		var raw_item := text.trim_prefix("Captured the wild Pokémon with ").trim_suffix(".")
		return "¡Has capturado al Pokémon salvaje con una %s!" % item_name(StringName(raw_item))
	if text.begins_with("Battle finished but settlement failed: "):
		return "El combate terminó, pero falló su cierre: %s" % text.trim_prefix("Battle finished but settlement failed: ")
	return text


static func _prettify(value: StringName) -> String:
	var words := String(value).replace("_", " ").split(" ", false)
	var out: Array[String] = []
	for word in words:
		out.append(word.capitalize())
	return " ".join(out)
