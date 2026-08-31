# NEXT STEPS — LIVE CHECKPOINT

Read immediately after `00_READ_FIRST.md` when recovering context.

## Latest certified baseline before current tranche
- PR #73 — `fix/data-v3-user-terminal-state-d`
- Final HEAD `67ba79e9a68a78669ee5ae04166a47ee11331bc7`
- 18/18 SUCCESS on exact notebook-bearing HEAD
- closed without merge.

## Current tranche — PR #74
- Branch: `fix/data-v3-all-pokemon-semantics`
- Parent: certified #73 final `67ba79e9a68a78669ee5ae04166a47ee11331bc7`
- Engineering SHA before notebooks: `99a435c291514612b5c1ce43ad2a28e47797c6c0`
- Engineering SHA: **18/18 SUCCESS**; DATA V3 and Godot global green.

### Flower Shield
Real move affects eligible Grass-type Pokémon across the field, not simply the opponent; Gen IX cannot select it. Legacy OPPONENT Defense +1 is false.
Decision: `DATA_ONLY`, `effect_specs=[]`; canonical summary records eligibility/current availability.

### Rototiller
Real move affects eligible grounded Grass-type Pokémon across the field, fails if none, and is unavailable for selection from Gen VIII onward. Legacy OPPONENT Attack/SpAtk +1 is false.
Decision: `DATA_ONLY`, `effect_specs=[]`; canonical summary records grounded/type/current availability.

## Exact #73 → #74 engineering artifact
- only `flower_shield` and `rototiller` changed;
- on both only `effect_specs` and `effect_summary` changed;
- coverage remains **590 runtime / 71 partial / 246 data-only / 12 unsupported**.

Important milestone: **all DATA_ONLY stat-change records with executable specs are now resolved**.

Only three DATA_ONLY records still have non-empty `effect_specs`:
1. `Purify`
2. `Swallow`
3. `Beat Up`

## Current certification step
Notebook synchronization moves SHA. Before closing #74:
1. verify only notebooks 01/02/04 changed after engineering SHA `99a435c291514612b5c1ce43ad2a28e47797c6c0`;
2. require 18/18 on exact final notebook-bearing HEAD;
3. close #74 without merge;
4. use that exact HEAD as next baseline.

## Exact next task
Audit the three remaining non-stat cases. Suggested order:
- `Purify`: source/current mechanic cures the selected target's major status and heals the user only if the cure succeeds; current generated SELF heal may grant a free heal without the cure transaction.
- `Swallow`: healing magnitude and legality depend on Stockpile count and consume that state; a flat heal without prerequisite/consumption is unsafe.
- `Beat Up`: hit count/damage depend on eligible party members rather than a fixed generic six-hit transaction.

Do not change Battle Core merely to make these records executable. If a faithful subset cannot be guaranteed, prefer effect-free `DATA_ONLY`.

## Workstream
**Move Effects V3 / battle-relevant DATA V3 semantic audit. Do not switch to trainer AI/archetypes.**

## Safety rule
`effect_specs` execute regardless of coverage label. `DATA_ONLY` is not an execution gate.

## Stop condition
Any focal/regression failure stops the tranche until root cause is fixed and rerun.
