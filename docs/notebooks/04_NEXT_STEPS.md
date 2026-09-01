# NEXT STEPS — LIVE CHECKPOINT

Read immediately after `00_READ_FIRST.md` when recovering context.

## Latest certified baseline
- PR #90 — `audit/data-v3-ability-end-turn-opponent-v1`
- Final HEAD `84e58498e4453ee5378e3209487f4cbfe7b2eead`
- **18/18 SUCCESS** on exact notebook-bearing HEAD
- closed without merge.

Move Effects V3 remains closed:
- **590 runtime / 71 partial / 246 data-only / 12 unsupported**;
- DATA_ONLY moves with executable `effect_specs`: **0**.

Certified #90 ability coverage:
- RUNTIME_SUPPORTED: **19**
- PARTIAL_RUNTIME: **14**
- DATA_ONLY: **340**
- total: **373**.

# Current tranche — PR #91
- Branch: `audit/data-v3-ability-target-state-v1`
- Parent: certified #90 final `84e58498e4453ee5378e3209487f4cbfe7b2eead`
- PR: #91 `DATA V3 — add shared target-state ability semantics`
- Engineering SHA: `a14b761016aec1dd3b0d733f89cee28fd06fe16a`
- Engineering SHA: **18/18 SUCCESS**
- DATA V3 domain: **529 PASS / 0 FAIL**
- Detailed notebook: `docs/notebooks/21_DATA_V3_ABILITY_TARGET_STATE.md`.

## #91 result
A generic target persistent-status predicate is now justified by two independent abilities, not one:

- historical `required_persistent_status_ids` remains **owner-local**;
- new `required_target_persistent_status_ids` is explicitly **target-local**;
- old callers remain compatible;
- no weather, gender or switch-history subsystem was added.

### Bad Dreams → RUNTIME_SUPPORTED
`END_TURN + target sleep + MAX_HP_DAMAGE(OPPONENT, 1250 bp)`.

Real battle contract:
- sleeping opponent loses exactly 1/8 max HP and emits one Bad Dreams event;
- awake opponent gets no Bad Dreams damage/event.

### Merciless → RUNTIME_SUPPORTED
`actor MODIFY_DAMAGE + target poison/badly_poisoned + force_critical=true`.

The project already had authoritative `calvo_v1` critical semantics and `DamageCalculator.force_critical`; #91 only exposes that existing capability through an ability trigger. Tests set natural critical chance to zero and prove poison/toxic force the critical while healthy/burned targets remain inert.

### Rivalry → DATA_ONLY
Requires user/target gender comparison. Runtime does not carry the required per-creature gender state; species `gender_rate` is not a valid replacement.

### Stakeout → DATA_ONLY
Requires target switch-history for the current turn. No turn-scoped switch-history predicate exists.

Rain Dish / Ice Body remain DATA_ONLY because weather architecture is still absent.

## Exact #90 final → #91 engineering artifact
Compared:
- #90 final run `33503120882`, artifact `9798542104`;
- #91 engineering run `33505565643`, artifact `9799469428`.

Canonical changes are exactly two classifications in raw and normalized:
- `bad_dreams: DATA_ONLY → RUNTIME_SUPPORTED`
- `merciless: DATA_ONLY → RUNTIME_SUPPORTED`.

Reports update only the corresponding lists/counters:
- runtime **19 → 21**;
- partial remains **14**;
- data-only **340 → 338**.

Everything else is unchanged: all other ability fields/records, Pokémon/species, moves/effects, items/statuses, learnsets/evolutions, types/stats, manifest, forms and auxiliary. `import_time_ms 509→507 ms` is timing noise.

## Ability coverage after #91 engineering
- RUNTIME_SUPPORTED: **21**
- PARTIAL_RUNTIME: **14**
- DATA_ONLY: **338**
- total: **373**.

## Current certification step
Notebook synchronization follows engineering SHA `a14b761016aec1dd3b0d733f89cee28fd06fe16a`.

Before closing #91:
1. verify engineering → final HEAD changed exactly `01_PROJECT_STATE.md`, `04_NEXT_STEPS.md`, `21_DATA_V3_ABILITY_TARGET_STATE.md`;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #91 without merge;
4. use exact final SHA as next certified baseline.

## Exact next task after #91 closure
Continue DATA FOUNDATION V3 ability reliability from the exact certified #91 final SHA.

Selection rules:
- prefer a small source-backed family whose semantics fit current primitives;
- negative audits remain valid closure work;
- do not open weather merely for Rain Dish/Ice Body;
- do not open gender solely for Rivalry;
- do not open turn-scoped switch-history solely for Stakeout;
- keep version-aware and contact per-strike/faint-safe blockers explicit rather than approximating them.

Trainer AI/archetypes remain deferred until the DATA V3 closure tranche is complete.

## Stop condition
Any focal/regression failure stops the tranche until root cause is fixed and rerun.
