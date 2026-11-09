extends SceneTree

# IA6 regression: real field bag mint -> native SaveV2 envelope -> manual reload.
# This catches the formerly invalid comparison against original nature_id.
var checks := 0
var errors: Array[String] = []
var done := false
const SAVE := "user://ia6_mint_native_save_20261109.json"

func _initialize() -> void:
	call_deferred("_run")
	create_timer(220.0).timeout.connect(func():
		if not done:
			push_error("IA6_MINT_FIELD_SAVE timeout")
			quit(2)
	)

func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		errors.append(label)
		push_error("IA6_MINT_FIELD_SAVE_FAIL " + label)

func _finish(scene: Node2D) -> void:
	for suffix: String in ["", ".tmp", ".bak"]:
		var file := SAVE + suffix
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	if scene != null:
		scene.queue_free()
		await process_frame
	done = true
	if errors.is_empty():
		print("IA6_MINT_FIELD_SAVE PASS checks=", checks, " features=real_bag,original_nature,effective_nature,savev2")
		quit(0)
	else:
		print("IA6_MINT_FIELD_SAVE FAIL checks=", checks, " errors=", JSON.stringify(errors))
		quit(1)

func _run() -> void:
	var scene: Node2D = load("res://scenes/visual/field_demo.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	check("demo_started", scene.is_demo_ready())
	if not scene.is_demo_ready():
		await _finish(scene)
		return
	scene.player.set_physics_process(false)
	var owner: PlayerCollection = scene.field_collection()
	var defs: DefinitionCatalog = scene.field_definitions()
	var bag: Control = scene._item_bag
	check("owner_definitions_bag", owner != null and defs != null and bag != null)
	if owner == null or defs == null or bag == null:
		await _finish(scene)
		return
	var party: Array[CreatureInstance] = owner.party.get_creatures()
	check("real_party_not_empty", not party.is_empty())
	if party.is_empty():
		await _finish(scene)
		return
	var mon: CreatureInstance = party[0]
	var species: CreatureSpecies = defs.species(mon.species_id)
	check("real_species", species != null)
	if species == null:
		await _finish(scene)
		return
	var original_nature: StringName = mon.nature_id
	var original_hp: int = mon.current_hp
	var original_id: StringName = mon.instance_id
	var selected: StringName = &""
	var target: StringName = &""
	var desired: Dictionary = {}
	for candidate: Dictionary in [
		{"item": &"lonely_mint", "nature": &"lonely"},
		{"item": &"mild_mint", "nature": &"mild"},
		{"item": &"naive_mint", "nature": &"naive"},
		{"item": &"gentle_mint", "nature": &"gentle"}]:
		var candidate_stats: Dictionary = StatCalculator.compute(
			species.base_stat_block(), mon.ivs, mon.evs, candidate.nature, mon.level).to_dict()
		if candidate_stats != mon.stats.to_dict():
			selected = candidate.item
			target = candidate.nature
			desired = candidate_stats
			break
	check("mint_changes_real_stats", selected != &"")
	if selected == &"":
		await _finish(scene)
		return
	check("mint_add_stock", owner.inventory.add(selected, 2))
	check("real_bag_open", bag.open_bag() and bag.visible)
	var index := -1
	for i in bag._items.item_count:
		if StringName(bag._items.get_item_metadata(i)) == selected:
			index = i
	check("mint_in_bag", index >= 0)
	if index < 0:
		await _finish(scene)
		return
	bag._items.select(index)
	bag._refresh_choices()
	var creature_index := -1
	for i in bag._targets.item_count:
		if StringName(bag._targets.get_item_metadata(i)) == original_id: creature_index = i
	check("target_in_bag", creature_index >= 0)
	if creature_index >= 0:
		bag._targets.select(creature_index)
		bag._refresh_choices()
	check("real_use_action_enabled", not bag._use.disabled)
	bag._use.pressed.emit()
	var minted: CreatureInstance = owner.owned_creature(original_id)
	check("real_bag_applied_mint", minted != null and minted.effective_nature_id == target
		and minted.nature_id == original_nature and minted.stats.to_dict() == desired)
	check("preserves_hp_identity", minted != null and minted.instance_id == original_id
		and minted.current_hp == original_hp)
	check("consumes_one", owner.inventory.quantity(selected) == 1)
	bag.hide()
	var bridge: Node = scene._native_battles
	bridge.save_path = SAVE
	for suffix: String in ["", ".tmp", ".bak"]:
		var p := SAVE + suffix
		if FileAccess.file_exists(p): DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	var stored: bool = bridge.save_game()
	check("field_native_save_accepts_effective_nature", stored)
	if stored:
		var reloaded: bool = await bridge.load_game()
		var fresh: PlayerCollection = scene.field_collection()
		var restored: CreatureInstance = fresh.owned_creature(original_id) if fresh != null else null
		check("manual_save_load", reloaded)
		check("savev2_preserves_nature_roles", restored != null and restored.nature_id == original_nature
			and restored.effective_nature_id == target and restored.stats.to_dict() == desired)
		check("savev2_preserves_held_inventory", fresh != null and fresh.inventory.quantity(selected) == 1)
		check("savev2_preserves_identity_hp", restored != null and restored.instance_id == original_id
			and restored.current_hp == original_hp)
	await _finish(scene)
