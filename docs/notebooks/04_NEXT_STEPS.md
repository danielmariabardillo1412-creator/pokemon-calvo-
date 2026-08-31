# NEXT STEPS — LIVE CHECKPOINT

Read this immediately after `00_READ_FIRST.md` when recovering context.

## Latest certified baseline before current tranche
- PR #71 — `fix/data-v3-user-mandatory-state-b`
- Final HEAD `98c68f1c184e84db30458a4533fb769cba1140ac`
- 18/18 SUCCESS on exact notebook-bearing HEAD
- closed without merge.

## Current tranche — PR #72
- Title: `DATA V3 — audit persistent-state user moves`
- Branch: `fix/data-v3-user-persistent-state-c`
- Parent: certified #71 final `98c68f1c184e84db30458a4533fb769cba1140ac`
- Engineering SHA before notebook sync: `16f7eef390fb08e7ce48f2a1d2cbf4547321a939`
- Engineering SHA CI: **18/18 SUCCESS**
- DATA V3 independent suite: SUCCESS
- Godot global: SUCCESS

## What #72 resolves
### Autotomize
- real base stat effect: Speed +2;
- current mechanics reduce weight by 100 kg per successful use, stacking to a 0.1 kg minimum;
- immutable snapshot generic prose is stale and incorrectly says weight is halved / does not stack;
- missing weight state can be beneficial or detrimental in weight-based interactions, so Speed +2 alone is not a safe partial.
Decision: `DATA_ONLY`, `effect_specs=[]`.
Canonical derived summary is repaired in memory to current 100 kg semantics; immutable source remains untouched.

### Minimize
- real base stat effect: Evasion +2;
- also applies persistent Minimized state with special attack vulnerabilities;
- Battle Core has no Minimized-state primitive;
- Evasion +2 alone removes an explicit drawback.
Decision: `DATA_ONLY`, `effect_specs=[]`.
Canonical summary now retains the Minimized-state fact generically.

## Small architecture improvement
New `tools/pokeapi_adapter_user_audit_chain.py` coordinates the narrow user audits in order:
`HP-cost → mandatory-state → persistent-state`.
It contains no move-specific semantic policy; this avoids repeatedly rewiring older certified layers.

## Exact #71 → #72 engineering artifact
- exactly two changed records: `autotomize`, `minimize`;
- both changed only `effect_specs` and `effect_summary`;
- no classification, target, accuracy or unrelated move changed.

Coverage remains:
- `RUNTIME_SUPPORTED`: **590**
- `PARTIAL_RUNTIME`: **71**
- `DATA_ONLY`: **246**
- `UNSUPPORTED`: **12**

DATA_ONLY with non-empty specs: **8**.
- 5 stat/stateful total.
- non-stat: `Beat Up`, `Purify`, `Swallow`.

## Current certification step
Notebook synchronization moves SHA. Before closing #72:
1. verify only notebooks 01/02/04 changed after engineering SHA `16f7eef390fb08e7ce48f2a1d2cbf4547321a939`;
2. require 18/18 on exact final notebook-bearing HEAD;
3. close #72 without merge;
4. use that exact final HEAD as next baseline.

## Exact next DATA V3 task after #72 certification
Only **3 user stat/stateful DATA_ONLY-with-specs** remain:
1. `extreme_evoboost`
2. `stockpile`
3. `tidy_up`

Recommended handling:
- `stockpile`: audit first; counter/cap and Spit Up/Swallow dependency probably make free Def/SpDef boosts unsafe without stored-state transaction.
- `tidy_up`: audit cleanup transaction vs stat boosts; determine whether retaining Atk/Speed alone creates strategic distortion.
- `extreme_evoboost`: audit Z-Move/Eevee activation and generation legality; do not treat as an ordinary freely selectable move.

Then all-pokemon:
- `flower_shield`
- `rototiller`

Then non-stat:
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
