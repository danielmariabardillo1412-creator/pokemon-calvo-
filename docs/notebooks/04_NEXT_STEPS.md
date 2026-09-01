# NEXT STEPS — LIVE CHECKPOINT

Read immediately after `00_READ_FIRST.md` when recovering context.

## Mandatory continuity rule
Material findings, exceptions, decisions, certification boundaries and deliberate deferrals must be written into the notebooks. Never rely on chat context alone.

## Latest certified baseline
- PR #94 — `audit/data-v3-evolution-closure-v1`
- Final HEAD `be5b4bde75252afa2ef355b2e7392d0884c42d7a`
- **18/18 SUCCESS** on exact notebook-bearing HEAD
- closed without merge.

Closed DATA V3 domain boundaries:
- Moves: **590 runtime / 71 partial / 246 data-only / 12 unsupported**.
- Abilities: **21 runtime / 14 partial / 338 data-only**.
- Items: exact held/trainer surfaces frozen in notebook 23.
- Evolutions: **391 runtime / 149 data-only / 14 unsupported / 0 partial**.

# Current tranche — PR #95 final DATA V3 end-to-end certification
- Branch: `audit/data-v3-end-to-end-closure-v1`
- Parent: certified #94 final `be5b4bde75252afa2ef355b2e7392d0884c42d7a`
- PR: #95 `DATA V3 — final end-to-end certification`
- Valid engineering SHA: `9e17f903f229b6efc0044608dde66aba4783ef9c`
- Engineering result: **18/18 SUCCESS**
- DATA V3 domain: **567 PASS / 0 FAIL**
- Spanish/type/runtime regression: **298 PASS / 0 FAIL**
- Detailed notebook: `docs/notebooks/25_DATA_V3_END_TO_END_CLOSURE.md`.

## End-to-end result
The final suite adds exactly **10 cross-domain closure checks** and proves:
- structural totals: 18 types, 1,025 species, 919 moves, 373 abilities, 2,222 items, 61,102 learnset entries, 554 evolutions, 326 forms;
- exact immutable PokeAPI source commit/API tree/schema tree and DATA V3 ruleset;
- raw ↔ normalized identity sets match for types/species/moves/abilities/items;
- cross-domain references are closed with zero broken references;
- Moves boundary remains **590/71/246/12**;
- Abilities boundary remains **21/14/338**;
- Evolutions boundary remains **391/0/149/14**, with conditioned DATA_ONLY records non-executable;
- Items held/trainer runtime surfaces remain exact;
- DATA_ONLY moves/abilities have no hidden execution;
- Shadow exclusion remains exactly **18** and audit/forms report totals remain exact.

Post-DataImporter evidence:
- `broken_references=0`
- `rejected=0`
- learnset_entries=61102
- evolutions=554.

## Engineering harness incidents
Two issues were found during #95 and are fully documented in notebook 25:
1. GDScript Variant-backed bool inference failure in the new test suite;
2. initial test attempted to read `import_summary.json` before the DataImporter phase creates it.

Both were **certification-harness defects only**. No Pokémon mechanic, canonical data, adapter semantics or runtime boundary was changed to resolve them. Invariants were moved to the correct pipeline phase, not weakened.

## Exact #94 final → #95 engineering artifact
Compared:
- #94 final: head `be5b4bde...`, run `33526438810`, artifact `9807934801`;
- #95 engineering: head `9e17f903...`, run `33527719967`, artifact `9808446505`.

Same **15-file** artifact set.

Byte-identical canonical outputs include raw, normalized, manifest, forms, unsupported mechanics, PokeAPI V3 audit and auxiliary reports.

Expected differences only:
- domain log: adds 10 final closure checks, **557 → 567 PASS / 0 FAIL**;
- Godot import log: **279 → 280** registered global classes due to the new test suite, plus percentage-position noise;
- normalization/import summary: only `import_time_ms 523 → 507`.

No canonical DATA V3 drift exists.

## Current certification step
Engineering and artifact comparison are complete. DATA V3 is functionally closed pending the second CI cycle on documentation-bearing HEAD.

Before closing #95:
1. verify engineering → final changed only `01_PROJECT_STATE.md`, `04_NEXT_STEPS.md`, `25_DATA_V3_END_TO_END_CLOSURE.md`;
2. require **18/18 SUCCESS** on the exact final notebook-bearing HEAD;
3. close #95 **without merge**;
4. use exact final #95 SHA as the certified DATA V3 baseline.

## Exact next work after #95 closure
**Return to Trainer AI / trainer systems.**

Do not start another DATA V3 tranche merely to raise support counts. Read the Trainer AI checkpoints and continue from the latest certified Trainer state rather than restarting its design.

## Stop condition
Any focal/regression failure stops the tranche until root cause is fixed and rerun.
