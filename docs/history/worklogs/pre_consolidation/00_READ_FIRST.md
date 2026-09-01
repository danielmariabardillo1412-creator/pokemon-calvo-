# PROJECT NOTEBOOKS — READ FIRST

These notebooks are the operational memory of the project. They exist so a new AI/chat context can recover the exact working state without relying on conversation history.

They do **not** replace formal architecture documents such as `docs/ARCHITECTURE.md`, `docs/BATTLE_EFFECTS.md`, or `docs/DATA_FOUNDATION_V3.md`. Formal docs describe the system. These notebooks describe **where the work currently is, why decisions were made, what is certified, and what must happen next**.

## Read order for a fresh context

1. `04_NEXT_STEPS.md` — exact current continuation point.
2. `01_PROJECT_STATE.md` — current certified technical state and repository landmarks.
3. `02_DATA_V3_MOVE_EFFECTS_AUDIT.md` — detailed DATA V3 / Move Effects V3 audit history.
4. `03_WORK_PROTOCOL.md` — non-negotiable working and certification rules.
5. Relevant formal docs under `docs/` for architecture details.

## Current continuity anchor

- Repository: `danielmariabardillo1412-creator/pokemon-calvo-`
- Engine: Godot 4.7
- Certified code baseline before introduction of these notebooks: `24889d355e8d89f8873d2d958efb951080fd8027`
- Baseline branch: `fix/data-v3-simple-self-stat-boosts-b`
- PR #51: closed without merge after exact-head certification.
- Normal certification set: 18 GitHub Actions workflows.
- Current major workstream: **DATA FOUNDATION V3 / Move Effects V3 semantic audit**.
- Do **not** jump back to trainer archetypes / trainer AI work until the data audit is deliberately closed.

## Handoff rule

At the end of every meaningful certified tranche, update at least:

- `04_NEXT_STEPS.md` with the exact next action and latest certified branch/PR.
- `02_DATA_V3_MOVE_EFFECTS_AUDIT.md` when the tranche belongs to DATA V3.
- `01_PROJECT_STATE.md` if project-wide counts, architecture, canonical branches, or certification rules materially change.

A fresh context should be able to continue by reading these files plus GitHub state. If chat memory and notebooks disagree, **GitHub commits, PR state, CI results, and immutable source data are authoritative**.
