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
- #70 reconciled #67/#68 with #69 — `4ee439a9741cc7dac8ec5d1792485ee79aa5f4b2`
- #71 mandatory-state user boosts — `98c68f1c184e84db30458a4533fb769cba1140ac`
- #72 persistent-state user moves — `d46be6864abd6e1cffdf54f9e932da06bed054dc`
All above: 18/18 on exact final notebook-bearing HEAD, closed without merge.

## User audit architecture after #72
`tools/pokeapi_adapter_user_audit_chain.py` coordinates narrow user audits in deterministic order:
`HP-cost → mandatory-state → persistent-state → terminal-state (#73)`.
Move-specific policy stays in narrow modules.

# Current tranche — PR #73 final user-state stat packages
- Branch: `fix/data-v3-user-terminal-state-d`
- Parent: certified #72 final `d46be6864abd6e1cffdf54f9e932da06bed054dc`.
- Engineering SHA before notebook sync: `51f0a15bf980befc2fdb2393dd8b516a2f53eaed`.
- Engineering SHA passed **18/18**, including DATA V3 and Godot global.
- Exact #72→#73 artifact diff changed exactly three move records and no unrelated move.

## #73 decisions
### Extreme Evoboost
- source stat package: Attack/Defense/SpAtk/SpDef/Speed +2;
- real mechanic is Eevee's exclusive Z-Move derived from Last Resort, not an ordinary freely selectable modern move;
- exposing +2-all as a normal move is false.
Decision: remain `DATA_ONLY`, `effect_specs=[]`.
Canonical derived summary now records the Z-Move/selectability constraint; immutable source remains untouched.

### Stockpile
- source stat package: Defense +1, SpDef +1;
- real mechanic also stores a capped Stockpile counter (max 3), couples to Spit Up/Swallow and loses/consumes associated state under those transactions;
- exposing only repeatable stat boosts without the counter is unsafe.
Decision: remain `DATA_ONLY`, `effect_specs=[]`.
Canonical summary now records max-three counter and Spit Up/Swallow coupling.

### Tidy Up
- source stat package: Attack +1, Speed +1;
- real move also clears Spikes, Toxic Spikes, Stealth Rock, Sticky Web and Substitute from both sides;
- omitting bilateral cleanup can preserve strategically favorable hazards and make the runtime move stronger.
Decision: remain `DATA_ONLY`, `effect_specs=[]`.
Snapshot has no generic effect entry; canonical summary is derived from current Scarlet/Violet flavor text and records boosts + bilateral cleanup.

Implementation: `tools/pokeapi_adapter_user_terminal_state.py`, appended to the #72 user-audit coordinator. Independent DATA V3 assertions require all three regenerated records to remain target=user, accuracy=-1, DATA_ONLY, empty specs, with complete canonical summaries.

## Exact #73 engineering artifact
Coverage remains:
- `RUNTIME_SUPPORTED`: **590**
- `PARTIAL_RUNTIME`: **71**
- `DATA_ONLY`: **246**
- `UNSUPPORTED`: **12**

DATA_ONLY with non-empty `effect_specs`: **5** only:
- `flower_shield`
- `rototiller`
- `beat_up`
- `purify`
- `swallow`

There are **zero remaining target=user DATA_ONLY records with executable stat specs**.

Exact #72 → #73 raw comparison:
- exactly `extreme_evoboost`, `stockpile`, `tidy_up` changed;
- changed keys on all three: `effect_specs`, `effect_summary` only;
- classification, target, accuracy and every unrelated move remain unchanged.

Notebook synchronization moves SHA. Final #73 notebook-bearing HEAD must pass 18/18 before closure without merge.

## Move Effects frontier after #73 engineering
All-pokemon stat cases:
- `flower_shield`
- `rototiller`

Non-stat cases:
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
