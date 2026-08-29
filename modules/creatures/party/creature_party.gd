class_name CreatureParty
extends RefCounted

# Persistent party roster. Pure domain state: holds references to the SAME CreatureInstance
# objects that battle/progression mutate. NOT a Node, NOT an autoload, NOT UI.
#
# Identity is by `instance_id` (never array index, Resource UID, NodePath or species_id).
# Two Pikachu can coexist; they are distinguished by instance_id.

var party_ruleset: PartyRuleset = PartyRuleset.new()
var _order: Array[StringName] = []        # ordered instance_ids (roster order / active contract)
var _by_id: Dictionary = {}               # instance_id -> CreatureInstance


func _sn_to_str(a: Array[StringName]) -> Array[String]:
	var out: Array[String] = []
	for x in a:
		out.append(String(x))
	return out


# --- Mutations ------------------------------------------------------------

func add_creature(creature: CreatureInstance) -> bool:
	if creature == null:
		return false
	if _by_id.has(creature.instance_id):
		return false
	if is_full():
		return false
	_by_id[creature.instance_id] = creature
	_order.append(creature.instance_id)
	return true


# Replace the object behind an existing stable identity without changing roster order.
# This is the ownership-safe handoff used when Progression returns a new CreatureInstance
# for an evolution while preserving instance_id. It deliberately refuses a missing/empty ID.
func replace_same_identity(creature: CreatureInstance) -> bool:
	if creature == null or creature.instance_id == &"":
		return false
	if not _by_id.has(creature.instance_id):
		return false
	_by_id[creature.instance_id] = creature
	return true


func remove_creature(instance_id: StringName) -> bool:
	if not _by_id.has(instance_id):
		return false
	_by_id.erase(instance_id)
	_order.erase(instance_id)
	return true


# Swap two roster positions by instance_id.
func swap(id_a: StringName, id_b: StringName) -> bool:
	if id_a == id_b:
		return false
	if not _by_id.has(id_a) or not _by_id.has(id_b):
		return false
	var ia := _order.find(id_a)
	var ib := _order.find(id_b)
	var tmp := _order[ia]
	_order[ia] = _order[ib]
	_order[ib] = tmp
	return true


# Reorder the whole roster. The provided ids must be an EXACT permutation of the current set:
# same count, no duplicate instance_id, no unknown id, no missing id.
func reorder(ordered_ids: Array[StringName]) -> bool:
	if ordered_ids.size() != _by_id.size():
		return false
	var seen := {}
	for id in ordered_ids:
		if seen.has(id):
			return false  # duplicate instance_id -> not a permutation
		if not _by_id.has(id):
			return false  # unknown id -> not the current set
		seen[id] = true
	_order = ordered_ids.duplicate()
	return true


# --- Queries --------------------------------------------------------------

func get_creature(instance_id: StringName) -> CreatureInstance:
	return _by_id.get(instance_id, null)


func contains_instance_id(instance_id: StringName) -> bool:
	return _by_id.has(instance_id)


func size() -> int:
	return _order.size()


func is_full() -> bool:
	return _order.size() >= party_ruleset.MAX_PARTY


func is_empty() -> bool:
	return _order.is_empty()


func get_creatures() -> Array[CreatureInstance]:
	var out: Array[CreatureInstance] = []
	for id in _order:
		out.append(_by_id[id])
	return out


func get_ordered_ids() -> Array[StringName]:
	return _order.duplicate()


func get_active() -> CreatureInstance:
	if _order.is_empty():
		return null
	return _by_id.get(_order[0], null)


# --- Serialization --------------------------------------------------------

func to_dict() -> Dictionary:
	var creatures: Array[Dictionary] = []
	for id in _order:
		creatures.append(_by_id[id].to_dict())
	return {
		"schema_version": party_ruleset.SCHEMA_VERSION,
		"ruleset_id": String(party_ruleset.ID),
		"ordered_instance_ids": _sn_to_str(_order),
		"creatures": creatures,
	}


static func from_dict(d: Dictionary, party_ruleset: PartyRuleset = null) -> CreatureParty:
	var pr := party_ruleset if party_ruleset != null else PartyRuleset.new()
	var p := CreatureParty.new()
	p.party_ruleset = pr
	var by_id: Dictionary = {}
	for cd in d.get("creatures", []):
		var c := CreatureInstance.from_dict(cd)
		by_id[c.instance_id] = c
	# Defensive deserialization:
	# - preserve first valid occurrence of each ordered id;
	# - ignore later duplicates and any id not present in `creatures`;
	# - then append any creature missing from the order (in dict order).
	var order: Array[StringName] = []
	var seen: Dictionary = {}
	for sid in d.get("ordered_instance_ids", []):
		var s := StringName(sid)
		if by_id.has(s) and not seen.has(s):
			order.append(s)
			seen[s] = true
	for cid in by_id.keys():
		if not seen.has(cid):
			order.append(cid)
			seen[cid] = true
	# Defensive: never exceed the roster limit even if data is corrupt.
	while order.size() > pr.MAX_PARTY:
		var extra := order[order.size() - 1]
		order.pop_back()
		by_id.erase(extra)
	# Invariant: every ordered id exists exactly once and _order.size() == _by_id.size().
	p._order = order
	p._by_id = by_id
	return p
