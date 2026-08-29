class_name CaptureSystem
extends RefCounted

# Pure, deterministic capture resolution. No UI, no Nodes, no autoload. All randomness is injected
# via the RandomNumberGenerator argument (the caller owns the RNG source).
#
# CaptureSystem is domain logic only: it does NOT, by itself, enforce a client/server trust
# boundary. It computes the deterministic outcome from whatever `target` and `context` it is given.
# When networking exists, a higher layer MUST validate that `target` + `context` are reconstructed
# from trusted server state before calling resolve(); this class does not authenticate or trust them.

# Server resolution of a single capture attempt. Mutates `party` (adds on success if there is
# room) and returns a CaptureResolution (result + captured creature + disposition + events).
static func resolve(
	attempt: CaptureAttempt,
	rng: RandomNumberGenerator,
	catalogs,
	party: CreatureParty,
) -> CaptureResolution:
	var res := CaptureResolution.new()
	var events: Array[CaptureEvent] = []
	var crs := CaptureRuleset.new()

	var target_id: StringName = &""
	if attempt != null and attempt.target != null:
		target_id = attempt.target.instance_id

	events.append(CaptureEvent.new(CaptureEvent.ATTEMPTED, {
		"ball_id": String(attempt.ball_id) if attempt != null else "",
		"target_id": String(target_id),
	}))

	var invalid_reason := _validate(attempt, catalogs)
	if invalid_reason != "":
		var r := CaptureResult.new()
		r.status = CaptureResult.INVALID
		if attempt != null:
			r.ball_id = attempt.ball_id
			if attempt.target != null:
				r.target_id = attempt.target.instance_id
		r.consume_item = false
		r.reason = invalid_reason
		res.result = r
		events.append(CaptureEvent.new(CaptureEvent.REJECTED, {"reason": invalid_reason}))
		res.events = events
		return res

	var target := attempt.target
	var ball_def := crs.ball(attempt.ball_id)
	var species: CreatureSpecies = null
	if catalogs != null:
		species = catalogs.species_catalog.get_by_id(target.species_id)

	var status_id := target.status_state.persistent_id
	var status_mult := crs.status_bonus(status_id)
	var p := 0.0
	var guaranteed := ball_def.guaranteed
	if not guaranteed:
		var rate := 0
		if species != null:
			rate = species.capture_rate
		p = crs.catch_probability(rate, ball_def.base_multiplier, status_mult, target.stats.max_hp, target.current_hp)

	# Master ball (and any guaranteed ball) succeeds without consuming RNG.
	var success := guaranteed or (p > 0.0 and rng.randf() < p)

	var r := CaptureResult.new()
	r.ball_id = attempt.ball_id
	r.target_id = target.instance_id
	r.probability = p
	r.consume_item = true

	if success:
		r.shake_count = 3
		r.status = CaptureResult.SUCCESS
		res.captured = target   # SAME instance - identity/IV/EV/nature/ability preserved
		events.append(CaptureEvent.new(CaptureEvent.SUCCEEDED, {
			"target_id": String(target.instance_id), "ball_id": String(attempt.ball_id),
		}))
		if party == null:
			# No roster supplied: the capture still resolves, but nothing is added anywhere.
			res.disposition = CaptureDisposition.UNROUTED
		elif party.is_full():
			res.disposition = CaptureDisposition.STORAGE_REQUIRED
			events.append(CaptureEvent.new(CaptureEvent.STORAGE_REQUIRED, {"target_id": String(target.instance_id)}))
		else:
			res.disposition = CaptureDisposition.PARTY
			party.add_creature(target)
			events.append(CaptureEvent.new(CaptureEvent.PARTY_ADDED, {"target_id": String(target.instance_id)}))
	else:
		r.shake_count = _failed_shakes(p)
		r.status = CaptureResult.FAILED
		events.append(CaptureEvent.new(CaptureEvent.SHAKE, {"count": r.shake_count}))
		events.append(CaptureEvent.new(CaptureEvent.FAILED, {"target_id": String(target.instance_id)}))

	res.result = r
	res.events = events
	return res


static func _validate(attempt: CaptureAttempt, catalogs) -> String:
	if attempt == null or attempt.target == null:
		return "invalid_target"
	if attempt.context == null:
		return "invalid_context"
	var ctx: CaptureBattleContext = attempt.context
	if ctx.battle_finished:
		return "battle_finished"
	# Trainer battles are never capturable in calvo_capture_v1.
	if not ctx.is_wild:
		return "trainer_battle_not_capturable"
	if ctx.target_owner_trainer_id != &"":
		return "target_owned_by_trainer"
	if not CaptureRuleset.ALLOW_CAPTURE_KO and attempt.target.is_knocked_out():
		return "target_knocked_out"
	if not CaptureRuleset.new().is_known_ball(attempt.ball_id):
		return "unknown_ball"
	var species: CreatureSpecies = null
	if catalogs != null:
		species = catalogs.species_catalog.get_by_id(attempt.target.species_id)
	if species == null:
		return "unknown_species"
	if not CaptureRuleset.is_valid_capture_rate(species.capture_rate):
		return "invalid_capture_rate"
	return ""


# Deterministic flavor: number of shakes before the ball breaks on a failed attempt.
static func _failed_shakes(probability: float) -> int:
	return clampi(int(probability * 3.0), 0, 2)
