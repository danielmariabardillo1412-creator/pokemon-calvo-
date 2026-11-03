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
			"03": _block_03(block)
			"04": _block_04(block)
			"05": _block_05(block)
			"06": _block_06(block)
			"07": _block_07(block)
			"08": _block_08(block)
			"09": _block_09(block)
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
	check("Bloque02 tres IDs exactos", ids == ["black_flute", "blue_flute", "escape_rope"])
	for raw_id: String in ids:
		var id := StringName(raw_id)
		check("Objeto campo registrado en catálogo " + raw_id, catalogs.item(id) != null)
		var blue: bool = id == &"blue_flute"
		for case: Dictionary in block.get("cases", []):
			for quantity: int in block.get("inventory_counts", []):
				var service := service_for()
				check("Política de selección permite objeto " + raw_id,
					service.selection.content_allowed(id))
				var target: CreatureInstance = service.owner.owned_creature(&"field_item_target")
				var asleep: bool = String(case.get("status", "")) == "sleep"
				if asleep:
					status(target, &"sleep")
					service.sleep_clocks[String(target.instance_id)] = {
						"version": "0.10.11", "start_time": 3, "time": 2}
				if quantity > 0:
					check("Mochila preparada " + raw_id, service.owner.inventory.add(id, quantity))
				var before: String = snapshot(service)
				var before_target: Dictionary = target.to_dict()
				var result: Dictionary = service.use_item(id, target.instance_id)
				if blue and asleep and quantity > 0:
					var after: CreatureInstance = service.owner.owned_creature(&"field_item_target")
					check("Flauta Azul cura sueño con efecto real", result.get("accepted", false) == true
						and String(result.get("status", "")) == "APPLIED"
						and after != null and after.status_state.persistent_id == &""
						and after.status_ids.is_empty() and after.instance_id == target.instance_id
						and after.current_hp == target.current_hp
						and after.friendship == target.friendship)
					check("Flauta Azul reutilizable, reloj sueño eliminado", 
						service.owner.inventory.quantity(id) == quantity
						and service.sleep_clocks.is_empty()
						and target.to_dict() == before_target)
				else:
					var expected: String = "field_effect_not_connected"
					if blue:
						expected = "item_not_owned" if quantity == 0 else "item_has_no_effect"
					check("Rechazo de campo sin mutación " + raw_id + String(case.get("name", "")),
						result.get("accepted", true) == false
						and String(result.get("reason", "")) == expected
						and snapshot(service) == before
						and service.owner.inventory.quantity(id) == quantity)
				var saved: Dictionary = service.owner.inventory.to_dict()
				var loaded: PlayerInventory = PlayerInventory.from_dict(saved)
				check("Mochila roundtrip con cantidad intacta " + raw_id,
					not loaded.corrupted and loaded.to_dict() == saved
					and loaded.quantity(id) == quantity)
		var locked_service := service_for()
		check("Bolsa para bloqueo " + raw_id, locked_service.owner.inventory.add(id, 2))
		var locked_before: String = snapshot(locked_service)
		locked = true
		var denied: Dictionary = locked_service.use_item(id, &"field_item_target")
		locked = false
		check("Bloqueo de campo previo a acción " + raw_id,
			denied.get("accepted", true) == false
			and String(denied.get("reason", "")) == "field_locked"
			and snapshot(locked_service) == locked_before)
		var bad_service := service_for()
		check("Bolsa para corrupción " + raw_id, bad_service.owner.inventory.add(id, 2))
		bad_service.owner.inventory.corrupted = true
		var bad_before: String = snapshot(bad_service)
		var invalid: Dictionary = bad_service.use_item(id, &"field_item_target")
		check("Corrupción de mochila sin cambio " + raw_id,
			invalid.get("accepted", true) == false
			and String(invalid.get("reason", "")) == "invalid_inventory"
			and snapshot(bad_service) == bad_before)
		var foreign_service := service_for()
		check("Bolsa para objetivo ajeno " + raw_id, foreign_service.owner.inventory.add(id, 2))
		var foreign_before: String = snapshot(foreign_service)
		var missing: Dictionary = foreign_service.use_item(id, &"not_owned")
		check("Objetivo ajeno nunca aplica efecto " + raw_id,
			missing.get("accepted", true) == false
			and snapshot(foreign_service) == foreign_before)

