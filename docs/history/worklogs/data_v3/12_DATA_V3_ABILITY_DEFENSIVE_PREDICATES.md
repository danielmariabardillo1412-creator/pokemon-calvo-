# DATA V3 ABILITY DEFENSIVE PREDICATES — V1

## Purpose
Operational record for the bounded ability tranche following certified PR #81.

## Certified parent
- PR #81: `DATA V3 — audit defensive damage ability modifiers`.
- Certified final HEAD: `e2eeef1d23def1d9fd124b5e2eeb437270212b68`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Parent ability coverage: **11 RUNTIME_SUPPORTED / 4 PARTIAL_RUNTIME / 358 DATA_ONLY / 373 total**.

## PR #82
- Branch: `audit/data-v3-ability-defensive-predicates-v2`.
- Exact parent: `e2eeef1d23def1d9fd124b5e2eeb437270212b68`.
- PR: #82 `DATA V3 — audit defensive predicate abilities`.
- Engineering SHA: `60edf8b7be9225f7670c6dd5039713e4b621163e`.
- Engineering SHA: **18/18 SUCCESS**, including DATA V3 and Godot 4.7 global.

## Source decisions

### Ice Scales — RUNTIME_SUPPORTED
Pinned source `data/api/v2/ability/246/index.json`:
- main-series Generation VIII;
- halves damage taken from special moves;
- `effect_changes=[]`.

Current/public mechanics were also cross-checked: the ability modifies special-move damage but not direct/fixed damage. Current DATA V3 direct/fixed-damage examples remain DATA_ONLY, so there is no hidden executable gap.

Runtime:
- target-side `MODIFY_DAMAGE`;
- `requires_special=true`;
- `multiplier_bp=5000`.

### Multiscale — RUNTIME_SUPPORTED
Pinned source `data/api/v2/ability/136/index.json`:
- main-series Generation V;
- halves damage taken while the owner is at full HP;
- `effect_changes=[]`.

Current/public mechanics were cross-checked:
- direct/fixed damage is not reduced;
- for a multistrike move starting at full HP, only the first hit is reduced once that hit removes the full-HP condition.

Battle Core already executes `_damage()` separately for each MULTI_HIT strike, and `_damage()` reevaluates `damage_modifiers()` on every strike. Therefore the generic full-HP predicate naturally rechecks after hit one.

Runtime:
- target-side `MODIFY_DAMAGE`;
- `requires_full_hp=true`;
- `multiplier_bp=5000`.

The certified #81 artifact contained 27 RUNTIME_SUPPORTED multihit moves. Focal integration uses canonical `double_kick`, a fixed two-hit physical move: hit one is reduced, hit two equals the no-ability control, and exactly one Multiscale trigger event is emitted.

### Heatproof — PARTIAL_RUNTIME
Pinned source `data/api/v2/ability/85/index.json`:
- main-series Generation IV;
- halves damage from Fire-type moves **and burns**;
- `effect_changes=[]`.

Runtime implements the faithful Fire-move subset:
- target-side `MODIFY_DAMAGE`;
- `move_type_id=fire`;
- `multiplier_bp=5000`.

It is intentionally **PARTIAL_RUNTIME**, not full. `StatusSystem.process_end_turn()` computes burn residual damage directly and currently exposes no ability-modifier hook. A regression test verifies Heatproof and the no-ability control receive identical burn residual damage, making the missing semantic explicit rather than silently overclaiming support.

### Filter / Solid Rock — remain DATA_ONLY
Both pinned Generation IV sources say the owner takes 0.75x damage from moves that are super effective against it, and each says it functions identically to the other. Both have `effect_changes=[]`.

Current `damage_modifiers()` runs before `DamageCalculator.calculate()` produces the effectiveness result. There is no certified generic `requires_super_effective` predicate. Do not duplicate type-chart/effectiveness computation in the ability layer solely to increase coverage.

Both records now have source guards and regression tests that require DATA_ONLY plus no runtime mapping.

