# DATA V3 / MOVE EFFECTS V3 AUDIT NOTEBOOK

## Purpose and invariant

DATA FOUNDATION V3 solved structural provenance/import problems, but a structurally valid move can still be semantically wrong at runtime. PokéAPI metadata is generic and sometimes versioned/conditional; the legacy converter can combine fields that do not share the same target or prerequisite.

Audit invariant:

> Every executable move effect must be faithful. If the current Battle Core cannot represent a mechanic, keep only a provably faithful subset (`PARTIAL_RUNTIME`) or remove executable effects (`DATA_ONLY`). Never keep a plausible but false effect.

Critical runtime fact: `BattleEffectRegistry` / executor consumes `effect_specs` without using the coverage label as a safety gate. Therefore a `DATA_ONLY` move with bad specs can still execute bad mechanics.

## Canonical source

Immutable DATA V3 source:

- branch `data/pokeapi-v2-snapshot`
- commit `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`
- `data/api/v2` + `data/schema/v2`
- source JSON is read-only

Current corrections belong in `tools/pokeapi_adapter.py`. Do not edit `tools/archive/pokeapi_adapter_v2_legacy.py` except as historical provenance (current policy: leave archived V2 untouched).

## Certified pre-audit corrections

### PR #34 — contact override path

- HEAD `cefd875cb227035c018400fac45106a09a4241a9`
- 18/18 SUCCESS, closed without merge
- Re-homed contact override loading in V3 shim after repository reorganization.
- Fails closed and verifies sentinels such as `tackle` / `thunder_punch`.

### PR #37 — legacy unsupported-name normalization

- HEAD `1a54395cfedf0c8b63af3631a1560b8e38ab5ca5`
- 18/18 SUCCESS, closed without merge
- Normalized hyphenated legacy unsupported IDs (`sleep_talk`, `me_first`, `mirror_move`, `nature_power`).
- Removed obsolete `astonish` unsupported placeholder; damage + 30% flinch is representable.

This became the starting certified baseline for Move Effects V3.

## Move Effects V3 certified tranches

### PR #42 — healing target semantics

HEAD `cf60b8cc7431643219e260ad90d8dcb61ddad4e5`, 18/18, closed without merge.

- `Heal Pulse`: selected-target heal corrected; fully representable in current single-target model → `RUNTIME_SUPPORTED`.
- `Floral Healing`: target heal represented; Grassy Terrain dependency missing → `PARTIAL_RUNTIME`.
- `Life Dew`: SELF subset represented; ally-side healing missing → `PARTIAL_RUNTIME`.
- `Jungle Healing`: SELF heal + SELF status cure represented; ally-side behavior missing → `PARTIAL_RUNTIME`.

### PR #43 — simple self heals

HEAD `28d66f3a...`, 18/18, closed without merge.

Verified exact `HEAL SELF 50%`, no hidden battle mechanic:
`Recover`, `Soft-Boiled`, `Milk Drink`, `Slack Off` → `RUNTIME_SUPPORTED`.

### PR #44 — weather-dependent heals

HEAD `7661e686...`, 18/18, closed without merge.

`Morning Sun`, `Synthesis`, `Moonlight`, `Shore Up`: neutral 50% SELF heal is representable; weather ratios are not → `PARTIAL_RUNTIME`.

### PR #45 — Roost

HEAD `5fe0b4d7...`, 18/18, closed without merge.

- SELF heal 50% represented.
- Temporary Flying-type suppression absent.
- `PARTIAL_RUNTIME`.

### PR #46 — Heal Order

HEAD `bdfced6754d1a2683c4f9e9de139b34642af6314`, 18/18, closed without merge.

Pure SELF 50% heal → `RUNTIME_SUPPORTED`.

### PR #47 — Rest

HEAD `a880f4dbec59244c3e21545a4a50ee6a7c949bac`, 18/18, closed without merge.

Kept `DATA_ONLY`, `effect_specs=[]` because a guessed `SLEEP SELF + HEAL 100%` would be wrong:
- current persistent-status system will not replace an existing status as Rest must;
- generic sleep duration differs from Rest-specific semantics;
- failure/status replacement details are absent.

### PR #48 — Wish

HEAD `24176396b9b3c620ed2a2a6217042d703e5a590f`, 18/18, closed without merge.

Kept `DATA_ONLY`, `effect_specs=[]`: delayed heal / persisted side-slot semantics are absent. Immediate heal would be false.

### PR #49 — Strength Sap

HEAD `2423066ebdf54e41b1bf2edfc5689d85492e0e92`, 18/18, closed without merge.

