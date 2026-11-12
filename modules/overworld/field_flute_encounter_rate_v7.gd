extends RefCounted
## W03 V7: opt-in Gen III/IV encounter-rate flutes. This is NOT enabled globally.
## No map-lifetime claim until a real map ID / transition source is proven.
const PROFILE: StringName = &"calvo_flutes_classic_encounter_rate_v1"
const BLACK: StringName = &"black_flute"
const WHITE: StringName = &"white_flute"
const MAX_BP := 10000
const SCHEMA_VERSION := 1

var active_id: StringName = &""

static func supports(item_id: StringName) -> bool:
	return item_id == BLACK or item_id == WHITE

func activate(item_id: StringName, profile: StringName) -> bool:
	if profile != PROFILE or not supports(item_id):
		return false
	active_id = item_id
	return true

func clear() -> void:
	active_id = &""

func modified_chance_bp(base_bp: int, profile: StringName) -> int:
	if profile != PROFILE or base_bp < 0 or base_bp > MAX_BP:
		return base_bp
	if active_id == BLACK:
		return clampi(roundi(float(base_bp) * 0.5), 0, MAX_BP)
	if active_id == WHITE:
		return clampi(roundi(float(base_bp) * 1.5), 0, MAX_BP)
	return base_bp

func prepare_table(table: WildEncounterTable, profile: StringName) -> WildEncounterTable:
	if table == null or table.corrupted or profile != PROFILE or active_id == &"":
		return table
	var copy := WildEncounterTable.from_dict(table.to_dict())
	if copy.corrupted:
		return table
	copy.encounter_chance_bp = modified_chance_bp(copy.encounter_chance_bp, profile)
	if not copy.validate().ok:
		return table
	return copy

func to_dict() -> Dictionary:
	return {"schema_version": SCHEMA_VERSION, "active_id": String(active_id)}

func validate_snapshot(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var snapshot: Dictionary = value
	var version: Variant = snapshot.get("schema_version")
	var item: Variant = snapshot.get("active_id")
	return (version is int or version is float) and is_finite(float(version)) and version == SCHEMA_VERSION and item is String and (item == "" or supports(StringName(item)))

func restore(value: Variant) -> bool:
	if not validate_snapshot(value):
		return false
	var snapshot: Dictionary = value
	active_id = StringName(snapshot["active_id"])
	return true
