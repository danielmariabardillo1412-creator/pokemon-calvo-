# DATA V3 ABILITY END-TURN OPPONENT AUDIT — V1

## Purpose
Operational checkpoint for the bounded DATA V3 ability-reliability tranche following certified PR #89.

## Certified parent
- PR #89: `DATA V3 — audit end-turn ability semantics`.
- Certified final HEAD: `407ad8f27d13a79b09c367aac2f6ae0c1ef801ef`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Parent ability coverage: **19 RUNTIME_SUPPORTED / 14 PARTIAL_RUNTIME / 340 DATA_ONLY / 373 total**.

## Current tranche
- Branch: `audit/data-v3-ability-end-turn-opponent-v1`.
- Exact parent: certified #89 final `407ad8f27d13a79b09c367aac2f6ae0c1ef801ef`.

## Initial bounded candidate set
- `bad_dreams` — candidate for opponent-directed END_TURN residual while foe is asleep;
- `rain_dish` — weather-gated END_TURN healing boundary control;
- `ice_body` — weather-gated END_TURN healing boundary control.

## Rules
1. immutable PokeAPI snapshot first;
2. inspect actual END_TURN target routing and condition vocabulary before claiming support;
3. promote only semantics already representable without broad new subsystems;
4. do not add weather/terrain merely to raise ability coverage;
5. do not fake Bad Dreams with unconditional residual damage if target sleep cannot be expressed exactly;
6. negative audit is an acceptable result;
7. real battle tests are mandatory for any promotion;
8. stop on any regression and fix root cause before unrelated work.

## Closure protocol
source audit -> END_TURN target/condition audit -> bounded implementation/tests if justified -> 18/18 engineering -> exact DATA V3 artifact diff against #89 -> sync `01`, `04`, `20` -> notebooks-only compare -> 18/18 exact final notebook-bearing HEAD -> close without merge.
