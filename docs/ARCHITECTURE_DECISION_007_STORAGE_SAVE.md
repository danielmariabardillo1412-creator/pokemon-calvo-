# Architecture Decision 007 — Storage + Savegame (FASE 8)

## Context

FASE 7 produced `CreatureParty` and `CaptureSystem`, but there was no persistent "PC"/box storage
and no savegame. Captures into a full party only emitted `STORAGE_REQUIRED` with no destination.
We needed: (a) a Storage Core that holds the same `CreatureInstance` objects as the party, and
(b) a versioned savegame that persists party + storage with full fidelity and no duplication.

## Decision

1. **Identity by `instance_id`, single source of truth.** A creature exists once. Party and storage
   reference the SAME `CreatureInstance`. This is the core invariant; everything else follows from it.
   - Rejected alternative: copy/clone creatures between containers (would allow divergent state and
     duplicate ids).

2. **Storage = ordered boxes of slot references.** `StorageBox` holds `Array[CreatureInstance|null]`
   of length `capacity`; `CreatureStorage` is an aggregate of boxes. `BOX_CAPACITY = 30`. No
   `MAX_BOXES` in V1 — boxes are created on demand (`ensure_box`). This keeps V1 simple and avoids an
   arbitrary cap that would need migration later.
   - Rejected alternative: fixed `MAX_BOXES` (would either waste memory or force a schema bump to grow).

3. **`PlayerCollection` owns deposit/withdraw** with rollback, preserving the same instance. Party is
   the only container allowed to add via capture; storage only receives via deposit or
   `STORAGE_REQUIRED` routing. No container ever rerolls a creature.

4. **Capture routing is a separate, thin router** (`CaptureOwnershipRouter`) that consumes the
   `CaptureDisposition` from FASE 7. Keeps `CaptureSystem` pure and lets UI/networking decide routing
   later without touching capture math.

5. **Savegame = canonical creature registry + reference layouts.** `SaveGameData` stores each creature
   exactly once in `creatures`; `party`/`storage` store only `instance_id` references. This eliminates
   duplicate full-creature blobs and makes double-ownership structurally impossible to serialize.
   - Rejected alternative: embed full creatures in every party/storage slot (data duplication, drift risk).

6. **Atomic write, transactional load, explicit corruption reasons.** Write to temp → verify parse →
   rename. Load builds the whole state then publishes only if valid; on failure `party`/`storage` are
   `null`. Forward-version schemas are rejected (`unsupported_schema`), never silently migrated.
   - Rejected alternative: in-place overwrite (crash could truncate save) and silent migrations (data loss).

7. **Runtime/IO separation.** `SaveGameData` is a pure snapshot (no `CreatureInstance`); `SaveGameSerializer`
   owns files; `SaveGameRepository` orchestrates build/validate/reconstruct. Matches the proven
   Foundation/Battle/Progression pattern.

8. **No UI, no autoloads, no networking, no merge to `main`.** Same contract as prior phases.

## Consequences

- 121 new tests; 429 PASS / 0 FAIL total. End-to-end capture→party/storage→save→load verified with full
  fidelity (IV/nature/ability/moveset/PP/HP/status/level/XP).
- Double-ownership is impossible at runtime (`contains_instance_id`) and at load (`validate`).
- Save schema is explicitly versioned; only V1 is supported. Future versions must add a migration path
  rather than reusing V1.
