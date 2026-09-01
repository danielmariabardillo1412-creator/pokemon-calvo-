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
- DATA V3 currently preserves exactly **2,222 canonical item records**.
- Canonical item records are metadata-only and contain `id`, `display_name`, `description`, `category`; unlike moves/abilities they do **not** carry a runtime `classification`.
- Runtime semantics therefore remain an explicit Battle Core registry concern rather than something inferred from item presence or description text.
- Held-item runtime and trainer bag-item runtime are intentionally separate surfaces.
- Current held-item frontier: `leftovers`, `sitrus_berry`.
- Current trainer bag frontier: `potion`, `super_potion`, `hyper_potion`, `max_potion`, `full_restore`.

### Super Potion / Hyper Potion historical metadata discrepancy
A real but bounded source/runtime discrepancy was found:
- canonical DATA V3 description generation currently reads the immutable PokeAPI `effect_entries` text;
- Super Potion's preserved English `effect_entry` says **50 HP**;
- Hyper Potion's preserved English `effect_entry` says **200 HP**;
- versioned PokeAPI flavor entries change these values to **60 HP** and **120 HP** from Sun/Moon onward;
- Calvo V1 Trainer AI / Battle Core already uses the explicit modern runtime contract **20 / 60 / 120 / full / full+status**.

Decision: this is treated as an **isolated metadata-version discrepancy, not a Battle Core bug and not a reason to open a general version-policy subsystem during Items V3 closure**. The executable Calvo V1 contract remains 60/120. A closure regression must ensure legacy descriptive metadata can never silently redefine runtime healing values.

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
The Items V3 closure suite is required to freeze:
- exactly **2,222** canonical items and unique IDs;
- exact metadata-only item schema;
- exact held runtime frontier `leftovers`, `sitrus_berry`;
- exact trainer bag frontier of the five Calvo V1 healing items;
- all runtime IDs must exist in canonical DATA V3;
- exact trainer healing contract `20 / 60 / 120 / full / full+status`;
- historical Super/Hyper metadata cannot redefine execution;
- Oran Berry remains canonical but deliberately unmapped/deferred.

## Workflow
1. inspect DATA V3 raw/normalized item schema and reports;
2. inspect `_register_items()` and `_register_trainer_items()` plus existing item tests;
3. inventory exact runtime IDs and source semantics;
4. audit only a tiny high-value subgroup if justified;
5. add closure regressions/invariants;
6. 18/18 engineering → artifact diff → sync `01/04/23` → notebooks-only compare → final 18/18 → close without merge.

## Safety
- held-item runtime and trainer bag-item runtime are separate contracts;
- do not infer execution from an item's presence in the 2,222-record dataset;
- do not infer executable numbers from unversioned/historical description text;
- no manual edits to generated JSON;
- no broad item lifecycle architecture unless multiple source-backed mechanics make it unavoidable;
- isolated metadata discrepancies may be corrected/guarded directly when the runtime contract is already explicit and source-backed, but the discovery and decision must first be recorded in the notebook;
- stop on any regression and fix root cause.
