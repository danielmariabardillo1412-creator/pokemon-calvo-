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
- PR: #95 `DATA V3 — final end-to-end certification`.
- Valid engineering SHA: `9e17f903f229b6efc0044608dde66aba4783ef9c`.

## Mandatory continuity rule
Every material discovery, exception, correction, architectural decision, certification boundary or deliberate deferral must be written into project notebooks. Chat context is never the sole source of continuity.

## Goal
Certify DATA Foundation V3 end-to-end as a stable data/runtime boundary before returning to Trainer AI. This tranche adds no new Pokémon mechanics.

## Frozen domain boundaries entering this tranche
### Moves V3
- RUNTIME_SUPPORTED: **590**
- PARTIAL_RUNTIME: **71**
- DATA_ONLY: **246**
- UNSUPPORTED: **12**
- total: **919**
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
- healing contract: `20 / 60 / 120 / full / full+status`
- legacy Super/Hyper description values 50/200 are historical metadata only.

### Evolutions V3
- RUNTIME_SUPPORTED: **391**
- DATA_ONLY: **149**
- UNSUPPORTED: **14**
- PARTIAL: **0**
- total: **554**
- conditioned records: **165**
- broken target/item references: **0**.

## Canonical structural contract
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
Immutable authority:
- snapshot branch `data/pokeapi-v2-snapshot`
- snapshot commit `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`
- API tree `8349ea1ce75716897fe96e02a15950d19edba6c3`
- schema tree `02e031e1928d7e9456bf6f7486daacc4b8946c84`
- `data/api/v2` and `data/schema/v2` read-only.

Pipeline:
`snapshot → V3 adapter → narrow semantic audit layers → raw JSON → Godot DataImporter → normalized data → runtime`.

## Final end-to-end closure suite
`DataFoundationV3EndToEndClosureTestSuite` adds exactly **10 checks**:
1. exact structural contract;
2. exact immutable source provenance;
3. raw ↔ normalized identity-set equality;
4. cross-domain reference closure and exact learnset/evolution totals;
5. frozen Moves V3 boundary;
6. frozen Abilities V3 boundary;
7. frozen Evolutions V3 boundary plus DATA_ONLY conditioned non-execution;
8. exact Items V3 runtime surfaces;
9. no DATA_ONLY move/ability hidden execution;
10. exact Shadow exclusion and report totals.

## Engineering attempt #1 — stopped correctly on GDScript typing failure
HEAD `f9a9b4b11e1aa14447c447d0f35a37e98da6797e`:
- **17/18 SUCCESS**;
- only DATA Foundation V3 failed.

Root cause:
- GDScript 4.7 could not infer the type of a compound boolean assembled from `Variant`-typed JSON values;
- the new global class failed to compile, runner instantiation failed, then the domain job timed out.

Correction:
- explicitly type closure boolean variables as `bool`;
- no data, adapter, runtime or Pokémon semantic change;
- no invariant weakened.

## Preflight finding #2 — import-summary phase ordering
The first attempt artifact showed `import_summary.json` is created only after the domain phase by `DataImporter`.

The initial suite incorrectly depended on that later artifact during pre-normalization domain tests.

Correction:
- pre-normalization domain checks derive structural totals from regenerated raw DATA and adapter reports;
- manifest/provenance checks use the canonical manifest and checked-in normalized manifest available at that stage;
- post-import `broken_references=0` and `rejected=0` remain mandatory and are verified from the DataImporter step/tested artifact;
- invariants were moved to their authoritative pipeline phase, not removed.

This was a certification-harness ordering defect, not a Pokémon/data defect.

## Valid engineering certification
Valid engineering HEAD:
`9e17f903f229b6efc0044608dde66aba4783ef9c`

Result:
- **18/18 workflows SUCCESS**;
- DATA Foundation V3: **567 PASS / 0 FAIL**;
- Spanish/type/runtime regression: **298 PASS / 0 FAIL**;
- all ten new end-to-end checks PASS;
- Godot 4.7 regression SUCCESS;
- all Trainer AI regression workflows SUCCESS.

Post-DataImporter exact evidence:
- species=1025
- forms=326
- types=18
- moves=919
- abilities=373
- items=2222
- learnset_entries=61102
- evolutions=554
- broken_references=0
- rejected=0.

## Exact #94 final → #95 engineering artifact comparison
Certified #94 final:
- head `be5b4bde75252afa2ef355b2e7392d0884c42d7a`
- DATA run `33526438810`
- artifact `9807934801`.

#95 valid engineering:
- head `9e17f903f229b6efc0044608dde66aba4783ef9c`
- DATA run `33527719967`
- artifact `9808446505`.

Both artifacts contain the same **15 files**.

### Byte-identical 11/15
The following are byte-identical:
- `data/raw/pokemon_api.json`
- `data/normalized/pokemon_api.json`
- `data/manifests/pokemon_api_manifest.json`
- `data/reports/forms_policy_report.json`
- `data/reports/unsupported_mechanics.json`
- `data/reports/pokeapi_v3_audit.json`
- `data/reports/pokeapi_v3_auxiliary.json`
- `data-v3-check.log`
- `data-v3-generate.log`
- `data-v3-godot-version.log`
- `data-v3-runtime-test.log`.

### Expected differences only
1. `data-v3-domain-test.log`
   - adds exactly the 10 final end-to-end PASS checks;
   - result **557 → 567 PASS / 0 FAIL**.
2. `data-v3-godot-import.log`
   - registered global classes **279 → 280** because the new closure test suite adds one class;
   - remaining differences are only progress-percentage position shifts.
3. `data-v3-normalize.log`
   - only `import_time_ms 523 → 507`.
4. `data/reports/import_summary.json`
   - only `import_time_ms 523 → 507`.

Therefore raw data, normalized data, manifest, reports, provenance, adapter output and runtime regression output are unchanged. **No canonical DATA V3 drift exists.**

## Closure meaning
At valid engineering SHA, DATA Foundation V3 is end-to-end closed at an honest capability boundary. “Closed” does not mean every Pokémon mechanic is runtime-supported; it means:
- immutable source provenance is frozen;
- canonical data and cross-domain references are coherent;
- runtime-supported/partial/data-only/unsupported boundaries are explicit and regression-tested;
- unsupported semantics cannot silently execute as weaker invented Pokémon rules;
- future work can return to Trainer AI without another open-ended DATA audit.

## Current certification step
Only notebook-bearing final certification remains.

Before closing #95:
1. engineering → final must change only `01_PROJECT_STATE.md`, `04_NEXT_STEPS.md`, `25_DATA_V3_END_TO_END_CLOSURE.md`;
2. require **18/18 SUCCESS** on the exact final notebook-bearing HEAD;
3. close #95 without merge;
4. exact final #95 SHA becomes the certified DATA V3 baseline.

## Next work after #95
**Return directly to Trainer AI / trainer systems.**

Do not open another DATA V3 tranche merely to increase coverage counts. Reopen a frozen domain only if a real regression or newly implemented subsystem materially invalidates a documented blocker/boundary.

## Safety
- no manual edits to generated JSON;
- no new move/ability/item/evolution mechanics in this closure tranche;
- no source inference from names when immutable data is available;
- resolve real semantic discrepancies against immutable/reliable Pokémon sources, never project invention;
- any focal/regression failure stops certification until root cause is fixed;
- final closure is a stable tested boundary, not fictional 100% runtime support.
