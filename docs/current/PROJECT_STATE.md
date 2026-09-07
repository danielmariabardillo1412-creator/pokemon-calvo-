# ESTADO ACTUAL DEL PROYECTO

## Baseline funcional certificado

Último baseline moderno certificado antes del workstream actual:

`337a4f787c7da18f9cf649aea929e79912840b2a`

Commit:

`docs(trainer-ai): freeze 27.1 game-ready hardening`

Estado:

- Trainer AI runtime system 26.67: **CLOSED / COMPLETED**;
- Trainer AI Game-Ready 27.1: **CLOSED / VALIDATED**;
- doble checkpoint técnico/humano: **18/18 workflows SUCCESS**;
- Evaluation: **408 PASS / 0 FAIL**;
- Trainer Battle Session: **66 PASS / 0 FAIL**;
- Team Composition: **1258 PASS / 0 FAIL**;
- Godot global: **472 PASS / 0 FAIL**.

## DATA V3

Estado: **CERRADO / CERTIFICADO**.

Contrato canónico preservado:

- 1.025 especies;
- 326 formas;
- 18 tipos runtime;
- 919 movimientos;
- 373 habilidades;
- 2.222 objetos;
- 61.102 entradas de learnset;
- 554 evoluciones.

No reabrir DATA V3 para subir contadores ni alterar fuentes inmutables.

## Trainer AI — sistema cerrado

El entrenador de combate ya dispone de:

- memoria bilateral sanitizada;
- beliefs sin información oculta;
- búsqueda acotada;
- MOVE / SWITCH / ITEM donde el modo lo permita;
- switching estratégico;
- loadouts y composición;
- proposal profundo sobre todas las raíces legales;
- sustitución autónoma side_b;
- resolución game-ready de empates exactos;
- integración real Overworld -> TrainerBattleSession -> presentación -> Battle Core;
- victoria, derrota, reset y segunda batalla certificados;
- adversarial full-battle sin deadlock.

No reabrir C3f ni Game-Ready 27.x salvo regresión reproducible.

## Nuevo workstream activo — Trainer AI Expertise V1

Rama:

`feature/trainer-ai-expertise-v1`

Parent exacto:

`337a4f787c7da18f9cf649aea929e79912840b2a`

Objetivo: separar **estilo** de **competencia/expertise** sin alterar legalidad ni acceso a información.

Evidencia de apertura:

- `TrainerProfile` ya contiene estilos `balanced`, `aggressive`, `cautious`, `technical`;
- `StrategicSwitchingTrainerBrain` acepta `TrainerProfile`;
- el proposal runtime Game-Ready usa actualmente `TrainerProfile.balanced()` de forma fija;
- `TrainerBattleSession` no expone todavía `expertise_id` ni `difficulty_id`;
- la telemetría final conserva `fase34_open=false`;
- el tie resolver Game-Ready no usa perfil como desempate oculto.

La primera tranche es **TEST/AUDIT-ONLY**. No se cableará producción hasta certificar el hueco exacto.

## Invariantes externos

- PR #105: **OPEN / unmerged**; no mergear casualmente.
- `main`: debe permanecer exactamente en `641d4b1fb0bcf964205d616e96f198f05d702197`.
- El workstream nuevo parte del freeze 27.1, no de `main`.
- Difficulty/expertise nunca puede conceder movimientos rivales ocultos, RNG privado ni un action-space distinto por conocimiento ilegítimo.
