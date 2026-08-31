# NEXT STEPS — LIVE CHECKPOINT

Read this immediately after `00_READ_FIRST.md` when recovering context.

## Latest certified baseline before current tranche
- PR #69 — `fix/data-v3-user-stateful-safe-subsets-a`
- Final HEAD `7aaae1c600120442581fdd7c0c048b29e3ee5690`
- 18/18 SUCCESS on exact notebook-bearing HEAD
- closed without merge.

## Branch divergence that was discovered
Two valid lines had diverged from certified PR #66:
- PR #67 — Battle Core self-target accuracy fix; final HEAD `432781b78e8864192343b952b0645a48046ceed4`; 18/18 certified and closed without merge.
- PR #68 — HP-cost safety for `clangorous_soul` / `fillet_away`; engineering HEAD `fb5cbf71edf2327725d8506b1b32965b0fae6bec`; 18/18 green but PR remained open and was not the canonical continuation.
- PR #69 — Charge / Defense Curl / Growth / Shell Smash audit; certified independently from #66.

Do **not** resume from #67 or #68. PR #70 is the reconciliation point that reunifies those validated technical changes on top of certified #69.

## Current tranche — PR #70
- Title: `DATA V3 — reconcile self-target accuracy and HP-cost audits`
- Branch: `reconcile/data-v3-user-audit-chain`
- Parent: certified #69 final `7aaae1c600120442581fdd7c0c048b29e3ee5690`
- Engineering SHA before notebook sync: `20fedf932ae1a867dd641f0e693c21b745393a9b`
- Engineering SHA CI: **18/18 SUCCESS**
- Godot global: SUCCESS, including `BattleSelfTargetAccuracyTestSuite` through battle commands.
- DATA V3: SUCCESS, including the #69 safe-user-stateful suite and the HP-cost suite together.

### Technical reconciliation
Ported from certified #67:
- `TurnExecutor` skips the normal Accuracy/Evasion roll only for `move.target == "user"`.
- Selected/opponent-target moves retain normal accuracy behavior.
- Move-specific failure conditions remain separate mechanics.

Ported from #68 engineering:
- `clangorous_soul`: mandatory 1/3 max-HP cost/failure transaction is not representable; free +1-all specs removed.
- `fillet_away`: mandatory 1/2 max-HP cost/failure transaction is not representable; free +2 Atk/SpAtk/Speed specs removed.
- Both remain `DATA_ONLY` with `effect_specs=[]`.

Unified audit chain:
`all_opponents → user_stateful_safe (#69) → user_hp_cost (#68)`.

Exact artifact comparison #69 → #70 engineering:
- only two move records changed: `clangorous_soul`, `fillet_away`;
- on both, only `effect_specs` changed to `[]`;
- no classification, target, accuracy, summary or unrelated move changed.

Coverage remains:
- `RUNTIME_SUPPORTED`: **590**
- `PARTIAL_RUNTIME`: **71**
- `DATA_ONLY`: **246**
- `UNSUPPORTED`: **12**

DATA_ONLY with non-empty specs: **12** total.
- 9 remaining stat/stateful records.
- non-stat: `Beat Up`, `Purify`, `Swallow`.

## Current certification step
Notebook synchronization moves the SHA. Before closing #70:
1. verify only `docs/notebooks/01_PROJECT_STATE.md`, `02_DATA_V3_MOVE_EFFECTS_AUDIT.md`, `04_NEXT_STEPS.md` changed after engineering SHA `20fedf932ae1a867dd641f0e693c21b745393a9b`;
2. require all 18 workflows green on the exact final notebook-bearing HEAD;
3. close #70 without merge;
4. close #68 as superseded by #70, without merge.

## Exact next DATA V3 task after #70 certification
Audit the remaining user stat/stateful records, starting with the two clearly unsafe transactions:
1. `geomancy` — +2 SpAtk/SpDef/Speed occurs after a charging turn; Power Herb can consume an item to skip the charge. Immediate free boosts are false.
2. `no_retreat` — +1 all stats is coupled to switch/escape restriction and repeat-use state. Unrestricted repeatable boosts are false.

Unless immutable source/public mechanics reveal a contradiction, both should remain `DATA_ONLY` and lose executable stat specs until the missing state transaction exists.

Then remaining user cases:
- `autotomize`: weight-reduction state.
- `extreme_evoboost`: Eevee-exclusive Z-Move / generation legality.
- `minimize`: persistent Minimized vulnerabilities/always-hit interactions.
- `stockpile`: capped stored counter + Spit Up/Swallow transaction.
- `tidy_up`: mandatory field/substitute cleanup transaction.

Remaining all-pokemon:
- `flower_shield`
- `rototiller`

Remaining non-stat:
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
