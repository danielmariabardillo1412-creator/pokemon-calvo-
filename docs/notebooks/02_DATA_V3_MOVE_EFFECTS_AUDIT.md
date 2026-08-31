# DATA V3 / MOVE EFFECTS V3 AUDIT NOTEBOOK

## Invariant
Every executable `effect_spec` and battle-relevant move field must be semantically faithful. If Battle Core cannot represent a mechanic, preserve only a provably safe faithful subset (`PARTIAL_RUNTIME`) or remove executable effects (`DATA_ONLY`). Coverage labels do not gate execution.

If an omitted mechanic is a mandatory cost, prerequisite, transaction, target predicate, or strategic drawback, keeping the visible benefit can create a stronger fake move. In those cases prefer effect-free `DATA_ONLY`.

## Canonical source / audit layers
- immutable snapshot: `data/pokeapi-v2-snapshot`, commit `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`
- compatibility corrections: `tools/pokeapi_adapter.py`
- canonical conversion: `tools/pokeapi_adapter_v3.py`
- selected-stateful: `tools/pokeapi_adapter_selected_stateful.py`
- all-opponents: `tools/pokeapi_adapter_all_opponents.py`
- safe user-stateful: `tools/pokeapi_adapter_user_stateful_safe.py`
- HP-cost user moves: `tools/pokeapi_adapter_user_hp_cost.py`
- archived V2 remains provenance-only.

## Certified recent heads
- #63 accuracy — `9f8b3e01bec1f86cff75380d68dd98d76e738e78`
- #64 selected special stats — `674ccaf0928c93749c581565d53eb1f672dfd7b4`
- #65 selected stateful — `b13af37c350156bc7a9a7d7faf63742245afd801`
- #66 all-opponents — `51bc14155338e47c76926047845a958205005bdd`
- #69 safe user-stateful subsets — `7aaae1c600120442581fdd7c0c048b29e3ee5690`
All certified 18/18 and closed without merge.

# PR #70 — reconcile parallel user-audit branches (CURRENT)
Branch `reconcile/data-v3-user-audit-chain`.
Parent: certified #69 final `7aaae1c600120442581fdd7c0c048b29e3ee5690`.
Engineering SHA before notebook sync: `20fedf932ae1a867dd641f0e693c21b745393a9b`.
Engineering SHA: **18/18 SUCCESS**.

## Why reconciliation was required
Two correct work lines diverged from certified #66:
- #67 fixed Battle Core accuracy semantics for self-target moves and was fully certified/closed.
- #68 audited Clangorous Soul and Fillet Away on top of #67; its engineering SHA was 18/18 but its PR remained open before final notebook certification.
- #69 independently audited Charge, Defense Curl, Growth and Shell Smash directly from #66 and later became the newest fully certified baseline.

Therefore neither #68 nor #69 alone contained all validated changes. #70 starts from #69 and replays only the technical production/tests from #67/#68. Old notebooks are not replayed.

## #67 runtime fix retained in #70
Root cause: `TurnExecutor` performed the normal actor Accuracy vs opposing Evasion check even for moves whose canonical target is `user`.

Fix:
- skip only the normal accuracy/evasion roll when `move.target == "user"`;
- non-user targets keep existing accuracy logic;
- move-specific failure conditions remain separate mechanics.

Regression ported byte-for-byte from certified #67:
- synthetic self-target move with accuracy=0, actor Accuracy -6 and opponent Evasion +6 must execute and consume PP without MOVE_MISSED;
- selected-target move with the same accuracy=0 must still miss.

Godot global, including battle-commands phase, passes in #70.

## Clangorous Soul — unsafe free HP-cost boost removed
Source/package:
- target user;
- Attack/Defense/SpAtk/SpDef/Speed +1;
- mandatory loss of 1/3 max HP / failure semantics.

Legacy output exposed five free SELF +1 effects because current Battle Core has no atomic max-HP payment + insufficient-HP failure primitive.

Decision:
- remain `DATA_ONLY`;
- `effect_specs=[]` until HP-payment transaction exists.

## Fillet Away — unsafe free HP-cost boost removed
Source/package:
- target user;
- Attack/SpAtk/Speed +2;
- mandatory 1/2 max-HP payment and failure threshold.

Legacy output exposed three free SELF +2 effects.

Decision:
- remain `DATA_ONLY`;
- `effect_specs=[]`.

The exact #68 audit module and independent output suite are replayed in #70. The only integration adaptation is the deterministic layer order:
`all-opponents → user-stateful-safe (#69) → user-hp-cost (#68)`.

## Exact #70 engineering artifact
Coverage:
- `RUNTIME_SUPPORTED`: **590**
- `PARTIAL_RUNTIME`: **71**
- `DATA_ONLY`: **246**
- `UNSUPPORTED`: **12**

DATA_ONLY with non-empty specs: **12**.
- 9 stat-change
- `Beat Up`, `Purify`, `Swallow`.

Exact #69→#70 raw comparison:
- exactly two move records changed;
- `clangorous_soul`: only `effect_specs`, five SELF +1 effects → empty;
- `fillet_away`: only `effect_specs`, three SELF +2 effects → empty;
- no classification, target, accuracy, summary or unrelated record changed.
- Battle Core #67 fix produces no raw-data differences.

Notebook sync moves the SHA. #70 requires second exact-head 18/18 before closure without merge.

# Audit frontier after #70 engineering
## User — 7 remaining stat/stateful cases
- `autotomize`: Speed +2 plus weight reduction; needs weight-state risk decision.
- `extreme_evoboost`: +2 to five stats but Z-Move/Eevee prerequisite and modern unavailability.
- `geomancy`: +2 SpAtk/SpDef/Speed after a charge turn; Power Herb can pay item cost to skip charge.
- `minimize`: Evasion +2 plus persistent Minimized vulnerability/always-hit/double-damage interactions.
- `no_retreat`: +1 five stats plus Can't Escape/switch restriction and repeat-use state.
- `stockpile`: Def/SpDef +1 plus stored counter capped at three and Spit Up/Swallow interactions.
- `tidy_up`: Atk/Speed +1 plus field cleanup transaction affecting hazards/substitutes.

Immediate next useful group: `geomancy` + `no_retreat`; their omitted charge/restriction mechanics make the current free stat packages unsafe.

## All-pokemon — 2
`flower_shield`, `rototiller`.

## Non-stat — 3
`Purify`, `Swallow`, `Beat Up`.

## Audit protocol
1. inspect immutable source;
2. cross-check current public mechanics where needed;
3. inspect exact generated record;
4. identify missing costs/predicates/state;
5. choose safe coverage;
6. fail-fast contract;
7. independent output assertion;
8. DATA V3 focal;
9. 18/18 engineering SHA;
10. artifact diff;
11. notebooks;
12. 18/18 final HEAD;
13. close without merge.

Stop on any failure and fix root cause before continuing.
