# NEXT STEPS — LIVE CHECKPOINT

Read immediately after `00_READ_FIRST.md` when recovering context.

## Mandatory continuity rule
Material findings, exceptions, decisions, certification boundaries and deliberate deferrals must be written into the notebooks. Never rely on chat context alone.

## Latest certified baseline
- PR #92 — `audit/data-v3-ability-closure-v1`
- Final HEAD `73dc4dced11804d762182a5017389bea77208aa7`
- **18/18 SUCCESS** on exact notebook-bearing HEAD
- closed without merge.

Move Effects V3 remains closed:
- **590 runtime / 71 partial / 246 data-only / 12 unsupported**
- DATA_ONLY moves with executable `effect_specs`: **0**.

Ability V3 is closed:
- **21 RUNTIME_SUPPORTED / 14 PARTIAL_RUNTIME / 338 DATA_ONLY / 373 total**.
- Do not resume ability micro-tranches merely to increase support count.

# Current tranche — PR #93 Items V3 closure
- Branch: `audit/data-v3-item-closure-v1`
- Parent: certified #92 final `73dc4dced11804d762182a5017389bea77208aa7`
- PR: #93 `DATA V3 — close item runtime frontier`
- Engineering SHA: `cf2d3fd8f5eea88e6310fec8886e5611938465ae`
- Engineering result: **18/18 SUCCESS**
- DATA V3 domain: **546 PASS / 0 FAIL**
- Detailed notebook: `docs/notebooks/23_DATA_V3_ITEM_CLOSURE.md`.

## #93 result — bounded Items V3 frontier
DATA V3 preserves exactly **2,222 canonical items** with metadata-only schema:
`id · display_name · description · category`.

Exact executable surfaces are intentionally separate:
- held: `leftovers`, `sitrus_berry`;
- trainer bag: `potion`, `super_potion`, `hyper_potion`, `max_potion`, `full_restore`.

The closure suite freezes:
- exact canonical count and unique IDs;
- exact metadata schema;
- exact runtime frontiers;
- every runtime ID must exist in DATA V3;
- Calvo V1 trainer healing contract `20 / 60 / 120 / full / full+status`;
- Oran Berry remains canonical but deliberately unmapped/deferred.

### Super/Hyper Potion isolated discrepancy
PokeAPI `effect_entries` preserve legacy **50 / 200 HP**, while versioned flavor entries use **60 / 120 HP** from Sun/Moon onward. Battle Core already uses the explicit Calvo V1 modern contract 60/120.

Decision: treat this as bounded historical metadata, not executable semantics and not a reason to build a general version-policy subsystem.

Rule: **DATA V3 descriptive/historical metadata must never silently redefine Battle Core execution.**

### Oran Berry
Mechanically compatible (`<= 1/2 HP → +10 HP → consume`) but deliberately deferred until held-item selection/loadouts are reopened. Do not widen Items V3 merely because one extra berry is easy.

## Exact #92 final → #93 engineering artifact
Compared:
- #92 final run `33510555305`, artifact `9801468899`, head `73dc4dce...`
- #93 engineering run `33512679014`, artifact `9802318978`, head `cf2d3fd8...`.

Both contain the same **15 files**.

Canonical outputs are identical except:
- `import_time_ms 529 → 518 ms` timing noise.

Expected test/log delta:
- DATA V3 domain **535 → 546 PASS / 0 FAIL** from 11 new closure checks;
- one extra Godot global test-suite class.

No canonical data drift exists.

## Current certification step
Engineering and artifact comparison are complete.

Before closing #93:
1. final synchronization must affect only `01_PROJECT_STATE.md`, `04_NEXT_STEPS.md`, `23_DATA_V3_ITEM_CLOSURE.md` after the certified engineering state;
2. require **18/18 SUCCESS** on the exact final notebook-bearing HEAD;
3. close #93 without merge;
4. use that exact final SHA as the parent of Evolutions V3.

## Exact next work after #93 closure
Proceed in this order:
1. **Evolutions V3 reliability** — verify references/conditions and freeze the real supported data boundary without opening unrelated progression architecture.
2. **final end-to-end DATA V3 certification** — consolidated artifact/CI/notebook closure.
3. return to **Trainer AI / trainer systems**.

Items V3 should not be reopened before Trainer AI unless a real regression or source-backed systemic gap invalidates the frozen boundary.

## Stop condition
Any focal/regression failure stops the tranche until root cause is fixed and rerun.
