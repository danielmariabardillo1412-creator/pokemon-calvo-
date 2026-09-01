# DATA V3 ITEM RELIABILITY / CLOSURE — V1

## Purpose
Operational checkpoint for the bounded Items V3 tranche immediately after certified Ability V3 closure.

## Certified parent
- PR #92: `DATA V3 — close ability runtime frontier`.
- Certified final HEAD: `73dc4dced11804d762182a5017389bea77208aa7`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Ability V3 is CLOSED at **21 RUNTIME_SUPPORTED / 14 PARTIAL_RUNTIME / 338 DATA_ONLY / 373 total**.

## Current tranche
- Branch: `audit/data-v3-item-closure-v1`.
- Exact parent: certified #92 final `73dc4dced11804d762182a5017389bea77208aa7`.
- PR: #93 `DATA V3 — close item runtime frontier`.
- Engineering SHA: `cf2d3fd8f5eea88e6310fec8886e5611938465ae`.
- Engineering result: **18/18 SUCCESS**.
- DATA V3 domain: **546 PASS / 0 FAIL**.

## Goal
Close the DATA V3 item frontier in one bounded tranche if possible. Do not repeat the long ability-by-ability audit.

## Questions
1. What item semantics are preserved in the 2,222 canonical item records?
2. Which **held items** are actually executable in `BattleEffectRegistry` today?
3. Which **trainer bag items** are executable through the separate trainer-item action surface?
4. Do canonical item records have an explicit runtime classification, or is support intentionally a Battle Core registry concern?
5. Is any preserved/non-runtime item silently executable through a hidden mapping?
6. Are there a few high-value source-backed items whose complete semantics already fit existing primitives and materially matter to trainer battles?

## Mandatory continuity rule
Every material discovery, exception, correction, architectural decision, certification boundary, or deliberate deferral found during this tranche must be written into the project notebooks before the tranche is considered closed. Chat context is never the sole source of continuity. If a live discovery changes what the next operator must know, record it here even when the correction itself is small and can be made immediately.

## Live audit findings
### Item schema / execution boundary
- DATA V3 preserves exactly **2,222 canonical item records**.
- Canonical item records contain only `id`, `display_name`, `description`, `category`; unlike moves/abilities they do **not** carry runtime `classification`.
- Runtime semantics therefore remain an explicit Battle Core registry concern rather than something inferred from item presence or description text.
- Held-item runtime and trainer bag-item runtime are intentionally separate surfaces.
- Current held-item frontier: `leftovers`, `sitrus_berry`.
- Current trainer bag frontier: `potion`, `super_potion`, `hyper_potion`, `max_potion`, `full_restore`.

### Super Potion / Hyper Potion historical metadata discrepancy
A real but bounded source/runtime discrepancy was found:
- canonical DATA V3 description generation currently reads immutable PokeAPI `effect_entries` text;
- Super Potion's preserved English `effect_entry` says **50 HP**;
- Hyper Potion's preserved English `effect_entry` says **200 HP**;
- versioned PokeAPI flavor entries change these values to **60 HP** and **120 HP** from Sun/Moon onward;
- Calvo V1 Trainer AI / Battle Core already uses the explicit modern runtime contract **20 / 60 / 120 / full / full+status**.

Decision: this is an **isolated metadata-version discrepancy, not a Battle Core bug and not a reason to open a general version-policy subsystem during Items V3 closure**. The executable Calvo V1 contract remains 60/120. A closure regression ensures legacy descriptive metadata cannot silently redefine runtime healing values.

Architectural rule extracted from the finding:
**DATA V3 descriptive/historical metadata is not an executable battle contract. Battle Core defines Calvo V1 runtime semantics unless a future explicit version-policy layer deliberately changes that rule.**

### Oran Berry
Immutable source semantics are clean and compatible with existing primitives: `HP <= 1/2 -> heal 10 HP -> consume`.

Decision: keep Oran Berry canonical but deliberately **not runtime-registered in this closure tranche**. Adding one easy berry would not close a systemic family and would reopen held-item scope while the project is trying to return to Trainer AI. Revisit when held-item selection/loadouts are intentionally reopened.

