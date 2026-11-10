extends "res://tests/gameplay/parallel_items_w05_book_ui_autorun_v2.gd"

# TANDA03: nine independent robustness scenarios, plus one final CI gate.
# Reuses real Godot fixture, definitions, owner, PanelContainer and FieldItemService
# from the certified V2 runner. Headless timings are NOT GPU FPS.
const HITS := 10
var completed := 0
var functional_hits := 0
var blocked_hits := 0
var elapsed_us: Array[int] = []

class RejectMoves:
	extends RefCounted
	func move_learnable(_move_id: String) -> bool:
		return false


func setup(move_id: StringName = &"pain_split", fill_four := false) -> Dictionary:
	var species_id := choose_species(move_id, true, fill_four)
	check("real species found " + String(move_id), species_id != &"")
	if species_id == &"":
		return {}
	var svc: Variant = new_service(species_id, move_id, fill_four)
	if svc == null:
		return {}
	check("real stock available " + String(move_id), svc.owner.inventory.add(
		&"tm31" if move_id == &"metal_claw" else &"tm202", 2))
	var panel: Variant = mount(svc)
	check("chosen real book", panel.select_book(&"tm31" if move_id == &"metal_claw" else &"tm202"))
	check("chosen party identity", panel.select_creature(POKEMON))
	return {"service": svc, "panel": panel, "species": species_id}


func load_all_books() -> Dictionary:
	var d := setup()
	if d.is_empty():
		return {}
	var svc: Variant = d.service
	var panel: Variant = d.panel
	var rows: Dictionary = svc.profile.get("machine_rows", {})
	var count := 0
	for raw: Variant in rows.keys():
		var id := StringName(raw)
		var versions: Variant = rows[raw]
		if not versions is Dictionary or not versions.has("scarlet-violet"):
			continue
		if svc.owner.inventory.has(id):
			continue
		check("add canonical book " + String(id), svc.owner.inventory.add(id, 1))
		count += 1
	check("profile contains exactly 229 active books", count == 228)
	panel.refresh()
	check("panel renders 229 books", panel.books.item_count == 229)
	return d


func hit_01_performance() -> void:
	var d := load_all_books()
	if d.is_empty():
		return
	var panel: Variant = d.panel
	var best := 9223372036854775807
	var worst := 0
	var sum := 0
	for iteration in range(10):
		var begin := Time.get_ticks_usec()
		panel.refresh()
		var elapsed := Time.get_ticks_usec() - begin
		best = min(best, elapsed)
		worst = max(worst, elapsed)
		sum += elapsed
		elapsed_us.append(elapsed)
		check("229 entries after refresh " + str(iteration), panel.books.item_count == 229)
		check("one layout after refresh " + str(iteration), panel.get_child_count() == 1)
	check("measurements nonnegative", best >= 0 and worst >= best and sum >= 0)
	print("W05_BOOKS_V3_PERF headless=true items=229 repeats=10 min_us=%d mean_us=%d max_us=%d" %
		[best, int(sum / 10), worst])
	panel.queue_free()


func hit_02_lifecycle() -> void:
	var d := setup()
	if d.is_empty():
		return
	var svc: Variant = d.service
	var panel: Variant = d.panel
	var callbacks := {"all": 0, "applied": 0}
	panel.teaching_finished.connect(func(result: Dictionary):
		callbacks["all"] += 1
		if result.get("accepted", false):
			callbacks["applied"] += 1)
	var original_children := panel.get_child_count()
	panel.get_parent().remove_child(panel)
	panel.request_ready()
	root.add_child(panel)
	check("no duplicate controls on reattach", panel.get_child_count() == original_children)
	check("button has exactly one handler", panel.teach_button.get_signal_connection_list("pressed").size() == 1)
	check("book selection survives reattach", panel._selected(panel.books) == &"tm202")
	panel.teach_button.pressed.emit()
	check("exactly one teach and one book consumed", svc.owner.inventory.quantity(&"tm202") == 1
		and callbacks.applied == 1 and callbacks.all == 1)
	var after := state(svc.owner)
	panel.teach_button.pressed.emit()
	check("repeated event cannot teach/spend twice", callbacks.applied == 1
		and callbacks.all == 2 and state(svc.owner) == after)
	panel.queue_free()
	var new_panel: Variant = mount(svc)
	check("new opening is a fresh panel", new_panel != panel
		and new_panel.teach_button.get_signal_connection_list("pressed").size() == 1)
	new_panel.queue_free()


