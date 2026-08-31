# DATA V3 / MOVE EFFECTS V3 AUDIT NOTEBOOK

## Invariant
Every executable `effect_spec` and battle-relevant move field must be semantically faithful. Coverage labels do not gate execution. If an omitted mechanic is a mandatory cost, prerequisite, transaction, target predicate, temporal delay, persistent state or strategic drawback, keeping only the visible benefit can create a stronger fake move; prefer effect-free `DATA_ONLY` unless the retained subset is provably safe.

## Canonical source / audit layers
- immutable snapshot: `data/pokeapi-v2-snapshot`, commit `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`
- compatibility corrections: `tools/pokeapi_adapter.py`
- canonical conversion: `tools/pokeapi_adapter_v3.py`
- selected-stateful: `tools/pokeapi_adapter_selected_stateful.py`
- all-opponents: `tools/pokeapi_adapter_all_opponents.py`
- safe user-stateful: `tools/pokeapi_adapter_user_stateful_safe.py`
- HP-cost user: `tools/pokeapi_adapter_user_hp_cost.py`
- mandatory-state user: `tools/pokeapi_adapter_user_mandatory_state.py`
- archived V2 remains provenance-only.

## Certified recent heads
- #63 accuracy — `9f8b3e01bec1f86cff75380d68dd98d76e738e78`
- #64 selected special stats — `674ccaf0928c93749c581565d53eb1f672dfd7b4`
- #65 selected stateful — `b13af37c350156bc7a9a7d7faf63742245afd801`
- #66 all-opponents — `51bc14155338e47c76926047845a958205005bdd`
- #69 safe user-stateful — `7aaae1c600120442581fdd7c0c048b29e3ee5690`
- #70 reconciled user audit chain — `4ee439a9741cc7dac8ec5d1792485ee79aa5f4b2`
All certified 18/18 and closed without merge.

## #70 reconciliation retained
#70 is the canonical continuation after the temporary #67/#68 vs #69 branch divergence. It preserves:
- self-target moves skipping only the normal opponent Accuracy/Evasion check;
- Clangorous Soul and Fillet Away effect-free because mandatory max-HP payment/failure transaction is unsupported;
- #69 safe subsets for Charge, Defense Curl, Growth and complete Shell Smash.

# PR #71 — mandatory-state user boosts (CURRENT)
Branch `fix/data-v3-user-mandatory-state-b`.
Parent: certified #70 final `4ee439a9741cc7dac8ec5d1792485ee79aa5f4b2`.
Engineering SHA before notebook sync: `b55a487b46ec5443992e623fef5b1c8ce2bb0665`.
Engineering SHA: **18/18 SUCCESS**.

## Geomancy
Immutable snapshot contract:
- target `user`;
- source accuracy null → canonical `-1`;
- SpAtk +2, SpDef +2, Speed +2;
- effect text: one turn to charge, then apply boosts.

Current public core-series mechanic:
- first turn charges;
- second turn applies +2/+2/+2;
- Power Herb can compress execution to one turn only by being consumed.

Generated pre-#71 package:
- three immediate deterministic SELF stat effects.

Current BattleEffectSpec has no charge/pending-action effect and no Power-Herb transaction for this move. The immediate package removes a mandatory temporal cost.
Decision: remain `DATA_ONLY`, set `effect_specs=[]`.

## No Retreat
Immutable snapshot contract:
- target `user`;
- source accuracy null → canonical `-1`;
- Attack/Defense/SpAtk/SpDef/Speed +1;
- effect text prevents switching out and states failure/reuse semantics.

Current public core-series mechanic:
- applies +1 to all five battle stats;
- applies Can't Escape/switch restriction;
- reuse has state-dependent failure semantics.

Generated pre-#71 package:
- five deterministic SELF +1 effects only.

Current BattleEffectSpec has no Can't Escape/trapping/reuse-state primitive. Keeping the boosts alone removes a mandatory strategic drawback and allows false repeatability.
Decision: remain `DATA_ONLY`, set `effect_specs=[]`.

## Independent #71 output gate
Regenerated raw data must assert for both:
- target `user`;
- canonical accuracy `-1`;
- classification `DATA_ONLY`;
- `effect_specs=[]`;
- canonical summary retains the missing real mechanic (charge for Geomancy; switching restriction for No Retreat).

## Exact #71 engineering artifact
Coverage:
- `RUNTIME_SUPPORTED`: **590**
- `PARTIAL_RUNTIME`: **71**
- `DATA_ONLY`: **246**
- `UNSUPPORTED`: **12**

DATA_ONLY with non-empty specs: **10**.
- 7 stat/stateful
- `Beat Up`, `Purify`, `Swallow`.

Exact #70→#71 raw comparison:
- exactly two records changed;
- `geomancy`: only `effect_specs`, 3 → 0;
- `no_retreat`: only `effect_specs`, 5 → 0;
- no classification, target, accuracy, summary or unrelated record changed.

Notebook sync moves the SHA. #71 requires a second exact-head 18/18 before closure without merge.

# Audit frontier after #71 engineering
## User — 5 remaining stat/stateful cases
- `autotomize`: Speed +2 plus weight reduction; weight change influences weight-based interactions and may be benefit or drawback.
- `extreme_evoboost`: +2 all five stats but is an Eevee-exclusive Z-Move with activation/legality prerequisites.
- `minimize`: Evasion +2 plus Minimized state causing special always-hit/double-damage interactions.
- `stockpile`: Def/SpDef +1 plus stored counter capped at three and Spit Up/Swallow dependency.
- `tidy_up`: Atk/Speed +1 plus field cleanup affecting hazards/substitutes.

Do not mass-promote these five. Audit the exact missing transaction/state before deciding partial vs effect-free DATA_ONLY.

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
