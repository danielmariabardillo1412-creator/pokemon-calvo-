# ADR 029 — Trainer Resources, Specialist Knowledge & Strategic Switching

## Status

PROPOSED / IMPLEMENTATION IN PROGRESS

## Context

The trainer AI can already choose MOVE and SWITCH actions and has tactical/search layers, but three important parts of believable trainer behaviour are still incomplete:

1. Trainers cannot use battle consumables such as Potions because BattleAction currently has no ITEM action.
2. CreatureInstance stores `held_item_id`, but imported item definitions are still data-only and Battle Core has no general held-item runtime.
3. Switching exists, but the current score can still prefer staying in a clearly losing or ineffective matchup because switching is treated as an ordinary scored action with a generic switch cost.

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

Required explainable signals include:

- `active_has_no_effective_damage`: current active has no meaningful damaging route against the observed opponent while a healthy bench creature does;
- `clear_offensive_matchup_gain`: incoming creature has substantially better offensive pressure;
- `escape_super_effective_threat`: current active is exposed to a known/publicly inferred strong threat and an incoming creature is materially safer;
- `preserve_low_hp_active`: already supported, retained;
- `preserve_unique_answer`: already supported at team level, retained;
- `avoid_fragile_switch_in`: already supported, retained;
- `avoid_pointless_switch`: no switch bonus when the gain is marginal or the current active is already strongly favoured.

A player switching Pokémon does not grant the NPC secret information. The trainer simply reevaluates the new observed active matchup on its next legal decision.

### 5. Implementation sequence

This ADR intentionally splits the work so regressions can be attributed correctly.

#### FASE 29A — Strategic Switching V2

- strengthen switching urgency using existing MOVE/SWITCH Battle Core;
- add deterministic tests for immunity/no-effect escape, clear counter-switching, super-effective threat escape and anti-ping-pong behaviour;
- require existing trainer corpus/regressions to remain green.

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
