# DATA V3 ABILITY OFFENSIVE STAT CONDITIONS — V1

## Purpose
Operational checkpoint for the bounded ability-reliability tranche following certified PR #86.

## Certified parent
- PR #86: `DATA V3 — audit offensive stat ability modifiers`.
- Certified final HEAD: `06b078b02766ff2c85d5ca45798d8293b8c8e557`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Parent ability coverage: **17 RUNTIME_SUPPORTED / 10 PARTIAL_RUNTIME / 346 DATA_ONLY / 373 total**.

## Current tranche
- Branch: `audit/data-v3-ability-offensive-stat-conditions-v1`.
- Exact parent: certified #86 final `06b078b02766ff2c85d5ca45798d8293b8c8e557`.

Initial bounded candidates:
- `defeatist`;
- `guts`;
- `hustle`.

Goal: determine whether the offensive-stat multiplier abstraction introduced in #86 can faithfully support any of these without converting source semantics into a final-damage approximation.

Rules:
1. immutable source first;
2. inspect effect history/version sensitivity before classification;
3. distinguish Attack/Special Attack multipliers from final damage multipliers;
4. verify burn/status interactions rather than assuming they exist;
5. if an ability has a second required mechanic (accuracy, burn override, turn counter, etc.), classify partial or leave DATA_ONLY rather than claiming full support;
6. no broad Battle Core changes solely to increase coverage;
7. at most this small candidate set in the tranche.

Closure protocol: source audit -> bounded decisions -> implementation/tests only if justified -> 18/18 engineering -> exact artifact diff against #86 -> sync `01`, `04`, `17` -> notebooks-only compare -> 18/18 exact final notebook-bearing HEAD -> close without merge.
