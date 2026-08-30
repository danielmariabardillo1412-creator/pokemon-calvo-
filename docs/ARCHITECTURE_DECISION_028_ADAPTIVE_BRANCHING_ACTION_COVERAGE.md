# ADR-028 — Adaptive Branching / Action Coverage V1

## Estado

VALIDADA / CERRADA.

## Contexto

FASE 27 confirmó un límite concreto: con cuatro respuestas rivales públicamente plausibles y
`max_actions_per_side = 3`, la búsqueda podía excluir la cuarta respuesta peligrosa aunque el
presupuesto de simulaciones no estuviese agotado. El mismo banco refutó que profundidad 2 sea,
por sí sola, un cuello de botella demostrado.

La inspección posterior mostró dos hechos:

1. `TrainerPlausibleWorldFactory` ya conserva hasta cuatro movimientos plausibles del rival;
2. `TrainerMultiTurnSearch._bounded_actions()` mantiene el orden recibido dentro de MOVE y
   recorta después al máximo permitido.

Por tanto, una amenaza podía existir correctamente en el mundo plausible y quedar fuera de la
matriz únicamente por su posición en el moveset.

## Decisión

FASE 28 mantiene intactos el planner y el buscador de FASE 27 y añade un candidato A/B separado:

- `TrainerThreatOrderedWorldFactory`;
- `TrainerAdaptiveBranchingSearch`;
- `AdaptiveBranchingTrainerBrain`.

### Ordenación de movimientos plausibles

El nuevo factory llama primero al generador legítimo de movimientos plausibles de FASE 27.
No añade movimientos, no consulta el moveset real oculto y no modifica las creencias.

Solo reordena los movimientos ya presentes según una amenaza determinista contra el Pokémon
activo propio observado:

- potencia;
- precisión declarada;
- STAB;
- efectividad de tipo;
- prioridad positiva;
- utilidad estructurada básica de estado, cambios de stages, curación/drenaje y flinch.

La confianza de la hipótesis desempata amenazas iguales y el ID estable resuelve el último
empate. Una vez que una acción ya pertenece a un mundo plausible, la búsqueda protege primero
contra las respuestas más peligrosas de ese mundo, no contra el orden accidental del ID.

### Preservación del branching

`TrainerAdaptiveBranchingSearch` hereda íntegramente `TrainerMultiTurnSearch` y únicamente
instala el factory ordenado por amenaza. `_bounded_actions()` conserva el mismo esquema
estratificado MOVE/SWITCH y el mismo límite.

No se elevó el ancho global.

### Candidato A/B

`AdaptiveBranchingTrainerBrain` hereda `DepthSearchTrainerBrain` y sustituye solo el objeto de
búsqueda por `TrainerAdaptiveBranchingSearch`.

El brain anterior permanece intacto. El gate histórico de FASE 27 continúa demostrando el
baseline negativo, mientras FASE 28 mide el candidato de forma separada.

## Presupuesto congelado

- profundidad: 2;
- mundos: 2;
- simulaciones del banco de límites: 128;
- acciones máximas por lado: 3.

## Resultados del banco FASE 28

Con tres semillas y espejo de lados:

- 24 partidas del candidato;
- 12 partidas probe;
- 0 inválidas;
- determinismo confirmado;
- controles de replanning: **6/6 y 6/6**;
- branching conocido: candidato **6/6**, frente a **0/6** del planner FASE 27;
- probe de branching: **6/6**;
- la nuke pública entra en la traza del candidato;
- el candidato abre con el debuff defensivo esperado;
- una respuesta débil queda podada;
- `max_actions_per_side` sigue en **3**;
- `budget_exhausted = false`;
- cobertura verdaderamente oculta: candidato **0/6** y el movimiento sigue ausente de la
  primera traza, preservando anti-cheat.

Gate específico: **52 PASS / 0 FAIL**.

## Regresión de inteligencia sobre FASE 26

El candidato adaptativo se ejecutó también sobre las 60 partidas del corpus estadístico de
FASE 26, no solo sobre los gates del planner antiguo.

Resultado:

- baseline: **48/60**;
- candidato adaptativo: **60/60**;
- mejoras emparejadas: **12**;
- regresiones emparejadas: **0**;
- pares iguales: **48**;
- 0 draws;
- 0 partidas inválidas;
- resultado determinista;
- **36 PASS / 0 FAIL** en el gate de corpus adaptativo.

Por tanto, la corrección del branching no muestra regresión en el corpus controlado existente.
Como siempre, 60/60 no se interpreta como superioridad universal fuera de ese corpus.

## Certificación

Sobre el HEAD previo al cierre documental `9c16127608bd983d6575d571a6c4d75451a68489`
se obtuvieron **11/11 workflows SUCCESS**:

- FASE 28 adaptive branching;
- FASE 27 search-limit benchmark;
- FASE 26 evaluation corpus;
- FASE 25 self-play;
- FASE 24 search-depth budget;
- FASE 23 search foundation;
- FASE 22 belief inference;
- FASE 21 tactical intelligence;
- FASE 20 intelligence foundation;
- FASE 19 trainer battle session;
- regresión global Godot 4.7.

El commit documental final debe repetir esta certificación antes de cerrar PR #23.

## Limitación residual

FASE 28 solo reordena los movimientos que ya llegaron al mundo plausible. No resuelve todavía
un dominio de hipótesis mayor de cuatro movimientos ni inventa cobertura que el modelo de
creencias no considere legítimamente plausible.

Ese límite se mantiene deliberadamente separado de la selección de branching.

## Siguiente decisión

La siguiente prioridad debe atacar el límite restante demostrado por FASE 27: **cobertura
oculta legítima / priors de moveset**, sin omnisciencia.

Antes de MCTS o profundidad 3 conviene comprobar si el dataset ya contiene compatibilidades de
movimientos por métodos distintos del level-up (máquinas, tutor, egg u otros) y, si existen,
construir priors de menor confianza que amplíen mundos plausibles sin revelar el moveset real.
