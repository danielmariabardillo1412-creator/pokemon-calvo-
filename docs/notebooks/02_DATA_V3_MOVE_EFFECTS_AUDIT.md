# DATA V3 / MOVE EFFECTS V3 AUDIT NOTEBOOK

## Purpose and invariant

DATA FOUNDATION V3 solved structural provenance/import problems, but a structurally valid move can still be semantically wrong at runtime. PokéAPI metadata is generic and sometimes versioned/conditional; the legacy converter can combine fields that do not share the same target or prerequisite.

Audit invariant:

> Every executable move effect must be faithful. If the current Battle Core cannot represent a mechanic, keep only a provably faithful subset (`PARTIAL_RUNTIME`) or remove executable effects (`DATA_ONLY`). Never keep a plausible but false effect.

Critical runtime fact: the executor consumes `effect_specs` without using the coverage label as a safety gate. Therefore a `DATA_ONLY` move with bad specs can still execute bad mechanics.

## Canonical source

Immutable DATA V3 source:

- branch `data/pokeapi-v2-snapshot`
- commit `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`
- `data/api/v2` + `data/schema/v2`
- source JSON is read-only

Current corrections belong in `tools/pokeapi_adapter.py`. Keep `tools/archive/pokeapi_adapter_v2_legacy.py` untouched as provenance.

## Certified pre-audit corrections

- PR #34 — contact override path — HEAD `cefd875cb227035c018400fac45106a09a4241a9` — 18/18, closed without merge.
- PR #37 — normalize legacy unsupported IDs and remove obsolete `astonish` placeholder — HEAD `1a54395cfedf0c8b63af3631a1560b8e38ab5ca5` — 18/18, closed without merge.

## Move Effects V3 certified chain

### PR #42 — healing target semantics

HEAD `cf60b8cc7431643219e260ad90d8dcb61ddad4e5`, 18/18.

- `Heal Pulse` → selected target heal, `RUNTIME_SUPPORTED`.
- `Floral Healing` → target heal represented, terrain dependency missing, `PARTIAL_RUNTIME`.
- `Life Dew` → SELF subset only, `PARTIAL_RUNTIME`.
- `Jungle Healing` → SELF heal + SELF status cure subset, `PARTIAL_RUNTIME`.

### PR #43 — simple self heals

HEAD `28d66f3a...`, 18/18.

`Recover`, `Soft-Boiled`, `Milk Drink`, `Slack Off` verified as exact 50% SELF heals → `RUNTIME_SUPPORTED`.

### PR #44 — weather heals

HEAD `7661e686...`, 18/18.

`Morning Sun`, `Synthesis`, `Moonlight`, `Shore Up`: neutral 50% heal represented; weather ratios absent → `PARTIAL_RUNTIME`.

### PR #45 — Roost

HEAD `5fe0b4d7...`, 18/18. SELF heal works; temporary Flying-type suppression absent → `PARTIAL_RUNTIME`.

### PR #46 — Heal Order

HEAD `bdfced6754d1a2683c4f9e9de139b34642af6314`, 18/18. Pure SELF 50% heal → `RUNTIME_SUPPORTED`.

### PR #47 — Rest

HEAD `a880f4dbec59244c3e21545a4a50ee6a7c949bac`, 18/18.

Kept `DATA_ONLY`, `effect_specs=[]`: current status replacement, Rest-specific sleep duration/failure semantics are not representable faithfully.

### PR #48 — Wish

HEAD `24176396b9b3c620ed2a2a6217042d703e5a590f`, 18/18.

Kept `DATA_ONLY`, `effect_specs=[]`: delayed persisted side-heal semantics absent; immediate heal would be false.

### PR #49 — Strength Sap

HEAD `2423066ebdf54e41b1bf2edfc5689d85492e0e92`, 18/18.

Opponent Attack -1 is faithful; heal equal to target's current Attack is not expressible → `PARTIAL_RUNTIME` with no guessed heal.

### PR #50 — simple self stat boosts A

HEAD `898db8a10005c66fc602d8d4d1d804aba6a5bf21`, 18/18.

Promoted after exact source/effect verification: Acid Armor, Agility, Amnesia, Barrier, Harden, Iron Defense.

