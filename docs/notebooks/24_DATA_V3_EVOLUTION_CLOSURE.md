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

## Initial questions
1. What exact evolution schema is preserved in the 554 canonical evolution records?
2. Are all evolution targets/references valid and deterministic?
3. Which trigger/condition families are preserved by the V3 adapter?
4. Which fields are actually consumed by `EvolutionSystem` today?
5. Are any preserved conditions silently ignored or simplified at runtime?
6. Is the current runtime boundary already sufficient for the game/trainer roadmap, or are there a few source-backed gaps that fit existing primitives without opening new systems?
7. Are there version/form/item/trade/location/time/friendship or party-context conditions whose honest execution requires architecture not currently present?

## Live audit finding — conditioned evolutions are currently overclaimed
This is a real semantic bug, not merely missing optional coverage.

`EvolutionRecord` preserves a free-form `conditions` dictionary and round-trips it through serialization. The V3 adapter deliberately stores source-backed evolution detail fields there after extracting the primary `trigger`, `min_level` and `item_id` fields.

However, current `EvolutionSystem`:
- classifies every `level_up` record as `RUNTIME_SUPPORTED`;
- classifies valid `use_item` records as `RUNTIME_SUPPORTED`;
- classifies every `trade` record as `RUNTIME_SUPPORTED`;
- evaluates only `min_level`, direct `item_id`, and the boolean `traded` context;
- never evaluates `record.conditions`.

Therefore a conditioned evolution under one of those three triggers can silently behave as a weaker simple evolution.

### Exact canonical inventory
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
- `take_damage`: **1**

Exactly **165 / 554** records carry a nonempty `conditions` dictionary.

Conditioned records inside triggers currently treated as executable:
- `level_up`: **111 / 438**
- `use_item`: **22 / 72**
- `trade`: **23 / 30**
- total conditioned records under these three runtime paths: **156**.

Thus the current runtime-support claim is materially too broad.

Observed preserved condition keys include:
- form/region identity: `base_form`, `evolved_form`, `region`;
- friendship/affection/beauty: `min_happiness`, `min_affection`, `min_beauty`;
- temporal/location/world context: `time_of_day`, `location`, `near_special_rock`, `needs_overworld_rain`;
- move knowledge/use: `known_move`, `known_move_type`, `used_move`, `min_move_count`;
- party/multiplayer context: `party_species`, `party_type`, `needs_multiplayer`;
- trade/item context: `held_item`, `trade_species`;
- stat/body/input context: `relative_physical_stats`, `gender`, `turn_upside_down`, `min_steps`, `min_damage_taken`.

Representative source-preserved examples that current runtime would oversimplify:
- Aipom → Ambipom requires knowing `double_hit`;
- Eevee branches include friendship/time/affection/move-type conditions;
- trade evolutions such as Clamperl branches preserve required held items;
- regional/form branches preserve `base_form` / `evolved_form` identity;
- later-generation mechanics preserve rain, party, move-use, damage-taken and similar conditions.

### Bounded correction decision
Do **not** implement 165 condition mechanics in this closure tranche.

Instead:
1. any evolution record with a nonempty `conditions` dictionary is **not fully executable by the current runtime** and must not be classified `RUNTIME_SUPPORTED`;
2. conditioned records whose primary trigger otherwise has a runtime path should be preserved as `DATA_ONLY` until the required condition subsystem is deliberately implemented;
3. `evolution_candidates()` must only expose records classified `RUNTIME_SUPPORTED`, preventing a DATA_ONLY conditioned record from silently executing via its weaker primary trigger;
4. unconditional `level_up`, valid `use_item`, and unconditional `trade` remain candidates for runtime support;
5. exotic triggers remain non-executable and must be classified honestly rather than inferred from names.

This is a capability-boundary correction, not a new evolution engine.

## Live audit finding — normalized trigger naming mismatch
A second, smaller classification defect exists.

`EvolutionSystem.UNSUPPORTED_TRIGGERS` currently stores several trigger names with hyphens such as `use-move`, `take-damage`, `three-critical-hits`, etc. DATA V3 normalizes trigger IDs to underscores such as `use_move`, `take_damage`, `three_critical_hits`.

Consequence:
- most exotic triggers fall through to generic `DATA_ONLY` rather than the intended `UNSUPPORTED` bucket;
- they are not currently executed because the runtime match has no path for them, so this is not the dangerous bug above;
- coverage reporting is nevertheless false and must be corrected during Evolutions V3 closure.

Decision: align the explicit unsupported-trigger constants with the canonical normalized IDs and freeze the trigger partition with regression tests.

## Provisional honest capability boundary
Before final verification of item references and existing progression contracts, the canonical inventory suggests:
- unconditional `level_up`: **327**
- unconditional `use_item`: **50**
- unconditional `trade`: **7**
- provisional fully runtime-capable records: **384**
- conditioned records under otherwise supported triggers: **156** → `DATA_ONLY`
- exotic/non-runtime trigger records: **14** → intended `UNSUPPORTED` if their normalized trigger IDs are explicitly recognized.

This **384 / 156 / 14** split is provisional until the closure suite verifies item references, importer invariants and existing progression tests. Do not certify these numbers merely from arithmetic.

## Closure rule
Prefer tested preservation + explicit runtime capability boundaries over pretending every main-series evolution mechanic is executable. Evolutions V3 can close when:
- canonical evolution counts/references are exact;
- trigger/condition families are inventoried;
- runtime-consumed fields are explicitly distinguished from preserved metadata;
- no unsupported condition can silently behave as a simpler supported evolution;
- any small, high-value compatible gap is either implemented in a bounded way or deliberately deferred;
- no broad overworld/trade/friendship/time/location/party/form subsystem is opened solely for data coverage.

## Workflow
1. inspect raw/normalized evolution schema and V3 adapter construction;
2. inspect `EvolutionRecord`, `EvolutionSystem`, progression tests and importer validation;
3. inventory exact trigger/condition families across the 554 records;
4. identify any semantic loss between canonical data and runtime evaluation;
5. add closure regressions/invariants;
6. 18/18 engineering → artifact diff → sync `01/04/24` → notebooks-only compare → final 18/18 → close without merge.

## Safety
- immutable PokeAPI snapshot remains read-only;
- no manual edits to generated JSON;
- do not infer missing conditions from Pokémon names or remembered game knowledge;
- do not simplify a multi-condition evolution into a weaker runtime rule without explicitly marking the unsupported boundary;
- conditioned records remain preserved even when runtime execution is deferred;
- do not build friendship/time/location/form/trade-item/party/move-use systems merely to raise coverage during closure;
- stop on any regression and fix root cause.