func hit_03_stock_stale() -> void:
	var d := setup()
	if d.is_empty():
		return
	var svc: Variant = d.service
	var panel: Variant = d.panel
	check("other book present", svc.owner.inventory.add(&"tm31", 1))
	panel.refresh()
	check("current selected book unchanged", panel._selected(panel.books) == &"tm202")
	check("externally remove chosen stock", svc.owner.inventory.remove(&"tm202", 2))
	var before := state(svc.owner)
	panel.teach_button.pressed.emit()
	check("stale selection rejected without consuming other book", not panel.last_result.get("accepted", false)
		and panel.last_result.get("reason", "") == "item_not_owned"
		and state(svc.owner) == before and svc.owner.inventory.quantity(&"tm31") == 1)
	panel.refresh()
	check("missing book not silently replaced", panel._selected(panel.books) == &""
		and panel.teach_button.disabled and panel.books.item_count == 1)
	before = state(svc.owner)
	panel.teach_button.pressed.emit()
	check("blank stale selection cannot spend alternate", not panel.last_result.get("accepted", false)
		and state(svc.owner) == before)
	check("restore original stock", svc.owner.inventory.add(&"tm202", 3))
	panel.refresh()
	check("select original book after stock refresh", panel.select_book(&"tm202"))
	check("live count reflects three", panel.books.get_item_text(panel.books.selected).contains("x3"))
	panel.teach_button.pressed.emit()
	check("only one of restored three spent", panel.last_result.get("accepted", false)
		and svc.owner.inventory.quantity(&"tm202") == 2
		and svc.owner.inventory.quantity(&"tm31") == 1)
	panel.queue_free()


func hit_04_owner_moved() -> void:
	var d := setup()
	if d.is_empty():
		return
	var svc: Variant = d.service
	var panel: Variant = d.panel
	var creature: CreatureInstance = svc.owner.owned_creature(POKEMON)
	check("deposit party -> storage", svc.owner.deposit(POKEMON))
	check("ownership now storage", svc.owner.location_of(POKEMON) == &"STORAGE")
	var before := state(svc.owner)
	panel.teach_button.pressed.emit()
	check("stale party view cannot teach storage member", not panel.last_result.get("accepted", false)
		and panel.last_result.get("reason", "") == "creature_not_in_party"
		and state(svc.owner) == before)
	check("remove deposited creature from storage", svc.owner.storage.remove_creature(POKEMON))
	check("ownership now absent", svc.owner.location_of(POKEMON) == &"")
	before = state(svc.owner)
	panel.teach_button.pressed.emit()
	check("removed pokemon cannot consume", not panel.last_result.get("accepted", false)
		and panel.last_result.get("reason", "") == "creature_not_owned"
		and state(svc.owner) == before)
	check("restore same creature identity", svc.owner.party.add_creature(creature))
	panel.refresh()
	check("party restoration allows original book", panel.select_creature(POKEMON)
		and panel.select_book(&"tm202") and not panel.teach_button.disabled)
	panel.queue_free()


