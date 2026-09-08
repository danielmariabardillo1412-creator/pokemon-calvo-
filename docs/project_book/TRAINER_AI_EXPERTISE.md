# Trainer AI — Expertise V1

## E1.0 — Apertura audit-first

Estado: **ACTIVO / AUTORIZADO POR EL USUARIO / FEATURE NUEVA**.

Baseline de entrada certificado:

`337a4f787c7da18f9cf649aea929e79912840b2a`

Freeze anterior:

`27.1 — Trainer AI Game-Ready hardening CLOSED / VALIDATED`

Rama:

`feature/trainer-ai-expertise-v1`

Esta fase no reabre C3f ni Game-Ready 27.x. Existe para abordar una feature histórica que quedó deliberadamente diferida: separar estilo táctico de competencia/expertise.

## Distinción canónica

- **Estilo**: preferencias tácticas entre opciones legítimas.
- **Expertise**: calidad con la que el entrenador utiliza las mismas herramientas e información legítimas.

Difficulty/expertise nunca puede conceder:

- movimientos rivales todavía no observados;
- estado oculto del rival;
- acción actual elegida por el jugador;
- RNG privado de Battle Core;
- acciones que no estén en el action-space legal.

## Evidencia manual de apertura

Sobre el baseline 27.1:

1. `TrainerProfile` ya define cuatro estilos: `balanced`, `aggressive`, `cautious`, `technical`.
2. Esos perfiles cambian pesos tácticos y no contienen campos de información rival.
3. `StrategicSwitchingTrainerBrain` acepta un `TrainerProfile` opcional.
4. `TrainerItemAwareActionProposal` —la costura usada por el runtime Game-Ready— creaba cada búsqueda con `TrainerProfile.balanced()` de forma fija antes de E1-C.
5. El proposal no recibía profile/expertise desde `TrainerBattleSession` antes de E1-C.
6. La telemetría existente declara `profile_tiebreak_used=false` y `fase34_open=false`.
7. `TrainerGameReadyTieResolver` no usa estilo ni expertise como desempate oculto.

Conclusión de apertura: **el sistema de combate estaba cerrado y game-ready, pero la personalización de estilo/competencia del NPC final todavía no estaba integrada en el proposal runtime**. Expertise V1 resuelve esa feature sin reabrir el cierre anterior.

## E1-A — contrato de auditoría — CLOSED / CERTIFIED

Scope estricto: **TEST/AUDIT-ONLY**.

Checkpoint exacto:

`f8ca9d8ecfe7e2cd259e3affdd2fd048a73d1021`

Tree:

`229aafd5186b45b7f2c5fac7c0102a19a98a5afd`

Resultado:

- **18/18 workflows SUCCESS**;
- Trainer Evaluation Corpus: **426 PASS / 0 FAIL**;
- 18/18 checks nuevos de expertise PASS;
- aggregate: `TRAINER_AI_EXPERTISE_CONTRACT_AUDIT_COMPLETE`;
- cero archivos de producción modificados.

E1-A certificó que:

- los cuatro estilos existen y son materialmente distintos;
- el schema de estilo no contiene expertise/difficulty ni información rival oculta;
- `StrategicSwitchingTrainerBrain` ya es profile-aware;
- el proposal Game-Ready continuaba fijado a `TrainerProfile.balanced()`;
- el proposal no recibía todavía profile/expertise;
- `profile_tiebreak_used=false`;
- `fase34_open=false`;
- `TrainerBattleSession` no tenía estado runtime de expertise/difficulty;
- el tie resolver Game-Ready no usa estilo/expertise como fallback.

PR #106 contiene este workstream y permanece separado del PR histórico #105.

## Plan de cierre fijo — 4 tramos

Para no mover el objetivo durante la ejecución, Expertise V1 queda fijado en cuatro tramos:

1. **E1-A — contrato y hueco runtime** — COMPLETADO / CERTIFICADO.
2. **E1-B — seguridad de knobs de competencia** — COMPLETADO / CERTIFICADO.
3. **E1-C — integración productiva mínima de estilo + expertise** — COMPLETADO / CERTIFICADO.
4. **E1-D — E2E, regresión, certificación final y freeze** — IMPLEMENTED / CI PENDING.

No se añadirá E1-E por inercia. Cualquier ampliación posterior será otra feature separada.

## E1-B — seguridad de knobs de competencia — CLOSED / CERTIFIED

Objetivo: no convertir cualquier presupuesto existente en una dificultad sin demostrar antes que preserva Game-Ready.

Scope: **TEST/AUDIT-ONLY / cero producción**.

Suite nueva:

`TrainerExpertiseBudgetSafetyAuditTestSuite`

Contrato de 18 checks propios.

### Hipótesis resueltas por el gate

**Profundidad**

El proposal runtime exige `REQUIRED_DEPTH = 2`. Un presupuesto `depth_turns=1` puede ser determinista, pero solo completa profundidad física 1. Por tanto no puede reutilizarse como “entrenador fácil” sin romper el contrato de propuesta Game-Ready.

**Simulaciones**

Un presupuesto depth-2 demasiado pequeño puede agotarse antes de cerrar el horizonte. E1-B usa el fixture ya certificado con `max_simulations=3` para exigir que ese caso siga marcado incomplete/exhausted. No se congela un mínimo universal de simulaciones a partir de un solo fixture.

**Branching interno**

El proposal evalúa externamente **todas las raíces legales**. El límite `max_actions_per_side` actúa dentro de cada simulación. E1-B comparó cap 1 y cap 3 manteniendo depth 2 y presupuesto suficiente y certificó:

