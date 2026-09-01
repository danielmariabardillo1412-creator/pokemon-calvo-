# PROJECT STATE NOTEBOOK

## Purpose / authority
Fast recovery for engineering work. GitHub commits, PR state, CI, immutable source and tested artifacts override this notebook on conflict.

## Mandatory continuity rule
Every material discovery, exception, correction, architectural decision, certification boundary or deliberate deferral must be written into the project notebooks. Chat context is never the sole source of continuity.

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
- 1,025 species
- 326 forms
- 18 runtime types
- 919 runtime moves
- 373 abilities
- 2,222 items
- 61,102 learnset entries
- 554 evolutions
- 0 broken refs
- 0 rejected definitions
- 18 XD Shadow moves explicitly excluded.

Pipeline:
`snapshot → V3 adapter → narrow semantic audit layers → raw JSON → Godot DataImporter → normalized data → runtime`.

## Closed DATA V3 milestones
### Move Effects V3
- RUNTIME_SUPPORTED: **590**
- PARTIAL_RUNTIME: **71**
- DATA_ONLY: **246**
- UNSUPPORTED: **12**
- DATA_ONLY moves with executable `effect_specs`: **0**.

### Ability V3 — certified closure #92
- PR #92 `DATA V3 — close ability runtime frontier`
- final HEAD `73dc4dced11804d762182a5017389bea77208aa7`
- **18/18 SUCCESS**, closed without merge.
- final coverage: **21 RUNTIME_SUPPORTED / 14 PARTIAL_RUNTIME / 338 DATA_ONLY / 373 total**.
- Remaining DATA_ONLY frontier is frozen into documented blocker families; do not resume ability micro-tranches merely to increase counters.
- Detailed closure: `docs/notebooks/22_DATA_V3_ABILITY_CLOSURE.md`.

## Current tranche — PR #93 Items V3 closure
- Branch: `audit/data-v3-item-closure-v1`
- Parent: certified #92 final `73dc4dced11804d762182a5017389bea77208aa7`
- PR: #93 `DATA V3 — close item runtime frontier`
- Engineering SHA: `cf2d3fd8f5eea88e6310fec8886e5611938465ae`
- Engineering result: **18/18 SUCCESS**
- DATA V3 domain: **546 PASS / 0 FAIL**
- detailed notebook: `docs/notebooks/23_DATA_V3_ITEM_CLOSURE.md`.

## #93 Items V3 boundary
Canonical DATA V3 preserves exactly **2,222 items**. Item records are metadata-only:
`id · display_name · description · category`.

They do not carry move/ability-style runtime classifications. Executable item support is an explicit Battle Core registry contract.

Exact runtime surfaces:
- held items: `leftovers`, `sitrus_berry`;
- trainer bag items: `potion`, `super_potion`, `hyper_potion`, `max_potion`, `full_restore`.

Closure suite proves:
- exactly 2,222 canonical item records and unique IDs;
- exact metadata-only schema;
- exact held and trainer-bag runtime frontiers;
- every runtime item ID exists canonically in DATA V3;
- Calvo V1 trainer healing contract is exactly `20 / 60 / 120 / full / full+status`;
- Oran Berry remains canonical but deliberately unmapped/deferred.

## Super/Hyper Potion isolated metadata discrepancy
The immutable PokeAPI snapshot keeps legacy English `effect_entries`:
- Super Potion: **50 HP**;
- Hyper Potion: **200 HP**.

Versioned flavor entries move to **60 HP / 120 HP** from Sun/Moon onward. Trainer AI / Battle Core already uses the explicit Calvo V1 modern contract 60/120.

Decision: this is an isolated metadata-version discrepancy, not a Battle Core bug and not a reason to open a general version-policy subsystem during Items V3 closure.

Architectural rule:
**DATA V3 descriptive/historical metadata is not an executable battle contract. Battle Core defines Calvo V1 runtime semantics unless a future explicit version-policy layer deliberately changes that rule.**

## Oran Berry decision
Source semantics are clean: `HP <= 1/2 → heal 10 HP → consume` and existing primitives could express it.

Decision: deliberately defer runtime registration. Adding one easy berry does not close a systemic family and would reopen held-item scope. Revisit when held-item selection/loadouts are intentionally reopened.

## #92 final → #93 engineering artifact comparison
Certified #92 final DATA V3 artifact:
- head `73dc4dced11804d762182a5017389bea77208aa7`
- run `33510555305`
- artifact `9801468899`.

#93 engineering DATA V3 artifact:
- head `cf2d3fd8f5eea88e6310fec8886e5611938465ae`
- run `33512679014`
- artifact `9802318978`.

Both artifacts contain the same **15-file output set**.

Canonically identical:
- raw `pokemon_api.json`;
- normalized `pokemon_api.json`;
- manifest;
- forms policy report;
- unsupported mechanics report;
- PokeAPI V3 audit report;
- auxiliary report.

No species/Pokémon, move/effect, ability, item/status, learnset/evolution, type/stat or report-set drift exists.

Only canonical JSON difference:
- `import_time_ms 529 → 518 ms`, execution timing noise.

Expected log differences:
- DATA V3 domain increases **535 → 546 PASS / 0 FAIL** because of the 11 new Items V3 closure checks;
- Godot import registers one additional test-suite class.

## Current certification step
Engineering is certified and artifact comparison is clean.

Before closing #93:
1. engineering → final must be notebooks-only;
2. synchronized notebooks are `01_PROJECT_STATE.md`, `04_NEXT_STEPS.md`, `23_DATA_V3_ITEM_CLOSURE.md`;
3. require **18/18 SUCCESS** on the exact final notebook-bearing HEAD;
4. close #93 without merge;
5. use exact final SHA as the certified parent for Evolutions V3.

## Next DATA V3 work after #93
1. **Evolutions V3 reliability**
2. **final end-to-end DATA V3 certification**
3. return to **Trainer AI / trainer systems**.

No further Items V3 expansion is required before returning to Trainer AI unless a closure regression exposes a real issue.
