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

- 121 new tests (FASE 8) + 26 FASE 8C regression tests; 470 PASS / 0 FAIL total. End-to-end
  capture→party/storage→save→load verified with full fidelity
  (IV/nature/ability/moveset/PP/HP/status/level/XP).
- Double-ownership is impossible at runtime (`contains_instance_id`) and at load (`validate`).
- Save schema is explicitly versioned; only V1 is supported. Future versions must add a migration path
  rather than reusing V1.

## Addendum — FASE 8C Hotfix (persistence + invariant fix)

Code review of FASE 8 found three silently-accepted failure modes; all are now closed:

1. **Unsafe save replacement.** `write_atomic` deleted the target then renamed temp→target; a rename
   failure lost the previous good save. Now PROTECTED REPLACEMENT: target is backed up to
   `path + ".bak"` before any rename; a failed publish restores the backup. The previous good save is
   never destroyed (reasons: `cannot_back_up_target`, `replace_failed_restored`,
   `replace_failed_restore_failed`).
2. **Corrupt party saves accepted silently.** `validate()` accepted duplicate/over-capacity/empty-id
   parties, and `load()` did not check `party.add_creature` results. Now `validate()` rejects
   `duplicate_party_instance_id`, `party_over_capacity`, `empty_party_instance_id`, `invalid_party_layout`;
   `load()` aborts with `party_rebuild_failed` if a rebuild add fails. Added `format_id` validation
   (`missing_format_id` / `unsupported_format`) and empty-creature-id rejection.
3. **`CaptureOwnershipRouter` false success.** `routed` was set `true` for `STORAGE_REQUIRED` before
   storage accepted, and `PARTY` was assumed present. Now `routed = stored` (STORAGE_REQUIRED), `null`
   storage is handled without crashing, and `PARTY` is only `routed=true` if the creature is actually in
   the party.

Layout fields in `SaveGameData` are `Variant` (not strictly typed) so a malformed payload reaches
`validate()` and is rejected with an explicit reason rather than crashing the loader.
