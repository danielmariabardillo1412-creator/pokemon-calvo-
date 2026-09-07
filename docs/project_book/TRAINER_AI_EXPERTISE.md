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
4. `TrainerItemAwareActionProposal` —la costura usada por el runtime Game-Ready— crea cada búsqueda con `TrainerProfile.balanced()` de forma fija.
5. El proposal no recibe profile/expertise desde `TrainerBattleSession`.
6. La telemetría existente declara `profile_tiebreak_used=false` y `fase34_open=false`.
7. `TrainerGameReadyTieResolver` no usa estilo ni expertise como desempate oculto.

Conclusión provisional: **el sistema de combate está cerrado y game-ready, pero la personalización de estilo/competencia del NPC final todavía no está integrada en el proposal runtime**. Esto es una feature nueva, no una regresión del cierre anterior.

## E1-A — contrato de auditoría

Scope estricto: **TEST/AUDIT-ONLY**.

Archivos previstos:

- nuevo `tests/trainer_ai/trainer_expertise_contract_audit_test_suite.gd`;
- una línea de conexión en `trainer_evaluation_corpus_test_runner.gd`;
- sincronización documental de `docs/current/` y este cuaderno.

Cero producción.

La suite debe certificar 18 puntos:

- presencia de las fuentes relevantes;
- cuatro estilos con IDs distintos;
- pesos materialmente distintos;
- schema de estilo sin `expertise_id`/`difficulty_id`;
- schema sin campos de información rival;
- roundtrip de estilo estable;
- `StrategicSwitchingTrainerBrain` profile-aware;
- proposal runtime fijado a `balanced`;
- ausencia de profile/expertise en la firma del proposal;
- `profile_tiebreak_used=false`;
- `fase34_open=false`;
- sesión sin estado runtime de expertise/difficulty;
- tie resolver sin fallback de perfil/expertise;
- aggregate final.

Baseline Evaluation antes de E1-A:

`408 PASS / 0 FAIL`

Si los 18 checks nuevos reflejan correctamente el contrato, objetivo focal:

`426 PASS / 0 FAIL`

Después: matriz normal **18/18 workflows SUCCESS** sobre el SHA exacto.

## Qué no se decide todavía

E1-A no congela nombres ni comportamiento de niveles de dificultad. En particular no autoriza todavía:

- `novice/normal/expert/master` u otra taxonomía;
- reducir profundidad o mundos por intuición;
- introducir errores artificiales;
- aleatoriedad para hacer NPCs malos;
- dar perfiles concretos a Líderes/Alto Mando/Campeón;
- campaign/recovery policy;
- MCTS/red neuronal;
- modificar Battle Core.

E1-B solo se abrirá a partir de evidencia E1-A verde y deberá usar el cambio productivo mínimo.

## Invariantes externos

- PR #105 permanece OPEN / unmerged y no se mergea casualmente.
- `main` permanece exactamente en `641d4b1fb0bcf964205d616e96f198f05d702197`.
- El parent del workstream es el freeze 27.1 exacto, no `main`.
