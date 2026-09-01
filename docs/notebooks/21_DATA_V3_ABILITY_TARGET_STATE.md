# DATA V3 ABILITY TARGET-STATE AUDIT — V1

## Purpose
Operational checkpoint for the bounded DATA V3 ability-reliability tranche following certified PR #90.

## Certified parent
- PR #90: `DATA V3 — audit opponent end-turn ability blockers`.
- Certified final HEAD: `84e58498e4453ee5378e3209487f4cbfe7b2eead`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Parent ability coverage: **19 RUNTIME_SUPPORTED / 14 PARTIAL_RUNTIME / 340 DATA_ONLY / 373 total**.

## Tranche identity
- Branch: `audit/data-v3-ability-target-state-v1`.
- PR: #91 `DATA V3 — add shared target-state ability semantics`.
- Exact parent: certified #90 final `84e58498e4453ee5378e3209487f4cbfe7b2eead`.
- Engineering SHA: `a14b761016aec1dd3b0d733f89cee28fd06fe16a`.
- Engineering result: **18/18 SUCCESS**.
- DATA V3 domain: **529 PASS / 0 FAIL**.

## Why target-state architecture is justified
PR #90 proved Bad Dreams was blocked because `required_persistent_status_ids` is owner-local. This tranche found a second independent source-backed consumer: Merciless. Therefore target persistent status is a shared condition surface rather than a one-off Bad Dreams patch.

The new contract is explicit:
- `required_persistent_status_ids` remains owner-local;
- `required_target_persistent_status_ids` evaluates the supplied opposing/effect target;
- historical callers remain compatible because the target argument is optional;
- damage modifiers pass the opposing combatant directionally;
- `TurnExecutor` passes the effect target to trigger-condition evaluation.

No weather, gender, switch-history or new critical subsystem was introduced.

## Bad Dreams → RUNTIME_SUPPORTED
Immutable source: Generation IV, main-series, no `effect_changes`; opposing Pokémon lose **1/8 maximum HP after each turn while asleep**.

Runtime contract:
- trigger: `END_TURN`;
- condition: `required_target_persistent_status_ids = ["sleep"]`;
- effect: `MAX_HP_DAMAGE` against `OPPONENT`, `ratio_basis_points = 1250`.

Real battle regression:
- sleeping opponent loses exactly 1/8 max HP and emits one Bad Dreams ability event;
- awake opponent receives no Bad Dreams damage/event.

This directly resolves the blocker documented in #90 without changing owner-local status semantics.

## Merciless → RUNTIME_SUPPORTED
Immutable source: Generation VII, main-series, no `effect_changes`; moves against poisoned targets are critical hits.

`calvo_v1` already defines project-authoritative critical semantics: base critical chance 1/24, critical multiplier 1.5x, and current V2 critical does not ignore stages. `DamageCalculator` already had a `force_critical` input; this tranche exposes that existing capability through the trigger contract rather than adding a second critical subsystem.

Runtime contract:
- trigger: actor `MODIFY_DAMAGE`;
- condition: target persistent status in `["poison", "badly_poisoned"]`;
- `force_critical = true`;
- no damage multiplier and no offensive-stat multiplier.

Real battle tests set natural critical chance to zero so any critical must come from Merciless:
- normal poison → forced critical;
- badly poisoned → forced critical;
- healthy target → no critical / no Merciless event;
- burned target → no critical / no Merciless event.

## Adjacent blockers
### Rivalry → DATA_ONLY
Pinned source requires comparing user and target gender and applying 1.25x / 0.75x regular damage. Runtime does not carry the necessary per-creature gender/comparison state. Do not infer it from species `gender_rate`.

### Stakeout → DATA_ONLY
Pinned source requires double power against a target that **switched in this turn**. Runtime lacks a turn-scoped target switch-history predicate. Do not approximate with generic ON_SWITCH_IN state.

### Weather blockers remain deferred
Rain Dish and Ice Body remain DATA_ONLY. Target-status work does not create weather state, rain/hail predicates or hail residual immunity.

## Source guards
`tools/pokeapi_ability_runtime_contracts.py` now validates:
- Bad Dreams generation + exact sleep/end-turn/1/8 semantics + no history;
- Merciless generation + poisoned-target critical semantics + no history;
- Rivalry generation + same/opposite/genderless 1.25x/0.75x semantics + no history;
- Stakeout generation + switched-this-turn/double-power semantics + no history.

Any source drift forces re-audit rather than silently retaining classifications.

## Safety / diff discipline
Before PR opening, full compare against certified #90 was checked. Central-file diffs remained narrow:
- `TurnExecutor`: 1 addition / 1 deletion;
- `BattleEffectExecutor`: 2 additions / 2 deletions;
- `BattleTriggerSystem`: small generic target-condition extension;
- registry: bounded Bad Dreams + Merciless specs;
- ability source contracts: additive narrow guards;
- no adapter rewrite, no canonical JSON edited by hand.

A temporary layered Python contract file considered during implementation was deleted before PR; final architecture keeps contracts in the existing ability runtime contract module.

## Engineering CI
Engineering SHA `a14b761016aec1dd3b0d733f89cee28fd06fe16a`:
- **18/18 normal workflows SUCCESS**;
- DATA V3 generation/import/domain/normalization/runtime all green;
- DATA V3 domain: **529 PASS / 0 FAIL**.

## Exact artifact comparison — certified #90 final → #91 engineering
Certified #90 final artifact:
- head `84e58498e4453ee5378e3209487f4cbfe7b2eead`;
- workflow run `33503120882`;
- artifact `9798542104`.

#91 engineering artifact:
- head `a14b761016aec1dd3b0d733f89cee28fd06fe16a`;
- workflow run `33505565643`;
- artifact `9799469428`.

Both artifacts contain the same 15-file output set.

Canonical drift is exactly:
- raw `bad_dreams.classification`: `DATA_ONLY → RUNTIME_SUPPORTED`;
- raw `merciless.classification`: `DATA_ONLY → RUNTIME_SUPPORTED`;
- normalized: exactly the same two classification changes;
- `unsupported_mechanics`: Bad Dreams/Merciless move from DATA_ONLY to RUNTIME_SUPPORTED and counters update;
- `pokeapi_v3_audit`: only ability counters update.

Unchanged:
- all other ability fields and records;
- Pokémon/species;
- moves/effects;
- items/statuses;
- learnsets/evolutions;
- types/stats;
- manifest;
- forms policy;
- auxiliary report.

`import_time_ms 509 → 507` is execution timing noise only.

## Ability coverage after #91 engineering
- RUNTIME_SUPPORTED: **21**
- PARTIAL_RUNTIME: **14**
- DATA_ONLY: **338**
- total: **373**.

## Final certification protocol
After this notebook plus `01_PROJECT_STATE.md` and `04_NEXT_STEPS.md` are synchronized:
1. engineering `a14b761...` → final HEAD must contain exactly those three notebook files;
2. no code/test/data changes after engineering certification;
3. require **18/18 SUCCESS** on exact notebook-bearing final HEAD;
4. close PR #91 without merge;
5. do not make a post-close commit merely to record closure; GitHub state is authoritative.

## Next work after #91 closure
Continue DATA FOUNDATION V3 ability reliability from the exact certified #91 final SHA. Keep weather, gender and switch-history architecture deferred unless a deliberately bounded multi-ability tranche justifies them. Prefer another small family that reuses current primitives or a negative audit. Trainer AI remains deferred until the DATA V3 closure tranche is complete.
