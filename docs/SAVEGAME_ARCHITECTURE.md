# Savegame Architecture (FASE 8, V1)

Versioned, atomic, transactional persistence. `schema_version = 1`, `format_id = calvo_save_v1`.

## Files

- `modules/save/save_game_data.gd` — `SaveGameData`: pure serializable snapshot (no `CreatureInstance`).
- `modules/save/save_game_serializer.gd` — `SaveGameSerializer`: file IO (atomic write).
- `modules/save/save_game_repository.gd` — `SaveGameRepository`: build/validate/persist + load.
- `modules/save/save_result.gd` — `SaveResult` (ok/path/reason).
- `modules/save/load_result.gd` — `LoadResult` (ok/reason/schema_version/party/storage).

## Schema (V1)

```
{
  "schema_version": 1,
  "format_id": "calvo_save_v1",
  "creatures": [ {instance_id, species_id, level, experience, ivs, evs, nature_id, ...}, ... ],  # CANONICAL registry (each once)
  "party":   { "schema_version": 2, "ruleset_id": "calvo_party_v1", "ordered_instance_ids": [id, ...] },   # REFERENCE only
  "storage": { "schema_version": 2, "ruleset_id": "calvo_storage_v1", "boxes": [ {"box_id","name","capacity","slots":[id|null,...]} ] }  # REFERENCE only
}
```

The creature registry is CANONICAL: each creature is stored exactly once. Party and storage layouts
reference creatures by `instance_id`. This guarantees a creature exists conceptually once in the
player's state and that no duplicate full-creature blob is written.

## Validation (`SaveGameData.validate`)

Returns `{ok, reason}`. Rejected reasons:
- `missing_format_id` — `format_id` absent (a save from a different format must never be loaded).
- `unsupported_format` — `format_id` != `FORMAT_ID` (no cross-format guessing).
- `missing_schema` — `schema_version` missing or older than supported.
- `unsupported_schema` — `schema_version` newer than `CURRENT_VERSION` (no fake migrations).
- `invalid_creatures_type` / `invalid_party_type` / `invalid_storage_type` / `invalid_boxes_type` —
  a top-level field is the wrong shape (corrupt/foreign payload).
- `empty_creature_instance_id` — a registry entry has an empty `instance_id` (rejected; never stored).
- `duplicate_creature_id` — a creature id appears twice in the registry.
- `invalid_party_layout` — `ordered_instance_ids` is not an array.
- `empty_party_instance_id` — a party slot references an empty id.
- `duplicate_party_instance_id` — a party lists the same creature twice.
- `party_over_capacity` — party size exceeds `PartyRuleset.MAX_PARTY`.
- `missing_creature_reference` — a party/storage slot references an id absent from the registry.
- `double_ownership` — the same id is referenced by both party and storage (or twice in storage).
- `invalid_storage_slot` — a box's slot count != its `capacity` (corrupt/mismatched box).

`SaveGameData` stores `creatures` / `party_layout` / `storage_layout` as `Variant` (not strictly typed)
so a malformed payload is carried into `validate()` and rejected with an explicit reason — the loader
never crashes on a bad field shape. `from_dict` does NOT raise; validation does the rejecting.

## Atomic write + protected replacement (`SaveGameSerializer.write_atomic`)

1. Serialize snapshot to a temp file `path + ".tmp"`.
2. Read back and `parse`; if it fails, delete temp and return `temp_verify_failed`.
3. If target does not exist: `rename(tmp, path)`. On failure return `rename_failed`.
4. If target exists (protected replacement):
   a. `rename(path, path + ".bak")` — back up the LAST KNOWN GOOD save. If this fails, the live
      target is left untouched and we return `cannot_back_up_target` (no data lost).
   b. `rename(tmp, path)` — publish. On success remove the backup.
   c. On publish failure: `rename(path + ".bak", path)` to RESTORE the previous good save
      (`replace_failed_restored`); if even that fails, `replace_failed_restore_failed`.
INVARIANT: the previous good save is never destroyed before a verified replacement is published. A
failed publish restores the previous good save; the live target is never left half-written. No `.tmp`
or `.bak` lingers after a successful write.

## Transactional load (`SaveGameRepository.load`)

All-or-nothing:
1. Read raw text; empty ⇒ `missing_file`; unparseable ⇒ `json_parse_error`.
2. `SaveGameData.from_dict` + `validate()`; any failure ⇒ return `LoadResult(ok=false, reason)`.
3. Build canonical registry (each `CreatureInstance.from_dict` once).
4. Rebuild party (references only) — each `party.add_creature(c)` result is checked; a rejected add
   aborts with `party_rebuild_failed` (never publishes a partial party).
5. Rebuild storage boxes (references only, guarding double-ownership).
6. Only if fully valid, set `out.ok = true`, `out.party`, `out.storage`.
On ANY failure, `out.party` and `out.storage` are `null` — no partially mutated state is published.

## Corruption handling

Unreadable/missing/forward-version/corrupt files are rejected with an explicit `reason`; the caller
keeps the in-memory state and can offer "new game" without crashing.
