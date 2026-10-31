# PROGRESSION ARCHITECTURE (FASE 6)

Runtime layer for per-creature progression, fully separated from Battle Core and presentation.

## Local regional/shiny extension — 2026-10-26

`pokemon_variant_catalog.gd` explicitly extends the runtime DefinitionCatalog with
57 ordinary regional definitions from `config/pokemon_variants_v1.json`; the frozen
canonical dataset is unchanged. Regional IDs are distinct definitions with their
own types, base stats, ability slots and coherently selected learnset. Provenance
records identify the canonical base species. Only explicitly matching regional
evolution records are routed; unsupported conditions remain preserved and blocked.

CreatureInstance has optional `is_shiny`, omitted when false for legacy snapshots.
`appearance_id()` supplies a presentation key without changing mechanical species
identity. Capture/storage/save preserve the same attribute; evolution carries it
to the new same-identity instance. Transform temporarily copies the target color,
serializes the original color with its reversible overlay and restores it on exit.

The factory uses a deterministic cosmetic RNG seeded from encounter RNG state and
creature identity without advancing the caller's RNG. Only species with an existing
front/back shiny pair can be selected. The default denominator is 4096; the local
technical selectors may explicitly request an available shiny. This does not
implement the final randomlock learnset/ability/encounter generator.

## Module map

```
modules/creatures/progression/
  progression_ruleset.gd     # calvo_progression_v1: XP curves, limits, nature table, helpers
  stat_calculator.gd         # compute(base, ivs, evs, nature_id, level) -> StatBlock
  learnset_system.gd         # initial_moves / level_up_moves_between / moves_learned_at_level
  evolution_system.gd        # classify_record / evolution_candidates / apply_evolution / coverage_report
  creature_factory.gd        # create(...) deterministic CreatureInstance
  progression_event.gd       # semantic events (LEVEL_UP, MOVE_LEARNED, EVOLUTION_AVAILABLE, ...)
  progression_system.gd      # gain_experience / apply_move_choice / apply_evolution / reconcile_battle_result

modules/battle/domain/
  battle_outcome.gd          # BattleOutcome.from_battle_state(state, catalogs)  (pure contract)

modules/creatures/domain/
  creature_species.gd        # + growth_rate, ev_yield, base_stat_block()
  creature_instance.gd       # + experience/ivs/evs/nature_id/friendship/moveset + recalc/add_move/replace_move/reconcile

modules/data/
  data_importer.gd           # SPECIES_KEYS += growth_rate, ev_yield
```

## Data flow

```
                Battle Core (no progression knowledge)
                          |
                          v
                 BattleState  --from_battle_state()-->  BattleOutcome
                                                  |
                                                  v
      ProgressionSystem.reconcile_battle_result(survivors, outcome, catalogs, ruleset)
                  |                         |                     |
                  v                         v                     v
        experience_for_defeats()      friendship += ...     EVOLUTION_AVAILABLE events
                  |
                  v
        ProgressionSystem.gain_experience(creature, amount, species, catalogs, ruleset)
                  |
                  +---> LEVEL_UP events
                  +---> STAT_CHANGED (recalculate_stats)
                  +---> MOVE_LEARNED (auto, if < 4 slots)
                  +---> MOVE_LEARN_CHOICE_REQUIRED (if full)  --> caller: apply_move_choice(LEARN/REPLACE/DECLINE)

   Evolution (deferred to caller decision):
        EvolutionSystem.evolution_candidates(species, {level=...}, catalog)
                  |
                  v
        ProgressionSystem.apply_evolution(creature, event, catalog, ruleset) -> new CreatureInstance
```

## Identity & mutation contract
- `CreatureInstance.instance_id` (StringName) is the stable key everywhere (party, PC, save, network).
- Battle mutates the SAME `CreatureInstance` in place: `current_hp`, `status_state`, `moveset[i].current_pp`.
- Progression mutates: `level`, `experience`, `ivs`, `evs`, `nature_id`, `friendship`, `moveset`,
  and recomputes `stats` via `StatCalculator`.
- `reconcile_post_battle()` drops volatile statuses (flinch/confusion) and clamps HP/PP.

## Determinism
- All randomness (`CreatureFactory` IVs, future ability rolls) flows through an injected `RandomNumberGenerator`
  seed; tests pin seeds and assert stable results.

## Testing
- `tests/gameplay/progression_test_suite.gd`: 71 checks (XP curves, stat calc, learnset, move choice,
  evolution apply/identity preservation, battle reconciliation, coverage invariants).
- Full suite: **208 PASS / 0 FAIL**.
