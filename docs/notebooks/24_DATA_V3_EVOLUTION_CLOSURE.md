# DATA V3 EVOLUTION RELIABILITY / CLOSURE — V1

## Purpose
Operational checkpoint for the Evolutions V3 reliability/closure tranche immediately after certified Items V3 closure.

## Certified parent
- PR #93: `DATA V3 — close item runtime frontier`.
- Certified final HEAD: `a034a8404d80a13cad25d43eb85c4f84e9fb22bf`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Items V3 is CLOSED at the explicit boundary documented in notebook 23.

## Current tranche
- Branch: `audit/data-v3-evolution-closure-v1`.
- Exact parent: certified #93 final `a034a8404d80a13cad25d43eb85c4f84e9fb22bf`.

## Mandatory continuity rule
Every material discovery, exception, correction, architectural decision, certification boundary or deliberate deferral must be written into the project notebooks. Chat context is never the sole source of continuity. A small live correction is allowed when it is bounded and source-backed, but the finding and decision must be recorded before the tranche is considered closed.

## Goal
Close Evolutions V3 as a bounded data-reliability tranche. Verify what evolution semantics are actually preserved and executable today, freeze the honest boundary, and do not open unrelated progression architecture merely to chase complete Pokémon-mechanics coverage.

## Exact canonical inventory
The certified #93 canonical artifact contains exactly **554 evolution records**.

Trigger partition:
- `level_up`: **438**
- `use_item`: **72**
- `trade`: **30**
- `use_move`: **2**
- `recoil_damage`: **1**
- `three_defeated_bisharp`: **1**
- `three_critical_hits`: **1**
- `gimmighoul_coins`: **1**
- `tower_of_darkness`: **1**
- `tower_of_waters`: **1**
- `spin`: **1**
- `shed`: **1**
- `strong_style_move`: **1**
- `agile_style_move`: **1**
- `other`: **1**
- `take_damage`: **1**.

Reference integrity was recomputed directly from the exact certified artifact:
- broken target-species references: **0**;
- broken/missing `use_item` item references: **0**.

Exactly **165 / 554** records carry a nonempty `conditions` dictionary.

Conditioned records inside primary triggers that already have runtime paths:
- `level_up`: **111 / 438**
- `use_item`: **22 / 72**
- `trade`: **23 / 30**
- total: **156**.

Observed preserved condition families include:
- form/region identity: `base_form`, `evolved_form`, `region`;
- friendship/affection/beauty: `min_happiness`, `min_affection`, `min_beauty`;
- temporal/location/world context: `time_of_day`, `location`, `near_special_rock`, `needs_overworld_rain`;
- move knowledge/use: `known_move`, `known_move_type`, `used_move`, `min_move_count`;
- party/multiplayer context: `party_species`, `party_type`, `needs_multiplayer`;
- trade/item context: `held_item`, `trade_species`;
- stat/body/input context: `relative_physical_stats`, `gender`, `turn_upside_down`, `min_steps`, `min_damage_taken`.

The closure suite freezes the exact condition-key inventory so a future adapter/source change cannot silently alter this frontier.

## Live audit finding #1 — conditioned evolutions were overclaimed
This is a real semantic bug, not merely missing optional coverage.

`EvolutionRecord` preserves `conditions` and round-trips them. The V3 adapter stores source-backed evolution-detail fields there after extracting `trigger`, `min_level` and `item_id`.

Before this tranche, `EvolutionSystem`:
- classified every `level_up` record as `RUNTIME_SUPPORTED`;
- classified valid `use_item` records as `RUNTIME_SUPPORTED`;
- classified every `trade` record as `RUNTIME_SUPPORTED`;
- evaluated only `min_level`, direct `item_id`, and boolean `traded`;
- never evaluated `record.conditions`;
- skipped only `UNSUPPORTED` records in `evolution_candidates()`, allowing `DATA_ONLY` records under a known primary trigger to be evaluated anyway.

Consequence: a conditioned evolution could silently degrade into a weaker simple level/item/trade evolution.

Representative preserved examples:
- Aipom → Ambipom requires knowing `double_hit`;
- Eevee branches preserve friendship/time/affection/move-type and historical location/stone methods;
- Clamperl trade branches preserve required held items;
- regional/form branches preserve `base_form` / `evolved_form` / `region` routing;
- later mechanics preserve rain, party, move-use, damage-taken and related requirements.

## Live audit finding #2 — `conditions` mixes real requirements with one provably redundant selector
The first conservative estimate treated every nonempty `conditions` dictionary as non-runtime and produced a provisional **384 / 156 / 14** split.

A deeper audit showed that this was too conservative. There are exactly **7** records whose only preserved condition is:

`{"base_form": <current source species id>}`

For those records the selector is already guaranteed by the fact that `EvolutionSystem` is evaluating that exact base species. No new form, region, time or version state is required.

