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
- #78 unconditional ability type boosts `eda483d9cd6423d32bdf1a156372416b2fbcb639`

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

## Ability reliability through certified #78
Detailed notebooks:
- `06_DATA_V3_ABILITY_RUNTIME_AUDIT.md`
- `07_DATA_V3_ABILITY_FAMILY_INVENTORY.md`
- `08_DATA_V3_ABILITY_TYPE_BOOSTS.md`

Known certified partials before this tranche:
- `intimidate`: base switch-in Attack drop works; extra acquisition/reacquisition/Substitute semantics absent.
- `levitate`: Ground move immunity works; grounded-field/suppression semantics absent.
- `static`: ordinary contact paralysis works; fatal contact cannot currently trigger because fainted owners are excluded from AFTER_DAMAGE.

Certified #78 ability coverage:
- `RUNTIME_SUPPORTED`: **8** — `blaze`, `dragons_maw`, `fire_mane`, `overgrow`, `rocky_payload`, `steelworker`, `swarm`, `torrent`
- `PARTIAL_RUNTIME`: **3** — `intimidate`, `levitate`, `static`
- `DATA_ONLY`: **362**
- total: **373**.

`transistor` remains deliberately DATA_ONLY because its multiplier is version-sensitive and the pinned snapshot does not provide an honest universal versioned contract.

# Current tranche — PR #79 Hit-triggered stat reactions

- Branch: `audit/data-v3-ability-hit-stat-reactions-v1`.
- Parent: certified #78 final `eda483d9cd6423d32bdf1a156372416b2fbcb639`.
- PR: #79 `DATA V3 — audit hit-triggered stat ability reactions`.
- Engineering SHA: `748b28b69d19be5912bbc0318f2e8e8d40f3eccd`.
- Engineering SHA: **18/18 SUCCESS**, including DATA V3 and Godot 4.7 global.
- Detailed notebook: `docs/notebooks/09_DATA_V3_ABILITY_HIT_STAT_REACTIONS.md`.

## #79 decision — Stamina
Immutable source `data/api/v2/ability/192/index.json` states that taking damage from a move raises Defense by one stage; main-series Generation VII; `effect_changes=[]`.

Battle Core now registers:
- `AFTER_DAMAGE`
- SELF Defense `+1`
- no invented contact/physical/type/HP condition.

This is a faithful subset, but **not complete** because current Battle Core fires AFTER_DAMAGE once per completed move rather than once per strike inside MULTI_HIT; it also excludes fainted owners from trigger execution.

Decision: **`stamina → PARTIAL_RUNTIME`**.

A dedicated DATA V3 integration suite creates a real `AuthoritativeBattleServer` and verifies:
- surviving Tackle damage triggers Stamina and Defense +1;
- non-damaging Growl does not trigger Stamina.

## #79 adjacent blockers
- `water_compaction`: stays `DATA_ONLY`; requires a Water-move predicate on AFTER_DAMAGE that the current condition evaluator does not expose.
- `weak_armor`: stays `DATA_ONLY`; needs a dual stat transaction plus per-hit/version-aware behavior.

No broad Battle Core primitive was added merely to increase coverage.

## Ability coverage after #79 engineering
- `RUNTIME_SUPPORTED`: **8**
- `PARTIAL_RUNTIME`: **4** — `intimidate`, `levitate`, `stamina`, `static`
- `DATA_ONLY`: **361**
- total: **373**.

## Exact #78 → #79 engineering artifact
Raw + normalized:
- exactly one changed ability: `stamina`;
- only changed semantic field: `classification`;
- `DATA_ONLY → PARTIAL_RUNTIME`.

Reports move only Stamina and update counts 362→361 DATA_ONLY / 3→4 PARTIAL_RUNTIME. Manifest, forms and auxiliary reports are unchanged. Import-time variation 357→516 ms is non-semantic.

## Current certification step
Notebook sync now moves SHA after engineering `748b28b69d19be5912bbc0318f2e8e8d40f3eccd`.

Before closing #79:
1. verify engineering → final HEAD changes only notebook files;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #79 without merge;
4. use that exact final HEAD as next baseline.

## Exact next work after #79
Remain in DATA FOUNDATION V3 ability reliability.

Do not shortcut Water Compaction or Weak Armor. Triage the remaining `stat_damage_modifier` bucket for another small allowlist whose complete or useful-partial semantics already fit Battle Core primitives. If no clean candidate exists, record that result and move to another family rather than broadening Battle Core solely for coverage.
