# DATA V3 / MOVE EFFECTS V3 AUDIT NOTEBOOK

## Invariant
DATA V3 structural correctness is not enough: every executable `effect_spec` and every battle-relevant move field must be semantically faithful. If Battle Core cannot represent a mechanic, preserve only a provably faithful subset (`PARTIAL_RUNTIME`) or remove executable effects (`DATA_ONLY`). Coverage labels do not gate execution.

A subset is not automatically safe merely because each retained effect is individually true. If an omitted mechanic is a mandatory cost/transaction or can remove a strategic drawback, exposing the remaining effect can create a stronger fake move. In those cases prefer effect-free `DATA_ONLY`.

## Canonical source
- immutable `data/pokeapi-v2-snapshot`
- commit `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`
- `data/api/v2` + `data/schema/v2`
- move-effect compatibility corrections in `tools/pokeapi_adapter.py`
- source-selection/canonical-field conversion in `tools/pokeapi_adapter_v3.py`
- selected stateful audit layer in `tools/pokeapi_adapter_selected_stateful.py`
- archived V2 is provenance-only and must remain untouched.

## Recent certified heads
- #60 Magnetic Flux — `a5b56a0ba3a1efa81ac57be63b2813c19f2962a7`
- #61 pure SELF stat packages A — `623930ca0b98b00099288bcf542e7e0a922ac180`
- #62 pure opponent stat drops A — `6d1335b8c5cee0b1cf1e99910a7707734b4aef85`
- #63 always-hit accuracy semantics — `9f8b3e01bec1f86cff75380d68dd98d76e738e78`
- #64 selected special stat packages A — `674ccaf0928c93749c581565d53eb1f672dfd7b4`
All above: 18/18 and closed without merge.

## Certified transversal accuracy contract from #63
- numeric PokéAPI accuracy is preserved;
- source `accuracy=null` becomes canonical `-1`;
- `MoveDefinition` preserves `-1`;
- `BattleRuleset` treats negative base accuracy as always-hit (10000 bp), while a genuine 100 remains Accuracy/Evasion-stage-sensitive.

# PR #65 — selected stateful semantics (CURRENT)
Branch `fix/data-v3-selected-special-stateful-b`.
Parent: certified #64 final `674ccaf0928c93749c581565d53eb1f672dfd7b4`.
Engineering SHA before notebook sync: `01854416bf54179b0caa32b99459667d40d369c7`.
Engineering SHA: **18/18 SUCCESS**.

The four final `selected-pokemon` DATA_ONLY-with-specs cases were checked against both the immutable snapshot and current public Pokémon mechanics references before choosing runtime exposure.

## Defog
Immutable snapshot:
- target `selected-pokemon`
- `accuracy=null` → canonical `-1`
- status move
- Evasion -1
- English source text also states field effects are removed.

Current public mechanics confirm that Defog is not merely an Evasion debuff: modern behavior includes removal of hazards and other field effects, including effects across both sides where applicable, plus target-side barriers/terrain-related cleanup.

Legacy/generated output before #65 exposed only:
- `OPPONENT Evasion -1`, 10000 bp.

That subset is unsafe as executable behavior. Omitting field cleanup can remove a strategic drawback (for example preserving hazards that real Defog would clear) and turn the move into a stronger fake debuff.

Decision:
- `DATA_ONLY`
- `effect_specs=[]`
- preserve target and canonical accuracy metadata.

## Memento
Immutable snapshot and public mechanics agree:
- target `selected-pokemon`
- accuracy 100
- Attack -2 / Special Attack -2
- **user faints**.

Legacy/generated output before #65 exposed only the opponent -2/-2 package. That omits the mandatory self-faint cost and would grant a free severe debuff.

Decision:
- `DATA_ONLY`
- `effect_specs=[]`.

## Parting Shot
Immutable snapshot and public mechanics agree:
- target `selected-pokemon`
- accuracy 100
- Attack -1 / Special Attack -1
- **user switches out** after the debuff transaction.

Legacy/generated output before #65 exposed only the opponent -1/-1 package. Keeping the user active changes the move materially and can allow repeatable debuffs that the real move cannot perform in that state.

Decision:
- `DATA_ONLY`
- `effect_specs=[]`.

