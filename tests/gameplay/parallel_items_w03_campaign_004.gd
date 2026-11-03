extends "res://tests/gameplay/item_capture_v11.gd"

# IA3/W03 CAMP004: pruebas de integración sobre el motor de captura REAL.
# No se simula buceo, noche/cueva ni historial de Pokédex.
const FIXTURE := "res://tests/fixtures/parallel_items/w03_campaign_004.json"

func _initialize() -> void:
	call_deferred("_run_campaign")
	create_timer(180).timeout.connect(func():
		if not done:
			push_error("CAMP004_W03_TIMEOUT")
			quit(2)
	)

func _run_campaign() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/normalized/pokemon_api.json"))
	if not raw is Dictionary:
		check("Existe catálogo real", false)
		_finish(0)
		return
	catalogs = GameData.from_dict(raw).to_definition_catalog()
	check("Overlay regional real", Variants.apply(catalogs))
	var decoded: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not decoded is Dictionary:
		check("Fixture válido", false)
		_finish(0)
		return
	var blocks: Array = decoded.get("blocks", [])
	check("Campaña W03 correcta", decoded.get("campaign", "") == "CAMP_004"
		and decoded.get("worker", "") == "W03" and not blocks.is_empty())
	var n := 0
	for block: Dictionary in blocks:
		n += 1
		match String(block.get("bloque", "")):
			"01": _block_01(block)
			_: check("Bloque sin suite funcional " + str(n), false)
	_finish(n)

func _block_01(block: Dictionary) -> void:
	var ids: Array = block.get("ids", [])
	check("Reserva exacta 01", ids == ["dive_ball", "dusk_ball", "repeat_ball"])
	check("No certificar efectos contextuales", not bool(block.get("functional_effect_certified", true)))
	var rules := CaptureRuleset.new()
	for raw_id: String in ids:
		var id := StringName(raw_id)
		check("La bola no está registrada: " + raw_id,
			not rules.is_known_ball(id) and rules.ball(id) == null
			and not CaptureRuleset.ordered_ball_ids().has(id))
	for entry: Dictionary in block.get("cases", []):
		var sid := StringName(String(entry.get("species_id", "")))
		check("Especie del catálogo " + String(sid), catalogs.species(sid) != null)
		if catalogs.species(sid) == null:
			continue
		for hp_mode: String in block.get("hp_modes", []):
			for context_data: Dictionary in block.get("contexts", []):
				for raw_id: String in ids:
					var id := StringName(raw_id)
					var target: CreatureInstance = _mon(sid, int(entry.get("level", 12)),
						StringName("c004_01_" + raw_id + String(sid) + hp_mode
						+ String(context_data.get("name", ""))))
					target.current_hp = target.stats.max_hp if hp_mode == "full" else 1
					var ctx := CaptureBattleContext.new()
					ctx.completed_turns = int(context_data.get("completed_turns", -1))
					ctx.catcher_level = int(context_data.get("catcher_level", -1))
					var inv := PlayerInventory.new()
					inv.add(id, 2)
					var party := CreatureParty.new()
					var rng := RandomNumberGenerator.new()
					rng.seed = int(entry.get("seed", 4001))
					var before_target: Dictionary = target.to_dict()
					var before_inv: Dictionary = inv.to_dict()
					var before_rng: int = rng.state
					var attempt := CaptureAttempt.new(target, id, ctx)
					check("Preflight unknown_ball " + raw_id,
						CaptureSystem.validate_attempt(attempt, catalogs) == "unknown_ball")
					var result: CaptureResolution = CaptureInventoryService.resolve(
						attempt, rng, catalogs, party, inv)
					check("No consumo/captura/RNG/modificación " + raw_id,
						result.result.status == CaptureResult.INVALID
						and result.result.reason == "unknown_ball"
						and not result.result.consume_item and result.captured == null
						and party.is_empty() and inv.to_dict() == before_inv
						and target.to_dict() == before_target and rng.state == before_rng)
	for raw_id: String in ids:
		var id := StringName(raw_id)
		for reason: String in block.get("invalid_cases", []):
			var target: CreatureInstance = _mon(&"mew", 35,
				StringName("c004_01_reject_" + raw_id + reason))
			var ctx := CaptureBattleContext.new()
			var inv := PlayerInventory.new()
			inv.add(id, 2)
			match reason:
				"trainer_battle_not_capturable": ctx.is_wild = false
				"battle_finished": ctx.battle_finished = true
				"target_knocked_out": target.current_hp = 0
				"item_not_owned": inv.remove(id, 2)
			var expected_reason: String = "unknown_ball" if reason == "item_not_owned" else reason
			var before_target: Dictionary = target.to_dict()
			var before_inv: Dictionary = inv.to_dict()
			var party := CreatureParty.new()
			var rng := RandomNumberGenerator.new()
			rng.seed = 491
			var before_rng: int = rng.state
			var result: CaptureResolution = CaptureInventoryService.resolve(
				CaptureAttempt.new(target, id, ctx), rng, catalogs, party, inv)
			check("Rechazo prioritario sin efectos " + raw_id + reason,
				result.result.status == CaptureResult.INVALID
				and result.result.reason == expected_reason
				and not result.result.consume_item and result.captured == null
				and party.is_empty() and inv.to_dict() == before_inv
				and target.to_dict() == before_target and rng.state == before_rng)

func _finish(n: int) -> void:
	done = true
	if errors.is_empty() and n > 0 and checks > 0:
		print("CAMP004_W03_GODOT PASS blocks=" + str(n) + " checks=" + str(checks))
		quit(0)
	else:
		print("CAMP004_W03_GODOT FAIL blocks=" + str(n) + " checks=" + str(checks)
			+ " errors=" + JSON.stringify(errors))
		quit(1)