func hit_05_all_slots_cancel() -> void:
	for index in range(4):
		var d := setup(&"metal_claw", true)
		if d.is_empty():
			continue
		var svc: Variant = d.service
		var panel: Variant = d.panel
		var before := state(svc.owner)
		check("replacement compulsory slot " + str(index), panel.teach_button.disabled)
		check("select candidate then cancel " + str(index), panel.select_replacement_slot(index)
			and panel.select_replacement_slot(-1))
		panel.teach_button.pressed.emit()
		check("cancellation consumes nothing " + str(index), not panel.last_result.get("accepted", false)
			and panel.last_result.get("reason", "") == "move_replacement_required"
			and state(svc.owner) == before)
		var original: CreatureInstance = svc.owner.owned_creature(POKEMON)
		var old_id: StringName = original.moveset[index].move_id
		var other_moves: Array = []
		for sl: BattleMoveSlot in original.moveset:
			other_moves.append({"id": sl.move_id, "pp": sl.current_pp, "max": sl.max_pp})
		check("select replacement " + str(index), panel.select_replacement_slot(index)
			and not panel.teach_button.disabled)
		panel.teach_button.pressed.emit()
		var current: CreatureInstance = svc.owner.owned_creature(POKEMON)
		var def: MoveDefinition = catalogs.move(&"metal_claw")
		check("slot replaced and one book consumed " + str(index), panel.last_result.get("accepted", false)
			and current.moveset[index].move_id == &"metal_claw"
			and svc.owner.inventory.quantity(&"tm31") == 1 and not current.has_move(old_id))
		check("new move base PP " + str(index), def != null
			and current.moveset[index].current_pp == def.pp and current.moveset[index].max_pp == def.pp)
		for k in range(4):
			if k == index:
				continue
			check("other move unchanged " + str(index) + "/" + str(k), current.moveset[k].move_id == other_moves[k].id
				and current.moveset[k].current_pp == other_moves[k].pp
				and current.moveset[k].max_pp == other_moves[k].max)
		panel.queue_free()


func hit_06_sort_filter() -> void:
	var d := load_all_books()
	if d.is_empty():
		return
	var svc: Variant = d.service
	var panel: Variant = d.panel
	var before := state(svc.owner)
	for mode in [1, 2, 3, 0]:
		panel.sort_mode.select(mode)
		panel.refresh()
		check("sort preserves item ID " + str(mode), panel._selected(panel.books) == &"tm202")
		check("no duplicate IDs after sort " + str(mode), panel.books.item_count == 229)
	var type_id := StringName(Presentation.presentacion(&"tm202", svc.profile, catalogs).get("type_id", ""))
	var filter_index := -1
	for i in range(1, panel.type_filter.item_count):
		if StringName(panel.type_filter.get_item_metadata(i)) != type_id:
			filter_index = i
			break
	check("different real type available", filter_index > 0)
	if filter_index > 0:
		panel.type_filter.select(filter_index)
		panel.refresh()
		check("filtered book is not silently substituted", panel._selected(panel.books) == &""
			and panel.teach_button.disabled and panel.books.item_count < 229)
		before = state(svc.owner)
		panel.teach_button.pressed.emit()
		check("filter change cannot spend another book", not panel.last_result.get("accepted", false)
			and state(svc.owner) == before)
	panel.type_filter.select(0)
	panel.refresh()
	check("restored all items and reselect by stable ID", panel.books.item_count == 229
		and panel.select_book(&"tm202"))
	check("increase stock for quantity sort", svc.owner.inventory.add(&"tm202", 5))
	panel.sort_mode.select(3)
	panel.refresh()
	check("descending stock sorts without changing ID", StringName(panel.books.get_item_metadata(0)) == &"tm202"
		and panel._selected(panel.books) == &"tm202")
	panel.queue_free()