- horizonte completo en ambos;
- determinismo en ambos;
- frontera anti-cheat idéntica;
- ausencia de live RNG en trace;
- más simulaciones con el cap ancho;
- estado vivo no mutado.

Esto autorizó branching interno como knob mecánicamente seguro para Expertise V1.

**World breadth**

`MAX_WORLDS=4` permanece congelado. No se reduce por intuición porque E1-B no demostró que bajar cobertura de mundos preserve la robustez deseada.

### Barreras

- no reducir `REQUIRED_DEPTH`;
- no aceptar un presupuesto que produzca `budget_exhausted`;
- no cambiar el conjunto externo de raíces legales;
- no tocar observation/belief para simular dificultad;
- no leer acción actual del jugador;
- no usar live Battle RNG;
- no usar perfil como desempate oculto;
- no modificar Battle Core.

Checkpoint exacto E1-B:

`f8053f2a655fd38b1082e6e48688b8318e17d850`

Resultado literal:

- **18/18 workflows SUCCESS**;
- **444 PASS / 0 FAIL**;
- aggregate `TRAINER_AI_EXPERTISE_BUDGET_SAFETY_AUDIT_COMPLETE`;
- cap 3 expande materialmente más búsqueda que cap 1;
- `MAX_WORLDS=4` no se modifica.

## E1-C — integración productiva mínima — CLOSED / CERTIFIED

Implementación deliberadamente mínima:

- estilos canónicos: `balanced`, `aggressive`, `cautious`, `technical`;
- expertise V1: `limited` = cap interno 1, `full` = cap interno 3;
- no existe un nivel intermedio inventado porque E1-B no certificó cap 2;
- default compatible: `balanced + full`, equivalente al comportamiento Game-Ready previo;
- depth 2, 4 mundos, 220 simulaciones por root y **todas las raíces legales externas** permanecen comunes;
- `TrainerBattleSession` posee los IDs trusted de estilo/expertise por batalla;
- el proposal recibe un `TrainerProfile` canónico y el cap de expertise;
- el validador autoritativo revalida profile ID, expertise ID, cap, profundidad, completeness y legalidad exacta;
- `TrainerGameReadyTieResolver` permanece sin cambios y no usa estilo/expertise como desempate;
- Battle Core, scheduler/shared budget/660 y FASE34 permanecen fuera de alcance.

Checkpoint humano canónico E1-C:

`9076eae75e024930f67fc04ce5173e2d5d65c5b0`

Tree byte-idéntico al checkpoint técnico previo de E1-C. El commit técnico fue creado por `github-actions[bot]` y GitHub lo dejó en `action_required` sin crear jobs; por eso no se utilizó como certificación. El sibling humano sí ejecutó la matriz normal sobre el mismo tree.

Resultado certificado:

- **18/18 workflows SUCCESS**;
- Trainer Evaluation Corpus: **471 PASS / 0 FAIL**;
- Team Composition: **1258 PASS / 0 FAIL**;
- `SCRIPT ERROR`: **0**;
- traceback: **0**;
- aggregate: `TRAINER_AI_EXPERTISE_RUNTIME_INTEGRATION_COMPLETE`.

Corrección de contabilidad: `TrainerExpertiseRuntimeIntegrationTestSuite` contiene **27 checks**, no 26. Por tanto el total correcto de E1-C es **471/0**, no 470/0. La predicción anterior quedó invalidada por el conteo real y no se conserva como resultado.

## E1-D — E2E / regresión / freeze — IMPLEMENTED / CI PENDING

Scope estricto: **TEST/AUDIT-ONLY + documentación**. No hay cambios de producción autorizados salvo que la auditoría descubra un bug real.

Suite nueva:

`TrainerExpertiseBattleE2EClosureTestSuite`

Contrato E1-D: **27 checks**.

La auditoría final exige:

1. `limited` y `full` completar turnos autónomos reales mediante `submit_player_action_with_autonomous_trainer`;
2. cap 1 frente a cap 3 conservar las mismas raíces legales externas, depth 2 y ausencia de caller fallback;
3. los cuatro estilos atravesar el scoring runtime con sus pesos de riesgo canónicos sin alterar el action-space legal;
4. metadata manipulada de profile, expertise o inner cap ser rechazada fail-closed antes de Battle Core y sin avance de turno;
5. `reset_after_completion()` restaurar `balanced + full`, y una segunda batalla sobre la misma sesión usar únicamente su nueva configuración sin fuga de la primera.

Objetivo aritmético de Evaluation antes de ejecutar CI:

- baseline certificado E1-C: **471 PASS / 0 FAIL**;
- checks nuevos E1-D: **27**;
- objetivo esperado: **498 PASS / 0 FAIL**.

Este 498 es una expectativa previa a CI, no una certificación. E1-D solo podrá declararse CLOSED cuando el SHA final obtenga la matriz normal 18/18 y se recuperen los totales literales de Evaluation y Team Composition sin `SCRIPT ERROR`/traceback.

## Qué sigue fuera de Expertise V1

- campaign/recovery policy persistente;
- MCTS/red neuronal;
- dificultad basada en trampas o información oculta;
- balance definitivo de Líderes/Alto Mando/Campeón;
- world-agent/rival de mapa completo;
- cualquier re-apertura de C3f o Game-Ready 27.x.

## Invariantes externos

- PR #105 permanece OPEN / unmerged y no se mergea casualmente.
- `main` permanece exactamente en `641d4b1fb0bcf964205d616e96f198f05d702197`.
- El parent del workstream es el freeze 27.1 exacto, no `main`.
