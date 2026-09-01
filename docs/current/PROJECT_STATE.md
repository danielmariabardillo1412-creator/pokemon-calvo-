# ESTADO ACTUAL DEL PROYECTO

## Baseline certificado

Último baseline funcional certificado anterior a esta reorganización:

- PR #95 — `DATA V3 — final end-to-end certification`
- rama: `audit/data-v3-end-to-end-closure-v1`
- HEAD final: `b4f6adc200bef18f8ac51b9144f2f9a838f464fd`
- estado: **cerrado sin merge**
- validación: **18/18 workflows SUCCESS** sobre el HEAD final.

Rama documental actual:

- `chore/documentation-consolidation-v1`
- parent exacto: `b4f6adc200bef18f8ac51b9144f2f9a838f464fd`
- alcance: documentación y organización; no cambia runtime, datos canónicos ni mecánicas.

`main` no representa actualmente el baseline moderno.

## DATA FOUNDATION V3 — CERRADO

Fuente inmutable:

- snapshot branch `data/pokeapi-v2-snapshot`
- commit `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`
- API tree `8349ea1ce75716897fe96e02a15950d19edba6c3`
- schema tree `02e031e1928d7e9456bf6f7486daacc4b8946c84`
- `data/api/v2` y `data/schema/v2` son read-only.

Contrato canónico:

- 1.025 especies
- 326 formas
- 18 tipos runtime
- 919 movimientos
- 373 habilidades
- 2.222 objetos
- 61.102 entradas de learnset
- 554 evoluciones
- 0 referencias rotas
- 0 definiciones rechazadas
- 18 movimientos XD Shadow excluidos explícitamente.

Fronteras runtime cerradas:

- Moves: 590 RUNTIME_SUPPORTED / 71 PARTIAL_RUNTIME / 246 DATA_ONLY / 12 UNSUPPORTED.
- Abilities: 21 RUNTIME_SUPPORTED / 14 PARTIAL_RUNTIME / 338 DATA_ONLY.
- Evolutions: 391 RUNTIME_SUPPORTED / 0 PARTIAL_RUNTIME / 149 DATA_ONLY / 14 UNSUPPORTED.
- Items held runtime: `leftovers`, `sitrus_berry`.
- Trainer bag runtime: `potion`, `super_potion`, `hyper_potion`, `max_potion`, `full_restore`.
- Curación Calvo V1: 20 / 60 / 120 / full / full+status.

El cierre end-to-end alcanza 567 PASS / 0 FAIL en el dominio DATA V3 y mantiene 298 PASS / 0 FAIL en la regresión española/tipos/runtime.

Referencia operativa: `docs/project_book/DATA_V3.md`.

## IA DE ENTRENADORES — STACK EXISTENTE

La línea certificada FASE 19–33 ya contiene:

- Trainer Battle Session
- Trainer Intelligence Foundation
- Tactical Intelligence
- Belief Inference
- Search Foundation
- Search Depth & Budget
- Self-Play Evaluation
- Evaluation Corpus
- Search Limit Benchmark
- Adaptive Branching / Action Coverage
- Public Coverage Beliefs
- Trainer Item Actions
- Strategic Switching V2
- Trainer Loadouts
- Trainer Team Composition.

El cerebro serio actual debe evolucionar desde `StrategicSwitchingTrainerBrain`, no volver a una ruta antigua de search-only.

`TrainerProfile` ya define estilos `balanced`, `aggressive`, `cautious` y `technical`. Esos perfiles cambian prioridades, no legalidad ni acceso a información oculta.

Las futuras diferencias de dificultad/expertise deben mantener la misma frontera anti-cheat.

Referencia operativa: `docs/project_book/TRAINER_AI.md`.

## Trabajo actual

1. terminar la reorganización documental;
2. certificar el HEAD documental exacto con la matriz normal;
3. cerrar la rama/PR según el protocolo de snapshots;
4. después retomar Trainer AI y diseñar la siguiente fase sin duplicar `TrainerProfile`.

## Trabajo deliberadamente no activo

- no reabrir DATA V3 para aumentar contadores;
- no introducir MCTS ni red neuronal sin un problema medido que lo justifique;
- no sustituir `main` todavía;
- no traducir masivamente código/runtime durante esta reorganización.
