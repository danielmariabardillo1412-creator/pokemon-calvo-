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

All entries above: **18/18 SUCCESS on exact final notebook-bearing HEAD and closed without merge**.

## Move Effects V3 closed milestone
- RUNTIME_SUPPORTED: **590**
- PARTIAL_RUNTIME: **71**
- DATA_ONLY: **246**
- UNSUPPORTED: **12**
- DATA_ONLY with executable `effect_specs`: **0**.

## Latest certified baseline — PR #89
Certified final HEAD:
`407ad8f27d13a79b09c367aac2f6ae0c1ef801ef`

Certified ability coverage:
- RUNTIME_SUPPORTED: **19**
- PARTIAL_RUNTIME: **14**
- DATA_ONLY: **340**
- total: **373**.

# Current tranche — PR #90 Opponent end-turn blockers
- Branch: `audit/data-v3-ability-end-turn-opponent-v1`.
- Exact parent: certified #89 final `407ad8f27d13a79b09c367aac2f6ae0c1ef801ef`.
- PR: #90 `DATA V3 — audit opponent end-turn ability blockers`.
- Engineering SHA: `52fafcc035dd46824bf9f0f6239cc93363981998`.
- Engineering result: **18/18 SUCCESS**.
- DATA Foundation V3: **516 PASS / 0 FAIL**.
- Spanish/type/runtime regression: **298 PASS / 0 FAIL**.
- Normalized import: 0 broken refs / 0 rejected definitions.
- Detailed notebook: `docs/notebooks/20_DATA_V3_ABILITY_END_TURN_OPPONENT.md`.

## #90 result — deliberately negative audit
No production/runtime file changed. No adapter change. No registry entry. No ability classification moved.

### Bad Dreams → DATA_ONLY
Pinned Generation IV source requires opposing Pokémon to lose 1/8 max HP after each turn **while they are asleep**.

Battle Core already has the effect primitive needed (`MAX_HP_DAMAGE` against `OPPONENT`), but the only persistent-status trigger predicate, `required_persistent_status_ids`, is evaluated against the **ability owner** in `BattleTriggerSystem.conditions_met()`.

END_TURN routing supplies owner + opponent, but conditions still receive only the owner. Therefore the engine cannot currently express “opponent is asleep”. Using the existing predicate would instead mean “ability owner is asleep”, which is false semantics.

Decision: remain **DATA_ONLY**. Do not approximate with unconditional 1/8 damage and do not add a target-status predicate solely for one ability.

Real-battle regression: Bad Dreams holder versus a sleeping opponent produces no false ability event and no Bad Dreams damage. A direct predicate probe also proves awake owner is rejected while sleeping owner is accepted, confirming owner-local semantics.

### Rain Dish → DATA_ONLY
Pinned Generation III source requires healing 1/16 max HP after each turn during rain. Repository-wide search found no battle weather state/condition surface.

Decision: remain **DATA_ONLY**. Do not install an unconditional heal and do not add weather architecture solely for this audit.

### Ice Body → DATA_ONLY
Pinned Generation IV source requires healing 1/16 max HP after each turn during hail and immunity to hail damage regardless of type. Current battle state has neither weather state nor hail residual transaction.

Decision: remain **DATA_ONLY**.

## #90 tests
New `DataFoundationV3AbilityEndTurnOpponentTestSuite` adds seven regressions:
1. Bad Dreams immutable source contract;
2. Rain Dish immutable source contract;
3. Ice Body immutable source contract;
4. all three stay DATA_ONLY with no END_TURN trigger;
5. existing persistent-status predicate is owner-local;
6. sleeping-target Bad Dreams real-battle gap remains explicit;
7. exact ability partition remains 19 / 14 / 340.

DATA V3 domain increases from #89's 509 checks to **516 PASS / 0 FAIL**.

## #90 exact artifact comparison
Certified #89 final tested artifact:
- run `33501387360`;
- artifact `9797865183`;
- head `407ad8f27d13a79b09c367aac2f6ae0c1ef801ef`.

#90 engineering tested artifact:
- run `33502577117`;
- artifact `9798322866`;
- head `52fafcc035dd46824bf9f0f6239cc93363981998`.

Both artifacts contain the same 15 files.

Semantically identical:
- raw `pokemon_api.json`;
- normalized `pokemon_api.json`;
- manifest;
- forms policy report;
- unsupported mechanics report;
- PokeAPI V3 audit report;
- auxiliary report.

No species/Pokémon, move/effect, ability classification, item/status, learnset/evolution, type/stat or report-set change exists.

Only difference: `import_time_ms 513 → 509 ms`, non-semantic execution timing noise.

## Ability coverage after #90 engineering
Unchanged from certified #89:
- RUNTIME_SUPPORTED: **19**
- PARTIAL_RUNTIME: **14**
- DATA_ONLY: **340**
- total: **373**.

## Important blockers after #90
Newly pinned:
- Bad Dreams: needs target/opponent persistent-status predicate on END_TURN or another shared target-state condition mechanism.
- Rain Dish: needs weather state + rain predicate.
- Ice Body: needs weather state + hail predicate + hail residual immunity.

Existing blockers remain: Shed Skin version-aware probability; Poison Heal residual replacement; Water Bubble burn prevention; Dry Skin weather/Water absorption; Guts burn/sleep; Hustle accuracy; contact per-strike/faint-safe policy; Rough Skin/Transistor version-aware values; Water Compaction/Weak Armor hit semantics; move-property metadata; super-effective predicates; Gorilla Tactics numeric provenance/move lock; Steely Spirit numeric/ally provenance.

## Current certification step
Notebook synchronization follows engineering SHA `52fafcc035dd46824bf9f0f6239cc93363981998`.

Before closing #90:
1. engineering → final must change exactly `01`, `04`, `20` notebooks;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #90 without merge;
4. use exact final SHA as next certified baseline.

Do not make a post-close commit solely to record closure; GitHub PR state is authoritative.

## Next work after #90
Continue DATA FOUNDATION V3 ability reliability from exact certified #90 final HEAD. Do **not** implement weather merely because Rain Dish/Ice Body exposed it, and do not add target-status solely for Bad Dreams. First identify a bounded source-backed family that genuinely reuses an existing primitive or demonstrates that a shared missing condition is justified by multiple abilities. A negative audit remains preferable to speculative architecture. Trainer AI/archetypes remain deferred.