# 03: Cola Plúmbea, Frambu Dorada y Señuelo.
# No producir huida, captura con bayas ni encuentros ficticios.
func _block_03(block: Dictionary) -> void:
	var ids: Array = block.get("ids", [])
	check("Bloque03 reserva exacta", ids == ["fluffy_tail", "golden_razz_berry", "lure"])
	check("No certificar efecto de campo ausente", not bool(block.get("functional_effect_certified", true)))
	for raw_id: String in ids:
		var id := StringName(raw_id)
		check("Objeto existe en catálogo " + raw_id, catalogs.item(id) != null)
		for case: Dictionary in block.get("cases", []):
			for count: int in block.get("inventory_counts", []):
				var service := service_for()
				check("Selección admite objeto " + raw_id, service.selection.content_allowed(id))
				var creature: CreatureInstance = service.owner.owned_creature(&"field_item_target")
				if String(case.get("status", "")) == "sleep":
					status(creature, &"sleep")
					service.sleep_clocks[String(creature.instance_id)] = {
						"version": "0.10.11", "start_time": 3, "time": 2}
				if count > 0:
					check("Mochila preparada " + raw_id, service.owner.inventory.add(id, count))
				var before: String = snapshot(service)
				var result: Dictionary = service.use_item(id, creature.instance_id)
				check("Sin conexión: rechazo sin gasto ni mutación " + raw_id,
					result.get("accepted", true) == false
					and String(result.get("reason", "")) == "field_effect_not_connected"
					and String(result.get("status", "")) == "DEPENDENCY_MISSING"
					and snapshot(service) == before
					and service.owner.inventory.quantity(id) == count)
				var saved: Dictionary = service.owner.inventory.to_dict()
				var restored: PlayerInventory = PlayerInventory.from_dict(saved)
				check("Serialización estricta de bolsa " + raw_id,
					not restored.corrupted and restored.to_dict() == saved
					and restored.quantity(id) == count)
		var locked_service := service_for()
		check("Mochila bloqueo " + raw_id, locked_service.owner.inventory.add(id, 2))
		var before_locked: String = snapshot(locked_service)
		locked = true
		var denied: Dictionary = locked_service.use_item(id, &"field_item_target")
		locked = false
		check("Campo bloqueado no consume ni altera " + raw_id,
			denied.get("accepted", true) == false
			and String(denied.get("reason", "")) == "field_locked"
			and snapshot(locked_service) == before_locked)
		var corrupt_service := service_for()
		check("Mochila para estado corrupto " + raw_id,
			corrupt_service.owner.inventory.add(id, 2))
		corrupt_service.owner.inventory.corrupted = true
		var before_corrupt: String = snapshot(corrupt_service)
		var invalid: Dictionary = corrupt_service.use_item(id, &"field_item_target")
		check("Inventario corrupto bloquea " + raw_id,
			invalid.get("accepted", true) == false
			and String(invalid.get("reason", "")) == "invalid_inventory"
			and snapshot(corrupt_service) == before_corrupt)
		var foreign_service := service_for()
		check("Mochila para objetivo ajeno " + raw_id,
			foreign_service.owner.inventory.add(id, 2))
		var before_foreign: String = snapshot(foreign_service)
		var foreign: Dictionary = foreign_service.use_item(id, &"foreign_creature")
		check("Objetivo ajeno: no activar ni consumir " + raw_id,
			foreign.get("accepted", true) == false
			and String(foreign.get("reason", "")) == "field_effect_not_connected"
			and snapshot(foreign_service) == before_foreign)

