class_name OverworldEncounterDirector
extends RefCounted

# Application boundary between completed overworld steps and WildAdventureSession.
#
# Responsibilities are intentionally narrow:
# - map stable zone_id -> validated WildEncounterTable;
# - reject non-encounter/unknown zones without consuming RNG;
# - call the already validated WildAdventureSession only while it is READY;
# - report whether a logical Battle actually started.
#
# It owns no movement, collision, capture, battle, progression or save rules.

var session: WildAdventureSession
var _tables: Dictionary = {}
var _encounter_rng: RandomNumberGenerator
var _next_battle_seed: int = 12000


func _init(
	p_session: WildAdventureSession = null,
	p_encounter_rng: RandomNumberGenerator = null,
	p_first_battle_seed: int = 12000,
) -> void:
	session = p_session
	_encounter_rng = p_encounter_rng if p_encounter_rng != null else RandomNumberGenerator.new()
	if p_encounter_rng == null:
		_encounter_rng.seed = 1
	_next_battle_seed = p_first_battle_seed


func register_zone(table: WildEncounterTable) -> bool:
	if session == null or table == null or table.zone_id == &"":
		return false
	if _tables.has(table.zone_id):
		return false
	var validation := table.validate(session.catalogs)
	if not validation.ok:
		return false
	_tables[table.zone_id] = table
	return true


func has_zone(zone_id: StringName) -> bool:
	return _tables.has(zone_id)


func registered_zone_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for raw_id in _tables.keys():
		out.append(StringName(raw_id))
	out.sort()
	return out


func on_step(zone_id: StringName) -> OverworldStepOutcome:
	var out := OverworldStepOutcome.new()
	out.zone_id = zone_id
	if zone_id == &"":
		out.reason = "no_encounter_zone"
		return out
	if session == null:
		out.reason = "missing_adventure_session"
		return out
	# A completed/captured battle must explicitly return to exploration first. This prevents the
	# world layer from silently skipping the lifecycle boundary introduced in FASE 11.
	if session.status != WildAdventureSession.READY:
		out.reason = "adventure_not_ready"
		return out
	var table := _tables.get(zone_id, null) as WildEncounterTable
	if table == null:
		out.reason = "unknown_encounter_zone"
		return out

	out.rolled = true
	var result := session.begin_encounter(table, _encounter_rng, _next_battle_seed)
	out.encounter = result
	if result == null:
		out.reason = "missing_encounter_result"
		return out
	if result.status == WildEncounterResult.INVALID:
		out.reason = result.reason
		return out
	if result.status == WildEncounterResult.ENCOUNTER:
		out.battle_started = session.has_active_battle()
		if out.battle_started:
			_next_battle_seed += 1
		else:
			out.reason = "encounter_without_battle"
	return out


func resume_exploration() -> bool:
	if session == null:
		return false
	if session.status == WildAdventureSession.READY:
		return true
	return session.reset_after_completion()
