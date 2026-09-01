# DATA V3 ABILITY EXISTING-PREDICATE SCAN — V1

## Purpose
Operational record for the bounded ability tranche following certified PR #80.

Use together with:
- `01_PROJECT_STATE.md` for broad project state;
- `04_NEXT_STEPS.md` for the live pointer;
- `07_DATA_V3_ABILITY_FAMILY_INVENTORY.md` for the 13-family triage;
- `10_DATA_V3_ABILITY_STAT_DAMAGE_MODIFIERS.md` for Tough Claws and Attack-doubling blockers.

## Certified parent
- PR #80: `DATA V3 — audit contact damage and attack-doubling abilities`.
- Certified final HEAD: `232a3e787fe2d7d58b1feb693272b63bd7a699bf`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Ability coverage at parent: **9 RUNTIME_SUPPORTED / 4 PARTIAL_RUNTIME / 360 DATA_ONLY / 373 total**.

## PR #81 — defensive damage modifiers
- Branch: `audit/data-v3-ability-existing-predicate-scan-v1`.
- Exact parent: certified #80 final `232a3e787fe2d7d58b1feb693272b63bd7a699bf`.
- PR: #81 `DATA V3 — audit defensive damage ability modifiers`.
- First attempted engineering SHA: `bc6fcd7914bb0707a3cab302d67e1ac9af6dcee5` — rejected because DATA V3 focal test failed.
- Corrected engineering SHA: `7d79fa4ed5deb1cb693518c4d326707b73ba94ba`.
- Corrected engineering SHA: **18/18 SUCCESS**, including DATA V3 and Godot 4.7 global.

## Source audit

### Fur Coat
Pinned immutable source:
- `data/api/v2/ability/169/index.json`;
- main-series Generation VI;
- English effect: halves damage from physical attacks;
- `effect_changes=[]`.

Decision: **`fur_coat → RUNTIME_SUPPORTED`**.

Runtime contract:
- target-side `MODIFY_DAMAGE`;
- `requires_physical=true`;
- `multiplier_bp=5000`.

### Thick Fat
Pinned immutable source:
- `data/api/v2/ability/47/index.json`;
- main-series Generation III;
- English effect: takes half damage from Fire- and Ice-type moves;
- `effect_changes=[]`.

Decision: **`thick_fat → RUNTIME_SUPPORTED`**.

Runtime contract uses two mutually exclusive target-side rules:
- Fire `move_type_id` + `multiplier_bp=5000`;
- Ice `move_type_id` + `multiplier_bp=5000`.

Only one can match a move, so one ability activation/event is emitted.

### Fluffy
Pinned immutable source:
- `data/api/v2/ability/218/index.json`;
- main-series Generation VII;
- contact damage is halved;
- Fire damage is doubled;
- `effect_changes=[]`.

Decision: **remain `DATA_ONLY`**.

Reason: a Fire contact move satisfies both independent modifiers simultaneously. Representing this as two current registry specs would produce two `ABILITY_TRIGGERED` events for one logical ability activation. Defer until modifier composition/event aggregation has an explicit contract.

## Battle Core change
Before #81, actor-side `MODIFY_DAMAGE` could use `move_type_id`, `requires_physical`, `requires_contact`, HP threshold and multiplier predicates, but target-side processing only consumed `immune_type_id` for Levitate-style immunity.

#81 generalizes the existing target-side path narrowly:
1. preserve `immune_type_id` handling unchanged;
2. if a target-owned `MODIFY_DAMAGE` spec has `multiplier_bp`, evaluate it through the already-existing `_damage_condition_matches` predicate surface;
3. multiply the same shared damage multiplier and emit the trigger as target-owned.

No new condition type, weather/status/party/form state, move tags or separate damage formula were added.

## Real-battle focal tests
New suite:
`tests/data/data_foundation_v3_ability_defensive_damage_test_suite.gd`

Using real `AuthoritativeBattleServer` battles with matched seeds/states:
- Fur Coat + physical Tackle: damage is reduced and defending ability event fires;
- Fur Coat + special Water Gun: damage is identical to control and no trigger fires;
- Thick Fat + Ember: damage is reduced and defending ability event fires;
- Thick Fat + Ice Beam: damage is reduced and defending ability event fires;
- Thick Fat + Water Gun: damage is identical to control and no trigger fires.

## First CI failure and root-cause correction
The first PR #81 engineering attempt (`bc6fcd7914bb0707a3cab302d67e1ac9af6dcee5`) stopped correctly at DATA V3 domain tests: **419 PASS / 3 FAIL**.

The failure was in the new test helper, not runtime semantics. It attempted to read nonexistent `BattleEvent.source_id`. `BattleEvent` actually exposes `actor_id`, `target_id` and metadata.

Fix:
- replace only `event.source_id == owner_id` with `event.actor_id == owner_id`;
- one-file, one-line semantic correction;
- failed SHA → corrected SHA compare: exactly **1 file, 1 addition, 1 deletion**;
- no runtime/data-contract code changed after the failed attempt.

Corrected engineering SHA:
`7d79fa4ed5deb1cb693518c4d326707b73ba94ba`

Result: **18/18 SUCCESS**. DATA V3 completed source audit, regeneration, invariants, Godot import, domain tests, normalization and runtime regression; global Godot and all trainer regressions also passed.

## Exact #80 → #81 engineering artifact drift
Compared successful #80 tested artifact with successful corrected #81 artifact.

Raw data:
- exactly two changed abilities: `fur_coat`, `thick_fat`;
- for each, the only changed field is `classification: DATA_ONLY → RUNTIME_SUPPORTED`.

Normalized data:
- exactly the same two classification-only changes.

Reports:
- `RUNTIME_SUPPORTED`: **9 → 11**;
- `PARTIAL_RUNTIME`: remains **4**;
- `DATA_ONLY`: **360 → 358**;
- total remains **373**;
- only Fur Coat and Thick Fat move between classification ID lists.

Explicitly unchanged:
- Fluffy;
- every other ability;
- species/Pokémon;
- moves/effects;
- items/statuses;
- learnsets/evolutions;
- types/stats;
- manifest/forms/auxiliary.

`import_time_ms` 495→530 ms is non-semantic timing noise.

## Coverage after #81 engineering
- `RUNTIME_SUPPORTED`: **11**
- `PARTIAL_RUNTIME`: **4** — `intimidate`, `levitate`, `stamina`, `static`
- `DATA_ONLY`: **358**
- total: **373**.

## Final certification procedure
After syncing this notebook plus `01_PROJECT_STATE.md` and `04_NEXT_STEPS.md`:
1. compare engineering SHA `7d79fa4ed5deb1cb693518c4d326707b73ba94ba` to final HEAD;
2. require only notebook changes (`01`, `04`, `11`);
3. require **18/18 SUCCESS** on that exact notebook-bearing HEAD;
4. close PR #81 without merge;
5. use that exact final HEAD as the next certified baseline.

## Next bounded work after #81 closure
Remain in DATA FOUNDATION V3 ability reliability. Audit another small defensive/existing-primitive subgroup, but do not implement Fluffy by duplicating events and do not broaden Battle Core merely for coverage.

Likely candidates require fresh audit rather than assumptions: Heatproof may expose a safe damage-reduction subset but also has burn-residual semantics; Ice Scales requires a special-move predicate not currently present; full-HP/super-effective reducers require predicates the engine does not yet expose.