func hit_07_negative_states() -> void:
	var d := setup()
	if d.is_empty():
		return
	var svc: Variant = d.service
	var panel: Variant = d.panel
	var original_content: Variant = svc.content
	var before := state(svc.owner)
	svc.guard = func(): return false
	panel.teach_button.pressed.emit()
	check("field locked refuses and conserves", panel.last_result.get("reason", "") == "field_locked"
		and state(svc.owner) == before)
	svc.guard = func(): return true
	svc.content = RejectMoves.new()
	panel._refresh_compatibility()
	check("move forbidden disables view", panel.teach_button.disabled
		and panel.compatibility_label.text.contains("no está permitido"))
	panel.teach_button.pressed.emit()
	check("forbidden move no cost", panel.last_result.get("reason", "") == "move_not_permitted"
		and state(svc.owner) == before)
	svc.content = original_content
	var species: CreatureSpecies = catalogs.species(d.species)
	var entries: Array = species.learnset.duplicate()
	species.learnset.clear()
	panel._refresh_compatibility()
	check("missing SV data does not guess", panel.teach_button.disabled
		and panel.compatibility_label.text.contains("Faltan datos"))
	panel.teach_button.pressed.emit()
	check("missing context no cost", panel.last_result.get("reason", "") == "species_machine_version_context_missing"
		and state(svc.owner) == before)
	for entry: LearnSetEntry in entries:
		species.learnset.append(entry)
	var creature: CreatureInstance = svc.owner.owned_creature(POKEMON)
	check("known move setup", creature.add_move(&"pain_split", catalogs))
	before = state(svc.owner)
	panel._refresh_compatibility()
	check("already known blocked", panel.teach_button.disabled and panel.compatibility_label.text.contains("Ya conoce"))
	panel.teach_button.pressed.emit()
	check("already known no cost", panel.last_result.get("reason", "") == "move_already_known"
		and state(svc.owner) == before)
	panel.queue_free()
	var incompatible_id := choose_species(&"pain_split", false)
	check("real incompatible species found", incompatible_id != &"")
	if incompatible_id != &"":
		var other: Variant = new_service(incompatible_id, &"pain_split", false)
		check("incompatible book added", other.owner.inventory.add(&"tm202", 1))
		var incompatible: Variant = mount(other)
		check("incompatible book targeted", incompatible.select_book(&"tm202"))
		before = state(other.owner)
		incompatible.teach_button.pressed.emit()
		check("incompatible no cost", incompatible.last_result.get("reason", "") == "machine_incompatible"
			and state(other.owner) == before)
		incompatible.queue_free()


func hit_08_spanish_audit() -> void:
	var d := load_all_books()
	if d.is_empty():
		return
	var svc: Variant = d.service
	var panel: Variant = d.panel
	var profile: Dictionary = svc.profile.get("machine_rows", {})
	var total := 0
	var verified := 0
	var fallback := 0
	var fallback_id := &""
	for raw: Variant in profile.keys():
		var id := StringName(raw)
		var versions: Dictionary = profile[raw]
		if not versions.has("scarlet-violet"):
			continue
		var item: Dictionary = Presentation.presentacion(id, svc.profile, catalogs)
		check("book label and type present " + String(id), item.get("disponible", false)
			and String(item.get("nombre_movimiento", "")).length() > 0
			and String(item.get("nombre_tipo", "")).length() > 0)
		total += 1
		var move_id := String(item.get("move_id", ""))
		if move_id in ["pain_split", "metal_claw"] or SpanishGameText.CORE_MOVE_NAMES.has(move_id):
			verified += 1
		else:
			fallback += 1
			if fallback_id == &"":
				fallback_id = id
	check("229 canonical text presentations audited", total == 229 and verified + fallback == 229)
	check("unverified names explicitly tracked", fallback > 0 and fallback_id != &"")
	if fallback_id != &"":
		check("select text fallback book", panel.select_book(fallback_id))
		check("unverified translation visibly labeled", panel.translation_label.text.contains("no verificada"))
	check("select verified pilot Spanish", panel.select_book(&"tm202"))
	check("verified Spanish has no warning", panel.translation_label.text == ""
		and panel.book_label.text.contains("Divide Dolor"))
	print("W05_BOOKS_V3_TRANSLATIONS audited=%d verified_spanish=%d unverified_fallback=%d invented=0" %
		[total, verified, fallback])
	panel.queue_free()


