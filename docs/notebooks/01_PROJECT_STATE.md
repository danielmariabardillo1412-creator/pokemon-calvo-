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

All entries above: **18/18 SUCCESS on exact final notebook-bearing HEAD and closed without merge**.

## Move Effects V3 closed milestone
- RUNTIME_SUPPORTED: **590**
- PARTIAL_RUNTIME: **71**
- DATA_ONLY: **246**
- UNSUPPORTED: **12**
- DATA_ONLY with executable `effect_specs`: **0**.

## Latest certified baseline — PR #88
Certified final HEAD:
`64625cd8d46576a528ea9229bbd0b1d7898f0332`

Certified ability coverage:
- RUNTIME_SUPPORTED: **18**
- PARTIAL_RUNTIME: **14**
- DATA_ONLY: **341**
- total: **373**.

# Current tranche — PR #89 End-turn ability semantics
- Branch: `audit/data-v3-ability-end-turn-v1`.
- Exact parent: certified #88 final `64625cd8d46576a528ea9229bbd0b1d7898f0332`.
- PR: #89 `DATA V3 — audit end-turn ability semantics`.
- Engineering SHA: `b161373a70d0ed226259fe01f98b0d5cfcf677ed`.
- Engineering result: **18/18 SUCCESS**.
- DATA Foundation V3: **509 PASS / 0 FAIL**.
- Spanish/type/runtime regression: **298 PASS / 0 FAIL**.
- Detailed notebook: `docs/notebooks/19_DATA_V3_ABILITY_END_TURN.md`.

## #89 source decisions
### Speed Boost
Pinned Gen III source: Speed rises one stage after each turn; no history.

Decision: **RUNTIME_SUPPORTED**.

Runtime is exactly one existing primitive transaction:
`END_TURN → SELF Speed +1`.

No Battle Core change was required. Real battle tests prove +1 after turn one, +2 after turn two, and exactly one ability event per completed turn.

### Shed Skin
Pinned source is version-sensitive:
- current prose: 33% cure chance after each turn;
- Black/White history: 30%;
- Diamond/Pearl history: 33%.

Decision: **DATA_ONLY** until ability runtime contracts become version-aware. No universal probability is chosen.

### Poison Heal
Pinned source requires poison to heal 1/8 max HP **instead of** causing poison damage, including bad poison.

Current end-turn order is:
1. `StatusSystem.process_end_turn()` applies residual;
2. KO handling;
3. END_TURN ability/item triggers.

A simple heal trigger would therefore be false semantics. Real battle tests prove a Poison Heal holder currently takes the same poison residual as a plain control.

Decision: **DATA_ONLY** until poison residual has an ability-aware replacement/suppression path.

## #89 architecture
No new Battle Core primitive and no changes to `TurnExecutor` or `StatusSystem`.

Only executable runtime change:
- register Speed Boost with existing END_TURN + MODIFY_STAT_STAGE semantics.

Shed Skin / Poison Heal receive provenance guards and negative regressions only.

## #89 exact artifact drift
Certified #88 final tested artifact → #89 engineering tested artifact:
- raw: exactly `speed_boost.classification: DATA_ONLY → RUNTIME_SUPPORTED`;
- normalized: exactly the same one-field change;
- RUNTIME_SUPPORTED set adds exactly `speed_boost`;
- DATA_ONLY set removes exactly `speed_boost`;
- PARTIAL_RUNTIME set unchanged;
- all other abilities unchanged;
- Pokémon/species, moves/effects, items/statuses, learnsets/evolutions, types/stats unchanged;
- manifest/forms/auxiliary unchanged;
- `pokeapi_v3_audit.json` changes only runtime/data-only counts;
- `import_time_ms 515 → 511 ms` is non-semantic timing noise.

## Ability coverage after #89 engineering
- RUNTIME_SUPPORTED: **19**
- PARTIAL_RUNTIME: **14**
- DATA_ONLY: **340**
- total: **373**.

## Important current blockers
Newly pinned:
- Shed Skin: version-aware probability semantics.
- Poison Heal: poison residual replacement/suppression.

Existing blockers remain: Water Bubble burn prevention; Dry Skin weather/Water absorption; Guts burn/sleep; Hustle accuracy; contact per-strike/faint-safe policy; Rough Skin/Transistor version-aware values; Water Compaction/Weak Armor hit semantics; move-property metadata; super-effective predicates; Gorilla Tactics numeric provenance/move lock; Steely Spirit numeric/ally provenance.

## Current certification step
Notebook synchronization follows engineering SHA `b161373a70d0ed226259fe01f98b0d5cfcf677ed`.

Before closing #89:
1. engineering → final must change exactly `01`, `04`, `19` notebooks;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #89 without merge;
4. use exact final SHA as next certified baseline.

## Next work after #89
Continue DATA FOUNDATION V3 ability reliability from exact certified #89 final HEAD. Select one bounded source-first subgroup from the remaining **340 DATA_ONLY** records. Prefer complete semantics already expressible with current primitives; negative audit is preferable to speculative architecture. Trainer AI/archetypes remain deferred.
