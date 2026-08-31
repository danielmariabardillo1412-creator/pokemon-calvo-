# PROJECT STATE NOTEBOOK

## Purpose
Fast context recovery for engineering work. GitHub commits, PR state, CI, immutable source data, and tested artifacts are authoritative if anything conflicts with this notebook.

## Repository / certification policy
- Repository: `danielmariabardillo1412-creator/pokemon-calvo-`
- Engine: Godot 4.7.
- Certified snapshots are retained as branches / closed PRs **without merge**.
- New tranches branch from the latest exact certified HEAD.
- Certification requires all 18 normal workflows green on the same exact final SHA.
- Notebook updates move SHA, so notebook-bearing HEAD requires a second 18/18 run before closure.
- Stop on any failing focal/regression test; fix root cause before continuing.

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
- #71 mandatory-state user boosts — `98c68f1c184e84db30458a4533fb769cba1140ac`
All above: 18/18 on exact final notebook-bearing HEAD, closed without merge.

# Current tranche — PR #72 persistent-state user moves
- Branch: `fix/data-v3-user-persistent-state-c`
- Parent: certified #71 final `98c68f1c184e84db30458a4533fb769cba1140ac`.
- Engineering SHA before notebook sync: `16f7eef390fb08e7ce48f2a1d2cbf4547321a939`.
- Engineering SHA passed **18/18**, including DATA V3 and Godot global.

## #72 architecture
New tiny coordinator `tools/pokeapi_adapter_user_audit_chain.py` centralizes the deterministic order of narrow user audits:
`HP-cost → mandatory-state → persistent-state`.
It does not define move semantics; each narrow module remains authoritative for its audited family.

## #72 decisions
### Autotomize
Immutable snapshot:
- target user; accuracy null → canonical -1;
- Speed +2;
- generic English effect prose is stale: says weight is halved and does not stack.

Current core-series mechanic checked publicly:
- each successful use reduces weight by 100 kg;
- effect stacks to a minimum weight of 0.1 kg.

Weight modification can help or hurt depending on weight-based attacks, so exposing only Speed +2 is not a provably safe partial.
Decision:
- remain `DATA_ONLY`;
- `effect_specs=[]`;
- immutable source stays untouched;
- loaded English prose is normalized before canonical `effect_summary` so derived data says Speed +2 and weight -100 kg rather than the stale half-weight rule.

### Minimize
Immutable snapshot:
- target user; accuracy null → canonical -1;
- Evasion +2;
- source prose records special vulnerabilities after using Minimize but is incomplete for modern mechanics.

Modern core-series rules apply persistent Minimized state with special accuracy/damage vulnerabilities. Current Battle Core has no Minimized-state primitive. Evasion +2 alone removes the drawback and is materially stronger.
Decision:
- remain `DATA_ONLY`;
- `effect_specs=[]`;
- canonical English summary is normalized to preserve the Minimized-state fact generically.

## Exact #72 engineering artifact
Coverage remains:
- `RUNTIME_SUPPORTED`: **590**
- `PARTIAL_RUNTIME`: **71**
- `DATA_ONLY`: **246**
- `UNSUPPORTED`: **12**

DATA_ONLY with non-empty `effect_specs`: **8**.
- 5 stat/stateful records total.
- 3 non-stat: `Beat Up`, `Purify`, `Swallow`.

Exact #71 → #72 raw comparison:
- exactly two records changed: `autotomize`, `minimize`;
- both changed only `effect_specs` and `effect_summary`;
- Autotomize: one SELF Speed +2 spec → empty; stale half-weight summary → current 100 kg wording;
- Minimize: one SELF Evasion +2 spec → empty; summary now records Minimized state;
- classification, target, accuracy and every unrelated record unchanged.

Notebook synchronization moves SHA. Final #72 notebook-bearing HEAD must pass 18/18 before closure without merge.

## Move Effects frontier after #72 engineering
Remaining user stat/stateful DATA_ONLY-with-specs: **3**
- `extreme_evoboost`
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
