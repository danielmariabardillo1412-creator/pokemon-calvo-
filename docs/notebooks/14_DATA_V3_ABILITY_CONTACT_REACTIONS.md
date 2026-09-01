# DATA V3 ABILITY CONTACT REACTIONS — V1

## Purpose
Operational checkpoint for the bounded ability tranche following certified PR #83.

## Certified parent
- PR #83: `DATA V3 — audit move-property ability contracts`.
- Certified final HEAD: `f4a1f76850d8737c4d9847045335e703d5ecaa23`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Parent ability coverage: **13 RUNTIME_SUPPORTED / 6 PARTIAL_RUNTIME / 354 DATA_ONLY / 373 total**.

## Current tranche
- Branch: `audit/data-v3-ability-contact-reactions-v1`.
- Exact parent: certified #83 final `f4a1f76850d8737c4d9847045335e703d5ecaa23`.

Goal: audit a small defender-owned contact-reaction subgroup against the existing `AFTER_DAMAGE + requires_contact` primitive already used by Static. Do not change generic faint-safe trigger policy in this tranche.

Initial candidates:
- `flame_body`;
- `poison_point`;
- `gooey`.

Expected boundary to verify:
- ordinary surviving contact hit can be modeled with existing trigger primitives;
- current TurnExecutor requests defender `AFTER_DAMAGE` only when damage > 0 and target survives;
- `_execute_triggers` also rejects knocked-out owners;
- therefore any source mechanic that should trigger from a fatal contact hit cannot be called full runtime support under current Battle Core.

Do not expand this tranche into Cute Charm, Effect Spore, item theft, ability replacement, or contact-damage families unless their required semantics are separately audited.

Closure protocol remains: source audit -> focal implementation/tests -> 18/18 engineering -> artifact diff -> notebook sync -> 18/18 final notebook-bearing HEAD -> close without merge.
