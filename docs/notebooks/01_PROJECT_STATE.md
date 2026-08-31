# PROJECT STATE NOTEBOOK

## Purpose
Fast context recovery for engineering work. GitHub commits, PR state, CI, immutable source data, and tested artifacts are authoritative if anything conflicts with this notebook.

## Repository / certification policy
- Repository: `danielmariabardillo1412-creator/pokemon-calvo-`
- Engine: Godot 4.7.
- Certified snapshots are retained as branches / closed PRs **without merge**.
- New tranches branch from the latest exact certified HEAD.
- Certification requires all 18 normal workflows green on the same exact final SHA.
- Notebook updates move the SHA, so the notebook-bearing HEAD requires a second 18/18 run before PR closure.
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
All above: 18/18 on exact final HEAD, closed without merge.

## Parallel-branch reconciliation
After #66, two valid branches were created in parallel:
- #67: Battle Core self-target accuracy fix, final `432781b78e8864192343b952b0645a48046ceed4`, 18/18 and closed without merge.
- #68: Clangorous Soul / Fillet Away HP-cost neutralization, engineering HEAD `fb5cbf71edf2327725d8506b1b32965b0fae6bec`, 18/18 but PR left open before final notebook certification.
- #69 independently audited Charge / Defense Curl / Growth / Shell Smash from #66 and became the latest fully certified DATA V3 baseline.

Do **not** continue from #67 or #68 independently. PR #70 reconciles their validated technical work on top of certified #69.

# Current tranche — PR #70 unified user-audit chain
- Branch: `reconcile/data-v3-user-audit-chain`
- Parent: certified #69 final `7aaae1c600120442581fdd7c0c048b29e3ee5690`.
- Engineering SHA before notebook synchronization: `20fedf932ae1a867dd641f0e693c21b745393a9b`.
- Engineering SHA passed **18/18**, including DATA V3 and Godot global.

### Ported from certified #67
Battle Core `TurnExecutor` skips the normal Accuracy/Evasion roll only for canonical `target=user` moves. Move-specific failure conditions remain separate mechanics. The exact #67 battle regression suite is reused and passes in #70.

### Ported from #68 engineering
`Clangorous Soul` and `Fillet Away` remain `DATA_ONLY`, but their executable SELF stat packages are removed because Battle Core cannot represent the mandatory max-HP payment + insufficient-HP failure transaction.
- Clangorous Soul: real +1 to five stats costs 1/3 max HP; free boosts were unsafe.
- Fillet Away: real +2 Atk/SpAtk/Speed costs 1/2 max HP; free boosts were unsafe.

### Unified audit chain
`all-opponents → user-stateful-safe (#69) → user-hp-cost (#68)`.
The #69 decisions stay intact; the HP-cost layer only handles Clangorous Soul and Fillet Away.

## Exact #70 engineering artifact
Coverage remains:
- `RUNTIME_SUPPORTED`: **590**
- `PARTIAL_RUNTIME`: **71**
- `DATA_ONLY`: **246**
- `UNSUPPORTED`: **12**

DATA_ONLY with non-empty `effect_specs`: **12**.
- 9 stat-change records.
- 3 non-stat: `Beat Up`, `Purify`, `Swallow`.

Exact #69 → #70 data comparison:
- changed records: exactly `clangorous_soul`, `fillet_away`;
- changed key on both: `effect_specs` only;
- both packages become empty;
- classifications, target, accuracy, summaries and every unrelated move remain unchanged.
- the #67 Battle Core fix changes no DATA V3 record.

Notebook synchronization moves the SHA. Final #70 notebook-bearing HEAD must pass 18/18 before closure without merge.

## Move Effects frontier after #70 engineering
Remaining user stat/stateful DATA_ONLY-with-specs: **7**
- `autotomize`
- `extreme_evoboost`
- `geomancy`
- `minimize`
- `no_retreat`
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
- `RUNTIME_SUPPORTED`: fully faithful in the current battle model.
- `PARTIAL_RUNTIME`: retained subset is faithful and omissions only weaken/omit benefits.
- `DATA_ONLY`: data retained without unsafe executable behavior.
- `UNSUPPORTED`: explicitly outside current contract.
