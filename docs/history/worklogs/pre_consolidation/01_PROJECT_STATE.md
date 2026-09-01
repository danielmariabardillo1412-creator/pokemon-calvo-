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

Canonical structural contract:
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

## Closed DATA V3 domain boundaries
### Move Effects V3
- **590 RUNTIME_SUPPORTED / 71 PARTIAL_RUNTIME / 246 DATA_ONLY / 12 UNSUPPORTED**.
- DATA_ONLY moves with executable `effect_specs`: **0**.

### Ability V3 — certified #92
- Final HEAD `73dc4dced11804d762182a5017389bea77208aa7`.
- **18/18 SUCCESS**, closed without merge.
- **21 RUNTIME_SUPPORTED / 14 PARTIAL_RUNTIME / 338 DATA_ONLY / 373 total**.
- Detailed closure: `docs/notebooks/22_DATA_V3_ABILITY_CLOSURE.md`.

### Items V3 — certified #93
- Final HEAD `a034a8404d80a13cad25d43eb85c4f84e9fb22bf`.
- **18/18 SUCCESS**, closed without merge.
- DATA domain **546 PASS / 0 FAIL**.
- Held runtime: `leftovers`, `sitrus_berry`.
- Trainer bag runtime: `potion`, `super_potion`, `hyper_potion`, `max_potion`, `full_restore`.
- Runtime healing contract: `20 / 60 / 120 / full / full+status`.
- Legacy Super/Hyper 50/200 text is historical metadata, not execution semantics.
- Oran Berry deliberately deferred.
- Detailed closure: `docs/notebooks/23_DATA_V3_ITEM_CLOSURE.md`.

### Evolutions V3 — certified #94
- Final HEAD `be5b4bde75252afa2ef355b2e7392d0884c42d7a`.
- **18/18 SUCCESS**, closed without merge.
- DATA domain **557 PASS / 0 FAIL**.
- **391 RUNTIME_SUPPORTED / 149 DATA_ONLY / 14 UNSUPPORTED / 0 PARTIAL / 554 total**.
- Exactly 165 conditioned records are preserved.
- Runtime no longer simplifies unsupported Pokémon evolution conditions into weaker level/item/trade rules.
- Exactly seven sole redundant `base_form == source species` selectors remain executable.
- Detailed closure: `docs/notebooks/24_DATA_V3_EVOLUTION_CLOSURE.md`.

## Current tranche — PR #95 final DATA V3 end-to-end certification
- Branch: `audit/data-v3-end-to-end-closure-v1`.
- Parent: certified #94 final `be5b4bde75252afa2ef355b2e7392d0884c42d7a`.
- PR: #95 `DATA V3 — final end-to-end certification`.
- Valid engineering SHA: `9e17f903f229b6efc0044608dde66aba4783ef9c`.
- Engineering result: **18/18 SUCCESS**.
- DATA V3 domain: **567 PASS / 0 FAIL**.
- Spanish/type/runtime regression: **298 PASS / 0 FAIL**.
- Detailed notebook: `docs/notebooks/25_DATA_V3_END_TO_END_CLOSURE.md`.

## #95 end-to-end closure result
Ten cross-domain checks now freeze:
1. exact canonical structural totals;
2. exact immutable source commit/API tree/schema tree/ruleset provenance;
3. raw ↔ normalized identity-set equality for types/species/moves/abilities/items;
4. zero cross-domain broken references with exact 61,102 learnsets and 554 evolutions;
5. frozen Moves V3 boundary 590/71/246/12;
6. frozen Abilities V3 boundary 21/14/338;
7. frozen Evolutions V3 boundary 391/0/149/14 and conditioned DATA_ONLY non-execution;
8. exact Items V3 held/trainer runtime surfaces;
9. zero hidden executable mappings for DATA_ONLY moves/abilities;
10. exact 18 Shadow exclusions plus audit/forms report totals.

Engineering import is clean:
- species=1025 forms=326 types=18 moves=919 abilities=373 items=2222;
- learnset_entries=61102 evolutions=554;
- broken_references=0 rejected=0.

## #95 engineering incidents — test harness only
Two certification-harness defects were found and recorded before correction:
1. GDScript 4.7 could not infer a compound boolean type from Variant-backed JSON expressions. Fix: explicit `bool` typing; no data/runtime change.
2. The initial suite attempted to read `import_summary.json` before the workflow's DataImporter stage creates it. Fix: pre-normalization invariants use raw/manifest/reports; post-import rejected/broken checks remain verified from the tested artifact. No invariant was weakened.

The first failed attempt therefore did **not** reveal a Pokémon or canonical-data defect.

## #94 final → #95 engineering artifact comparison
Certified #94 final:
- head `be5b4bde75252afa2ef355b2e7392d0884c42d7a`
- run `33526438810`
- artifact `9807934801`.

#95 valid engineering:
- head `9e17f903f229b6efc0044608dde66aba4783ef9c`
- run `33527719967`
- artifact `9808446505`.

Both artifacts contain the same **15 files**.

Exactly **11/15 files are byte-identical**, including:
- raw `pokemon_api.json`;
- normalized `pokemon_api.json`;
- manifest;
- forms policy report;
- unsupported mechanics report;
- PokeAPI V3 audit report;
- auxiliary report;
- adapter check/generate logs, runtime regression log and Godot version log.

Expected differences only:
- `data-v3-domain-test.log`: adds exactly the 10 end-to-end PASS checks, **557 → 567 PASS / 0 FAIL**;
- `data-v3-godot-import.log`: global class registration **279 → 280** because the new closure suite is a new global class, with resulting percentage-position noise only;
- `data-v3-normalize.log`: `import_time_ms 523 → 507`;
- `import_summary.json`: only `import_time_ms 523 → 507` differs.

Canonical data, reports, provenance and runtime regression output are unchanged. **No DATA V3 drift exists.**

## Current certification step
DATA V3 is functionally end-to-end closed at engineering SHA `9e17f903...`; only final notebook-bearing certification remains.

Before closing #95:
1. engineering → final must change only `01_PROJECT_STATE.md`, `04_NEXT_STEPS.md`, `25_DATA_V3_END_TO_END_CLOSURE.md`;
2. require **18/18 SUCCESS** on the exact final notebook-bearing HEAD;
3. close #95 without merge;
4. the exact final #95 SHA becomes the certified DATA V3 baseline.

## Next work after #95
**Return directly to Trainer AI / trainer systems.**

Do not open another DATA tranche merely to increase coverage counters. Reopen a frozen DATA domain only when a real regression or a newly implemented subsystem materially removes a documented blocker.
