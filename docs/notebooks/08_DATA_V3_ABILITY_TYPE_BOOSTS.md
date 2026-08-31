# DATA V3 ABILITY TYPE BOOSTS — V1

## Purpose

Operational checkpoint for the bounded ability tranche that follows certified PR #77.

Use together with:
- `01_PROJECT_STATE.md` for broad state;
- `04_NEXT_STEPS.md` for the live pointer;
- `06_DATA_V3_ABILITY_RUNTIME_AUDIT.md` for the initial six-ability audit;
- `07_DATA_V3_ABILITY_FAMILY_INVENTORY.md` for the 13-family inventory and Swarm certification.

## Certified parent

- PR #77: `DATA V3 — inventory ability families and audit Swarm`.
- Certified final HEAD: `78da22438d0866193b0d1154814464531ac55641`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Ability coverage at parent:
  - `RUNTIME_SUPPORTED`: 4 (`blaze`, `overgrow`, `swarm`, `torrent`)
  - `PARTIAL_RUNTIME`: 3 (`intimidate`, `levitate`, `static`)
  - `DATA_ONLY`: 366
  - total: 373.

## Current tranche — type-specific unconditional damage boosts

- Branch: `audit/data-v3-ability-type-boosts-v1`.
- Exact parent: certified #77 final `78da22438d0866193b0d1154814464531ac55641`.
- Starting point committed before runtime edits so an interruption cannot erase the workstream state.

### Goal

Audit the bounded family of abilities whose battle transaction is potentially expressible by the existing `MODIFY_DAMAGE` primitive as:

- user's move has one specified type;
- unconditional damage multiplier;
- no required weather/terrain/item/status/switch/form/party transaction.

`Steelworker` is the first candidate because immutable source explicitly states Steel moves have `1.5x` power and `effect_changes=[]`.

### Rules

1. Do not infer numeric multipliers from flavor text alone.
2. Every promoted ability requires explicit immutable-source evidence and a fail-fast source contract.
3. Reuse the existing damage-modifier path; do not add a general Battle Core primitive merely to raise coverage.
4. Abilities with extra mandatory mechanics stay out of this family even if they also boost a type.
5. Any source/version ambiguity keeps the record `DATA_ONLY` until separately resolved.
6. Preserve exact 373-accounting and prohibit accidental promotion outside the audited allowlist.
7. Before closure: focal tests -> 18/18 engineering SHA -> artifact diff -> notebook sync -> 18/18 exact final SHA -> close without merge.

## Immediate work order

1. Verify Steelworker source and runtime fit.
2. Search the existing 366-record DATA_ONLY frontier for genuinely equivalent type-boost candidates.
3. Separate clean equivalents from abilities with extra mechanics or insufficient numeric source evidence.
4. Implement only the clean bounded allowlist and add exact regression tests.
5. Record rejected candidates and reasons here so the next session does not rediscover them.
