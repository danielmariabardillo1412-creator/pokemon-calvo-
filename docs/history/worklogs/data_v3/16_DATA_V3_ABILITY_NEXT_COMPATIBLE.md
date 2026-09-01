# DATA V3 ABILITY OFFENSIVE STAT MODIFIERS — V1

## Purpose
Operational record for PR #86, the bounded DATA FOUNDATION V3 ability tranche following certified PR #85.

Use together with:
- `01_PROJECT_STATE.md` for broad state;
- `04_NEXT_STEPS.md` for the live pointer;
- `07_DATA_V3_ABILITY_FAMILY_INVENTORY.md` for the original family frontier;
- `15_DATA_V3_ABILITY_CONTACT_DAMAGE.md` for the immediately preceding certified tranche.

## Certified parent
- PR #85: `DATA V3 — audit contact retaliation damage ability`.
- Certified final HEAD: `6909aa778eca6555184167401f5e52be11f46ac3`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Parent ability coverage: **13 RUNTIME_SUPPORTED / 10 PARTIAL_RUNTIME / 350 DATA_ONLY / 373 total**.

## PR #86
- Branch: `audit/data-v3-ability-next-compatible-v1`.
- Base branch: `audit/data-v3-ability-contact-damage-v1`.
- PR: #86 `DATA V3 — audit offensive stat ability modifiers`.
- Exact parent: certified #85 final `6909aa778eca6555184167401f5e52be11f46ac3`.
- First engineering candidate: `fd5a3f8d3138827c2cb6964bbe53bf3f9f524d5d` — DATA V3 **468 PASS / 3 FAIL**.
- Final corrected engineering SHA: `60281b7c016f8032a1f6c8f955cdfe2a727b58ac`.
- Corrected engineering SHA: **18/18 SUCCESS**.
- Corrected DATA V3 domain: **471 PASS / 0 FAIL**.

## Candidate-selection result
The bounded source-first audit selected four abilities that share one real battle concept: multiplying the effective offensive stat before the base damage formula.

Promoted to **RUNTIME_SUPPORTED**:
- `huge_power`;
- `pure_power`;
- `toxic_boost`;
- `flare_boost`.

This is not a keyword-based mass promotion. Each immutable source record was checked for generation, exact battle semantics and effect history before implementation.

## Immutable source contracts
### Huge Power
Pinned source: `data/api/v2/ability/37/index.json`.

Contract:
- main-series;
- Generation III;
- Attack is doubled in battle;
- the bonus does not count as a stat-stage modifier;
- source states it functions identically to Pure Power;
- `effect_changes=[]`.

Decision: **`huge_power → RUNTIME_SUPPORTED`**.

### Pure Power
Pinned source: `data/api/v2/ability/74/index.json`.

Contract:
- main-series;
- Generation III;
- Attack is doubled in battle;
- same non-stage-modifier semantics as Huge Power;
- functions identically to Huge Power;
- `effect_changes=[]`.

Decision: **`pure_power → RUNTIME_SUPPORTED`**.

### Toxic Boost
Pinned source: `data/api/v2/ability/137/index.json`.

Contract:
- main-series;
- Generation V;
- Attack becomes **1.5x** while poisoned;
- `effect_changes=[]`.

Runtime persistent-status model has both `poison` and `badly_poisoned`. Both are poison states for this source mechanic and are accepted by the trigger predicate.

Decision: **`toxic_boost → RUNTIME_SUPPORTED`**.

### Flare Boost
Pinned source: `data/api/v2/ability/138/index.json`.

Contract:
- main-series;
- Generation V;
- Special Attack becomes **1.5x** while burned;
- `effect_changes=[]`.

Decision: **`flare_boost → RUNTIME_SUPPORTED`**.

## Why final-damage multiplication was rejected
The existing ability `MODIFY_DAMAGE` path already had a generic final-damage `multiplier_bp`, but that is not the source mechanic for these four abilities.

For example, Huge Power says **Attack x2**, not **final damage x2**.

Because the damage formula uses integer arithmetic and floors inside the base formula, multiplying Attack before the formula can differ from multiplying the final damage after the formula. Treating these abilities as ordinary `multiplier_bp` effects would therefore be a semantic approximation.

The new focal suite deliberately uses an odd Attack value (`61`) and proves:
- Attack x2 before the formula produces a positive result;
- final damage x2 also produces a positive result;
- the two results are **not equal**.

This regression protects the architectural distinction from being simplified away later.

## Battle Core abstraction
### `BattleTriggerSystem`
`damage_modifiers()` now separates:
- `multiplier_basis_points` — existing final-damage modifier;
- `offensive_stat_multiplier_basis_points` — new effective Attack/Special Attack modifier;
- `immune` — existing immunity result.

Actor-owned MODIFY_DAMAGE trigger specs may now provide:
- `offensive_stat_multiplier_bp`.

