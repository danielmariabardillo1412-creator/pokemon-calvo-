# PROJECT STATE NOTEBOOK

## Purpose
Fast context recovery for engineering work. GitHub commits, PR state, CI, immutable source data, and tested artifacts are authoritative if anything conflicts with this notebook.

## Repository / certification policy
- Repository: `danielmariabardillo1412-creator/pokemon-calvo-`
- Engine: Godot 4.7.
- Certified snapshots are retained as branches / closed PRs **without merge**.
- New tranches branch from the latest exact certified HEAD.
- Certification requires all 18 normal workflows green on the same exact final SHA.
- Notebook updates move the SHA, so the notebook-bearing HEAD requires a second 18/18 run before PR closure.
- Stop on any failing focal/regression test and fix root cause before continuing.

## DATA FOUNDATION V3 authority
Immutable source:
- branch `data/pokeapi-v2-snapshot`
- commit `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`
- API tree `8349ea1ce75716897fe96e02a15950d19edba6c3`
- schema tree `02e031e1928d7e9456bf6f7486daacc4b8946c84`
- paths `data/api/v2`, `data/schema/v2`
- source JSON is read-only.

Pipeline:
`snapshot → tools/pokeapi_adapter_v3.py → compatibility/narrow audit layers → data/raw/pokemon_api.json → Godot DataImporter → data/normalized/pokemon_api.json → runtime`.

## Structural V3 facts
- 1,025 base species; 326 forms.
- 18 runtime battle types.
- 919 runtime moves.
- 373 abilities; 2,222 items.
- 61,102 learnset entries.
- 554 evolution records.
- 0 broken refs; 0 rejected definitions.
- 18 XD Shadow moves explicitly excluded instead of remapped.

## Recent certified chain
- #63 always-hit data accuracy — `9f8b3e01bec1f86cff75380d68dd98d76e738e78`
- #64 selected special stats — `674ccaf0928c93749c581565d53eb1f672dfd7b4`
- #65 selected stateful semantics — `b13af37c350156bc7a9a7d7faf63742245afd801`
- #66 all-opponents stat semantics — `51bc14155338e47c76926047845a958205005bdd`
All certified 18/18 on exact final HEAD and closed without merge.

## Certified DATA V3 coverage after #66
- `RUNTIME_SUPPORTED`: **589**
- `PARTIAL_RUNTIME`: **68**
- `DATA_ONLY`: **250**
- `UNSUPPORTED`: **12**
- DATA_ONLY with non-empty `effect_specs`: **18**
  - 15 stat-change
  - `Beat Up`, `Purify`, `Swallow`

The `selected-pokemon` and `all-opponents` DATA_ONLY-with-specs families are fully audited.

# Current tranche — PR #67 self-target accuracy semantics
- Branch: `fix/battle-self-target-accuracy`
- Parent: certified #66 final `51bc14155338e47c76926047845a958205005bdd`.
- Engineering SHA before notebook synchronization: `b4beb85a57738acfdacfdb0859a20b427d08f908`.
- Engineering SHA passed **18/18**, including DATA V3 and complete Godot global.
- No data records, classifications, `effect_specs`, source files, or coverage counts change in #67.
- Notebook synchronization moves the SHA; final exact HEAD must pass 18/18 again before #67 closes without merge.

## #67 root cause
During the audit of user-target moves, `TurnExecutor._execute_move()` was found to run the normal accuracy/evasion check for every move. It always compared:
- `move.accuracy`,
- actor Accuracy stage,
- opposing active Pokémon Evasion stage,

even when the move's canonical target was `user`.

That allowed a self-only move with numeric accuracy to emit `MOVE_MISSED` because the opponent raised Evasion or the user had reduced Accuracy. This is semantically wrong for the normal accuracy check of self-target moves.

## #67 fix
`TurnExecutor` now skips only the normal Accuracy/Evasion roll when `move.target == "user"`.

Important boundary:
- this does **not** make conditional self-target moves automatically succeed;
- move-specific failure rules (HP prerequisite, stat caps, two-turn charging, weather/state predicates, etc.) remain separate mechanics and must be modeled/audited independently;
- every non-user target keeps the existing accuracy logic unchanged.

## #67 regression gate
New isolated suite: `tests/battle/battle_self_target_accuracy_test_suite.gd`.
It is called by the already-CI-gated `battle_commands_test_runner.gd`.

Adversarial checks:
- synthetic `target=user`, `accuracy=0`, actor Accuracy -6, opponent Evasion +6 → must **not** emit `MOVE_MISSED` and must consume PP;
- synthetic `target=selected-pokemon`, `accuracy=0` under the same environment → must still emit `MOVE_MISSED`.

This proves the fix is target-specific rather than a global accuracy bypass.

## Move Effects frontier after #67
Resume the 13 `user` conditional/stateful DATA_ONLY-with-specs moves:
`autotomize`, `charge`, `clangorous_soul`, `defense_curl`, `extreme_evoboost`, `fillet_away`, `geomancy`, `growth`, `minimize`, `no_retreat`, `shell_smash`, `stockpile`, `tidy_up`.

Immediate next family already inspected: HP-cost boosts.
- `clangorous_soul`: generated five +1 self stat effects but real move pays 1/3 max HP and can fail if payment/prerequisites are not met.
- `fillet_away`: generated Atk/SpAtk/Speed +2 but real move pays 1/2 max HP and can fail if payment/prerequisites are not met.
- Current `RECOIL` effect cannot model these costs because it derives recoil from `context.last_damage`; status moves have no previous dealt damage and there is no max-HP payment/failure primitive.
- Therefore these boosts must not remain executable for free. After #67 certification, audit/neutralize them in a separate DATA V3 tranche rather than expanding Battle Core casually.

Remaining after user family:
- all-pokemon: `flower_shield`, `rototiller`.
- non-stat: `Purify`, `Swallow`, `Beat Up`.

## Runtime safety invariant
`effect_specs` execute regardless of coverage label. `DATA_ONLY` is not an execution gate. A known-false or strategically unsafe spec must be removed/corrected.
