# DATA V3 END-TO-END CERTIFICATION / CLOSURE — V1

## Purpose
Final DATA Foundation V3 certification checkpoint after bounded closure of Moves, Abilities, Items and Evolutions.

## Certified parent
- PR #94: `DATA V3 — close evolution runtime frontier`.
- Certified final HEAD: `be5b4bde75252afa2ef355b2e7392d0884c42d7a`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Evolutions V3 final boundary: **391 RUNTIME_SUPPORTED / 149 DATA_ONLY / 14 UNSUPPORTED / 0 PARTIAL / 554 total**.

## Current tranche
- Branch: `audit/data-v3-end-to-end-closure-v1`.
- Exact parent: certified #94 final `be5b4bde75252afa2ef355b2e7392d0884c42d7a`.

## Mandatory continuity rule
Every material discovery, exception, correction, architectural decision, certification boundary or deliberate deferral must be written into project notebooks. Chat context is never the sole source of continuity.

## Goal
Certify DATA Foundation V3 end-to-end as a stable data/runtime boundary before returning to Trainer AI. This tranche is not for adding new Pokémon mechanics. It must prove that the immutable source, adapter output, normalized data, runtime capability boundaries and regression surfaces agree with the already-certified domain closures.

## Frozen domain boundaries entering this tranche
### Moves V3
- RUNTIME_SUPPORTED: **590**
- PARTIAL_RUNTIME: **71**
- DATA_ONLY: **246**
- UNSUPPORTED: **12**
- total runtime move records: **919**
- DATA_ONLY moves with executable effect specs: **0**.

### Abilities V3
- RUNTIME_SUPPORTED: **21**
- PARTIAL_RUNTIME: **14**
- DATA_ONLY: **338**
- total: **373**.

### Items V3
- canonical items: **2,222**
- held runtime: `leftovers`, `sitrus_berry`
- trainer bag runtime: `potion`, `super_potion`, `hyper_potion`, `max_potion`, `full_restore`
- trainer healing contract: `20 / 60 / 120 / full / full+status`
- legacy Super/Hyper description metadata must not redefine runtime semantics.

### Evolutions V3
- RUNTIME_SUPPORTED: **391**
- DATA_ONLY: **149**
- UNSUPPORTED: **14**
- PARTIAL: **0**
- total: **554**
- conditioned records: **165**
- broken target/item references: **0**.

## Canonical structural contract
The final end-to-end certification must freeze at least:
- species: **1,025**
- forms: **326**
- runtime types: **18**
- moves: **919**
- abilities: **373**
- items: **2,222**
- learnset entries: **61,102**
- evolutions: **554**
- broken references: **0**
- rejected definitions: **0**
- XD Shadow moves explicitly excluded: **18**.

## Source/provenance contract
Immutable authority remains:
- snapshot branch `data/pokeapi-v2-snapshot`
- snapshot commit `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`
- API tree `8349ea1ce75716897fe96e02a15950d19edba6c3`
- schema tree `02e031e1928d7e9456bf6f7486daacc4b8946c84`
- `data/api/v2` and `data/schema/v2` remain read-only.

Pipeline contract:
`snapshot → V3 adapter → narrow semantic audit layers → raw JSON → Godot DataImporter → normalized data → runtime`.

## Closure strategy
Do not reopen domain mechanics. Add a final deterministic closure suite/report only where it materially protects cross-domain invariants not already frozen by domain suites.

The end-to-end closure should prove:
1. canonical structural totals remain exact;
2. source commit/tree/schema provenance is exact;
3. raw and normalized datasets contain the same canonical identity sets across species/moves/abilities/items;
4. all cross-domain references used by runtime remain valid;
5. frozen move/ability/evolution coverage totals remain exact;
6. exact Items V3 runtime surfaces remain unchanged;
7. no DATA_ONLY move or ability silently gains executable mappings;
8. no conditioned DATA_ONLY evolution silently becomes executable;
9. reports/manifest identify the same dataset/ruleset/source authority;
10. CI regenerates the same canonical artifact as certified #94 apart from execution timing noise.

## Certification workflow
1. audit existing V3 tests/reports to avoid duplicating already-certified invariants;
2. add only missing cross-domain end-to-end closure guards;
3. open PR from exact certified #94 final;
4. require 18/18 engineering;
5. compare tested DATA V3 artifact byte/canonical output against #94 final;
6. synchronize `01_PROJECT_STATE.md`, `04_NEXT_STEPS.md`, `25_DATA_V3_END_TO_END_CLOSURE.md` only;
7. verify engineering → final is notebooks-only;
8. require second 18/18 on exact final notebook-bearing HEAD;
9. close without merge;
10. return to Trainer AI using the exact final SHA as certified DATA V3 baseline.

## Safety
- no manual edits to generated JSON;
- no new move/ability/item/evolution mechanics in this closure tranche;
- no source inference from names when immutable data is available;
- any discrepancy must be resolved against immutable source / reliable Pokémon references rather than project invention;
- any focal or regression failure stops certification until root cause is fixed;
- final closure means stable tested boundary, not fictional 100% runtime support.
