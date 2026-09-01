# DATA V3 ABILITY FAMILY INVENTORY — V1

## Purpose

Operational checkpoint for the ability-family work that follows certified PR #76.

Use this notebook together with:
- `01_PROJECT_STATE.md` for broad project state;
- `04_NEXT_STEPS.md` for the live pointer;
- `06_DATA_V3_ABILITY_RUNTIME_AUDIT.md` for the initial six-ability semantic audit.

## Certified parent

- PR #76: `DATA V3 — establish audited ability runtime contracts`.
- Certified final HEAD: `a596a38680b60db317f1dfd6b6beb8d7ded7b813`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Ability coverage at parent:
  - `RUNTIME_SUPPORTED`: 3 (`blaze`, `overgrow`, `torrent`)
  - `PARTIAL_RUNTIME`: 3 (`intimidate`, `levitate`, `static`)
  - `DATA_ONLY`: 367
  - total: 373.

## Current tranche — PR #77

- Branch: `audit/data-v3-ability-family-inventory-v1`.
- PR: #77 `DATA V3 — inventory ability families and audit Swarm`.
- Engineering SHA: `3eb799c2fefc513ef925ebe329e4ad092954aef1`.
- Engineering SHA certification: **18/18 workflows SUCCESS**, including DATA Foundation V3 and Godot 4.7 global.

Scope is deliberately bounded:
1. inventory the exact 367-record DATA_ONLY frontier inherited from #76;
2. group it deterministically for planning only;
3. audit one clean family member (`swarm`);
4. forbid mass promotion of the other records.

The inventory is a triage device, **not a parser that grants runtime support**. Promotion still requires explicit immutable-source contracts and a matching Battle Core path.

## Deterministic family inventory — exact #76 frontier

The CI suite `tests/data/data_foundation_v3_ability_family_inventory_test_suite.gd` excludes only the six abilities already audited in #76, so it always accounts for the exact **367 records** that were DATA_ONLY at the start of this tranche.

Primary family counts:

| Family | Count |
|---|---:|
| `stat_damage_modifier` | 78 |
| `source_text_missing` | 60 |
| `immunity_absorb_prevention` | 53 |
| `move_property_control` | 38 |
| `weather_terrain` | 33 |
| `misc_unresolved` | 26 |
| `status_dependent` | 25 |
| `item_transaction` | 13 |
| `form_identity` | 12 |
| `contact_reactive` | 11 |
| `switch_party` | 11 |
| `faint_dependent` | 6 |
| `pinch_type_boost` | 1 |
| **Total** | **367** |

Important boundaries:
- `source_text_missing` (60) is an explicit blocker. Missing source prose is never evidence for support.
- `contact_reactive` contains 11 records: `cute_charm`, `effect_spore`, `flame_body`, `gooey`, `iron_barbs`, `mummy`, `pickpocket`, `poison_point`, `poison_touch`, `rough_skin`, `wandering_spirit`.
- Contact abilities are not mass-promoted because Static already exposed a faint-sensitive AFTER_DAMAGE gap.
- Weather/terrain, item transactions, switching/party state, form identity, faint-dependent behavior and move rewriting remain separate blocked families until their required state/transactions are modeled or explicitly shown to fit existing primitives.

The suite also fails if any former #76 DATA_ONLY ability other than the explicitly audited Swarm is silently promoted in this tranche.

## First bounded family — `pinch_type_boost`

The inventory finds exactly one unaudited member:

- `swarm`

This is the fourth battle-equivalent member of the existing Blaze / Overgrow / Torrent primitive.

### Immutable Swarm source

Snapshot record: `data/api/v2/ability/68/index.json`.

Current battle semantics:
- main-series ability;
- Generation III;
- when HP is **1/3 or less**, Bug-type moves deal **1.5x regular damage**.

The snapshot does contain `effect_changes`, unlike Blaze/Overgrow/Torrent. They are historical **overworld-only** changes (`overworld` encounter/cries behavior), not changes to the battle damage transaction.

