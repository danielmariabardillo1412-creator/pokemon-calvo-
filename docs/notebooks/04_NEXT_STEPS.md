# NEXT STEPS — LIVE CHECKPOINT

Read this immediately after `00_READ_FIRST.md` when recovering context.

## Previous certified tranche
- PR #66 — `fix/data-v3-all-opponents-stat-audit`
- Final HEAD `51bc14155338e47c76926047845a958205005bdd`
- 18/18 SUCCESS on exact notebook-bearing HEAD
- closed without merge.

## Current tranche — PR #69
- Branch `fix/data-v3-user-stateful-safe-subsets-a`
- Parent `51bc14155338e47c76926047845a958205005bdd`
- Engineering SHA before notebook sync: `a2de4701b028e35622d9fb6b1ea2980d09179a92`
- Engineering SHA CI: **18/18 SUCCESS**
- Exact artifact comparison changed only `charge`, `defense_curl`, `growth`, `shell_smash`, and only their `classification` fields.
- Notebook synchronization moves branch tip. Require **18/18 on the final exact notebook-bearing HEAD**, then close #69 without merge.

## Workstream
**Move Effects V3 / battle-relevant DATA V3 semantic audit. Do not switch to trainer AI/archetypes.**

## What #69 resolves
- `shell_smash` -> `RUNTIME_SUPPORTED`; exact SELF package Defense -1, SpDef -1, Atk +2, SpAtk +2, Speed +2 is complete.
- `charge` -> `PARTIAL_RUNTIME`; keep SELF SpDef +1, missing Electric-boost state.
- `defense_curl` -> `PARTIAL_RUNTIME`; keep SELF Defense +1, missing Rollout/Ice Ball boost flag.
- `growth` -> `PARTIAL_RUNTIME`; keep neutral-weather SELF Atk +1 / SpAtk +1, missing harsh-sun +2/+2 branch.

All four retain target, accuracy and effect specs unchanged.

## Exact #69 engineering artifact
- `RUNTIME_SUPPORTED`: **590**
- `PARTIAL_RUNTIME`: **71**
- `DATA_ONLY`: **246**
- `UNSUPPORTED`: **12**
- DATA_ONLY with non-empty specs: **14**
  - 11 stat-change
  - Beat Up
  - Purify
  - Swallow

## Exact next task after #69 closure
Audit the first **mandatory-cost/stateful user group**:
1. `clangorous_soul`
2. `fillet_away`
3. `geomancy`
4. `no_retreat`

Known real mechanics already cross-checked publicly:
- Clangorous Soul: costs 1/3 max HP and fails when HP is too low; current free +1-all package would be false.
- Fillet Away: costs 1/2 max HP and has an HP threshold; current free +2 Atk/SpAtk/Speed would be false.
- Geomancy: requires a charge turn unless a Power Herb is consumed; current immediate +2/+2/+2 would be false.
- No Retreat: +1 all stats is inseparable from Can't Escape/switch restriction and repeat-use state; current unrestricted boosts would be false.

Recommended decision unless immutable source reveals a contradiction: keep each as `DATA_ONLY` but remove its executable stat specs until the missing transaction/state exists. Add fail-fast source/generated contracts and independent effect-free output tests.

## Other remaining user cases after that group
- `autotomize`: weight state.
- `extreme_evoboost`: Z-Move prerequisite/unusable in modern generations.
- `minimize`: persistent Minimized vulnerability.
- `stockpile`: capped stored counter + Spit Up/Swallow interaction.
- `tidy_up`: field cleanup transaction.

## Remaining all-pokemon
- `flower_shield`
- `rototiller`

## Remaining non-stat
- `Purify`
- `Swallow`
- `Beat Up`

## Safety rule
`effect_specs` execute regardless of coverage label. `DATA_ONLY` is not an execution gate. If a generated spec is known false or unsafe, remove/correct it before proceeding.

## Certification sequence
1. immutable source + public mechanic audit;
2. exact generated record inspection;
3. narrow implementation + fail-fast contracts;
4. independent regenerated-output tests;
5. DATA V3 focal;
6. 18/18 engineering SHA;
7. artifact diff/counts;
8. notebooks;
9. 18/18 exact final HEAD;
10. close PR without merge.

## Stop condition
If any focal or regression test fails, stop immediately, diagnose/fix root cause, rerun focal, then full matrix. Never accumulate failures.
