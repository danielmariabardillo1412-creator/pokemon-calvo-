# DEFERRED WORK AND ROADMAP NOTEBOOK

## Purpose

Record important work that exists or has been planned but is **not the current task**. This prevents a fresh context from jumping into a familiar-looking older branch and abandoning the active workstream.

## Current priority

Finish DATA FOUNDATION V3 semantic reliability before returning to trainer AI expansion.

Reason: trainer decisions are only meaningful if species, learnsets, move effects, types, abilities/items metadata, and runtime-support labels are trustworthy. Bad data can make a good trainer brain appear bad and can contaminate later AI evaluation/training.

## Trainer AI — deferred, not abandoned

A substantial trainer AI stack already exists and is covered by the 18-workflow matrix. Prior phases include:

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

The old/incomplete archetype direction must not be resumed blindly.

Known future direction:

- Serious trainer archetypes (Leader / Elite Four / Champion and similar) should build on `StrategicSwitchingTrainerBrain`, not regress to an older search-brain path.
- Difficulty should alter priorities/competence, not grant illegal hidden information.
- Preserve no-cheating rules for unknown opponent moves/public information.
- Trainer item use must respect finite resources.
- Strategic switching, loadouts, expertise and team composition are already architectural foundations to reuse.

## Data work after Move Effects V3

After move-effect semantics are sufficiently trustworthy, remaining data-reliability work should include explicit contracts for:

- Abilities: distinguish preserved source metadata from mechanics actually implemented at runtime.
- Items: distinguish stored item data from executable battle/overworld effects.
- Evolutions: preserve full conditions/provenance while making supported runtime evolution mechanics explicit.
- Final end-to-end data certification from immutable snapshot → V3 adapter → raw data → Godot importer → normalized data → runtime tests.

Do **not** interpret “373 abilities” or “2,222 items preserved” as “373 abilities and 2,222 item mechanics implemented.”

## Battle Core expansion policy

Some moves currently expose missing engine capabilities, including:

- side/team targeting
- delayed/persisted effects
- weather-dependent effect values
- temporary type changes/suppression
- status replacement / move-specific status durations
- heal values derived from live battle stats
- unique move state machines

These observations are valuable future requirements, but Move Effects V3 should not expand Battle Core merely to improve coverage numbers. Implement such mechanics later as deliberate engine features with their own tests.

## Repository/documentation maintenance

The project has formal architecture docs, ADR/history areas, and now `docs/notebooks/` for operational continuity.

When a new major workstream begins, add or update a dedicated notebook rather than letting `04_NEXT_STEPS.md` grow into a giant history file. `04_NEXT_STEPS.md` should remain a short live pointer; detailed history belongs in topic notebooks.
