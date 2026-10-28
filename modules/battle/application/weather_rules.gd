extends RefCounted

# Explicit weather pilot, independent of frozen move classifications.
const MOVES := {&"rain_dance": &"rain", &"hail": &"hail", &"sandstorm": &"sandstorm",
	&"snowscape": &"snow", &"chilly_reception": &"snow"}
const TYPES := {&"rain_dance": &"water", &"hail": &"ice", &"sandstorm": &"rock",
	&"snowscape": &"ice", &"chilly_reception": &"ice"}
const ROCKS := {&"rain": &"damp_rock", &"hail": &"icy_rock", &"snow": &"icy_rock", &"sandstorm": &"smooth_rock"}


static func supports(move: MoveDefinition) -> bool:
	return move != null and MOVES.has(move.id) and move.power == 0 and move.priority == 0 \
		and move.accuracy == -1 and move.damage_class == "status" and move.target == "entire-field" \
		and move.type_id == TYPES[move.id] and move.effect_specs.is_empty()


static func effective(state: BattleState) -> StringName:
	if not state.weather_rules_enabled or state.weather.is_empty():
		return &""
	for id: StringName in state.active_ids:
		var c := state.creature(id)
		if c != null and not c.is_knocked_out() and c.ability_id in [&"cloud_nine", &"air_lock"]:
			return &"" # Suppressed, not removed; duration still advances.
	return StringName(state.weather.get("id", ""))


static func start(state: BattleState, actor: CreatureInstance, move: MoveDefinition,
	events: Array[BattleEvent]) -> bool:
	var weather_id: StringName = MOVES[move.id]
	if StringName(state.weather.get("id", "")) == weather_id:
		events.append(BattleEvent.new(BattleEvent.WEATHER_FAILED, state.turn, actor.instance_id,
			&"", move.id, 0, {"reason": "already_active", "weather_id": String(weather_id)}))
		return false
	var duration := 8 if actor.held_item_id == ROCKS[weather_id] and not actor.held_item_consumed else 5
	var previous := String(state.weather.get("id", ""))
	state.weather = {"id": String(weather_id), "turns_remaining": duration,
		"source_id": String(actor.instance_id), "source_move": String(move.id), "set_turn": state.turn}
	events.append(BattleEvent.new(BattleEvent.WEATHER_CHANGED, state.turn, actor.instance_id,
		&"", move.id, duration, {"weather": presentation(state), "previous": previous}))
	return true


static func presentation(state: BattleState) -> Dictionary:
	var result := state.weather.duplicate(true)
	if not result.is_empty(): result["suppressed"] = effective(state) == &""
	return result


static func label(data: Dictionary) -> String:
	var name := String({"rain": "Lluvia", "sun": "Sol intenso", "hail": "Granizo", "snow": "Nieve", "sandstorm": "Tormenta de arena"}.get(String(data.get("id", "")), ""))
	if name.is_empty(): return ""
	return "%s · %d turnos%s" % [name, int(data.get("turns_remaining", 0)), " (efecto anulado)" if data.get("suppressed", false) else ""]


static func damage_multiplier(state: BattleState, move: MoveDefinition) -> int:
	if effective(state) == &"rain":
		if move.type_id == &"water": return 15000
		if move.type_id == &"fire": return 5000
	return 10000


static func defense_multiplier(state: BattleState, defender: CreatureInstance,
	move: MoveDefinition, catalog: DefinitionCatalog) -> int:
	var species := catalog.species(defender.species_id)
	if species == null: return 10000
	var id := effective(state)
	if id == &"sandstorm" and move.damage_class == "special" and species.has_type(&"rock"):
		return 15000
	if id == &"snow" and move.damage_class == "physical" and species.has_type(&"ice"):
		return 15000
	return 10000


static func end_turn(state: BattleState, catalog: DefinitionCatalog, events: Array[BattleEvent]) -> void:
	if not state.weather_rules_enabled or state.weather.is_empty(): return
	state.weather.turns_remaining = int(state.weather.turns_remaining) - 1
	if state.weather.turns_remaining <= 0:
		var ended := state.weather.duplicate(true)
		state.weather.clear()
		events.append(BattleEvent.new(BattleEvent.WEATHER_ENDED, state.turn, &"", &"", &"", 0, {"weather": ended}))
		return # Expiration precedes the residual callback, as in the reference simulator.
	var id := effective(state)
	events.append(BattleEvent.new(BattleEvent.WEATHER_UPKEEP, state.turn, &"", &"", &"", 0,
		{"weather": presentation(state), "suppressed": id == &""}))
	if id == &"": return
	for instance_id: StringName in state.active_ids.duplicate():
		var c := state.creature(instance_id)
		if c == null or c.is_knocked_out(): continue
		var species := catalog.species(c.species_id)
		var immune := c.ability_id in [&"magic_guard", &"overcoat"] \
			or (c.held_item_id == &"safety_goggles" and not c.held_item_consumed)
		if id == &"sandstorm":
			immune = immune or c.ability_id in [&"sand_veil", &"sand_rush", &"sand_force"] \
				or species.has_type(&"rock") or species.has_type(&"ground") or species.has_type(&"steel")
		elif id == &"hail":
			immune = immune or species.has_type(&"ice") or c.ability_id in [&"ice_body", &"snow_cloak", &"slush_rush"]
		else:
			immune = true # Neither rain nor snow has passive chip damage.
		if not immune:
			var damage := c.apply_damage(maxi(1, c.stats.max_hp / 16))
			events.append(BattleEvent.new(BattleEvent.STATUS_DAMAGE, state.turn, c.instance_id,
				c.instance_id, &"", damage, {"cause": "weather", "weather_id": String(id)}))
		var healing := (id == &"rain" and c.ability_id == &"rain_dish") \
			or (id in [&"hail", &"snow"] and c.ability_id == &"ice_body")
		if healing and not c.is_knocked_out():
			var hp := c.recover_hp(maxi(1, c.stats.max_hp / 16))
			if hp > 0:
				events.append(BattleEvent.new(BattleEvent.HP_RECOVERED, state.turn, c.instance_id,
					c.instance_id, &"", hp, {"cause": "weather_ability", "ability_id": String(c.ability_id)}))