## Closure rule
Prefer a tested capability boundary over implementing a general item engine. Items V3 can close when:
- held-item and trainer-item runtime surfaces are inventoried separately;
- canonical references/source provenance remain stable;
- unsupported items cannot acquire hidden executable mappings silently;
- any obvious high-value compatible gaps are either implemented in a small bounded group or explicitly blocked;
- no large lifecycle subsystem (consumption, transfer, choice locking, species/form triggers, weather, etc.) is opened merely to increase coverage.

## Engineering closure suite
`DataFoundationV3ItemClosureTestSuite` freezes the Items V3 boundary with **11 checks**:
- exactly **2,222** canonical items;
- unique canonical IDs;
- exact metadata-only schema;
- nonempty explicit category inventory;
- exact held runtime frontier `leftovers`, `sitrus_berry`;
- exact trainer bag frontier of the five Calvo V1 healing items;
- all runtime IDs exist in canonical DATA V3;
- exact trainer healing contract `20 / 60 / 120 / full`;
- Full Restore = full heal + status cure;
- historical Super/Hyper metadata cannot redefine execution;
- Oran Berry remains canonical but deliberately unmapped/deferred.

Engineering DATA V3 result rises from certified #92's **535 checks** to **546 PASS / 0 FAIL**.

## Engineering CI
Engineering SHA `cf2d3fd8f5eea88e6310fec8886e5611938465ae`:
- **18/18 normal workflows SUCCESS**;
- DATA V3 generation/import/domain/normalization/runtime all green;
- Godot 4.7 suite green;
- Trainer Item Actions and all Trainer AI regression workflows green.

## Exact artifact comparison — certified #92 final → #93 engineering
Certified #92 final tested artifact:
- head `73dc4dced11804d762182a5017389bea77208aa7`;
- workflow run `33510555305`;
- artifact `9801468899`.

#93 engineering tested artifact:
- head `cf2d3fd8f5eea88e6310fec8886e5611938465ae`;
- workflow run `33512679014`;
- artifact `9802318978`.

Both artifacts contain the same **15-file output set**.

Byte-identical canonical outputs:
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

Expected noncanonical log differences:
- DATA V3 domain log contains the 11 new item closure PASS lines and moves from **535 → 546 PASS / 0 FAIL**;
- Godot import registers one additional global class, `DataFoundationV3ItemClosureTestSuite`.

## Final Items V3 boundary
Items V3 closes at this explicit capability boundary:
- canonical DATA: **2,222 items**;
- held runtime: **2 IDs** (`leftovers`, `sitrus_berry`);
- trainer bag runtime: **5 IDs** (`potion`, `super_potion`, `hyper_potion`, `max_potion`, `full_restore`);
- no synthetic classification layer added to the 2,222 canonical records;
- Oran Berry compatible but deferred;
- historical metadata cannot redefine execution.

This is not an unfinished attempt to make all 2,222 items executable. Reopening Items later requires a deliberate held-item/loadout/lifecycle tranche or evidence that invalidates this frozen boundary.

## Certification protocol
Engineering SHA `cf2d3fd8f5eea88e6310fec8886e5611938465ae` is certified 18/18 and its artifact comparison against #92 is clean.

Before closing #93:
1. engineering → final must be notebooks-only;
2. synchronized notebook set is `01_PROJECT_STATE.md`, `04_NEXT_STEPS.md`, `23_DATA_V3_ITEM_CLOSURE.md`;
3. require **18/18 SUCCESS** on the exact final notebook-bearing HEAD;
4. close #93 without merge;
5. use exact final SHA as the certified parent of Evolutions V3.

## Next phase after #93 certification
Proceed directly to:
1. Evolutions V3 reliability;
2. final end-to-end DATA V3 certification;
3. return to Trainer AI / trainer systems.

Do **not** reopen Items V3 merely to add easy individual held items before Trainer AI.

## Safety
- held-item runtime and trainer bag-item runtime are separate contracts;
- do not infer execution from an item's presence in the 2,222-record dataset;
- do not infer executable numbers from unversioned/historical description text;
- no manual edits to generated JSON;
- no broad item lifecycle architecture unless multiple source-backed mechanics make it unavoidable;
- isolated metadata discrepancies may be corrected/guarded directly when the runtime contract is already explicit and source-backed, but the discovery and decision must first be recorded in the notebook;
- stop on any regression and fix root cause.
