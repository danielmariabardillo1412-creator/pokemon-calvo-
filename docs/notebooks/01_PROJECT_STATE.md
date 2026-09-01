# PROJECT STATE NOTEBOOK

## Purpose / authority
Fast recovery for engineering work. GitHub commits, PR state, CI, immutable source and tested artifacts override this notebook on conflict.

## Certification policy
- Repo: `danielmariabardillo1412-creator/pokemon-calvo-`; Godot 4.7.
- Certified snapshots stay as closed PR branches **without merge**.
- New tranches start from the latest exact certified HEAD, never `main`.
- Require all 18 normal workflows green on the same exact engineering SHA.
- Compare DATA V3 tested artifacts against the prior certified final.
- Notebook commits move SHA, therefore final notebook-bearing HEAD requires a second 18/18.
- Engineering → final must be notebooks-only.
- Any focal/regression failure stops the tranche until root cause is fixed.
- PR close is external state; do not move a certified SHA merely to record closure.

## DATA FOUNDATION V3 authority
Immutable source:
- branch `data/pokeapi-v2-snapshot`
- commit `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`
- API tree `8349ea1ce75716897fe96e02a15950d19edba6c3`
- schema tree `02e031e1928d7e9456bf6f7486daacc4b8946c84`
- `data/api/v2`, `data/schema/v2` read-only.

Structural facts: 1,025 species; 326 forms; 18 runtime types; 919 runtime moves; 373 abilities; 2,222 items; 61,102 learnset entries; 554 evolutions; 0 broken refs; 0 rejected defs; 18 XD Shadow moves explicitly excluded.

Pipeline:
`snapshot → V3 adapter → narrow semantic audit layers → raw JSON → Godot DataImporter → normalized data → runtime`.

## Recent certified chain
- #75 `4bb4bdc64982eef62f126f8d1c38e9509d21c96c`
- #76 `a596a38680b60db317f1dfd6b6beb8d7ded7b813`
- #77 `78da22438d0866193b0d1154814464531ac55641`
- #78 `eda483d9cd6423d32bdf1a156372416b2fbcb639`
- #79 `5b9ad561017fc4c209d6fd11ef9ddc7dbf3fbd71`
- #80 `232a3e787fe2d7d58b1feb693272b63bd7a699bf`
- #81 `e2eeef1d23def1d9fd124b5e2eeb437270212b68`
- #82 `089140a8439390758d688636f715a311ec175163`
- #83 `f4a1f76850d8737c4d9847045335e703d5ecaa23`
- #84 `67c483899dadb2e3d1b5314a779d4c71b1bc8708`
- #85 `6909aa778eca6555184167401f5e52be11f46ac3`
- #86 `06b078b02766ff2c85d5ca45798d8293b8c8e557`
- #87 `6fc1f73be1b24cba0c8052549ab4ea5f1e96c976`
- #88 `64625cd8d46576a528ea9229bbd0b1d7898f0332`
- #89 `407ad8f27d13a79b09c367aac2f6ae0c1ef801ef`
- #90 `84e58498e4453ee5378e3209487f4cbfe7b2eead`

All entries above: **18/18 SUCCESS on exact final notebook-bearing HEAD and closed without merge**.

## Move Effects V3 closed milestone
- RUNTIME_SUPPORTED: **590**
- PARTIAL_RUNTIME: **71**
- DATA_ONLY: **246**
- UNSUPPORTED: **12**
- DATA_ONLY with executable `effect_specs`: **0**.

## Latest certified baseline — PR #90
Certified final HEAD:
`84e58498e4453ee5378e3209487f4cbfe7b2eead`

Certified #90 ability coverage:
- RUNTIME_SUPPORTED: **19**
- PARTIAL_RUNTIME: **14**
- DATA_ONLY: **340**
- total: **373**.

# Current tranche — PR #91 Target-state semantics
- Branch: `audit/data-v3-ability-target-state-v1`.
- Parent: certified #90 final `84e58498e4453ee5378e3209487f4cbfe7b2eead`.
- PR: #91 `DATA V3 — add shared target-state ability semantics`.
- Engineering SHA: `a14b761016aec1dd3b0d733f89cee28fd06fe16a`.
- Engineering result: **18/18 SUCCESS**.
- DATA V3 domain: **529 PASS / 0 FAIL**.
- Detailed notebook: `docs/notebooks/21_DATA_V3_ABILITY_TARGET_STATE.md`.

