# NEXT STEPS — LIVE CHECKPOINT

Read immediately after `00_READ_FIRST.md` when recovering context.

## Latest certified baseline
- PR #77 — `audit/data-v3-ability-family-inventory-v1`
- Final HEAD `78da22438d0866193b0d1154814464531ac55641`
- **18/18 SUCCESS** on exact notebook-bearing HEAD
- closed without merge.

Move Effects V3 remains closed:
- move coverage: **590 runtime / 71 partial / 246 data-only / 12 unsupported**;
- `DATA_ONLY` moves with non-empty `effect_specs`: **0**.

Ability coverage at certified #77:
- `RUNTIME_SUPPORTED`: **4** — `blaze`, `overgrow`, `swarm`, `torrent`
- `PARTIAL_RUNTIME`: **3** — `intimidate`, `levitate`, `static`
- `DATA_ONLY`: **366**
- total: **373**.

Detailed prior ability notebooks:
- `docs/notebooks/06_DATA_V3_ABILITY_RUNTIME_AUDIT.md`
- `docs/notebooks/07_DATA_V3_ABILITY_FAMILY_INVENTORY.md`.

# Current tranche — PR #78

- Branch: `audit/data-v3-ability-type-boosts-v1`
- Parent: certified #77 final `78da22438d0866193b0d1154814464531ac55641`
- PR: #78 `DATA V3 — audit unconditional ability type boosts`
- Engineering SHA: `f01b1d0553b7dfa1e5998ee1de99ace9fad1534b`
- Engineering SHA: **18/18 SUCCESS**; DATA V3 and Godot global green.
- Detailed current notebook: `docs/notebooks/08_DATA_V3_ABILITY_TYPE_BOOSTS.md`.

## #78 result
Four clean unconditional user-move type boosts fit the already-existing `MODIFY_DAMAGE` primitive and have explicit numeric immutable-source contracts:

- `steelworker` — Steel x1.5
- `dragons_maw` — Dragon +50%
- `rocky_payload` — Rock +50%
- `fire_mane` — Fire +50%

All four become **`RUNTIME_SUPPORTED`**.

Runtime shape for each:
- `MODIFY_DAMAGE`
- exact `move_type_id`
- `multiplier_bp=15000`
- no HP threshold and no new Battle Core primitive.

### Transistor is deliberately excluded
The pinned Transistor record says +50% Electric power and has no historical effect changes, but the ability is version-sensitive. DATA V3 does not yet have enough version-aware ability semantics to choose one universal multiplier honestly.

Decision: **`transistor` stays `DATA_ONLY`** and the test suite enforces that choice.

## Ability coverage after #78 engineering
- `RUNTIME_SUPPORTED`: **8**
- `PARTIAL_RUNTIME`: **3**
- `DATA_ONLY`: **362**
- total: **373**.

Runtime-supported IDs:
`blaze`, `dragons_maw`, `fire_mane`, `overgrow`, `rocky_payload`, `steelworker`, `swarm`, `torrent`.

## Exact #77 → #78 artifact
Raw + normalized:
- exactly four semantic changes;
- only `classification: DATA_ONLY → RUNTIME_SUPPORTED` for `dragons_maw`, `fire_mane`, `rocky_payload`, `steelworker`.

No other ability, Pokémon/species, move/effect, item, learnset, evolution, type or stat changed. Reports move exactly those same IDs and counts. Manifest/forms/auxiliary remain unchanged. Import timing 519→525 ms is non-semantic.

## Current certification step
Notebook synchronization now moves the branch after engineering SHA `f01b1d0553b7dfa1e5998ee1de99ace9fad1534b`.

Before closing #78:
1. verify engineering SHA → final HEAD changed only `01_PROJECT_STATE.md`, `04_NEXT_STEPS.md`, `08_DATA_V3_ABILITY_TYPE_BOOSTS.md`;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #78 without merge;
4. use exact final HEAD as next baseline.

## Exact next task after #78 closure
Continue **DATA FOUNDATION V3 ability reliability** with another bounded family that can use existing primitives.

First candidate: `stamina`, subject to a fresh immutable-source + runtime audit. Do not bulk-convert the remaining `stat_damage_modifier` family. Keep the broad contact-reactive family deferred while Static's fatal-contact AFTER_DAMAGE gap remains unresolved.

Trainer AI/archetypes remain deferred.

## Stop condition
Any focal/regression failure stops the tranche until root cause is fixed and rerun.
