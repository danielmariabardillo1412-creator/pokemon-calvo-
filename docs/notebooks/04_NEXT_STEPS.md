# NEXT STEPS — LIVE CHECKPOINT

Read immediately after `00_READ_FIRST.md` when recovering context.

## Latest certified baseline
- PR #88 — `audit/data-v3-ability-existing-primitives-v1`
- Final HEAD `64625cd8d46576a528ea9229bbd0b1d7898f0332`
- **18/18 SUCCESS** on exact notebook-bearing HEAD
- closed without merge.

Move Effects V3 remains closed:
- **590 runtime / 71 partial / 246 data-only / 12 unsupported**;
- DATA_ONLY moves with executable `effect_specs`: **0**.

Certified #88 ability coverage:
- RUNTIME_SUPPORTED: **18**
- PARTIAL_RUNTIME: **14**
- DATA_ONLY: **341**
- total: **373**.

# Current tranche — PR #89
- Branch: `audit/data-v3-ability-end-turn-v1`
- Parent: certified #88 final `64625cd8d46576a528ea9229bbd0b1d7898f0332`
- PR: #89 `DATA V3 — audit end-turn ability semantics`
- Engineering SHA: `b161373a70d0ed226259fe01f98b0d5cfcf677ed`
- Engineering SHA: **18/18 SUCCESS**
- DATA V3 domain: **509 PASS / 0 FAIL**
- Detailed notebook: `docs/notebooks/19_DATA_V3_ABILITY_END_TURN.md`.

## #89 result
### Speed Boost → RUNTIME_SUPPORTED
Pinned Gen III source requires exactly Speed +1 after each turn and has no historical effect changes.

Current runtime already supports the complete transaction:
`END_TURN → SELF Speed +1`.

No new Battle Core primitive was added.

Real battle tests pin:
- turn 1: Speed stage +1, one Speed Boost event;
- turn 2: Speed stage +2, one Speed Boost event that turn;
- no-ability control remains at Speed stage 0.

### Shed Skin → DATA_ONLY
Pinned source has version-sensitive probability:
- current prose 33%;
- Black/White 30%;
- Diamond/Pearl 33%.

Do not choose a universal probability until ability runtime is version-aware. Source guards preserve the exact history and runtime tests require no END_TURN trigger.

### Poison Heal → DATA_ONLY
Pinned source requires healing 1/8 max HP under poison **instead of poison residual damage**.

Current `TurnExecutor` runs `StatusSystem.process_end_turn()` before END_TURN ability triggers. A simple heal afterward would not reproduce the mechanic.

Real battle tests pin the blocker: a poisoned Poison Heal holder currently takes the same positive status residual as an otherwise identical control and emits no Poison Heal event.

## Architecture
**No Battle Core primitive changed in #89.**

Only runtime addition is Speed Boost registration using existing END_TURN and MODIFY_STAT_STAGE. `TurnExecutor` and `StatusSystem` remain untouched.

## Exact #88 → #89 engineering artifact
Raw + normalized:
- exactly `speed_boost.classification: DATA_ONLY → RUNTIME_SUPPORTED`.

Reports:
- runtime **18→19**;
- partial **14→14**;
- data-only **341→340**.

Explicitly unchanged:
- every other ability;
- Pokémon/species;
- moves/effects;
- items/statuses;
- learnsets/evolutions;
- types/stats;
- manifest/forms/auxiliary.

`import_time_ms 515→511 ms` is non-semantic timing noise.

## Ability coverage after #89 engineering
- RUNTIME_SUPPORTED: **19**
- PARTIAL_RUNTIME: **14**
- DATA_ONLY: **340**
- total: **373**.

## Current certification step
Notebook synchronization follows engineering SHA `b161373a70d0ed226259fe01f98b0d5cfcf677ed`.

Before closing #89:
1. verify engineering → final HEAD changed exactly `01_PROJECT_STATE.md`, `04_NEXT_STEPS.md`, `19_DATA_V3_ABILITY_END_TURN.md`;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #89 without merge;
4. use exact final SHA as next certified baseline.

## Exact next task after #89 closure
Continue **DATA FOUNDATION V3 ability reliability** from exact certified #89 final SHA. Select one small immutable-source-backed subgroup from the remaining **340 DATA_ONLY** abilities whose complete semantics already fit existing primitives.

Do not implement Shed Skin until version-aware ability probability is deliberate. Do not implement Poison Heal as a post-residual heal; it needs residual replacement/suppression. Trainer AI/archetypes remain deferred.

## Stop condition
Any focal/regression failure stops the tranche until root cause is fixed and rerun.
