# DATA V3 ABILITY END-TURN AUDIT — V1

## Purpose
Operational record for the bounded DATA V3 ability-reliability tranche following certified PR #88.

## Certified parent
- PR #88: `DATA V3 — isolate damage modifier roles and audit compound abilities`.
- Certified final HEAD: `64625cd8d46576a528ea9229bbd0b1d7898f0332`.
- Parent status: **18/18 workflows SUCCESS**, closed without merge.
- Parent ability coverage: **18 RUNTIME_SUPPORTED / 14 PARTIAL_RUNTIME / 341 DATA_ONLY / 373 total**.

## Current tranche
- Branch: `audit/data-v3-ability-end-turn-v1`.
- PR: #89 `DATA V3 — audit end-turn ability semantics`.
- Exact parent: certified #88 final `64625cd8d46576a528ea9229bbd0b1d7898f0332`.
- Engineering SHA: `b161373a70d0ed226259fe01f98b0d5cfcf677ed`.
- Engineering certification: **18/18 workflows SUCCESS**.
- DATA Foundation V3: **509 PASS / 0 FAIL**.
- Godot global: SUCCESS.

## Bounded source-first candidate set
- `speed_boost`;
- `shed_skin`;
- `poison_heal`.

The tranche intentionally does not introduce weather, field state, a generic version-aware ability policy, or poison-residual suppression solely to increase coverage.

## Source decision — Speed Boost
Immutable source: `data/api/v2/ability/3/index.json` on `data/pokeapi-v2-snapshot`.

Pinned contract:
- main-series;
- Generation III;
- Speed rises exactly one stage after each turn;
- no `effect_changes`.

Current Battle Core already has every required semantic:
- `BattleTriggerSpec.END_TURN`;
- `BattleEffectSpec.MODIFY_STAT_STAGE`;
- self target;
- Speed stages.

Runtime registration is therefore exactly:
`END_TURN → ability/speed_boost → SELF Speed +1`
with no condition dictionary and no new primitive.

Decision: **`speed_boost → RUNTIME_SUPPORTED`**.

### Real-battle proof
New `DataFoundationV3AbilityEndTurnTestSuite` imports the canonical V3 dataset through `DataImporter` and runs real `AuthoritativeBattleServer` turns.

It pins:
- first completed turn: Speed stage becomes `+1`, exactly one `ABILITY_TRIGGERED` event;
- second completed turn: Speed stage becomes `+2`, exactly one Speed Boost event during that turn;
- identical no-ability control remains Speed stage `0`;
- registry shape is one unconditional END_TURN / SELF / Speed / +1 transaction.

This validates execution timing, not only registry metadata.

## Source decision — Shed Skin
Immutable source: `data/api/v2/ability/61/index.json`.

Pinned source is version-sensitive:
- current English effect: **33%** chance after each turn to cure any major status ailment;
- `effect_changes` records Black/White: **30%**;
- `effect_changes` records Diamond/Pearl: **33%**.

The repository currently has no version-aware ability runtime policy that selects which historical probability applies to the active battle ruleset. Choosing one universal value would silently overwrite preserved source history.

Decision: **remain `DATA_ONLY`**.

A fail-fast source guard requires the current 33% prose and the exact 30%/33% historical shape, so future snapshot changes force explicit re-audit. Runtime tests require Shed Skin to have no END_TURN trigger; a burned holder remains burned in the current engine.

## Source decision — Poison Heal
Immutable source: `data/api/v2/ability/90/index.json`.

Pinned battle contract:
- main-series Generation IV;
- while poisoned, heal **1/8 max HP after each turn instead of taking poison damage**;
- includes bad poison;
- its recorded Black/White history is overworld-only and does not alter this battle transaction.

### Timing blocker
Current `TurnExecutor._complete_turn()` executes:
1. `StatusSystem.process_end_turn()`;
2. KO handling;
3. ability/item `END_TURN` triggers for surviving active creatures.

`StatusSystem.process_end_turn()` directly applies poison/bad-poison residual before ability END_TURN execution.

Therefore a simple `END_TURN HEAL 1/8` mapping would be wrong: it would heal **after** normal poison damage instead of replacing that damage.

Decision: **remain `DATA_ONLY`** until poison residual has an ability-aware suppression/replacement transaction or a deliberately redesigned residual phase.

### Real-battle blocker proof
The focal test poisons a Poison Heal holder and an otherwise identical control using the same deterministic battle shape. The Poison Heal holder:
- receives positive `STATUS_DAMAGE`;
- receives exactly the same poison residual as the plain control;
- loses exactly that HP;
- emits no Poison Heal ability event.

