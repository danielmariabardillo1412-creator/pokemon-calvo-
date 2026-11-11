extends "res://modules/inventory/field_item_service.gd"
# W04 V3 test-only fault injection. Never used in production.
# The first inventory publication is dropped AFTER owner replacement; the
# base evolve method must recognize mismatch and roll back both resources.
var fail_next_publish := true

func _publish_bag(staged: PlayerInventory) -> void:
    if fail_next_publish:
        fail_next_publish = false
        return
    super._publish_bag(staged)