The source guard therefore:
- requires the current 1/3 + Bug + 1.5x + damage semantics;
- requires every historical Swarm effect-change entry to remain explicitly overworld-only;
- fails if a historical effect change ever starts describing Bug damage, 1.5x, HP threshold or another battle semantic.

Decision: **`swarm → RUNTIME_SUPPORTED`** for the battle runtime.

## Runtime implementation

Swarm does not add a new Battle Core primitive.

`BattleEffectRegistry._register_abilities()` now reuses the same pinch loop:
- `blaze` → Fire
- `torrent` → Water
- `overgrow` → Grass
- `swarm` → Bug

Exact Swarm trigger:
- trigger: `MODIFY_DAMAGE`
- `move_type_id = bug`
- `hp_at_or_below_divisor = 3`
- `multiplier_bp = 15000`

The existing damage-modifier path already consumes this exact shape and is battle-tested by the original pinch abilities.

### Compatibility API decision

`runtime_supported_ability_ids()` remains frozen as the historical Battle V2 compatibility surface so old V2 coverage fixtures do not get rewritten merely because DATA V3 expands.

New `BattleEffectRegistry.implemented_ability_ids()` returns the actual `_ability_specs` trigger registry and is used by DATA V3 semantic-reliability tests.

After Swarm, actual implemented ability IDs are:
`blaze`, `intimidate`, `levitate`, `overgrow`, `static`, `swarm`, `torrent`.

## Ability coverage after #77 engineering build

- `RUNTIME_SUPPORTED`: **4** — `blaze`, `overgrow`, `swarm`, `torrent`
- `PARTIAL_RUNTIME`: **3** — `intimidate`, `levitate`, `static`
- `DATA_ONLY`: **366**
- total: **373**

No other ability is promoted.

## Exact #76 → #77 engineering artifact comparison

Compared certified #76 final artifact with engineering artifact from `3eb799c2fefc513ef925ebe329e4ad092954aef1`.

Raw dataset:
- exactly one changed ability: `swarm`;
- exactly one changed field: `classification`;
- `DATA_ONLY → RUNTIME_SUPPORTED`.

Normalized dataset:
- exactly the same single `swarm.classification` change.

Unchanged in raw + normalized:
- every other ability record;
- species/Pokémon data;
- all moves and `effect_specs`;
- items;
- learnsets;
- evolutions;
- types and stats.

Reports:
- `pokeapi_v3_audit.json`: `RUNTIME_SUPPORTED 3→4`, `DATA_ONLY 367→366`;
- `unsupported_mechanics.json`: Swarm moves from DATA_ONLY list to RUNTIME_SUPPORTED list and the same two counts change;
- `import_summary.json`: only nondeterministic import timing changed (`512→519 ms`), which is non-semantic.

Manifest, forms report and auxiliary report are unchanged.

## Certification state

Engineering SHA `3eb799c2fefc513ef925ebe329e4ad092954aef1`: **18/18 SUCCESS**.

Notebook synchronization now moves HEAD. Before closing #77:
1. update `01_PROJECT_STATE.md` and `04_NEXT_STEPS.md` to point here;
2. verify engineering SHA → final HEAD changes only notebooks;
3. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
4. close #77 without merge;
5. use that exact SHA as the next certified parent.

## Next bounded candidate — do not implement in #77

`steelworker` is the clearest next candidate from `stat_damage_modifier`.

Immutable snapshot `data/api/v2/ability/200/index.json` says:
- main-series, Generation VII;
- "This Pokémon's Steel moves have 1.5x power";
- `effect_changes=[]`.

The current `MODIFY_DAMAGE` primitive appears capable of expressing this as a simple unconditional Steel-type 1.5x multiplier, but **Steelworker is not audited or promoted in #77**. The next tranche must still perform an explicit source/runtime contract, focal test and artifact-diff cycle before changing its classification.

Do not jump directly from this observation to Transistor / Dragon's Maw / Rocky Payload: their preserved short prose lacks the numeric multiplier needed for the same source-only proof and therefore requires separate evidence/audit.
