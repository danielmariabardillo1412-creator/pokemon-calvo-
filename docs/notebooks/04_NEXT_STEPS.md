# NEXT STEPS — LIVE CHECKPOINT

Read immediately after `00_READ_FIRST.md` when recovering context.

## Latest certified baseline
- PR #75 — `fix/data-v3-final-data-only-effects`
- Final HEAD `4bb4bdc64982eef62f126f8d1c38e9509d21c96c`
- 18/18 SUCCESS on exact notebook-bearing HEAD
- closed without merge.

Move Effects V3 milestone at this baseline:
- move coverage: **590 runtime / 71 partial / 246 data-only / 12 unsupported**;
- `DATA_ONLY` moves with non-empty `effect_specs`: **0**.

## Current tranche — PR #76
- Branch: `audit/data-v3-ability-runtime-contracts-v1`
- Parent: certified #75 final `4bb4bdc64982eef62f126f8d1c38e9509d21c96c`
- Engineering SHA: `8e1ea4e443ef76dcca8f83ebf49c0ea282f4c890`
- Engineering SHA: **18/18 SUCCESS**; DATA V3 and Godot global green.
- Detailed state: `docs/notebooks/06_DATA_V3_ABILITY_RUNTIME_AUDIT.md`.

## Ability audit decision
DATA V3 preserves **373** ability records. Battle Core currently has explicit trigger implementations for six IDs.

New semantic classification:

- `RUNTIME_SUPPORTED` **3**: `blaze`, `overgrow`, `torrent`
- `PARTIAL_RUNTIME` **3**: `intimidate`, `levitate`, `static`
- `DATA_ONLY` **367**

Why partial:
- `intimidate`: base switch-in Attack drop works; additional source battle semantics are missing.
- `levitate`: Ground-move immunity works; field/suppression semantics are missing.
- `static`: ordinary 30% contact paralysis works, but fatal contact currently cannot trigger because the knocked-out ability owner is excluded from AFTER_DAMAGE trigger execution.

Do not quick-fix Static by globally firing all post-damage triggers on fainted owners; held-item triggers share that infrastructure and need a deliberate faint-safe engine policy.

## Implementation / regression protection
- explicit source-validated six-ID contract: `tools/pokeapi_ability_runtime_contracts.py`;
- DATA V3 adapter publishes exact ability coverage labels/counts;
- dedicated Godot DATA V3 suite enforces exact **3 / 3 / 367** plus registry consistency;
- all unlisted abilities remain `DATA_ONLY` until explicitly audited.

## Exact #75 → #76 engineering artifact
Raw + normalized:
- exactly six semantic changes;
- only `classification` changes for Blaze, Overgrow, Torrent, Intimidate, Levitate and Static.

Reports add ability classification IDs/counts and source-audit checks. No species, move/effect, item, learnset, evolution, type or stat drift. Manifest/forms/auxiliary reports unchanged. `import_time_ms` variation is timing noise only.

## Current certification step
Notebook synchronization moves the SHA. Before closing #76:
1. verify engineering SHA `8e1ea4e443ef76dcca8f83ebf49c0ea282f4c890` → final HEAD changes only notebooks;
2. require 18/18 SUCCESS on that exact final notebook-bearing HEAD;
3. close #76 without merge;
4. use exact final HEAD as next baseline.

## Exact next task after #76 closure
Continue the **Ability runtime-support audit**, but in bounded families rather than one ability per session or all 367 at once.

Next tranche:
- inventory the remaining 367 `DATA_ONLY` abilities by semantic family;
- identify families already expressible with current Battle Core primitives (damage modifiers, type immunity, switch-in stat changes, contact/status triggers, end-turn effects, etc.);
- choose one bounded high-confidence family and audit it against immutable source;
- do not implement new general engine primitives merely to improve coverage numbers.

## Workstream
**DATA FOUNDATION V3 semantic reliability — Abilities.** Trainer AI/archetypes remain deferred.

## Stop condition
Any focal/regression failure stops the tranche until root cause is fixed and rerun.