func hit_09_save_open_panel() -> void:
	var d := setup()
	if d.is_empty():
		return
	var svc: Variant = d.service
	var panel: Variant = d.panel
	check("independent second stock", svc.owner.inventory.add(&"tm31", 1))
	clear_save()
	var repo := SaveGameRepository.new()
	var written: SaveResult = repo.save_collection(SAVE, svc.owner)
	check("manual SaveV2 open panel", written.ok)
	if written.ok:
		var loaded: LoadResult = repo.load(SAVE)
		check("reload SaveV2 while panel remains open", loaded.ok)
		if loaded.ok:
			var owner := PlayerCollection.new()
			owner.party = loaded.party
			owner.storage = loaded.storage
			owner.inventory = loaded.inventory
			check("restored stock and owner", owner.inventory.quantity(&"tm202") == 2
				and owner.inventory.quantity(&"tm31") == 1
				and owner.location_of(POKEMON) == &"PARTY")
			check("rebind original service to loaded SaveV2", svc.configure(owner, catalogs, func(): return true))
			check("rebind panel to loaded service", panel.bind_existing_service(svc))
			check("selected same book after reload", panel._selected(panel.books) == &"tm202")
			check("remove loaded stock in another action", owner.inventory.remove(&"tm202", 2))
			var before := state(owner)
			panel.teach_button.pressed.emit()
			check("loaded stale UI no teach", not panel.last_result.get("accepted", false)
				and panel.last_result.get("reason", "") == "item_not_owned" and state(owner) == before)
			panel.refresh()
			check("loaded absent item no fallback book", panel._selected(panel.books) == &""
				and owner.inventory.quantity(&"tm31") == 1)
			check("write loaded state manually", repo.save_collection(SAVE, owner).ok)
			var after: LoadResult = repo.load(SAVE)
			check("loaded quantity kept across second SaveV2", after.ok
				and after.inventory.quantity(&"tm202") == 0
				and after.inventory.quantity(&"tm31") == 1
				and after.party.get_creature(POKEMON) != null)
	clear_save()
	panel.queue_free()


func _run() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
	check("canonical source exists", data is Dictionary)
	if data is Dictionary:
		catalogs = GameData.from_dict(data).to_definition_catalog()
		check("canonical definitions", catalogs != null)
		check("real content policy", policy.load_local())
		if catalogs != null and policy.valid:
			var tasks := [
				{"n": 1, "name": "rendimiento_229", "call": Callable(self, "hit_01_performance")},
				{"n": 2, "name": "apertura_cierre", "call": Callable(self, "hit_02_lifecycle")},
				{"n": 3, "name": "stock_obsoleto", "call": Callable(self, "hit_03_stock_stale")},
				{"n": 4, "name": "propietario_retirado", "call": Callable(self, "hit_04_owner_moved")},
				{"n": 5, "name": "cuatro_slots_cancelar", "call": Callable(self, "hit_05_all_slots_cancel")},
				{"n": 6, "name": "orden_tipo_stock", "call": Callable(self, "hit_06_sort_filter")},
				{"n": 7, "name": "rechazos", "call": Callable(self, "hit_07_negative_states")},
				{"n": 8, "name": "textos_es_fallback", "call": Callable(self, "hit_08_spanish_audit")},
				{"n": 9, "name": "SaveV2_abierto", "call": Callable(self, "hit_09_save_open_panel")},
			]
			for task: Dictionary in tasks:
				var prior_checks := checks
				var prior_failures := failures.size()
				var call: Callable = task["call"]
				call.call()
				var is_ok := failures.size() == prior_failures and checks > prior_checks
				completed += 1
				if is_ok:
					functional_hits += 1
				else:
					blocked_hits += 1
				print("W05_BOOKS_AUTORUN_V3_HIT block=%02d name=%s status=%s checks=%d" %
					[int(task.n), String(task.name), "CERTIFICABLE" if is_ok else "FAIL", checks - prior_checks])
			var baseline := failures.size()
			check("10 hit matrix 9 independent + final gate", completed == 9 and HITS == 10)
			check("all nine positive before final CI gate", functional_hits == 9 and blocked_hits == 0)
			completed += 1
			if failures.size() == baseline:
				functional_hits += 1
			else:
				blocked_hits += 1
			print("W05_BOOKS_AUTORUN_V3_HIT block=10 name=ci_resiliencia status=%s checks=%d" %
				["CERTIFICABLE" if failures.size() == baseline else "FAIL", checks - prior_checks])
	if failures.is_empty() and completed == HITS and functional_hits == HITS:
		print("W05_BOOKS_AUTORUN_V3_GODOT PASS blocks=10 functional=10 blocked=0 checks=%d" % checks)
		quit(0)
	else:
		print("W05_BOOKS_AUTORUN_V3_GODOT FAIL blocks=%d functional=%d blocked=%d checks=%d errors=%s" %
			[completed, functional_hits, blocked_hits, checks, str(failures)])
		quit(1)
