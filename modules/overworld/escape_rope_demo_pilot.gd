class_name EscapeRopeDemoPilot
extends RefCounted

# CAMP006/W03: demo-only, non-consuming navigation pilot. The shared world,
# inventory, item bag and SaveV2 APIs are deliberately NOT changed here.
# An eventual inventory transaction belongs to the IA6-owned integration seam.
const ITEM_ID := &"escape_rope"
const ANCHORS := {
	&"cave": {"portal": "CaveExit", "marker": "SurfaceCaveReturn",
		"portal_id": &"cave_surface_exit"},
	&"building": {"portal": "BuildingExit", "marker": "SurfaceBuildingReturn",
		"portal_id": &"building_surface_exit"},
}


static func preview(field: Node2D) -> Dictionary:
	if field == null or not field.has_method("technical_region_id"):
		return _deny("missing_world")
	if not field.has_method("field_can_use_items") or not field.field_can_use_items():
		return _deny("field_locked")
	var region: StringName = field.technical_region_id()
	if not ANCHORS.has(region):
		return _deny("no_return_anchor")
	var config: Dictionary = ANCHORS[region]
	var portal := field.get_node_or_null(NodePath(config.portal)) as OverworldPortal
	var marker := field.get_node_or_null(NodePath(config.marker)) as Marker2D
	var traversal := field.get_node_or_null("TraversalController") as OverworldTraversalController
	if portal == null or marker == null or traversal == null or traversal.is_busy():
		return _deny("missing_or_busy_traversal")
	if portal.portal_id != config.portal_id or portal.source_region_id != region 			or portal.destination_region_id != &"surface" 			or portal.destination_node() != marker:
		return _deny("invalid_return_anchor")
	if not traversal._destination_is_clear(marker.global_position):
		return _deny("return_anchor_occupied")
	return {"ok": true, "region_id": String(region),
		"destination_region_id": "surface",
		"anchor_id": String(config.marker), "portal": portal,
		"destination": marker.global_position}


static func return_to_demo_anchor(field: Node2D) -> Dictionary:
	var plan := preview(field)
	if not bool(plan.get("ok", false)):
		return plan
	var traversal := field.get_node("TraversalController") as OverworldTraversalController
	var portal := plan.portal as OverworldPortal
	# Travel passes through the actual collision/locking/telemetry controller.
	# No bag item is spent until IA6 supplies an atomic inventory/world commit.
	var moved: bool = await traversal.traverse_portal(portal)
	if not moved:
		return _deny("traversal_rejected")
	var success: bool = field.technical_region_id() == &"surface" 			and field.player.global_position.is_equal_approx(plan.destination)
	if not success:
		return _deny("postcondition_failed")
	return {"ok": true, "status": "PILOT_TRAVERSED_NO_SPEND",
		"anchor_id": plan.anchor_id,
		"destination_region_id": "surface",
		"position": [field.player.global_position.x, field.player.global_position.y]}


static func _deny(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "status": "REJECTED_NO_SPEND"}
