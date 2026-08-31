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

## Latest certified ability baseline — PR #82
Detailed notebooks: `06`, `07`, `08`, `09`, `10`, `11`, `12`.

Certified #82 coverage:
- `RUNTIME_SUPPORTED`: **13**
- `PARTIAL_RUNTIME`: **5** — `heatproof`, `intimidate`, `levitate`, `stamina`, `static`
- `DATA_ONLY`: **355**
- total: **373**.

# Current tranche — PR #83 Move-property ability contracts
- Branch: `audit/data-v3-ability-move-property-v1`.
- Exact parent: certified #82 final `089140a8439390758d688636f715a311ec175163`.
- PR: #83 `DATA V3 — audit move-property ability contracts`.
- Engineering SHA: `f9d3538dec9c443e60070b0e4bf7d7904c984e55`.
- Engineering SHA: **18/18 SUCCESS**.
- Detailed notebook: `docs/notebooks/13_DATA_V3_ABILITY_MOVE_PROPERTIES.md`.

## #83 decision — Reckless
Pinned Generation IV source requires 1.2x power for recoil **and crash** moves; Struggle is excluded.

Current runtime has a trustworthy structured recoil subset through `BattleEffectSpec.RECOIL` but does not yet encode Jump Kick / High Jump Kick crash-on-miss as the same transaction.

Decision: **`reckless → PARTIAL_RUNTIME`**.

Battle Core adds one generic structural condition:
- `requires_recoil=true`, recursively matched from `move.effect_specs`;
- no move-name/prose inference.

Reckless registration:
- actor `MODIFY_DAMAGE`;
- `requires_recoil=true`;
- `multiplier_bp=12000`.

Real-battle integration verifies:
- Double-Edge damage increases and Reckless triggers;
- normal recoil still occurs;
- Tackle is unchanged and does not trigger Reckless;
- Jump Kick remains unchanged with/without Reckless and emits no Reckless trigger, explicitly documenting the missing crash subset.

## #83 audited blockers
### Long Reach
Source is clean, but defender-owned contact-trigger evaluation currently receives trigger owner + move, not the move user. Long Reach therefore remains **DATA_ONLY** rather than introducing a hidden ability-id special-case or broad trigger-context expansion.

### Technician
Source requires resolved/variable-power and prior power-modifier semantics. Static `move.power <= 60` is knowingly insufficient for current stateful/variable-power moves. Remains **DATA_ONLY**.

### Iron Fist / Strong Jaw / Mega Launcher / Sharpness
Current `MoveDefinition` has no provenance-backed punch/bite/pulse/slicing tags. All remain **DATA_ONLY**; no inference from names or prose.

## #83 artifact drift
Certified #82 artifact → successful #83 engineering artifact:
- raw: exactly `reckless.classification: DATA_ONLY → PARTIAL_RUNTIME`;
- normalized: exactly the same one-field change;
- `RUNTIME_SUPPORTED`: remains **13**;
- `PARTIAL_RUNTIME`: **5 → 6**;
- `DATA_ONLY`: **355 → 354**;
- Long Reach, Technician, Iron Fist, Strong Jaw, Mega Launcher and Sharpness unchanged;
- every other ability unchanged;
- species/Pokémon, moves/effects, items/statuses, learnsets/evolutions, types/stats, manifest/forms/auxiliary unchanged;
- `pokeapi_v3_audit.json` changes only partial 5→6 and data-only 355→354;
- `import_time_ms` 396→398 ms is non-semantic.

## Ability coverage after #83 engineering
- `RUNTIME_SUPPORTED`: **13**
- `PARTIAL_RUNTIME`: **6** — `heatproof`, `intimidate`, `levitate`, `reckless`, `stamina`, `static`
- `DATA_ONLY`: **354**
- total: **373**.

## Known blockers after #83
- `reckless`: full support needs structured crash-on-miss move semantics.
- `long_reach`: needs a shared effective-contact/context contract exposing move user to contact reactions.
- `technician`: needs resolved/transactional move-power semantics, not static base-power approximation.
- `iron_fist`, `strong_jaw`, `mega_launcher`, `sharpness`: need provenance-backed move-property tags.
- `filter`, `solid_rock`: need a shared super-effective/effectiveness predicate.
- `heatproof`: full support needs burn residual ability interaction.
- `fluffy`: needs modifier composition/event aggregation to avoid duplicate logical trigger events.
- `huge_power`, `pure_power`: need genuine offensive-stat multiplier abstraction.
- `transistor`: version-sensitive multiplier contract unresolved.
- `water_compaction`: requires Water-specific AFTER_DAMAGE predicate.
- `weak_armor`: requires dual stat transaction plus per-hit/version semantics.

## Current certification step
Notebook synchronization follows engineering SHA `f9d3538dec9c443e60070b0e4bf7d7904c984e55`.

Before closing #83:
1. verify engineering → final HEAD changes only `01`, `04`, `13` notebooks;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #83 without merge;
4. use exact final SHA as next certified baseline.

## Exact next work after #83
Continue DATA FOUNDATION V3 ability reliability with another bounded family selected from the remaining 354 DATA_ONLY records only after source-vs-runtime comparison. Do not broaden Battle Core merely to improve coverage. Trainer AI/archetypes remain deferred.
