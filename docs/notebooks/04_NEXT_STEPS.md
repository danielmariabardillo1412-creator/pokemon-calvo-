# NEXT STEPS — LIVE CHECKPOINT

Read immediately after `00_READ_FIRST.md` when recovering context.

## Latest certified baseline
- PR #82 — `audit/data-v3-ability-defensive-predicates-v2`
- Final HEAD `089140a8439390758d688636f715a311ec175163`
- **18/18 SUCCESS** on exact notebook-bearing HEAD
- closed without merge.

Move Effects V3 remains closed:
- **590 runtime / 71 partial / 246 data-only / 12 unsupported**;
- `DATA_ONLY` moves with executable `effect_specs`: **0**.

Certified #82 ability coverage:
- `RUNTIME_SUPPORTED`: **13**
- `PARTIAL_RUNTIME`: **5** — `heatproof`, `intimidate`, `levitate`, `stamina`, `static`
- `DATA_ONLY`: **355**
- total: **373**.

Prior detailed ability notebooks: `06`, `07`, `08`, `09`, `10`, `11`, `12`.

# Current tranche — PR #83
- Branch: `audit/data-v3-ability-move-property-v1`
- Parent: certified #82 final `089140a8439390758d688636f715a311ec175163`
- PR: #83 `DATA V3 — audit move-property ability contracts`
- Engineering SHA: `f9d3538dec9c443e60070b0e4bf7d7904c984e55`
- Engineering SHA: **18/18 SUCCESS**; DATA V3 and Godot global green.
- Detailed notebook: `docs/notebooks/13_DATA_V3_ABILITY_MOVE_PROPERTIES.md`.

## #83 result
### Reckless
Decision: **PARTIAL_RUNTIME**.

Source requires 1.2x for both recoil moves and crash moves, with Struggle unaffected.

Faithful executable subset:
- generic `requires_recoil=true` predicate backed recursively by structured `BattleEffectSpec.RECOIL`;
- actor-side `MODIFY_DAMAGE`;
- `multiplier_bp=12000`.

Real-battle focal coverage:
- Double-Edge gets higher matched-seed damage and emits Reckless trigger;
- recoil still executes normally;
- Tackle remains identical/no trigger;
- Jump Kick has no structured RECOIL transaction today and remains identical/no trigger, explicitly documenting the missing crash subset.

### Long Reach
Remains **DATA_ONLY**. Defender-owned contact-trigger evaluation does not currently receive the move user, so it cannot safely know the attacker has Long Reach. Do not add a hidden ability-id special-case or mutate move contact metadata.

### Technician
Remains **DATA_ONLY**. Source requires variable/resolved power and prior power-modifier semantics. Static `move.power <= 60` is a known-false shortcut for current dynamic moves.

### Iron Fist / Strong Jaw / Mega Launcher / Sharpness
Remain **DATA_ONLY**. Current runtime move definitions do not preserve punch/bite/pulse/slicing tags; do not infer them from names/prose.

## Battle Core scope
One new generic condition only:
- `requires_recoil=true`, structural recursive search through `move.effect_specs`.

No new trigger kind, crash mechanic, move-tag system, name heuristic, contact-context plumbing or broad architecture was added.

## Ability coverage after #83 engineering
- `RUNTIME_SUPPORTED`: **13**
- `PARTIAL_RUNTIME`: **6** — `heatproof`, `intimidate`, `levitate`, `reckless`, `stamina`, `static`
- `DATA_ONLY`: **354**
- total: **373**.

## Exact #82 → #83 artifact
Raw + normalized:
- exactly one semantic difference;
- `reckless.classification: DATA_ONLY → PARTIAL_RUNTIME`.

Reports:
- runtime stays 13;
- partial 5→6, adding only Reckless;
- data-only 355→354, removing only Reckless;
- `pokeapi_v3_audit.json` changes only those two count values.

Explicitly unchanged:
- Long Reach, Technician, Iron Fist, Strong Jaw, Mega Launcher, Sharpness;
- every other ability;
- Pokémon/species;
- moves/effects;
- items/statuses;
- learnsets/evolutions;
- types/stats;
- manifest/forms/auxiliary.

`import_time_ms` 396→398 ms is non-semantic.

## Current certification step
Notebook synchronization now moves the branch after engineering SHA `f9d3538dec9c443e60070b0e4bf7d7904c984e55`.

Before closing #83:
1. verify engineering SHA → final HEAD changed only `01_PROJECT_STATE.md`, `04_NEXT_STEPS.md`, `13_DATA_V3_ABILITY_MOVE_PROPERTIES.md`;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #83 without merge;
4. use exact final HEAD as next baseline.

## Exact next task after #83 closure
Continue **DATA FOUNDATION V3 ability reliability** with another bounded subgroup selected from the remaining 354 DATA_ONLY records.

Do not reopen the blockers just documented unless their required shared primitive has actually been added for a broader reason. Prefer an existing-primitive family or a documented negative audit over architecture added solely to increase ability coverage.

Trainer AI/archetypes remain deferred.

## Stop condition
Any focal/regression failure stops the tranche until root cause is fixed and rerun.
