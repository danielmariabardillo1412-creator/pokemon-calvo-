# NEXT STEPS — LIVE CHECKPOINT

Read this immediately after `00_READ_FIRST.md` when recovering context.

## Latest certified baseline before current tranche
- PR #70 — `reconcile/data-v3-user-audit-chain`
- Final HEAD `4ee439a9741cc7dac8ec5d1792485ee79aa5f4b2`
- 18/18 SUCCESS on exact notebook-bearing HEAD
- closed without merge.

#70 is the canonical continuation after the temporary #67/#68 vs #69 branch divergence. Do not resume from #67 or #68.

## Current tranche — PR #71
- Title: `DATA V3 — neutralize mandatory-state user boosts`
- Branch: `fix/data-v3-user-mandatory-state-b`
- Parent: certified #70 final `4ee439a9741cc7dac8ec5d1792485ee79aa5f4b2`
- Engineering SHA before notebook sync: `b55a487b46ec5443992e623fef5b1c8ce2bb0665`
- Engineering SHA CI: **18/18 SUCCESS**
- DATA V3 independent suite: SUCCESS
- Godot global: SUCCESS

## What #71 resolves
### Geomancy
- real source: one charge turn, then SpAtk/SpDef/Speed +2;
- Power Herb can skip the delay by consuming the item;
- current Battle Core has no charge/pending-turn primitive;
- immediate free +2/+2/+2 was false.
Decision: `DATA_ONLY`, `effect_specs=[]`.

### No Retreat
- real source: +1 Attack/Defense/SpAtk/SpDef/Speed;
- inseparable Can't Escape/switch restriction and reuse/failure state;
- current Battle Core has no trapping/reuse-state primitive;
- free repeatable +1-all was false.
Decision: `DATA_ONLY`, `effect_specs=[]`.

Exact #70 → #71 artifact comparison:
- changed records: exactly `geomancy`, `no_retreat`;
- changed key on both: only `effect_specs`;
- no classification, target, accuracy, summary or unrelated move changed.

Coverage remains:
- `RUNTIME_SUPPORTED`: **590**
- `PARTIAL_RUNTIME`: **71**
- `DATA_ONLY`: **246**
- `UNSUPPORTED`: **12**

DATA_ONLY with non-empty specs: **10**.
- 7 stat/stateful.
- non-stat: `Beat Up`, `Purify`, `Swallow`.

## Current certification step
Notebook synchronization moves SHA. Before closing #71:
1. verify only 01/02/04 changed after engineering SHA `b55a487b46ec5443992e623fef5b1c8ce2bb0665`;
2. require 18/18 on the exact final notebook-bearing HEAD;
3. close #71 without merge;
4. use that exact final HEAD as next baseline.

## Exact next DATA V3 task after #71 certification
Audit the remaining **5 user stat/stateful DATA_ONLY-with-specs**:
- `autotomize`
- `extreme_evoboost`
- `minimize`
- `stockpile`
- `tidy_up`

Recommended split:
1. `autotomize` + `minimize`: persistent self-state omitted from otherwise real stat boosts; determine whether omission is merely weakening or strategically false.
2. `stockpile`: counter/cap and Spit Up/Swallow dependency; likely unsafe without stored-state transaction.
3. `tidy_up`: field/substitute cleanup plus boosts; determine whether retaining boosts alone removes an inseparable cost/strategic effect.
4. `extreme_evoboost`: Z-Move/Eevee activation and generation legality; do not treat as ordinary freely selectable status move.

Then remaining all-pokemon:
- `flower_shield`
- `rototiller`

Then remaining non-stat:
- `Purify`
- `Swallow`
- `Beat Up`

## Workstream
**Move Effects V3 / battle-relevant DATA V3 semantic audit. Do not switch to trainer AI/archetypes.**

## Safety rule
`effect_specs` execute regardless of coverage label. `DATA_ONLY` is not an execution gate. If a generated spec is known false or strategically unsafe, remove/correct it before proceeding.

## Certification protocol
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
