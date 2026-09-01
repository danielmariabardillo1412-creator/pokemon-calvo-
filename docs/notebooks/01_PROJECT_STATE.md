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
- **590 RUNTIME_SUPPORTED / 71 PARTIAL_RUNTIME / 246 DATA_ONLY / 12 UNSUPPORTED**.
- DATA_ONLY moves with executable `effect_specs`: **0**.

### Ability V3 — certified closure #92
- Final HEAD `73dc4dced11804d762182a5017389bea77208aa7`.
- **18/18 SUCCESS**, closed without merge.
- **21 RUNTIME_SUPPORTED / 14 PARTIAL_RUNTIME / 338 DATA_ONLY / 373 total**.
- Detailed closure: `docs/notebooks/22_DATA_V3_ABILITY_CLOSURE.md`.

### Items V3 — certified closure #93
- Final HEAD `a034a8404d80a13cad25d43eb85c4f84e9fb22bf`.
- **18/18 SUCCESS**, closed without merge.
- DATA V3 domain: **546 PASS / 0 FAIL**.
- Exact held runtime: `leftovers`, `sitrus_berry`.
- Exact trainer bag runtime: `potion`, `super_potion`, `hyper_potion`, `max_potion`, `full_restore`.
- Calvo V1 healing contract: `20 / 60 / 120 / full / full+status`.
- Super/Hyper legacy 50/200 description text is historical metadata only and must not redefine runtime 60/120.
- Oran Berry is canonical but deliberately deferred.
- Detailed closure: `docs/notebooks/23_DATA_V3_ITEM_CLOSURE.md`.

## Current tranche — PR #94 Evolutions V3 closure
- Branch: `audit/data-v3-evolution-closure-v1`.
- Parent: certified #93 final `a034a8404d80a13cad25d43eb85c4f84e9fb22bf`.
- PR: #94 `DATA V3 — close evolution runtime frontier`.
- Engineering SHA: `87a48acc2746ee429cbd6786e6a8adedb1afabeb`.
- Engineering result: **18/18 SUCCESS**.
- DATA V3 domain: **557 PASS / 0 FAIL**.
- Detailed notebook: `docs/notebooks/24_DATA_V3_EVOLUTION_CLOSURE.md`.

## #94 evolution reliability finding
DATA V3 preserves exactly **554 evolution records**, of which **165** carry nonempty `conditions`.

The prior runtime overclaimed support because it:
- classified all `level_up`, valid `use_item` and `trade` records as executable;
- evaluated only level, direct item and a boolean trade flag;
- ignored preserved conditions such as friendship, time, gender, known move, held trade item, region/form, location, rain, party state and later-game special requirements;
- allowed DATA_ONLY records under known triggers to pass through candidate evaluation.

Consequence: real Pokémon evolution rules could silently degrade into weaker invented rules. This is forbidden.

A second bug used hyphenated unsupported-trigger constants while canonical DATA V3 uses underscores, producing false coverage buckets.

## Bounded Evolutions V3 correction
No broad evolution-condition subsystem was added.

`EvolutionSystem` now:
1. uses exact canonical underscore trigger IDs;
2. marks exotic triggers with no runtime path `UNSUPPORTED`;
3. allows `level_up`, `use_item`, `trade` to be runtime-supported only when preserved conditions are actually compatible with current runtime context;
4. treats empty conditions as compatible;
5. permits exactly seven source-backed records whose sole condition is redundant `base_form == current source species`;
6. keeps every other conditioned record `DATA_ONLY`;
7. exposes only `RUNTIME_SUPPORTED` records from `evolution_candidates()`;
8. requires valid nonempty item references for `use_item`.

Exact corrected boundary:
- **391 RUNTIME_SUPPORTED**
- **149 DATA_ONLY**
- **14 UNSUPPORTED**
- **0 PARTIAL**
- **554 total**.

Reference integrity:
- broken target-species references: **0**;
- broken/missing `use_item` item references: **0**.

The closure suite adds **11 checks** freezing exact count, trigger partition, condition inventory, reference integrity, exact support boundary, exotic-trigger classification, seven redundant base-form exceptions and candidate gating.

## #93 final → #94 engineering artifact comparison
Certified #93 final DATA V3 artifact:
- head `a034a8404d80a13cad25d43eb85c4f84e9fb22bf`
- run `33513512710`
- artifact `9802641046`.

#94 engineering DATA V3 artifact:
- head `87a48acc2746ee429cbd6786e6a8adedb1afabeb`
- run `33515258905`
- artifact `9803339060`.

Both artifacts contain the same **15 files**.

Byte-identical canonical outputs:
- raw `pokemon_api.json`;
- normalized `pokemon_api.json`;
- manifest;
- forms policy report;
- unsupported mechanics report;
- PokeAPI V3 audit report;
- auxiliary report.

`import_summary.json` is canonically identical except execution timing:
- `import_time_ms 508 → 491 ms`.

Expected log delta:
- DATA V3 domain **546 → 557 PASS / 0 FAIL** from the 11 new Evolutions V3 closure checks.
- runtime/check logs are otherwise unchanged.

No canonical DATA V3 drift exists.

## Current certification step
Engineering is certified and artifact comparison is clean.

Before closing #94:
1. engineering → final must change only `01_PROJECT_STATE.md`, `04_NEXT_STEPS.md`, `24_DATA_V3_EVOLUTION_CLOSURE.md`;
2. require **18/18 SUCCESS** on the exact final notebook-bearing HEAD;
3. close #94 without merge;
4. use that exact final SHA as the parent for the final end-to-end DATA V3 certification.

## Next DATA V3 work after #94
1. **final end-to-end DATA V3 certification**
2. return to **Trainer AI / trainer systems**.

Do not reopen Moves, Abilities, Items or Evolutions merely to increase counters unless a real regression or newly available subsystem invalidates a frozen boundary.
