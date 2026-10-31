extends SceneTree

# Development-only observer. Resolves through the actual authoritative server.
const Live = preload("res://modules/battle/application/live_move_profile.gd")
const Stage = preload("res://modules/battle/application/stat_stage_move_rules.gd")
const Fixed = preload("res://modules/battle/application/fixed_damage_move_rules.gd")
const VariablePower = preload("res://modules/battle/application/variable_power_move_rules.gd")
const Binding = preload("res://modules/battle/application/binding_move_rules.gd")
const Healing = preload("res://modules/battle/application/healing_move_rules.gd")
const Substitute = preload("res://modules/battle/application/substitute_rules.gd")
var catalog: DefinitionCatalog


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 4 or args[0] != "--input" or args[2] != "--output":
		push_error("Usage: --input input.json --output output.json")
		quit(2)
		return
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(args[1]))
	if not manifest is Dictionary or manifest.get("schema_version") != 1 or not manifest.get("cases") is Array or manifest.cases.is_empty():
		push_error("Invalid manifest")
		quit(2)
		return
	catalog = GameData.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))).to_definition_catalog()
	var started := Time.get_ticks_msec()
	var results := []
	for item: Dictionary in manifest.cases:
		results.append(_observe(item))
	var file := FileAccess.open(args[3], FileAccess.WRITE)
	if file == null:
		push_error("Cannot write adapter output")
		quit(2)
		return
	file.store_string(JSON.stringify({"schema_version": 1, "adapter": "godot", "version": Engine.get_version_info().string,
		"elapsed_ms": Time.get_ticks_msec() - started, "results": results}, "\t"))
	file.close()
	print("BATTLE_REFERENCE_GODOT cases=", results.size())
	quit(0)


