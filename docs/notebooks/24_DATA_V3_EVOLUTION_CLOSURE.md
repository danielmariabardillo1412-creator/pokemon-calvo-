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
- PR: #94 `DATA V3 — close evolution runtime frontier`.
- Engineering SHA: `87a48acc2746ee429cbd6786e6a8adedb1afabeb`.

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

Reference integrity:
- broken target-species references: **0**;
- broken/missing `use_item` item references: **0**.

Exactly **165 / 554** records carry a nonempty `conditions` dictionary.

Conditioned records inside primary triggers that already have runtime paths:
- `level_up`: **111 / 438**
- `use_item`: **22 / 72**
- `trade`: **23 / 30**
- total: **156**.

Preserved condition families include:
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

Consequence: a conditioned evolution could silently degrade into a weaker simple level/item/trade evolution. That would modify Pokémon rules rather than implement them faithfully.

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

## Certified engineering capability boundary
Engineering CI confirms the exact classification:
- `RUNTIME_SUPPORTED`: **391**
- `DATA_ONLY`: **149**
- `UNSUPPORTED`: **14**
- `PARTIAL`: **0**
- total: **554**.

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

## Engineering certification
Engineering HEAD:
- `87a48acc2746ee429cbd6786e6a8adedb1afabeb`.

Result:
- **18/18 workflows SUCCESS**;
- Godot 4.7 regression suite SUCCESS;
- DATA Foundation V3 SUCCESS;
- Trainer AI regressors SUCCESS;
- DATA V3 domain: **557 PASS / 0 FAIL**.

## Exact #93 final → #94 engineering artifact comparison
Certified #93 final:
- head `a034a8404d80a13cad25d43eb85c4f84e9fb22bf`;
- DATA V3 run `33513512710`;
- artifact `9802641046`.

#94 engineering:
- head `87a48acc2746ee429cbd6786e6a8adedb1afabeb`;
- DATA V3 run `33515258905`;
- artifact `9803339060`.

Both artifacts contain the same **15-file output set**.

Byte-identical canonical outputs:
- raw `pokemon_api.json`;
- normalized `pokemon_api.json`;
- manifest;
- forms policy report;
- unsupported mechanics report;
- PokeAPI V3 audit report;
- auxiliary report.

`import_summary.json` is canonically identical except timing noise:
- `import_time_ms 508 → 491 ms`.

Expected log delta:
- DATA V3 domain increases **546 → 557 PASS / 0 FAIL** because of the 11 new Evolutions V3 closure checks.
- runtime/check logs are unchanged.

No canonical DATA V3 drift exists.

## Closure rule
Prefer tested preservation + explicit runtime capability boundaries over pretending every main-series evolution mechanic is executable. Evolutions V3 closes only when:
- canonical evolution counts/references are exact;
- trigger/condition families are inventoried;
- runtime-consumed fields are explicitly distinguished from preserved metadata;
- no unsupported condition can silently behave as a simpler supported evolution;
- the narrow redundant-selector exception is frozen by tests;
- no broad overworld/trade/friendship/time/location/party/form subsystem is opened solely for data coverage;
- engineering and final notebook-bearing HEADs both pass 18/18.

## Current certification step
Engineering and artifact comparison are complete.

Before closing #94:
1. engineering → final must change only `01_PROJECT_STATE.md`, `04_NEXT_STEPS.md`, `24_DATA_V3_EVOLUTION_CLOSURE.md`;
2. require **18/18 SUCCESS** on the exact final notebook-bearing HEAD;
3. close #94 without merge;
4. use that exact final SHA as the certified parent for final end-to-end DATA V3 certification.

## Safety
- immutable PokeAPI snapshot remains read-only;
- no manual edits to generated JSON;
- do not infer missing conditions from Pokémon names or remembered game knowledge;
- when source uncertainty matters, verify against PokeAPI/authoritative Pokémon references rather than inventing mechanics;
- do not simplify a multi-condition evolution into a weaker runtime rule;
- conditioned records remain preserved even when runtime execution is deferred;
- do not build friendship/time/location/form/trade-item/party/move-use systems merely to raise coverage during closure;
- the seven redundant-base-form exceptions must never broaden into generic form inference;
- stop on any regression and fix root cause.
