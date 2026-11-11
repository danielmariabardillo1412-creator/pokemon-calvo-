# W04 — CONTINUOUS_V2 / CHECKPOINT 2026-11-11

- worker: W04
- branch: `codex/calvo-items-20261104-w04-camp006`
- mission_version: `CONTINUOUS_V2/PLAN_W04.md` en rama árbitra
- phase: B
- block: **B02, pruebas CI pendientes**; B01 inventario completo
- next_id: confirmar CI del workflow `parallel-w04-continuous-v2.yml` y reparar SOLO archivos propios; después B03, sin repetir matriz.
- checked: **57 especies regionales / 28 EvolutionRecord** examinados estáticamente
- functional_new: **0 certificados** en V2, a la espera de CI real
- already_certified: **2 contratos L2 Galarica** de T05 (sin contarlos de nuevo)
- candidate_routes_B02: **7 use_item** existentes en fuentes regionales: `darumaka_galar/ice_stone/darmanitan_galar_standard`, `growlithe_hisui/fire_stone/arcanine_hisui`, `sandshrew_alola/ice_stone/sandslash_alola`, `slowpoke_galar/galarica_cuff/slowbro_galar`, `slowpoke_galar/galarica_wreath/slowking_galar`, `voltorb_hisui/leaf_stone/electrode_hisui`, `vulpix_alola/ice_stone/ninetales_alola`
- matrix_static: 11 RUNTIME_SUPPORTED_STATIC; 7 RUNTIME_CONDITIONAL_ITEM_CATALOG; 10 DATA_ONLY/unsupported. These static values are NOT CI/proven functional.
- blocked: no new blocked IDs proven until runtime; global evolution L3 blocked by missing consumer/transaction and destination `form_id`; Exeggutor Alola hidden Harvest still blocked
- L3_real_new: **0**
- last_green_code_sha: `18bc8cbf0a2135b34516cf857e6e36824c920244` (previous known T05 green; do not attribute to new V2 HEAD)
- last_green_run_id: `42922194326` (T05 only)
- ci_pending: **YES**; current V2 CI has not been observed completed/success
- owned_files_changed: `reports/W04/CONTINUOUS_V2_REGIONAL_EVOLUTION_MATRIX.csv`, `regional_item_evolution_contract_w04_v2.gd`, `tests/gameplay/w04_continuous_v2_regional_items.gd`, `.github/workflows/parallel-w04-continuous-v2.yml`
- protected_tickets: shared `EvolutionSystem.apply_evolution` cannot safely preserve regional target form or require real item/atomic replacement; IA6 must integrate. A tentative V6 edit published during previous turn was **reverted** after discovering the newer V2 prohibition; verified restoration of original blob SHA `2f684ae11f36c6c2183a7100b9015c3f6c906f49`. Unverified V6 workflow/test removed, historical V6 progress preserved.
- next_safe_action: verify V2 CI logs, repair only W04-owned helpers/tests/workflow if red, do B03 Party/Storage/SaveV2 regression on existing authentic forms, publish READY_FOR_IA6 if L2 program exhausted.

## Evidence
- B01 canonical matrix commit `5e7a5166babaeee3c33a7fecb07ba8ec111af0c8`.
- B02 contract helper commit `aa234b8f92f42e234e65477daad6ac369acdf31b`.
- B02 functional test commit `7a456c6fd628d4c09fd41c2d789df4957c3974fd`.
- CI workflow commit `5da274b45c15ce2b28bd2a2f3185354adcb32147`.

**Important:** No reported CI run ID/SUCCESS for current V2 HEAD, no item-level consumer and no cross-worker integration verified. Do not claim campaign complete.