### PR #51 — simple self stat boosts B

HEAD `24889d355e8d89f8873d2d958efb951080fd8027`, 18/18.

Promoted: Meditate, Nasty Plot, Rock Polish, Sharpen, Swords Dance, Tail Glow.

### PR #52 — persistent notebooks

HEAD `7ab2c1be78fab18309c6c4f4de9b2cf02ed96b46`, 18/18. Added `docs/notebooks/` continuity layer.

### PR #53 — simple self stat boosts C

Final HEAD `b3cfa577e01f45d57e0d73ebe662b84665d6f48e`, 18/18.

Promoted: Cotton Guard, Double Team, Withdraw. Explicitly excluded moves with extra semantics such as Autotomize, Charge, Defense Curl, Minimize, Stuff Cheeks, Aromatic Mist, Silk Trap.

### PR #54 — Silk Trap false SELF debuff

Final HEAD `c1f5e55c7d1d8acc991b3a6ddde906f10930bb67`, 18/18.

Legacy false output: `SELF Speed -1` because source-level `target=user` was incorrectly applied to a contact-triggered attacker debuff.

Fix: verify source + false legacy signature, remove executable spec, keep `DATA_ONLY`, `effect_specs=[]` until protection/contact-response targeting exists.

### PR #55 — Aromatic Mist false SELF buff

Final HEAD `844efde0eed27e1a5ca8790ae95a183fba6ba98c`, 18/18.

Source target is selected ally, SpDef +1. Legacy emitted `SELF SpDef +1`.

Fix: remove false executable effect; keep `DATA_ONLY`, effect-free until ally targeting exists.

### PR #56 — Stuff Cheeks unconditional Defense boost

Final HEAD `1c4217d5ebc6727982ef5d7b5b5b0667cea6c5b6`, 18/18.

Source requires held Berry, consumes it/triggers its effect, then raises Defense +2. Legacy emitted unconditional `SELF Defense +2`.

Fix: verify held-Berry contract and false legacy signature; remove executable effect; keep `DATA_ONLY`, effect-free until held-item prerequisite/consumption semantics exist.

Artifact after correction: 555 runtime / 66 partial / 286 data-only / 12 unsupported; 63 DATA_ONLY records still had specs.

### PR #57 — Howl user-and-allies target correction

Final HEAD `53e20600d372d44bc21eb145f598448a41828e5d`, 18/18, closed without merge.

Source:
- target `user-and-allies`
- Attack +1
- Sword/Shield and Scarlet/Violet explicitly say user + allies gain Attack.

Legacy false output: `OPPONENT Attack +1`.

Correct representation:
- preserve source target;
- executable subset exactly `SELF Attack +1`, 100%;
- `PARTIAL_RUNTIME` because ally subset is missing;
- independent regenerated-output assertion.

Artifact: 555 runtime / 67 partial / 285 data-only / 12 unsupported; 62 DATA_ONLY records still had specs.

### PR #58 — Coaching false OPPONENT buffs (CURRENT)

Branch `fix/data-v3-coaching-semantics`.
Parent: certified PR #57 final `53e20600d372d44bc21eb145f598448a41828e5d`.
Engineering SHA before notebook sync: `b7da56687d1e1e45072ca4572f5f0751f9d309d7`.
Engineering SHA: **18/18 SUCCESS**, including DATA V3, independent Coaching assertion, and Godot global.

Immutable source facts:
- move 811 `coaching`
- target `user-and-allies`
- Attack +1, Defense +1
- English effect text: raises the target's Attack/Defense and fails if no ally is adjacent to the user
- Scarlet/Violet flavor text describes coaching ally Pokémon

Legacy bug:
- generic target mapping produced `OPPONENT Attack +1` and `OPPONENT Defense +1`, both unconditional;
- runtime could therefore buff the rival despite `DATA_ONLY` classification.

Correct representation today:
- preserve source target `user-and-allies`;
- verify exact source stat package, adjacent-ally failure rule, current ally flavor text, and exact false legacy signature;
- remove both executable specs;
- keep `DATA_ONLY`, `effect_specs=[]` because current Battle Core has neither ally targeting nor adjacent-ally legality/failure semantics;
- independent DATA V3 regenerated-output assertion.

