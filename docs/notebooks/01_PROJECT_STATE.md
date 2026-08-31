# PROJECT STATE NOTEBOOK

## Purpose / authority
Fast recovery for engineering work. GitHub commits, PR state, CI, immutable source and tested artifacts override this notebook on conflict.

## Certification policy
- Repo: `danielmariabardillo1412-creator/pokemon-calvo-`; Godot 4.7.
- Certified snapshots stay as closed PR branches **without merge**.
- New tranches start from the latest exact certified HEAD.
- Require all 18 normal workflows green on the same exact final SHA.
- Notebook commits move SHA, therefore the final notebook-bearing HEAD requires a second 18/18.
- Any focal/regression failure stops the tranche until root cause is fixed.

## DATA FOUNDATION V3 authority
Immutable source:
- branch `data/pokeapi-v2-snapshot`
- commit `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`
- API tree `8349ea1ce75716897fe96e02a15950d19edba6c3`
- schema tree `02e031e1928d7e9456bf6f7486daacc4b8946c84`
- `data/api/v2`, `data/schema/v2` are read-only.

Structural facts: 1,025 species; 326 forms; 18 runtime types; 919 runtime moves; 373 abilities; 2,222 items; 61,102 learnset entries; 554 evolutions; 0 broken refs; 0 rejected defs; 18 XD Shadow moves explicitly excluded.

Pipeline:
`snapshot → V3 adapter → narrow semantic audit layers → raw JSON → Godot DataImporter → normalized data → runtime`.

## Recent certified chain
- #75 final DATA_ONLY executable effects `4bb4bdc64982eef62f126f8d1c38e9509d21c96c`
- #76 initial ability runtime contracts `a596a38680b60db317f1dfd6b6beb8d7ded7b813`
- #77 ability family inventory + Swarm `78da22438d0866193b0d1154814464531ac55641`
- #78 unconditional ability type boosts `eda483d9cd6423d32bdf1a156372416b2fbcb639`
- #79 hit-triggered stat reactions `5b9ad561017fc4c209d6fd11ef9ddc7dbf3fbd71`
- #80 contact damage + attack-doubling audit `232a3e787fe2d7d58b1feb693272b63bd7a699bf`
- #81 defensive damage modifiers `e2eeef1d23def1d9fd124b5e2eeb437270212b68`

All entries above: **18/18 SUCCESS on exact final notebook-bearing HEAD and closed without merge**.

## Move Effects V3 closed milestone
Move coverage remains:
- `RUNTIME_SUPPORTED`: **590**
- `PARTIAL_RUNTIME`: **71**
- `DATA_ONLY`: **246**
- `UNSUPPORTED`: **12**
- `DATA_ONLY` with executable `effect_specs`: **0**.

## Ability coverage principle
Preserved metadata is not executable support.
- `RUNTIME_SUPPORTED`: modeled battle mechanic is faithful.
- `PARTIAL_RUNTIME`: useful faithful subset works but known source-required behavior is absent.
- `DATA_ONLY`: data retained without claiming executable mechanics.

Battle Core ability execution is controlled by trigger registration; DATA V3 classification describes semantic completeness.

## Certified ability baseline — PR #81
Detailed notebooks: `06`, `07`, `08`, `09`, `10`, `11`.

Certified #81 coverage:
- `RUNTIME_SUPPORTED`: **11**
- `PARTIAL_RUNTIME`: **4** — `intimidate`, `levitate`, `stamina`, `static`
- `DATA_ONLY`: **358**
- total: **373**.

# Current tranche — PR #82 Defensive predicates
- Branch: `audit/data-v3-ability-defensive-predicates-v2`.
- Parent: certified #81 final `e2eeef1d23def1d9fd124b5e2eeb437270212b68`.
- PR: #82 `DATA V3 — audit defensive predicate abilities`.
- Engineering SHA: `60edf8b7be9225f7670c6dd5039713e4b621163e`.
- Engineering SHA: **18/18 SUCCESS**.
- Detailed notebook: `docs/notebooks/12_DATA_V3_ABILITY_DEFENSIVE_PREDICATES.md`.

