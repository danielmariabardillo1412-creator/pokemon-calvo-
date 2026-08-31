# NEXT STEPS — LIVE CHECKPOINT

Read this immediately after `00_READ_FIRST.md` when recovering context.

## Previous certified tranche
- PR #64 — `fix/data-v3-selected-special-stat-packages-a`
- Final HEAD `674ccaf0928c93749c581565d53eb1f672dfd7b4`
- 18/18 SUCCESS on exact notebook-bearing HEAD
- closed without merge.

## Current tranche — PR #65
- Branch `fix/data-v3-selected-special-stateful-b`
- Parent `674ccaf0928c93749c581565d53eb1f672dfd7b4`
- Engineering SHA before notebook sync: `01854416bf54179b0caa32b99459667d40d369c7`
- Engineering SHA CI: **18/18 SUCCESS**
- DATA V3 independently verified all four selected-stateful decisions.
- Notebook synchronization moves branch tip. Require **18/18 on the final exact notebook-bearing HEAD**, then close #65 without merge.

## Workstream
**Move Effects V3 / battle-relevant DATA V3 semantic audit. Do not switch to trainer AI/archetypes.**

## What #65 resolves
The entire remaining `selected-pokemon` DATA_ONLY-with-specs family is now resolved.

### Defog
- real: Evasion -1 plus field/hazard/screen/terrain cleanup;
- current engine cannot represent cleanup;
- Evasion-only execution can remove a real strategic drawback;
- result: `DATA_ONLY`, `effect_specs=[]`, accuracy -1 preserved.

### Memento
- real: target Atk/SpAtk -2 and user faints;
- free -2/-2 without self-faint would be false;
- result: `DATA_ONLY`, `effect_specs=[]`, accuracy 100 preserved.

### Parting Shot
- real: target Atk/SpAtk -1 and user switches;
- staying active changes the transaction and permits false repeatable debuffs;
- result: `DATA_ONLY`, `effect_specs=[]`, accuracy 100 preserved.

### Tar Shot
- real: Speed -1 plus persistent Fire vulnerability;
- missing Fire vulnerability only weakens the move;
- result: `PARTIAL_RUNTIME`, retain exactly OPPONENT Speed -1, accuracy 100.

## Exact #65 engineering artifact
- `RUNTIME_SUPPORTED`: **584**
- `PARTIAL_RUNTIME`: **68**
- `DATA_ONLY`: **255**
- `UNSUPPORTED`: **12**
- DATA_ONLY with non-empty specs: **26**
  - 23 stat-change
  - Beat Up
  - Purify
  - Swallow

Exact #64→#65 comparison:
- only 4 move records changed;
- Defog/Memento/Parting Shot changed only `effect_specs` → empty;
- Tar Shot changed only `classification` DATA_ONLY → PARTIAL_RUNTIME;
- no unrelated move changed.

## Exact next task after #65 closure
Audit the **8 `all-opponents` stat-change moves** as the next candidate family:
- `captivate`
- `cotton_spore`
- `growl`
- `leer`
- `string_shot`
- `sweet_scent`
- `tail_whip`
- `venom_drench`

Do not promote them as one blind batch. First inspect immutable source + current public mechanics + exact generated outputs and split by semantics.

Known issues to check before classification:
- `Captivate`: gender/sex compatibility condition; an unconditional stat drop would be false if the predicate is unsupported.
- `Venom Drench`: poisoned-target prerequisite; unconditional drops would be false.
- spread target `all-opponents`: current singles engine has one opponent, so verify whether mapping the effect to OPPONENT is semantically faithful in the current model and does not hide another condition.
- `Growl`, `Leer`, `Cotton Spore`, `String Shot`, `Sweet Scent`, `Tail Whip`: likely simpler spread debuffs, but confirm current-generation stat packages and accuracy before grouping.

Recommended sequence:
1. inspect all eight source records and generated records without editing;
2. isolate conditional moves (`captivate`, `venom_drench`) from simple spread debuffs;
3. only batch moves with genuinely identical support logic;
4. add fail-fast source contracts + independent regenerated-output tests;
5. DATA V3 focal → 18/18 engineering → artifact diff → notebooks → 18/18 final → close without merge.

## Other remaining user conditional/stateful — 13
`autotomize`, `charge`, `clangorous_soul`, `defense_curl`, `extreme_evoboost`, `fillet_away`, `geomancy`, `growth`, `minimize`, `no_retreat`, `shell_smash`, `stockpile`, `tidy_up`.
Do not mass-promote.

## Remaining all-pokemon — 2
`flower_shield`, `rototiller`.
Current SELF/OPPONENT model likely requires conservative handling because both include target-set/type predicates.

## Remaining non-stat with specs — 3
`Purify`, `Swallow`, `Beat Up`.
Audit separately.

## Safety rule reinforced by #65
A retained effect can be factually true yet still be unsafe if an omitted mechanic is a mandatory cost/transaction or removes a strategic drawback. `PARTIAL_RUNTIME` is appropriate only when the exposed subset remains faithful and omissions do not create materially false advantageous behavior.

## Stop condition
If any focal or regression test fails, stop immediately, diagnose/fix root cause, rerun focal, then full matrix. Never accumulate failures.
