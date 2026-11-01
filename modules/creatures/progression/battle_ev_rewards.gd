extends RefCounted

# Recompensas de EV en la progresión, sin RNG, motor paralelo ni cambio de XP.
# Perfil Gen VII-IX: objetos Power +8 por derrota, Macho Brace x2.
# Topes 252/510 desde Gen VI. No Pokérus ni Exp. Share.
const POWER_STAT := {
	"power_weight": "hp",
	"power_bracer": "attack",
	"power_belt": "defense",
	"power_lens": "special_attack",
	"power_band": "special_defense",
	"power_anklet": "speed",
}

# Las sesiones no guardan el objeto activo por cada KO. Solo usar la
# bonificación cuando coincide el objeto presente al inicio y al final.
# No prueba una transferencia intermedia que lo devolviese al propietario.
static func stable_training_item(creature: CreatureInstance, starting_items: Dictionary) -> String:
	if creature == null or creature.held_item_consumed:
		return ""
	var current := String(creature.held_item_id)
	if current != String(starting_items.get(String(creature.instance_id), "")):
		return ""
	if current == "macho_brace" or POWER_STAT.has(current):
		return current
	return ""

static func award(creature: CreatureInstance, defeats: Array, catalogs: DefinitionCatalog,
		ruleset: ProgressionRuleset, starting_items: Dictionary = {}) -> Dictionary:
	var gained: Dictionary = {}
	if creature == null or creature.is_knocked_out() or catalogs == null:
		return gained
	var owner: CreatureSpecies = catalogs.species(creature.species_id)
	if owner == null or creature.stats == null:
		return gained
	var total := 0
	for key: Variant in creature.evs:
		if not ProgressionRuleset.STAT_KEYS.has(key):
			return gained
	for key: String in ProgressionRuleset.STAT_KEYS:
		var value: Variant = creature.evs.get(key, 0)
		if not (value is int or value is float) or not is_finite(value):
			return gained
		if value != int(value) or int(value) < 0 or int(value) > ruleset.EV_PER_STAT_MAX:
			return gained
		total += int(value)
	if total > ruleset.EV_TOTAL_MAX:
		return gained
	var item := stable_training_item(creature, starting_items)
	# El cap se aplica tras cada enemigo, sin multiplicar recompensas previas.
	for defeated: Dictionary in defeats:
		if int(defeated.get("base_experience", 0)) <= 0:
			continue
		var foe: CreatureSpecies = catalogs.species(StringName(defeated.get("species_id", "")))
		if foe == null:
			continue
		var amounts: Dictionary = {}
		for key: String in ProgressionRuleset.STAT_KEYS:
			var base := maxi(0, int(foe.ev_yield.get(key, 0)))
			amounts[key] = base * 2 if item == "macho_brace" else base
		if POWER_STAT.has(item):
			var bonus_stat: String = POWER_STAT[item]
			amounts[bonus_stat] = int(amounts[bonus_stat]) + 8
		for key: String in ProgressionRuleset.STAT_KEYS:
			var room := mini(ruleset.EV_PER_STAT_MAX - int(creature.evs.get(key, 0)), ruleset.EV_TOTAL_MAX - total)
			var delta := mini(maxi(0, int(amounts[key])), maxi(0, room))
			if delta <= 0:
				continue
			creature.evs[key] = int(creature.evs.get(key, 0)) + delta
			gained[key] = int(gained.get(key, 0)) + delta
			total += delta
	if not gained.is_empty():
		# Igual que los consumibles EV del campo: conservar el daño al
		# variar los PS máximos; nunca reanimar un Pokémon debilitado.
		var old_max := creature.stats.max_hp
		var old_hp := creature.current_hp
		creature.recalculate_stats(owner, ruleset)
		creature.current_hp = clampi(old_hp + creature.stats.max_hp - old_max, 1, creature.stats.max_hp)
	return gained
