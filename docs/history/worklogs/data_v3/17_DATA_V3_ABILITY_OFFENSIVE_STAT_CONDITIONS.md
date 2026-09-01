# DATA V3 ABILITY OFFENSIVE STAT CONDITIONS — V1

## Purpose
Operational record for the bounded ability-reliability tranche following certified PR #86.

## Certified parent
- PR #86: `DATA V3 — audit offensive stat ability modifiers`.
- Certified final HEAD: `06b078b02766ff2c85d5ca45798d8293b8c8e557`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Parent ability coverage: **17 RUNTIME_SUPPORTED / 10 PARTIAL_RUNTIME / 346 DATA_ONLY / 373 total**.

## Current tranche
- Branch: `audit/data-v3-ability-offensive-stat-conditions-v1`.
- PR: #87 `DATA V3 — audit conditional offensive stat abilities`.
- Exact parent: certified #86 final `06b078b02766ff2c85d5ca45798d8293b8c8e557`.
- Engineering SHA: `c641891f6a8d2b0b8fcf63db0a57436c2445374f`.
- Engineering certification: **18/18 workflows SUCCESS**.
- DATA V3 domain: **482 PASS / 0 FAIL**.

## Source-first decisions
### Defeatist — RUNTIME_SUPPORTED
Pinned source:
- main-series Generation V;
- Attack and Special Attack are halved when HP is half or less;
- `effect_changes=[]`.

Runtime uses only primitives that already existed after #86:
- physical `MODIFY_DAMAGE` + `hp_at_or_below_divisor=2` + `offensive_stat_multiplier_bp=5000`;
- special mirror with the same HP condition and multiplier.

The two specs are mutually exclusive by damage class. No final `multiplier_bp` is used.

Real-battle boundary tests:
- at exactly 120/240 HP, physical damage is reduced and the ability triggers;
- at exactly 120/240 HP, special damage is reduced and the ability triggers;
- at 121/240 HP, damage equals the no-ability control and no trigger is emitted.

Decision: **`defeatist → RUNTIME_SUPPORTED`**.

### Guts — PARTIAL_RUNTIME
Pinned source:
- main-series Generation III;
- current effect: Attack x1.5 while asleep, burned, paralyzed or poisoned;
- burn additionally must NOT apply its ordinary Attack cut;
- the bonus is not a stat stage;
- pinned `effect_changes` contains one Diamond/Pearl battle-relevant rule: Guts did not take effect during sleep.

Current Battle Core applies the ordinary physical burn penalty after the offensive-stat multiplier inside `DamageCalculator`. Therefore registering Guts for burn would produce a false net result. A universal sleep rule would also erase source-preserved version history.

Faithful executable subset:
- physical move;
- persistent status in `paralysis`, `poison`, `badly_poisoned`;
- `offensive_stat_multiplier_bp=15000`.

Explicitly absent:
- `burn` — requires a deliberate ability-aware burn-cut suppression semantic;
- `sleep` — requires version-aware ability behavior.

Real-battle tests prove poison and badly poisoned boost Attack, while a burned Guts user currently behaves exactly like a burned no-ability control and emits no Guts trigger.

Decision: **`guts → PARTIAL_RUNTIME`**.

### Hustle — PARTIAL_RUNTIME
Pinned source:
- main-series Generation III;
- regular physical moves deal 1.5x damage;
- those moves have 0.8x normal accuracy;
- special moves are unaffected;
- set-damage moves keep their damage but still suffer the accuracy change;
- recorded history changes only the old overworld encounter effect.

Faithful executable subset:
- physical move;
- final `multiplier_bp=15000`.

Explicitly absent:
- required accuracy x0.8 behavior.

The structural contract also pins that Hustle does NOT use `offensive_stat_multiplier_bp`; it is a final regular-damage modifier, unlike Huge Power/Guts/Defeatist.

Real-battle tests prove Tackle damage rises while Water Gun is inert.

Decision: **`hustle → PARTIAL_RUNTIME`**.

## Architecture result
**No Battle Core file changed in #87.**

