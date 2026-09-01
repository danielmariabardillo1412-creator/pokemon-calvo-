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

Structural facts:
- 1,025 species;
- 326 forms;
- 18 runtime types;
- 919 runtime moves;
- 373 abilities;
- 2,222 items;
- 61,102 learnset entries;
- 554 evolutions;
- 0 broken refs;
- 0 rejected defs;
- 18 XD Shadow moves explicitly excluded.

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

All above: **18/18 SUCCESS on exact final notebook-bearing HEAD and closed without merge**.

## Move Effects V3 closed milestone
- `RUNTIME_SUPPORTED`: **590**
- `PARTIAL_RUNTIME`: **71**
- `DATA_ONLY`: **246**
- `UNSUPPORTED`: **12**
- `DATA_ONLY` with executable `effect_specs`: **0**.

## Latest certified baseline — PR #87
Certified final HEAD:
`6fc1f73be1b24cba0c8052549ab4ea5f1e96c976`

Certified ability coverage:
- `RUNTIME_SUPPORTED`: **18**
- `PARTIAL_RUNTIME`: **12**
- `DATA_ONLY`: **343**
- total: **373**.

Detailed ability notebooks: `06` through `17`.

# Current tranche — PR #88 Damage modifier roles + compound abilities
- Branch: `audit/data-v3-ability-existing-primitives-v1`.
- Exact parent: certified #87 final `6fc1f73be1b24cba0c8052549ab4ea5f1e96c976`.
- PR: #88 `DATA V3 — isolate damage modifier roles and audit compound abilities`.
- Engineering SHA: `15543135b42254c8d475db9d3eeb36503a674b6c`.
- Engineering SHA: **18/18 SUCCESS**.
- DATA V3 domain: **499 PASS / 0 FAIL**.
- Detailed notebook: `docs/notebooks/18_DATA_V3_ABILITY_EXISTING_PRIMITIVES.md`.

## #88 root-cause correction — role isolation
A pre-existing Battle Core bug allowed ability `MODIFY_DAMAGE` specs to be evaluated from both actor and target sides because no directional contract existed.

Invalid examples before the fix:
- attacking Fur Coat could reduce its own outgoing physical damage;
- defending low-HP Blaze could amplify incoming Fire damage.

Correction:
- every ability `MODIFY_DAMAGE` spec now declares `damage_role = actor` or `damage_role = target`;
- actor loop accepts only actor specs;
- target loop accepts only target specs;
- missing role is fail-safe inert.

All existing ability damage modifiers were tagged according to their real direction. New real-battle regressions prove defender Blaze and attacker Fur Coat are inert in the wrong role.

This is a shared correctness repair, not architecture added solely for coverage.

## #88 source decisions
### Water Bubble
Decision: **PARTIAL_RUNTIME**.

Pinned Gen VII source requires:
- outgoing Water x2;
- incoming Fire x0.5;
- burn prevention / immediate cure.

Runtime subset:
- actor Water `multiplier_bp=20000`;
- target Fire `multiplier_bp=5000`.

Missing: burn prevention/cure.

### Dry Skin
Decision: **PARTIAL_RUNTIME**.

Pinned Gen IV source requires:
- sun 1/8 max-HP damage;
- rain 1/8 max-HP healing;
- incoming Fire x1.25;
- Water absorption + 1/4 max-HP heal.

Runtime subset:
- target Fire `multiplier_bp=12500`.

Missing: weather and Water absorption/healing.

### Gorilla Tactics
Decision: **DATA_ONLY**.
Pinned source states Attack boost + first-move lock but contains no numeric boost amount. No value is invented. A guard forces re-audit if numeric provenance appears.

### Steely Spirit
Decision: **DATA_ONLY**.
Pinned source states Steel boost for holder/allies but contains no numeric amount. No value is invented. A guard forces re-audit if numeric provenance appears.

## #88 tests
New `DataFoundationV3AbilityDamageRoleTestSuite` verifies:
- every `MODIFY_DAMAGE` ability spec has explicit role;
- defender Blaze wrong-role inert;
- attacker Fur Coat wrong-role inert;
- Water Bubble outgoing Water x2;
- Water Bubble incoming Fire x0.5;
- Water Bubble opposite-role leakage absent;
- Water Bubble burn gap explicit;
- Dry Skin incoming Fire x1.25;
- Dry Skin attacker wrong-role inert;
- Dry Skin Water absorption gap explicit;
- Gorilla Tactics / Steely Spirit stay DATA_ONLY.

The global runtime contract suite also pins exact registry shapes and exact coverage counts.

## #88 exact artifact drift
Certified #87 final artifact → #88 engineering artifact:
- raw: exactly two one-field changes:
  - `dry_skin.classification: DATA_ONLY → PARTIAL_RUNTIME`;
  - `water_bubble.classification: DATA_ONLY → PARTIAL_RUNTIME`;
- normalized: exactly the same two changes;
- PARTIAL set adds exactly `dry_skin`, `water_bubble`;
- DATA_ONLY set removes exactly those two;
- RUNTIME_SUPPORTED set unchanged;
- every other ability unchanged;
- Pokémon/species, moves/effects, items/statuses, learnsets/evolutions, types/stats unchanged;
- manifest/forms/auxiliary unchanged;
- `pokeapi_v3_audit.json` changes only partial/data-only counts;
- `import_time_ms 504 → 406 ms` is non-semantic timing noise.

## Ability coverage after #88 engineering
- `RUNTIME_SUPPORTED`: **18**
- `PARTIAL_RUNTIME`: **14** — `dry_skin`, `flame_body`, `gooey`, `guts`, `heatproof`, `hustle`, `intimidate`, `iron_barbs`, `levitate`, `poison_point`, `reckless`, `stamina`, `static`, `water_bubble`
- `DATA_ONLY`: **341**
- total: **373**.

## Important blockers after #88
- Water Bubble: burn prevention/immediate cure.
- Dry Skin: weather + Water absorption/healing.
- Gorilla Tactics: missing numeric source value + move lock.
- Steely Spirit: missing numeric source value + ally context.
- Guts: burn-cut suppression + version-aware sleep.
- Hustle: accuracy modifier.
- Iron Barbs / Static / Flame Body / Poison Point / Gooey: per-strike/faint-safe contact policy.
- Rough Skin / Transistor: version-aware ability values.
- Water Compaction / Weak Armor: hit-context / compound per-hit transactions.
- Technician / move-property families: resolved move properties.
- Filter / Solid Rock: super-effective predicate.

## Current certification step
Notebook synchronization follows engineering SHA `15543135b42254c8d475db9d3eeb36503a674b6c`.

Before closing #88:
1. verify engineering → final HEAD changes only `01`, `04`, `18` notebooks;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #88 without merge;
4. use exact final SHA as the next certified baseline.

## Exact next work after #88
Continue DATA FOUNDATION V3 ability reliability from the exact #88 certified final HEAD with one bounded immutable-source-backed subgroup among the remaining **341 DATA_ONLY** records. Prefer the now role-safe damage surface or another genuinely shared correctness primitive. Trainer AI/archetypes remain deferred.
