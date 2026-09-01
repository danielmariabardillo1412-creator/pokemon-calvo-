# DATA V3 ABILITY TARGET-STATE AUDIT — V1

## Purpose
Operational checkpoint for the bounded DATA V3 ability-reliability tranche following certified PR #90.

## Certified parent
- PR #90: `DATA V3 — audit opponent end-turn ability blockers`.
- Certified final HEAD: `84e58498e4453ee5378e3209487f4cbfe7b2eead`.
- Status: **18/18 workflows SUCCESS**, closed without merge.
- Parent ability coverage: **19 RUNTIME_SUPPORTED / 14 PARTIAL_RUNTIME / 340 DATA_ONLY / 373 total**.

## Current tranche
- Branch: `audit/data-v3-ability-target-state-v1`.
- Exact parent: certified #90 final `84e58498e4453ee5378e3209487f4cbfe7b2eead`.

## Audit question
PR #90 proved that Bad Dreams is blocked because existing persistent-status conditions inspect the ability owner rather than the effect target. This tranche asks whether target-state gating is a genuinely shared ability-family requirement or merely an isolated mechanic.

## Initial plan
1. inventory remaining DATA_ONLY abilities whose source semantics depend on opponent/target battle state;
2. audit a bounded set (roughly 3–4 candidates) from immutable source;
3. distinguish missing target-status gating from unrelated missing mechanics such as critical-hit control, switch history, gender, weather, or field state;
4. add a generic target-state predicate only if multiple source-backed mechanics can safely reuse it with existing effect primitives;
5. otherwise record a negative audit and preserve current classifications.

## Rules
- source-first, never infer behavior from names;
- no coverage inflation;
- no broad weather/terrain/switch/critical subsystem merely to rescue one candidate;
- any new condition must be generic, directionally explicit, and covered by real battle tests;
- if the effect transaction itself is not representable, target-state gating alone is insufficient;
- stop on any regression and fix root cause before unrelated work.

## Closure protocol
source inventory -> bounded semantic audit -> minimal implementation/tests only if justified -> 18/18 engineering -> exact artifact diff against #90 -> sync `01`, `04`, `21` -> notebooks-only compare -> 18/18 exact final notebook-bearing HEAD -> close without merge.
