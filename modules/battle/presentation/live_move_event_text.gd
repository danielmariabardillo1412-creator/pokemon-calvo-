extends RefCounted

static func describe(event: BattleEvent, actor: String, target: String, catalog: DefinitionCatalog) -> String:
	if event.metadata.has("binding_op"):
		return "%s quedó atrapado por %s." % [target, SpanishGameText.move_name(event.move_id, catalog)] if event.metadata.binding_op == "start" else "%s se liberó del atrapamiento." % target
	if event.kind == BattleEvent.STATUS_DAMAGE and event.metadata.get("binding", false):
		return "%s perdió %d PS por el atrapamiento." % [target, event.amount]
	match event.kind:
		BattleEvent.HP_RECOVERED: return "%s recuperó %d PS." % [target, event.amount]
		BattleEvent.STATUS_CURED: return "%s se ha curado de su problema de estado." % target
		BattleEvent.STAT_STAGES_REASSIGNED:
			return "%s: %s actualizó los modificadores de %s." % [SpanishGameText.move_name(event.move_id, catalog), actor, target]
		BattleEvent.MOVE_EFFECT_FAILED: return "%s no tuvo efecto." % SpanishGameText.move_name(event.move_id, catalog)
		BattleEvent.SWITCH_REQUESTED: return "Elige una reserva para continuar el mismo turno."
		BattleEvent.SWITCH_EFFECT_FAILED: return "No se pudo completar el relevo o la expulsión."
		BattleEvent.MOVE_EFFECT_RESOLVED: return "Se completó el efecto de %s." % SpanishGameText.move_name(event.move_id, catalog)
		BattleEvent.MOVE_REFLECTED: return "%s reflejó el movimiento." % actor
		BattleEvent.HP_COST: return "%s cedió %d PS." % [actor, event.amount]
		BattleEvent.SUBSTITUTE_CREATED: return "%s creó un sustituto." % target
		BattleEvent.SUBSTITUTE_DAMAGED: return "El sustituto recibió el golpe (%d PS)." % event.amount
		BattleEvent.SUBSTITUTE_BROKEN: return "El sustituto se rompió."
		BattleEvent.SUBSTITUTE_TRANSFERRED: return "%s recibió el sustituto." % target
		BattleEvent.SUBSTITUTE_BLOCKED: return "El sustituto bloqueó el efecto."
		BattleEvent.SUBSTITUTE_FAILED: return "No se pudo crear el sustituto."
		BattleEvent.TRANSFORMED: return "%s se transformó en %s." % [actor, SpanishGameText.species_name(StringName(event.metadata.get("species_id", "")), catalog)]
		BattleEvent.TRANSFORM_REVERTED: return "%s recuperó su forma original." % actor
		BattleEvent.TRANSFORM_FAILED: return "La transformación falló."
		BattleEvent.WEATHER_CHANGED, BattleEvent.WEATHER_UPKEEP: return "Clima: " + preload("res://modules/battle/application/weather_rules.gd").label(event.metadata.get("weather", {}))
		BattleEvent.WEATHER_ENDED: return "El clima terminó."
		BattleEvent.WEATHER_FAILED: return "Ese clima ya está activo."
		BattleEvent.ABILITY_TRIGGERED: return "%s activó su habilidad." % actor
		BattleEvent.ITEM_TRIGGERED: return "%s activó su objeto." % actor
	return ""
