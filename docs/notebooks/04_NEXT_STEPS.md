# NEXT STEPS — LIVE CHECKPOINT

Read this immediately after `00_READ_FIRST.md` when recovering context.

## Previous certified tranche
- Branch `fix/data-v3-gear-up-semantics`
- PR #59 closed without merge
- Final HEAD `ef7dd6a41b1cf4bccacf0a8d5098a755bb9fd3e9`
- 18/18 SUCCESS on exact notebook-bearing HEAD.

## Current tranche — PR #60
- Branch `fix/data-v3-magnetic-flux-semantics`
- Parent `ef7dd6a41b1cf4bccacf0a8d5098a755bb9fd3e9`
- Engineering SHA before notebook synchronization: `ee5380e27a0a3312c88c68fc8e476c14dac0a1a7`
- Engineering SHA CI: 18/18 SUCCESS, including independent Magnetic Flux output assertion.
- Notebook synchronization moves branch tip. **Require 18/18 on the final exact notebook-bearing HEAD, then close #60 without merge.**

## Current workstream
**Move Effects V3 semantic audit. Do not switch to trainer AI/archetypes.**

## Exact artifact metrics from #60 engineering SHA
- `RUNTIME_SUPPORTED`: 555
- `PARTIAL_RUNTIME`: 67
- `DATA_ONLY`: 285
- `UNSUPPORTED`: 12
- DATA_ONLY with non-empty specs: **59**
  - 56 stat-change records
  - `Purify`
  - `Swallow`
  - `Beat Up`

## Tranche just completed technically
`Magnetic Flux` source semantics:
- target `user-and-allies`
- Defense +1 / Special Defense +1
- only friendly Pokémon with Plus or Minus are beneficiaries.

Legacy produced false `OPPONENT Defense +1` and `OPPONENT Special Defense +1`. The fix preserves the source record but removes executable effects: `DATA_ONLY`, `effect_specs=[]`. SELF would also be false without the Plus/Minus predicate.

This closes the known high-risk `user-and-allies` family: Howl, Coaching, Gear Up, Magnetic Flux.

## Exact next technical task after #60 closure
Do **not** immediately edit another move. First regroup the remaining **56 stat-change DATA_ONLY records** from the final certified #60 artifact into semantic families.

Priority:
1. Find user-target multi-stat moves that may be genuinely pure and fully representable.
2. Separate those from moves with costs/conditions/state: Autotomize, Charge, Clangorous Soul, Defense Curl, Fillet Away, Geomancy, Growth, Minimize, No Retreat, Shell Smash, Stockpile, Tidy Up, etc.
3. Inspect immutable source before putting any move into a clean batch.
4. Prefer small homogeneous batches (for example, 3–6 pure self stat packages) rather than one-by-one if source contracts are truly identical.
5. Keep special/conditional moves separate.
6. Continue fail-fast adapter validation + focal DATA V3 + 18/18 engineering + artifact measurement + notebooks + 18/18 final.

Potential clean self-stat candidates to investigate, **not yet approved**: `Bulk Up`, `Calm Mind`, `Coil`, `Cosmic Power`, `Defend Order`, `Dragon Dance`, `Hone Claws`, `Quiver Dance`, `Shift Gear`, `Work Up`. Verify each source for hidden mechanics before promotion.

## Known exclusions / special cases
- Rest: DATA_ONLY until Rest-specific status replacement/sleep semantics exist.
- Wish: DATA_ONLY until delayed persisted effects exist.
- Strength Sap: PARTIAL_RUNTIME; Attack drop works, stat-derived heal missing.
- Roost/weather heals/team heals: PARTIAL_RUNTIME for known missing mechanics.
- Silk Trap, Aromatic Mist, Stuff Cheeks, Coaching, Gear Up, Magnetic Flux: safely DATA_ONLY/effect-free until their missing target/trigger/resource predicates exist.
- Howl: PARTIAL_RUNTIME, SELF subset only.
- Purify, Swallow, Beat Up: unaudited special cases; handle separately.

## Stop condition
If any focal or regression test fails, stop. Diagnose/fix root cause, rerun focal, then full matrix. Do not accumulate failures.
