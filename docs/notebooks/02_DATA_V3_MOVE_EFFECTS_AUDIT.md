# DATA V3 / MOVE EFFECTS V3 AUDIT NOTEBOOK

## Purpose / invariant
DATA FOUNDATION V3 solved structural provenance/import problems, but generic PokéAPI metadata can still create semantically false runtime effects.

> Every executable effect must be faithful. If Battle Core cannot represent a mechanic, preserve only a provably faithful subset (`PARTIAL_RUNTIME`) or remove executable effects (`DATA_ONLY`). Never retain a plausible but false effect.

Critical runtime fact: coverage classification is not an execution gate; `effect_specs` are consumed directly.

## Canonical source
- immutable branch `data/pokeapi-v2-snapshot`
- commit `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`
- paths `data/api/v2`, `data/schema/v2`
- current corrections live in `tools/pokeapi_adapter.py`
- archived V2 remains untouched at `tools/archive/pokeapi_adapter_v2_legacy.py`

## Certified correction chain
Pre-audit:
- #34 contact override path — `cefd875cb227035c018400fac45106a09a4241a9`
- #37 unsupported-ID normalization / Astonish correction — `1a54395cfedf0c8b63af3631a1560b8e38ab5ca5`

Move Effects V3:
- #42 healing targets — `cf60b8cc7431643219e260ad90d8dcb61ddad4e5`
- #43 Recover / Soft-Boiled / Milk Drink / Slack Off → RUNTIME_SUPPORTED
- #44 Morning Sun / Synthesis / Moonlight / Shore Up → PARTIAL_RUNTIME for weather ratios
- #45 Roost → PARTIAL_RUNTIME (temporary Flying suppression missing)
- #46 Heal Order → RUNTIME_SUPPORTED
- #47 Rest → DATA_ONLY effect-free
- #48 Wish → DATA_ONLY effect-free
- #49 Strength Sap → PARTIAL_RUNTIME
- #50 simple self boosts A
- #51 simple self boosts B
- #52 persistent notebooks baseline — `7ab2c1be78fab18309c6c4f4de9b2cf02ed96b46`
- #53 simple self boosts C — `b3cfa577e01f45d57e0d73ebe662b84665d6f48e`
- #54 Silk Trap — `c1f5e55c7d1d8acc991b3a6ddde906f10930bb67`
- #55 Aromatic Mist — `844efde0eed27e1a5ca8790ae95a183fba6ba98c`
- #56 Stuff Cheeks — `1c4217d5ebc6727982ef5d7b5b5b0667cea6c5b6`
- #57 Howl — `53e20600d372d44bc21eb145f598448a41828e5d`
- #58 Coaching — `3c4ac4d772a5869b45de592be7dd7f4d9b2a389b`
- #59 Gear Up — `ef7dd6a41b1cf4bccacf0a8d5098a755bb9fd3e9`
- #60 Magnetic Flux — `a5b56a0ba3a1efa81ac57be63b2813c19f2962a7`

All certified entries above passed 18/18 on exact final HEAD and were closed without merge.

## PR #61 — pure SELF stat packages A (CURRENT)
Branch `fix/data-v3-simple-self-stat-packages-a`.
Parent: certified #60 final `a5b56a0ba3a1efa81ac57be63b2813c19f2962a7`.
Engineering SHA before notebook sync: `f3927a99d4d21d711dec77d68e7526757691c47f`.
Engineering SHA passed **18/18**, including DATA V3, independent ten-move package assertion, and Godot global.

### Audited moves
Immutable source was checked individually before batching. Each of these has `target=user`, status category, no ailment/heal/drain/flinch/cost/condition/field/switch/delayed mechanic in the audited source contract, and exactly the listed stat package:

- Bulk Up: Attack +1, Defense +1
- Calm Mind: Special Attack +1, Special Defense +1
- Coil: Attack +1, Defense +1, Accuracy +1
- Cosmic Power: Defense +1, Special Defense +1
- Defend Order: Defense +1, Special Defense +1
- Dragon Dance: Attack +1, Speed +1
- Hone Claws: Attack +1, Accuracy +1
- Quiver Dance: Special Attack +1, Special Defense +1, Speed +1
- Shift Gear: Attack +1, Speed +2
- Work Up: Attack +1, Special Attack +1

