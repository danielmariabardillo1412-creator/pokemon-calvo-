# DATA V3 ABILITY END-TURN AUDIT — V1

## Purpose
Operational checkpoint for the bounded ability-reliability tranche following certified PR #88.

## Certified parent
- PR #88: `DATA V3 — isolate damage modifier roles and audit compound abilities`.
- Certified final HEAD: `64625cd8d46576a528ea9229bbd0b1d7898f0332`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Parent ability coverage: **18 RUNTIME_SUPPORTED / 14 PARTIAL_RUNTIME / 341 DATA_ONLY / 373 total**.

## Current tranche
- Branch: `audit/data-v3-ability-end-turn-v1`.
- Exact parent: certified #88 final `64625cd8d46576a528ea9229bbd0b1d7898f0332`.

## Initial bounded candidate set
- `speed_boost`;
- `shed_skin`;
- `poison_heal`.

## Rules
1. immutable PokeAPI snapshot first;
2. inspect current END_TURN execution before claiming support;
3. prefer existing trigger/effect primitives;
4. do not add weather, field-state, or broad status subsystems just to raise coverage;
5. partial support is acceptable only when the implemented subset is independently faithful;
6. if Poison Heal still takes normal poison residual damage, do not model it as a simple end-turn heal;
7. add real battle/end-turn tests for any promotion;
8. stop on any regression and fix root cause before unrelated work.

Closure protocol: source audit -> execution/timing audit -> bounded implementation/tests if justified -> 18/18 engineering -> exact artifact diff against #88 -> sync `01`, `04`, `19` -> notebooks-only compare -> 18/18 exact final notebook-bearing HEAD -> close without merge.
