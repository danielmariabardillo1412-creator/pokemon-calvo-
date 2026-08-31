# NEXT STEPS — LIVE CHECKPOINT

Read this immediately after `00_READ_FIRST.md` when recovering context.

## Previous certified tranche
- Branch `fix/data-v3-magnetic-flux-semantics`
- PR #60 closed without merge
- Final HEAD `a5b56a0ba3a1efa81ac57be63b2813c19f2962a7`
- 18/18 SUCCESS on exact notebook-bearing HEAD.

## Current tranche — PR #61
- Branch `fix/data-v3-simple-self-stat-packages-a`
- Parent `a5b56a0ba3a1efa81ac57be63b2813c19f2962a7`
- Engineering SHA before notebook synchronization: `f3927a99d4d21d711dec77d68e7526757691c47f`
- Engineering SHA CI: **18/18 SUCCESS**, including independent regenerated-output assertions for all ten pure SELF stat packages.
- Notebook synchronization moves branch tip. **Require 18/18 on the final exact notebook-bearing HEAD, then close #61 without merge.**

## Current workstream
**Move Effects V3 semantic audit. Do not switch to trainer AI/archetypes.**

## Exact artifact metrics from #61 engineering SHA
- `RUNTIME_SUPPORTED`: **565**
- `PARTIAL_RUNTIME`: **67**
- `DATA_ONLY`: **275**
- `UNSUPPORTED`: **12**
- DATA_ONLY with non-empty specs: **49**
  - 46 stat-change records
  - `Purify`
  - `Swallow`
  - `Beat Up`

Remaining stat-change targets:
- 23 `selected-pokemon`
- 13 `user`
- 8 `all-opponents`
- 2 `all-pokemon`

## Tranche just completed technically
The following ten moves were individually source-verified and then safely batched because their complete battle semantics are exactly an unconditional SELF stat package:

- Bulk Up — Attack +1 / Defense +1
- Calm Mind — SpAtk +1 / SpDef +1
- Coil — Attack +1 / Defense +1 / Accuracy +1
- Cosmic Power — Defense +1 / SpDef +1
- Defend Order — Defense +1 / SpDef +1
- Dragon Dance — Attack +1 / Speed +1
- Hone Claws — Attack +1 / Accuracy +1
- Quiver Dance — SpAtk +1 / SpDef +1 / Speed +1
- Shift Gear — Attack +1 / Speed +2
- Work Up — Attack +1 / SpAtk +1

The legacy generator already emitted the correct effects. PR #61 adds exact fail-fast package validation and promotes only those ten to `RUNTIME_SUPPORTED`; it does not rewrite their effect specs.

## Exact next technical task after #61 closure
Do **not** force the 13 remaining `user` moves into another batch. They are the conditional/stateful remainder:
`Autotomize`, `Charge`, `Clangorous Soul`, `Defense Curl`, `Extreme Evoboost`, `Fillet Away`, `Geomancy`, `Growth`, `Minimize`, `No Retreat`, `Shell Smash`, `Stockpile`, `Tidy Up`.

Next priority is to regroup the **23 `selected-pokemon` stat-change DATA_ONLY records** into semantic families before editing.

Recommended sequence:
1. Close #61 only after final exact-head 18/18.
2. Branch from that final certified SHA.
3. Inspect the 23 selected-pokemon records from the exact certified artifact.
4. Separate simple unconditional opponent stat drops from special cases.
5. Likely special cases to keep separate include `decorate`, `defog`, `memento`, `parting_shot`, `spicy_extract`, `tar_shot`, and any move whose effect text adds switching, field cleanup, type changes, mixed positive/negative targets, or other state.
6. Verify every proposed clean candidate against immutable source before batching.
7. Batch only truly homogeneous moves; add exact fail-fast package validation + independent regenerated-output assertion.
8. DATA V3 focal → 18/18 engineering → artifact → notebooks → 18/18 final → close without merge.

## Known exclusions / special cases
- Rest: DATA_ONLY until Rest-specific status replacement/sleep semantics exist.
- Wish: DATA_ONLY until delayed persisted effects exist.
- Strength Sap: PARTIAL_RUNTIME; Attack drop works, stat-derived heal missing.
- Roost/weather heals/team heals: PARTIAL_RUNTIME for known missing mechanics.
- Silk Trap, Aromatic Mist, Stuff Cheeks, Coaching, Gear Up, Magnetic Flux: safely DATA_ONLY/effect-free until their missing target/trigger/resource predicates exist.
- Howl: PARTIAL_RUNTIME, SELF subset only.
- Purify, Swallow, Beat Up: unaudited special cases; handle separately.
- Remaining 13 user stat-change cases: intentionally not part of the clean package batch; audit individually/small conditional families.

## Stop condition
If any focal or regression test fails, stop. Diagnose/fix root cause, rerun focal, then full matrix. Do not accumulate failures.
