# PROJECT STATE NOTEBOOK

## Purpose / authority
Fast recovery for engineering work. GitHub commits, PR state, CI, immutable source and tested artifacts override this notebook on conflict.

## Certification policy
- Repo: `danielmariabardillo1412-creator/pokemon-calvo-`; Godot 4.7.
- Certified snapshots stay as closed PR branches **without merge**.
- New tranches start from the latest exact certified HEAD.
- Require all 18 normal workflows green on the same exact final SHA.
- Notebook commits move SHA, therefore the final notebook-bearing HEAD requires a second 18/18.
- Any focal/regression failure stops the tranche until root cause is fixed.
- PR close is external state; do not move a certified SHA merely to record closure in a notebook.

## DATA FOUNDATION V3 authority
Immutable source:
- branch `data/pokeapi-v2-snapshot`
- commit `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`
- API tree `8349ea1ce75716897fe96e02a15950d19edba6c3`
- schema tree `02e031e1928d7e9456bf6f7486daacc4b8946c84`
- `data/api/v2`, `data/schema/v2` are read-only.

Structural facts: 1,025 species; 326 forms; 18 runtime types; 919 runtime moves; 373 abilities; 2,222 items; 61,102 learnset entries; 554 evolutions; 0 broken refs; 0 rejected defs; 18 XD Shadow moves explicitly excluded.

Pipeline:
`snapshot → V3 adapter → narrow semantic audit layers → raw JSON → Godot DataImporter → normalized data → runtime`.

## Recent certified chain
- #75 final DATA_ONLY executable effects `4bb4bdc64982eef62f126f8d1c38e9509d21c96c`
- #76 initial ability runtime contracts `a596a38680b60db317f1dfd6b6beb8d7ded7b813`
- #77 ability family inventory + Swarm `78da22438d0866193b0d1154814464531ac55641`
- #78 unconditional ability type boosts `eda483d9cd6423d32bdf1a156372416b2fbcb639`
- #79 hit-triggered stat reactions `5b9ad561017fc4c209d6fd11ef9ddc7dbf3fbd71`
- #80 Tough Claws / contact damage audit `232a3e787fe2d7d58b1feb693272b63bd7a699bf`
- #81 defensive damage modifiers `e2eeef1d23def1d9fd124b5e2eeb437270212b68`
- #82 defensive predicates `089140a8439390758d688636f715a311ec175163`
- #83 move-property contracts / Reckless partial `f4a1f76850d8737c4d9847045335e703d5ecaa23`
- #84 defender contact reactions `67c483899dadb2e3d1b5314a779d4c71b1bc8708`
- #85 contact retaliation damage `6909aa778eca6555184167401f5e52be11f46ac3`
- #86 offensive stat ability modifiers `06b078b02766ff2c85d5ca45798d8293b8c8e557`

All entries above: **18/18 SUCCESS on exact final notebook-bearing HEAD and closed without merge**.

## Move Effects V3 closed milestone
Move coverage remains:
- `RUNTIME_SUPPORTED`: **590**
- `PARTIAL_RUNTIME`: **71**
- `DATA_ONLY`: **246**
- `UNSUPPORTED`: **12**
- `DATA_ONLY` with executable `effect_specs`: **0**.

## Ability coverage principle
Preserved metadata is not executable support.
- `RUNTIME_SUPPORTED`: modeled battle mechanic is faithful.
- `PARTIAL_RUNTIME`: useful faithful subset works but known source-required behavior is absent.
- `DATA_ONLY`: data retained without claiming executable mechanics.

Battle Core ability execution is controlled by trigger registration; DATA V3 classification describes semantic completeness.

## Latest certified baseline — PR #86
Detailed ability notebooks: `06` through `16`.

Certified #86 final HEAD:
`06b078b02766ff2c85d5ca45798d8293b8c8e557`

Certified #86 ability coverage:
- `RUNTIME_SUPPORTED`: **17**
- `PARTIAL_RUNTIME`: **10** — `flame_body`, `gooey`, `heatproof`, `intimidate`, `iron_barbs`, `levitate`, `poison_point`, `reckless`, `stamina`, `static`
- `DATA_ONLY`: **346**
- total: **373**.

# Current tranche — PR #87 Conditional offensive stat abilities
- Branch: `audit/data-v3-ability-offensive-stat-conditions-v1`.
- Exact parent: certified #86 final `06b078b02766ff2c85d5ca45798d8293b8c8e557`.
- PR: #87 `DATA V3 — audit conditional offensive stat abilities`.
- Engineering SHA: `c641891f6a8d2b0b8fcf63db0a57436c2445374f`.
- Engineering SHA: **18/18 SUCCESS**.
- DATA V3 domain: **482 PASS / 0 FAIL**.
- Detailed notebook: `docs/notebooks/17_DATA_V3_ABILITY_OFFENSIVE_STAT_CONDITIONS.md`.

