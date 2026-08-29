# PROGRESSION ARCHITECTURE (FASE 6)

Runtime layer for per-creature progression, fully separated from Battle Core and presentation.

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
- `tests/progression_test_suite.gd`: 71 checks (XP curves, stat calc, learnset, move choice,
  evolution apply/identity preservation, battle reconciliation, coverage invariants).
- Full suite: **208 PASS / 0 FAIL**.
