# IA6 — W04 regional integration audit, 2026-11-11

Official base: `ddc8a1af56c5fe7e950bee5bf3986d8e62261f8f`
Candidate: `codex/calvo-ia6-candidate-w04-regional-20261111`
Source: `codex/calvo-ia6-staging-20261111-w04-evolution`
Source checkpoint: `docs/coordination/items_parallel_v1/CONTINUOUS_V4/STATE_W04.md`.

## Successfully carried to isolated candidate (NOT production-certified yet)

- `modules/creatures/domain/creature_instance.gd`
- `modules/creatures/progression/creature_factory.gd`
- `modules/inventory/field_item_service.gd`
- Regional helpers: `canonical_form_identity_w04.gd`, `regional_ability_selection_w04.gd`, `regional_evolution_contract_w04.gd`, `regional_item_evolution_contract_w04_v2.gd`.

These three existing modules were checked against the W04 staging base `e63b2e6c7e175fba318cc2f562bebd1769589092`: current official blobs were identical before port. This is a partial candidate; dependencies remain absent.

## Three mandatory surgical conflicts (DO NOT replace whole files)

1. `modules/creatures/progression/evolution_system.gd`: official already preserves W02 `effective_nature_id` and computes stats via `stat_nature`. Add W04 regional target/form inspection and form publication around this path **without duplicating or reverting** effective-nature computation.
2. `modules/save/field_native_save.gd`: official already builds and publishes `caught_base_species_ids`, validates canonical captured ledger after load. Add W04 persistent form validation while retaining these capture fields.
3. `modules/save/save_game_data.gd`: official already carries optional capture history through build/decode/validate. Add W04 `form_id` structural validation inside creature decode while retaining the ledger and legacy defaults.

Preserve W03 native repel, W03 capture Repeat/Net/Moon, W05 books panel, W02 nature/evolution, IA6 Cuerda Huida, and `dynamax_candy` exclusion. No changes to `main`, V28, PR118 or worker branches.

## Certification status and next steps

W04 staging checkpoint says `READY_FOR_IA6_MERGE_CANDIDATE`, 7/7 regional routes, 396 checks, 55/56 regional encounters; Alolan Exeggutor remains blocked. It explicitly has NOT run historic CAMP003–006 on staging or the real visual bag. Its green CI #42965322073 applies to source SHA `cdd53fb1d61a3aeb8790818aa571e13f9afbaed8`, not this integrated candidate.

1. Make narrow additive edits in the three conflicting modules, inspect each merged function.
2. Bring W04 test runners into isolated candidate, adapt CI to new branch. Preserve guards for W03 capture ledger and W02 effective nature.
3. Run W04 regional routes, SaveV2 hostile/legacy, W02, W03, W05, and real FieldItemBag integration.
4. Do not promote to official until this exact candidate SHA has green cross-worker runs. No false claim that partial stage is functionally ready.
