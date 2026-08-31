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
All certified entries above: 18/18 on exact final notebook-bearing HEAD, closed without merge.

## Runtime safety invariant
`effect_specs` execute regardless of `classification`. `DATA_ONLY` is not an execution gate. A known-false or strategically unsafe spec must be removed/corrected.

Coverage semantics:
- `RUNTIME_SUPPORTED`: fully faithful in current model.
- `PARTIAL_RUNTIME`: faithful subset; omissions only weaken/omit benefits.
- `DATA_ONLY`: data retained without unsafe executable behavior.
- `UNSUPPORTED`: explicitly outside current contract.

# Current tranche — PR #75 final DATA_ONLY executable effects
- Branch: `fix/data-v3-final-data-only-effects`
- Parent: certified #74 final `9a917fea11df07c3aa26c8962e2dca9784a41875`.
- Engineering SHA before notebook sync: `db73a16b631f4e7bd539ac5e73b288401489d39a`.
- Engineering SHA: **18/18 SUCCESS**, including DATA V3 and Godot global.

## #75 decisions
### Purify
Immutable source requires the selected target to have a major/non-volatile status condition. The move cures that status and only then heals the user up to 50%; it fails when no eligible target status exists.

Legacy output was unconditional `HEAL SELF 50%`, allowing a free heal on a turn that should fail.
Decision: remain `DATA_ONLY`, `effect_specs=[]`; canonical summary retains cure prerequisite + conditional heal.

### Swallow
Immutable source requires stored Stockpile energy. Stockpile levels 1/2/3 heal 25%/50%/100%, then the stored energy is consumed and associated Stockpile Defense/Special Defense changes are removed. It fails at zero Stockpile.

Legacy output was unconditional `HEAL SELF 25%`.
Decision: remain `DATA_ONLY`, `effect_specs=[]`; canonical summary retains prerequisite, variable healing and consumption.

### Beat Up
Immutable source is a physical selected-target move with source `power=null`; snapshot meta exposes `min_hits=max_hits=6`, but source prose/effect history describes party participation. Modern core-series behavior uses one strike for each eligible conscious party member without a non-volatile status, with party-member-dependent strike power rather than a fixed generic six-hit action.

Legacy output was unconditional `MULTI_HIT 6..6`.
Decision: remain `DATA_ONLY`, `effect_specs=[]`; canonical summary records party-dependent semantics.

Implementation: `tools/pokeapi_adapter_final_data_only_effects.py`, invoked as the final explicit post-stat audit stage. Independent DATA V3 assertions verify the three output contracts and the global zero-unsafe-spec invariant.

## Exact #74 → #75 engineering artifact
Raw and normalized datasets agree:
- only `beat_up`, `purify`, `swallow` changed;
- on all three only `effect_specs` and `effect_summary` changed;
- no classification, target, accuracy, power, PP or unrelated record changed.

Coverage remains:
- `RUNTIME_SUPPORTED`: **590**
- `PARTIAL_RUNTIME`: **71**
- `DATA_ONLY`: **246**
- `UNSUPPORTED`: **12**

DATA_ONLY with non-empty `effect_specs`: **0**.

**Move Effects V3 executable-safety frontier is closed at the engineering artifact.**

Notebook sync moves SHA; final #75 HEAD must pass 18/18 before closure without merge.

## Next workstream after #75 certification
Remain in DATA FOUNDATION V3 semantic reliability. Begin explicit **Ability runtime-support contracts**: distinguish the 373 preserved ability records from the subset whose battle mechanics are actually implemented. Do not return to trainer AI/archetypes until the remaining data-reliability work is deliberately closed or reprioritized.
