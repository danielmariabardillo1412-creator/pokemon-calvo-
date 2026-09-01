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

## Goal
Close the DATA V3 item frontier in one bounded tranche if possible. Do not repeat the long ability-by-ability audit.

## Questions
1. What item semantics are preserved in the 2,222 canonical item records?
2. Which **held items** are actually executable in `BattleEffectRegistry` today?
3. Which **trainer bag items** are executable through the separate trainer-item action surface?
4. Do canonical item records have an explicit runtime classification, or is support intentionally a Battle Core registry concern?
5. Is any preserved/non-runtime item silently executable through a hidden mapping?
6. Are there a few high-value source-backed items whose complete semantics already fit existing primitives and materially matter to trainer battles?

## Closure rule
Prefer a tested capability boundary over implementing a general item engine. Items V3 can close when:
- held-item and trainer-item runtime surfaces are inventoried separately;
- canonical references/source provenance remain stable;
- unsupported items cannot acquire hidden executable mappings silently;
- any obvious high-value compatible gaps are either implemented in a small bounded group or explicitly blocked;
- no large lifecycle subsystem (consumption, transfer, choice locking, species/form triggers, weather, etc.) is opened merely to increase coverage.

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
- no manual edits to generated JSON;
- no broad item lifecycle architecture unless multiple source-backed mechanics make it unavoidable;
- stop on any regression and fix root cause.
