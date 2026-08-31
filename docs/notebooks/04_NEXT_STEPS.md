# NEXT STEPS — LIVE CHECKPOINT

Read this immediately after `00_READ_FIRST.md` when recovering context.

## Previous certified tranche
- PR #66 — `fix/data-v3-all-opponents-stat-audit`
- Final HEAD `51bc14155338e47c76926047845a958205005bdd`
- 18/18 SUCCESS on exact notebook-bearing HEAD
- closed without merge.

## Current tranche — PR #67
- Branch `fix/battle-self-target-accuracy`
- Parent `51bc14155338e47c76926047845a958205005bdd`
- Engineering SHA before notebook sync: `b4beb85a57738acfdacfdb0859a20b427d08f908`
- Engineering SHA CI: **18/18 SUCCESS**
- No DATA V3 record or coverage count changes.
- Notebook synchronization moves branch tip. Require **18/18 on the final exact notebook-bearing HEAD**, then close #67 without merge.

## Workstream
**Move Effects V3 / battle-relevant DATA V3 semantic audit. Do not switch to trainer AI/archetypes.**

## What #67 fixes
A transversal Battle Core bug discovered during the user-target audit:
- before #67, every move performed the normal Accuracy/Evasion check against the opponent;
- this included moves whose canonical target is only `user`;
- therefore opponent Evasion or reduced user Accuracy could make a self-only move emit `MOVE_MISSED`.

New contract:
- if `move.target == "user"`, skip the normal Accuracy/Evasion roll;
- all other targets keep existing accuracy logic;
- move-specific failure conditions remain separate and are **not** bypassed.

Regression:
- synthetic self-target move with accuracy 0, actor Accuracy -6, opponent Evasion +6 must execute without `MOVE_MISSED` and consume PP;
- synthetic selected-target move with accuracy 0 must still miss;
- suite runs through the existing CI-gated `battle_commands_test_runner.gd`.

## Coverage remains unchanged from #66
- `RUNTIME_SUPPORTED`: **589**
- `PARTIAL_RUNTIME`: **68**
- `DATA_ONLY`: **250**
- `UNSUPPORTED`: **12**
- DATA_ONLY with non-empty specs: **18**
  - 15 stat-change
  - Beat Up
  - Purify
  - Swallow

## Exact next task after #67 closure
Resume the 13 `user` conditional/stateful moves with the **HP-cost pair only**:
1. `clangorous_soul`
2. `fillet_away`

Already established:
- Clangorous Soul currently exposes five SELF +1 stat effects but real semantics pay 1/3 max HP and can fail when the payment/prerequisites are not satisfied.
- Fillet Away currently exposes SELF Attack +2 / Special Attack +2 / Speed +2 but real semantics pay 1/2 max HP and require sufficient HP.
- Coverage labels do not gate these specs, so today they can execute as false free boosts.
- Current `RECOIL` cannot model the payment: it is based on `context.last_damage`, not user max HP, and there is no payment prerequisite/failure transaction.

Recommended action:
- create a separate DATA V3 tranche from the final certified #67 SHA;
- fail-fast validate immutable source + exact generated boost packages;
- remove executable specs for both;
- keep them `DATA_ONLY` until a proper max-HP payment/failure primitive exists;
- add independent regenerated-output assertions;
- focal DATA V3 → 18/18 engineering → artifact diff → notebooks → 18/18 final → close without merge.

## Remaining user moves after HP-cost pair
- `autotomize`
- `charge`
- `defense_curl`
- `extreme_evoboost`
- `geomancy`
- `growth`
- `minimize`
- `no_retreat`
- `shell_smash`
- `stockpile`
- `tidy_up`

Suggested families:
- two-turn/delayed: Geomancy
- weather-dependent: Growth
- stored counter/state: Stockpile
- persistent/special interactions: Autotomize, Charge, Defense Curl, Minimize, No Retreat, Tidy Up
- multi-stat packages: Shell Smash, Extreme Evoboost

After user family:
- all-pokemon: `flower_shield`, `rototiller`
- non-stat: `Purify`, `Swallow`, `Beat Up`

## Safety rule
`effect_specs` execute regardless of coverage label. `DATA_ONLY` is not an execution gate. A known-false or strategically unsafe spec must be removed/corrected.

## Stop condition
If any focal or regression test fails, stop immediately, diagnose/fix root cause, rerun focal, then full matrix. Never accumulate failures.