A second generic condition was added:
- `required_persistent_status_ids`.

The condition succeeds only when the ability owner's current persistent status ID is in that explicit allowlist.

### `DamageCalculator`
A new optional argument is appended:

`offensive_stat_multiplier_basis_points: int = 10000`

It is applied after the normal stat-stage multiplier and **before the base damage formula**:

`effective_attack = staged_attack * offensive_stat_multiplier / 10000`

The damage result metadata now records:
- `offensive_stat_multiplier_basis_points`.

### Positional API compatibility
During implementation, the new argument was initially inserted before the existing `force_critical` parameter. Repository search showed historical tests using positional calls such as:

`..., 10000, 0`

where the final `0` means **force non-critical**.

Before the first CI run, the signature was corrected to preserve the historical order:
1. `damage_multiplier_basis_points`;
2. `force_critical`;
3. new `offensive_stat_multiplier_basis_points`.

The focal suite explicitly proves an old 8-argument call and a new explicit 9-argument call produce the same damage and non-critical result when the offensive multiplier is the default 10000.

### `BattleEffectExecutor`
The executor now passes both modifier channels independently:
- final-damage multiplier through the historical parameter;
- `-1` for default force-critical behavior;
- offensive-stat multiplier through the new appended parameter.

No move definition or generated dataset schema was changed for this abstraction.

## Runtime registrations
### Huge Power
`MODIFY_DAMAGE` actor trigger:
- `requires_physical=true`;
- `offensive_stat_multiplier_bp=20000`;
- no final `multiplier_bp`.

### Pure Power
Same exact trigger contract as Huge Power.

### Toxic Boost
`MODIFY_DAMAGE` actor trigger:
- `requires_physical=true`;
- `required_persistent_status_ids=["poison", "badly_poisoned"]`;
- `offensive_stat_multiplier_bp=15000`;
- no final `multiplier_bp`.

### Flare Boost
`MODIFY_DAMAGE` actor trigger:
- `requires_special=true`;
- `required_persistent_status_ids=["burn"]`;
- `offensive_stat_multiplier_bp=15000`;
- no final `multiplier_bp`.

## Source-contract layer
`tools/pokeapi_ability_runtime_contracts.py` now:
- classifies all four abilities as RUNTIME_SUPPORTED;
- validates their exact source generations;
- validates Attack / Special Attack wording and required numeric multiplier;
- rejects source-history drift by requiring no `effect_changes` for all four;
- removes Huge Power / Pure Power from the previous explicit DATA_ONLY blocker set.

Any future pinned-source change therefore forces a re-audit instead of silently preserving a stale runtime claim.

## Exact contract tests
`tests/data/data_foundation_v3_ability_runtime_contract_test_suite.gd` now requires:
- exact **17 RUNTIME_SUPPORTED** IDs;
- exact **10 PARTIAL_RUNTIME** IDs;
- exactly **346 DATA_ONLY**;
- exact 373 partition;
- exact implemented registry inventory;
- exact Huge/Pure physical 20000 offensive-stat triggers;
- exact Toxic Boost physical + poison/badly-poisoned 15000 trigger;
- exact Flare Boost special + burn 15000 trigger;
- none of these four may use final `multiplier_bp`.

`tests/data/data_foundation_v3_ability_family_inventory_test_suite.gd` adds only these four IDs to the explicit post-#76 promotion allowlist. The original 367-record frontier and family counts remain frozen.

## Real-battle focal suite
New suite:
`tests/data/data_foundation_v3_ability_offensive_stat_test_suite.gd`

Registered in:
`tests/data/data_foundation_v3_domain_test_runner.gd`.

It verifies:
1. Tackle is physical and Water Gun is special;
2. old positional `DamageCalculator` API remains compatible;
3. offensive-stat x2 is observably different from final-damage x2 with odd Attack;
4. Huge Power boosts physical damage and emits its ability event with 20000 offensive-stat metadata;
5. Huge Power is inert for special damage;
6. Pure Power matches Huge Power exactly under the same seed;
7. Toxic Boost activates for normal poison;
8. Toxic Boost activates identically for badly poisoned;
9. Toxic Boost is inert while clean;
10. Toxic Boost is inert for special attacks even while poisoned;
11. Flare Boost activates for burned special attacks;
12. Flare Boost is inert while clean;
13. Flare Boost is inert for physical attacks while burned, leaving the ordinary burn physical penalty unchanged.

## First CI failure — important root-cause record
First candidate:
`fd5a3f8d3138827c2cb6964bbe53bf3f9f524d5d`

DATA source audit, regeneration, raw invariants and import all passed. All new functional offensive-stat tests also passed.

DATA V3 domain ended:

**468 PASS / 3 FAIL**

The only failures were exact inventory ordering assertions:
- `data_v3_ability_contract_runtime_supported_exact`;
- `data_v3_ability_contract_registry_exact`;
- `data_v3_ability_contract_report_ids`.