The seven source-backed redundant-selector cases are:
- Eevee → Vaporeon (`water_stone`)
- Eevee → Jolteon (`thunder_stone`)
- Eevee → Flareon (`fire_stone`)
- Eevee → Leafeon (`leaf_stone`)
- Eevee → Glaceon (`ice_stone`)
- Floette → Florges (`shiny_stone`)
- Pikachu → Raichu (`thunder_stone`).

This exception is deliberately narrow. A `base_form` value such as `meowth_galar`, any `region`, any `evolved_form`, or any additional condition remains non-runtime because the current progression context cannot prove it.

## Live audit finding #3 — normalized trigger naming mismatch
`EvolutionSystem.UNSUPPORTED_TRIGGERS` used old hyphenated spellings (`use-move`, `take-damage`, `three-critical-hits`, etc.) while DATA V3 canonical trigger IDs use underscores (`use_move`, `take_damage`, `three_critical_hits`, etc.).

Consequence:
- most exotic triggers fell through to generic `DATA_ONLY` instead of the intended `UNSUPPORTED` bucket;
- they did not execute accidentally because the runtime match had no path for them;
- coverage reporting was nevertheless false.

Correction: the unsupported-trigger registry now uses the exact canonical underscore IDs.

## Bounded correction implemented
No new evolution-condition subsystem is being built.

`EvolutionSystem` now follows these rules:
1. canonical exotic triggers are `UNSUPPORTED`;
2. `level_up`, `use_item` and `trade` can be `RUNTIME_SUPPORTED` only when their preserved conditions are runtime-compatible;
3. empty `conditions` are compatible;
4. the sole nonempty compatible condition is exactly one `base_form` equal to the source species currently being evaluated;
5. every other preserved condition is `DATA_ONLY`;
6. `use_item` still requires a nonempty valid item ID;
7. `evolution_candidates()` now accepts **only** records classified `RUNTIME_SUPPORTED`; `DATA_ONLY` cannot silently execute through a weaker known trigger;
8. `coverage_report()` classifies with the source species ID so the narrow redundant `base_form` exception is auditable.

This is a capability-boundary correction, not a general version/form/friendship/trade evolution engine.

## Provisional corrected capability boundary
With exact references verified and the redundant-selector rule applied, the expected canonical classification is:
- `RUNTIME_SUPPORTED`: **391**
- `DATA_ONLY`: **149**
- `UNSUPPORTED`: **14**
- `PARTIAL`: **0**
- total: **554**.

This **391 / 149 / 14** boundary is now encoded in the closure suite but is not certified until engineering CI and artifact comparison pass.

## Closure regression suite
`DataFoundationV3EvolutionClosureTestSuite` adds **11 closure checks**:
1. exact evolution count = 554;
2. exact 16-trigger partition;
3. exact conditioned count = 165;
4. exact condition-key inventory;
5. zero broken target-species references;
6. zero broken `use_item` item references;
7. exact classification boundary = **391 runtime / 149 data-only / 14 unsupported / 0 partial**;
8. no real preserved condition may silently execute;
9. exactly seven redundant `base_form == source species` exceptions remain runtime-compatible;
10. all canonical exotic trigger IDs classify `UNSUPPORTED`;
11. candidate gating proves conditioned level/trade records stay out while a redundant base-form item evolution remains executable.

## Closure rule
Prefer tested preservation + explicit runtime capability boundaries over pretending every main-series evolution mechanic is executable. Evolutions V3 can close when:
- canonical evolution counts/references are exact;
- trigger/condition families are inventoried;
- runtime-consumed fields are explicitly distinguished from preserved metadata;
- no unsupported condition can silently behave as a simpler supported evolution;
- the narrow redundant-selector exception is frozen by tests;
- no broad overworld/trade/friendship/time/location/party/form subsystem is opened solely for data coverage.

## Workflow
1. inspect raw/normalized evolution schema and V3 adapter construction;
2. inspect `EvolutionRecord`, `EvolutionSystem`, progression tests and importer validation;
3. inventory exact trigger/condition families across the 554 records;
4. identify and correct semantic loss between canonical data and runtime evaluation;
5. add closure regressions/invariants;
6. 18/18 engineering → artifact diff → sync `01/04/24` → notebooks-only compare → final 18/18 → close without merge.

## Safety
- immutable PokeAPI snapshot remains read-only;
- no manual edits to generated JSON;
- do not infer missing conditions from Pokémon names or remembered game knowledge;
- do not simplify a multi-condition evolution into a weaker runtime rule;
- conditioned records remain preserved even when runtime execution is deferred;
- do not build friendship/time/location/form/trade-item/party/move-use systems merely to raise coverage during closure;
- the seven redundant-base-form exceptions must never broaden into generic form inference;
- stop on any regression and fix root cause.
