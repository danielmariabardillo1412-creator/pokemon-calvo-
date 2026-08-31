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
All: 18/18 on exact final notebook-bearing HEAD, closed without merge.

## Runtime safety invariant
`effect_specs` execute regardless of `classification`. `DATA_ONLY` is not an execution gate. A known-false or strategically unsafe spec must be removed/corrected.

Coverage semantics:
- `RUNTIME_SUPPORTED`: fully faithful in current model.
- `PARTIAL_RUNTIME`: faithful subset; omissions only weaken/omit benefits.
- `DATA_ONLY`: data retained without unsafe executable behavior.
- `UNSUPPORTED`: explicitly outside current contract.

# Current tranche — PR #74 all-pokemon semantics
- Branch: `fix/data-v3-all-pokemon-semantics`
- Parent: certified #73 final `67ba79e9a68a78669ee5ae04166a47ee11331bc7`.
- Engineering SHA before notebook sync: `99a435c291514612b5c1ce43ad2a28e47797c6c0`.
- Engineering SHA: **18/18 SUCCESS**, including DATA V3 and Godot global.
- Exact #73→#74 artifact diff: only `flower_shield`, `rototiller`; on both only `effect_specs` and `effect_summary` changed.

## #74 decisions
### Flower Shield
Source: target `all-pokemon`, accuracy null, Defense +1; source prose says all Grass Pokémon in battle. Current mechanics affect eligible Grass-type Pokémon on the field, fail if none, and the move cannot be selected in Generation IX.

Legacy output was unconditional `OPPONENT Defense +1`, which can buff an ineligible opponent and miss eligible user/allies. SELF/OPPONENT cannot express all-Pokémon fan-out + Grass predicate.
Decision: `DATA_ONLY`, `effect_specs=[]`; canonical summary records eligibility/current selectability.

### Rototiller
Source: target `all-pokemon`, accuracy null, Attack +1 / SpAtk +1; source prose says all Grass Pokémon in battle. Current mechanics in usable generations affect eligible **grounded** Grass-type Pokémon, fail if none, and the move cannot be selected from Generation VIII onward.

Legacy output was unconditional `OPPONENT Attack +1 / SpAtk +1`; not faithful.
Decision: `DATA_ONLY`, `effect_specs=[]`; canonical summary records grounded/type/current selectability semantics.

Implementation: `tools/pokeapi_adapter_all_pokemon.py`, invoked as a narrow final post-stat audit. Independent DATA V3 assertions verify target, accuracy=-1, DATA_ONLY, empty specs and summaries.

## Exact #74 engineering artifact
Coverage unchanged:
- `RUNTIME_SUPPORTED`: **590**
- `PARTIAL_RUNTIME`: **71**
- `DATA_ONLY`: **246**
- `UNSUPPORTED`: **12**

DATA_ONLY with non-empty specs: **3 only**:
- `beat_up`
- `purify`
- `swallow`

**All stat-change DATA_ONLY-with-spec cases are now resolved.**

Notebook sync moves SHA; final #74 HEAD must pass 18/18 before closure.

## Remaining Move Effects frontier
Only three non-stat cases remain:
- `Beat Up`
- `Purify`
- `Swallow`
