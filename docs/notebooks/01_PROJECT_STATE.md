# PROJECT STATE NOTEBOOK

## Purpose

Fast, durable context recovery for engineering work. This notebook records the current certified chain, DATA V3 authority, runtime constraints, and live metrics. Detailed Move Effects history lives in `02_DATA_V3_MOVE_EFFECTS_AUDIT.md`; the immediate continuation point lives in `04_NEXT_STEPS.md`.

## Repository and certification policy

- Repository: `danielmariabardillo1412-creator/pokemon-calvo-`
- Engine: Godot 4.7.
- Certified snapshots are commonly retained as branches / closed PRs **without merge**.
- Every new tranche branches from the latest exact certified HEAD.
- A tranche is not certified until **all 18 normal workflows are green on the same final SHA**.
- If notebooks are updated after engineering CI, that creates a new SHA and therefore requires a second 18/18 run.
- If chat/notebooks disagree with GitHub, GitHub commits, PR state, CI, and immutable source data are authoritative.

## DATA FOUNDATION V3 authority

Immutable PokéAPI snapshot:

- Branch: `data/pokeapi-v2-snapshot`
- Source commit: `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`
- API tree: `8349ea1ce75716897fe96e02a15950d19edba6c3`
- Schema tree: `02e031e1928d7e9456bf6f7486daacc4b8946c84`
- Source paths: `data/api/v2`, `data/schema/v2`
- Source JSON is read-only.

Pipeline:

`data/api/v2 + data/schema/v2`
→ `tools/pokeapi_adapter_v3.py`
→ compatibility corrections in `tools/pokeapi_adapter.py`
→ `data/raw/pokemon_api.json`
→ Godot `DataImporter`
→ `data/normalized/pokemon_api.json`
→ runtime definitions.

The obsolete V2 adapter remains archived for provenance at `tools/archive/pokeapi_adapter_v2_legacy.py` and must not be edited for current fixes.

## Certified structural V3 facts

- 1,025 base species
- 326 forms
- 18 runtime battle types
- 919 runtime move records
- 373 abilities
- 2,222 items
- 61,102 learnset entries
- 554 evolution records
- 0 broken references
- 0 rejected definitions
- 18 XD Shadow moves explicitly excluded instead of remapped

Learnsets are version-aware per species; species/forms use PokéAPI default-variety semantics; ability slot/hidden metadata and evolution provenance are preserved.

## Repository organization baseline

Repository organization V1:

- Branch: `chore/repository-organization-v1`
- HEAD: `1247c4029b8001abd445db2f4155012962c703ee`
- PR #33 closed without merge
- 18/18 workflows SUCCESS

Organized test roots: `tests/battle/`, `tests/data/`, `tests/gameplay/`, `tests/trainer_ai/`; `tests/test_runner.gd` remains the sole global root runner.

## Current certified chain

Persistent notebooks baseline:

- PR #52 — `docs/project-notebooks-v1`
- HEAD `7ab2c1be78fab18309c6c4f4de9b2cf02ed96b46`
- 18/18 SUCCESS, closed without merge

Recent Move Effects V3 chain:

- PR #53 — simple self stat boosts C — final `b3cfa577e01f45d57e0d73ebe662b84665d6f48e` — 18/18
- PR #54 — Silk Trap target/trigger bug — final `c1f5e55c7d1d8acc991b3a6ddde906f10930bb67` — 18/18
- PR #55 — Aromatic Mist ally-target bug — final `844efde0eed27e1a5ca8790ae95a183fba6ba98c` — 18/18
- PR #56 — Stuff Cheeks held-Berry prerequisite bug — final `1c4217d5ebc6727982ef5d7b5b5b0667cea6c5b6` — 18/18
- PR #57 — Howl user-and-allies target bug — final `53e20600d372d44bc21eb145f598448a41828e5d` — 18/18, closed without merge

Current tranche:

- PR #58 — `fix/data-v3-coaching-semantics`
- Parent: certified #57 final `53e20600d372d44bc21eb145f598448a41828e5d`
- Engineering SHA before notebook synchronization: `b7da56687d1e1e45072ca4572f5f0751f9d309d7`
- Engineering SHA passed 18/18 workflows, including the independent Coaching regenerated-dataset assertion and Godot global.
- Notebook synchronization moves the branch tip. **The final exact PR #58 HEAD must pass 18/18 again before closure without merge.**

Active workstream: **Move Effects V3 semantic audit**, not trainer AI/archetypes.

## Exact move coverage from PR #58 engineering artifact

Artifact generated from `b7da56687d1e1e45072ca4572f5f0751f9d309d7`:

- `RUNTIME_SUPPORTED`: 555
- `PARTIAL_RUNTIME`: 67
- `DATA_ONLY`: 285
- `UNSUPPORTED`: 12

Remaining `DATA_ONLY` records with non-empty `effect_specs`: **61**.

Current breakdown:

- 58 stat-change DATA_ONLY records
- 2 heal cases: `Purify`, `Swallow`
- 1 multi-hit case: `Beat Up`

Important recently neutralized/corrected behavior:

- `Silk Trap`: DATA_ONLY, effect-free; previous `SELF Speed -1` was false because the real debuff is contact-triggered on the attacker.
- `Aromatic Mist`: DATA_ONLY, effect-free; previous `SELF SpDef +1` targeted the wrong creature because source target is ally.
- `Stuff Cheeks`: DATA_ONLY, effect-free; previous unconditional `SELF Defense +2` ignored the required held-Berry consume transaction.
- `Howl`: `PARTIAL_RUNTIME`; modern source target is `user-and-allies`, executable subset is exactly `SELF Attack +1`, ally subset remains missing. Previous generic output incorrectly buffed OPPONENT.
- `Coaching`: DATA_ONLY, effect-free; source mechanics affect ally Pokémon and fail with no adjacent ally. Previous generic output incorrectly granted `OPPONENT Attack +1` and `OPPONENT Defense +1`.

## Runtime constraints relevant to Move Effects audit

`BattleEffectSpec` / importer currently support the core effect kinds used here: DAMAGE, HEAL, RECOIL, DRAIN, INFLICT_STATUS, CURE_STATUS, MODIFY_STAT_STAGE, CHANCE, FLINCH, FIXED_DAMAGE, MULTI_HIT (REVIVE constant exists but importer/runtime support must be checked before use).

Effect targets available today are effectively **SELF and OPPONENT**. The model does not generally represent:

- ally/team/side targeting
- delayed persisted effects
- weather-conditioned heal ratios
- temporary type suppression
- protection/contact-response triggers
- held-item prerequisites/consumption transactions
- many unique move-specific state machines

`StatStages` supports Attack, Defense, Special Attack, Special Defense, Speed, Accuracy, and Evasion with normal stage clamping.

Crucial runtime fact: **`effect_specs` execute regardless of the move's coverage label.** Therefore `DATA_ONLY` is not a safety barrier by itself. A false generated effect must be removed or corrected.

## Coverage meaning

- `RUNTIME_SUPPORTED`: audited battle semantics represented faithfully.
- `PARTIAL_RUNTIME`: a faithful subset executes; known mechanics are absent.
- `DATA_ONLY`: data preserved; no faithful executable behavior should be implied.
- `UNSUPPORTED`: explicitly outside the current contract.

Never promote coverage merely because a generic `effect_spec` exists. Never leave a known-false executable effect merely because the label says DATA_ONLY.
