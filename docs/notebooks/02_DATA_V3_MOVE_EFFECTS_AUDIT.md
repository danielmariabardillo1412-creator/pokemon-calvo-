# DATA V3 / MOVE EFFECTS V3 AUDIT NOTEBOOK

## Why this audit exists

DATA FOUNDATION V3 fixed major structural data problems, but later auditing showed that a structurally valid move record can still be semantically wrong at runtime. Generic PokéAPI metadata does not always describe a move's complete battle behavior, and legacy classification rules were too coarse.

The audit goal is not to implement all Pokémon mechanics immediately. The goal is stricter:

> Every move used by runtime/AI must either have a faithful executable representation or be honestly classified as partial/data-only/unsupported. Never let a plausible but false effect masquerade as support.

## Certified pre-audit fixes

### Contact override path after repository reorganization

- Branch: `fix/data-v3-contact-override-path`
- HEAD: `cefd875cb227035c018400fac45106a09a4241a9`
- PR #34, closed without merge.
- 18/18 workflows passed.

Problem: V3 reused the archived V2 `_load_contact_override()`, whose path became wrong after archival. It silently returned an empty contact set. The V3 compatibility shim now owns loading `tools/move_flags_override.json`, fails closed, and verifies sentinels including `tackle` and `thunder_punch`.

### Legacy unsupported-name normalization

- Branch: `fix/data-v3-legacy-move-classification`
- HEAD: `1a54395cfedf0c8b63af3631a1560b8e38ab5ca5`
- PR #37, closed without merge.
- 18/18 workflows passed.

Fixes:

- Normalize legacy unsupported move names to underscore IDs.
- Correct escaped cases such as `sleep_talk`, `me_first`, `mirror_move`, `nature_power`.
- Remove obsolete `astonish` placeholder because damage + 30% flinch is representable.
- Add CI gates for contact and classification regressions.

This HEAD became the starting point for Move Effects V3.

## Move Effects V3 certified tranches

### PR #42 — healing target semantics

Certified target semantics for:

- `Heal Pulse`: target heal represented as OPPONENT; full runtime support for the current singles target model.
- `Floral Healing`: target heal represented, but Grassy Terrain dependency missing → `PARTIAL_RUNTIME`.
- `Life Dew`: self subset represented; ally-side healing missing → `PARTIAL_RUNTIME`.
- `Jungle Healing`: self heal + self status cure represented; ally-side behavior missing → `PARTIAL_RUNTIME`.

HEAD: `cf60b8cc7431643219e260ad90d8dcb61ddad4e5`
18/18 passed. PR closed without merge.

### PR #43 — simple self heals

Certified as `RUNTIME_SUPPORTED` with exactly one `HEAL SELF 50%`:

- `Recover`
- `Soft-Boiled`
- `Milk Drink`
- `Slack Off`

HEAD: `28d66f3a...`
18/18 passed. PR closed without merge.

### PR #44 — weather-dependent self heals

Moves:

- `Morning Sun`
- `Synthesis`
- `Moonlight`
- `Shore Up`

The neutral 50% self-heal is representable, but weather-specific ratios are not. Classified `PARTIAL_RUNTIME`; no fake weather mechanics added.

HEAD: `7661e686...`
18/18 passed. PR closed without merge.

### PR #45 — Roost

`Roost` has a representable 50% self-heal, but the temporary Flying-type suppression is not expressible by current `BattleEffectSpec`.

Classification: `PARTIAL_RUNTIME`.

HEAD: `5fe0b4d7...`
18/18 passed. PR closed without merge.

### PR #46 — Heal Order

`Heal Order` verified as a pure 50% self-heal and promoted to `RUNTIME_SUPPORTED`.

HEAD: `bdfced6754d1a2683c4f9e9de139b34642af6314`
18/18 passed. PR closed without merge.

### PR #47 — Rest

`Rest` was deliberately kept `DATA_ONLY` with empty `effect_specs`.

Why not implement it as `SLEEP SELF + HEAL 100%`:

- Current persistent-status logic rejects applying sleep over an existing persistent status.
- Generic sleep duration is 1–3 turns.
- Rest requires move-specific status replacement, sleep duration, failure conditions, and full-heal semantics.

A generic approximation would look plausible but be wrong. The no-op is intentional and protected by fail-fast gates.

HEAD: `a880f4dbec59244c3e21545a4a50ee6a7c949bac`
18/18 passed. PR closed without merge.

### PR #48 — Wish

`Wish` kept `DATA_ONLY` with empty `effect_specs`.

Reason: the actual heal is delayed until the end of the following turn and can apply to a replacement after switching. Current `BattleEffectSpec` has no delayed-heal effect and `BattleState` has no persisted pending-effect queue/side slot for this mechanic.

An immediate `HEAL SELF` would be false.

HEAD: `24176396b9b3c620ed2a2a6217042d703e5a590f`
18/18 passed. PR closed without merge.

### PR #49 — Strength Sap

`Strength Sap` has a faithful representable subset:

- Opponent Attack -1: representable and executable.
- Heal equal to the target's current Attack value: not expressible by current fixed/ratio heal model.

Classification corrected from `DATA_ONLY` to `PARTIAL_RUNTIME`. Gate requires exactly the real Attack drop and forbids a guessed heal.

HEAD: `2423066ebdf54e41b1bf2edfc5689d85492e0e92`
18/18 passed. PR closed without merge.

### PR #50 — simple self stat boosts A

Promoted to `RUNTIME_SUPPORTED`, with exact source/effect contracts:

- `Acid Armor`: Defense +2
- `Agility`: Speed +2
- `Amnesia`: Special Defense +2
- `Barrier`: Defense +2
- `Harden`: Defense +1
- `Iron Defense`: Defense +2

Each must remain a user-targeted status move with exactly one unconditional self stat-stage effect and no hidden generated effect.

HEAD: `898db8a10005c66fc602d8d4d1d804aba6a5bf21`
18/18 passed. PR closed without merge.

### PR #51 — simple self stat boosts B

Promoted to `RUNTIME_SUPPORTED` using the same already-certified contract:

- `Meditate`: Attack +1
- `Nasty Plot`: Special Attack +2
- `Rock Polish`: Speed +2
- `Sharpen`: Attack +1
- `Swords Dance`: Attack +2
- `Tail Glow`: Special Attack +3

HEAD: `24889d355e8d89f8873d2d958efb951080fd8027`
18/18 passed. PR closed without merge.

### PR #52 — persistent project notebooks

Operational continuity notebooks were added under `docs/notebooks/` so another chat/context can recover the certified state without relying on conversation history.

- Branch: `docs/project-notebooks-v1`
- HEAD: `7ab2c1be78fab18309c6c4f4de9b2cf02ed96b46`
- 18/18 passed.
- PR closed without merge.

All subsequent tranches descend from this notebook-bearing branch chain.

### PR #53 — simple self stat boosts C

Promoted through the already-certified pure-self-boost contract:

- `Cotton Guard`: Defense +3
- `Double Team`: Evasion +1
- `Withdraw`: Defense +1

Deliberately excluded due to extra mechanics/targeting: `Autotomize`, `Charge`, `Defense Curl`, `Minimize`, `Stuff Cheeks`, `Aromatic Mist`, `Silk Trap`.

Final HEAD: `b3cfa577e01f45d57e0d73ebe662b84665d6f48e`.
18/18 passed on that exact notebook-bearing HEAD. PR closed without merge.

### PR #54 — Silk Trap false self-debuff

This tranche found an **active semantic runtime bug**, not just a coverage-label problem.

Immutable snapshot facts for move 852 (`silk-trap`):

- `target = user` because Silk Trap protects the user.
- priority = +4.
- `stat_changes = Speed -1`.
- flavor text states that an attacker making direct contact has its Speed lowered.

The legacy generic converter combined `target=user` with the independent stat change and emitted:

`MODIFY_STAT_STAGE target=SELF stat=speed value=-1`

Because runtime executes `effect_specs` regardless of DATA_ONLY classification, using Silk Trap could incorrectly slow the **user itself**.

