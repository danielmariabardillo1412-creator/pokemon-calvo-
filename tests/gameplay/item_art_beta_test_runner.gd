extends SceneTree

const Art = preload("res://scenes/visual/item_art_catalog.gd")
var output := "res://.godot/item_art_beta_v1/"
var checks := 0
var errors: Array[String] = []
var scene: Node2D
var capture := false
var reviewed_v5 := false


func _initialize() -> void:
	capture = "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	if "--art-expansion-v2" in OS.get_cmdline_user_args(): output = "res://.godot/item_art_expansion_v2/"
	if "--art-utility-v3" in OS.get_cmdline_user_args(): output = "res://.godot/item_art_utility_v3/"
	reviewed_v5 = "--art-reviewed-v5" in OS.get_cmdline_user_args()
	if reviewed_v5: output = "res://.godot/item_art_reviewed_v5/"
	call_deferred("_run")


func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok: errors.append(label); push_error(label)


func state() -> String:
	return JSON.stringify({"inventory": scene._session.player.inventory.to_dict(), "party": scene._session.player.party.get_creatures().map(func(c): return c.to_dict()), "rng": scene._director._encounter_rng.state})


func snapshot(name: String) -> void:
	if not capture: return
	await process_frame; await process_frame
	await RenderingServer.frame_post_draw
	check("GPU screenshot " + name, root.get_texture().get_image().save_png(output + name + ".png") == OK)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	check("original beta coverage retained", Art.rows().size() >= 364)
	if "--art-expansion-v2" in OS.get_cmdline_user_args() or "--art-utility-v3" in OS.get_cmdline_user_args() or reviewed_v5:
		var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/current/ITEM_ART_EXPANSION_V2_PLAN.json"))
		check("609 expanded beta entries retained", Art.rows().size() >= 609)
		for id: String in plan.target_ids: check("planned expansion item " + id, Art.rows().has(id))
		for id: String in plan.excluded_art_ids: check("banned Z crystal not imported " + id, not Art.rows().has(id))
		for id: String in plan.deferred_art_ids: check("deferred item not enabled by art " + id, not Art.rows().has(id))
		check("generic Normalium Z retained for damage", Art.rows().has("normalium_z_held") and Art.rows().has("normalium_z_bag"))
		check("Absolite Z is a Mega Stone", Art.rows().absolite_z.family == "MEGA_STONE")
		check("Z bag and held keep distinct entries", Art.rows().firium_z_bag.family == "Z_BAG_TOKEN" and Art.rows().firium_z_held.family == "Z_CRYSTAL")
	if "--art-utility-v3" in OS.get_cmdline_user_args() or reviewed_v5:
		var utility: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/current/ITEM_ART_UTILITY_V3_PLAN.json"))
		check("654 utility beta entries retained", Art.rows().size() >= 654)
		for id: String in utility.target_ids: check("planned utility artwork " + id, Art.rows().has(id))
		for id: String in utility.excluded_art_ids: check("decorative leaf letter not imported " + id, not Art.rows().has(id))
		for id: String in utility.deferred_content_ids: check("undecided content not imported " + id, not Art.rows().has(id))
		for id: String in utility.deferred_style_ids:
			if Art.rows().has(id):
				var generated: Dictionary = Art.rows()[id]
				check("style gap has explicit generated provenance " + id, generated.source == "GENERATED" and generated.has("generated_reference_sha256") and generated.has("generation_prompts"))
				if generated.has("generated_reference"):
					check("generated item retains original reference " + id, FileAccess.get_sha256(generated.generated_reference) == generated.generated_reference_sha256)
			else:
				check("unresolved style remains absent " + id, true)
		check("functional doll retained", Art.rows().has("poke_doll"))
		check("bottle caps retained despite loot category", Art.rows().has("bottle_cap") and Art.rows().has("gold_bottle_cap"))
	if reviewed_v5:
		var reviewed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/current/ITEM_ART_REVIEWED_V5_PLAN.json"))
		check("1011 reviewed entries installed", Art.rows().size() == reviewed.expected_total_entries)
		for id: String in reviewed.target_ids: check("reviewed image installed " + id, Art.rows().has(id))
		for id: String in reviewed.generated_ids: check("generated source identified " + id, Art.rows()[id].source == "GENERATED")
		for id: String in reviewed.conditional_small_reference_ids: check("small unselected reference not imported " + id, not Art.rows().has(id))
		var previous: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://.godot/item_art_reviewed_v5/before_manifest.json"))
		for id: String in previous.items: check("previous entry preserved " + id, Art.rows()[id] == previous.items[id])
		check("shared material art retains separate IDs", Art.rows().has("aipom_hair") and Art.rows().has("alomomola_mucus") and Art.rows().aipom_hair.sha256 == Art.rows().alomomola_mucus.sha256)
	var scope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/current/ITEM_ART_SCOPE.json"))
	var excluded: Dictionary = {}
	for r: Dictionary in scope.rows:
		if r.scope != "RETAIN_FOR_FUNCTIONAL_REVIEW": excluded[r.id] = true
	for id: String in Art.rows():
		var row: Dictionary = Art.rows()[id]
		check("permitted art ID " + id, not excluded.has(id))
		check("original source bytes " + id, FileAccess.get_sha256(row.texture) == row.sha256)
		var image := Art.texture(StringName(id))
		check("Godot texture " + id, image != null and image.get_width() == row.width and image.get_height() == row.height)
	check("no misleading image for an unknown ID", Art.texture(&"not_an_item") == null)
	check("Hisui and modern Heavy Balls stay distinct", Art.rows().heavy_ball.sha256 != Art.rows().laheavy_ball.sha256)
	check("Rokikos is explicitly provisional", Art.rows().pewter_crunchies.small_fallback)
	check("Genesect ROM marked for later historical redesign", Art.rows().burn_drive.historical_review)
	scene = load("res://scenes/visual/field_demo.tscn").instantiate(); root.add_child(scene)
	await process_frame; await physics_frame
	check("same project field boots", scene.is_demo_ready())
	var before := state()
	scene.toggle_pokemon_gallery()
	var gallery: Control = scene._pokemon_gallery
	check("two visual tabs in the existing gallery", gallery._tabs.get_tab_count() == 2)
	check("Pokemon preview remains present", gallery._arena != null and gallery._list.item_count > 1000)
	await snapshot("pokemon_tab")
	gallery._tabs.current_tab = 1
	check("item browser inside the existing modal", gallery._items.is_visible_in_tree() and not scene.player.movement_enabled)
	for id: String in ["burn_drive", "lapoke_ball", "heavy_ball", "laheavy_ball", "pewter_crunchies", "metal_alloy"]:
		check("find canonical item " + id, gallery._items.select_id(id))
		check("selected icon keeps identity " + id, gallery._items.selected_id == id and gallery._items._large.texture == Art.texture(StringName(id)))
	gallery._items.select_id("burn_drive")
	await snapshot("item_gallery")
	if "--art-expansion-v2" in OS.get_cmdline_user_args() or "--art-utility-v3" in OS.get_cmdline_user_args() or reviewed_v5:
		check("modern Mega image reachable", gallery._items.select_id("abomasite"))
		check("Mega preview states pending mechanic", gallery._items._detail.text.contains("pendiente"))
		await snapshot("mega_art")
		check("damaging Z crystal reachable", gallery._items.select_id("firium_z_held"))
		await snapshot("z_art")
	if "--art-utility-v3" in OS.get_cmdline_user_args() or reviewed_v5:
		check("new useful item reachable", gallery._items.select_id("bottle_cap"))
		await snapshot("utility_art")
	if reviewed_v5:
		check("generated mineral reachable", gallery._items.select_id("armorite_ore"))
		check("generated origin visible", gallery._items._detail.text.contains("Arte generado"))
		await snapshot("generated_mineral")
		check("generated Max Lure reachable", gallery._items.select_id("max_lure"))
		await snapshot("generated_lure")
		check("form item reachable", gallery._items.select_id("prison_bottle"))
		await snapshot("reviewed_form_art")
		check("shared material reachable", gallery._items.select_id("aipom_hair"))
		await snapshot("shared_material_art")
	var bridge: Node = scene._native_battles
	check("item tab blocks save without writing", not bridge.save_game())
	await scene._on_player_step_completed(Vector2(420, 150))
	check("art browsing preserves party, inventory and RNG", state() == before and not bridge.occupied())
	gallery._items._filter("no_such_art_item")
	check("empty search clears the previous image", gallery._items.selected_id.is_empty() and gallery._items._large.texture == null)
	scene.toggle_pokemon_gallery()
	check("closing item gallery restores movement", scene.player.movement_enabled)
	check("capture buttons use installed art", bridge.view._ball.icon == Art.texture(&"poke_ball") and bridge.view._master.icon == Art.texture(&"master_ball"))
	# Exercise the real map's native battle dialog; opening art does not issue an item command.
	var config: Dictionary = scene._active_config.duplicate(true); config.encounter_chance_percent = 100
	scene._on_configuration_applied(config)
	scene._session.player.inventory.add(&"potion", 1)
	scene.player.global_position = Vector2(420, 150)
	await scene._on_player_step_completed(scene.player.global_position)
	check("real native encounter opens", bridge.view.session != null and bridge.view.session.has_active_battle())
	if bridge.view.session != null and bridge.view.session.has_active_battle():
		bridge.view._playback.set_process(false)
		for _frame in 100:
			if not bridge.view._playback.is_playing(): break
			bridge.view._playback._advance(0.5); await process_frame
		bridge.view._refresh_view()
		var revision: int = bridge.view.session.revision
		var inventory_before := JSON.stringify(bridge.view.session.inventory.to_dict())
		bridge.view.open_medicine_bag()
		check("medicine selection displays its own art", bridge.view._medicine_items.item_count > 0 and bridge.view._medicine_icon.texture == Art.texture(StringName(bridge.view._medicine_items.get_item_metadata(bridge.view._medicine_items.selected))))
		check("opening medicine art does not consume or advance battle", bridge.view.session.revision == revision and JSON.stringify(bridge.view.session.inventory.to_dict()) == inventory_before)
		await snapshot("medicine_bag")
		bridge.view._medicine_popup.hide()
		await bridge.view.session.close()
	var file := FileAccess.open(output + ("gpu.json" if capture else "godot.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"status": "PASS" if errors.is_empty() else "FAIL", "checks": checks, "errors": errors, "images": Art.rows().size()}, "  ")); file.close()
	scene.queue_free(); await process_frame
	print("ITEM_ART_BETA ", "PASS" if errors.is_empty() else "FAIL", " checks=", checks, " images=", Art.rows().size())
	quit(0 if errors.is_empty() else 1)
