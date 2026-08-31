# DATA V3 / MOVE EFFECTS V3 AUDIT NOTEBOOK

## Core invariant
Every executable `effect_spec` must be semantically faithful. Coverage labels do not gate execution. If an omitted mechanic is a mandatory cost, prerequisite, transaction, target predicate, delay, persistent state or strategic drawback, keep only a provably safe subset or remove executable effects.

## Source / audit chain
- immutable snapshot: `data/pokeapi-v2-snapshot` @ `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`
- canonical adapter: `tools/pokeapi_adapter_v3.py`
- compatibility: `tools/pokeapi_adapter.py`
- selected-stateful: `pokeapi_adapter_selected_stateful.py`
- all-opponents: `pokeapi_adapter_all_opponents.py`
- safe user-stateful: `pokeapi_adapter_user_stateful_safe.py`
- post-stat coordinator: `pokeapi_adapter_user_audit_chain.py` (compatibility name retained)
- HP-cost / mandatory-state / persistent-state / terminal-user modules
- all-pokemon: `pokeapi_adapter_all_pokemon.py`
- archived V2 remains provenance-only.

## Certified recent heads
#63 `9f8b3e01bec1f86cff75380d68dd98d76e738e78`; #64 `674ccaf0928c93749c581565d53eb1f672dfd7b4`; #65 `b13af37c350156bc7a9a7d7faf63742245afd801`; #66 `51bc14155338e47c76926047845a958205005bdd`; #69 `7aaae1c600120442581fdd7c0c048b29e3ee5690`; #70 `4ee439a9741cc7dac8ec5d1792485ee79aa5f4b2`; #71 `98c68f1c184e84db30458a4533fb769cba1140ac`; #72 `d46be6864abd6e1cffdf54f9e932da06bed054dc`; #73 `67ba79e9a68a78669ee5ae04166a47ee11331bc7`. All 18/18, closed without merge.

# PR #74 — all-pokemon stat semantics (CURRENT)
Branch `fix/data-v3-all-pokemon-semantics`; parent certified #73 final `67ba79e9a68a78669ee5ae04166a47ee11331bc7`; engineering SHA `99a435c291514612b5c1ce43ad2a28e47797c6c0`; engineering CI **18/18 SUCCESS**.

## Flower Shield
- immutable: target `all-pokemon`, accuracy null, Defense +1; English source says all Grass Pokémon in battle;
- current rules: eligible Grass-type Pokémon on field; fails if none; unavailable for selection in Gen IX;
- legacy generated unconditional `OPPONENT Defense +1`.

That target collapse is false: it can buff a non-Grass opponent and omit eligible user/allies. Current effect model lacks all-Pokémon fan-out/type predicate.
Decision: `DATA_ONLY`, `effect_specs=[]`; canonical summary normalized to eligibility/selectability semantics.

## Rototiller
- immutable: target `all-pokemon`, accuracy null, Attack +1 / SpAtk +1;
- current usable-generation rules: eligible **grounded** Grass-type Pokémon; fails if none; unavailable for selection Gen VIII+;
- legacy generated unconditional `OPPONENT Attack +1 / SpAtk +1`.

Decision: `DATA_ONLY`, `effect_specs=[]`; canonical summary normalized to grounded/type/selectability semantics.

## Independent gate
Both regenerated records must retain target `all-pokemon`, canonical accuracy `-1`, classification `DATA_ONLY`, empty specs and the canonical Grass eligibility summaries.

## Exact #74 engineering artifact
Coverage unchanged: **590 RUNTIME_SUPPORTED / 71 PARTIAL_RUNTIME / 246 DATA_ONLY / 12 UNSUPPORTED**.

Exact #73→#74 raw comparison:
- only `flower_shield`, `rototiller` changed;
- changed keys: `effect_specs`, `effect_summary` only;
- no classification, target, accuracy or unrelated record changed.

DATA_ONLY with non-empty specs: **3 only**:
- `Beat Up`
- `Purify`
- `Swallow`

**The stat-change DATA_ONLY-with-spec frontier is fully resolved.**

Notebook sync moves SHA; #74 requires second exact-head 18/18 before closure.

# Remaining Move Effects audit
1. `Purify`
2. `Swallow`
3. `Beat Up`

Use the same protocol: source → public current mechanics where needed → exact generated record → safety decision → fail-fast contract → independent output test → DATA V3 → 18/18 → artifact diff → notebooks → final 18/18 → close without merge.