- Opponent Attack -1 is faithful and executable.
- Heal equal to target's current Attack is not expressible by fixed/ratio HEAL.
- Corrected to `PARTIAL_RUNTIME`; gate forbids guessed heal.

### PR #50 — simple self stat boosts A

HEAD `898db8a10005c66fc602d8d4d1d804aba6a5bf21`, 18/18, closed without merge.

Promoted after exact source/effect verification:
- Acid Armor Def +2
- Agility Speed +2
- Amnesia SpDef +2
- Barrier Def +2
- Harden Def +1
- Iron Defense Def +2

### PR #51 — simple self stat boosts B

HEAD `24889d355e8d89f8873d2d958efb951080fd8027`, 18/18, closed without merge.

Promoted:
- Meditate Atk +1
- Nasty Plot SpAtk +2
- Rock Polish Speed +2
- Sharpen Atk +1
- Swords Dance Atk +2
- Tail Glow SpAtk +3

### PR #52 — persistent notebooks

HEAD `7ab2c1be78fab18309c6c4f4de9b2cf02ed96b46`, 18/18, closed without merge.

Created `docs/notebooks/` continuity layer. All later tranches descend from notebook-bearing snapshots.

### PR #53 — simple self stat boosts C

Final HEAD `b3cfa577e01f45d57e0d73ebe662b84665d6f48e`, 18/18, closed without merge.

Promoted:
- Cotton Guard Def +3
- Double Team Evasion +1
- Withdraw Def +1

Explicitly excluded from pure batches because they have extra semantics: `Autotomize`, `Charge`, `Defense Curl`, `Minimize`, `Stuff Cheeks`, `Aromatic Mist`, `Silk Trap`.

### PR #54 — Silk Trap false SELF debuff

Final HEAD `c1f5e55c7d1d8acc991b3a6ddde906f10930bb67`, 18/18, closed without merge.

Source:
- `target=user` because the move protects the user.
- stat metadata contains Speed -1, but real recipient is an attacker that makes direct contact.

Legacy false output:
`SELF Speed -1`

Fix:
- fail-fast source + legacy signature;
- remove executable spec;
- keep `DATA_ONLY`, `effect_specs=[]` until protection/contact-trigger/attacker targeting exists;
- independent DATA V3 regenerated-JSON assertion.

### PR #55 — Aromatic Mist false SELF buff

Final HEAD `844efde0eed27e1a5ca8790ae95a183fba6ba98c`, 18/18, closed without merge.

Source: `target=ally`, selected ally SpDef +1.
Legacy false output: `SELF SpDef +1`.

Fix:
- fail-fast ally source + false SELF signature;
- remove executable effect;
- `DATA_ONLY`, `effect_specs=[]` until ally target exists;
- independent regenerated-output assertion.

### PR #56 — Stuff Cheeks unconditional Defense boost

Final HEAD `1c4217d5ebc6727982ef5d7b5b5b0667cea6c5b6`, 18/18, closed without merge.

Source move 747:
- target user
- Defense +2
- cannot be used without held Berry
- Berry must be consumed / its effect triggered before the boost

Legacy false output: unconditional `SELF Defense +2`.

Fix:
- fail-fast target/category/stat metadata plus held-Berry prerequisite/consumption text;
- verify legacy false unconditional signature;
- remove executable effect;
- keep `DATA_ONLY`, `effect_specs=[]` until held-item prerequisite/consumption transaction is representable;
- independent regenerated-output assertion.

Exact PR #56 artifact after correction:
- RUNTIME_SUPPORTED 555
- PARTIAL_RUNTIME 66
- DATA_ONLY 286
- UNSUPPORTED 12
- 63 DATA_ONLY records still had non-empty specs.

### PR #57 — Howl user-and-allies target correction (CURRENT)

Branch `fix/data-v3-howl-target-semantics`.
Parent: certified PR #56 final `1c4217d5ebc6727982ef5d7b5b5b0667cea6c5b6`.
Engineering SHA before notebook sync: `fc118cb3a06d3f1724b65aac5ba5c8893d0ea83b`.
Engineering SHA: **18/18 SUCCESS** including DATA V3 + independent Howl assertion + Godot global.

Source facts:
- move 336 `howl`
- target `user-and-allies`
- Attack +1
- Sword/Shield text: user raises spirit of itself and allies; their Attack rises
- Scarlet/Violet text: user rouses itself and allies; their Attack rises

Legacy bug:
- `user-and-allies` was not included in legacy `self_target` detection;
- generated output was `OPPONENT Attack +1`;
- because specs execute despite DATA_ONLY label, Howl could buff the rival.