This pins the missing semantic directly in runtime.

## Source provenance guards
`tools/pokeapi_ability_runtime_contracts.py` now:
- promotes only `speed_boost`;
- validates Speed Boost Generation III / Speed +1 after each turn / no history;
- guards Shed Skin exact current and historical probability contract while keeping it DATA_ONLY;
- guards Poison Heal exact replacement semantics and overworld-only historical change while keeping it DATA_ONLY.

An intermediate local commit accidentally used `:=` in the new Python Shed Skin guard. It was detected before PR CI and corrected before the engineering candidate. The certified engineering SHA contains valid Python syntax; the first CI candidate for #89 was therefore `b161373a...`, not the erroneous intermediate commit.

## Architecture boundary
#89 adds **no new Battle Core primitive**.

Only runtime change:
- one Speed Boost registration in `BattleEffectRegistry` using already-existing END_TURN + stat-stage semantics.

Explicitly unchanged:
- `TurnExecutor`;
- `StatusSystem`;
- damage calculation;
- accuracy;
- weather/terrain;
- Trainer AI;
- held/trainer items.

Shed Skin and Poison Heal are represented only by provenance guards and negative runtime regressions.

## Engineering CI
Engineering SHA:
`b161373a70d0ed226259fe01f98b0d5cfcf677ed`

Result:
- **18/18 normal workflows SUCCESS**;
- DATA Foundation V3: **509 PASS / 0 FAIL**;
- Spanish/type/runtime regression: **298 PASS / 0 FAIL**;
- normalized import: 0 broken refs / 0 rejected definitions;
- Godot 4.7 global workflow: SUCCESS.

## Exact artifact drift — certified #88 final → #89 engineering
Compared tested DATA V3 artifacts:
- #88 final workflow run `33498859468`, artifact `9796883279`, head `64625cd8...`;
- #89 engineering workflow run `33500947846`, artifact `9797690332`, head `b161373a...`.

Both artifacts contain the same expected 15 files.

Raw `pokemon_api.json`:
- exactly one semantic change:
  - `speed_boost.classification: DATA_ONLY → RUNTIME_SUPPORTED`.

Normalized `pokemon_api.json`:
- exactly the same one-field change.

`unsupported_mechanics.json` set-level change:
- RUNTIME_SUPPORTED adds exactly `speed_boost`;
- DATA_ONLY removes exactly `speed_boost`;
- PARTIAL_RUNTIME set unchanged.

`pokeapi_v3_audit.json`:
- RUNTIME_SUPPORTED count **18 → 19**;
- DATA_ONLY count **341 → 340**;
- PARTIAL_RUNTIME remains **14**.

Explicitly unchanged:
- every other ability and field;
- Pokémon/species;
- moves/effects;
- items/statuses;
- learnsets/evolutions;
- types/stats;
- manifest;
- forms policy report;
- auxiliary report.

`import_time_ms 515 → 511 ms` is non-semantic execution timing noise.

## Ability coverage after #89 engineering
- `RUNTIME_SUPPORTED`: **19**.
- `PARTIAL_RUNTIME`: **14** — unchanged from #88.
- `DATA_ONLY`: **340**.
- total: **373**.

## Important blockers after #89
Newly pinned:
- `shed_skin`: full/runtime support requires version-aware probability semantics (33% vs 30% historical source).
- `poison_heal`: requires ability-aware poison residual replacement/suppression before ordinary residual damage is committed.

Existing blockers remain, including Water Bubble burn prevention, Dry Skin weather/Water absorption, Guts burn/sleep, Hustle accuracy, contact faint/per-strike ordering, Rough Skin/Transistor version-aware values, move-property metadata, super-effective predicates, Gorilla Tactics move lock/value provenance and Steely Spirit numeric/ally provenance.

## Final certification protocol
After engineering SHA `b161373a70d0ed226259fe01f98b0d5cfcf677ed`:
1. synchronize only `01_PROJECT_STATE.md`, `04_NEXT_STEPS.md`, and this notebook `19`;
2. verify engineering → final HEAD changes exactly those three notebooks;
3. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
4. close PR #89 without merge;
5. use that exact final SHA as the next certified baseline.

Do not make a post-close commit solely to record closure; GitHub PR state is authoritative.

## Next work after #89 closure
Continue DATA FOUNDATION V3 ability reliability from the exact certified #89 final HEAD. Select a bounded source-first group from the remaining **340 DATA_ONLY** records. Prefer abilities whose complete semantics already fit existing trigger/effect primitives. A negative audit is preferable to adding a broad subsystem for one ability.
