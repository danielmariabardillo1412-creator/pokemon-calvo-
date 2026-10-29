extends OptionButton

# A view of the staged battle inventory; no capture rules or mutations here.
func selected_ball() -> StringName:
	return StringName(get_item_metadata(selected)) if selected >= 0 else &""

func render_balls(inventory: PlayerInventory, catalogs: DefinitionCatalog, locked: bool) -> void:
	var previous := selected_ball()
	clear()
	for id: StringName in CaptureRuleset.ordered_ball_ids():
		if id == &"master_ball": continue # Existing dedicated button is retained.
		var count := inventory.quantity(id)
		add_item("%s · %d" % [SpanishGameText.item_name(id, catalogs), count])
		set_item_metadata(item_count - 1, String(id))
		set_item_disabled(item_count - 1, count == 0)
		if id == previous: select(item_count - 1)
	disabled = locked
