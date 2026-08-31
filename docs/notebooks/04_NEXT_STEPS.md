# NEXT STEPS — LIVE CHECKPOINT

Read immediately after `00_READ_FIRST.md` when recovering context.

## Latest certified baseline
- PR #78 — `audit/data-v3-ability-type-boosts-v1`
- Final HEAD `eda483d9cd6423d32bdf1a156372416b2fbcb639`
- **18/18 SUCCESS** on exact notebook-bearing HEAD
- closed without merge.

Move Effects V3 remains closed:
- **590 runtime / 71 partial / 246 data-only / 12 unsupported**;
- `DATA_ONLY` moves with executable `effect_specs`: **0**.

Certified #78 ability coverage:
- `RUNTIME_SUPPORTED`: **8**
- `PARTIAL_RUNTIME`: **3** — `intimidate`, `levitate`, `static`
- `DATA_ONLY`: **362**
- total: **373**.

Prior ability notebooks: `06`, `07`, `08`.

# Current tranche — PR #79

- Branch: `audit/data-v3-ability-hit-stat-reactions-v1`
- Parent: certified #78 final `eda483d9cd6423d32bdf1a156372416b2fbcb639`
- PR: #79 `DATA V3 — audit hit-triggered stat ability reactions`
- Engineering SHA: `748b28b69d19be5912bbc0318f2e8e8d40f3eccd`
- Engineering SHA: **18/18 SUCCESS**; DATA V3 and Godot global green.
- Detailed notebook: `docs/notebooks/09_DATA_V3_ABILITY_HIT_STAT_REACTIONS.md`.

## #79 result

### Stamina
Pinned source `data/api/v2/ability/192/index.json`:
- main-series Generation VII;
- taking damage from a move raises Defense one stage;
- `effect_changes=[]`.

Implemented faithful subset:
- `AFTER_DAMAGE`
- SELF Defense `+1`
- no contact/physical/type/HP gate.

Decision: **`stamina → PARTIAL_RUNTIME`**, not full support.

Reason for partial classification: current Battle Core fires AFTER_DAMAGE once after the complete move. MULTI_HIT resolves its strikes internally before that trigger, so Stamina cannot currently activate per strike. Fainted owners are also excluded from trigger execution.

A dedicated DATA V3 integration suite uses a real `AuthoritativeBattleServer` and verifies:
- Tackle damage to a surviving Stamina owner → Defense +1 + `ABILITY_TRIGGERED`;
- Growl/non-damage → no Stamina trigger.

### Explicit blockers
- `water_compaction` remains `DATA_ONLY`: current AFTER_DAMAGE conditions cannot require Water type without adding a broader primitive.
- `weak_armor` remains `DATA_ONLY`: dual stat transaction + per-hit/version semantics exceed this tranche.

## Ability coverage after #79 engineering
- `RUNTIME_SUPPORTED`: **8**
- `PARTIAL_RUNTIME`: **4** — `intimidate`, `levitate`, `stamina`, `static`
- `DATA_ONLY`: **361**
- total: **373**.

## Exact #78 → #79 artifact
Raw + normalized:
- exactly one semantic change;
- `stamina.classification: DATA_ONLY → PARTIAL_RUNTIME`.

No other ability, species, move/effect, item, learnset, evolution, type or stat changed. Reports move only Stamina and adjust the matching counts. Manifest/forms/auxiliary are unchanged. Import-time variation is non-semantic.

## Current certification step
Notebook synchronization has moved the branch after engineering SHA `748b28b69d19be5912bbc0318f2e8e8d40f3eccd`.

Before closing #79:
1. verify engineering SHA → final HEAD changed only `01_PROJECT_STATE.md`, `04_NEXT_STEPS.md`, `09_DATA_V3_ABILITY_HIT_STAT_REACTIONS.md`;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #79 without merge;
4. use exact final HEAD as next baseline.

## Exact next task after #79 closure
Continue **DATA FOUNDATION V3 ability reliability**.

Triage the remaining `stat_damage_modifier` family for another bounded set whose semantics already fit existing Battle Core primitives. Do not implement Water Compaction or Weak Armor by shortcut and do not broaden Battle Core solely to improve the coverage number. If that bucket yields no clean candidate, record the negative result and move to another family.

Trainer AI/archetypes remain deferred.

## Stop condition
Any focal/regression failure stops the tranche until root cause is fixed and rerun.
