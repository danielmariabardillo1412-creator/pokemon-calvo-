# DATA V3 ABILITY CLOSURE AUDIT — V1

## Purpose
Operational checkpoint for closing the DATA FOUNDATION V3 ability-reliability phase without chasing artificial 373/373 executable coverage.

## Certified parent
- PR #91: `DATA V3 — add shared target-state ability semantics`.
- Certified final HEAD: `9a6d559e1c83699d01a54718a1748bca791c034a`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Parent ability coverage: **21 RUNTIME_SUPPORTED / 14 PARTIAL_RUNTIME / 338 DATA_ONLY / 373 total**.

## Current tranche
- Branch: `audit/data-v3-ability-closure-v1`.
- Exact parent: certified #91 final `9a6d559e1c83699d01a54718a1748bca791c034a`.

## Closure question
Determine whether the remaining 338 DATA_ONLY abilities contain a meaningful final subset whose complete or useful-partial semantics fit the current battle model, or whether the remaining frontier is dominated by explicit architectural blockers that should be documented and deferred.

## Deterministic remaining frontier
The current regenerated DATA V3 artifact contains exactly **338 DATA_ONLY abilities**. Using the same deterministic planning classifier already used by the family inventory, the remaining frontier partitions as:

- `stat_damage_modifier`: **64**
- `source_text_missing`: **60**
- `immunity_absorb_prevention`: **52**
- `move_property_control`: **36**
- `weather_terrain`: **33**
- `misc_unresolved`: **26**
- `status_dependent`: **18**
- `item_transaction`: **13**
- `form_identity`: **12**
- `switch_party`: **11**
- `contact_reactive`: **7**
- `faint_dependent`: **6**

Total: **338**.

These are closure/planning buckets, not promotion heuristics. They exist to freeze the remaining capability frontier and prevent accidental mass support claims.

## Dominant blockers
The remaining frontier is dominated by mechanics intentionally outside the current battle model or requiring a deliberate future subsystem:

- weather / terrain state and residual transactions;
- doubles / ally context / global auras;
- forms / transformations / identity mutations;
- gender and per-target comparison state;
- turn-scoped switch history and forced-switch/party transactions;
- accuracy/evasion and priority interception;
- move-property metadata such as punch/bite/pulse/slicing/bullet/dance/etc.;
- effectiveness-aware predicates and move-result provenance;
- item consumption/reuse/transfer lifecycle;
- status prevention/replacement and version-sensitive status semantics;
- contact per-hit/faint-safe reactions and KO attribution;
- source records with no English battle semantics (**60 records**), which must never be inferred from ability names.

## Final compatible-subgroup audit — Battle Armor / Shell Armor
Immutable sources:
- Battle Armor: Generation III, main-series, no `effect_changes`; moves cannot score critical hits against the holder; source says it is identical to Shell Armor.
- Shell Armor: Generation III, main-series, no `effect_changes`; moves cannot score critical hits against the holder; source says it is identical to Battle Armor.

The raw battle outcome could be approximated with the existing `force_critical` channel by letting a defensive modifier force `false`. However the current trigger/event contract cannot distinguish:
1. a critical that **would have occurred and was prevented**; from
2. an ordinary non-critical roll where the prevention ability did nothing.

Blindly emitting `ABILITY_TRIGGERED` on every incoming damaging move would be false provenance. Silently forcing `force_critical = 0` without a corresponding truthful trigger event would introduce an exception to the current event contract. Correctly solving that requires critical-prevention result provenance/interception, which is broader than this closure tranche.

Decision: **Battle Armor and Shell Armor remain DATA_ONLY**. Do not add a critical-prevention subsystem merely to increase the coverage count by two.

## Closure regression suite
`DataFoundationV3AbilityClosureTestSuite` freezes the boundary with these invariants:

1. exact DATA_ONLY frontier = **338**;
2. exact 12-bucket partition above;
3. **no DATA_ONLY ability may already have a hidden registry mapping**;
4. a high-value deferred sentinel set remains DATA_ONLY and unmapped (Battle Armor/Shell Armor, weather blockers, Rivalry/Stakeout, Shed Skin/Poison Heal, source/version blockers, effectiveness blockers, hit-timing blockers, move-property blockers, Fluffy, etc.);
5. `source_text_missing` remains exactly **60**, preventing name-based inference.

## Closure decision
If CI confirms these invariants and the tested artifact is canonically identical to certified #91, **Ability V3 is closed at 21 RUNTIME_SUPPORTED / 14 PARTIAL_RUNTIME / 338 DATA_ONLY**.

That is an honest capability boundary, not an unfinished attempt to reach 373/373. Reopening abilities later requires a new battle subsystem or source/runtime evidence that materially changes one of the frozen blockers.

## Next phase after certification
Do not continue ability micro-tranches after this closure. Move DATA FOUNDATION V3 to:
1. Items V3 reliability/coverage;
2. Evolutions V3 reliability;
3. final end-to-end DATA V3 certification;
4. then return to Trainer AI / trainer systems.

## Safety
- no speculative new weather/terrain/doubles/form/gender/switch-history architecture;
- no use of external remembered numeric values when immutable source lacks them;
- no mass promotion from family heuristics;
- no manual edits to generated canonical JSON;
- stop on any focal/regression failure and fix root cause.
