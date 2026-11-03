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
			"02": _block_02(block)
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

# 02: Caracterización de uso de campo real, sin simular navegación ni encuentros.
# Se comprueban contrato de rechazo, estado de criatura, bolsa y roundtrip.
func _block_02(block: Dictionary) -> void:
	var ids: Array = block.get("ids", [])
	check("Bloque02 tres IDs exactos", ids == ["black_flute", "blue_flute", "escape_rope"]
		and not bool(block.get("supported_effects_certified", true)))
	for raw_id: String in ids:
		var id := StringName(raw_id)
		check("Objeto presente en catálogo " + raw_id, catalogs.item(id) != null)
		for case: Dictionary in block.get("cases", []):
			for quantity: int in block.get("inventory_counts", []):
				var service := service_for()
				check("Selección permite objeto del bloque02 " + raw_id,
					service.selection.content_allowed(id))
				var target: CreatureInstance = service.owner.owned_creature(&"field_item_target")
				if String(case.get("status", "none")) == "sleep":
					status(target, &"sleep")
				check("Inventario preparada " + raw_id, service.owner.inventory.add(id, quantity) if quantity > 0 else true)
				var before: String = snapshot(service)
				var result: Dictionary = service.use_item(id, target.instance_id)
				check("Sin ejecutor de campo debe rechazarse sin efectos " + raw_id,
					result.get("accepted", true) == false
					and String(result.get("reason", "")) == "field_effect_not_connected"
					and String(result.get("status", "")) == "DEPENDENCY_MISSING"
					and snapshot(service) == before
					and service.owner.inventory.quantity(id) == quantity)
				var saved: Dictionary = service.owner.inventory.to_dict()
				var loaded: PlayerInventory = PlayerInventory.from_dict(saved)
				check("Roundtrip inventario de item campo " + raw_id,
					not loaded.corrupted and loaded.to_dict() == saved
					and loaded.quantity(id) == quantity)
				check("No suprime sueño por falsa Flauta Azul " + raw_id,
					String(case.get("status", "")) != "sleep"
					or target.status_state.persistent_id == &"sleep")
		var service_locked := service_for()
		check("Bolsa preparada bloqueo " + raw_id, service_locked.owner.inventory.add(id, 2))
		var before_locked: String = snapshot(service_locked)
		locked = true
		var denied: Dictionary = service_locked.use_item(id, &"field_item_target")
		locked = false
		check("Bloqueo impide uso y consumo " + raw_id,
			denied.get("accepted", true) == false
			and String(denied.get("reason", "")) == "field_locked"
			and snapshot(service_locked) == before_locked)
		var service_bad := service_for()
		check("Bolsa preparada corrupción " + raw_id, service_bad.owner.inventory.add(id, 2))
		service_bad.owner.inventory.corrupted = true
		var before_bad: String = snapshot(service_bad)
		var invalid: Dictionary = service_bad.use_item(id, &"field_item_target")
		check("Bolsa corrupta rechaza sin mutar " + raw_id,
			invalid.get("accepted", true) == false
			and String(invalid.get("reason", "")) == "invalid_inventory"
			and snapshot(service_bad) == before_bad)
		var service_foreign := service_for()
		check("Bolsa preparada objetivo ajeno " + raw_id, service_foreign.owner.inventory.add(id, 2))
		var before_foreign: String = snapshot(service_foreign)
		var missing: Dictionary = service_foreign.use_item(id, &"not_owned")
		check("No hay aplicación a objetivo ajeno " + raw_id,
			missing.get("accepted", true) == false
			and snapshot(service_foreign) == before_foreign)

func _finish(n: int) -> void:
	done = true
	if errors.is_empty() and n > 0 and checks > 0:
		print("CAMP004_W03_GODOT PASS blocks=" + str(n) + " checks=" + str(checks))
		quit(0)
	else:
		print("CAMP004_W03_GODOT FAIL blocks=" + str(n) + " checks=" + str(checks)
			+ " errors=" + JSON.stringify(errors))
		quit(1)
