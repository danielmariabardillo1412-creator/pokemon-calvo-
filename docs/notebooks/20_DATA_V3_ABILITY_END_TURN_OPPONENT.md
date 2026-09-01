# DATA V3 ABILITY END-TURN OPPONENT AUDIT — V1

## Purpose
Operational record for the bounded negative DATA V3 ability-reliability tranche following certified PR #89.

## Certified parent
- PR #89: `DATA V3 — audit end-turn ability semantics`.
- Certified final HEAD: `407ad8f27d13a79b09c367aac2f6ae0c1ef801ef`.
- Parent status: **18/18 workflows SUCCESS**, closed without merge.
- Parent ability coverage: **19 RUNTIME_SUPPORTED / 14 PARTIAL_RUNTIME / 340 DATA_ONLY / 373 total**.

## Current tranche
- Branch: `audit/data-v3-ability-end-turn-opponent-v1`.
- PR: #90 `DATA V3 — audit opponent end-turn ability blockers`.
- Exact parent: certified #89 final `407ad8f27d13a79b09c367aac2f6ae0c1ef801ef`.
- Engineering SHA: `52fafcc035dd46824bf9f0f6239cc93363981998`.
- Engineering certification: **18/18 workflows SUCCESS**.
- DATA Foundation V3: **516 PASS / 0 FAIL**.
- Spanish/type/runtime regression: **298 PASS / 0 FAIL**.
- Normalized import: **0 broken refs / 0 rejected definitions**.

## Bounded candidate set
- `bad_dreams`;
- `rain_dish`;
- `ice_body`.

This tranche is intentionally negative: source and runtime were audited first, and none of the three can be represented completely without semantics absent from current Battle Core.

## Bad Dreams — source contract and blocker
Immutable source: `data/api/v2/ability/123/index.json`.

Pinned contract:
- main-series;
- Generation IV;
- opposing Pokémon lose **1/8 max HP after each turn while asleep**;
- no `effect_changes`.

### What Battle Core already has
`BattleEffectSpec.MAX_HP_DAMAGE` supports ratio-based max-HP damage and `BattleEffectSpec.OPPONENT` resolves the effect recipient to the opposing active Pokémon.

Therefore the damage transaction itself is representable as opponent 1/8 max-HP damage.

### What Battle Core lacks
`BattleTriggerSystem.conditions_met(spec, owner, move)` evaluates `required_persistent_status_ids` against:
`owner.status_state.persistent_id`.

END_TURN routing in `TurnExecutor` executes each owner's triggers with the opponent supplied as effect target, but trigger conditions are still checked against the owner only.

Consequently the current predicate can express:
- “the Bad Dreams holder is asleep”;

but it cannot express:
- “the opposing Pokémon is asleep”.

Using the existing condition would therefore invert the required subject. Omitting the condition would damage awake opponents. Both are false semantics.

Decision: **`bad_dreams` remains DATA_ONLY**.

No `target_status` predicate is introduced solely to raise coverage for one ability.

### Runtime proof
New test creates a synthetic END_TURN condition with `required_persistent_status_ids=[sleep]`:
- awake owner → condition false;
- sleeping owner → condition true.

This pins owner-local semantics directly.

A real `AuthoritativeBattleServer` battle then runs a Bad Dreams holder against a sleeping opponent. The sleeping opponent:
- remains asleep;
- loses no HP from Bad Dreams;
- produces no Bad Dreams `ABILITY_TRIGGERED` event.

That is the correct current fail-safe behavior until target-state gating exists.

## Rain Dish — source contract and blocker
Immutable source: `data/api/v2/ability/44/index.json`.

Pinned contract:
- main-series;
- Generation III;
- heals **1/16 max HP after each turn during rain**;
- no `effect_changes`.

The HEAL + SELF transaction is representable, but repository-wide battle-state search found no weather state or trigger-condition surface capable of proving rain is active.

An unconditional end-turn heal would be false semantics.

Decision: **`rain_dish` remains DATA_ONLY**.

Do not add weather architecture solely for this ability.

## Ice Body — source contract and blocker
Immutable source: `data/api/v2/ability/115/index.json`.

Pinned contract:
- main-series;
- Generation IV;
- heals **1/16 max HP after each turn during hail**;
- does not take hail damage regardless of type;
- no `effect_changes`.

Current battle state exposes neither weather state nor a hail residual transaction. Even a future conditional heal alone would not be the full ability because hail-damage immunity is also source-required.

Decision: **`ice_body` remains DATA_ONLY**.

