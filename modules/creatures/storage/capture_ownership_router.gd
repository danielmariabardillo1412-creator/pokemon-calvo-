class_name CaptureOwnershipRouter
extends RefCounted

# Consumes a CaptureResolution and routes the captured CreatureInstance to the correct ownership
# container. This is a SERVICE above CaptureSystem + CreatureStorage; CaptureSystem itself does NOT
# know about storage (separation preserved).
#
# Disposition handling:
#  - PARTY:            already added to party by CaptureSystem when a party was supplied; only report
#                      routed=true if the creature is ACTUALLY present in the party.
#  - STORAGE_REQUIRED: insert `captured` into storage (party was full). Same instance, no reroll.
#                      routed=true ONLY when storage actually accepted it.
#  - UNROUTED:         not a normal game path; caller may keep the creature or discard it. No routing.
#
# INVARIANT: `routed` is never true unless the creature is genuinely owned by the claimed container.
# storage=null or a rejected add are reported as routed=false, never a false success.

func route(resolution: CaptureResolution, party: CreatureParty, storage: CreatureStorage) -> CaptureRoutingResult:
	var out := CaptureRoutingResult.new()
	if resolution == null or resolution.captured == null:
		out.reason = "no_captured_creature"
		return out
	var c: CreatureInstance = resolution.captured
	match resolution.disposition:
		CaptureDisposition.PARTY:
			# CaptureSystem already added it; only confirm routed=true if it is really there.
			if party != null and party.contains_instance_id(c.instance_id):
				out.routed = true
				out.stored = false
				out.reason = "already_in_party"
			else:
				out.routed = false
				out.stored = false
				out.reason = "party_ownership_missing"
		CaptureDisposition.STORAGE_REQUIRED:
			# routed is true ONLY when storage actually accepted the creature.
			if storage == null:
				out.routed = false
				out.stored = false
				out.reason = "storage_null"
			else:
				out.stored = storage.add_creature(c)
				out.routed = out.stored
				if out.stored:
					out.reason = "stored"
				elif storage.contains_instance_id(c.instance_id):
					out.reason = "duplicate_instance_id"
				else:
					out.reason = "storage_rejected_creature"
		CaptureDisposition.UNROUTED:
			out.routed = false
			out.stored = false
			out.reason = "unrouted_no_container"
	return out
