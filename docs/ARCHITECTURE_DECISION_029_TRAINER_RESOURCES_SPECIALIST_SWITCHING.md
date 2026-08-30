# ADR 029 — Trainer Resources, Specialist Knowledge & Strategic Switching

## Status

FASE 29A VALIDATED / FASE 29B+ PENDING

## Context

The trainer AI can already choose MOVE and SWITCH actions and has tactical/search layers, but three important parts of believable trainer behaviour are still incomplete:

1. Trainers cannot use battle consumables such as Potions because BattleAction currently has no ITEM action.
2. CreatureInstance stores `held_item_id`, but imported item definitions are still data-only and Battle Core has no general held-item runtime.
3. Switching existed before this ADR, but the generic score could still prefer staying in a clearly losing or ineffective matchup because switching was treated as an ordinary scored action with a generic switch cost.

The goal is not to give NPCs infinite resources or hidden information. The goal is to give them authored, finite resources and public battle knowledge appropriate to trainer tier.

## Decision

### 1. Consumables and held items are separate systems

**Trainer consumables** are finite side-owned battle resources. A trainer can only use the items explicitly assigned to that trainer/loadout. Using one decrements its count. No NPC may materialize an item from the global catalog during battle.

**Held items** are part of the creature's pre-battle loadout. A trainer may equip an allowed held item when the roster is authored/generated, but cannot swap held items arbitrarily during battle unless a future explicit mechanic allows it.

The trainer AI chooses among legal actions; it does not bypass Battle Core to heal, cure status, consume an item, or trigger a held-item effect.

### 2. Resource quality scales with trainer progression/role

Resource availability is data-driven, not inferred from the global item catalog.

Examples of intended balancing policy:

- early-route trainer: usually no consumables or a very small low-tier stock;
- ordinary experienced trainer: limited healing/status resources;
- Gym Leader: deliberate loadout, finite stronger consumables, synergistic held items;
- Elite Four / equivalent: high-quality but still finite consumables, deliberate held-item coverage, stronger tactical use;
- Champion / special boss: strongest authored resources allowed by the battle ruleset, never infinite unless a specific encounter explicitly defines that gimmick.

Exact counts and item IDs belong to trainer data/balance, not to the brain implementation.

### 3. Public knowledge is not cheating

All serious trainers may know the public type chart. Difficulty must not expose hidden opponent moves, held items, exact private stats, RNG, or unseen party members.

A specialist Gym Leader may receive a specialist profile containing one or more `specialist_type_ids`. This means the AI should strongly understand:

- weaknesses, resistances and immunities of its specialist type;
- dual-type interactions;
- which of its own moves/party members cover those weaknesses;
- when the current matchup is poor enough to justify switching;
- public species compatibility/belief information already allowed by the trainer-intelligence boundary.

Elite-level trainers use the same legitimate information boundary but with stronger search, belief use, team preservation, resource management and matchup reasoning. Higher difficulty means better reasoning, not omniscience.

### 4. Strategic switching gets explicit urgency signals

Switching must remain selective: repeatedly switching without a concrete gain is a blunder. However, the evaluator/search must explicitly recognize high-urgency situations instead of relying only on a generic switch score.

The validated FASE 29A implementation adds `TrainerStrategicSwitchEvaluator` with these explainable signals:

- `active_has_no_effective_damage`: current active has no meaningful damaging route against the observed opponent while a healthy bench creature does;
- `clear_offensive_matchup_gain`: incoming creature has substantially better offensive pressure;
- `escape_super_effective_threat`: current active is exposed to a known/public strong threat and an incoming creature is materially safer;
- `avoid_switch_with_immediate_ko`: do not throw away an immediate public KO to make a merely attractive switch;
- `avoid_pointless_switch`: penalize marginal switching and prevent ping-pong.

Existing signals such as `preserve_low_hp_active`, `preserve_unique_answer` and `avoid_fragile_switch_in` remain active in the older tactical/team layers.

A player switching Pokémon does not grant the NPC secret information. The trainer simply reevaluates the newly observed active matchup on its next legal decision.

### 5. Implementation sequence

This ADR intentionally splits the work so regressions can be attributed correctly.

#### FASE 29A — Strategic Switching V2 — VALIDATED

- strengthened switching urgency using existing MOVE/SWITCH Battle Core;
- integrated into `TacticalTrainerBrain` and `DepthSearchTrainerBrain`, therefore also into `AdaptiveBranchingTrainerBrain`;
- no increase to search depth or branching;
- no new hidden information source.

Validation on PR #24 candidate SHA `7c0e2f3abf6d0bdf05e9fa491493aa81f7b06d6e`:

- strategic switching gate: **13 PASS / 0 FAIL**;
- no-effect/immunity case: tactical and adaptive brains both switch to the valid counter;
- clear bad matchup: switches to the stronger counter;
- favourable matchup: stays and attacks rather than ping-pong switching;
- observed player switch: reevaluates the new active and counter-switches;
- decision trace contains the switching model/reason and no IV/EV/nature/RNG leakage;
- FASE 26 corpus with adaptive candidate: **36 PASS / 0 FAIL**, planner record remains **60/60**, paired regressions remain **0**;
- all 12 CI workflows, including the complete Godot 4.7 regression, passed on the candidate SHA.

#### FASE 29B — Trainer Battle Resources Contract

- introduce a side-owned finite trainer consumable stock/loadout;
- no UI requirement;
- resources must serialize deterministically and be inspectable in decision traces only as own-side information.

#### FASE 30 — Battle ITEM Action V1

- extend authoritative BattleAction/Battle Core with legal finite item use;
- begin with a deliberately supported subset (healing/status cure first) rather than pretending all imported items work;
- consume stock authoritatively;
- AI receives only legal ITEM candidates.

#### FASE 31 — Held Item Runtime V1

- classify and implement a supported subset of held-item effects through Battle Core triggers;
- keep `held_item_id` as pre-battle loadout state;
- document unsupported items explicitly.

#### FASE 32 — Public Coverage Priors

- continue the previously planned hidden-move compatibility work using public learnset methods;
- keep version-group limitations explicit;
- no hidden moveset leakage.

## Invariants

- No infinite consumables by default.
- No item may be used unless the side owns a remaining legal count.
- No held item may appear during battle unless it was part of the creature/loadout or produced by an explicit supported mechanic.
- Trainer difficulty never grants raw hidden BattleState/RNG/private opponent data.
- Every SWITCH/ITEM decision remains explainable in TrainerDecisionTrace.
- Battle Core remains authoritative for legality and effects.

## Dataset reality

The imported dataset currently contains 2,222 item definitions, but all are classified `DATA_ONLY`. Therefore item IDs/categories/descriptions existing in data must not be confused with runtime support. Held-item and consumable behaviour will be added incrementally and reported explicitly.
