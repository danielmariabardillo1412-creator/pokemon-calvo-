extends "res://tests/gameplay/parallel_items_w05_book_ui_autorun_v3.gd"

# Separate V4 runner: every Spanish MT label must match original local PokeAPI
# names.es. Existing V1/V2 Godot suites remain responsible for 229 teaching
# positives, stock/PP/SaveV2. This adds view-level Spanish source validation.
const TABLE := "res://data/localization/machine_moves_es_sv_v1.json"


func _run() -> void:
	var original: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
	check("normalized gameplay source", original is Dictionary)
	var translations: Variant = JSON.parse_string(FileAccess.get_file_as_string(TABLE))
	check("ES localization file is valid", translations is Dictionary)
	if not (original is Dictionary and translations is Dictionary):
		print("W05_BOOKS_AUTORUN_V4_GODOT FAIL groups=0 translated=0 missing=229 checks=%d" % checks)
		quit(1)
		return
	catalogs = GameData.from_dict(original).to_definition_catalog()
	check("real catalog built", catalogs != null)
	check("content policy from project", policy.load_local())
	if catalogs == null or not policy.valid:
		quit(1)
		return
	var records: Dictionary = translations.get("entries", {})
	check("229 exact entries", records.size() == 229
		and translations.get("locale", "") == "es"
		and translations.get("version", "") == "scarlet-violet")
	var setup_case := load_all_books()
	if setup_case.is_empty():
		quit(1)
		return
	var svc: Variant = setup_case.service
	var panel: Variant = setup_case.panel
	var before := state(svc.owner)
	var total_verified := 0
	var total_missing := 0
	for group in range(10):
		var start_id := group * 23 + 1
		var end_id := mini((group+1) * 23, 229)
		var valid := 0
		var missing := 0
		var checkpoint := failures.size()
		var before_checks := checks
		for n in range(start_id, end_id+1):
			var item_id := StringName("tm%02d" % n)
			var move_id := StringName(svc.profile["machine_rows"][String(item_id)]["scarlet-violet"])
			var row: Variant = records.get(String(move_id), null)
			check("sourced row " + String(item_id), row is Dictionary)
			if not row is Dictionary:
				missing += 1
				continue
			var es_name := String(row.get("nombre_es", ""))
			var api_id := int(row.get("source_api_id", 0))
			var local: Dictionary = MachineMovesEsSvW05.resolve(move_id, "")
			var presented: Dictionary = Presentation.presentacion(item_id, svc.profile, catalogs)
			check("verified local source " + String(item_id), es_name != ""
				and local.get("name", "") == es_name
				and local.get("verified_es", false)
				and local.get("source_api_id", 0) == api_id)
			check("presentation authentic ES " + String(item_id),
				presented.get("disponible", false)
				and presented.get("nombre_movimiento", "") == es_name
				and presented.get("traduccion_es_verificada", false)
				and presented.get("nombre_source_api_id", 0) == api_id
				and String(presented.get("etiqueta", "")).contains(es_name))
			check("panel selection real ID " + String(item_id), panel.select_book(item_id)
				and panel._selected(panel.books) == item_id)
			check("panel actual Spanish title " + String(item_id), panel.book_label.text.contains(es_name)
				and panel.books.get_item_text(panel.books.selected).contains(es_name)
				and panel.translation_label.text == "")
			var source_path := "res://data/api/v2/move/%d/index.json" % api_id
			var source: Variant = JSON.parse_string(FileAccess.get_file_as_string(source_path))
			check("source document intact " + String(item_id), source is Dictionary)
			if source is Dictionary:
				check("PokeAPI canonical identity " + String(item_id), source.get("id", 0) == api_id
					and source.get("name", "") == String(move_id).replace("_", "-"))
				var matches := 0
				for entry: Dictionary in source.get("names", []):
					if String(entry.get("language", {}).get("name", "")) == "es":
						matches += 1
						check("exact PokeAPI source ES " + String(item_id), entry.get("name", "") == es_name)
				check("exactly one Spanish locale row " + String(item_id), matches == 1)
			valid += 1
		total_verified += valid
		total_missing += missing
		var ok := failures.size() == checkpoint and valid == end_id-start_id+1 and missing == 0
		print("W05_BOOKS_AUTORUN_V4_GROUP block=%02d status=%s ids=%d translated=%d missing=%d checks=%d" %
			[group+1, "CERTIFICABLE" if ok else "FAIL", end_id-start_id+1, valid, missing,
			checks-before_checks])
	check("ES lookup never guessed for absent move",
		not MachineMovesEsSvW05.resolve(&"w05_nonexistent_move", "Sin traducción").get("verified_es", true)
		and MachineMovesEsSvW05.resolve(&"w05_nonexistent_move", "Sin traducción").get("name", "") == "Sin traducción")
	check("local light screen correction, global code unchanged",
		MachineMovesEsSvW05.resolve(&"light_screen", "").get("name", "") == "Pantalla de Luz"
		and SpanishGameText.CORE_MOVE_NAMES.get("light_screen", "") == "Pantalla Luz")
	check("all 229 labels audited", total_verified == 229 and total_missing == 0)
	check("presentation does not consume stock", state(svc.owner) == before)
	check("known pilot local es", panel.select_book(&"tm202")
		and panel.book_label.text.contains("Divide Dolor")
		and panel.translation_label.text == "")
	check("teach valid book still permitted", not panel.teach_button.disabled)
	panel.teach_button.pressed.emit()
	check("teaching remains one unit and translated", panel.last_result.get("accepted", false)
		and svc.owner.inventory.quantity(&"tm202") == 1
		and panel.result_label.text.contains("Divide Dolor"))
	var final_before := state(svc.owner)
	panel.teach_button.pressed.emit()
	check("duplicate teaching still rejected", not panel.last_result.get("accepted", false)
		and state(svc.owner) == final_before)
	clear_save()
	var saves := SaveGameRepository.new()
	check("manual SaveV2 after ES teaching", saves.save_collection(SAVE, svc.owner).ok)
	var loaded: LoadResult = saves.load(SAVE)
	check("ES presentation does not corrupt SaveV2", loaded.ok
		and loaded.inventory.quantity(&"tm202") == 1
		and loaded.party.get_creature(POKEMON) != null)
	clear_save()
	panel.queue_free()
	if failures.is_empty() and total_verified == 229:
		print("W05_BOOKS_AUTORUN_V4_GODOT PASS groups=10 translated=229 missing=0 checks=%d" % checks)
		quit(0)
	else:
		print("W05_BOOKS_AUTORUN_V4_GODOT FAIL groups=10 translated=%d missing=%d checks=%d errors=%s" %
			[total_verified, total_missing, checks, str(failures)])
		quit(1)