## #82 decisions
### Ice Scales
Source: Generation VIII/main-series; halves special-move damage; no effect history.
Runtime: target-side `MODIFY_DAMAGE`, `requires_special=true`, `multiplier_bp=5000`.
Decision: **RUNTIME_SUPPORTED**.

### Multiscale
Source: Generation V/main-series; halves move damage while at full HP; no effect history.
Runtime: target-side `MODIFY_DAMAGE`, `requires_full_hp=true`, `multiplier_bp=5000`.
Decision: **RUNTIME_SUPPORTED**.

`MULTI_HIT` calls `_damage()` per strike, so the full-HP condition is reevaluated each hit. Real-battle integration with canonical two-hit `double_kick` proves only hit one is reduced and exactly one Multiscale trigger is emitted.

### Heatproof
Source: Generation IV/main-series; halves Fire-move damage and burn residual damage; no effect history.
Runtime currently implements only Fire-move reduction: `move_type_id=fire`, `multiplier_bp=5000`.
Decision: **PARTIAL_RUNTIME** because burn residual is still calculated directly by `StatusSystem.process_end_turn()` without an ability modifier hook. A regression test explicitly proves burn damage remains unchanged under Heatproof.

### Filter / Solid Rock
Both require a super-effective predicate and remain **DATA_ONLY**. Current effectiveness is produced inside `DamageCalculator.calculate()` after `damage_modifiers()` runs. Do not duplicate type-chart logic in the ability layer solely for coverage.

## #82 Battle Core change
Only two generic condition keys were added:
- `requires_special=true`, mirror of existing `requires_physical`;
- `requires_full_hp=true`, exact owner `current_hp == max_hp`.

The target multiplier path from #81 is reused. No new trigger type, damage formula, weather/status/party/form/item machinery or effectiveness duplication was introduced.

## #82 artifact drift
Certified #81 → successful #82 engineering artifact:
- raw: exactly `ice_scales`, `multiscale`, `heatproof` change classification and no other field;
- normalized: exactly the same three classification-only changes;
- `ice_scales`: DATA_ONLY → RUNTIME_SUPPORTED;
- `multiscale`: DATA_ONLY → RUNTIME_SUPPORTED;
- `heatproof`: DATA_ONLY → PARTIAL_RUNTIME;
- `unsupported_mechanics.json`: 11→13 runtime, 4→5 partial, 358→355 data-only;
- `pokeapi_v3_audit.json`: exactly those same three count changes and nothing else;
- every other ability, species, move/effect, item/status, learnset/evolution, type/stat, manifest/forms/auxiliary unchanged;
- `import_time_ms` 505→506 ms is non-semantic.

## Ability coverage after #82 engineering
- `RUNTIME_SUPPORTED`: **13**
- `PARTIAL_RUNTIME`: **5** — `heatproof`, `intimidate`, `levitate`, `stamina`, `static`
- `DATA_ONLY`: **355**
- total: **373**.

## Known blockers after #82
- `filter`, `solid_rock`: need a shared super-effective/effectiveness predicate.
- `heatproof`: full support needs burn residual ability interaction.
- `fluffy`: needs modifier composition/event aggregation to avoid duplicate logical trigger events.
- `huge_power`, `pure_power`: need genuine offensive-stat multiplier abstraction.
- `transistor`: version-sensitive multiplier contract unresolved.
- `water_compaction`: requires Water-specific AFTER_DAMAGE predicate.
- `weak_armor`: requires dual stat transaction plus per-hit/version semantics.

## Current certification step
Notebook synchronization follows engineering SHA `60edf8b7be9225f7670c6dd5039713e4b621163e`.

Before closing #82:
1. verify engineering → final HEAD changes only `01`, `04`, `12` notebooks;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #82 without merge;
4. use exact final SHA as next certified baseline.

## Exact next work after #82
Continue DATA FOUNDATION V3 ability reliability with another bounded family selected by source semantics and current primitives. Do not broaden Battle Core merely to improve the coverage number. Trainer AI/archetypes remain deferred.
