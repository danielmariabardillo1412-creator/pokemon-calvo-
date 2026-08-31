# NEXT STEPS — LIVE CHECKPOINT

Read immediately after `00_READ_FIRST.md` when recovering context.

## Latest certified baseline
- PR #81 — `audit/data-v3-ability-existing-predicate-scan-v1`
- Final HEAD `e2eeef1d23def1d9fd124b5e2eeb437270212b68`
- **18/18 SUCCESS** on exact notebook-bearing HEAD
- closed without merge.

Move Effects V3 remains closed:
- **590 runtime / 71 partial / 246 data-only / 12 unsupported**;
- `DATA_ONLY` moves with executable `effect_specs`: **0**.

Certified #81 ability coverage:
- `RUNTIME_SUPPORTED`: **11**
- `PARTIAL_RUNTIME`: **4** — `intimidate`, `levitate`, `stamina`, `static`
- `DATA_ONLY`: **358**
- total: **373**.

Prior detailed ability notebooks: `06`, `07`, `08`, `09`, `10`, `11`.

# Current tranche — PR #82
- Branch: `audit/data-v3-ability-defensive-predicates-v2`
- Parent: certified #81 final `e2eeef1d23def1d9fd124b5e2eeb437270212b68`
- PR: #82 `DATA V3 — audit defensive predicate abilities`
- Engineering SHA: `60edf8b7be9225f7670c6dd5039713e4b621163e`
- Engineering SHA: **18/18 SUCCESS**; DATA V3 and Godot global green.
- Detailed notebook: `docs/notebooks/12_DATA_V3_ABILITY_DEFENSIVE_PREDICATES.md`.

## #82 result
### Ice Scales
- source: halves damage from special moves;
- runtime: target `MODIFY_DAMAGE`, `requires_special=true`, `multiplier_bp=5000`;
- decision: **RUNTIME_SUPPORTED**.

### Multiscale
- source: halves move damage at full HP;
- runtime: target `MODIFY_DAMAGE`, `requires_full_hp=true`, `multiplier_bp=5000`;
- decision: **RUNTIME_SUPPORTED**.

Battle Core reevaluates damage modifiers for every MULTI_HIT strike. Canonical fixed two-hit `double_kick` integration verifies only hit one is reduced when starting at full HP and exactly one ability trigger fires.

### Heatproof
- source: halves Fire-move damage and burn residual damage;
- runtime subset: target `MODIFY_DAMAGE`, Fire type, `multiplier_bp=5000`;
- decision: **PARTIAL_RUNTIME**.

Burn residual remains outside ability modifier hooks; focal regression verifies Heatproof currently receives the same burn residual as the no-ability control.

### Filter / Solid Rock
Remain **DATA_ONLY**. They require a super-effective predicate. Type effectiveness is currently produced after the ability modifier phase inside damage calculation, so no duplicate type-chart logic was added.

## Battle Core scope
Exactly two generic predicates were added:
- `requires_special`;
- `requires_full_hp`.

No new trigger kind, parallel damage formula, weather/status/party/form/item system or effectiveness duplicate was introduced.

## Ability coverage after #82 engineering
- `RUNTIME_SUPPORTED`: **13**
- `PARTIAL_RUNTIME`: **5** — `heatproof`, `intimidate`, `levitate`, `stamina`, `static`
- `DATA_ONLY`: **355**
- total: **373**.

## Exact #81 → #82 artifact
Raw + normalized:
- exactly three changed ability records;
- `ice_scales.classification: DATA_ONLY → RUNTIME_SUPPORTED`;
- `multiscale.classification: DATA_ONLY → RUNTIME_SUPPORTED`;
- `heatproof.classification: DATA_ONLY → PARTIAL_RUNTIME`;
- classification is the only changed field for each.

Reports:
- runtime 11→13;
- partial 4→5;
- data-only 358→355;
- only those three IDs move between lists;
- `pokeapi_v3_audit.json` changes only the same three ability-classification counts.

No other ability, Pokémon/species, move/effect, item/status, learnset, evolution, type or stat changed. Manifest/forms/auxiliary are unchanged. `import_time_ms` 505→506 ms is non-semantic.

## Current certification step
Notebook synchronization now moves the branch after engineering SHA `60edf8b7be9225f7670c6dd5039713e4b621163e`.

Before closing #82:
1. verify engineering SHA → final HEAD changed only `01_PROJECT_STATE.md`, `04_NEXT_STEPS.md`, `12_DATA_V3_ABILITY_DEFENSIVE_PREDICATES.md`;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #82 without merge;
4. use exact final HEAD as next baseline.

## Exact next task after #82 closure
Continue **DATA FOUNDATION V3 ability reliability** with another bounded subgroup chosen from the remaining DATA_ONLY frontier.

Do not force Filter/Solid Rock before a shared effectiveness contract exists; do not upgrade Heatproof before burn residual can consult abilities; do not shortcut Fluffy with duplicate trigger events. Prefer a small honest family or a documented negative result over broad architecture solely for coverage.

Trainer AI/archetypes remain deferred.

## Stop condition
Any focal/regression failure stops the tranche until root cause is fixed and rerun.
