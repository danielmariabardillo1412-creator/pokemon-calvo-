# NEXT STEPS — LIVE CHECKPOINT

Read immediately after `00_READ_FIRST.md` when recovering context.

## Latest certified baseline
- PR #86 — `audit/data-v3-ability-next-compatible-v1`
- Final HEAD `06b078b02766ff2c85d5ca45798d8293b8c8e557`
- **18/18 SUCCESS** on exact notebook-bearing HEAD
- closed without merge.

Move Effects V3 remains closed:
- **590 runtime / 71 partial / 246 data-only / 12 unsupported**;
- `DATA_ONLY` moves with executable `effect_specs`: **0**.

Certified #86 ability coverage:
- `RUNTIME_SUPPORTED`: **17**
- `PARTIAL_RUNTIME`: **10**
- `DATA_ONLY`: **346**
- total: **373**.

Prior detailed ability notebooks: `06` through `16`.

# Current tranche — PR #87
- Branch: `audit/data-v3-ability-offensive-stat-conditions-v1`
- Parent: certified #86 final `06b078b02766ff2c85d5ca45798d8293b8c8e557`
- PR: #87 `DATA V3 — audit conditional offensive stat abilities`
- Engineering SHA: `c641891f6a8d2b0b8fcf63db0a57436c2445374f`
- Engineering SHA: **18/18 SUCCESS**
- DATA V3 domain: **482 PASS / 0 FAIL**
- Detailed notebook: `docs/notebooks/17_DATA_V3_ABILITY_OFFENSIVE_STAT_CONDITIONS.md`.

## #87 result
### Defeatist
Decision: **RUNTIME_SUPPORTED**.

Pinned Gen V source requires Attack and Special Attack x0.5 at half HP or less, with no effect history.

Runtime reuses existing #86 conditions:
- physical or special;
- `hp_at_or_below_divisor=2`;
- `offensive_stat_multiplier_bp=5000`.

Real battle pins the exact threshold:
- 120/240 HP activates;
- 121/240 HP is inert.

### Guts
Decision: **PARTIAL_RUNTIME**.

Faithful runtime subset:
- physical move;
- `paralysis`, `poison` or `badly_poisoned`;
- Attack x1.5 through `offensive_stat_multiplier_bp=15000`.

Explicit gaps:
- burn is excluded because the source says Guts suppresses the usual burn Attack cut, while current `DamageCalculator` still applies that cut;
- sleep is excluded because the pinned source preserves Diamond/Pearl battle-history semantics.

Tests pin both poison support and the current burn gap.

### Hustle
Decision: **PARTIAL_RUNTIME**.

Faithful runtime subset:
- physical regular damage x1.5 via final `multiplier_bp=15000`.

Explicit gap:
- source-required accuracy x0.8 is not implemented.

Special damage is tested inert. Structural tests guarantee Hustle does not masquerade as an offensive-stat multiplier.

## Architecture
**No Battle Core file changed in #87.**

This tranche intentionally reuses existing predicates and modifier channels. No new effect, condition or calculator parameter was added.

## Exact #86 → #87 artifact
Raw + normalized:
- exactly `defeatist.classification: DATA_ONLY → RUNTIME_SUPPORTED`;
- exactly `guts.classification: DATA_ONLY → PARTIAL_RUNTIME`;
- exactly `hustle.classification: DATA_ONLY → PARTIAL_RUNTIME`.

Reports:
- runtime **17→18**;
- partial **10→12**;
- data-only **346→343**.

Explicitly unchanged:
- every other ability;
- Pokémon/species;
- moves/effects;
- items/statuses;
- learnsets/evolutions;
- types/stats;
- manifest/forms/auxiliary.

`import_time_ms 491→518 ms` is non-semantic.

## Ability coverage after #87 engineering
- `RUNTIME_SUPPORTED`: **18**
- `PARTIAL_RUNTIME`: **12** — `flame_body`, `gooey`, `guts`, `heatproof`, `hustle`, `intimidate`, `iron_barbs`, `levitate`, `poison_point`, `reckless`, `stamina`, `static`
- `DATA_ONLY`: **343**
- total: **373**.

## Current certification step
Notebook synchronization follows engineering SHA `c641891f6a8d2b0b8fcf63db0a57436c2445374f`.

Before closing #87:
1. verify engineering → final HEAD changed only `01_PROJECT_STATE.md`, `04_NEXT_STEPS.md`, `17_DATA_V3_ABILITY_OFFENSIVE_STAT_CONDITIONS.md`;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #87 without merge;
4. use exact final HEAD as next baseline.

## Exact next task after #87 closure
Continue **DATA FOUNDATION V3 ability reliability** from the exact certified #87 final SHA. Select one small source-first subgroup from the remaining **343 DATA_ONLY** records whose semantics already fit current primitives or justify one genuinely shared primitive.

Do not reopen Guts until burn-cut suppression + version-aware sleep are designed. Do not reopen Hustle until accuracy modifiers are part of hit resolution. Trainer AI/archetypes remain deferred.

## Stop condition
Any focal/regression failure stops the tranche until root cause is fixed and rerun.
