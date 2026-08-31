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

## Certified ability baseline — PR #79
Detailed notebooks:
- `06_DATA_V3_ABILITY_RUNTIME_AUDIT.md`
- `07_DATA_V3_ABILITY_FAMILY_INVENTORY.md`
- `08_DATA_V3_ABILITY_TYPE_BOOSTS.md`
- `09_DATA_V3_ABILITY_HIT_STAT_REACTIONS.md`

Certified #79 coverage:
- `RUNTIME_SUPPORTED`: **8** — `blaze`, `dragons_maw`, `fire_mane`, `overgrow`, `rocky_payload`, `steelworker`, `swarm`, `torrent`
- `PARTIAL_RUNTIME`: **4** — `intimidate`, `levitate`, `stamina`, `static`
- `DATA_ONLY`: **361**
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

# Current tranche — PR #80

- Branch: `audit/data-v3-ability-stat-damage-modifiers-v2`.
- Parent: certified #79 final `5b9ad561017fc4c209d6fd11ef9ddc7dbf3fbd71`.
- PR: #80 `DATA V3 — audit contact damage and attack-doubling abilities`.
- Engineering SHA: `fecf7995e0284a0c7111239107aa3762f4e1233f`.
- Engineering SHA: **18/18 SUCCESS**, including DATA V3 and Godot global.
- Detailed notebook: `docs/notebooks/10_DATA_V3_ABILITY_STAT_DAMAGE_MODIFIERS.md`.

## #80 result — Tough Claws
Pinned immutable source `data/api/v2/ability/181/index.json` is Generation VI/main-series, `effect_changes=[]`, but its English prose says contact moves are `1.33x` power.

Current audited main-series mechanics are a **30%** contact-move power boost. Immutable source remains untouched. The ability contract first validates the stale pinned `1.33x` shape and then normalizes only the loaded project-owned record to:
`Boosts the power of moves that make contact by 30%.`

Runtime uses only existing primitives:
- `MODIFY_DAMAGE`
- `requires_contact=true`
- `multiplier_bp=13000`
- no type gate
- no physical-only gate.

Decision: **`tough_claws → RUNTIME_SUPPORTED`**.

A real-battle DATA V3 suite verifies:
- contact `Tackle` receives the boost and emits `ABILITY_TRIGGERED`;
- non-contact `Earthquake` has identical damage to the no-ability control and emits no Tough Claws trigger.

## #80 rejected adjacent candidates
`huge_power` and `pure_power` remain **DATA_ONLY**.

Their pinned source says **Attack is doubled in battle** and explicitly says this is not a stat-stage modifier. A blanket final physical-damage x2 is not a faithful substitute for an offensive-stat multiplier. Both records now have source guards and regression tests; no MODIFY_DAMAGE mapping is registered.

## Ability coverage after #80 engineering
- `RUNTIME_SUPPORTED`: **9**
- `PARTIAL_RUNTIME`: **4**
- `DATA_ONLY`: **360**
- total: **373**.

## Exact #79 → #80 artifact
Raw and normalized data:
- exactly one changed ability: `tough_claws`;
- exactly three changed fields: `classification`, `description`, `effect_summary`.

Reports move only Tough Claws from DATA_ONLY to RUNTIME_SUPPORTED and update 8→9 / 361→360 counts. Partial remains 4.

Explicitly unchanged:
- Huge Power
- Pure Power
- all other abilities
- species/Pokémon
- moves/effects
- items
- learnsets
- evolutions
- types/stats
- manifest/forms/auxiliary.

`import_time_ms` 516→495 ms is non-semantic timing noise.

## Safety note
A draft broad replacement of `tools/pokeapi_adapter_v3.py` was caught by the pre-PR compare check (716 changed lines) and removed before PR creation. Final #80 engineering diff leaves the adapter unchanged from certified #79 and implements the correction only in the narrow ability-contract layer.

## Current certification step
Notebook synchronization follows engineering SHA `fecf7995e0284a0c7111239107aa3762f4e1233f`.

Before closing #80:
1. verify engineering SHA → final HEAD changes only `01`, `04`, `10` notebooks;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #80 without merge;
4. use that exact final SHA as the next certified baseline.

## Exact next work after #80
Continue DATA FOUNDATION V3 ability reliability with another bounded subgroup whose semantics fit existing primitives. Do not bulk-promote the remaining abilities and do not add broad weather/status/party/form state solely to increase coverage.

Huge Power/Pure Power stay deferred until a genuine offensive-stat multiplier abstraction exists. Trainer AI/archetypes remain deferred.
