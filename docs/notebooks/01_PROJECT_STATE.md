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

All entries above: 18/18 on exact final notebook-bearing HEAD, closed without merge.

## Move Effects V3 closed milestone
PR #75 certified that no `DATA_ONLY` move retains executable `effect_specs`.

Move coverage at #75:
- `RUNTIME_SUPPORTED`: **590**
- `PARTIAL_RUNTIME`: **71**
- `DATA_ONLY`: **246**
- `UNSUPPORTED`: **12**
- `DATA_ONLY` with non-empty `effect_specs`: **0**

`Purify`, `Swallow`, and `Beat Up` were the final unsafe approximations and now remain `DATA_ONLY + effect_specs=[]` until Battle Core can represent their complete transactions.

## Coverage safety principle
Preserved data is not equivalent to executable support.

- `RUNTIME_SUPPORTED`: current modeled battle mechanic is faithful.
- `PARTIAL_RUNTIME`: real useful subset works, but known source-required battle behavior is absent/wrong.
- `DATA_ONLY`: source metadata retained without claiming executable mechanics.
- `UNSUPPORTED`: explicitly outside the current contract.

For moves, `effect_specs` execute regardless of label, so unsafe specs must be removed. For abilities, Battle Core trigger registration controls execution while DATA V3 classification describes semantic completeness.

# Current tranche — PR #76 Ability runtime contracts

- Branch: `audit/data-v3-ability-runtime-contracts-v1`
- Parent: certified #75 final `4bb4bdc64982eef62f126f8d1c38e9509d21c96c`.
- Engineering SHA: `8e1ea4e443ef76dcca8f83ebf49c0ea282f4c890`.
- Engineering SHA: **18/18 SUCCESS**, including DATA V3 and Godot 4.7 global.
- Detailed notebook: `docs/notebooks/06_DATA_V3_ABILITY_RUNTIME_AUDIT.md`.

## #76 audited ability result
Battle Core has explicit triggers for six abilities. DATA V3 previously mislabeled all 373 abilities as `DATA_ONLY`.

After source/runtime audit:

### RUNTIME_SUPPORTED — 3
- `blaze`
- `overgrow`
- `torrent`

Their source 1/3-HP + matching-type + 1.5x damage transaction matches the actual Battle Core damage-modifier path.

### PARTIAL_RUNTIME — 3
- `intimidate`: switch-in Attack -1 works; additional acquisition/reacquisition/Substitute semantics are absent.
- `levitate`: Ground-move immunity works; grounded-field/suppression semantics are absent.
- `static`: ordinary contact 30% paralysis works, but a contact hit that KOs the Static holder cannot currently trigger its AFTER_DAMAGE ability path.

### DATA_ONLY — 367
All other ability records remain data-only until their semantic families are explicitly audited.

## #76 implementation contract
- `tools/pokeapi_ability_runtime_contracts.py`: explicit six-ID allowlist with fail-fast immutable-source semantic checks.
- `tools/pokeapi_adapter_v3.py`: emits audited ability classifications and report counts/IDs.
- `tests/data/data_foundation_v3_ability_runtime_contract_test_suite.gd`: exact 3/3/367 partition + registry consistency.
- No generic Battle Core trigger changes in this tranche.

## Exact #75 → #76 engineering artifact
Raw and normalized:
- exactly six changes;
- all are `ability.classification` changes only.

Reports add the corresponding classification IDs/counts and audit check. Species, moves/effects, items, learnsets, evolutions, types, stats, manifest, forms and auxiliary data are unchanged. `import_time_ms` variation is non-semantic execution timing only.

## Current certification step
Notebook synchronization follows engineering SHA `8e1ea4e443ef76dcca8f83ebf49c0ea282f4c890`.

Before closing #76 without merge:
1. verify engineering → final HEAD changed only operational notebooks;
2. require 18/18 on exact final notebook-bearing HEAD;
3. close #76 without merge;
4. use final HEAD as next baseline.

## Exact next work after #76
Remain in DATA FOUNDATION V3 ability reliability. Inventory/classify the remaining **367** abilities by semantic families and prioritize families expressible with existing Battle Core primitives. Do not mass-implement all abilities and do not return to trainer AI/archetypes yet.
