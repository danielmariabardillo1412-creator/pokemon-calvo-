# NEXT STEPS — LIVE CHECKPOINT

Read immediately after `00_READ_FIRST.md` when recovering context.

## Latest certified baseline before current tranche
- PR #74 — `fix/data-v3-all-pokemon-semantics`
- Final HEAD `9a917fea11df07c3aa26c8962e2dca9784a41875`
- 18/18 SUCCESS on exact notebook-bearing HEAD
- closed without merge.

## Current tranche — PR #75
- Branch: `fix/data-v3-final-data-only-effects`
- Parent: certified #74 final `9a917fea11df07c3aa26c8962e2dca9784a41875`
- Engineering SHA before notebooks: `db73a16b631f4e7bd539ac5e73b288401489d39a`
- Engineering SHA: **18/18 SUCCESS**; DATA V3 and Godot global green.

### Purify
Requires an eligible target status, cures it, then heals the user up to 50%; legacy unconditional SELF 50% heal was unsafe.
Decision: `DATA_ONLY`, `effect_specs=[]`.

### Swallow
Requires Stockpile, heals 25%/50%/100% at levels 1/2/3, consumes Stockpile and associated defensive changes; legacy flat SELF 25% heal was unsafe.
Decision: `DATA_ONLY`, `effect_specs=[]`.

### Beat Up
Party-dependent multi-hit attack whose eligible strike count depends on conscious/non-statused party members and whose modern strike power is party-member-dependent; legacy fixed 6-hit spec was false.
Decision: `DATA_ONLY`, `effect_specs=[]`.

## Exact #74 → #75 engineering artifact
Raw and normalized agree:
- only `beat_up`, `purify`, `swallow` changed;
- on all three only `effect_specs` and `effect_summary` changed;
- coverage remains **590 runtime / 71 partial / 246 data-only / 12 unsupported**;
- `DATA_ONLY` with non-empty `effect_specs`: **0**.

Important milestone: **Move Effects V3 executable-safety frontier is closed.**

## Current certification step
Notebook synchronization moves SHA. Before closing #75:
1. verify only notebooks 01/02/04 changed after engineering SHA `db73a16b631f4e7bd539ac5e73b288401489d39a`;
2. require 18/18 on exact final notebook-bearing HEAD;
3. close #75 without merge;
4. use that exact HEAD as next baseline.

## Exact next task after #75 closure
Begin a new DATA V3 reliability workstream for **Ability runtime-support contracts**.

First tranche should be an inventory/audit, not mass implementation:
- enumerate the 373 preserved ability records;
- identify which abilities have actual Battle Core/runtime mechanics versus metadata-only storage;
- identify any ability records whose current labels or executable paths imply more support than exists;
- establish explicit coverage semantics/tests before implementing additional abilities;
- create a dedicated ability-audit notebook rather than bloating this live pointer.

Do not implement hundreds of abilities at once and do not switch back to trainer AI/archetypes yet.

## Workstream
**DATA FOUNDATION V3 semantic reliability. Move Effects V3 is closing; Abilities are next.**

## Safety rule
Preserved source metadata is not equivalent to implemented runtime mechanics. Coverage/support claims must match what the engine can actually execute.

## Stop condition
Any focal/regression failure stops the tranche until root cause is fixed and rerun.