# 04: Max Lure, Max Repel y Flauta Roja sin efectos atribuidos sin API.
func _block_04(block: Dictionary) -> void:
	var ids: Array = block.get("ids", [])
	check("Bloque04 IDs autorizados", ids == ["max_lure", "max_repel", "red_flute"])
	check("No atribuir funcionamiento sin prueba", not bool(block.get("functional_effect_certified", true)))
	for raw_id: String in ids:
		var id := StringName(raw_id)
		check("ID de catálogo real " + raw_id, catalogs.item(id) != null)
		for case: Dictionary in block.get("cases", []):
			for count: int in block.get("inventory_counts", []):
				var service := service_for()
				check("Selección oficial admite " + raw_id, service.selection.content_allowed(id))
				var creature: CreatureInstance = service.owner.owned_creature(&"field_item_target")
				match String(case.get("status", "none")):
					"confusion":
						creature.status_state.add_volatile(&"confusion", {"turns": 3})
					"sleep":
						status(creature, &"sleep")
						service.sleep_clocks[String(creature.instance_id)] = {
							"version": "0.10.11", "start_time": 3, "time": 2}
				if count > 0:
					check("Preparar mochila " + raw_id, service.owner.inventory.add(id, count))
				var before: String = snapshot(service)
				var response: Dictionary = service.use_item(id, creature.instance_id)
				check("Uso sin ruta rechaza y conserva todo " + raw_id,
					response.get("accepted", true) == false
					and String(response.get("reason", "")) == "field_effect_not_connected"
					and String(response.get("status", "")) == "DEPENDENCY_MISSING"
					and snapshot(service) == before
					and service.owner.inventory.quantity(id) == count)
				var saved: Dictionary = service.owner.inventory.to_dict()
				var loaded: PlayerInventory = PlayerInventory.from_dict(saved)
				check("Mochila persiste por serialización pura " + raw_id,
					not loaded.corrupted and loaded.to_dict() == saved
					and loaded.quantity(id) == count)
				if String(case.get("status", "")) == "confusion":
					check("No fingir curación Flauta Roja " + raw_id,
						creature.status_state.has_volatile(&"confusion"))
		var locked_service := service_for()
		check("Mochila preparada para campo bloqueado " + raw_id,
			locked_service.owner.inventory.add(id, 2))
		var before_locked: String = snapshot(locked_service)
		locked = true
		var denied: Dictionary = locked_service.use_item(id, &"field_item_target")
		locked = false
		check("Campo bloqueado guarda invariantes " + raw_id,
			denied.get("accepted", true) == false
			and String(denied.get("reason", "")) == "field_locked"
			and snapshot(locked_service) == before_locked)
		var corrupt_service := service_for()
		check("Mochila preparada para corrupción " + raw_id,
			corrupt_service.owner.inventory.add(id, 2))
		corrupt_service.owner.inventory.corrupted = true
		var before_corrupt: String = snapshot(corrupt_service)
		var invalid: Dictionary = corrupt_service.use_item(id, &"field_item_target")
		check("Bolsa corrupta rechaza sin cambios " + raw_id,
			invalid.get("accepted", true) == false
			and String(invalid.get("reason", "")) == "invalid_inventory"
			and snapshot(corrupt_service) == before_corrupt)
		var foreign_service := service_for()
		check("Preparar objetivo ajeno " + raw_id,
			foreign_service.owner.inventory.add(id, 2))
		var before_foreign: String = snapshot(foreign_service)
		var foreign: Dictionary = foreign_service.use_item(id, &"foreign_creature")
		check("Objetivo ajeno sin efecto ni gasto " + raw_id,
			foreign.get("accepted", true) == false
			and String(foreign.get("reason", "")) == "field_effect_not_connected"
			and snapshot(foreign_service) == before_foreign)