The legacy generator already produced the correct complete SELF `modify_stat_stage` effects. PR #61 deliberately does **not** rewrite those specs. It adds an explicit `_PURE_SELF_STAT_PACKAGES` allowlist plus fail-fast validation of:
- target/category/ailment/metadata
- exact source stat dictionary
- exact generated effect count
- every effect kind/SELF target/100% chance
- exact generated stat dictionary

Only after all checks pass is coverage changed to `RUNTIME_SUPPORTED`.

Independent Godot DATA V3 test loops all ten regenerated records and verifies presence, source target, `RUNTIME_SUPPORTED`, effect count, SELF/stat-stage shape, 100% chance, and exact package.

### Exact engineering artifact
- `RUNTIME_SUPPORTED`: **565**
- `PARTIAL_RUNTIME`: **67**
- `DATA_ONLY`: **275**
- `UNSUPPORTED`: **12**
- DATA_ONLY with non-empty specs: **49**
- breakdown: **46 stat-change** + `Purify` + `Swallow` + `Beat Up`

Remaining stat-change target distribution:
- 23 `selected-pokemon`
- 13 `user`
- 8 `all-opponents`
- 2 `all-pokemon`

Notebook synchronization moves the SHA. #61 requires a second exact-head 18/18 before closure without merge.

## Remaining 46 stat-change DATA_ONLY records

### Remaining user-target cases — all require separate semantic treatment
`Autotomize`, `Charge`, `Clangorous Soul`, `Defense Curl`, `Extreme Evoboost`, `Fillet Away`, `Geomancy`, `Growth`, `Minimize`, `No Retreat`, `Shell Smash`, `Stockpile`, `Tidy Up`.

These are deliberately excluded from the clean package batch because one or more carries extra state/cost/field/version mechanics: weight change, Electric move charging, HP cost, Rollout interaction, Z-Move provenance, two-turn charge, sun scaling, Minimize-specific interactions, switching lock, Stockpile counter, hazard/substitute cleanup, etc. Do not mass-promote them.

### Selected-pokemon candidates — next likely batching area
23 records remain. Known names include:
`baby_doll_eyes`, `charm`, `confide`, `decorate`, `defog`, `eerie_impulse`, `fake_tears`, `feather_dance`, `flash`, `kinesis`, `memento`, `metal_sound`, `noble_roar`, `parting_shot`, `play_nice`, `sand_attack`, `scary_face`, `screech`, `smokescreen`, `spicy_extract`, `tar_shot`, `tearful_look`, `tickle`.

Do not mass-promote. Some may be exact opponent stat drops; others carry extra mechanics or even positive ally-target semantics (`decorate`). Regroup and verify source before editing.

### All-opponents / all-pokemon
- 8 all-opponents cases; conditions such as gender/poisoned-only matter.
- 2 all-pokemon cases; current SELF/OPPONENT model cannot generally express all-Pokémon + species/type predicates faithfully.

### Non-stat DATA_ONLY with specs
- `Purify` — heal/status interaction
- `Swallow` — Stockpile-dependent heal
- `Beat Up` — party-dependent multi-hit

## Battle Core limits
Effect targets effectively SELF/OPPONENT only. Missing/general features include ally/team/side targets, ability-filtered recipients, delayed effects, weather ratios, temporary type effects, protection/contact triggers, held-item transactions, and move-specific state machines.

## Audit protocol
1. Inspect immutable source semantics.
2. Inspect exact latest certified generated record.
3. Confirm what Battle Core can represent.
4. Choose coverage from semantics, not convenience.
5. Add fail-fast adapter assertions.
6. Add independent output assertion when shape/target/classification changes.
7. Batch only after proving source contracts are homogeneous.
8. Run focal DATA V3.
9. Require 18/18 engineering SHA.
10. Measure exact artifact.
11. Sync notebooks.
12. Require 18/18 final notebook-bearing SHA.
13. Close PR without merge.

Stop on any failure and fix root cause before continuing.