func _observe(c: Dictionary) -> Dictionary:
	var id := StringName(c.move_id)
	var move := catalog.move(id)
	var supported: bool = (c.family == "stat_stages" and Stage.supports(move)) or (c.family == "fixed_damage" and Fixed.supports(move)) or (c.family == "variable_power" and VariablePower.supports(move))
	supported = supported or (c.family == "binding" and Binding.supports(move))
	supported = supported or (c.family == "healing" and Healing.supports(move))
	if not supported or not Live.reason(move).is_empty():
		return {"id": c.id, "status": "unsupported", "reason": "Family/move is outside the current live contract"}
	var definition := move.to_dict()
	for key: String in c.contract:
		if definition.get(key) != c.contract[key]:
			return {"id": c.id, "status": "unsupported", "reason": "Canonical move contract differs: " + key}
	var actor := _creature(&"actor", c.actor, id, 200)
	var target := _creature(&"target", c.target, &"tackle", 100)
	if int(c.get("lifecycle_turns", 1)) == 8: actor.add_move(&"haze", catalog)
	var bench_actor := _creature(&"bench_actor", {"species_id": "mew", "ability_id": "", "stages": c.bench_stages.actor, "substitute_hp": 0}, &"tackle", 100)
	var bench_target := _creature(&"bench_target", {"species_id": "mew", "ability_id": "", "stages": c.bench_stages.target, "substitute_hp": 0}, &"tackle", 100)
	if c.family == "healing":
		for pair: Array in [[bench_actor, c.healing_bench.actor], [bench_target, c.healing_bench.target]]:
			var creature: CreatureInstance = pair[0]
			var spec: Dictionary = pair[1]
			creature.stats.max_hp = 101; creature.current_hp = int(spec.hp)
			creature.status_state.persistent_id = StringName(spec.status_id)
			creature.ability_id = StringName(spec.ability_id)
	var own: Array[CreatureInstance] = [actor, bench_actor]
	var other: Array[CreatureInstance] = [target, bench_target]
	var side := StringName(c.actor_side)
	var passive := &"side_b" if side == &"side_a" else &"side_a"
	var state := BattleState.create_with_parties(&"reference", own if side == &"side_a" else other,
		other if side == &"side_a" else own, int(c.seed))
	Live.apply(state)
	var server := AuthoritativeBattleServer.new(state, catalog)
	if c.actor.has("pp"): actor.move_slot(id).current_pp = int(c.actor.pp)
	var before: int = actor.move_slot(id).current_pp
	var events := server.submit_reaction_turn(BattleAction.new(1, actor.instance_id, id, target.instance_id, BattleAction.MOVE, side), passive)
	var used := false
	var power := 0
	var contact := false
	var hits := 0
	var residual_damage := 0
	var protocol := []
	for event: BattleEvent in events:
		protocol.append(event.to_dict())
		if event.kind == BattleEvent.STATUS_DAMAGE and event.target_id == target.instance_id and event.metadata.get("binding", false): residual_damage += event.amount
		if event.kind == BattleEvent.ACTION_REJECTED:
			return {"id": c.id, "status": "error", "reason": "Authoritative server rejected fixture: " + JSON.stringify(event.to_dict())}
		if event.kind == BattleEvent.ACTION_USED and event.actor_id == actor.instance_id and event.move_id == id:
			used = true
		if event.actor_id == actor.instance_id and event.move_id == id and event.kind in [BattleEvent.DAMAGE_APPLIED, BattleEvent.SUBSTITUTE_DAMAGED]:
			var damage: Dictionary = event.metadata.get("damage", {}) if event.kind == BattleEvent.SUBSTITUTE_DAMAGED else event.metadata
			if damage.has("resolved_power"):
				hits += 1
				power = int(damage.resolved_power)
				contact = bool(damage.resolved_contact)
	if c.family == "variable_power" and hits > 1:
		return {"id": c.id, "status": "error", "reason": "Unexpected repeated power observations"}
	var a := _row(actor)
	a.pp_spent = before - actor.move_slot(id).current_pp
	a.move_used = used
	var binding_data := Binding.record(target)
	var bound := not binding_data.is_empty()
	var binding := {"present": bound, "blocked": Binding.switch_blocked(state, target, catalog), "residual_damage": residual_damage,
		"move_id": binding_data.get("move_id", ""), "clock_valid": not bound or (int(binding_data.get("duration", 0)) == 7 if actor.held_item_id == &"grip_claw" else int(binding_data.get("duration", 0)) in [4, 5])}
	var lifecycle := []
	if c.family == "binding" and int(c.get("lifecycle_turns", 1)) == 8:
		lifecycle.append(_binding_snapshot(state, target, residual_damage))
		for turn in range(2, 9):
			var continued := server.submit_reaction_turn(BattleAction.new(turn, actor.instance_id, &"haze", target.instance_id, BattleAction.MOVE, side), passive)
			var damage := 0
			for event: BattleEvent in continued:
				protocol.append(event.to_dict())
				if event.kind == BattleEvent.STATUS_DAMAGE and event.target_id == target.instance_id and event.metadata.get("binding", false): damage += event.amount
			lifecycle.append(_binding_snapshot(state, target, damage))
	return {"id": c.id, "status": "ok", "actor": a, "target": _row(target), "power": power, "contact": contact, "hit_received": hits > 0,
		"binding": binding, "lifecycle": lifecycle,
		"healing_benches": {"actor": {"hp": bench_actor.current_hp, "status_id": String(bench_actor.status_state.persistent_id)}, "target": {"hp": bench_target.current_hp, "status_id": String(bench_target.status_state.persistent_id)}},
		"benches": {"actor": bench_actor.stat_stages.to_dict(), "target": bench_target.stat_stages.to_dict()}, "protocol": protocol}


func _creature(id: StringName, spec: Dictionary, move: StringName, speed: int) -> CreatureInstance:
	var creature := CreatureInstance.new(id, StringName(spec.species_id), int(spec.get("level", 50)), StatBlock.new(int(spec.get("max_hp", 20000)), 100, 100, int(spec.get("speed", speed)), 100, 100), [move])
	creature.current_hp = int(spec.get("hp", spec.get("max_hp", 20000)))
	creature.held_item_id = StringName(spec.get("item_id", ""))
	creature.friendship = int(spec.get("friendship", 127))
	creature.status_state.persistent_id = StringName(spec.get("status_id", ""))
	creature.initialize_move_pp(catalog)
	creature.ability_id = StringName(spec.ability_id)
	creature.stat_stages = StatStages.from_dict(spec.stages)
	if int(spec.substitute_hp) > 0:
		creature.status_state.add_volatile(&"substitute", {"hp": int(spec.substitute_hp), "max_hp": int(spec.substitute_hp)})
	return creature


func _row(creature: CreatureInstance) -> Dictionary:
	return {"stages": creature.stat_stages.to_dict(), "substitute_present": creature.status_state.has_volatile(&"substitute"), "status_id": String(creature.status_state.persistent_id),
		"hp": creature.current_hp, "substitute_hp": Substitute.hp(creature), "knocked_out": creature.is_knocked_out()}


func _binding_snapshot(state: BattleState, target: CreatureInstance, damage: int) -> Dictionary:
	var data := Binding.record(target)
	return {"present": not data.is_empty(), "blocked": Binding.switch_blocked(state, target, catalog), "duration": int(data.get("duration", 0)), "residual_damage": damage}
