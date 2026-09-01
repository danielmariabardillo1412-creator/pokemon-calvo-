# NEXT STEPS — LIVE CHECKPOINT

Read immediately after `00_READ_FIRST.md` when recovering context.

## Latest certified baseline
- PR #87 — `audit/data-v3-ability-offensive-stat-conditions-v1`
- Final HEAD `6fc1f73be1b24cba0c8052549ab4ea5f1e96c976`
- **18/18 SUCCESS** on exact notebook-bearing HEAD
- closed without merge.

Move Effects V3 remains closed:
- **590 runtime / 71 partial / 246 data-only / 12 unsupported**;
- `DATA_ONLY` moves with executable `effect_specs`: **0**.

Certified #87 ability coverage:
- `RUNTIME_SUPPORTED`: **18**
- `PARTIAL_RUNTIME`: **12**
- `DATA_ONLY`: **343**
- total: **373**.

Prior detailed ability notebooks: `06` through `17`.

# Current tranche — PR #88
- Branch: `audit/data-v3-ability-existing-primitives-v1`
- Parent: certified #87 final `6fc1f73be1b24cba0c8052549ab4ea5f1e96c976`
- PR: #88 `DATA V3 — isolate damage modifier roles and audit compound abilities`
- Engineering SHA: `15543135b42254c8d475db9d3eeb36503a674b6c`
- Engineering SHA: **18/18 SUCCESS**
- DATA V3 domain: **499 PASS / 0 FAIL**
- Detailed notebook: `docs/notebooks/18_DATA_V3_ABILITY_EXISTING_PRIMITIVES.md`.

## #88 root result — damage roles fixed
A pre-existing `BattleTriggerSystem.damage_modifiers()` bug let ability damage modifiers be evaluated from both sides because registry specs had no directional contract.

Now every ability `MODIFY_DAMAGE` spec must declare:
- `damage_role = actor` for outgoing/offensive behavior; or
- `damage_role = target` for incoming/defensive behavior or immunity.

A missing role is fail-safe inert.

All existing ability damage modifiers were tagged. Real-battle regressions prove:
- low-HP defender Blaze no longer amplifies incoming Fire damage;
- attacker Fur Coat no longer reduces its own outgoing physical damage.

This correctness fix is the required foundation for Water Bubble's opposite-direction effects.

## #88 ability decisions
### Water Bubble → PARTIAL_RUNTIME
Faithful subset:
- outgoing Water x2 (`actor`, `multiplier_bp=20000`);
- incoming Fire x0.5 (`target`, `multiplier_bp=5000`).

Explicit gap:
- burn prevention / immediate cure.

Tests also pin no cross-role leakage: holder's own Fire attack is not halved, and incoming Water is not doubled.

### Dry Skin → PARTIAL_RUNTIME
Faithful subset:
- incoming Fire x1.25 (`target`, `multiplier_bp=12500`).

Explicit gaps:
- sun damage;
- rain heal;
- Water absorption + 1/4 max-HP heal.

A real-battle test proves incoming Water still deals ordinary damage, keeping the partial boundary visible.

### Gorilla Tactics → DATA_ONLY
Pinned source contains no numeric Attack boost value. It also needs move-lock behavior. No multiplier is invented.

### Steely Spirit → DATA_ONLY
Pinned source contains no numeric Steel boost value and ally context is absent. No multiplier is invented.

Both prose-only source records have fail-fast guards so a future numeric source change forces re-audit.

## Exact #87 → #88 artifact
Raw + normalized:
- exactly `dry_skin.classification: DATA_ONLY → PARTIAL_RUNTIME`;
- exactly `water_bubble.classification: DATA_ONLY → PARTIAL_RUNTIME`.

Reports:
- runtime **18→18**;
- partial **12→14**;
- data-only **343→341**.

Explicitly unchanged:
- every other ability;
- Pokémon/species;
- moves/effects;
- items/statuses;
- learnsets/evolutions;
- types/stats;
- manifest/forms/auxiliary.

`import_time_ms 504→406 ms` is non-semantic timing noise.

## Ability coverage after #88 engineering
- `RUNTIME_SUPPORTED`: **18**
- `PARTIAL_RUNTIME`: **14** — `dry_skin`, `flame_body`, `gooey`, `guts`, `heatproof`, `hustle`, `intimidate`, `iron_barbs`, `levitate`, `poison_point`, `reckless`, `stamina`, `static`, `water_bubble`
- `DATA_ONLY`: **341**
- total: **373**.

## Current certification step
Notebook synchronization now follows engineering SHA `15543135b42254c8d475db9d3eeb36503a674b6c`.

Before closing #88:
1. verify engineering SHA → final HEAD changes only `01_PROJECT_STATE.md`, `04_NEXT_STEPS.md`, `18_DATA_V3_ABILITY_EXISTING_PRIMITIVES.md`;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #88 without merge;
4. use exact final HEAD as the next baseline.

## Exact next task after #88 closure
Continue **DATA FOUNDATION V3 ability reliability** from the exact certified #88 final SHA. Select one bounded source-first subgroup from the remaining **341 DATA_ONLY** abilities.

Prefer:
- semantics that now fit the role-safe damage modifier surface; or
- one genuinely shared correctness primitive with multiple source-backed uses.

Do not reopen Water Bubble/Dry Skin missing mechanics unless burn/status prevention, weather or absorption/heal transactions are being designed deliberately. Do not invent values absent from the immutable snapshot. Trainer AI/archetypes remain deferred.

## Stop condition
Any focal/regression failure stops the tranche until root cause is fixed and rerun.
