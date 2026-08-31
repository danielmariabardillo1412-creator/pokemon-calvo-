# DATA V3 / MOVE EFFECTS V3 AUDIT NOTEBOOK

## Invariant
DATA V3 structural correctness is not enough: every executable `effect_spec` and every battle-relevant move field must be semantically faithful. If Battle Core cannot represent a mechanic, preserve only a provably faithful subset (`PARTIAL_RUNTIME`) or remove executable effects (`DATA_ONLY`). Coverage labels do not gate execution.

A retained effect can be individually true yet still unsafe if an omitted mechanic is a mandatory cost, transaction, prerequisite, target predicate, or strategic drawback. In those cases prefer effect-free `DATA_ONLY`.

## Canonical source
- immutable `data/pokeapi-v2-snapshot`
- commit `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`
- `data/api/v2` + `data/schema/v2`
- compatibility corrections: `tools/pokeapi_adapter.py`
- canonical conversion: `tools/pokeapi_adapter_v3.py`
- selected-stateful audit: `tools/pokeapi_adapter_selected_stateful.py`
- all-opponents audit: `tools/pokeapi_adapter_all_opponents.py`
- archived V2 is provenance-only and must remain untouched.

## Certified recent heads
- #63 always-hit data accuracy — `9f8b3e01bec1f86cff75380d68dd98d76e738e78`
- #64 selected special stats — `674ccaf0928c93749c581565d53eb1f672dfd7b4`
- #65 selected stateful — `b13af37c350156bc7a9a7d7faf63742245afd801`
- #66 all-opponents stats — `51bc14155338e47c76926047845a958205005bdd`
All certified 18/18 on exact notebook-bearing HEAD and closed without merge.

## Data accuracy contract from #63
- numeric PokéAPI accuracy is preserved;
- source `accuracy=null` becomes canonical `-1`;
- `MoveDefinition` preserves `-1`;
- `BattleRuleset` treats negative base accuracy as always-hit, while genuine numeric accuracy remains stage-sensitive for moves that perform the normal accuracy check.

# PR #67 — self-target accuracy semantics (CURRENT)
Branch `fix/battle-self-target-accuracy`.
Parent: certified #66 final `51bc14155338e47c76926047845a958205005bdd`.
Engineering SHA before notebook sync: `b4beb85a57738acfdacfdb0859a20b427d08f908`.
Engineering SHA: **18/18 SUCCESS**.

## Discovery
While auditing `clangorous_soul` and `fillet_away`, Battle Core was inspected to determine whether their self-target behavior could be represented faithfully. This exposed a transversal runtime bug unrelated to their HP costs:

`TurnExecutor` always performed the normal Accuracy/Evasion calculation against the opponent, regardless of `move.target`.

Consequences before #67:
- a self-only move with numeric accuracy could miss because the user had reduced Accuracy;
- the opposing active Pokémon's Evasion could make a move used only on the user miss;
- this mixed target semantics with accuracy semantics and made user-target data unsafe even when the move package itself was correct.

## #67 contract
For canonical `move.target == "user"`:
- skip the normal Accuracy/Evasion roll entirely;
- still consume PP and execute the move transaction normally;
- do not emit `MOVE_MISSED` from the normal accuracy system.

For all other targets:
- existing accuracy calculation remains unchanged.

This is intentionally narrow. It does not implement or bypass move-specific failure conditions.

Examples of separate failure mechanics that still need their own contracts:
- insufficient HP payment (`Clangorous Soul`, `Fillet Away`);
- stat-cap failure;
- two-turn charge state (`Geomancy`);
- weather-dependent stat values (`Growth`);
- stored counters (`Stockpile`);
- switch restrictions or field cleanup (`No Retreat`, `Tidy Up`).

## #67 independent runtime regression
`BattleSelfTargetAccuracyTestSuite` is executed through the existing CI-gated `battle_commands_test_runner.gd`.

Adversarial self-target case:
- synthetic status move;
- `target=user`;
- `accuracy=0`;
- actor Accuracy stage -6;
- opponent Evasion stage +6;
- expected: action executes without `MOVE_MISSED` and PP is consumed.

Control case:
- same numeric accuracy 0;
- `target=selected-pokemon`;
- expected: `MOVE_MISSED` still occurs.

Engineering result: Godot global, including the battle commands phase, passed. DATA V3 also remained green.

## Data impact of #67
None.
- no source JSON changed;
- no canonical move record changed;
- no classification changed;
- no `effect_specs` changed;
- coverage remains **589 RUNTIME_SUPPORTED / 68 PARTIAL_RUNTIME / 250 DATA_ONLY / 12 UNSUPPORTED**;
- DATA_ONLY with non-empty specs remains **18**.

Notebook sync moves the SHA. #67 requires a second 18/18 on the exact final HEAD before closure without merge.

# Audit frontier after #67
## User — 13 conditional/stateful
`autotomize`, `charge`, `clangorous_soul`, `defense_curl`, `extreme_evoboost`, `fillet_away`, `geomancy`, `growth`, `minimize`, `no_retreat`, `shell_smash`, `stockpile`, `tidy_up`.

### Immediate next tranche: HP-cost boosts
#### Clangorous Soul
Immutable snapshot provides:
- target `user`;
- five stat changes, each +1;
- effect text says user loses 33% of max HP;
- move fails when the HP payment would knock the user out / relevant failure conditions apply.

Current generated record exposes five unconditional SELF +1 stat effects. Coverage being DATA_ONLY does not stop execution. Therefore the current specs grant a false free boost.

#### Fillet Away
Immutable snapshot provides:
- target `user`;
- Attack +2 / Special Attack +2 / Speed +2;
- Scarlet/Violet text explicitly says the boosts use the user's own HP.
Current mechanics require payment of half max HP and sufficient HP.

Current generated record exposes the three boosts without the payment, again creating a false free benefit.

#### Why current RECOIL cannot represent either
`BattleEffectExecutor.RECOIL` requires `context.last_damage > 0` and derives recoil from damage dealt to the opponent. These are status moves and their cost is based on the user's max HP, with a prerequisite/failure rule. There is no current max-HP payment primitive or transactional prerequisite.

Decision direction after #67 closes: do not expand Battle Core casually; create a narrow DATA V3 tranche that fail-fast validates both source contracts and removes their executable stat specs until a proper HP-payment mechanic exists.

## Remaining user families after HP-cost pair
- two-turn: `geomancy`
- weather-dependent: `growth`
- stored state: `stockpile`
- persistent/special interactions: `autotomize`, `charge`, `defense_curl`, `minimize`, `no_retreat`, `tidy_up`
- multi-stat packages to verify: `shell_smash`, `extreme_evoboost`

## After user family
- all-pokemon: `flower_shield`, `rototiller`
- non-stat: `Purify`, `Swallow`, `Beat Up`

## Audit protocol
1. Inspect immutable source.
2. Cross-check public mechanics where source is incomplete/version-ambiguous.
3. Inspect exact generated artifact.
4. Identify every cost, prerequisite, target rule and state transaction.
5. Fix transversal runtime contracts separately from move-specific data contracts.
6. Add fail-fast source/generated contract.
7. Add independent regression.
8. Run focal then 18/18 engineering SHA.
9. Sync notebooks.
10. Run 18/18 exact final HEAD.
11. Close without merge.

Stop on any failure and fix root cause before another family.