# 05: Repelente, Baya Frambu Plateada y Supercolonia.
# No fingir efectos de encuentro/captura sin contrato de integración.
func _block_05(block: Dictionary) -> void:
	var ids: Array = block.get("ids", [])
	check("Bloque05 IDs autorizados", ids == ["repel", "silver_razz_berry", "super_lure"])
	check("Bloque05 sin efectos ficticios", not bool(block.get("functional_effect_certified", true)))
	for raw_id: String in ids:
		var id := StringName(raw_id)
		check("Catálogo contiene ID " + raw_id, catalogs.item(id) != null)
		for case: Dictionary in block.get("cases", []):
			for count: int in block.get("inventory_counts", []):
				var service := service_for()
				check("Política de selección permite " + raw_id, service.selection.content_allowed(id))
				var creature: CreatureInstance = service.owner.owned_creature(&"field_item_target")
				match String(case.get("status", "")):
					"confusion":
						creature.status_state.add_volatile(&"confusion", {"turns": 3})
					"sleep":
						status(creature, &"sleep")
						service.sleep_clocks[String(creature.instance_id)] = {
							"version": "0.10.11", "start_time": 3, "time": 2}
				if count > 0:
					check("Existencias preparadas " + raw_id, service.owner.inventory.add(id, count))
				var before: String = snapshot(service)
				var result: Dictionary = service.use_item(id, creature.instance_id)
				check("Rechazo seguro de efecto no conectado " + raw_id,
					result.get("accepted", true) == false
					and String(result.get("reason", "")) == "field_effect_not_connected"
					and String(result.get("status", "")) == "DEPENDENCY_MISSING"
					and snapshot(service) == before
					and service.owner.inventory.quantity(id) == count)
				var saved: Dictionary = service.owner.inventory.to_dict()
				var loaded: PlayerInventory = PlayerInventory.from_dict(saved)
				check("Inventario conserva cantidades tras roundtrip " + raw_id,
					not loaded.corrupted and loaded.to_dict() == saved
					and loaded.quantity(id) == count)
				if String(case.get("status", "")) == "confusion":
					check("No alterar confusión por un objeto sin ejecutor " + raw_id,
						creature.status_state.has_volatile(&"confusion"))
		var locked_service := service_for()
		check("Mochila bloqueo preparada " + raw_id, locked_service.owner.inventory.add(id, 2))
		var before_locked: String = snapshot(locked_service)
		locked = true
		var denied: Dictionary = locked_service.use_item(id, &"field_item_target")
		locked = false
		check("Campo bloqueado conserva estado " + raw_id,
			denied.get("accepted", true) == false
			and String(denied.get("reason", "")) == "field_locked"
			and snapshot(locked_service) == before_locked)
		var corrupt_service := service_for()
		check("Preparación mochila corrupta " + raw_id, corrupt_service.owner.inventory.add(id, 2))
		corrupt_service.owner.inventory.corrupted = true
		var before_corrupt: String = snapshot(corrupt_service)
		var invalid: Dictionary = corrupt_service.use_item(id, &"field_item_target")
		check("Mochila corrupta rechaza sin gasto " + raw_id,
			invalid.get("accepted", true) == false
			and String(invalid.get("reason", "")) == "invalid_inventory"
			and snapshot(corrupt_service) == before_corrupt)
		var foreign_service := service_for()
		check("Mochila objetivo ajeno preparada " + raw_id,
			foreign_service.owner.inventory.add(id, 2))
		var before_foreign: String = snapshot(foreign_service)
		var foreign: Dictionary = foreign_service.use_item(id, &"foreign_creature")
		check("Objetivo ajeno sin gasto ni efectos " + raw_id,
			foreign.get("accepted", true) == false
			and String(foreign.get("reason", "")) == "field_effect_not_connected"
			and snapshot(foreign_service) == before_foreign)

