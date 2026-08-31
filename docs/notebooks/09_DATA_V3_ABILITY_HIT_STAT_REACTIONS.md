# DATA V3 ABILITY HIT-STAT REACTIONS — V1

## Purpose

Operational checkpoint for the bounded ability tranche that follows certified PR #78.

Use together with:
- `01_PROJECT_STATE.md` for broad project state;
- `04_NEXT_STEPS.md` for the live pointer;
- `06_DATA_V3_ABILITY_RUNTIME_AUDIT.md` for the initial six-ability audit;
- `07_DATA_V3_ABILITY_FAMILY_INVENTORY.md` for the 13-family inventory;
- `08_DATA_V3_ABILITY_TYPE_BOOSTS.md` for certified unconditional type boosts.

## Certified parent

- PR #78: `DATA V3 — audit unconditional ability type boosts`.
- Certified final HEAD: `eda483d9cd6423d32bdf1a156372416b2fbcb639`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Ability coverage at parent:
  - `RUNTIME_SUPPORTED`: 8
  - `PARTIAL_RUNTIME`: 3
  - `DATA_ONLY`: 362
  - total: 373.

## Current tranche — hit-triggered stat reactions

- Branch: `audit/data-v3-ability-hit-stat-reactions-v1`.
- Exact parent: certified #78 final `eda483d9cd6423d32bdf1a156372416b2fbcb639`.
- This checkpoint is committed before runtime edits so interruption cannot erase the workstream state.

### Goal

Audit a small family of abilities whose battle transaction may be expressible with existing trigger/effect primitives as:
- owner is hit by a damaging move;
- a deterministic stat-stage change occurs;
- no contact-only requirement unless explicitly supported;
- no weather/terrain/item/form/switch/party/faint transaction.

`Stamina` is the first candidate.

### Rules

1. Do not group by English keywords alone; promotion requires explicit immutable-source semantics.
2. Distinguish **being hit**, **taking damage**, **physical/special damage**, and **contact**. They are not interchangeable.
3. Do not reuse Static's faint-sensitive AFTER_DAMAGE behavior blindly; any candidate whose source must trigger after a fatal hit needs separate policy.
4. Prefer existing Battle Core trigger/effect primitives. Do not add a broad generic mechanic just to increase coverage.
5. Any ability with multi-effect transactions, HP thresholds, form change, switching, or status prerequisites stays outside this tranche unless separately proven safe.
6. Preserve exact 373-accounting and prohibit accidental promotion outside the audited allowlist.
7. Closure protocol remains: focal tests -> 18/18 engineering SHA -> artifact diff -> notebook sync -> 18/18 final SHA -> close without merge.

## Immediate work order

1. Audit immutable source for `stamina`.
2. Inspect existing Battle Core trigger conditions and execution timing for a non-contact hit-triggered stat change.
3. Search only for genuinely equivalent/small adjacent candidates (for example Water Compaction / Weak Armor if their transactions fit).
4. Explicitly reject candidates whose source timing or secondary effects exceed the current primitive.
5. Implement only the clean bounded allowlist, with exact regression tests.