Exact PR #58 engineering artifact:
- `RUNTIME_SUPPORTED`: 555
- `PARTIAL_RUNTIME`: 67
- `DATA_ONLY`: 285
- `UNSUPPORTED`: 12
- remaining DATA_ONLY with non-empty specs: 61
- Coaching record: `target=user-and-allies`, `DATA_ONLY`, `effect_specs=[]`.

Notebook sync moves the SHA. **PR #58 must receive a second exact-head 18/18 certification before closure without merge.**

## Remaining high-risk families

### Remaining `user-and-allies` target records

After Howl and Coaching, two known high-risk records remain:

- `Gear Up`: generic output buffs OPPONENT; real semantics affect friendly Pokémon with Plus/Minus.
- `Magnetic Flux`: generic output buffs OPPONENT; real semantics affect friendly Pokémon with Plus/Minus.

Audit separately. Do not infer a SELF subset without proving the user is a legal recipient under the ability prerequisite.

### Selected-pokemon stat records

Examples include `baby_doll_eyes`, `charm`, `confide`, `decorate`, `defog`, `eerie_impulse`, `fake_tears`, `feather_dance`, `flash`, `kinesis`, `memento`, `metal_sound`, `noble_roar`, `parting_shot`, `play_nice`, `sand_attack`, `scary_face`, `screech`, `smokescreen`, `spicy_extract`, `tar_shot`, `tearful_look`, `tickle`.

Do not mass-promote: Defog, Memento, Parting Shot, Tar Shot, etc. carry extra mechanics.

### User-target stat records

Examples include `Autotomize`, `Bulk Up`, `Calm Mind`, `Charge`, `Clangorous Soul`, `Coil`, `Cosmic Power`, `Defend Order`, `Defense Curl`, `Dragon Dance`, `Extreme Evoboost`, `Fillet Away`, `Geomancy`, `Growth`, `Hone Claws`, `Minimize`, `No Retreat`, `Quiver Dance`, `Shell Smash`, `Shift Gear`, `Stockpile`, `Tidy Up`, `Work Up`.

Some are pure stat packages; others require costs, charging turns, weather, switching locks, counters, cleanup effects, weight changes, etc. Audit by small family.

### All-opponents / all-pokemon

All-opponents examples: `Captivate`, `Cotton Spore`, `Growl`, `Leer`, `String Shot`, `Sweet Scent`, `Tail Whip`, `Venom Drench`. Preserve conditions such as gender or poisoned-only.

All-pokemon examples: `Flower Shield`, `Rototiller`; current single-opponent effects cannot represent all-Pokémon + Grass-only semantics faithfully.

### Non-stat remaining DATA_ONLY with specs

- `Purify` — heal/status semantics not yet audited
- `Swallow` — heal depends on Stockpile state
- `Beat Up` — multi-hit depends on party composition/stats

## Battle Core limitations relevant to classification

Effect targets currently supported by importer/runtime are effectively SELF and OPPONENT. Missing/general limitations include:

- ally/team/side targeting
- delayed/persisted effects
- weather-conditioned heal ratios
- temporary type suppression
- protection/contact-response triggers
- held-item prerequisites/consumption transactions
- move-specific counters/state machines

`StatStages` supports Attack, Defense, Special Attack, Special Defense, Speed, Accuracy, Evasion.

## Audit protocol

1. Inspect immutable source semantics, including version-specific text when relevant.
2. Inspect exact generated record from latest certified DATA V3 artifact.
3. Confirm what Battle Core can represent faithfully.
4. Decide coverage from semantics, not convenience.
5. Add fail-fast adapter assertions.
6. Add independent regenerated-output assertion when effect shape/target/classification changes.
7. Keep scope tiny; never generalize from superficial similarity.
8. Run focal DATA V3.
9. Require 18/18 on engineering SHA.
10. Measure exact artifact.
11. Synchronize notebooks.
12. Require 18/18 again on final notebook-bearing SHA.
13. Close PR without merge.

Stop immediately on any failure; fix root cause before another family.
