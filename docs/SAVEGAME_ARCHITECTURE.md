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
- `missing_schema` — `schema_version` missing or older than supported.
- `unsupported_schema` — `schema_version` newer than `CURRENT_VERSION` (no fake migrations).
- `duplicate_creature_id` — a creature id appears twice in the registry.
- `missing_creature_reference` — a party/storage slot references an id absent from the registry.
- `double_ownership` — the same id is referenced by both party and storage (or twice in storage).
- `invalid_storage_slot` — a box's slot count != its `capacity` (corrupt/mismatched box).

## Atomic write (`SaveGameSerializer.write_atomic`)

1. Serialize snapshot to a temp file `path + ".tmp"`.
2. Read back and `parse`; if it fails, delete temp and return `temp_verify_failed`.
3. If target exists, delete it (rollback if delete fails).
4. `DirAccess.rename(tmp, path)`. On failure return `rename_failed`.
The target is replaced only after a verified temp exists; a crash mid-write never leaves a `.tmp`
behind and never truncates the previous good save.

## Transactional load (`SaveGameRepository.load`)

All-or-nothing:
1. Read raw text; empty ⇒ `missing_file`; unparseable ⇒ `json_parse_error`.
2. `SaveGameData.from_dict` + `validate()`; any failure ⇒ return `LoadResult(ok=false, reason)`.
3. Build canonical registry (each `CreatureInstance.from_dict` once).
4. Rebuild party (references only) and storage boxes (references only, guarding double-ownership).
5. Only if fully valid, set `out.ok = true`, `out.party`, `out.storage`.
On ANY failure, `out.party` and `out.storage` are `null` — no partially mutated state is published.

## Corruption handling

Unreadable/missing/forward-version/corrupt files are rejected with an explicit `reason`; the caller
keeps the in-memory state and can offer "new game" without crashing.
