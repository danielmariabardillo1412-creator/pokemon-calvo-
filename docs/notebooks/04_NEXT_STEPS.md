# NEXT STEPS — LIVE CHECKPOINT

Read immediately after `00_READ_FIRST.md` when recovering context.

## Latest certified baseline
- PR #80 — `audit/data-v3-ability-stat-damage-modifiers-v2`
- Final HEAD `232a3e787fe2d7d58b1feb693272b63bd7a699bf`
- **18/18 SUCCESS** on exact notebook-bearing HEAD
- closed without merge.

Move Effects V3 remains closed:
- **590 runtime / 71 partial / 246 data-only / 12 unsupported**;
- `DATA_ONLY` moves with executable `effect_specs`: **0**.

Certified #80 ability coverage:
- `RUNTIME_SUPPORTED`: **9**
- `PARTIAL_RUNTIME`: **4** — `intimidate`, `levitate`, `stamina`, `static`
- `DATA_ONLY`: **360**
- total: **373**.

Prior detailed ability notebooks: `06`, `07`, `08`, `09`, `10`.

# Current tranche — PR #81
- Branch: `audit/data-v3-ability-existing-predicate-scan-v1`
- Parent: certified #80 final `232a3e787fe2d7d58b1feb693272b63bd7a699bf`
- PR: #81 `DATA V3 — audit defensive damage ability modifiers`
- Corrected engineering SHA: `7d79fa4ed5deb1cb693518c4d326707b73ba94ba`
- Corrected engineering SHA: **18/18 SUCCESS**; DATA V3 and Godot global green.
- Detailed notebook: `docs/notebooks/11_DATA_V3_ABILITY_EXISTING_PREDICATE_SCAN.md`.

## #81 result
### Fur Coat
- source: halves physical-attack damage;
- runtime: target-side `MODIFY_DAMAGE`, `requires_physical=true`, `multiplier_bp=5000`;
- decision: **RUNTIME_SUPPORTED**.

### Thick Fat
- source: half damage from Fire- and Ice-type moves;
- runtime: two mutually exclusive target-side type rules, each `multiplier_bp=5000`;
- decision: **RUNTIME_SUPPORTED**.

### Fluffy
Remains **DATA_ONLY**. Fire contact moves satisfy both independent rules; representing both as current specs would emit duplicate `ABILITY_TRIGGERED` events for one logical activation. Defer until modifier composition/event aggregation is explicitly modeled.

## Battle Core scope
#81 generalizes the existing target-side MODIFY_DAMAGE path so target-owned specs with `multiplier_bp` use the existing condition matcher. Levitate-style `immune_type_id` handling is preserved.

No new condition type, weather/status/party/form state or move-property tag was introduced.

## CI correction recorded
First engineering attempt `bc6fcd7914bb0707a3cab302d67e1ac9af6dcee5` stopped at DATA V3: **419 PASS / 3 FAIL**.

Root cause was only the new test helper: it referenced nonexistent `BattleEvent.source_id`. `BattleEvent.actor_id` is the correct owner field.

The fix changed exactly one line in one test file; runtime code was untouched after the failure. Corrected SHA `7d79fa4e...` then achieved **18/18 SUCCESS**.

## Ability coverage after #81 engineering
- `RUNTIME_SUPPORTED`: **11**
- `PARTIAL_RUNTIME`: **4**
- `DATA_ONLY`: **358**
- total: **373**.

## Exact #80 → #81 artifact
Raw + normalized:
- exactly two changes: `fur_coat.classification` and `thick_fat.classification`;
- both `DATA_ONLY → RUNTIME_SUPPORTED`.

Reports move only those two IDs and update 9→11 runtime / 360→358 data-only; partial stays 4.

Fluffy is unchanged. No other ability, Pokémon/species, move/effect, item/status, learnset, evolution, type or stat changed. Manifest/forms/auxiliary are unchanged. `import_time_ms` 495→530 ms is non-semantic.

## Current certification step
Notebook synchronization now moves the branch after engineering SHA `7d79fa4ed5deb1cb693518c4d326707b73ba94ba`.

Before closing #81:
1. verify engineering SHA → final HEAD changed only `01_PROJECT_STATE.md`, `04_NEXT_STEPS.md`, `11_DATA_V3_ABILITY_EXISTING_PREDICATE_SCAN.md`;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #81 without merge;
4. use exact final HEAD as next baseline.

## Exact next task after #81 closure
Continue **DATA FOUNDATION V3 ability reliability** with another bounded subgroup.

Do not shortcut Fluffy. Freshly audit candidates before implementation. Heatproof may have a representable Fire-damage subset plus missing burn-residual behavior; Ice Scales needs a special-move predicate; full-HP/effectiveness reducers need predicates not currently present. Prefer a small honest family or a documented negative result over broadening Battle Core solely to increase coverage.

Trainer AI/archetypes remain deferred.

## Stop condition
Any focal/regression failure stops the tranche until root cause is fixed and rerun.
