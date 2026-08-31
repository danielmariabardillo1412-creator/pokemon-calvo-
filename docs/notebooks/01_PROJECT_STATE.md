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
- paths `data/api/v2`, `data/schema/v2`
- source JSON is read-only.

Pipeline:
`snapshot → tools/pokeapi_adapter_v3.py → compatibility + narrow audit layers → data/raw/pokemon_api.json → Godot DataImporter → data/normalized/pokemon_api.json → runtime`.

Structural facts:
- 1,025 base species; 326 forms; 18 runtime types.
- 919 runtime moves; 373 abilities; 2,222 items.
- 61,102 learnset entries; 554 evolution records.
- 0 broken refs; 0 rejected definitions.
- 18 XD Shadow moves explicitly excluded.

## Recent certified Move Effects chain
- #63 always-hit accuracy — `9f8b3e01bec1f86cff75380d68dd98d76e738e78`
- #64 selected special stats — `674ccaf0928c93749c581565d53eb1f672dfd7b4`
- #65 selected stateful — `b13af37c350156bc7a9a7d7faf63742245afd801`
- #66 all-opponents stat semantics — `51bc14155338e47c76926047845a958205005bdd`
All: 18/18 on exact final notebook-bearing HEAD, closed without merge.

## Accuracy contract retained
PokéAPI `accuracy=null` maps to canonical `accuracy=-1`, matching Battle Core's always-hit sentinel. Numeric accuracy remains numeric.

# Current tranche — PR #69 safe user-stateful subsets
- Branch: `fix/data-v3-user-stateful-safe-subsets-a`
- Parent: certified #66 final `51bc14155338e47c76926047845a958205005bdd`.
- Engineering SHA before notebook synchronization: `a2de4701b028e35622d9fb6b1ea2980d09179a92`.
- Engineering SHA passed **18/18**, including DATA V3 independent regenerated-output assertions and Godot global.
- Exact #66→#69 artifact comparison changed exactly four records, and on all four **classification was the only changed key**.
- Notebook synchronization moves the SHA; final exact notebook-bearing HEAD must pass 18/18 again before #69 closes without merge.

## #69 audited decisions
Immutable PokéAPI source and current public core-series mechanics were cross-checked before changing coverage.

### Shell Smash — complete
Source/current semantics are exactly:
- Defense -1
- Special Defense -1
- Attack +2
- Special Attack +2
- Speed +2

The legacy generator already emitted exactly that SELF package. No missing battle mechanic remains in the audited base move.
Decision: `RUNTIME_SUPPORTED`.

### Charge — safe partial
Generated SELF Special Defense +1 is faithful. Missing mechanic: persistent Charge/Electric-boost state that doubles the next qualifying Electric move (current Gen IX semantics retain the charge until an Electric move is attempted/used under the game's rules).
Omission removes an extra benefit rather than a cost.
Decision: `PARTIAL_RUNTIME`, keep SELF SpDef +1.

### Defense Curl — safe partial
Generated SELF Defense +1 is faithful. Missing mechanic: persistent flag that doubles Rollout/Ice Ball power while the user remains in battle.
Omission removes an extra benefit.
Decision: `PARTIAL_RUNTIME`, keep SELF Defense +1.

### Growth — safe partial
Generated neutral-weather SELF Attack +1 / Special Attack +1 is faithful. In harsh sunlight the real move gives +2/+2.
Omission weakens the move but does not remove a cost or create a false advantage.
Decision: `PARTIAL_RUNTIME`, keep +1/+1.

Implementation is isolated in `tools/pokeapi_adapter_user_stateful_safe.py`, chained after the certified all-opponents layer. It validates source target/class/accuracy, exact stat package, semantic evidence and exact generated SELF effects. It does not rewrite specs.

## Exact #69 engineering artifact
Coverage:
- `RUNTIME_SUPPORTED`: **590**
- `PARTIAL_RUNTIME`: **71**
- `DATA_ONLY`: **246**
- `UNSUPPORTED`: **12**

DATA_ONLY with non-empty `effect_specs`: **14**.
- 11 stat-change records.
- 3 non-stat: `Beat Up`, `Purify`, `Swallow`.

Exact #66 → #69 raw comparison:
- changed records: `charge`, `defense_curl`, `growth`, `shell_smash` only;
- changed key on each: `classification` only;
- no target/accuracy/effect-summary/effect-spec change;
- no unrelated record changed.

## Move Effects frontier after #69 engineering
Remaining user stat/stateful DATA_ONLY-with-specs: **9**
- `autotomize`
- `clangorous_soul`
- `extreme_evoboost`
- `fillet_away`
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
`effect_specs` execute regardless of coverage label. `DATA_ONLY` is not an execution gate. A known-false or strategically unsafe spec must be removed/corrected.

Coverage:
- `RUNTIME_SUPPORTED`: audited semantics fully faithful in current battle model.
- `PARTIAL_RUNTIME`: faithful executable subset whose omissions only weaken or omit benefits without removing a mandatory cost/transaction/drawback.
- `DATA_ONLY`: data retained without exposing unsafe executable behavior.
- `UNSUPPORTED`: explicitly outside current contract.
