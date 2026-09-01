# WORK PROTOCOL NOTEBOOK

## Purpose

Rules for continuing this repository safely across long AI/chat sessions. These rules are operational safeguards, not optional style preferences.

## Core engineering rule

**Do not accumulate failures.**

For every tranche:

1. Investigate first.
2. Make one bounded change/family.
3. Add a regression gate that encodes the intended truth.
4. Run the focal workflow.
5. If it fails, stop all onward work and find the root cause.
6. Fix the root cause, rerun focal tests, then rerun regressions.
7. Continue only when green.

Never continue stacking changes on top of an unexplained failure.

## Small-tranche rule

Prefer small semantic families over large bulk edits, even if bulk editing appears faster.

Reason: one hidden exception in a broad transformation can contaminate many records and make later failures difficult to localize.

For DATA V3 move effects, the preferred unit is usually:

- one unique move, or
- a small family whose source semantics and runtime representation have been explicitly proven identical.

## Source-of-truth order

When sources disagree, use this priority:

1. Immutable canonical source snapshot (`data/api/v2`, `data/schema/v2`).
2. Exact Git commit/branch state.
3. CI output/artifacts generated from that exact HEAD.
4. Formal repository documentation.
5. Operational notebooks.
6. Chat/context memory.

Do not edit immutable source JSON to make tests pass.

## DATA V3 correctness rule

Do not confuse these statements:

- “PokéAPI contains this datum.”
- “V3 preserved this datum.”
- “Battle Core can execute this mechanic faithfully.”

They are separate claims.

If runtime support is incomplete, classify honestly as `PARTIAL_RUNTIME`, `DATA_ONLY`, or `UNSUPPORTED`. Never add a plausible approximation merely to increase coverage counts.

Do not expand Battle Core solely to make coverage reports prettier. Add mechanics only when deliberately implementing the game mechanic itself.

## Archived V2 rule

`tools/archive/pokeapi_adapter_v2_legacy.py` is provenance/legacy code. Avoid modifying it for DATA V3 corrections.

V3-specific compatibility corrections belong in `tools/pokeapi_adapter.py` unless architecture is deliberately redesigned.

## Branch / PR certification pattern

This repository currently uses a chain of certified snapshot branches.

- Create the next branch from the latest certified HEAD.
- Make the bounded change.
- Open a PR against the immediately previous certified branch.
- Let all normal workflows run on the final code/test HEAD.
- Require all 18 workflows to pass on that exact SHA.
- Close the PR **without merge** after certification unless the user explicitly changes this policy.
- The closed PR branch/HEAD becomes the next snapshot parent.

Do not assume `main` contains the latest certified work.

## Exact-head rule

If code/tests change after CI was green, the old CI result no longer certifies the branch. Run certification again on the new HEAD.

Documentation-only changes should also be tested when they become part of the new chain baseline, because workflow/config interactions and repository integrity still matter.

## CI matrix expected during current work

Normal matrix is 18 workflows, including:

- Data Foundation V3
- Godot 4.7 global
- Spanish Types Foundation
- Trainer Battle Session
- Trainer Intelligence Foundation
- Trainer Tactical Intelligence
- Trainer Belief Inference
- Trainer Search Foundation
- Trainer Search Depth Budget
- Trainer Self Play Evaluation
- Trainer Evaluation Corpus
- Trainer Search Limit Benchmark
- Trainer Adaptive Branching
- Trainer Public Coverage Beliefs
- Trainer Item Actions
- Trainer Strategic Switching V2
- Trainer Loadouts
- Trainer Team Composition

If the matrix changes, update this notebook and `01_PROJECT_STATE.md`.

## Conversation / timeout resilience

The chat may time out or reach context limits. GitHub state must make this harmless.

Work in checkpoints. At every meaningful checkpoint record:

- branch
- exact HEAD
- PR number/state
- CI result
- what was proven/fixed
- exact next step

Avoid giant repository-tree fetches. Prefer targeted file/directory queries and exact CI artifacts; oversized responses previously caused delivery problems.

## Fresh-context recovery procedure

A new AI/chat should:

1. Read `docs/notebooks/00_READ_FIRST.md`.
2. Read `docs/notebooks/04_NEXT_STEPS.md`.
3. Read the relevant audit notebook.
4. Resolve the referenced branch/HEAD/PR in GitHub.
5. Verify CI state before modifying anything.
6. Continue from the latest certified HEAD, not from `main` by assumption.

If the notebook is slightly stale, GitHub is authoritative; update the notebook as part of the next certified tranche.
