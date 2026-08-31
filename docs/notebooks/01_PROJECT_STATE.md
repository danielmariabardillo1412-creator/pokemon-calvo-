# PROJECT STATE NOTEBOOK

## Purpose
Fast context recovery for engineering work. GitHub commits, PR state, CI, immutable source data, and tested artifacts are authoritative if anything conflicts with this notebook.

## Repository / certification policy
- Repository: `danielmariabardillo1412-creator/pokemon-calvo-`
- Engine: Godot 4.7.
- Certified snapshots are retained as branches / closed PRs **without merge**.
- New tranches branch from the latest exact certified HEAD.
- Certification requires all 18 normal workflows green on the same exact final SHA.
- Notebook updates move the SHA, so notebook-bearing HEAD requires a second 18/18 run before PR closure.
- Stop on any failing focal/regression test and fix root cause before continuing.

## DATA FOUNDATION V3 authority
Immutable source:
- branch `data/pokeapi-v2-snapshot`
- commit `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`
- API tree `8349ea1ce75716897fe96e02a15950d19edba6c3`
- schema tree `02e031e1928d7e9456bf6f7486daacc4b8946c84`
- source paths `data/api/v2`, `data/schema/v2`
- source JSON is read-only.

Pipeline:
`snapshot → V3 canonical adapter → narrow semantic audit layers → raw JSON → Godot DataImporter → normalized data → runtime`.

Structural facts:
- 1,025 base species; 326 forms; 18 runtime types.
- 919 runtime moves; 373 abilities; 2,222 items.
- 61,102 learnset entries; 554 evolution records.
- 0 broken refs; 0 rejected definitions.
- 18 XD Shadow moves explicitly excluded.

## Recent certified chain
- #63 always-hit data accuracy — `9f8b3e01bec1f86cff75380d68dd98d76e738e78`
- #64 selected special stats — `674ccaf0928c93749c581565d53eb1f672dfd7b4`
- #65 selected stateful — `b13af37c350156bc7a9a7d7faf63742245afd801`
- #66 all-opponents semantics — `51bc14155338e47c76926047845a958205005bdd`
- #69 safe user-stateful subsets — `7aaae1c600120442581fdd7c0c048b29e3ee5690`
- #70 reconciliation of #67/#68 with #69 — `4ee439a9741cc7dac8ec5d1792485ee79aa5f4b2`
All above: 18/18 on exact final notebook-bearing HEAD, closed without merge.

## Certified reconciliation from #70
After #66, #67/#68 and #69 had diverged. #70 is the canonical reunification point; do not resume from #67 or #68.

#70 contains:
- certified Battle Core self-target accuracy fix from #67: normal Accuracy/Evasion roll is skipped only for canonical `target=user`; move-specific failure rules remain separate;
- Clangorous Soul / Fillet Away HP-cost safety from #68: both remain `DATA_ONLY` but their free stat specs are removed because max-HP payment/failure transaction is not representable;
- all #69 safe-user-stateful classifications remain intact.

#70 final coverage:
- `RUNTIME_SUPPORTED`: 590
- `PARTIAL_RUNTIME`: 71
- `DATA_ONLY`: 246
- `UNSUPPORTED`: 12
- DATA_ONLY with non-empty specs: 12 (9 stat/stateful + Beat Up + Purify + Swallow).

# Current tranche — PR #71 mandatory-state user boosts
- Branch: `fix/data-v3-user-mandatory-state-b`
- Parent: certified #70 final `4ee439a9741cc7dac8ec5d1792485ee79aa5f4b2`.
- Engineering SHA before notebook sync: `b55a487b46ec5443992e623fef5b1c8ce2bb0665`.
- Engineering SHA passed **18/18**, including DATA V3 and Godot global.

## #71 decisions
### Geomancy
Immutable source:
- target user; source accuracy null → canonical -1;
- SpAtk +2, SpDef +2, Speed +2;
- English effect explicitly says it takes one turn to charge.
Public core-series mechanics confirm Power Herb can execute it in one turn only by consuming the item.

Current BattleEffectSpec has no charge/pending-turn primitive. Immediate +2/+2/+2 is materially stronger than the real move.
Decision: remain `DATA_ONLY`, `effect_specs=[]`.

### No Retreat
Immutable source:
- target user; source accuracy null → canonical -1;
- Attack/Defense/SpAtk/SpDef/Speed +1;
- effect explicitly prevents switching out and contains reuse/failure semantics.
Public mechanics confirm Can't Escape/switch restriction is integral.

Current BattleEffectSpec has no trapping/reuse state. Free repeatable +1-all is materially stronger than the real move.
Decision: remain `DATA_ONLY`, `effect_specs=[]`.

Implementation: `tools/pokeapi_adapter_user_mandatory_state.py`, executed after safe-user-stateful and HP-cost audits. Independent DATA V3 suite verifies both regenerated records are effect-free and retain semantic summaries.

## Exact #71 engineering artifact
Coverage remains:
- `RUNTIME_SUPPORTED`: **590**
- `PARTIAL_RUNTIME`: **71**
- `DATA_ONLY`: **246**
- `UNSUPPORTED`: **12**

DATA_ONLY with non-empty `effect_specs`: **10**.
- 7 stat/stateful records.
- 3 non-stat: `Beat Up`, `Purify`, `Swallow`.

Exact #70 → #71 raw comparison:
- exactly two records changed: `geomancy`, `no_retreat`;
- changed key on each: `effect_specs` only;
- Geomancy 3 SELF stat specs → empty;
- No Retreat 5 SELF stat specs → empty;
- classifications, target, accuracy, summaries and every unrelated record unchanged.

Notebook synchronization moves SHA. Final #71 notebook-bearing HEAD must pass 18/18 before closure without merge.

## Move Effects frontier after #71 engineering
Remaining user stat/stateful DATA_ONLY-with-specs: **5**
- `autotomize`
- `extreme_evoboost`
- `minimize`
- `stockpile`
- `tidy_up`

Remaining all-pokemon stat cases: **2**
- `flower_shield`
- `rototiller`

Remaining non-stat cases: **3**
- `Beat Up`
- `Purify`
- `Swallow`

## Runtime safety invariant
`effect_specs` execute regardless of coverage label. `DATA_ONLY` is not an execution gate. Known-false or strategically unsafe specs must be removed/corrected.

Coverage:
- `RUNTIME_SUPPORTED`: fully faithful in current battle model.
- `PARTIAL_RUNTIME`: retained subset is faithful and omissions only weaken/omit benefits.
- `DATA_ONLY`: data retained without unsafe executable behavior.
- `UNSUPPORTED`: explicitly outside current contract.
