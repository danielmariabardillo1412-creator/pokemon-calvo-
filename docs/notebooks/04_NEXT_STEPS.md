# NEXT STEPS — LIVE CHECKPOINT

Read immediately after `00_READ_FIRST.md` when recovering context.

## Latest certified baseline
- PR #85 — `audit/data-v3-ability-contact-damage-v1`
- Final HEAD `6909aa778eca6555184167401f5e52be11f46ac3`
- **18/18 SUCCESS** on exact notebook-bearing HEAD
- closed without merge.

Move Effects V3 remains closed:
- **590 runtime / 71 partial / 246 data-only / 12 unsupported**;
- `DATA_ONLY` moves with executable `effect_specs`: **0**.

Certified #85 ability coverage:
- `RUNTIME_SUPPORTED`: **13**
- `PARTIAL_RUNTIME`: **10** — `flame_body`, `gooey`, `heatproof`, `intimidate`, `iron_barbs`, `levitate`, `poison_point`, `reckless`, `stamina`, `static`
- `DATA_ONLY`: **350**
- total: **373**.

Prior detailed ability notebooks: `06` through `15`.

# Current tranche — PR #86
- Branch: `audit/data-v3-ability-next-compatible-v1`
- Parent: certified #85 final `6909aa778eca6555184167401f5e52be11f46ac3`
- PR: #86 `DATA V3 — audit offensive stat ability modifiers`
- First candidate `fd5a3f8d3138827c2cb6964bbe53bf3f9f524d5d`: DATA V3 **468 PASS / 3 FAIL**.
- Corrected engineering SHA: `60281b7c016f8032a1f6c8f955cdfe2a727b58ac`
- Corrected engineering SHA: **18/18 SUCCESS**.
- Corrected DATA V3 domain: **471 PASS / 0 FAIL**.
- Detailed notebook: `docs/notebooks/16_DATA_V3_ABILITY_NEXT_COMPATIBLE.md`.

## #86 result
Promoted to **RUNTIME_SUPPORTED**:
- `huge_power` — Attack x2;
- `pure_power` — Attack x2;
- `toxic_boost` — Attack x1.5 while poisoned;
- `flare_boost` — Special Attack x1.5 while burned.

All four pinned source records are main-series, have the expected generation/value semantics and no `effect_changes`.

Toxic Boost accepts both runtime poison states: `poison` and `badly_poisoned`.

## Shared Battle Core abstraction
Do **not** model these abilities with the existing final-damage `multiplier_bp`.

New channel:
- `offensive_stat_multiplier_basis_points`.

`DamageCalculator` applies it to effective staged Attack/Special Attack **before** the base damage formula.

`BattleTriggerSystem` now returns final-damage and offensive-stat modifiers separately and supports generic `required_persistent_status_ids`.

A direct regression with odd Attack proves Attack x2 is not equivalent to final damage x2 under integer flooring.

## Positional API compatibility
Historical calculator calls use positional `..., damage_multiplier, force_critical` arguments. The new offensive-stat parameter is therefore appended **after** `force_critical`.

The focal suite pins compatibility between old 8-argument use and explicit 9-argument default use.

## First CI failure — fixed in exact inventory expectations
All new functional tests passed on the first candidate. Only three exact sorted-list assertions failed because expected arrays placed:

`toxic_boost` before `tough_claws`.

Canonical lexical order is:

`tough_claws` before `toxic_boost`.

No runtime/source/classification change was required. Comment-only audit annotations accidentally removed during the first correction were restored before selecting the final engineering SHA.

Corrected result: **18/18 SUCCESS**, DATA V3 **471 PASS / 0 FAIL**.

## Exact #85 → #86 artifact
Raw + normalized:
- exactly four semantic differences;
- `flare_boost.classification: DATA_ONLY → RUNTIME_SUPPORTED`;
- `huge_power.classification: DATA_ONLY → RUNTIME_SUPPORTED`;
- `pure_power.classification: DATA_ONLY → RUNTIME_SUPPORTED`;
- `toxic_boost.classification: DATA_ONLY → RUNTIME_SUPPORTED`.

Reports:
- runtime **13→17**;
- partial remains **10**;
- data-only **350→346**.

Explicitly unchanged:
- every other ability;
- Pokémon/species;
- moves/effects;
- items/statuses;
- learnsets/evolutions;
- types/stats;
- manifest/forms/auxiliary.

`import_time_ms 509→548 ms` is non-semantic.

## Ability coverage after #86 engineering
- `RUNTIME_SUPPORTED`: **17**
- `PARTIAL_RUNTIME`: **10**
- `DATA_ONLY`: **346**
- total: **373**.

## Current certification step
Notebook synchronization now moves the branch after engineering SHA `60281b7c016f8032a1f6c8f955cdfe2a727b58ac`.

Before closing #86:
1. verify engineering SHA → final HEAD changes only `01_PROJECT_STATE.md`, `04_NEXT_STEPS.md`, `16_DATA_V3_ABILITY_NEXT_COMPATIBLE.md`;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #86 without merge;
4. use exact final HEAD as the next baseline.

## Exact next task after #86 closure
Continue **DATA FOUNDATION V3 ability reliability** with one bounded source-first subgroup selected from the remaining **346 DATA_ONLY** abilities.

Keep explicit blockers closed until their shared semantics genuinely exist: version-aware ability values, per-strike/faint-safe contact reactions, resolved move-power/property metadata, super-effective predicates, compound modifier/event aggregation, residual-damage hooks, or dual-stat/per-hit transactions as appropriate.

Trainer AI/archetypes remain deferred.

## Stop condition
Any focal/regression failure stops the tranche until root cause is fixed and rerun.
