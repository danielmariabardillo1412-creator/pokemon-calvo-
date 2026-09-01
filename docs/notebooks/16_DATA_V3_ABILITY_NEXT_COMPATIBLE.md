# DATA V3 ABILITY NEXT COMPATIBLE — V1

## Purpose
Operational checkpoint for the bounded ability-reliability tranche following certified PR #85.

## Certified parent
- PR #85: `DATA V3 — audit contact retaliation damage ability`.
- Certified final HEAD: `6909aa778eca6555184167401f5e52be11f46ac3`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Parent ability coverage: **13 RUNTIME_SUPPORTED / 10 PARTIAL_RUNTIME / 350 DATA_ONLY / 373 total**.

## Current tranche
- Branch: `audit/data-v3-ability-next-compatible-v1`.
- Exact parent: certified #85 final `6909aa778eca6555184167401f5e52be11f46ac3`.

Goal: inspect a small source-first subset of the remaining 350 DATA_ONLY abilities and promote only candidates whose faithful full or useful-partial semantics already fit Battle Core with no broad architecture change.

Rules:
1. audit immutable source before implementation;
2. at most 2–4 candidates in this tranche;
3. no mass promotion from keyword/family heuristics;
4. do not reopen Iron Barbs/Rough Skin, Water Compaction/Weak Armor, Transistor or other explicitly blocked mechanics merely to increase coverage;
5. inspect actor/defender direction, trigger granularity, condition predicates, multi-effect transactions and version history before deciding support;
6. a negative audit with explicit blockers is a valid result;
7. if a candidate needs a broad Battle Core primitive solely for one ability, keep it DATA_ONLY instead.

Closure protocol: source audit -> bounded decision -> implementation/tests only if justified -> 18/18 engineering -> exact artifact diff against #85 -> sync `01`, `04`, `16` -> notebooks-only compare -> 18/18 exact final notebook-bearing HEAD -> close without merge.
