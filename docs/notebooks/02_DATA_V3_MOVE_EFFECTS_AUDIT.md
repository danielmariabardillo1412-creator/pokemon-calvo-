# DATA V3 / MOVE EFFECTS V3 AUDIT NOTEBOOK

## Invariant
Every executable `effect_spec` and battle-relevant move field must be semantically faithful. If Battle Core cannot represent a mechanic, preserve only a provably safe faithful subset (`PARTIAL_RUNTIME`) or remove executable effects (`DATA_ONLY`). Coverage labels do not gate execution.

A retained effect can be individually true yet unsafe if an omitted mechanic is a mandatory cost, prerequisite, transaction, target predicate, or strategic drawback. In those cases prefer effect-free `DATA_ONLY`.

## Canonical source / layers
- immutable snapshot: `data/pokeapi-v2-snapshot`, commit `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`
- compatibility corrections: `tools/pokeapi_adapter.py`
- canonical conversion: `tools/pokeapi_adapter_v3.py`
- selected-stateful audit: `tools/pokeapi_adapter_selected_stateful.py`
- all-opponents audit: `tools/pokeapi_adapter_all_opponents.py`
- safe user-stateful audit: `tools/pokeapi_adapter_user_stateful_safe.py`
- archived V2 remains provenance-only.

## Certified recent heads
- #63 accuracy — `9f8b3e01bec1f86cff75380d68dd98d76e738e78`
- #64 selected special stats — `674ccaf0928c93749c581565d53eb1f672dfd7b4`
- #65 selected stateful — `b13af37c350156bc7a9a7d7faf63742245afd801`
- #66 all-opponents — `51bc14155338e47c76926047845a958205005bdd`
All: 18/18 on exact final HEAD and closed without merge.

# PR #69 — safe user-stateful subsets (CURRENT)
Branch `fix/data-v3-user-stateful-safe-subsets-a`.
Parent: certified #66 final `51bc14155338e47c76926047845a958205005bdd`.
Engineering SHA before notebook sync: `a2de4701b028e35622d9fb6b1ea2980d09179a92`.
Engineering SHA: **18/18 SUCCESS**.

## Shell Smash
Immutable source and current mechanics agree on one complete SELF transaction:
- Defense -1
- Special Defense -1
- Attack +2
- Special Attack +2
- Speed +2
- target user, source accuracy null -> canonical -1

Legacy/generated output already matches exactly. Decision: `RUNTIME_SUPPORTED`; effects unchanged.

## Charge
Source contains two parts:
- Special Defense +1;
- Charge/Electric-boost state for a later Electric move.
Current public Gen IX mechanics retain the boost until a qualifying Electric move is attempted/used under the game's rules rather than merely 'next turn'.

Generated output contains only SELF SpDef +1. That subset is independently true; the missing mechanic is an additional benefit, not a cost. Decision: `PARTIAL_RUNTIME`; effects unchanged.

## Defense Curl
Source/current mechanics:
- Defense +1;
- persistent state doubling Rollout and Ice Ball power while user remains in battle.

Generated output contains SELF Defense +1 only. Missing state only removes an additional benefit. Decision: `PARTIAL_RUNTIME`; effects unchanged.

## Growth
Source/current mechanics:
- Attack +1 and SpAtk +1 normally;
- Attack +2 and SpAtk +2 in harsh sunlight.

Generated output contains the neutral-weather +1/+1 package. Missing weather branch only weakens the move. Decision: `PARTIAL_RUNTIME`; effects unchanged.

## Independent #69 tests
Regenerated raw data must verify for all four:
- target `user`;
- canonical `accuracy=-1`;
- exact coverage;
- exact number of SELF `modify_stat_stage` effects;
- every effect deterministic at 10000 bp;
- exact stat dictionary.

## Exact #69 engineering artifact
- `RUNTIME_SUPPORTED`: **590**
- `PARTIAL_RUNTIME`: **71**
- `DATA_ONLY`: **246**
- `UNSUPPORTED`: **12**
- DATA_ONLY with non-empty specs: **14**
  - 11 stat-change
  - `Beat Up`, `Purify`, `Swallow`

Exact #66→#69 raw comparison:
- exactly four records changed: `charge`, `defense_curl`, `growth`, `shell_smash`;
- only `classification` changed on each;
- effect specs, accuracy, target and summaries unchanged;
- no unrelated record changed.

Notebook sync moves the SHA. #69 requires a second exact-head 18/18 before closure without merge.

# Audit frontier after #69 engineering
## User — 9 unsafe/special cases
- `autotomize`: Speed +2 plus weight reduction; weight change can alter both benefits and drawbacks of weight-based attacks.
- `clangorous_soul`: +1 five stats with mandatory 1/3 max-HP cost/failure rule.
- `extreme_evoboost`: +2 five stats but is an Eevee-exclusive Z-Move and cannot be selected from Gen VIII onward.
- `fillet_away`: +2 Atk/SpAtk/Speed with mandatory 1/2 max-HP cost and failure threshold.
- `geomancy`: +2 SpAtk/SpDef/Speed after a charging turn; Power Herb interaction can skip charge at item cost.
- `minimize`: Evasion +2 plus persistent Minimized vulnerability/always-hit interactions.
- `no_retreat`: +1 five stats plus Can't Escape/switch restriction and repeat-use semantics.
- `stockpile`: Def/SpDef +1 plus stored counter capped at 3 and Spit Up/Swallow interactions.
- `tidy_up`: Atk/Speed +1 plus mandatory field cleanup of hazards/substitutes on both sides.

Do not leave their stat packages active until the omitted mechanic is proven harmless. Next useful audit group: mandatory-cost/transaction cases (`clangorous_soul`, `fillet_away`, `geomancy`, `no_retreat`).

## All-pokemon — 2
`flower_shield`, `rototiller`; both require all-Pokémon/type predicates.

## Non-stat — 3
`Purify`, `Swallow`, `Beat Up`.

## Audit protocol
1. inspect immutable source;
2. cross-check public mechanics when needed;
3. inspect exact generated artifact;
4. identify missing costs/predicates/state;
5. choose safe coverage;
6. fail-fast source/generated contract;
7. independent regenerated-output assertion;
8. DATA V3 focal;
9. 18/18 engineering SHA;
10. exact artifact diff;
11. notebooks;
12. 18/18 final HEAD;
13. close without merge.

Stop on any failure; fix root cause before another family.