The tranche reuses the #86 surfaces:
- `requires_physical` / `requires_special`;
- `hp_at_or_below_divisor`;
- `required_persistent_status_ids`;
- `multiplier_bp` for final damage;
- `offensive_stat_multiplier_bp` for Attack/Special Attack before the base formula.

This is the intended payoff of the #86 abstraction: three additional source-audited abilities can be modeled without another engine primitive.

## Source guards
`tools/pokeapi_ability_runtime_contracts.py` now fails fast if:
- Defeatist stops being Gen V, loses the half-HP Attack/Special Attack contract, or gains history;
- Guts loses its current major-status/Attack/burn-cut semantics, its Diamond/Pearl sleep history changes shape/version/text, or generation changes;
- Hustle loses its physical-damage/accuracy/set-damage semantics or its recorded history ceases to be overworld-only.

## Tests
New `DataFoundationV3AbilityOffensiveStatConditionsTestSuite` is registered in the DATA V3 domain runner and checks:
- canonical physical/special control metadata;
- Defeatist exact 50% boundary for physical and special;
- Defeatist 50% + 1 HP inert boundary;
- Guts poison and badly-poisoned faithful subset;
- explicit Guts burn gap;
- Hustle physical-damage subset;
- Hustle special inert boundary.

The global runtime contract suite additionally requires exact registry shapes and exact classification inventories/counts.

## Engineering certification
Engineering SHA:
`c641891f6a8d2b0b8fcf63db0a57436c2445374f`

Result:
- **18/18 workflows SUCCESS**;
- DATA Foundation V3 domain: **482 PASS / 0 FAIL**;
- Godot global: SUCCESS;
- no focal or regression failure occurred in this tranche.

## Exact artifact drift — certified #86 final → #87 engineering
Raw `pokemon_api.json`:
- exactly `defeatist.classification: DATA_ONLY → RUNTIME_SUPPORTED`;
- exactly `guts.classification: DATA_ONLY → PARTIAL_RUNTIME`;
- exactly `hustle.classification: DATA_ONLY → PARTIAL_RUNTIME`;
- no other raw semantic change.

Normalized dataset:
- exactly the same three one-field classification changes;
- no other normalized semantic change.

Reports:
- `RUNTIME_SUPPORTED`: **17 → 18**;
- `PARTIAL_RUNTIME`: **10 → 12**;
- `DATA_ONLY`: **346 → 343**;
- total remains **373**;
- `pokeapi_v3_audit.json` changes only those three counts.

Explicitly unchanged:
- every other ability;
- Pokémon/species;
- moves/effects;
- items/statuses;
- learnsets/evolutions;
- types/stats;
- manifest;
- forms policy report;
- auxiliary report.

`import_time_ms 491 → 518 ms` is non-semantic execution noise.

## Coverage after #87 engineering
- `RUNTIME_SUPPORTED`: **18**.
- `PARTIAL_RUNTIME`: **12** — `flame_body`, `gooey`, `guts`, `heatproof`, `hustle`, `intimidate`, `iron_barbs`, `levitate`, `poison_point`, `reckless`, `stamina`, `static`.
- `DATA_ONLY`: **343**.
- total: **373**.

## Remaining boundaries introduced/confirmed here
- Guts full support needs version-aware sleep semantics plus a deliberate way for the ability to suppress the normal burn Attack cut.
- Hustle full support needs an accuracy modifier integrated into move hit resolution, including set-damage moves.
- Defeatist has no known missing source-required battle behavior under the current contract.

## Final certification protocol
After this engineering SHA:
1. synchronize only `01_PROJECT_STATE.md`, `04_NEXT_STEPS.md`, and this notebook `17`;
2. verify engineering → final HEAD changes only those three notebooks;
3. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
4. close PR #87 without merge;
5. use that exact final SHA as the next certified baseline.

Do not commit a post-close notebook update solely to say the PR is closed; GitHub PR state is authoritative for external closure.

## Next work after #87 closure
Continue DATA FOUNDATION V3 ability reliability from the exact #87 certified final HEAD. Select another small immutable-source-backed subgroup from the remaining 343 DATA_ONLY records. Prefer existing primitives; do not reopen Guts/Hustle blockers merely to increase coverage.
