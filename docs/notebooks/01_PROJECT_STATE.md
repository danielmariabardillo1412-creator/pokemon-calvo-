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

## Certified ability baseline — PR #80
Detailed notebooks: `06`, `07`, `08`, `09`, `10`.

Certified #80 coverage:
- `RUNTIME_SUPPORTED`: **9** — `blaze`, `dragons_maw`, `fire_mane`, `overgrow`, `rocky_payload`, `steelworker`, `swarm`, `torrent`, `tough_claws`
- `PARTIAL_RUNTIME`: **4** — `intimidate`, `levitate`, `stamina`, `static`
- `DATA_ONLY`: **360**
- total: **373**.

Known partial reasons:
- `intimidate`: switch-in Attack drop works; additional acquisition/Substitute semantics absent.
- `levitate`: Ground move immunity works; grounding/suppression/field interactions absent.
- `static`: ordinary surviving contact reaction works; fatal-contact trigger gap remains.
- `stamina`: ordinary surviving damaging hit gives Defense +1; current AFTER_DAMAGE is once per completed move and excludes fainted owners, so per-hit/fatal-hit semantics are incomplete.

Known blockers:
- `transistor`: version-sensitive multiplier not honestly represented by pinned source.
- `water_compaction`: requires a Water-specific AFTER_DAMAGE predicate.
- `weak_armor`: requires dual stat transaction plus per-hit/version semantics.
- `huge_power`, `pure_power`: source doubles Attack stat; require genuine offensive-stat multiplier abstraction.
- `fluffy`: simultaneous Fire/contact modifier composition would currently duplicate ability-trigger events.

# Current tranche — PR #81 Defensive damage modifiers
- Branch: `audit/data-v3-ability-existing-predicate-scan-v1`.
- Parent: certified #80 final `232a3e787fe2d7d58b1feb693272b63bd7a699bf`.
- PR: #81 `DATA V3 — audit defensive damage ability modifiers`.
- Detailed notebook: `docs/notebooks/11_DATA_V3_ABILITY_EXISTING_PREDICATE_SCAN.md`.

## #81 decisions
### Fur Coat
Source: Generation VI/main-series, halves physical-attack damage, no effect history.
Runtime: target-side `MODIFY_DAMAGE`, `requires_physical=true`, `multiplier_bp=5000`.
Decision: **RUNTIME_SUPPORTED**.

### Thick Fat
Source: Generation III/main-series, half damage from Fire- and Ice-type moves, no effect history.
Runtime: two mutually exclusive target-side type rules, Fire/Ice, each `multiplier_bp=5000`.
Decision: **RUNTIME_SUPPORTED**.

### Fluffy
Source: halves contact damage and doubles Fire damage.
Decision: remains **DATA_ONLY** because a Fire contact move would satisfy both current specs and produce duplicate logical ability-trigger events. Needs explicit modifier/event aggregation first.

## #81 Battle Core change
Target-side `MODIFY_DAMAGE` now supports ordinary `multiplier_bp` specs through the already-existing `_damage_condition_matches` surface while preserving `immune_type_id` behavior. No new predicate type or broad battle state was added.

## #81 focal/CI incident
Initial engineering SHA `bc6fcd7914bb0707a3cab302d67e1ac9af6dcee5` failed DATA V3 with **419 PASS / 3 FAIL** because the new test helper read nonexistent `BattleEvent.source_id`.

`BattleEvent` exposes `actor_id`; the helper was corrected in exactly one line. Failed SHA → corrected SHA changed only the defensive test file (1 addition / 1 deletion). Runtime code did not change after the failure.

Corrected engineering SHA:
`7d79fa4ed5deb1cb693518c4d326707b73ba94ba`

Result: **18/18 SUCCESS**.

## #81 artifact drift
Successful #80 → corrected #81 engineering artifact:
- raw: only `fur_coat.classification` and `thick_fat.classification` change `DATA_ONLY → RUNTIME_SUPPORTED`;
- normalized: exactly the same two changes;
- reports: runtime 9→11, partial stays 4, data-only 360→358;
- Fluffy unchanged;
- all other abilities/species/moves/items/statuses/learnsets/evolutions/types/stats unchanged;
- manifest/forms/auxiliary unchanged;
- `import_time_ms` 495→530 ms is non-semantic.

## Ability coverage after #81 engineering
- `RUNTIME_SUPPORTED`: **11**
- `PARTIAL_RUNTIME`: **4**
- `DATA_ONLY`: **358**
- total: **373**.

## Current certification step
Notebook sync follows corrected engineering SHA `7d79fa4ed5deb1cb693518c4d326707b73ba94ba`.

Before closing #81:
1. verify engineering → final HEAD changes only `01`, `04`, `11` notebooks;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #81 without merge;
4. use exact final SHA as next certified baseline.

## Exact next work after #81
Continue DATA FOUNDATION V3 ability reliability with another bounded subgroup. Do not implement Fluffy by duplicating events. Candidates such as Heatproof/Ice Scales/full-HP or effectiveness reducers require fresh contract audits and possibly predicates not currently available; do not assume support.

Trainer AI/archetypes remain deferred.
