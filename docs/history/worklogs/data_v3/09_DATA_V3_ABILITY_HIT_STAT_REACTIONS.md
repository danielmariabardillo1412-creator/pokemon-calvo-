# DATA V3 ABILITY HIT-STAT REACTIONS — V1

## Purpose

Operational checkpoint for the bounded ability tranche after certified PR #78.

Use together with:
- `01_PROJECT_STATE.md` for broad state;
- `04_NEXT_STEPS.md` for the live pointer;
- `06_DATA_V3_ABILITY_RUNTIME_AUDIT.md` for the initial six abilities;
- `07_DATA_V3_ABILITY_FAMILY_INVENTORY.md` for the 13-family inventory;
- `08_DATA_V3_ABILITY_TYPE_BOOSTS.md` for certified unconditional type boosts.

## Certified parent

- PR #78: `DATA V3 — audit unconditional ability type boosts`.
- Final certified HEAD: `eda483d9cd6423d32bdf1a156372416b2fbcb639`.
- Status: **18/18 SUCCESS**, closed without merge.
- Parent ability coverage: **8 runtime / 3 partial / 362 data-only / 373 total**.

## PR #79 — hit-triggered stat reactions

- Branch: `audit/data-v3-ability-hit-stat-reactions-v1`.
- Exact parent: `eda483d9cd6423d32bdf1a156372416b2fbcb639`.
- Engineering SHA: `748b28b69d19be5912bbc0318f2e8e8d40f3eccd`.
- Engineering SHA: **18/18 workflows SUCCESS**.

### Source audit

#### Stamina
Immutable source: `data/api/v2/ability/192/index.json`.

Source contract:
- main-series, Generation VII;
- when the holder takes damage from a move, Defense rises by one stage;
- `effect_changes=[]` in the pinned snapshot.

Current Battle Core can represent a useful faithful subset with its existing `AFTER_DAMAGE` + `MODIFY_STAT_STAGE` primitives.

However current execution timing is move-level, not hit-level:
- `MULTI_HIT` resolves all strikes inside `BattleEffectExecutor`;
- `TurnExecutor` calls `AFTER_DAMAGE` once after the completed move;
- fainted owners are excluded from `_execute_triggers`.

Therefore Stamina must **not** be labelled complete.

Decision: **`stamina → PARTIAL_RUNTIME`**.

Implemented runtime subset:
- trigger: `AFTER_DAMAGE`;
- effect: SELF Defense `+1`;
- no contact, physical, type, HP or other invented gate.

### Real battle integration test

New suite: `tests/data/data_foundation_v3_ability_hit_stat_test_suite.gd`.

It imports canonical DATA V3, creates a real `AuthoritativeBattleServer`, and verifies:
1. a surviving Stamina owner damaged by `Tackle` receives exactly Defense +1 and emits `ABILITY_TRIGGERED`;
2. a non-damaging `Growl` against the owner does not fire Stamina.

This suite is invoked by `data_foundation_v3_domain_test_runner.gd`, so the DATA V3 workflow exercises the actual battle path rather than only inspecting registry metadata.

### Adjacent candidates deliberately blocked

#### Water Compaction
Immutable source: `data/api/v2/ability/195/index.json`.

Requires Defense +2 when hit by a **Water move**. Current generic `AFTER_DAMAGE` condition evaluator does not support a move-type predicate. Adding a broad Battle Core condition solely to raise coverage is outside this tranche.

Decision: **remain `DATA_ONLY`**.

#### Weak Armor
Immutable source: `data/api/v2/ability/133/index.json`.

Requires a physical-hit reaction with a multi-stat transaction and per-hit behavior for multi-hit moves; its historical/version semantics also require separate treatment.

Decision: **remain `DATA_ONLY`**.

## Coverage after #79 engineering

- `RUNTIME_SUPPORTED`: **8**
- `PARTIAL_RUNTIME`: **4** — `intimidate`, `levitate`, `stamina`, `static`
- `DATA_ONLY`: **361**
- total: **373**.

## #78 → #79 engineering artifact diff

Raw and normalized datasets:
- exactly one changed ability: `stamina`;
- exactly one changed semantic field: `classification`;
- `DATA_ONLY → PARTIAL_RUNTIME`.

No other ability, species, move/effect, item, learnset, evolution, type or stat changed.

Reports:
- remove only `stamina` from DATA_ONLY;
- add only `stamina` to PARTIAL_RUNTIME;
- counts `362→361` DATA_ONLY and `3→4` PARTIAL_RUNTIME.

Unchanged:
- manifest;
- forms report;
- auxiliary report.

`import_time_ms` changed `357→516 ms`; this is nondeterministic execution timing only.

## Safety conclusions

1. A registry entry is not sufficient evidence for `RUNTIME_SUPPORTED`; trigger granularity matters.
2. `AFTER_DAMAGE` currently means **once after a completed damaging move**, not once per strike.
3. Do not generalize Stamina into Water Compaction/Weak Armor automatically.
4. Do not change global AFTER_DAMAGE/fainted-owner semantics inside a data reliability tranche; Static and held-item behavior share that infrastructure.
5. The #76-frontier inventory allowlist now explicitly includes Stamina so any other silent promotion still fails CI.

## Certification closure still required

After this notebook sync:
1. verify engineering `748b28b69d19be5912bbc0318f2e8e8d40f3eccd` → final HEAD changes only notebooks;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close PR #79 without merge;
4. use that exact HEAD as the next baseline.

## Exact next work after #79 closure

Remain in DATA FOUNDATION V3 ability reliability.

Do **not** implement Water Compaction or Weak Armor as a shortcut. First triage the remaining `stat_damage_modifier` bucket for another small set whose complete or partial semantics fit primitives already present in Battle Core. Prefer a bounded allowlist with explicit source contracts; if no clean candidate exists, record that and move to the next family rather than broadening Battle Core only for coverage.