## Architecture boundary
#90 changes **no production/runtime code**.

Explicitly unchanged:
- `BattleEffectRegistry`;
- `BattleTriggerSystem`;
- `BattleEffectExecutor`;
- `TurnExecutor`;
- `BattleState`;
- `StatusSystem`;
- adapter/runtime contracts;
- all ability classifications;
- Trainer AI;
- items;
- weather/terrain architecture.

The only technical additions are a DATA V3 regression suite and one runner registration line.

## New tests
`tests/data/data_foundation_v3_ability_end_turn_opponent_test_suite.gd` adds seven checks:
1. `data_v3_bad_dreams_source_contract`;
2. `data_v3_rain_dish_source_contract`;
3. `data_v3_ice_body_source_contract`;
4. `data_v3_end_turn_opponent_blockers_stay_data_only`;
5. `data_v3_bad_dreams_existing_status_predicate_is_owner_local`;
6. `data_v3_bad_dreams_sleeping_target_gap_explicit`;
7. `data_v3_end_turn_opponent_negative_audit_preserves_counts`.

The source-contract tests read the immutable snapshot JSON directly so upstream/source drift forces re-audit even though no adapter classification changes in this tranche.

DATA V3 domain total:
- #89: **509 PASS / 0 FAIL**;
- #90 engineering: **516 PASS / 0 FAIL**.

## Engineering CI
Engineering SHA:
`52fafcc035dd46824bf9f0f6239cc93363981998`

Result:
- **18/18 normal workflows SUCCESS**;
- DATA Foundation V3: **516 PASS / 0 FAIL**;
- Spanish/type/runtime: **298 PASS / 0 FAIL**;
- normalized import: 0 broken refs / 0 rejected definitions;
- Godot 4.7 global workflow: SUCCESS.

## Exact tested artifact comparison — #89 final → #90 engineering
Certified #89 final:
- workflow run `33501387360`;
- artifact `9797865183`;
- head `407ad8f27d13a79b09c367aac2f6ae0c1ef801ef`.

#90 engineering:
- workflow run `33502577117`;
- artifact `9798322866`;
- head `52fafcc035dd46824bf9f0f6239cc93363981998`.

Both artifact ZIPs contain the same expected 15 files.

JSON-semantic equality is exact for:
- `data/raw/pokemon_api.json`;
- `data/normalized/pokemon_api.json`;
- `data/manifests/pokemon_api_manifest.json`;
- `data/reports/forms_policy_report.json`;
- `data/reports/unsupported_mechanics.json`;
- `data/reports/pokeapi_v3_audit.json`;
- `data/reports/pokeapi_v3_auxiliary.json`.

Therefore there is **zero canonical data drift**:
- every Pokémon/species unchanged;
- every move/effect unchanged;
- every ability record/classification unchanged;
- every item/status unchanged;
- every learnset/evolution unchanged;
- every type/stat unchanged;
- all classification sets/counts unchanged.

Only `data/reports/import_summary.json` differs by:
- `import_time_ms: 513 → 509`.

This is non-semantic execution timing noise.

## Ability coverage after #90 engineering
Exactly unchanged from certified #89:
- RUNTIME_SUPPORTED: **19**;
- PARTIAL_RUNTIME: **14**;
- DATA_ONLY: **340**;
- total: **373**.

## Safety conclusion
The negative result is valuable and intentional:
- Bad Dreams is blocked by **condition subject/direction**, not by missing damage effect;
- Rain Dish is blocked by **weather state**;
- Ice Body is blocked by **weather state plus weather residual immunity**.

No false approximation was introduced to make the support count look larger.

## Final certification protocol
After engineering SHA `52fafcc035dd46824bf9f0f6239cc93363981998`:
1. synchronize only `01_PROJECT_STATE.md`, `04_NEXT_STEPS.md`, and this notebook `20`;
2. verify engineering → final HEAD changes exactly those three notebooks;
3. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
4. close PR #90 without merge;
5. use that exact final SHA as the next certified baseline.

Do not make a post-close commit solely to record closure; GitHub PR state is authoritative.

## Next work after #90 closure
Continue DATA FOUNDATION V3 ability reliability from exact certified #90 final HEAD.

Do not immediately implement weather just because Rain Dish/Ice Body exposed it. Do not add target-status solely for Bad Dreams. First audit another bounded source-backed group and determine whether an existing primitive is sufficient or whether a missing condition is genuinely shared by multiple abilities.

A negative audit remains preferable to speculative architecture or coverage inflation.
