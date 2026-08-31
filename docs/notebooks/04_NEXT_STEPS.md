# NEXT STEPS — LIVE CHECKPOINT

Read this immediately after `00_READ_FIRST.md` when recovering context.

## Previous certified tranche
- PR #62 — `fix/data-v3-simple-opponent-stat-drops-a`
- Final HEAD `6d1335b8c5cee0b1cf1e99910a7707734b4aef85`
- 18/18 SUCCESS on exact notebook-bearing HEAD
- closed without merge.

## Current tranche — PR #63
- Branch `fix/data-v3-always-hit-accuracy`
- Parent `6d1335b8c5cee0b1cf1e99910a7707734b4aef85`
- Engineering SHA before notebook sync: `428e1f2e387301899d749a9b97127f9e1a0a5b45`
- Engineering SHA CI: **18/18 SUCCESS**
- DATA V3 independently verified null-accuracy canonicalization, MoveDefinition preservation and BattleRuleset sentinel semantics.
- Notebook synchronization moves branch tip. Require **18/18 on the final exact notebook-bearing HEAD**, then close #63 without merge.

## Workstream
**Move Effects V3 / battle-relevant DATA V3 semantic audit. Do not switch to trainer AI/archetypes.**

## What #63 fixes
PokéAPI `accuracy=null` previously became canonical `accuracy=100`.
That was wrong because Battle Core distinguishes:
- negative accuracy = bypass normal accuracy/evasion check;
- 100 = normal 100% base accuracy, still modified by Accuracy/Evasion stages.

Correct mapping is now:
- numeric source accuracy → same integer;
- null source accuracy → `-1`.

No Battle Core change was required.

## Exact #63 engineering artifact
Compared with certified #62:
- 919 moves before and after.
- **285** records changed.
- every changed record changed **only `accuracy`**.
- 0 classification changes.
- 0 `effect_specs` changes.

285 always-hit records by coverage:
- 66 RUNTIME_SUPPORTED
- 28 PARTIAL_RUNTIME
- 180 DATA_ONLY
- 11 UNSUPPORTED

Overall coverage remains:
- `RUNTIME_SUPPORTED`: **582**
- `PARTIAL_RUNTIME`: **67**
- `DATA_ONLY`: **258**
- `UNSUPPORTED`: **12**

Sentinels:
- Confide / Play Nice / Tearful Look / Decorate / Spicy Extract → -1
- Charm → genuine 100 remains 100
- BattleRuleset(-1, Accuracy -6, Evasion +6) → 10000 bp
- BattleRuleset(100, Accuracy -6, Evasion +6) → below 10000 bp

## Exact next task after #63 closure
Return to the six remaining `selected-pokemon` special stat cases. Start with the two already inspected:
1. `Decorate`
2. `Spicy Extract`

Initial evidence already established:
- Decorate source: selected-pokemon, Attack +2 / SpAtk +2, accuracy null.
- Its generated effects are OPPONENT Attack +2 / SpAtk +2.
- Spicy Extract source: selected-pokemon, Attack +2 / Defense -2, accuracy null.
- Its generated effects are OPPONENT Attack +2 / Defense -2.
- #63 makes their always-hit accuracy representation faithful (`-1`).

Do not promote them merely from this note. After #63 certification:
- re-check exact source contracts,
- add fail-fast move-specific/package validation,
- add independent regenerated-output assertions including accuracy=-1,
- decide `RUNTIME_SUPPORTED` only if the full current singles battle semantics are represented.

Then audit separately:
- `Defog` — field/hazard/screen cleanup beyond visible stat change.
- `Memento` — user faints after target drops.
- `Parting Shot` — user switches after target drops.
- `Tar Shot` — Speed drop plus Fire interaction/state.

## Remaining DATA_ONLY with specs after #62/#63
32 total:
- 29 stat-change
- Beat Up
- Purify
- Swallow

Stat targets:
- 13 user
- 8 all-opponents
- 6 selected-pokemon
- 2 all-pokemon

User conditional/stateful:
`autotomize`, `charge`, `clangorous_soul`, `defense_curl`, `extreme_evoboost`, `fillet_away`, `geomancy`, `growth`, `minimize`, `no_retreat`, `shell_smash`, `stockpile`, `tidy_up`.

All-opponents:
`captivate`, `cotton_spore`, `growl`, `leer`, `string_shot`, `sweet_scent`, `tail_whip`, `venom_drench`.

All-pokemon:
`flower_shield`, `rototiller`.

## Stop condition
If any focal or regression test fails, stop immediately, diagnose/fix root cause, rerun focal, then full matrix. Never accumulate failures.
