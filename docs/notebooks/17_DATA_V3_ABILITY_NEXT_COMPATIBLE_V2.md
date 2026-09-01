# DATA V3 ABILITY NEXT COMPATIBLE — V2

## Purpose
Operational checkpoint for the bounded DATA FOUNDATION V3 ability-reliability tranche following certified PR #86.

## Certified parent
- PR #86: `DATA V3 — audit offensive stat ability modifiers`.
- Certified final HEAD: `06b078b02766ff2c85d5ca45798d8293b8c8e557`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Parent ability coverage: **17 RUNTIME_SUPPORTED / 10 PARTIAL_RUNTIME / 346 DATA_ONLY / 373 total**.

## Current tranche
- Branch: `audit/data-v3-ability-next-compatible-v2`.
- Exact parent: certified #86 final `06b078b02766ff2c85d5ca45798d8293b8c8e557`.

Goal: audit a small source-first subgroup from the remaining 346 DATA_ONLY abilities. Promote only mechanics whose source-faithful semantics fit existing Battle Core abstractions cleanly, or justify one genuinely shared primitive across multiple abilities.

Rules:
1. immutable snapshot source first;
2. bounded scope: normally 2–4 candidates;
3. no keyword/family mass promotion;
4. negative audit is a valid result;
5. do not broaden Battle Core solely to increase coverage;
6. preserve actor/defender direction, calculation phase, trigger granularity and version history;
7. add real battle integration tests whenever timing/calculation placement matters.

Explicit blockers not to reopen in this tranche merely for coverage:
- Iron Barbs full support / Rough Skin version history;
- Static, Flame Body, Poison Point, Gooey fatal/per-strike contact policy;
- Water Compaction / Weak Armor;
- Transistor version-sensitive multiplier;
- Long Reach / Technician;
- Iron Fist / Strong Jaw / Mega Launcher / Sharpness move-category provenance;
- Filter / Solid Rock effectiveness predicate;
- Fluffy modifier composition/event aggregation;
- Heatproof burn residual;
- Reckless crash-on-miss semantics.

Closure protocol:
source audit -> bounded decision -> implementation/tests only if justified -> 18/18 engineering -> exact artifact diff against #86 -> sync `01`, `04`, `17` -> notebooks-only compare -> 18/18 exact final notebook-bearing HEAD -> close without merge.
