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
- user coordinator: `tools/pokeapi_adapter_user_audit_chain.py`
- HP-cost user: `tools/pokeapi_adapter_user_hp_cost.py`
- mandatory-state user: `tools/pokeapi_adapter_user_mandatory_state.py`
- persistent-state user: `tools/pokeapi_adapter_user_persistent_state.py`
- terminal-state user: `tools/pokeapi_adapter_user_terminal_state.py`
- archived V2 remains provenance-only.

## Certified recent heads
- #63 accuracy — `9f8b3e01bec1f86cff75380d68dd98d76e738e78`
- #64 selected special stats — `674ccaf0928c93749c581565d53eb1f672dfd7b4`
- #65 selected stateful — `b13af37c350156bc7a9a7d7faf63742245afd801`
- #66 all-opponents — `51bc14155338e47c76926047845a958205005bdd`
- #69 safe user-stateful — `7aaae1c600120442581fdd7c0c048b29e3ee5690`
- #70 reconciled user chain — `4ee439a9741cc7dac8ec5d1792485ee79aa5f4b2`
- #71 mandatory-state user — `98c68f1c184e84db30458a4533fb769cba1140ac`
- #72 persistent-state user — `d46be6864abd6e1cffdf54f9e932da06bed054dc`
All certified 18/18 and closed without merge.

# PR #73 — terminal user-state audit (CURRENT)
Branch `fix/data-v3-user-terminal-state-d`.
Parent: certified #72 final `d46be6864abd6e1cffdf54f9e932da06bed054dc`.
Engineering SHA before notebook sync: `51f0a15bf980befc2fdb2393dd8b516a2f53eaed`.
Engineering SHA: **18/18 SUCCESS**.

## Extreme Evoboost
Immutable snapshot:
- target `user`, source accuracy null → canonical `-1`;
- PP 1, Generation VII;
- Attack/Defense/SpAtk/SpDef/Speed +2.

Current core-series contract checked publicly:
- Eevee-exclusive Z-Move derived from Last Resort;
- not an ordinary freely selectable move from Generation VIII onward.

Generated pre-#73 package: five deterministic SELF +2 stat effects.
Why unsafe: the runtime would expose the reward as a normal move while omitting the Z-Move/Eevee activation transaction and modern selectability restriction.
Decision: remain `DATA_ONLY`, `effect_specs=[]`.
Canonical derived summary is normalized to retain Z-Move/selectability semantics; immutable source is untouched.

## Stockpile
Immutable snapshot:
- target `user`, source accuracy null → canonical `-1`;
- Defense +1, SpDef +1;
- English effect explicitly records stored energy, max three levels, Spit Up/Swallow coupling and loss on leaving the field.

Generated pre-#73 package: deterministic SELF Defense +1 and SpDef +1.
Why unsafe: without the capped Stockpile counter and consumption/loss transaction, the stat package can be repeated and retained under semantics the real move does not allow.
Decision: remain `DATA_ONLY`, `effect_specs=[]`.
Canonical short summary is normalized to record max-three counter and associated boost consumption.

## Tidy Up
Immutable snapshot:
- target `user`, accuracy null → canonical `-1`;
- Generation IX, PP 10, Attack +1, Speed +1;
- generic `effect_entries` and `meta` absent; Scarlet/Violet flavor text carries current semantics.

Current mechanic checked publicly and against source flavor:
- Attack +1 / Speed +1;
- removes Spikes, Toxic Spikes, Stealth Rock, Sticky Web and Substitute from both sides.

Generated pre-#73 package: deterministic SELF Attack +1 / Speed +1 only.
Why unsafe: omitting bilateral cleanup can retain favorable hazards on the opponent's side, creating a stronger fake move.
Decision: remain `DATA_ONLY`, `effect_specs=[]`.
Canonical English summary is synthesized in-memory from source/current mechanics; immutable source remains untouched.

## Independent #73 output gate
For all three regenerated records:
- target `user`;
- canonical accuracy `-1`;
- classification `DATA_ONLY`;
- `effect_specs=[]`.

Summary assertions additionally require:
- Extreme Evoboost: exclusive Z-Move / five stats / Generation VIII selectability language;
- Stockpile: maximum three / Spit Up / Swallow / associated boosts;
- Tidy Up: Attack+Speed / hazards / Substitute / both sides.

## Exact #73 engineering artifact
Coverage unchanged:
- `RUNTIME_SUPPORTED`: **590**
- `PARTIAL_RUNTIME`: **71**
- `DATA_ONLY`: **246**
- `UNSUPPORTED`: **12**

DATA_ONLY with non-empty specs: **5** only:
- `flower_shield`
- `rototiller`
- `beat_up`
- `purify`
- `swallow`

There are **zero remaining target=user DATA_ONLY stat-spec records**.

Exact #72→#73 raw comparison:
- changed records exactly `extreme_evoboost`, `stockpile`, `tidy_up`;
- changed keys exactly `effect_specs`, `effect_summary` on each;
- no classification, target, accuracy or unrelated record changed.

Notebook sync moves SHA. #73 requires second exact-head 18/18 before closure without merge.

# Audit frontier after #73 engineering
## All-pokemon stat cases — 2
- `flower_shield`
- `rototiller`
Current SELF/OPPONENT-only effect model cannot directly express all-Pokémon/type predicates. Audit source/current mechanics before editing.

## Non-stat cases — 3
- `Purify`
- `Swallow`
- `Beat Up`

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
