# NEXT STEPS — LIVE CHECKPOINT

Read immediately after `00_READ_FIRST.md` when recovering context.

## Mandatory continuity rule
Material findings, exceptions, decisions, certification boundaries and deliberate deferrals must be written into the notebooks. Never rely on chat context alone.

## Latest certified baseline
- PR #93 — `audit/data-v3-item-closure-v1`
- Final HEAD `a034a8404d80a13cad25d43eb85c4f84e9fb22bf`
- **18/18 SUCCESS** on exact notebook-bearing HEAD
- closed without merge.

Closed DATA V3 domains:
- Moves: **590 runtime / 71 partial / 246 data-only / 12 unsupported**.
- Abilities: **21 runtime / 14 partial / 338 data-only / 373 total**.
- Items: exact runtime boundary frozen in notebook 23; do not widen before Trainer AI without a systemic reason.

# Current tranche — PR #94 Evolutions V3 closure
- Branch: `audit/data-v3-evolution-closure-v1`
- Parent: certified #93 final `a034a8404d80a13cad25d43eb85c4f84e9fb22bf`
- PR: #94 `DATA V3 — close evolution runtime frontier`
- Engineering SHA: `87a48acc2746ee429cbd6786e6a8adedb1afabeb`
- Engineering result: **18/18 SUCCESS**
- DATA V3 domain: **557 PASS / 0 FAIL**
- Detailed notebook: `docs/notebooks/24_DATA_V3_EVOLUTION_CLOSURE.md`.

## #94 result — honest evolution boundary
Canonical DATA V3 preserves exactly **554 evolution records** with **165 conditioned records** and zero broken target/item references.

The old runtime overclaimed support by ignoring preserved `conditions` while executing level/item/trade triggers. That could incorrectly turn real Pokémon requirements such as friendship, time, gender, known move, held trade item, form/region, location, rain or party state into weaker invented rules.

Correction is deliberately bounded:
- canonical exotic trigger IDs use underscores and classify `UNSUPPORTED` when no runtime path exists;
- `level_up`, `use_item`, `trade` are executable only when their full preserved condition set is runtime-compatible;
- empty conditions are compatible;
- exactly seven records with sole redundant `base_form == current source species` remain executable;
- every other conditioned record is `DATA_ONLY`;
- `evolution_candidates()` now returns only `RUNTIME_SUPPORTED` records.

Exact corrected classification:
- **391 RUNTIME_SUPPORTED**
- **149 DATA_ONLY**
- **14 UNSUPPORTED**
- **0 PARTIAL**
- **554 total**.

No friendship/time/location/form/trade-item/party/move-use subsystem was invented merely to raise coverage.

## Exact #93 final → #94 engineering artifact
Compared:
- #93 final run `33513512710`, artifact `9802641046`, head `a034a840...`
- #94 engineering run `33515258905`, artifact `9803339060`, head `87a48acc...`.

Both artifacts contain the same **15 files**.

Canonical outputs are identical:
- raw dataset;
- normalized dataset;
- manifest;
- forms policy report;
- unsupported mechanics report;
- PokeAPI V3 audit;
- auxiliary report.

Only `import_summary.json` timing changes:
- `import_time_ms 508 → 491 ms`.

Expected test delta:
- DATA V3 domain **546 → 557 PASS / 0 FAIL** from 11 Evolutions V3 closure checks.

No canonical data drift exists.

## Current certification step
Engineering and artifact comparison are complete.

Before closing #94:
1. engineering → final must affect only `01_PROJECT_STATE.md`, `04_NEXT_STEPS.md`, `24_DATA_V3_EVOLUTION_CLOSURE.md`;
2. require **18/18 SUCCESS** on the exact final notebook-bearing HEAD;
3. close #94 without merge;
4. use that exact final SHA as the parent of final end-to-end DATA V3 certification.

## Exact next work after #94 closure
Proceed in this order:
1. **final end-to-end DATA V3 certification** — one consolidated verification of immutable source provenance, canonical counts, frozen domain boundaries, references, artifacts and CI.
2. return to **Trainer AI / trainer systems**.

Do not reopen Moves, Abilities, Items or Evolutions merely to increase support counters unless a real regression or a newly implemented subsystem invalidates a frozen boundary.

## Stop condition
Any focal/regression failure stops the tranche until root cause is fixed and rerun.
