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
- final DATA_ONLY executable-effects audit: `pokeapi_adapter_final_data_only_effects.py`
- archived V2 remains provenance-only.

## Certified recent heads
#63 `9f8b3e01bec1f86cff75380d68dd98d76e738e78`; #64 `674ccaf0928c93749c581565d53eb1f672dfd7b4`; #65 `b13af37c350156bc7a9a7d7faf63742245afd801`; #66 `51bc14155338e47c76926047845a958205005bdd`; #69 `7aaae1c600120442581fdd7c0c048b29e3ee5690`; #70 `4ee439a9741cc7dac8ec5d1792485ee79aa5f4b2`; #71 `98c68f1c184e84db30458a4533fb769cba1140ac`; #72 `d46be6864abd6e1cffdf54f9e932da06bed054dc`; #73 `67ba79e9a68a78669ee5ae04166a47ee11331bc7`; #74 `9a917fea11df07c3aa26c8962e2dca9784a41875`. All 18/18, closed without merge.

# PR #75 — final DATA_ONLY executable effects (CURRENT)
Branch `fix/data-v3-final-data-only-effects`; parent certified #74 final `9a917fea11df07c3aa26c8962e2dca9784a41875`; engineering SHA `db73a16b631f4e7bd539ac5e73b288401489d39a`; engineering CI **18/18 SUCCESS**.

## Purify
- immutable source: id 685, selected-pokemon, accuracy null, status, healing 50;
- source semantics: cure target major/non-volatile status, then heal user up to 50%; fail when target has no eligible status;
- legacy generated exact package: `HEAL SELF 5000 bp`;
- that package is unsafe because it removes the cure prerequisite and failure transaction.

Decision: `DATA_ONLY`, `effect_specs=[]`; canonical summary keeps prerequisite and conditional healing.

## Swallow
- immutable source: id 256, user, accuracy null, healing 25;
- source semantics: require Stockpile; level 1/2/3 heals 25%/50%/100%; consume Stockpile and remove associated defensive changes; fail at level 0;
- legacy generated exact package: `HEAL SELF 2500 bp`;
- flat unconditional 25% healing is not a faithful subset because it bypasses both prerequisite and consumption.

Decision: `DATA_ONLY`, `effect_specs=[]`; canonical summary keeps variable healing, prerequisite and consumption.

## Beat Up
- immutable source: id 251, selected-pokemon, physical, accuracy 100, power null;
- snapshot meta contains `min_hits=6`, `max_hits=6`, but source prose/effect history explicitly describes party participation;
- modern core-series behavior uses one strike for each conscious party member without a non-volatile status; from Generation V onward strike power is party-member-dependent rather than fixed generic six-hit damage;
- legacy generated exact package: `MULTI_HIT opponent 6..6` with no children;
- this is false whenever fewer than six party members are eligible and cannot represent the party-dependent damage transaction.

Decision: `DATA_ONLY`, `effect_specs=[]`; canonical summary records party eligibility and modern party-dependent semantics.

## Independent gate
Regenerated records must retain their source target/accuracy/classification, expose empty specs, and preserve the canonical summaries. The suite also asserts globally:

`count(DATA_ONLY where effect_specs != []) == 0`

## Exact #74 → #75 engineering artifact
Raw and normalized datasets both show exactly three changed move records:
- `beat_up`
- `purify`
- `swallow`

For each, the only changed keys are:
- `effect_specs`
- `effect_summary`

Coverage unchanged: **590 RUNTIME_SUPPORTED / 71 PARTIAL_RUNTIME / 246 DATA_ONLY / 12 UNSUPPORTED**.

DATA_ONLY with non-empty specs: **0**.

# Move Effects V3 status
**Executable-safety audit frontier CLOSED at engineering SHA.**

This does not mean all 919 move mechanics are implemented. It means the audited DATA V3 runtime exposure no longer leaves known `DATA_ONLY` moves with executable packages that contradict their required semantics.

Notebook sync moves SHA; #75 requires second exact-head 18/18 before closure without merge.

# Next data-reliability work after #75
Move to explicit **Ability runtime-support contracts** in a dedicated notebook/workstream. Preserve ability source data, distinguish metadata from implemented runtime mechanics, and fail closed on unsupported executable claims. Do not resume trainer AI/archetypes merely because Move Effects V3 is closed.
