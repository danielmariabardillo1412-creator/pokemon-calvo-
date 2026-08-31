# DATA V3 ABILITY RUNTIME AUDIT NOTEBOOK

## Purpose

Operational continuity for the ability reliability workstream that starts after Move Effects V3 executable-safety closure.

This notebook is authoritative for the **current ability audit only**. `01_PROJECT_STATE.md` remains the broad project state and `04_NEXT_STEPS.md` remains the short live pointer.

## Certified parent

- Parent workstream: PR #75 — final DATA_ONLY executable move effects.
- Certified parent HEAD: `4bb4bdc64982eef62f126f8d1c38e9509d21c96c`.
- Parent status: 18/18 workflows SUCCESS, PR closed without merge.
- Move Effects V3 safety milestone: `0 DATA_ONLY` move records with non-empty executable `effect_specs`.

## Current tranche — PR #76

- Branch: `audit/data-v3-ability-runtime-contracts-v1`.
- PR: #76 `DATA V3 — establish audited ability runtime contracts`.
- Goal: establish honest runtime-support semantics for the six abilities already registered in Battle Core before auditing the remaining preserved ability corpus.
- Scope: classification/contracts/tests only for those six; no mass ability implementation.
- Engineering SHA: `8e1ea4e443ef76dcca8f83ebf49c0ea282f4c890`.
- Engineering SHA certification: **18/18 workflows SUCCESS**, including DATA Foundation V3 and Godot 4.7 global.

## Coverage semantics

- `RUNTIME_SUPPORTED`: the battle-relevant source mechanic is faithfully represented by the current engine for states/mechanics the project claims to model; no known missing intrinsic transaction changes the result.
- `PARTIAL_RUNTIME`: a real, useful subset executes correctly, but at least one source-required battle behavior/condition is missing or an in-scope edge case is wrong.
- `DATA_ONLY`: source metadata is preserved but no executable ability mechanic is claimed.
- `UNSUPPORTED`: reserved for ability mechanics that cannot be represented/retained safely under the current contract; do not use merely because an ability is unimplemented.

Coverage labels are claims, not execution gates. Runtime behavior is still determined by Battle Core trigger registrations.

## Certified engineering classification

### `RUNTIME_SUPPORTED`

- `blaze`
- `overgrow`
- `torrent`

Immutable source and engine agree on the relevant battle transaction: at 1/3 max HP or less, matching Fire/Grass/Water moves deal 1.5x regular damage. Battle Core uses `hp_at_or_below_divisor = 3`, `multiplier_bp = 15000`, and the multiplier is consumed by the actual damage calculation.

### `PARTIAL_RUNTIME` — Intimidate

Current Battle Core correctly lowers the opposing active Pokémon's Attack one stage on switch-in in the singles model. The preserved source also includes battle semantics not represented by the current trigger model, including ability acquisition/reacquisition and Substitute-related behavior.

Decision: `PARTIAL_RUNTIME` rather than falsely claiming complete support.

### `PARTIAL_RUNTIME` — Levitate

Current Battle Core correctly blocks Ground-type move damage. The preserved source additionally covers grounded-field interactions and suppression conditions such as Spikes, Toxic Spikes, Arena Trap, Gravity, Ingrain and Iron Ball.

Decision: `PARTIAL_RUNTIME`.

### `PARTIAL_RUNTIME` — Static

Ordinary behavior works: after contact damage, the engine gives a 30% chance to paralyze the attacker.

A real edge-case gap remains: `TurnExecutor` requests the target's AFTER_DAMAGE triggers only while that target remains alive, and `_execute_triggers` also rejects knocked-out owners. Therefore a contact hit that knocks out the Static holder cannot currently trigger Static.

Do **not** patch generic AFTER_DAMAGE semantics inside this data audit. The trigger infrastructure is shared with held items, so faint-safe triggering needs a deliberate Battle Core policy rather than a shortcut that could heal/consume items on invalid fainted states.

Decision: `PARTIAL_RUNTIME` until that engine behavior is deliberately implemented and tested.

## Exact classification counts after #76 engineering build

For all 373 preserved ability records:

- `RUNTIME_SUPPORTED`: **3**
- `PARTIAL_RUNTIME`: **3**
- `DATA_ONLY`: **367**
- total: **373**

The six IDs with explicit Battle Core trigger implementations remain exactly:
`blaze`, `intimidate`, `levitate`, `overgrow`, `static`, `torrent`.

The historical `BattleEffectRegistry.runtime_supported_ability_ids()` still names those six implementation IDs. DATA V3 now provides the stricter semantic-completeness split above.

## Implementation

- `tools/pokeapi_ability_runtime_contracts.py`
  - explicit allowlist for the six audited abilities;
  - fail-fast checks against immutable source semantics;
  - every unlisted ability remains `DATA_ONLY`.
- `tools/pokeapi_adapter_v3.py`
  - emits audited ability classifications;
  - publishes ability classification counts and exact IDs in audit/report data.
- `tests/data/data_foundation_v3_ability_runtime_contract_test_suite.gd`
  - verifies exact 3/3/367 partition;
  - verifies all six audited IDs;
  - verifies consistency with the six Battle Core registered ability IDs.
- `tests/data/data_foundation_v3_domain_test_runner.gd`
  - runs the new suite in DATA V3 CI.

## Exact #75 → #76 engineering artifact comparison

Compared certified #75 final artifact (`4bb4bdc64982eef62f126f8d1c38e9509d21c96c`) with #76 engineering artifact (`8e1ea4e443ef76dcca8f83ebf49c0ea282f4c890`).

Raw dataset:
- exactly six semantic changes, all under `abilities[*].classification`;
- Blaze / Overgrow / Torrent: `DATA_ONLY → RUNTIME_SUPPORTED`;
- Intimidate / Levitate / Static: `DATA_ONLY → PARTIAL_RUNTIME`.

Normalized dataset:
- exactly the same six classification changes by ability ID.

Reports:
- `unsupported_mechanics.json` gains explicit ability classification IDs/counts plus the updated ability-coverage note;
- `pokeapi_v3_audit.json` gains `ability_classification_counts` and `audited_ability_ids_present=true`.

Unchanged:
- species/Pokémon data;
- moves and `effect_specs`;
- items;
- learnsets/evolutions/types/stats;
- manifest, forms report and auxiliary report.

`import_summary.json` differs only in nondeterministic `import_time_ms` (`517 → 521` ms); this is execution timing noise, not canonical semantic drift.

## Certification state

Engineering SHA `8e1ea4e443ef76dcca8f83ebf49c0ea282f4c890`: **18/18 SUCCESS**.

Notebook synchronization now moves the branch HEAD. Before #76 can be closed without merge:

1. update operational notebooks with this exact result;
2. verify engineering SHA → final HEAD changes only notebook files;
3. require **18/18 SUCCESS** again on that exact notebook-bearing final HEAD;
4. close PR #76 without merge;
5. use that exact final HEAD as the next baseline.

## Next work after #76 certification

Do not implement hundreds of abilities at once. Inventory/classify the remaining 367 by semantic families and identify which families can be represented safely by existing Battle Core primitives. First follow-up tranche should be family inventory/prioritization plus one bounded family audit, not a mass conversion.
