# PROJECT STATE NOTEBOOK

## Purpose

High-level state needed to resume engineering work safely. This is a continuity document, not a replacement for formal architecture documentation.

## Repository and workflow

- Repository: `danielmariabardillo1412-creator/pokemon-calvo-`
- Engine: Godot 4.7.
- Working policy: certified snapshots are commonly kept as branches/closed PRs **without merge**. Do not assume a conventional merge-to-main workflow.
- A new tranche branches from the latest certified HEAD.
- Certification is performed on the exact final HEAD; do not certify one SHA and then add code afterward.
- Normal regression matrix: 18 workflows.

## DATA FOUNDATION V3 canonical source

Immutable source snapshot:

- Branch: `data/pokeapi-v2-snapshot`
- Source commit: `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`
- API tree: `8349ea1ce75716897fe96e02a15950d19edba6c3`
- Schema tree: `02e031e1928d7e9456bf6f7486daacc4b8946c84`
- Source paths: `data/api/v2`, `data/schema/v2`
- Source JSON is read-only.

Pipeline:

`data/api/v2 + data/schema/v2`
→ `tools/pokeapi_adapter_v3.py`
→ `data/raw/pokemon_api.json`
→ Godot `DataImporter`
→ `data/normalized/pokemon_api.json`
→ runtime definitions.

V3 reuses mature legacy move-conversion helpers through `tools/pokeapi_adapter.py`, while the obsolete V2 adapter remains archived for provenance at `tools/archive/pokeapi_adapter_v2_legacy.py`.

## Certified V3 foundation facts

The original V3 foundation established:

- 1,025 base species.
- 326 forms.
- 18 runtime battle types.
- 919 runtime move records.
- 373 abilities.
- 2,222 items.
- 61,102 learnset entries.
- 554 evolution records.
- 0 broken references.
- 0 rejected definitions.
- 18 XD Shadow moves explicitly excluded rather than remapped to standard types.

Learnsets are version-aware per species. Species/forms use PokéAPI default-variety semantics rather than naïve hyphen filtering. Ability slot/hidden metadata and evolution provenance are preserved.

## Repository organization baseline

Repository organization V1 was certified on branch `chore/repository-organization-v1`, final HEAD `1247c4029b8001abd445db2f4155012962c703ee`, PR #33 closed without merge.

Key organized test roots:

- `tests/battle/`
- `tests/data/`
- `tests/gameplay/`
- `tests/trainer_ai/`
- `tests/test_runner.gd` is the sole global root runner.

## Current certification chain

Notebook baseline:

- Branch: `docs/project-notebooks-v1`
- HEAD: `7ab2c1be78fab18309c6c4f4de9b2cf02ed96b46`
- PR #52: closed without merge.
- CI: 18/18 SUCCESS.

Simple self-stat boosts C:

- Branch: `fix/data-v3-simple-self-stat-boosts-c`
- Final HEAD: `b3cfa577e01f45d57e0d73ebe662b84665d6f48e`
- PR #53: closed without merge.
- CI: 18/18 SUCCESS.

Silk Trap semantic fix:

- Branch: `fix/data-v3-silk-trap-semantics`
- Final HEAD: `c1f5e55c7d1d8acc991b3a6ddde906f10930bb67`
- PR #54: closed without merge.
- CI: 18/18 SUCCESS on that exact final notebook-bearing HEAD.

Current Aromatic Mist tranche:

- Branch: `fix/data-v3-aromatic-mist-semantics`
- PR #55.
- Parent: certified HEAD `c1f5e55c7d1d8acc991b3a6ddde906f10930bb67`.
- Engineering SHA before notebook synchronization: `7ae7d5c8f20c555e03411e3baacdbd2de1084f1c`.
- That engineering SHA passed 18/18 workflows, including the independent Aromatic Mist dataset assertion and Godot global.
- Notebook synchronization moves the branch tip; **the exact final certified HEAD must be read from PR #55 / branch tip after its second 18/18 run before closure**. GitHub is authoritative.

The active work is **Move Effects V3 semantic audit**, not trainer AI.

## Current move coverage from PR #55 engineering artifact

Exact generated artifact counts from SHA `7ae7d5c8f20c555e03411e3baacdbd2de1084f1c`:

- `RUNTIME_SUPPORTED`: 555
- `PARTIAL_RUNTIME`: 66
- `DATA_ONLY`: 286
- `UNSUPPORTED`: 12

Among the remaining `DATA_ONLY` records, 64 still have generated `effect_specs` and therefore deserve special scrutiny:

- 61 records contain stat-change effects (109 nested/top-level `modify_stat_stage` specs in total across them).
- 2 heal-related cases: `Purify`, `Swallow`.
- 1 multi-hit case: `Beat Up`.

`Silk Trap` remains `DATA_ONLY` with empty `effect_specs`; its previous generic `SELF Speed -1` was false because the real Speed drop is contact-triggered on the attacker.

`Aromatic Mist` remains `DATA_ONLY` with empty `effect_specs`; its previous generic `SELF Special Defense +1` was false because the immutable source explicitly targets a selected ally. Current Battle Core has no ally target.

This count is a prioritization signal, **not** proof that all other DATA_ONLY moves are correct. The audit must continue by semantic family.

## Battle effect model relevant to the audit

`BattleEffectSpec` currently supports:

- DAMAGE
- HEAL
- REVIVE constant (note importer support must be checked before use)
- RECOIL
- DRAIN
- INFLICT_STATUS
- CURE_STATUS
- MODIFY_STAT_STAGE
- CHANCE
- FLINCH
- FIXED_DAMAGE
- MULTI_HIT

Targets currently available to the effect model/importer are SELF and OPPONENT. Team/side/ally targeting, delayed effects, weather-conditioned heal ratios, temporary type suppression, protection/contact-response triggers, and several unique move mechanics are not generally representable.

`StatStages` supports Attack, Defense, Special Attack, Special Defense, Speed, Accuracy, and Evasion with normal stage clamping.

## Core interpretation rule

A source record existing in PokéAPI does **not** imply the runtime implements its mechanics.

Coverage labels must mean what they say:

- `RUNTIME_SUPPORTED`: the runtime representation is faithful for the audited battle semantics.
- `PARTIAL_RUNTIME`: a real subset executes, but known mechanics remain unrepresented.
- `DATA_ONLY`: preserved as data but no faithful runtime effect is claimed.
- `UNSUPPORTED`: explicitly unsupported by the current contract.

Never promote coverage simply because a generic `effect_spec` exists. If a generic effect is demonstrably false, remove/neutralize it even when the coverage label was already DATA_ONLY, because runtime execution is driven by `effect_specs` rather than coverage alone.
