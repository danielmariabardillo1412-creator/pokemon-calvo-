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
- user audit coordinator: `tools/pokeapi_adapter_user_audit_chain.py`
- HP-cost user: `tools/pokeapi_adapter_user_hp_cost.py`
- mandatory-state user: `tools/pokeapi_adapter_user_mandatory_state.py`
- persistent-state user: `tools/pokeapi_adapter_user_persistent_state.py`
- archived V2 remains provenance-only.

## Certified recent heads
- #63 accuracy — `9f8b3e01bec1f86cff75380d68dd98d76e738e78`
- #64 selected special stats — `674ccaf0928c93749c581565d53eb1f672dfd7b4`
- #65 selected stateful — `b13af37c350156bc7a9a7d7faf63742245afd801`
- #66 all-opponents — `51bc14155338e47c76926047845a958205005bdd`
- #69 safe user-stateful — `7aaae1c600120442581fdd7c0c048b29e3ee5690`
- #70 reconciled user audit chain — `4ee439a9741cc7dac8ec5d1792485ee79aa5f4b2`
- #71 mandatory-state user — `98c68f1c184e84db30458a4533fb769cba1140ac`
All certified 18/18 and closed without merge.

# PR #72 — persistent-state user moves (CURRENT)
Branch `fix/data-v3-user-persistent-state-c`.
Parent: certified #71 final `98c68f1c184e84db30458a4533fb769cba1140ac`.
Engineering SHA before notebook sync: `16f7eef390fb08e7ce48f2a1d2cbf4547321a939`.
Engineering SHA: **18/18 SUCCESS**.

## Coordinator refactor
`pokeapi_adapter_user_audit_chain.py` is a 14-line coordinator only. It applies narrow audits in deterministic order:
1. HP-cost;
2. mandatory-state;
3. persistent-state.
It intentionally contains no move-specific policy. This avoids repeatedly rewiring already-certified audit modules as the remaining user families are processed.

## Autotomize
Immutable snapshot:
- target `user`;
- source accuracy null → canonical `-1`;
- Speed +2;
- generic effect prose incorrectly says weight is halved and does not stack.

Current core-series mechanics verified publicly:
- each successful use reduces weight by 100 kg;
- reduction stacks to a minimum effective weight of 0.1 kg.

Generated pre-#72 package:
- one deterministic SELF Speed +2 effect.

Why not PARTIAL_RUNTIME:
- weight state affects weight-based attacks and can be beneficial or detrimental;
- preserving the original weight while granting Speed +2 can make some interactions artificially stronger than the real move.

Decision:
- remain `DATA_ONLY`;
- `effect_specs=[]`;
- immutable snapshot untouched;
- normalize only the loaded English effect prose before canonical `effect_summary` is built.

Canonical derived summary now says Speed +2 and weight -100 kg rather than the stale half-weight rule.

## Minimize
Immutable snapshot:
- target `user`;
- source accuracy null → canonical `-1`;
- Evasion +2;
- source effect records Minimize-specific vulnerabilities but only an older/incomplete subset of affected attacks.

Modern core-series mechanic:
- using Minimize establishes persistent Minimized state;
- special attacks against Minimized targets receive accuracy/damage exceptions.

Generated pre-#72 package:
- one deterministic SELF Evasion +2 effect.

Why not PARTIAL_RUNTIME:
- current Battle Core has no Minimized-state primitive;
- keeping Evasion +2 while omitting the vulnerability state removes an explicit drawback and makes the move stronger.

Decision:
- remain `DATA_ONLY`;
- `effect_specs=[]`;
- canonical English summary normalized generically to state that Minimized state is applied, avoiding a stale/incomplete move list.

## Independent #72 output gate
Regenerated raw data must verify:
- Autotomize: target user, accuracy -1, DATA_ONLY, empty specs, summary includes 100 kg and excludes stale half/no-stack wording.
- Minimize: target user, accuracy -1, DATA_ONLY, empty specs, summary includes Evasion and Minimized state.

## Exact #72 engineering artifact
Coverage:
- `RUNTIME_SUPPORTED`: **590**
- `PARTIAL_RUNTIME`: **71**
- `DATA_ONLY`: **246**
- `UNSUPPORTED`: **12**

DATA_ONLY with non-empty specs: **8**.
- 5 stat/stateful total.
- non-stat: `Beat Up`, `Purify`, `Swallow`.

Exact #71→#72 raw comparison:
- exactly two records changed: `autotomize`, `minimize`;
- changed keys on each: `effect_specs`, `effect_summary` only;
- no classification, target, accuracy or unrelated move changed.

Notebook sync moves SHA. #72 requires second exact-head 18/18 before closure without merge.

# Audit frontier after #72 engineering
## User — 3 remaining stat/stateful cases
- `extreme_evoboost`: +2 all five stats but requires Eevee-specific Z-Move activation and is not an ordinary freely selectable modern move.
- `stockpile`: Def/SpDef +1 plus stored counter capped at three and Spit Up/Swallow dependency.
- `tidy_up`: Atk/Speed +1 plus field cleanup affecting hazards/substitutes.

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
