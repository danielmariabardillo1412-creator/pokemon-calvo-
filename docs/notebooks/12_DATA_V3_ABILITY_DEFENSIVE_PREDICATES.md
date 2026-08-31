# DATA V3 ABILITY DEFENSIVE PREDICATES — V1

## Purpose
Operational checkpoint for the bounded ability tranche following certified PR #81.

## Certified parent
- PR #81: `DATA V3 — audit defensive damage ability modifiers`.
- Certified final HEAD: `e2eeef1d23def1d9fd124b5e2eeb437270212b68`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Ability coverage at parent: **11 RUNTIME_SUPPORTED / 4 PARTIAL_RUNTIME / 358 DATA_ONLY / 373 total**.

## Current tranche
- Branch: `audit/data-v3-ability-defensive-predicates-v2`.
- Exact parent: certified #81 final `e2eeef1d23def1d9fd124b5e2eeb437270212b68`.
- Goal: audit a small defensive subgroup that can be represented by extending the existing generic `MODIFY_DAMAGE` condition surface, without opening weather, terrain, party, form, item, critical-hit, type-effectiveness, or status-residual architecture.

## Source audit

### Ice Scales
Pinned immutable source:
- `data/api/v2/ability/246/index.json`;
- main-series Generation VIII;
- halves damage taken from special moves;
- `effect_changes=[]`.

Candidate decision: **RUNTIME_SUPPORTED** if Battle Core adds a generic `requires_special` mirror of the existing `requires_physical` predicate.

### Multiscale
Pinned immutable source:
- `data/api/v2/ability/136/index.json`;
- main-series Generation V;
- halves damage taken while the owner is at full HP;
- `effect_changes=[]`.

Battle Core already reevaluates `damage_modifiers()` inside each `_damage()` call. `MULTI_HIT` calls `_damage()` once per hit, so a generic `requires_full_hp` target predicate will naturally apply only while HP is still full. The certified #81 DATA V3 artifact contains 27 `RUNTIME_SUPPORTED` multihit moves, including fixed two-hit `double_kick` and variable 2–5-hit families.

Candidate decision: **RUNTIME_SUPPORTED** if focal integration confirms first-hit-only reduction on a canonical multihit move and ordinary full/not-full behavior.

### Heatproof
Pinned immutable source:
- `data/api/v2/ability/85/index.json`;
- main-series Generation IV;
- halves damage from Fire-type moves **and burns**;
- `effect_changes=[]`.

`StatusSystem.process_end_turn()` currently computes burn residual damage directly and does not route it through `MODIFY_DAMAGE` or another ability modifier hook.

Candidate decision: **PARTIAL_RUNTIME** for the faithful Fire-move half-damage subset only. Do not claim RUNTIME_SUPPORTED until burn residual damage can be modified through an explicit status/ability contract.

### Filter / Solid Rock
Pinned source for both says 0.75x damage from moves that are super effective against the owner; both have `effect_changes=[]` and are explicitly equivalent to each other.

Decision for this tranche: **remain DATA_ONLY**. Current `damage_modifiers()` runs before `DamageCalculator.calculate()` produces the type-effectiveness result, so there is no certified generic `requires_super_effective` predicate. Do not duplicate type-chart logic inside ability registration solely to promote these records.

## Intended minimal Battle Core extension
Only two new generic condition keys are in scope:
- `requires_special=true` — exact mirror of existing `requires_physical`;
- `requires_full_hp=true` — owner `current_hp == max_hp`.

No new trigger type and no new damage formula are needed.

Expected registrations if focal tests pass:
- `ice_scales`: target `MODIFY_DAMAGE`, `requires_special=true`, `multiplier_bp=5000`;
- `multiscale`: target `MODIFY_DAMAGE`, `requires_full_hp=true`, `multiplier_bp=5000`;
- `heatproof`: target `MODIFY_DAMAGE`, `move_type_id=fire`, `multiplier_bp=5000`.

## Expected classification delta
If all three candidates pass:
- `RUNTIME_SUPPORTED`: 11 -> 13;
- `PARTIAL_RUNTIME`: 4 -> 5;
- `DATA_ONLY`: 358 -> 355;
- total remains 373.

Filter and Solid Rock remain DATA_ONLY.

## Test requirements
1. Registry/source-contract tests for exact conditions and classifications.
2. Ice Scales real battle: special damage reduced; physical control unchanged.
3. Multiscale real battle: full-HP damage reduced; pre-damaged control unchanged.
4. Multiscale canonical multihit: only the first hit is reduced once HP is no longer full; ability trigger count must reflect actual matching hits.
5. Heatproof real battle: Fire move damage reduced; non-Fire control unchanged.
6. Explicit Heatproof regression documenting that burn residual remains unmodified, therefore classification stays PARTIAL_RUNTIME.
7. Filter and Solid Rock explicit DATA_ONLY blockers.
8. Preserve exact 373 partition and no mass promotion.

## Closure protocol
Focal tests -> 18/18 engineering SHA -> exact artifact diff against #81 -> notebook sync (`01`, `04`, `12`) -> 18/18 exact final notebook-bearing SHA -> close without merge.