Correct representation today:
- preserve source target `user-and-allies`;
- rewrite executable spec to exactly `SELF Attack +1`, 100% chance;
- set `PARTIAL_RUNTIME` because SELF subset is faithful but ally subset is missing;
- independent DATA V3 assertion checks target, classification, effect count, effect kind, SELF target, Attack +1, and 100% chance.

Exact PR #57 engineering artifact:
- `RUNTIME_SUPPORTED`: 555
- `PARTIAL_RUNTIME`: 67
- `DATA_ONLY`: 285
- `UNSUPPORTED`: 12
- remaining DATA_ONLY with non-empty specs: 62
- Howl record: `target=user-and-allies`, `PARTIAL_RUNTIME`, one `SELF Attack +1` effect.

Notebook sync moves the SHA. **PR #57 must receive a second exact-head 18/18 certification before closure without merge.**

## Remaining high-risk families

### `user-and-allies` target records

PR #56 artifact exposed four such DATA_ONLY records whose generic stat effects targeted OPPONENT. Howl is now corrected separately. Remaining:

- `Coaching`: real semantics involve an adjacent ally and failure if no legal adjacent ally; do not blindly rewrite to SELF.
- `Gear Up`: real semantics apply to friendly Pokémon with Plus/Minus; do not blindly rewrite to SELF.
- `Magnetic Flux`: real semantics apply to friendly Pokémon with Plus/Minus; do not blindly rewrite to SELF.

Audit each separately.

### Selected-pokemon stat records

Known remaining examples include `baby_doll_eyes`, `charm`, `confide`, `decorate`, `defog`, `eerie_impulse`, `fake_tears`, `feather_dance`, `flash`, `kinesis`, `memento`, `metal_sound`, `noble_roar`, `parting_shot`, `play_nice`, `sand_attack`, `scary_face`, `screech`, `smokescreen`, `spicy_extract`, `tar_shot`, `tearful_look`, `tickle`.

Do not mass-promote: several carry extra mechanics (Defog field removal, Memento self-faint, Parting Shot switching, Tar Shot Fire interaction, etc.).

### User-target stat records

Known cases include `Autotomize`, `Bulk Up`, `Calm Mind`, `Charge`, `Clangorous Soul`, `Coil`, `Cosmic Power`, `Defend Order`, `Defense Curl`, `Dragon Dance`, `Extreme Evoboost`, `Fillet Away`, `Geomancy`, `Growth`, `Hone Claws`, `Minimize`, `No Retreat`, `Quiver Dance`, `Shell Smash`, `Shift Gear`, `Stockpile`, `Tidy Up`, `Work Up`.

Some are pure stat packages; others require weight changes, costs, charging turns, weather, switching locks, stored counters, cleanup effects, etc. Audit by small semantic family.

### All-opponents / all-pokemon

All-opponents examples: `Captivate`, `Cotton Spore`, `Growl`, `Leer`, `String Shot`, `Sweet Scent`, `Tail Whip`, `Venom Drench`. Conditions like gender or poisoned-only must be preserved.

All-pokemon examples: `Flower Shield`, `Rototiller`; current generic single-opponent effects cannot represent all-Pokémon + Grass-only semantics faithfully.

### Non-stat remaining DATA_ONLY with specs

- `Purify` — heal/status semantics not yet audited
- `Swallow` — heal amount depends on Stockpile state
- `Beat Up` — multi-hit semantics depend on party composition/stats

Handle separately.

## Battle Core limitations relevant to classification

Effect targets currently supported by the importer/runtime are effectively SELF and OPPONENT. Missing/general limitations include:

- ally/team/side targeting
- delayed/persisted effects
- weather-conditioned heal ratios
- temporary type suppression
- protection/contact-response triggers
- held-item prerequisites/consumption transactions
- move-specific counters/state machines

`StatStages` supports Attack, Defense, Special Attack, Special Defense, Speed, Accuracy, Evasion.

## Audit protocol

For every microfamily:

1. Inspect immutable source semantics, including version-specific flavor/effect data when relevant.
2. Inspect exact generated record from the latest certified DATA V3 artifact.
3. Confirm what Battle Core can represent faithfully.
4. Decide `RUNTIME_SUPPORTED`, `PARTIAL_RUNTIME`, `DATA_ONLY`, or `UNSUPPORTED` from semantics, not convenience.
5. Add fail-fast adapter assertions.
6. Add independent regenerated-output assertion when effect shape/target/classification changes.
7. Keep scope tiny; never generalize one move's rule to superficially similar moves without source verification.
8. Run focal DATA V3.
9. Require 18/18 on the engineering SHA.
10. Measure the exact artifact instead of estimating counts.
11. Synchronize notebooks.
12. Require 18/18 again on the final notebook-bearing SHA.
13. Close PR without merge.

Stop immediately on any failure; fix root cause before another family.
