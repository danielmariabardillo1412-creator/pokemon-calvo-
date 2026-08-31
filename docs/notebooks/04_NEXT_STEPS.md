# NEXT STEPS — LIVE CHECKPOINT

Read immediately after `00_READ_FIRST.md` when recovering context.

## Latest certified baseline
- PR #76 — `audit/data-v3-ability-runtime-contracts-v1`
- Final HEAD `a596a38680b60db317f1dfd6b6beb8d7ded7b813`
- 18/18 SUCCESS on exact notebook-bearing HEAD
- closed without merge.

Move Effects V3 remains closed:
- move coverage: **590 runtime / 71 partial / 246 data-only / 12 unsupported**;
- `DATA_ONLY` moves with non-empty `effect_specs`: **0**.

Ability coverage at certified #76:
- `RUNTIME_SUPPORTED`: **3** — `blaze`, `overgrow`, `torrent`
- `PARTIAL_RUNTIME`: **3** — `intimidate`, `levitate`, `static`
- `DATA_ONLY`: **367**

Detailed #76 audit: `docs/notebooks/06_DATA_V3_ABILITY_RUNTIME_AUDIT.md`.

# Current tranche — PR #77

- Branch: `audit/data-v3-ability-family-inventory-v1`
- Parent: certified #76 final `a596a38680b60db317f1dfd6b6beb8d7ded7b813`
- PR: #77 `DATA V3 — inventory ability families and audit Swarm`
- Engineering SHA: `3eb799c2fefc513ef925ebe329e4ad092954aef1`
- Engineering SHA: **18/18 SUCCESS**; DATA V3 and Godot global green.
- Detailed current notebook: `docs/notebooks/07_DATA_V3_ABILITY_FAMILY_INVENTORY.md`.

## #77 result
The exact **367-record** DATA_ONLY frontier inherited from #76 is now deterministically partitioned into 13 CI-enforced triage families. This inventory does not grant support automatically.

Largest buckets:
- `stat_damage_modifier`: 78
- `source_text_missing`: 60
- `immunity_absorb_prevention`: 53
- `move_property_control`: 38
- `weather_terrain`: 33

The `pinch_type_boost` family contains exactly one unaudited member: `swarm`.

### Swarm
Immutable source `data/api/v2/ability/68/index.json` confirms:
- main-series Generation III ability;
- <=1/3 HP;
- Bug moves deal 1.5x regular damage;
- historical `effect_changes` are overworld-only.

Decision: **`swarm → RUNTIME_SUPPORTED`**.

Runtime implementation reuses the existing Blaze/Torrent/Overgrow MODIFY_DAMAGE path with:
- `move_type_id=bug`
- `hp_at_or_below_divisor=3`
- `multiplier_bp=15000`

No new Battle Core primitive was introduced.

## Ability coverage after #77 engineering
- `RUNTIME_SUPPORTED`: **4** — `blaze`, `overgrow`, `swarm`, `torrent`
- `PARTIAL_RUNTIME`: **3** — `intimidate`, `levitate`, `static`
- `DATA_ONLY`: **366**
- total: **373**

## Exact #76 → #77 engineering artifact
Raw + normalized:
- exactly one semantic change;
- `swarm.classification: DATA_ONLY → RUNTIME_SUPPORTED`.

No other ability, species, move/effect, item, learnset, evolution, type or stat changed. Reports change only matching ability counts/lists; import-time variation is non-semantic.

## Current certification step
Notebook synchronization has moved the branch after engineering SHA `3eb799c2fefc513ef925ebe329e4ad092954aef1`.

Before closing #77:
1. verify engineering SHA → final HEAD changed only notebook files;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #77 without merge;
4. use exact final HEAD as next baseline.

## Exact next task after #77 closure
Continue the ability audit with **one bounded family/candidate**, not a bulk conversion.

First candidate: `steelworker` (`data/api/v2/ability/200/index.json`). Immutable source says Steel moves have 1.5x power and has `effect_changes=[]`; current MODIFY_DAMAGE appears sufficient for an unconditional Steel multiplier. It is **not yet audited or promoted**.

Do not infer the same multiplier for Transistor / Dragon's Maw / Rocky Payload from their short preserved prose alone; they require separate evidence.

## Workstream
**DATA FOUNDATION V3 semantic reliability — Abilities.** Trainer AI/archetypes remain deferred.

## Stop condition
Any focal/regression failure stops the tranche until root cause is fixed and rerun.