# 06: Superrepelente, Flauta Blanca y Flauta Amarilla; integracion no existente.
func _block_06(block: Dictionary) -> void:
	var ids: Array = block.get("ids", [])
	check("Bloque06 reserva exacta", ids == ["super_repel", "white_flute", "yellow_flute"])
	check("Bloque06 no declara efecto sin API", not bool(block.get("functional_effect_certified", true)))
	for raw_id: String in ids:
		var id := StringName(raw_id)
		check("Objeto de catálogo " + raw_id, catalogs.item(id) != null)
		for case: Dictionary in block.get("cases", []):
			for count: int in block.get("inventory_counts", []):
				var service := service_for()
				check("Objeto seleccionado por política " + raw_id, service.selection.content_allowed(id))
				var creature: CreatureInstance = service.owner.owned_creature(&"field_item_target")
				match String(case.get("status", "")):
					"confusion":
						creature.status_state.add_volatile(&"confusion", {"turns": 3})
					"sleep":
						status(creature, &"sleep")
						service.sleep_clocks[String(creature.instance_id)] = {
							"version": "0.10.11", "start_time": 3, "time": 2}
				if count > 0:
					check("Mochila inicial " + raw_id, service.owner.inventory.add(id, count))
				var before: String = snapshot(service)
				var result: Dictionary = service.use_item(id, creature.instance_id)
				check("Efecto ausente rechaza sin consumir " + raw_id,
					result.get("accepted", true) == false
					and String(result.get("reason", "")) == "field_effect_not_connected"
					and String(result.get("status", "")) == "DEPENDENCY_MISSING"
					and snapshot(service) == before
					and service.owner.inventory.quantity(id) == count)
				var saved: Dictionary = service.owner.inventory.to_dict()
				var loaded: PlayerInventory = PlayerInventory.from_dict(saved)
				check("Roundtrip de inventario sin perdida " + raw_id,
					not loaded.corrupted and loaded.to_dict() == saved
					and loaded.quantity(id) == count)
				if String(case.get("status", "")) == "confusion":
					check("Flauta Amarilla aun no cura confusion " + raw_id,
						creature.status_state.has_volatile(&"confusion"))
		var locked_service := service_for()
		check("Mochila para bloqueo " + raw_id, locked_service.owner.inventory.add(id, 2))
		var before_locked: String = snapshot(locked_service)
		locked = true
		var denied: Dictionary = locked_service.use_item(id, &"field_item_target")
		locked = false
		check("Bloqueo de campo seguro " + raw_id,
			denied.get("accepted", true) == false
			and String(denied.get("reason", "")) == "field_locked"
			and snapshot(locked_service) == before_locked)
		var bad_service := service_for()
		check("Mochila para corrupcion " + raw_id, bad_service.owner.inventory.add(id, 2))
		bad_service.owner.inventory.corrupted = true
		var before_bad: String = snapshot(bad_service)
		var invalid: Dictionary = bad_service.use_item(id, &"field_item_target")
		check("Bolsa corrupta conserva estado " + raw_id,
			invalid.get("accepted", true) == false
			and String(invalid.get("reason", "")) == "invalid_inventory"
			and snapshot(bad_service) == before_bad)
		var foreign_service := service_for()
		check("Bolsa para criatura ajena " + raw_id,
			foreign_service.owner.inventory.add(id, 2))
		var before_foreign: String = snapshot(foreign_service)
		var foreign: Dictionary = foreign_service.use_item(id, &"foreign_creature")
		check("Objetivo ajeno no activa ni consume " + raw_id,
			foreign.get("accepted", true) == false
			and String(foreign.get("reason", "")) == "field_effect_not_connected"
			and snapshot(foreign_service) == before_foreign)

# 07: inventario positivo de Teralitos, pero SIN teracristalizacion.
func _block_07(block: Dictionary) -> void:
	var ids: Array = block.get("ids", [])
	check("Bloque07 IDs Tera autorizados",
		ids == ["bug_tera_shard", "dark_tera_shard", "dragon_tera_shard",
		"electric_tera_shard", "fairy_tera_shard"])
	check("No certificar teracristalizacion",
		bool(block.get("no_terastallization_certified", false)))
	for raw_id: String in ids:
		var id := StringName(raw_id)
		check("Teralito presente en catalogo " + raw_id, catalogs.item(id) != null)
		for count: int in block.get("inventory_counts", []):
			var service := service_for()
			check("Teralito seleccionado " + raw_id, service.selection.content_allowed(id))
			if count > 0:
				check("Inventario admite Teralito " + raw_id, service.owner.inventory.add(id, count))
			check("Inventario cantidad y presencia " + raw_id,
				service.owner.inventory.quantity(id) == count
				and service.owner.inventory.has(id) == (count > 0))
			var before: String = snapshot(service)
			var result: Dictionary = service.use_item(id, &"field_item_target")
			check("Sin API Tera, uso directo rechaza sin gasto " + raw_id,
				result.get("accepted", true) == false
				and String(result.get("reason", "")) == "field_effect_not_connected"
				and String(result.get("status", "")) == "DEPENDENCY_MISSING"
				and snapshot(service) == before)
			var serialized: Dictionary = service.owner.inventory.to_dict()
			var loaded: PlayerInventory = PlayerInventory.from_dict(serialized)
			check("Roundtrip puro mochila Tera " + raw_id,
				not loaded.corrupted and loaded.to_dict() == serialized
				and loaded.quantity(id) == count)
			if count > 0:
				check("Extraccion transaccional valida " + raw_id,
					loaded.remove(id) and loaded.quantity(id) == count - 1)
				check("Reposicion exacta Tera " + raw_id,
					loaded.add(id) and loaded.to_dict() == serialized)
				check("No hay consumo al rechazar Tera " + raw_id,
					service.owner.inventory.quantity(id) == count)
			else:
				check("Sin Teralito no se extrae " + raw_id,
					not loaded.remove(id) and loaded.is_empty())
			if count == InventoryRuleset.MAX_STACK:
				check("Limite de stack sin desbordamiento " + raw_id,
					not loaded.add(id) and loaded.quantity(id) == count)
		var locked_service := service_for()
		check("Preparar Teralito para bloqueo " + raw_id,
			locked_service.owner.inventory.add(id, 2))
		var locked_before: String = snapshot(locked_service)
		locked = true
		var denied: Dictionary = locked_service.use_item(id, &"field_item_target")
		locked = false
		check("Frontera de campo para Tera " + raw_id,
			denied.get("accepted", true) == false
			and String(denied.get("reason", "")) == "field_locked"
			and snapshot(locked_service) == locked_before)
		var bad_service := service_for()
		check("Preparar bolsa para corrupcion Tera " + raw_id,
			bad_service.owner.inventory.add(id, 2))
		bad_service.owner.inventory.corrupted = true
		var bad_before: String = snapshot(bad_service)
		var invalid: Dictionary = bad_service.use_item(id, &"field_item_target")
		check("Tera no atraviesa inventario corrupto " + raw_id,
			invalid.get("accepted", true) == false
			and String(invalid.get("reason", "")) == "invalid_inventory"
			and snapshot(bad_service) == bad_before)

