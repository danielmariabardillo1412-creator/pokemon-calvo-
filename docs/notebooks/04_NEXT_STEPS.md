# NEXT STEPS — LIVE CHECKPOINT

Read this immediately after `00_READ_FIRST.md` when recovering context.

## Latest certified baseline before current tranche
- PR #72 — `fix/data-v3-user-persistent-state-c`
- Final HEAD `d46be6864abd6e1cffdf54f9e932da06bed054dc`
- 18/18 SUCCESS on exact notebook-bearing HEAD
- closed without merge.

## Current tranche — PR #73
- Title: `DATA V3 — neutralize final user-state stat packages`
- Branch: `fix/data-v3-user-terminal-state-d`
- Parent: certified #72 final `d46be6864abd6e1cffdf54f9e932da06bed054dc`
- Engineering SHA before notebook sync: `51f0a15bf980befc2fdb2393dd8b516a2f53eaed`
- Engineering SHA CI: **18/18 SUCCESS**
- DATA V3 independent suite: SUCCESS
- Godot global: SUCCESS

## What #73 resolves
### Extreme Evoboost
- source +2 to all five battle stats;
- real move is Eevee's exclusive Z-Move derived from Last Resort and not an ordinary freely selectable modern move;
- +2-all exposed as a normal move is false.
Decision: `DATA_ONLY`, `effect_specs=[]`; canonical summary records Z-Move/selectability constraint.

### Stockpile
- source Defense +1 / SpDef +1;
- real move also stores a capped counter (max three), couples to Spit Up/Swallow and consumes/loses associated state;
- stat-only execution is unsafe.
Decision: `DATA_ONLY`, `effect_specs=[]`; summary records max-three/coupling semantics.

### Tidy Up
- source Attack +1 / Speed +1;
- real move also removes Spikes, Toxic Spikes, Stealth Rock, Sticky Web and Substitute from both sides;
- omitting bilateral cleanup can preserve strategically favorable hazards.
Decision: `DATA_ONLY`, `effect_specs=[]`; summary is synthesized from Scarlet/Violet source/current mechanics.

## Exact #72 → #73 engineering artifact
- exactly three changed records: `extreme_evoboost`, `stockpile`, `tidy_up`;
- changed keys on each: `effect_specs`, `effect_summary` only;
- no classification, target, accuracy or unrelated record changed.

Coverage remains:
- `RUNTIME_SUPPORTED`: **590**
- `PARTIAL_RUNTIME`: **71**
- `DATA_ONLY`: **246**
- `UNSUPPORTED`: **12**

DATA_ONLY with non-empty specs: **5** only:
1. `flower_shield`
2. `rototiller`
3. `beat_up`
4. `purify`
5. `swallow`

Important milestone: **zero remaining `target=user` DATA_ONLY records with executable stat specs**.

## Current certification step
Notebook synchronization moves SHA. Before closing #73:
1. verify only notebooks 01/02/04 changed after engineering SHA `51f0a15bf980befc2fdb2393dd8b516a2f53eaed`;
2. require 18/18 on exact final notebook-bearing HEAD;
3. close #73 without merge;
4. use that exact final HEAD as next baseline.

## Exact next DATA V3 task after #73 certification
Audit the two remaining `all-pokemon` stat cases:
- `flower_shield`
- `rototiller`

Do not map `all-pokemon` blindly to SELF or OPPONENT. Verify immutable source + current mechanics + exact generated specs, especially Grass-type/grounded predicates and whether the current OPPONENT-targeted generated boosts are false.

After those two, only three non-stat DATA_ONLY-with-spec cases remain:
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
