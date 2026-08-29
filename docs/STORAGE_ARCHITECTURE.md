# Storage Architecture (FASE 8, V1)

Pure domain state for persistent creature storage ("PC" / boxes). No `Node`, no autoload, no UI.

## Files

- `modules/creatures/storage/storage_ruleset.gd` — `StorageRuleset.BOX_CAPACITY = 30`.
  No `MAX_BOXES` in V1; boxes are created dynamically via `CreatureStorage.ensure_box()`.
- `modules/creatures/storage/storage_box.gd` — `StorageBox`. One ordered box of slots.
- `modules/creatures/storage/creature_storage.gd` — `CreatureStorage`. Aggregate of boxes.
- `modules/creatures/storage/player_collection.gd` — `PlayerCollection` (party + storage).
- `modules/creatures/storage/capture_routing_result.gd` — `CaptureRoutingResult`.
- `modules/creatures/storage/capture_ownership_router.gd` — `CaptureOwnershipRouter`.

## Identity rule

A creature exists ONCE, identified by `instance_id`. Party and storage hold references to the SAME
`CreatureInstance` object. Moving a creature between party and storage (deposit/withdraw) relocates
the object; it never duplicates or rerolls it.

## Invariants (`CreatureStorage`)

- An `instance_id` appears at most once across ALL boxes.
- A slot holds at most one creature.
- A creature cannot be in two boxes/slots at once.
- `move_between_boxes` leaves the origin empty and the destination with the same instance.
- Invalid operations never corrupt state (caller gets `false`, state unchanged; rollback on partial failure).
- `from_dict` rebuilds boxes from a canonical creature registry; any slot referencing a missing
  creature marks the box `corrupted` (consumed by `SaveGameData.validate` → `invalid_storage_slot`).

## Box model

`StorageBox._slots: Array` of `CreatureInstance|null`, length == `capacity` (30). Serialization
stores slot REFERENCES (instance_id strings) only; the canonical creature data lives in the
savegame creature registry. `StorageBox.from_dict(d, reg)` resolves references via `reg`.

## Party ↔ Storage (`PlayerCollection`)

- `deposit(instance_id)`: removes from party, adds to storage (same object). Rolls back to party
  if storage cannot accept (no loss).
- `withdraw(instance_id)`: removes from storage, adds to party (same object) ONLY if party is not
  full. Rolls back to storage on failure (no duplication).
- `location_of(instance_id)`: `&"PARTY"` / `&"STORAGE"` / `&""`.

## Capture routing (`CaptureOwnershipRouter`)

`route(resolution, party, storage) -> CaptureRoutingResult` consumes `CaptureResolution.disposition`
(FASE 7):
- `PARTY` → no-op (the party was already mutated by `CaptureSystem`).
- `STORAGE_REQUIRED` → `storage.add_creature(resolution.captured)`.
- `UNROUTED` → no-op (e.g. `party == null`).

The router never creates or rerolls a creature; `resolution.captured` is the same `CreatureInstance`
that battle/progression mutated.
