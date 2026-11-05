extends RefCounted
## W03 CAMP006 block03: standalone field effect, not yet connected to shared encounter producer.
## Step counting only from real OverworldPlayer.step_completed signal.
const DURATIONS := {&"repel": 100, &"super_repel": 200, &"max_repel": 250}
var active_id: StringName = &""
var remaining_steps: int = 0
var _player: OverworldPlayer = null

func attach(player: OverworldPlayer) -> bool:
	if player == null: return false
	if _player != null and _player != player: return false
	if _player == player: return true
	_player = player
	_player.step_completed.connect(_on_real_step)
	return true

func detach() -> void:
	if _player != null and _player.step_completed.is_connected(_on_real_step):
		_player.step_completed.disconnect(_on_real_step)
	_player = null

func start(item_id: StringName) -> Dictionary:
	if not DURATIONS.has(item_id): return {"accepted": false, "reason": "unsupported_item"}
	if remaining_steps > 0: return {"accepted": false, "reason": "repel_already_active"}
	active_id = item_id
	remaining_steps = DURATIONS[item_id]
	return {"accepted": true, "duration": remaining_steps, "item_id": String(item_id)}

func _on_real_step(_position: Vector2) -> void:
	if remaining_steps <= 0: return
	remaining_steps -= 1
	if remaining_steps == 0: active_id = &""

func blocks_level(wild_level: int, leader_level: int) -> bool:
	if remaining_steps <= 0 or leader_level <= 0 or wild_level <= 0: return false
	# Equal/higher-level encounters are permitted; only weaker wild Pokémon are repelled.
	return wild_level < leader_level

func decision(wild_level: int, leader_level: int) -> Dictionary:
	return {"blocked": blocks_level(wild_level, leader_level),
		"remaining_steps": remaining_steps, "active_item": String(active_id),
		"rng_consumed": false}

func to_dict() -> Dictionary:
	return {"schema_version": 1, "active_id": String(active_id),
		"remaining_steps": remaining_steps}

func restore(snapshot: Dictionary) -> bool:
	if int(snapshot.get("schema_version", 0)) != 1: return false
	var sid := StringName(snapshot.get("active_id", ""))
	var steps := int(snapshot.get("remaining_steps", -1))
	if steps < 0 or (steps > 0 and (not DURATIONS.has(sid) or steps > int(DURATIONS[sid]))) \
			or (steps == 0 and sid != &""):
		return false
	active_id = sid
	remaining_steps = steps
	return true
