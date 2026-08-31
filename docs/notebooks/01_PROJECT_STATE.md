# PROJECT STATE NOTEBOOK

## Purpose / authority
Fast recovery for engineering work. GitHub commits, PR state, CI, immutable source and tested artifacts override this notebook on conflict.

## Certification policy
- Repo: `danielmariabardillo1412-creator/pokemon-calvo-`; Godot 4.7.
- Certified snapshots stay as closed PR branches **without merge**.
- New tranche starts from latest exact certified HEAD.
- Require all 18 normal workflows green on the same exact final SHA.
- Notebook commits move SHA, so final notebook-bearing HEAD requires a second 18/18.
- Stop on any failing focal/regression and fix root cause first.

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
- #63 accuracy `9f8b3e01bec1f86cff75380d68dd98d76e738e78`
- #64 selected special stats `674ccaf0928c93749c581565d53eb1f672dfd7b4`
- #65 selected stateful `b13af37c350156bc7a9a7d7faf63742245afd801`
- #66 all-opponents `51bc14155338e47c76926047845a958205005bdd`
- #69 safe user-stateful `7aaae1c600120442581fdd7c0c048b29e3ee5690`
- #70 reconciled chain `4ee439a9741cc7dac8ec5d1792485ee79aa5f4b2`
- #71 mandatory-state user `98c68f1c184e84db30458a4533fb769cba1140ac`
- #72 persistent-state user `d46be6864abd6e1cffdf54f9e932da06bed054dc`
- #73 terminal user-state `67ba79e9a68a78669ee5ae04166a47ee11331bc7`
- #74 all-pokemon semantics `9a917fea11df07c3aa26c8962e2dca9784a41875`
- #75 final DATA_ONLY executable effects `4bb4bdc64982eef62f126f8d1c38e9509d21c96c`
- #76 initial ability runtime contracts `a596a38680b60db317f1dfd6b6beb8d7ded7b813`
- #77 ability family inventory + Swarm `78da22438d0866193b0d1154814464531ac55641`

All entries above: **18/18 SUCCESS on exact final notebook-bearing HEAD and closed without merge**.

## Move Effects V3 closed milestone
PR #75 certified that no `DATA_ONLY` move retains executable `effect_specs`.

Move coverage:
- `RUNTIME_SUPPORTED`: **590**
- `PARTIAL_RUNTIME`: **71**
- `DATA_ONLY`: **246**
- `UNSUPPORTED`: **12**
- `DATA_ONLY` with non-empty `effect_specs`: **0**.

## Coverage safety principle
Preserved data is not equivalent to executable support.

- `RUNTIME_SUPPORTED`: current modeled battle mechanic is faithful.
- `PARTIAL_RUNTIME`: real useful subset works, but known source-required battle behavior is absent/wrong.
- `DATA_ONLY`: source metadata retained without claiming executable mechanics.
- `UNSUPPORTED`: explicitly outside the current contract.

For moves, `effect_specs` execute regardless of label, so unsafe specs must be removed. For abilities, Battle Core trigger registration controls execution while DATA V3 classification describes semantic completeness.

## Certified ability baseline through PR #77
Detailed notebooks:
- `docs/notebooks/06_DATA_V3_ABILITY_RUNTIME_AUDIT.md`
- `docs/notebooks/07_DATA_V3_ABILITY_FAMILY_INVENTORY.md`

PR #76 established the initial honest ability split and the known partials:
- `intimidate`: base switch-in Attack drop works; extra acquisition/reacquisition/Substitute semantics absent.
- `levitate`: Ground move immunity works; grounded-field/suppression semantics absent.
- `static`: ordinary contact paralysis works; fatal contact cannot currently trigger because fainted owners are excluded from AFTER_DAMAGE.

PR #77 then partitioned the exact 367-record #76 DATA_ONLY frontier into **13 deterministic triage families** and promoted only `swarm` after an explicit source/runtime audit.

Certified #77 ability coverage:
- `RUNTIME_SUPPORTED`: **4** — `blaze`, `overgrow`, `swarm`, `torrent`
- `PARTIAL_RUNTIME`: **3** — `intimidate`, `levitate`, `static`
- `DATA_ONLY`: **366**
- total: **373**.

# Current tranche — PR #78 Ability type boosts

- Branch: `audit/data-v3-ability-type-boosts-v1`.
- Parent: certified #77 final `78da22438d0866193b0d1154814464531ac55641`.
- PR: #78 `DATA V3 — audit unconditional ability type boosts`.
- Engineering SHA: `f01b1d0553b7dfa1e5998ee1de99ace9fad1534b`.
- Engineering SHA: **18/18 SUCCESS**, including DATA V3 and Godot 4.7 global.
- Detailed notebook: `docs/notebooks/08_DATA_V3_ABILITY_TYPE_BOOSTS.md`.

## #78 bounded source/runtime result
Four unconditional type-power boosts are source-complete and fit the existing `MODIFY_DAMAGE` primitive without a new Battle Core mechanism:

- `steelworker` — Steel, x1.5
- `dragons_maw` — Dragon, +50%
- `rocky_payload` — Rock, +50%
- `fire_mane` — Fire, +50%

All four have explicit numeric current source semantics, expected generation guards and `effect_changes=[]` in the pinned snapshot.

Decision: all four become `RUNTIME_SUPPORTED`.

`transistor` remains deliberately `DATA_ONLY`: its ability semantics are version-sensitive while the pinned source lacks enough versioned history to justify one universal multiplier under the project's version-aware policy.

## #78 runtime contract
Battle Core registers each new ability as:
- trigger `MODIFY_DAMAGE`;
- exact `move_type_id`;
- `multiplier_bp=15000`;
- no HP threshold or additional hidden condition.

No new general primitive and no global damage-order change were introduced. Historical `runtime_supported_ability_ids()` remains frozen for Battle V2 compatibility; DATA V3 uses `implemented_ability_ids()`.

## Ability coverage after #78 engineering
- `RUNTIME_SUPPORTED`: **8**
- `PARTIAL_RUNTIME`: **3**
- `DATA_ONLY`: **362**
- total: **373**.

The exact runtime-supported set is:
`blaze`, `dragons_maw`, `fire_mane`, `overgrow`, `rocky_payload`, `steelworker`, `swarm`, `torrent`.

## Exact #77 → #78 engineering artifact
Raw + normalized datasets:
- exactly four semantic changes;
- only `classification: DATA_ONLY → RUNTIME_SUPPORTED` for `dragons_maw`, `fire_mane`, `rocky_payload`, `steelworker`.

No other ability, species, move/effect, item, learnset, evolution, type or stat changed.

Reports move exactly those four IDs and update counts 4→8 runtime / 366→362 data-only. Manifest, forms report and auxiliary report are unchanged. `import_time_ms` 519→525 ms is non-semantic timing noise.

## Current certification step
Notebook synchronization follows engineering SHA `f01b1d0553b7dfa1e5998ee1de99ace9fad1534b`.

Before closing #78 without merge:
1. verify engineering SHA → final HEAD changes only `01`, `04`, `08` notebooks;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #78 without merge;
4. use that exact final SHA as next certified baseline.

## Exact next work after #78
Remain in DATA FOUNDATION V3 ability reliability. Audit another bounded existing-primitive family rather than bulk-promoting `stat_damage_modifier`.

First candidate: `stamina`, subject to a fresh source/runtime audit. Keep the broad contact-reactive family deferred while the Static fatal-contact trigger gap remains unresolved.