Fix:

- Validate the exact source signature and the legacy false-self-debuff signature fail-fast.
- Remove the false runtime effect.
- Keep `Silk Trap` as `DATA_ONLY` with `effect_specs=[]` until protection + contact-trigger + attacker-target semantics exist.
- Add an independent DATA V3 domain test against regenerated raw JSON.

Final HEAD: `c1f5e55c7d1d8acc991b3a6ddde906f10930bb67`.
18/18 passed on that exact notebook-bearing HEAD. PR closed without merge.

### PR #55 — Aromatic Mist false self-buff

This tranche found another **active target-semantics bug**.

Immutable snapshot facts for move 597 (`aromatic-mist`):

- `target = ally`.
- Status move, power 0.
- `stat_changes = Special Defense +1`.
- Source effect text explicitly says it raises a **selected ally's** Special Defense by one stage.

The legacy generic converter cannot represent ally targeting and emitted:

`MODIFY_STAT_STAGE target=SELF stat=special_defense value=+1`

Because `effect_specs` execute regardless of DATA_ONLY classification, this could buff the user instead of the selected ally.

Fix:

- Fail-fast verify the exact ally-targeted source contract and the legacy false-SELF signature.
- Remove the false executable effect.
- Keep `Aromatic Mist` as `DATA_ONLY` with `effect_specs=[]` until the battle target model supports allies.
- Add an independent DATA V3 domain test requiring the regenerated raw record to remain present, `target=ally`, `classification=DATA_ONLY`, and effect-free.

Engineering SHA before notebook synchronization: `7ae7d5c8f20c555e03411e3baacdbd2de1084f1c`.
That SHA passed 18/18 workflows. The final exact notebook-bearing HEAD for PR #55 must be read from GitHub after the required second 18/18 certification before closure.

## Current artifact metrics from PR #55 engineering SHA

- `RUNTIME_SUPPORTED`: 555
- `PARTIAL_RUNTIME`: 66
- `DATA_ONLY`: 286
- `UNSUPPORTED`: 12

Remaining `DATA_ONLY` moves that nevertheless contain `effect_specs`: 64.

Breakdown:

- 61 records with stat-change effects.
- 2 heal cases: `Purify`, `Swallow`.
- 1 multi-hit case: `Beat Up`.

The count should shrink only through audited semantic tranches, not mass relabeling.

## Known semantic families / traps already identified

- Targeted heal vs self heal.
- User-and-allies targeting unsupported by SELF/OPPONENT-only effect targets.
- Explicit ally targeting (`Aromatic Mist`): never collapse to SELF/OPPONENT silently.
- Weather-conditioned healing ratios.
- Temporary type suppression (`Roost`).
- Persistent status replacement and move-specific sleep (`Rest`).
- Delayed/persisted effects (`Wish`).
- Heal amount derived from opponent stat (`Strength Sap`).
- Pure self stat boosts: safe only after verifying no hidden extra mechanic.
- Protection/contact-trigger effects (`Silk Trap`): source-level `target=user` must not be blindly applied to conditional stat changes on an attacker.
- `Stockpile`, `Charge`, `Minimize`, `No Retreat`, etc. must **not** be assumed equivalent to pure stat boosts; they may carry additional state/mechanics.
- `Purify`, `Swallow`, and `Beat Up` require separate semantic audits.

## Audit rule

For every family:

1. Inspect immutable source semantics.
2. Inspect current generated `effect_specs` from an exact certified DATA V3 artifact.
3. Confirm Battle Core can execute the represented mechanics faithfully.
4. Add explicit adapter fail-fast assertions.
5. Add independent output invariants when the effect shape/target is being changed; pure extensions of an already-certified table may reuse its fail-fast contract while still passing the complete DATA V3 regeneration/import/runtime workflow.
6. Run focal DATA V3.
7. Run/confirm all 18 workflows on the exact same engineering HEAD.
8. Synchronize the notebooks when the tranche changes project state; this creates a new HEAD and therefore requires another exact-head 18/18 certification before closure.
9. Close PR without merge after final certification.