### Root cause
Expected arrays ended with:

`..., torrent, toxic_boost, tough_claws`

but the canonical sorted output is:

`..., torrent, tough_claws, toxic_boost`

This was a lexicographic test expectation error only. Runtime semantics, source contracts, counts and all new real-battle tests were already passing.

### Correction history
The first correction commit changed only the runtime-contract test file, but a full-file replacement accidentally removed comment-only audit annotations. That did not alter execution, but it created unnecessary review noise.

A follow-up commit restored those comments. Comparing the original failed SHA to final corrected engineering SHA shows:
- one changed file;
- only the two expected-order swaps plus a final-file newline marker;
- no runtime, source-contract or classification change after the failed candidate.

Final corrected engineering SHA:
`60281b7c016f8032a1f6c8f955cdfe2a727b58ac`

Result:
- **18/18 SUCCESS**;
- DATA V3 **471 PASS / 0 FAIL**;
- Godot 4.7 global regression **SUCCESS**.

## Exact #85 → #86 engineering artifact drift
Compared:
- certified #85 final DATA V3 artifact from head `6909aa778eca6555184167401f5e52be11f46ac3`;
- successful #86 engineering artifact from head `60281b7c016f8032a1f6c8f955cdfe2a727b58ac`.

Both artifacts contain the same 15 expected files.

### Raw data
Exactly four ability records change, and on each record only `classification` changes:
- `flare_boost: DATA_ONLY → RUNTIME_SUPPORTED`;
- `huge_power: DATA_ONLY → RUNTIME_SUPPORTED`;
- `pure_power: DATA_ONLY → RUNTIME_SUPPORTED`;
- `toxic_boost: DATA_ONLY → RUNTIME_SUPPORTED`.

No other raw top-level domain changes.

### Normalized data
Exactly the same four one-field classification changes.

No other normalized top-level domain changes.

### Reports
`unsupported_mechanics.json`:
- RUNTIME_SUPPORTED **13 → 17**, adding exactly the four IDs above;
- PARTIAL_RUNTIME remains **10**;
- DATA_ONLY **350 → 346**, removing exactly those four IDs.

`pokeapi_v3_audit.json`:
- RUNTIME_SUPPORTED count **13 → 17**;
- DATA_ONLY count **350 → 346**;
- no other ability-count change.

### Explicitly unchanged
- every other ability record;
- species/Pokémon;
- moves and move effect specs;
- items/statuses;
- learnsets/evolutions;
- types/stats;
- `pokemon_api_manifest.json`;
- `forms_policy_report.json`;
- `pokeapi_v3_auxiliary.json`.

`import_summary.json` changes only `import_time_ms` **509 → 548 ms**, which is non-semantic execution timing noise.

## Ability coverage after #86 engineering
- `RUNTIME_SUPPORTED`: **17**
- `PARTIAL_RUNTIME`: **10** — `flame_body`, `gooey`, `heatproof`, `intimidate`, `iron_barbs`, `levitate`, `poison_point`, `reckless`, `stamina`, `static`
- `DATA_ONLY`: **346**
- total: **373**.

## Remaining explicit blockers
Do not reopen these merely to increase coverage:
- `iron_barbs`: per-strike + faint-safe/double-KO contact retaliation;
- `rough_skin`: version-aware ability value contract;
- `static`, `flame_body`, `poison_point`, `gooey`: fatal/per-strike contact policy;
- `water_compaction`: Water-specific AFTER_DAMAGE predicate;
- `weak_armor`: dual-stat transaction + per-hit/version semantics;
- `transistor`: version-sensitive multiplier;
- `long_reach`: effective-contact context exposing move user;
- `technician`: resolved/transactional move power;
- `iron_fist`, `strong_jaw`, `mega_launcher`, `sharpness`: provenance-backed move-category tags;
- `filter`, `solid_rock`: shared super-effective/effectiveness predicate;
- `fluffy`: modifier composition + ability-event aggregation;
- `heatproof`: burn residual interaction;
- `reckless`: crash-on-miss semantics.

## Final certification procedure
After syncing this notebook plus `01_PROJECT_STATE.md` and `04_NEXT_STEPS.md`:
1. compare engineering SHA `60281b7c016f8032a1f6c8f955cdfe2a727b58ac` to final HEAD;
2. require only notebook changes (`01`, `04`, `16`);
3. require **18/18 SUCCESS** on that exact notebook-bearing final HEAD;
4. close PR #86 without merge;
5. use the exact final HEAD as the next certified baseline.

## Next bounded work after #86 closure
Remain in DATA FOUNDATION V3 ability reliability. Select another small source-first subgroup from the remaining **346 DATA_ONLY** records whose semantics either fit existing abstractions cleanly or justify a genuinely shared primitive across multiple abilities.

A negative audit remains preferable to broadening Battle Core for coverage alone. Trainer AI/archetypes remain deferred.
