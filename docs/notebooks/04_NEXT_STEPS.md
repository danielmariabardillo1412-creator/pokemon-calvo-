# NEXT STEPS — LIVE CHECKPOINT

Read immediately after `00_READ_FIRST.md` when recovering context.

## Latest certified baseline
- PR #89 — `audit/data-v3-ability-end-turn-v1`
- Final HEAD `407ad8f27d13a79b09c367aac2f6ae0c1ef801ef`
- **18/18 SUCCESS** on exact notebook-bearing HEAD
- closed without merge.

Move Effects V3 remains closed:
- **590 runtime / 71 partial / 246 data-only / 12 unsupported**;
- DATA_ONLY moves with executable `effect_specs`: **0**.

Certified #89 ability coverage:
- RUNTIME_SUPPORTED: **19**
- PARTIAL_RUNTIME: **14**
- DATA_ONLY: **340**
- total: **373**.

# Current tranche — PR #90
- Branch: `audit/data-v3-ability-end-turn-opponent-v1`
- Parent: certified #89 final `407ad8f27d13a79b09c367aac2f6ae0c1ef801ef`
- PR: #90 `DATA V3 — audit opponent end-turn ability blockers`
- Engineering SHA: `52fafcc035dd46824bf9f0f6239cc93363981998`
- Engineering SHA: **18/18 SUCCESS**
- DATA V3 domain: **516 PASS / 0 FAIL**
- Spanish/type/runtime regression: **298 PASS / 0 FAIL**
- Detailed notebook: `docs/notebooks/20_DATA_V3_ABILITY_END_TURN_OPPONENT.md`.

## #90 result — negative audit by design
No production/runtime or adapter file changed and no ability classification moved.

### Bad Dreams → DATA_ONLY
Immutable Gen IV source requires opposing Pokémon to lose 1/8 max HP after each turn while asleep.

The engine already has `MAX_HP_DAMAGE` and `OPPONENT`, so the damage transaction itself is representable. The blocker is the condition: `required_persistent_status_ids` is evaluated on the ability **owner**, not the target/opponent. END_TURN passes an opponent into the effect context but `conditions_met()` still sees owner state only.

Therefore do not:
- make the damage unconditional;
- use owner-sleep as a proxy;
- add a one-off target-status predicate just to promote Bad Dreams.

Tests prove the predicate is owner-local and a real sleeping opponent receives no false Bad Dreams damage/event.

### Rain Dish → DATA_ONLY
Source requires 1/16 max-HP healing during rain. Current battle state has no weather state/predicate. Do not install an unconditional heal.

### Ice Body → DATA_ONLY
Source requires 1/16 max-HP healing during hail plus hail-damage immunity. Current battle state has no weather state or hail residual transaction.

## #90 regression value
New suite adds seven checks:
- three immutable source contracts;
- all three blockers stay DATA_ONLY/no END_TURN trigger;
- owner-local status predicate proof;
- real sleeping-target Bad Dreams gap proof;
- exact 19 / 14 / 340 partition.

DATA V3 rises from **509 → 516 checks**, all green.

## Exact #89 final → #90 engineering artifact
Compared:
- #89 final run `33501387360`, artifact `9797865183`;
- #90 engineering run `33502577117`, artifact `9798322866`.

All canonical JSON is semantically identical:
- raw;
- normalized;
- manifest;
- forms;
- unsupported mechanics;
- audit;
- auxiliary.

No domain or classification drift. Only `import_time_ms 513→509 ms` changed, which is execution timing noise.

## Ability coverage after #90 engineering
Unchanged:
- RUNTIME_SUPPORTED: **19**
- PARTIAL_RUNTIME: **14**
- DATA_ONLY: **340**
- total: **373**.

## Current certification step
Notebook synchronization follows engineering SHA `52fafcc035dd46824bf9f0f6239cc93363981998`.

Before closing #90:
1. verify engineering → final HEAD changed exactly `01_PROJECT_STATE.md`, `04_NEXT_STEPS.md`, `20_DATA_V3_ABILITY_END_TURN_OPPONENT.md`;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #90 without merge;
4. use exact final SHA as next certified baseline.

## Exact next task after #90 closure
Continue DATA FOUNDATION V3 ability reliability from exact certified #90 final SHA.

Candidate-selection rule:
- prefer a small source-backed family whose complete semantics already fit current primitives;
- if considering a missing condition such as target status, first prove multiple abilities genuinely need the same shared mechanism;
- keep weather deferred unless doing a deliberate multi-ability weather architecture tranche rather than patching Rain Dish/Ice Body individually;
- negative audit is acceptable and preferable to coverage inflation.

Trainer AI/archetypes remain deferred.

## Stop condition
Any focal/regression failure stops the tranche until root cause is fixed and rerun.
