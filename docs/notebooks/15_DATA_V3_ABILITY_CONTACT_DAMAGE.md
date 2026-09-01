# DATA V3 ABILITY CONTACT DAMAGE — V1

## Purpose
Operational checkpoint for the bounded ability tranche following certified PR #84.

## Certified parent
- PR #84: `DATA V3 — audit defender contact reaction abilities`.
- Certified final HEAD: `67c483899dadb2e3d1b5314a779d4c71b1bc8708`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Parent ability coverage: **13 RUNTIME_SUPPORTED / 9 PARTIAL_RUNTIME / 351 DATA_ONLY / 373 total**.

## Current tranche
- Branch: `audit/data-v3-ability-contact-damage-v1`.
- Exact parent: certified #84 final `67c483899dadb2e3d1b5314a779d4c71b1bc8708`.

Goal: audit the small contact-damage subgroup beginning with:
- `rough_skin`;
- `iron_barbs`.

Questions that must be answered before implementation:
1. exact immutable source fraction and generation/history for each ability;
2. whether reactive damage is based on the attacker's or defender's maximum HP;
3. whether the source mechanic is per contact hit in multi-hit moves;
4. whether it still applies when the ability owner faints from the same contact hit;
5. whether current Battle Core can represent the faithful subset without changing generic faint-safe AFTER_DAMAGE policy.

No implementation or promotion is allowed before these boundaries are proved. If current AFTER_DAMAGE cannot express fatal/per-hit semantics, prefer PARTIAL_RUNTIME with an explicit regression rather than widening Battle Core inside this tranche.

Closure protocol: source audit -> focused runtime proof -> implementation/tests if justified -> 18/18 engineering -> exact artifact diff -> sync `01`, `04`, `15` -> 18/18 final notebook-bearing HEAD -> close without merge.
