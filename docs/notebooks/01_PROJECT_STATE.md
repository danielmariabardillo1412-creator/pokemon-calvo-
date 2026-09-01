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
- #80 contact damage + attack-doubling audit `232a3e787fe2d7d58b1feb693272b63bd7a699bf`
- #81 defensive damage modifiers `e2eeef1d23def1d9fd124b5e2eeb437270212b68`
- #82 defensive predicates `089140a8439390758d688636f715a311ec175163`
- #83 move-property ability contracts `f4a1f76850d8737c4d9847045335e703d5ecaa23`
- #84 defender contact reactions `67c483899dadb2e3d1b5314a779d4c71b1bc8708`
- #85 contact retaliation damage `6909aa778eca6555184167401f5e52be11f46ac3`

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

## Latest certified baseline — PR #85
Detailed ability notebooks: `06` through `15`.

Certified #85 coverage:
- `RUNTIME_SUPPORTED`: **13**
- `PARTIAL_RUNTIME`: **10** — `flame_body`, `gooey`, `heatproof`, `intimidate`, `iron_barbs`, `levitate`, `poison_point`, `reckless`, `stamina`, `static`
- `DATA_ONLY`: **350**
- total: **373**.

# Current tranche — PR #86 Offensive stat ability modifiers
- Branch: `audit/data-v3-ability-next-compatible-v1`.
- Exact parent: certified #85 final `6909aa778eca6555184167401f5e52be11f46ac3`.
- PR: #86 `DATA V3 — audit offensive stat ability modifiers`.
- First engineering candidate: `fd5a3f8d3138827c2cb6964bbe53bf3f9f524d5d` — DATA V3 **468 PASS / 3 FAIL**.
- Corrected engineering SHA: `60281b7c016f8032a1f6c8f955cdfe2a727b58ac`.
- Corrected engineering SHA: **18/18 SUCCESS**.
- Corrected DATA V3 domain: **471 PASS / 0 FAIL**.
- Detailed notebook: `docs/notebooks/16_DATA_V3_ABILITY_NEXT_COMPATIBLE.md`.

## #86 source decisions
Promoted to **RUNTIME_SUPPORTED** after immutable-source audit:
- `huge_power`: Gen III Attack x2, no effect history;
- `pure_power`: Gen III Attack x2, no effect history;
- `toxic_boost`: Gen V Attack x1.5 while poisoned, no effect history;
- `flare_boost`: Gen V Special Attack x1.5 while burned, no effect history.

Toxic Boost accepts both runtime poison states: `poison` and `badly_poisoned`.

## #86 Battle Core abstraction
The existing `multiplier_bp` is a **final-damage** modifier and was deliberately not reused for these abilities.

New shared channel:
- `offensive_stat_multiplier_basis_points`.

`BattleTriggerSystem.damage_modifiers()` now separates:
- final-damage multiplier;
- offensive-stat multiplier;
- immunity.

New generic trigger condition:
- `required_persistent_status_ids`.

`DamageCalculator` applies the offensive multiplier to staged Attack/Special Attack **before the base formula**. Damage-event metadata records the multiplier.

A focal odd-Attack regression proves Attack x2 is not generally equivalent to final damage x2 because integer floors occur inside the formula.

## Positional API compatibility
The new calculator parameter was initially inserted before `force_critical`, but repository search found historical positional calls `..., 10000, 0` where the final `0` means force non-critical.

Before first CI, the signature was corrected so the new parameter is appended after `force_critical`.

The focal suite proves old positional usage and explicit new usage are equivalent at the default offensive multiplier.

## #86 runtime registrations
- Huge Power: physical + offensive stat `20000`.
- Pure Power: physical + offensive stat `20000`.
- Toxic Boost: physical + status in `{poison, badly_poisoned}` + offensive stat `15000`.
- Flare Boost: special + burn + offensive stat `15000`.

None of the four uses final `multiplier_bp`.

## #86 real-battle coverage
New `DataFoundationV3AbilityOffensiveStatTestSuite` verifies:
- physical/special controls;
- positional calculator compatibility;
- stat-multiplier vs final-damage-multiplier distinction;
- Huge Power physical support / special inert;
- Pure Power parity with Huge Power;
- Toxic Boost normal poison + badly poisoned support, clean/special inert;
- Flare Boost burned-special support, clean/physical inert.

## #86 first CI failure and correction
First candidate `fd5a3f8...` passed source audit, regeneration, counts and **all new functional tests**, but three exact inventory assertions failed.

Root cause: expected arrays used:
`..., torrent, toxic_boost, tough_claws`

Canonical sorted output is:
`..., torrent, tough_claws, toxic_boost`.

This was purely an ordering expectation error.

The first test-only correction accidentally removed comment-only audit annotations through full-file replacement. A follow-up restored them. Failed candidate → final corrected engineering SHA changes only the runtime-contract test file: the two order swaps plus an EOF newline marker; no runtime/source/classification changes.

Corrected engineering result: **18/18 SUCCESS**, DATA V3 **471 PASS / 0 FAIL**.

## #86 exact artifact drift
Certified #85 final artifact → successful #86 engineering artifact:
- raw: exactly four one-field changes, `classification: DATA_ONLY → RUNTIME_SUPPORTED`, for `flare_boost`, `huge_power`, `pure_power`, `toxic_boost`;
- normalized: exactly the same four changes;
- every other ability unchanged;
- species/Pokémon, moves/effects, items/statuses, learnsets/evolutions, types/stats unchanged;
- manifest/forms/auxiliary unchanged;
- RUNTIME_SUPPORTED **13 → 17**;
- PARTIAL_RUNTIME remains **10**;
- DATA_ONLY **350 → 346**;
- `pokeapi_v3_audit.json` changes only runtime/data-only counts;
- `import_time_ms` **509 → 548 ms** is non-semantic timing noise.

## Ability coverage after #86 engineering
- `RUNTIME_SUPPORTED`: **17**
- `PARTIAL_RUNTIME`: **10** — `flame_body`, `gooey`, `heatproof`, `intimidate`, `iron_barbs`, `levitate`, `poison_point`, `reckless`, `stamina`, `static`
- `DATA_ONLY`: **346**
- total: **373**.

## Known blockers after #86 engineering
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
Notebook synchronization follows engineering SHA `60281b7c016f8032a1f6c8f955cdfe2a727b58ac`.

Before closing #86:
1. verify engineering → final HEAD changes only `01`, `04`, `16` notebooks;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #86 without merge;
4. use exact final SHA as next certified baseline.

## Exact next work after #86
Continue DATA FOUNDATION V3 ability reliability with one bounded source-first subgroup from the remaining **346 DATA_ONLY** records. Prefer an existing abstraction or a genuinely shared primitive across multiple source-compatible abilities. A negative audit is preferable to architecture added only for coverage.

Trainer AI/archetypes remain deferred.
