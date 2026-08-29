class_name CaptureOwnershipRouter
extends RefCounted

# Consumes a CaptureResolution and routes the captured CreatureInstance to the correct ownership
# container. This is a SERVICE above CaptureSystem + CreatureStorage; CaptureSystem itself does NOT
# know about storage (separation preserved).
#
# Disposition handling:
#  - PARTY:            already added to party by CaptureSystem when a party was supplied; nothing to do.
#  - STORAGE_REQUIRED: insert `captured` into storage (party was full). Same instance, no reroll.
#  - UNROUTED:         not a normal game path; caller may keep the creature or discard it. No routing.

func route(resolution: CaptureResolution, party: CreatureParty, storage: CreatureStorage) -> CaptureRoutingResult:
	var out := CaptureRoutingResult.new()
	if resolution == null or resolution.captured == null:
		out.reason = "no_captured_creature"
		return out
	match resolution.disposition:
		CaptureDisposition.PARTY:
			out.routed = true
			out.stored = false
			out.reason = "already_in_party"
		CaptureDisposition.STORAGE_REQUIRED:
			out.routed = true
			out.stored = storage.add_creature(resolution.captured)
			out.reason = "stored" if out.stored else "storage_full_unexpected"
		CaptureDisposition.UNROUTED:
			out.routed = false
			out.reason = "unrouted_no_container"
	return out