# 08: pruebas reales de inventario adicionales sin activar Tera.
func _block_08(block: Dictionary) -> void:
	var ids: Array = block.get("ids", [])
	check("Bloque08 IDs Tera autorizados",
		ids == ["fighting_tera_shard", "fire_tera_shard", "flying_tera_shard",
		"ghost_tera_shard", "grass_tera_shard"])
	check("No certificar teracristalizacion",
		bool(block.get("no_terastallization_certified", false)))
	for raw_id: String in ids:
		var id := StringName(raw_id)
		check("Teralito presente en catalogo " + raw_id, catalogs.item(id) != null)
		for count: int in block.get("inventory_counts", []):
			var service := service_for()
			check("Teralito seleccionado " + raw_id, service.selection.content_allowed(id))
			if count > 0:
				check("Inventario admite Teralito " + raw_id, service.owner.inventory.add(id, count))
			check("Inventario cantidad y presencia " + raw_id,
				service.owner.inventory.quantity(id) == count
				and service.owner.inventory.has(id) == (count > 0))
			var before: String = snapshot(service)
			var result: Dictionary = service.use_item(id, &"field_item_target")
			check("Sin API Tera, uso directo rechaza sin gasto " + raw_id,
				result.get("accepted", true) == false
				and String(result.get("reason", "")) == "field_effect_not_connected"
				and String(result.get("status", "")) == "DEPENDENCY_MISSING"
				and snapshot(service) == before)
			var serialized: Dictionary = service.owner.inventory.to_dict()
			var loaded: PlayerInventory = PlayerInventory.from_dict(serialized)
			check("Roundtrip puro mochila Tera " + raw_id,
				not loaded.corrupted and loaded.to_dict() == serialized
				and loaded.quantity(id) == count)
			if count > 0:
				check("Extraccion transaccional valida " + raw_id,
					loaded.remove(id) and loaded.quantity(id) == count - 1)
				check("Reposicion exacta Tera " + raw_id,
					loaded.add(id) and loaded.to_dict() == serialized)
				check("No hay consumo al rechazar Tera " + raw_id,
					service.owner.inventory.quantity(id) == count)
			else:
				check("Sin Teralito no se extrae " + raw_id,
					not loaded.remove(id) and loaded.is_empty())
			if count == InventoryRuleset.MAX_STACK:
				check("Limite de stack sin desbordamiento " + raw_id,
					not loaded.add(id) and loaded.quantity(id) == count)
		var locked_service := service_for()
		check("Preparar Teralito para bloqueo " + raw_id,
			locked_service.owner.inventory.add(id, 2))
		var locked_before: String = snapshot(locked_service)
		locked = true
		var denied: Dictionary = locked_service.use_item(id, &"field_item_target")
		locked = false
		check("Frontera de campo para Tera " + raw_id,
			denied.get("accepted", true) == false
			and String(denied.get("reason", "")) == "field_locked"
			and snapshot(locked_service) == locked_before)
		var bad_service := service_for()
		check("Preparar bolsa para corrupcion Tera " + raw_id,
			bad_service.owner.inventory.add(id, 2))
		bad_service.owner.inventory.corrupted = true
		var bad_before: String = snapshot(bad_service)
		var invalid: Dictionary = bad_service.use_item(id, &"field_item_target")
		check("Tera no atraviesa inventario corrupto " + raw_id,
			invalid.get("accepted", true) == false
			and String(invalid.get("reason", "")) == "invalid_inventory"
			and snapshot(bad_service) == bad_before)