## Battle Core extension
Only two generic predicates were added to the existing condition evaluator:
- `requires_special=true`: exact mirror of `requires_physical`;
- `requires_full_hp=true`: owner `current_hp == max_hp`.

The target-side multiplier path from #81 is reused unchanged. No new trigger kind, no parallel damage formula, and no weather/status/party/form/item/effectiveness architecture were introduced.

## Focal integration
Extended `tests/data/data_foundation_v3_ability_defensive_damage_test_suite.gd` verifies real battles:
- Ice Scales reduces special Water Gun and is inert for physical Tackle;
- Multiscale reduces ordinary damage at full HP and is inert after one point of pre-damage;
- Multiscale + canonical two-hit Double Kick reduces only hit one and emits exactly one ability trigger;
- Heatproof reduces Ember and is inert for Water Gun;
- Heatproof burn residual remains unchanged versus control, documenting its partial boundary.

Registry/source-contract tests verify exact predicates, classifications and blockers. The family inventory allowlist remains explicit, preserving the no-mass-promotion invariant.

## Engineering certification
Engineering SHA:
`60edf8b7be9225f7670c6dd5039713e4b621163e`

Result: **18/18 SUCCESS**.

DATA Foundation V3 completed successfully through:
- immutable source audit;
- regeneration;
- raw invariants;
- Godot import;
- domain tests;
- normalization;
- Spanish/type/runtime regression;
- artifact upload.

Global Godot and all trainer workflows also passed.

## Exact #81 → #82 artifact drift
Successful certified #81 artifact compared with successful #82 engineering artifact.

Raw abilities — exactly three changed IDs:
- `ice_scales`: `classification DATA_ONLY → RUNTIME_SUPPORTED`;
- `multiscale`: `classification DATA_ONLY → RUNTIME_SUPPORTED`;
- `heatproof`: `classification DATA_ONLY → PARTIAL_RUNTIME`.

For all three, **classification is the only changed field**. No description/effect-summary correction occurs.

Normalized data contains exactly the same three classification-only changes.

`unsupported_mechanics.json`:
- `RUNTIME_SUPPORTED`: 11 → 13;
- `PARTIAL_RUNTIME`: 4 → 5;
- `DATA_ONLY`: 358 → 355;
- only the three expected IDs move between classification lists.

`pokeapi_v3_audit.json` changes exactly three values and nothing else:
- `ability_classification_counts.RUNTIME_SUPPORTED`: 11 → 13;
- `ability_classification_counts.PARTIAL_RUNTIME`: 4 → 5;
- `ability_classification_counts.DATA_ONLY`: 358 → 355.

Explicitly unchanged:
- every other ability, including Filter and Solid Rock;
- species/Pokémon;
- moves/effects;
- items/statuses;
- learnsets/evolutions;
- types/stats;
- manifest/forms/auxiliary.

`import_time_ms` 505 → 506 ms is non-semantic timing noise.

## Coverage after #82 engineering
- `RUNTIME_SUPPORTED`: **13**
- `PARTIAL_RUNTIME`: **5** — `heatproof`, `intimidate`, `levitate`, `stamina`, `static`
- `DATA_ONLY`: **355**
- total: **373**.

## Final certification procedure
After syncing this notebook plus `01_PROJECT_STATE.md` and `04_NEXT_STEPS.md`:
1. compare engineering SHA `60edf8b7be9225f7670c6dd5039713e4b621163e` to final HEAD;
2. require only notebook changes (`01`, `04`, `12`);
3. require **18/18 SUCCESS** on that exact final notebook-bearing HEAD;
4. close PR #82 without merge;
5. use that exact final HEAD as the next certified baseline.

## Next bounded work after #82 closure
Remain in DATA FOUNDATION V3 ability reliability. Do not force Filter/Solid Rock until effectiveness is available through a proper shared contract, do not upgrade Heatproof until burn residual can consult abilities, and do not shortcut Fluffy by duplicating logical activation events. Audit another small family against existing primitives first.
