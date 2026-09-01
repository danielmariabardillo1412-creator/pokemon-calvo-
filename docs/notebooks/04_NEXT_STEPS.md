# NEXT STEPS — LIVE CHECKPOINT

Read immediately after `00_READ_FIRST.md` when recovering context.

## Latest certified baseline
- PR #83 — `audit/data-v3-ability-move-property-v1`
- Final HEAD `f4a1f76850d8737c4d9847045335e703d5ecaa23`
- **18/18 SUCCESS** on exact notebook-bearing HEAD
- closed without merge.

Move Effects V3 remains closed:
- **590 runtime / 71 partial / 246 data-only / 12 unsupported**;
- `DATA_ONLY` moves with executable `effect_specs`: **0**.

Certified #83 ability coverage:
- `RUNTIME_SUPPORTED`: **13**
- `PARTIAL_RUNTIME`: **6** — `heatproof`, `intimidate`, `levitate`, `reckless`, `stamina`, `static`
- `DATA_ONLY`: **354**
- total: **373**.

Prior detailed ability notebooks: `06`, `07`, `08`, `09`, `10`, `11`, `12`, `13`.

# Current tranche — PR #84
- Branch: `audit/data-v3-ability-contact-reactions-v1`
- Parent: certified #83 final `f4a1f76850d8737c4d9847045335e703d5ecaa23`
- PR: #84 `DATA V3 — audit defender contact reaction abilities`
- Engineering SHA: `27a9d2b429334ea6f809009de219bb3fce0bb813`
- Engineering SHA: **18/18 SUCCESS**; DATA V3 and Godot global green.
- DATA V3 domain: **451 PASS / 0 FAIL**.
- Detailed notebook: `docs/notebooks/14_DATA_V3_ABILITY_CONTACT_REACTIONS.md`.

## #84 result
### Flame Body
Decision: **PARTIAL_RUNTIME**.

Source battle semantics: contacting move user has a 30% chance to be burned. The pinned historical change is overworld-only.

Runtime subset:
- defender `AFTER_DAMAGE`;
- `requires_contact=true`;
- 30% CHANCE -> burn attacker.

### Poison Point
Decision: **PARTIAL_RUNTIME**.

Source battle semantics: contacting move user has a 30% chance to be poisoned; no effect history.

Runtime subset:
- defender `AFTER_DAMAGE`;
- `requires_contact=true`;
- 30% CHANCE -> poison attacker.

### Gooey
Decision: **PARTIAL_RUNTIME**.

Source battle semantics: contact lowers attacker Speed one stage; no effect history.

Runtime subset:
- defender `AFTER_DAMAGE`;
- `requires_contact=true`;
- attacker Speed `-1` stage.

## Shared partial boundary
No generic Battle Core code changed in #84. All three reuse the existing Static-style contact-reaction path.

The current path does not trigger for a defender that fainted from the hit and is evaluated once after the completed move rather than once per multi-hit strike. Therefore fatal/per-strike semantics remain absent and the three classifications stay partial.

A focal real-battle regression explicitly KOs a 1-HP Gooey owner with Tackle and confirms no Gooey reaction, preserving the missing behavior as a visible contract rather than hiding it.

## Exact #83 → #84 artifact
Raw + normalized:
- exactly three semantic differences;
- `flame_body.classification: DATA_ONLY → PARTIAL_RUNTIME`;
- `gooey.classification: DATA_ONLY → PARTIAL_RUNTIME`;
- `poison_point.classification: DATA_ONLY → PARTIAL_RUNTIME`.

No other field on those records changes.

Reports:
- runtime stays 13;
- partial 6→9, adding exactly those three IDs;
- data-only 354→351, removing exactly those three IDs;
- `pokeapi_v3_audit.json` changes only those two count values.

Explicitly unchanged:
- every other ability;
- Pokémon/species;
- moves/effects;
- items/statuses;
- learnsets/evolutions;
- types/stats;
- manifest/forms/auxiliary.

`import_time_ms` 705→524 ms is non-semantic.

## Ability coverage after #84 engineering
- `RUNTIME_SUPPORTED`: **13**
- `PARTIAL_RUNTIME`: **9** — `flame_body`, `gooey`, `heatproof`, `intimidate`, `levitate`, `poison_point`, `reckless`, `stamina`, `static`
- `DATA_ONLY`: **351**
- total: **373**.

## Current certification step
Notebook synchronization now moves the branch after engineering SHA `27a9d2b429334ea6f809009de219bb3fce0bb813`.

Before closing #84:
1. verify engineering SHA → final HEAD changed only `01_PROJECT_STATE.md`, `04_NEXT_STEPS.md`, `14_DATA_V3_ABILITY_CONTACT_REACTIONS.md`;
2. require **18/18 SUCCESS** on exact final notebook-bearing HEAD;
3. close #84 without merge;
4. use exact final HEAD as next baseline.

## Exact next task after #84 closure
Continue **DATA FOUNDATION V3 ability reliability** with one bounded subgroup selected from the remaining 351 DATA_ONLY records.

Do not mass-promote the rest of the contact family:
- Cute Charm needs gender/infatuation semantics;
- Effect Spore needs mutually exclusive random-status behavior;
- Iron Barbs/Rough Skin need a properly audited max-HP contact-damage transaction;
- Mummy/Wandering Spirit need ability replacement;
- Pickpocket needs held-item transfer;
- Poison Touch needs attacker-owned post-hit contact handling.

Prefer one existing-primitive family or a documented negative audit over broadening architecture solely for coverage. Trainer AI/archetypes remain deferred.

## Stop condition
Any focal/regression failure stops the tranche until root cause is fixed and rerun.
