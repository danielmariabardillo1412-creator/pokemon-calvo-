class_name WildEscapeRuleset
extends RefCounted

# Calvo escape V1 keeps the familiar core-series shape without claiming bit-perfect parity with a
# specific generation. Faster/equal player Speed escapes automatically. Otherwise chance increases
# with repeated attempts and uses one injected RNG roll in [0, 255]. Persistent Speed is used, so
# temporary battle stages/paralysis modifiers do not silently alter this application-layer rule.
const ID := &"calvo_escape_v1"
const ROLL_MAX := 255
const ATTEMPT_BONUS := 30
const SPEED_SCALE := 128


func guaranteed(player_speed: int, wild_speed: int) -> bool:
	return player_speed > 0 and wild_speed > 0 and player_speed >= wild_speed


func odds(player_speed: int, wild_speed: int, attempt: int) -> int:
	if player_speed <= 0 or wild_speed <= 0 or attempt <= 0:
		return 0
	return int(floor(float(player_speed * SPEED_SCALE) / float(wild_speed))) + ATTEMPT_BONUS * attempt


func resolve(
	player_speed: int,
	wild_speed: int,
	attempt: int,
	rng: RandomNumberGenerator = null,
) -> WildEscapeResolution:
	var out := WildEscapeResolution.new()
	out.attempt = attempt
	if player_speed <= 0 or wild_speed <= 0:
		out.reason = "invalid_escape_speed"
		return out
	if attempt <= 0:
		out.reason = "invalid_escape_attempt"
		return out

	out.odds = odds(player_speed, wild_speed, attempt)
	if guaranteed(player_speed, wild_speed) or out.odds > ROLL_MAX:
		out.escaped = true
		return out
	if rng == null:
		out.reason = "escape_rng_required"
		return out

	out.roll = rng.randi_range(0, ROLL_MAX)
	out.rng_consumed = true
	out.escaped = out.roll < out.odds
	return out
