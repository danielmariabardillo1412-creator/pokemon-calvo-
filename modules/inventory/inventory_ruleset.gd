class_name InventoryRuleset
extends RefCounted

# Canonical bag policy for calvo_inventory_v1. Pure domain rules: no UI, no Nodes, no autoload.
const ID := &"calvo_inventory_v1"
const SCHEMA_VERSION := 1
const MAX_STACK := 999

static func is_valid_item_id(item_id: StringName) -> bool:
	return item_id != &""

static func is_valid_quantity(quantity: int) -> bool:
	return quantity >= 0 and quantity <= MAX_STACK

static func is_valid_stored_quantity(quantity: int) -> bool:
	# Serialized entries are sparse: zero-count items are omitted.
	return quantity > 0 and quantity <= MAX_STACK
