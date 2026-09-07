# SIGUIENTE TRABAJO

## Workstream activo — Trainer AI Expertise V1

Rama:

`feature/trainer-ai-expertise-v1`

Parent certificado:

`337a4f787c7da18f9cf649aea929e79912840b2a`

Este workstream es una **feature nueva** posterior al cierre Game-Ready 27.1. No reabre C3f, no crea 27.2 y no invalida el cierre previo.

## Problema que se va a resolver

El sistema distingue ya personalidad táctica mediante `TrainerProfile`:

- `balanced`;
- `aggressive`;
- `cautious`;
- `technical`.

Pero el proposal autónomo final usa actualmente `TrainerProfile.balanced()` de forma fija y no existe una capa runtime separada de `expertise`/`difficulty`.

La regla de diseño permanece:

**estilo != competencia**.

- estilo = qué decisiones prefiere el entrenador;
- expertise = qué tan bien utiliza las mismas herramientas legítimas.

Ningún nivel de dificultad puede obtener información oculta adicional.

## E1-A — auditoría de contrato (ACTUAL)

Scope: **TEST/AUDIT-ONLY**.

Debe demostrar:

1. que los cuatro estilos existen y son materialmente distintos;
2. que el schema de `TrainerProfile` no contiene competencia ni información rival oculta;
3. que `StrategicSwitchingTrainerBrain` ya puede recibir un perfil;
4. que `TrainerItemAwareActionProposal` final está fijado a `balanced`;
5. que el proposal no recibe todavía `expertise` ni perfil desde `TrainerBattleSession`;
6. que la telemetría mantiene `profile_tiebreak_used=false` y `fase34_open=false`;
7. que el tie resolver Game-Ready no introduce personalidad como desempate oculto;
8. que el hueco de expertise es real antes de modificar producción.

Gate focal esperado tras conectar la nueva suite:

- Evaluation anterior: 408 PASS / 0 FAIL;
- nueva auditoría: 18 checks;
- objetivo si todo coincide con el contrato: **426 PASS / 0 FAIL**.

Después se exigirá la matriz completa normal de 18 workflows sobre el SHA exacto.

## Después de E1-A

Solo si la auditoría queda verde se diseñará E1-B, con el cambio productivo mínimo necesario para introducir competencia separada de estilo.

Todavía NO decidir por adelantado:

- nombres finales de niveles de expertise;
- profundidad/budget exactos por nivel;
- errores artificiales o aleatoriedad de entrenadores débiles;
- perfiles por Líder/Alto Mando/Campeón;
- integración de campaign/recovery;
- MCTS/red neuronal.

Esos puntos requieren evidencia y tests antes de convertirse en política.

## Barreras

- misma frontera anti-cheat para todos los niveles;
- misma legalidad autoritativa de Battle Core;
- no leer la acción actual elegida por el jugador;
- no usar live Battle RNG como atajo de dificultad;
- no debilitar completeness/depth guards para hacer a un entrenador “más fácil”;
- no mergear PR #105;
- no mover `main` de `641d4b1fb0bcf964205d616e96f198f05d702197`.
