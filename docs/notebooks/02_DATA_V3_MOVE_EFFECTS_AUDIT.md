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
- #47 Rest → DATA_ONLY effect-free (status replacement / Rest sleep semantics absent)
- #48 Wish → DATA_ONLY effect-free (delayed persisted heal absent)
- #49 Strength Sap → PARTIAL_RUNTIME (Attack -1 works; stat-derived heal missing)
- #50 simple self boosts A → Acid Armor, Agility, Amnesia, Barrier, Harden, Iron Defense
- #51 simple self boosts B → Meditate, Nasty Plot, Rock Polish, Sharpen, Swords Dance, Tail Glow
- #52 persistent notebooks baseline — `7ab2c1be78fab18309c6c4f4de9b2cf02ed96b46`
- #53 simple self boosts C → Cotton Guard, Double Team, Withdraw — final `b3cfa577e01f45d57e0d73ebe662b84665d6f48e`
- #54 Silk Trap false SELF Speed -1 removed — final `c1f5e55c7d1d8acc991b3a6ddde906f10930bb67`
- #55 Aromatic Mist false SELF ally buff removed — final `844efde0eed27e1a5ca8790ae95a183fba6ba98c`
- #56 Stuff Cheeks unconditional Defense +2 without held Berry removed — final `1c4217d5ebc6727982ef5d7b5b5b0667cea6c5b6`
- #57 Howl false OPPONENT Attack +1 → faithful SELF Attack +1 subset; PARTIAL_RUNTIME — final `53e20600d372d44bc21eb145f598448a41828e5d`
- #58 Coaching false OPPONENT Attack/Defense buffs removed — final `3c4ac4d772a5869b45de592be7dd7f4d9b2a389b`
- #59 Gear Up false OPPONENT Attack/SpAtk buffs removed — final `ef7dd6a41b1cf4bccacf0a8d5098a755bb9fd3e9`

All certified entries above passed 18/18 on exact final HEAD and were closed without merge.

## PR #60 — Magnetic Flux Plus/Minus target bug (CURRENT)
Branch `fix/data-v3-magnetic-flux-semantics`.
Parent: certified #59 final `ef7dd6a41b1cf4bccacf0a8d5098a755bb9fd3e9`.
Engineering SHA before notebook sync: `ee5380e27a0a3312c88c68fc8e476c14dac0a1a7`.
Engineering SHA passed **18/18**, including DATA V3, independent Magnetic Flux assertion, and Godot global.

Immutable source facts for move 602:
- `name=magnetic-flux`
- `target=user-and-allies`
- Defense +1, Special Defense +1
- English effect: raises Defense and Special Defense of all friendly Pokémon with Plus or Minus by one stage.

Legacy false output:
- `OPPONENT Defense +1`
- `OPPONENT Special Defense +1`

Why no SELF rewrite:
- recipient must satisfy Plus/Minus Ability predicate;
- current generic stat effect cannot select a friendly side with an Ability condition.

Fix:
- extend the already-certified Plus/Minus helper with an explicit Magnetic Flux stat package and move-specific source phrase;
- verify exact source metadata and exact false legacy signature fail-fast;
- remove both executable specs;
- keep `DATA_ONLY`, `effect_specs=[]`;
- independent regenerated-JSON assertion verifies target/classification/effect-free output.

Exact engineering artifact:
- RUNTIME_SUPPORTED 555
- PARTIAL_RUNTIME 67
- DATA_ONLY 285
- UNSUPPORTED 12
- DATA_ONLY with non-empty specs: **59**
- breakdown: **56 stat-change** + `Purify` + `Swallow` + `Beat Up`
- Magnetic Flux: `target=user-and-allies`, `DATA_ONLY`, `effect_specs=[]`.

Notebook synchronization moves the SHA. #60 requires a second exact-head 18/18 before closure without merge.

## Closed target-risk family
Known `user-and-allies` false-target cases are now audited:
- Howl: SELF subset retained correctly, ally subset missing → PARTIAL_RUNTIME.
- Coaching: ally-only + adjacency rule → DATA_ONLY effect-free.
- Gear Up: friendly Plus/Minus only → DATA_ONLY effect-free.
- Magnetic Flux: friendly Plus/Minus only → DATA_ONLY effect-free.

Do not assume all other targets are safe; this only closes this known family.

## Remaining 56 stat-change DATA_ONLY records
Before editing further, regroup from the exact #60 artifact by semantic family. Known buckets include:

### User-target candidates
`Autotomize`, `Bulk Up`, `Calm Mind`, `Charge`, `Clangorous Soul`, `Coil`, `Cosmic Power`, `Defend Order`, `Defense Curl`, `Dragon Dance`, `Extreme Evoboost`, `Fillet Away`, `Geomancy`, `Growth`, `Hone Claws`, `Minimize`, `No Retreat`, `Quiver Dance`, `Shell Smash`, `Shift Gear`, `Stockpile`, `Tidy Up`, `Work Up`.

Some may be pure stat packages. Others have extra mechanics: weight change, charge/electric boost, HP cost, delayed turn, weather dependency, switch lock, counters, cleanup, etc. Audit small families only.

### Selected-pokemon candidates
`baby_doll_eyes`, `charm`, `confide`, `decorate`, `defog`, `eerie_impulse`, `fake_tears`, `feather_dance`, `flash`, `kinesis`, `memento`, `metal_sound`, `noble_roar`, `parting_shot`, `play_nice`, `sand_attack`, `scary_face`, `screech`, `smokescreen`, `spicy_extract`, `tar_shot`, `tearful_look`, `tickle`.

Do not mass-promote; Defog, Memento, Parting Shot, Tar Shot and others carry extra semantics.

### All-opponents / all-pokemon
All-opponents examples: Captivate, Cotton Spore, Growl, Leer, String Shot, Sweet Scent, Tail Whip, Venom Drench. Conditions such as gender/poisoned-only matter.
All-pokemon examples: Flower Shield, Rototiller; current single-opponent targeting cannot represent all-Pokémon + Grass-only semantics faithfully.

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
7. Keep scope small.
8. Run focal DATA V3.
9. Require 18/18 engineering SHA.
10. Measure exact artifact.
11. Sync notebooks.
12. Require 18/18 final notebook-bearing SHA.
13. Close PR without merge.

Stop on any failure and fix root cause before continuing.