## Tar Shot
Immutable snapshot and public mechanics agree:
- target `selected-pokemon`
- accuracy 100
- Speed -1
- persistent Fire vulnerability / doubled Fire effectiveness under its effect.

Legacy/generated output exposes:
- `OPPONENT Speed -1`, 10000 bp.

Unlike the three moves above, the missing mechanic is an additional benefit, not a mandatory cost or strategic drawback. Keeping Speed -1 produces a weaker but truthful subset.

Decision:
- `PARTIAL_RUNTIME`
- retain exactly `OPPONENT Speed -1`.

## Implementation contract
`tools/pokeapi_adapter_selected_stateful.py` validates before altering exposure:
- exact source target;
- status damage class;
- source accuracy/priority;
- `effect_changes=[]`;
- exact source stat dictionary;
- exact generated OPPONENT stat package at 10000 bp;
- move-specific semantic evidence from source text/meta.

`tools/pokeapi_adapter_v3.py` applies this narrow layer immediately after the existing legacy/compatibility generator and before canonical records are written.

Independent Godot DATA V3 tests verify regenerated output rather than trusting the adapter internally:
- Defog: selected target, accuracy -1, DATA_ONLY, no specs.
- Memento: selected target, accuracy 100, DATA_ONLY, no specs.
- Parting Shot: selected target, accuracy 100, DATA_ONLY, no specs.
- Tar Shot: selected target, accuracy 100, PARTIAL_RUNTIME, exactly one OPPONENT Speed -1 effect.

## Exact #65 engineering artifact
Coverage:
- `RUNTIME_SUPPORTED`: **584**
- `PARTIAL_RUNTIME`: **68**
- `DATA_ONLY`: **255**
- `UNSUPPORTED`: **12**

DATA_ONLY with non-empty specs: **26**.
- 23 stat-change
- `Beat Up`, `Purify`, `Swallow`.

Exact #64→#65 raw comparison:
- exactly four move records changed;
- Defog: `effect_specs` only, Evasion -1 → empty;
- Memento: `effect_specs` only, Atk/SpAtk -2/-2 → empty;
- Parting Shot: `effect_specs` only, Atk/SpAtk -1/-1 → empty;
- Tar Shot: `classification` only, DATA_ONLY → PARTIAL_RUNTIME; Speed -1 unchanged;
- no unrelated record changed.

Notebook synchronization moves the SHA. #65 requires a second exact-head 18/18 before closure without merge.

# Audit frontier after #65
The `selected-pokemon` family is complete.

## User — 13 conditional/stateful
`autotomize`, `charge`, `clangorous_soul`, `defense_curl`, `extreme_evoboost`, `fillet_away`, `geomancy`, `growth`, `minimize`, `no_retreat`, `shell_smash`, `stockpile`, `tidy_up`.
Do not mass-promote.

## All-opponents — 8
`captivate`, `cotton_spore`, `growl`, `leer`, `string_shot`, `sweet_scent`, `tail_whip`, `venom_drench`.
This is likely the next useful family, but inspect source conditions first. Gender predicates, poisoned-only rules, and spread-target semantics must not be flattened silently.

## All-pokemon — 2
`flower_shield`, `rototiller`.
Current singles SELF/OPPONENT effect targeting cannot directly express all-Pokémon/type predicates.

## Non-stat — 3
`Purify`, `Swallow`, `Beat Up` require separate semantic audits.

## Audit protocol
1. Inspect immutable source.
2. Cross-check public Pokémon mechanics when source text is incomplete/version-ambiguous.
3. Inspect exact generated artifact.
4. Determine all battle-relevant fields, not only `effect_specs`.
5. Determine whether an omitted mechanic is merely a missing benefit or instead a cost/transaction/drawback.
6. Choose coverage from semantics, not convenience.
7. Add exact fail-fast source/generated contract.
8. Add independent regenerated-output/runtime assertion.
9. Batch only genuinely homogeneous contracts.
10. DATA V3 focal.
11. 18/18 engineering SHA.
12. Measure artifact and compare changed fields.
13. Sync notebooks.
14. 18/18 final HEAD.
15. Close without merge.

Stop on any failure; fix root cause before another family.