## #87 source decisions
### Defeatist
Pinned Gen V source: Attack and Special Attack are halved at half HP or less; no history.

Decision: **`defeatist → RUNTIME_SUPPORTED`**.

Runtime:
- physical and special mutually-exclusive `MODIFY_DAMAGE` specs;
- `hp_at_or_below_divisor=2`;
- `offensive_stat_multiplier_bp=5000`;
- no final-damage multiplier.

Real battle pins exactly 120/240 active and 121/240 inert.

### Guts
Pinned Gen III source requires Attack x1.5 while asleep/burned/paralyzed/poisoned, plus suppression of the usual burn Attack cut. Pinned history records Diamond/Pearl sleep behavior.

Decision: **`guts → PARTIAL_RUNTIME`**.

Faithful subset only:
- physical;
- status in `paralysis`, `poison`, `badly_poisoned`;
- offensive stat `15000`.

Deliberately absent:
- burn: current `DamageCalculator` would still apply the normal burn cut after the offensive-stat multiplier;
- sleep: source history is version-sensitive.

### Hustle
Pinned Gen III source requires regular physical damage x1.5 and accuracy x0.8; special moves unaffected. Recorded history is overworld-only.

Decision: **`hustle → PARTIAL_RUNTIME`**.

Faithful subset only:
- physical;
- final `multiplier_bp=15000`.

Missing: accuracy x0.8 integration.

## #87 architecture
**No Battle Core file changed.**

The tranche reuses existing #86 primitives:
- physical/special predicates;
- HP divisor condition;
- persistent-status list;
- final damage multiplier;
- offensive-stat multiplier.

This is intentional: coverage increased through source-compatible reuse rather than another architecture layer.

## #87 exact artifact drift
Certified #86 final artifact → #87 engineering artifact:
- raw: exactly three one-field changes:
  - `defeatist.classification: DATA_ONLY → RUNTIME_SUPPORTED`;
  - `guts.classification: DATA_ONLY → PARTIAL_RUNTIME`;
  - `hustle.classification: DATA_ONLY → PARTIAL_RUNTIME`;
- normalized: exactly the same three changes;
- every other ability unchanged;
- species/Pokémon, moves/effects, items/statuses, learnsets/evolutions, types/stats unchanged;
- manifest/forms/auxiliary unchanged;
- runtime **17 → 18**;
- partial **10 → 12**;
- data-only **346 → 343**;
- `pokeapi_v3_audit.json` changes only those three counts;
- `import_time_ms 491 → 518 ms` is non-semantic timing noise.

## Ability coverage after #87 engineering
- `RUNTIME_SUPPORTED`: **18**
- `PARTIAL_RUNTIME`: **12** — `flame_body`, `gooey`, `guts`, `heatproof`, `hustle`, `intimidate`, `iron_barbs`, `levitate`, `poison_point`, `reckless`, `stamina`, `static`
- `DATA_ONLY`: **343**
- total: **373**.

## Known blockers after #87 engineering
- `guts`: full support needs version-aware sleep behavior and ability-aware suppression of the burn Attack cut.
- `hustle`: full support needs an accuracy modifier in hit resolution, including set-damage moves.
- `iron_barbs`: full support needs deliberate per-strike and faint-safe/double-KO ordering.
- `rough_skin`: needs version-aware ability semantics.
- `static`, `flame_body`, `poison_point`, `gooey`: full support needs deliberate fatal/per-strike contact policy.
- `water_compaction`: requires Water-specific AFTER_DAMAGE predicate.
- `weak_armor`: requires dual stat transaction plus per-hit/version semantics.
- `transistor`: version-sensitive multiplier unresolved.
- `long_reach`: needs effective-contact context exposing move user.
- `technician`: needs resolved/transactional move power.
- `iron_fist`, `strong_jaw`, `mega_launcher`, `sharpness`: need provenance-backed move-category tags.
- `filter`, `solid_rock`: need shared super-effective predicate.
- `fluffy`: needs modifier composition/event aggregation.
- `heatproof`: full support needs burn residual interaction.
- `reckless`: full support needs crash-on-miss semantics.

## Current certification step
Notebook synchronization follows engineering SHA `c641891f6a8d2b0b8fcf63db0a57436c2445374f`.

Before closing #87:
1. verify engineering → final HEAD changes only `01`, `04`, `17` notebooks;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #87 without merge;
4. use exact final SHA as next certified baseline.

## Exact next work after #87
Continue DATA FOUNDATION V3 ability reliability with one bounded source-first subgroup from the remaining **343 DATA_ONLY** records. Do not reopen Guts/Hustle blockers merely to raise coverage. Trainer AI/archetypes remain deferred.