# 09: Teralitos Tierra Hielo Normal Veneno; no activar Tera.
func _block_09(block: Dictionary) -> void:
	var ids: Array = block.get("ids", [])
	check("Bloque09 IDs Tera autorizados",
		ids == ["ground_tera_shard", "ice_tera_shard", "normal_tera_shard",
		"poison_tera_shard"])
	check("No certificar teracristalizacion",
		bool(block.get("no_terastallization_certified", false)))
	for raw_id: String in ids:
		var id := StringName(raw_id)
		check("Teralito presente en catalogo " + raw_id, catalogs.item(id) != null)
		for count: int in block.get("inventory_counts", []):
			var service := service_for()
			check("Teralito seleccionado " + raw_id, service.selection.content_allowed(id))
			if count > 0:
				check("Inventario admite Teralito " + raw_id, service.owner.inventory.add(id, count))
			check("Inventario cantidad y presencia " + raw_id,
				service.owner.inventory.quantity(id) == count
				and service.owner.inventory.has(id) == (count > 0))
			var before: String = snapshot(service)
			var result: Dictionary = service.use_item(id, &"field_item_target")
			check("Sin API Tera, uso directo rechaza sin gasto " + raw_id,
				result.get("accepted", true) == false
				and String(result.get("reason", "")) == "field_effect_not_connected"
				and String(result.get("status", "")) == "DEPENDENCY_MISSING"
				and snapshot(service) == before)
			var serialized: Dictionary = service.owner.inventory.to_dict()
			var loaded: PlayerInventory = PlayerInventory.from_dict(serialized)
			check("Roundtrip puro mochila Tera " + raw_id,
				not loaded.corrupted and loaded.to_dict() == serialized
				and loaded.quantity(id) == count)
			if count > 0:
				check("Extraccion transaccional valida " + raw_id,
					loaded.remove(id) and loaded.quantity(id) == count - 1)
				check("Reposicion exacta Tera " + raw_id,
					loaded.add(id) and loaded.to_dict() == serialized)
				check("No hay consumo al rechazar Tera " + raw_id,
					service.owner.inventory.quantity(id) == count)
			else:
				check("Sin Teralito no se extrae " + raw_id,
					not loaded.remove(id) and loaded.is_empty())
			if count == InventoryRuleset.MAX_STACK:
				check("Limite de stack sin desbordamiento " + raw_id,
					not loaded.add(id) and loaded.quantity(id) == count)
		var locked_service := service_for()
		check("Preparar Teralito para bloqueo " + raw_id,
			locked_service.owner.inventory.add(id, 2))
		var locked_before: String = snapshot(locked_service)
		locked = true
		var denied: Dictionary = locked_service.use_item(id, &"field_item_target")
		locked = false
		check("Frontera de campo para Tera " + raw_id,
			denied.get("accepted", true) == false
			and String(denied.get("reason", "")) == "field_locked"
			and snapshot(locked_service) == locked_before)
		var bad_service := service_for()
		check("Preparar bolsa para corrupcion Tera " + raw_id,
			bad_service.owner.inventory.add(id, 2))
		bad_service.owner.inventory.corrupted = true
		var bad_before: String = snapshot(bad_service)
		var invalid: Dictionary = bad_service.use_item(id, &"field_item_target")
		check("Tera no atraviesa inventario corrupto " + raw_id,
			invalid.get("accepted", true) == false
			and String(invalid.get("reason", "")) == "invalid_inventory"
			and snapshot(bad_service) == bad_before)

func _finish(n: int) -> void:
	done = true
	if errors.is_empty() and n > 0 and checks > 0:
		print("CAMP004_W03_GODOT PASS blocks=" + str(n) + " checks=" + str(checks))
		quit(0)
	else:
		print("CAMP004_W03_GODOT FAIL blocks=" + str(n) + " checks=" + str(checks)
			+ " errors=" + JSON.stringify(errors))
		quit(1)
