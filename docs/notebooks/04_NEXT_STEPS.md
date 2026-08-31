# NEXT STEPS — LIVE CHECKPOINT

Read immediately after `00_READ_FIRST.md` when recovering context.

## Latest certified baseline
- PR #79 — `audit/data-v3-ability-hit-stat-reactions-v1`
- Final HEAD `5b9ad561017fc4c209d6fd11ef9ddc7dbf3fbd71`
- **18/18 SUCCESS** on exact notebook-bearing HEAD
- closed without merge.

Move Effects V3 remains closed:
- **590 runtime / 71 partial / 246 data-only / 12 unsupported**;
- `DATA_ONLY` moves with executable `effect_specs`: **0**.

Certified #79 ability coverage:
- `RUNTIME_SUPPORTED`: **8**
- `PARTIAL_RUNTIME`: **4** — `intimidate`, `levitate`, `stamina`, `static`
- `DATA_ONLY`: **361**
- total: **373**.

Prior detailed ability notebooks: `06`, `07`, `08`, `09`.

# Current tranche — PR #80

- Branch: `audit/data-v3-ability-stat-damage-modifiers-v2`
- Parent: certified #79 final `5b9ad561017fc4c209d6fd11ef9ddc7dbf3fbd71`
- PR: #80 `DATA V3 — audit contact damage and attack-doubling abilities`
- Engineering SHA: `fecf7995e0284a0c7111239107aa3762f4e1233f`
- Engineering SHA: **18/18 SUCCESS**; DATA V3 and Godot global green.
- Detailed current notebook: `docs/notebooks/10_DATA_V3_ABILITY_STAT_DAMAGE_MODIFIERS.md`.

## #80 result

### Tough Claws / Garra Dura
Pinned immutable source is Generation VI/main-series and says contact moves are `1.33x` power, with no historical effect changes recorded.

That prose is stale relative to audited current main-series mechanics. DATA V3 therefore:
- leaves immutable source untouched;
- fail-fast validates the pinned `1.33x` source shape;
- normalizes only the loaded project-owned record to `Boosts the power of moves that make contact by 30%.`;
- registers `MODIFY_DAMAGE` with `requires_contact=true` and `multiplier_bp=13000`.

Decision: **`tough_claws → RUNTIME_SUPPORTED`**.

Real-battle integration verifies:
- contact Tackle is boosted and emits the ability trigger;
- non-contact Earthquake is unchanged and emits no Tough Claws trigger.

### Huge Power / Pure Power
Both remain **`DATA_ONLY`**.

Pinned source explicitly says **Attack is doubled in battle**, not final physical damage. Until Battle Core has a genuine offensive-stat multiplier abstraction, mapping either ability to a blanket physical-damage x2 would overclaim fidelity. Tests enforce both records remain DATA_ONLY and have no MODIFY_DAMAGE mapping.

## Ability coverage after #80 engineering
- `RUNTIME_SUPPORTED`: **9**
- `PARTIAL_RUNTIME`: **4**
- `DATA_ONLY`: **360**
- total: **373**.

## Exact #79 → #80 artifact
Raw + normalized:
- exactly one changed ability: `tough_claws`;
- exactly three changed fields:
  - `classification: DATA_ONLY → RUNTIME_SUPPORTED`
  - corrected `description`
  - corrected `effect_summary`.

Reports move only Tough Claws and update counts 8→9 runtime / 361→360 data-only. Partial remains 4.

Huge Power and Pure Power are unchanged. No other ability, Pokémon/species, move/effect, item, learnset, evolution, type or stat changed. Manifest/forms/auxiliary are unchanged. `import_time_ms` 516→495 ms is non-semantic.

## Implementation safety catch
A draft edit that would have broadly replaced `tools/pokeapi_adapter_v3.py` was detected by the pre-PR compare check and removed before PR creation. The actual #80 diff keeps that adapter identical to certified #79 and confines the correction to the ability contract layer.

## Current certification step
Notebook synchronization now moves the branch after engineering SHA `fecf7995e0284a0c7111239107aa3762f4e1233f`.

Before closing #80:
1. verify engineering SHA → final HEAD changes only `01_PROJECT_STATE.md`, `04_NEXT_STEPS.md`, `10_DATA_V3_ABILITY_STAT_DAMAGE_MODIFIERS.md`;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #80 without merge;
4. use exact final HEAD as next baseline.

## Exact next task after #80 closure
Continue **DATA FOUNDATION V3 ability reliability** with another bounded subgroup selected from the remaining DATA_ONLY records.

Audit source + existing predicates first. Do not bulk-convert `stat_damage_modifier`, and do not introduce broad weather/status/party/form mechanics merely to improve the coverage number. Huge Power/Pure Power remain deferred until an offensive-stat multiplier primitive exists.

Trainer AI/archetypes remain deferred.

## Stop condition
Any focal/regression failure stops the tranche until root cause is fixed and rerun.
