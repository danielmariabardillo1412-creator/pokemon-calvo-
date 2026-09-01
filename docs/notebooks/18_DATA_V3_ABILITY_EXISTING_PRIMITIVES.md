# DATA V3 ABILITY EXISTING PRIMITIVES — V1

## Purpose
Operational checkpoint for the bounded ability-reliability tranche following certified PR #87.

## Certified parent
- PR #87: `DATA V3 — audit conditional offensive stat abilities`.
- Certified final HEAD: `6fc1f73be1b24cba0c8052549ab4ea5f1e96c976`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Parent ability coverage: **18 RUNTIME_SUPPORTED / 12 PARTIAL_RUNTIME / 343 DATA_ONLY / 373 total**.

## Current tranche
- Branch: `audit/data-v3-ability-existing-primitives-v1`.
- Exact parent: certified #87 final `6fc1f73be1b24cba0c8052549ab4ea5f1e96c976`.

## Scope
Audit a small source-first set of remaining DATA_ONLY abilities that may reuse already certified Battle Core primitives. Initial anchor candidate: `gorilla_tactics`; adjacent candidates will be selected only after immutable-source and runtime-surface inspection.

Rules:
1. immutable source first;
2. prefer existing trigger predicates and modifier channels;
3. no broad Battle Core primitive solely to increase coverage;
4. partial support is acceptable only for an explicitly faithful subset;
5. source-required secondary mechanics must remain explicit blockers rather than being approximated;
6. keep the tranche to roughly 2–4 candidates;
7. do not reopen Guts/Hustle blockers from #87 in this tranche.

Closure protocol: source audit -> bounded decisions -> implementation/tests only if justified -> 18/18 engineering -> exact artifact diff against #87 -> sync `01`, `04`, `18` -> notebooks-only compare -> 18/18 exact final notebook-bearing HEAD -> close without merge.