## #91 shared target-state architecture
#90 proved Bad Dreams could not use the owner-local persistent-status predicate. #91 found a second independent consumer, Merciless, so a generic target-status condition is justified.

Contract:
- `required_persistent_status_ids` remains owner-local;
- `required_target_persistent_status_ids` evaluates the supplied opposing/effect target;
- historical callers remain compatible via optional target argument;
- damage modifiers pass the opposing combatant directionally;
- no weather/gender/switch-history subsystem was added.

## #91 ability decisions
### Bad Dreams → RUNTIME_SUPPORTED
- Gen IV source; no history.
- `END_TURN` + target `sleep` + `MAX_HP_DAMAGE(OPPONENT, 1250 bp)`.
- Real battle: sleeping rival loses exactly 1/8 max HP and triggers once; awake rival is inert.

### Merciless → RUNTIME_SUPPORTED
- Gen VII source; no history.
- actor `MODIFY_DAMAGE` + target status `{poison, badly_poisoned}` + `force_critical=true`.
- no damage multiplier / no offensive-stat multiplier.
- Natural critical chance is forced to zero in tests; poison/toxic still critical, healthy/burn controls do not.
- Uses existing project-authoritative `calvo_v1` critical semantics rather than a new critical subsystem.

### Rivalry → DATA_ONLY
Requires comparing user/target gender. Runtime does not carry the required per-creature gender/comparison state. Species `gender_rate` is not a safe substitute.

### Stakeout → DATA_ONLY
Requires knowing whether the target switched in during the current turn. Runtime lacks turn-scoped target switch-history state.

Rain Dish / Ice Body remain DATA_ONLY because weather architecture is still absent.

## #91 source guards
Ability contracts now explicitly guard immutable source semantics for Bad Dreams, Merciless, Rivalry and Stakeout. Source drift forces re-audit.

## #91 exact artifact comparison
Certified #90 final:
- run `33503120882`
- artifact `9798542104`
- head `84e58498e4453ee5378e3209487f4cbfe7b2eead`.

#91 engineering:
- run `33505565643`
- artifact `9799469428`
- head `a14b761016aec1dd3b0d733f89cee28fd06fe16a`.

Canonical drift is exactly:
- `bad_dreams.classification: DATA_ONLY → RUNTIME_SUPPORTED`
- `merciless.classification: DATA_ONLY → RUNTIME_SUPPORTED`
in raw and normalized.

Reports change only corresponding ability lists/counters:
- RUNTIME_SUPPORTED **19 → 21**
- PARTIAL_RUNTIME **14 → 14**
- DATA_ONLY **340 → 338**.

Unchanged: all other ability fields/records, Pokémon/species, moves/effects, items/statuses, learnsets/evolutions, types/stats, manifest, forms and auxiliary. `import_time_ms 509 → 507` is timing noise.

## Ability coverage after #91 engineering
- RUNTIME_SUPPORTED: **21**
- PARTIAL_RUNTIME: **14**
- DATA_ONLY: **338**
- total: **373**.

## Current certification step
Notebook synchronization follows engineering SHA `a14b761016aec1dd3b0d733f89cee28fd06fe16a`.

Before closing #91:
1. engineering → final must change exactly `01`, `04`, `21` notebooks;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #91 without merge;
4. use exact final SHA as next certified baseline.

Do not make a post-close commit solely to record closure; GitHub PR state is authoritative.

## Important blockers still open
- weather state/residuals: Rain Dish, Ice Body and other weather families;
- gender comparison: Rivalry;
- turn-scoped switch history: Stakeout;
- version-aware ability values/probabilities: Rough Skin, Transistor, Shed Skin;
- residual replacement/prevention: Poison Heal, Heatproof burn residual, Water Bubble burn prevention;
- Guts burn/sleep semantics; Hustle accuracy;
- contact per-strike/faint-safe policy;
- move-property metadata and super-effective predicates;
- Gorilla Tactics numeric provenance/move lock; Steely Spirit numeric/ally provenance.

## Next work after #91
Continue DATA FOUNDATION V3 ability reliability from exact certified #91 final HEAD. Prefer another bounded family that reuses existing primitives or produces a useful negative audit. Do not open weather/gender/switch-history architecture casually. Trainer AI/archetypes remain deferred until DATA V3 closure is complete.
