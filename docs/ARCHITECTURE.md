# Pokémon Calvo — Current Architecture

Fecha de sincronización: 2026-08-30  
Baseline: FASE 18 — `feature/battle-run-presentation-v1`

Este documento describe la arquitectura **vigente** del baseline stacked. Los ADR conservan el razonamiento histórico de cada cambio; este archivo no intenta repetir fase por fase toda la historia.

## Forma general

La arquitectura es **feature-first con límites hexagonales selectivos**. El dominio se agrupa por capacidad (`battle`, `creatures`, `capture`, `inventory`, `save`, `encounters`, `overworld`, `gameplay`) y las capas aparecen cuando existe una frontera real de autoridad o presentación.

```text
Input / UI / Scene Nodes
        |
        | intents
        v
Presentation / Overworld orchestration
        |
        v
WildAdventureSession  <---- application boundary for wild-adventure lifecycle
   |        |       |       |
   |        |       |       +--> SaveGameRepository
   |        |       +----------> ProgressionSystem
   |        +------------------> Capture / Inventory / Party / Storage
   +---------------------------> AuthoritativeBattleServer
                                     |
                                     v
                       BattleState + TurnExecutor + RNG
                         |        |         |
                         |        |         +--> Status / triggers / effects
                         |        +------------> DefinitionCatalog
                         v
                       BattleEvent[]
```

La UI puede **leer** estado vivo para representarlo, pero no es dueña de su verdad. No modifica HP, PP, `active_id`, ownership, catch probability, escape odds ni resultado de combate por su cuenta.

## Reglas de dependencia

1. Las reglas y agregados de dominio son `RefCounted`/`Resource` y no dependen de escenas, input, sprites ni animación.
2. Los `Node` se reservan para mundo, composición y UI. Overworld y Battle Presentation son Nodes porque esa es precisamente su responsabilidad.
3. No hay autoloads como mecanismo de autoridad global; las dependencias se construyen e inyectan explícitamente.
4. Los datos estáticos usan IDs estables; saves/snapshots no dependen de rutas visuales ni Resource UIDs.
5. Todo RNG de gameplay relevante se inyecta o vive en estado serializable del sistema correspondiente. La UI no inventa seeds ocultas de producción.
6. Presentación construye intenciones y representa resultados; no reimplementa reglas de Battle/Capture/Run/Progression.
7. Una entrada inválida debe rechazarse antes de efectos laterales siempre que el contrato lo permita: sin turno gratis, consumo parcial, RNG innecesario ni publicación de estado incompleto.
8. Cualquier frontera futura de networking debe mover estrategia/RNG/estado sensible a autoridad server-side; el runtime local actual no se vende como seguridad de red.

## Datos y catálogos

La fuente masiva se transforma fuera del runtime en un dataset normalizado versionado. El juego consume `data/normalized/pokemon_api.json`; no ejecuta el importador PokéAPI durante el arranque normal.

`GameData` expone catálogos enfocados (`SpeciesCatalog`, `MoveCatalog`, `TypeCatalog`, `AbilityCatalog`, `ItemCatalog`, `StatusCatalog`) y `DefinitionCatalog` actúa como fachada para los subsistemas que necesitan resolver IDs.

Las definiciones (`CreatureSpecies`, moves, tipos, abilities, items...) son datos estáticos. `CreatureInstance` es estado vivo persistente con `instance_id`, nivel/XP, IV/EV, naturaleza, HP/status, ability, held item y moveset/PP.

## Battle Core

Battle usa `BattleRuleset(calvo_v1)` y un pipeline determinista de turnos. El núcleo modela:

- parties y combatiente activo;
- MOVE y SWITCH;
- PP;
- priority/speed;
- physical/special damage;
- STAB/type effectiveness;
- accuracy/evasion;
- stat stages;
- críticos;
- status persistentes/volátiles soportados;
- effects/triggers estructurados;
- abilities/held items explícitamente soportados;
- eventos semánticos;
- snapshot con RNG/estado suficiente para continuación determinista del core.

`AuthoritativeBattleServer` valida intenciones antes de ejecutar `TurnExecutor`. El Battle Core genérico no conoce CAPTURE ni RUN: esas acciones pertenecen al lifecycle de un encuentro salvaje.

## Wild battle application boundary

`WildAdventureSession` compone los dominios existentes sin absorber sus reglas.

Es responsable de:

- comenzar un encounter y construir Battle con las mismas `CreatureInstance` persistentes;
- exponer la Battle viva;
- aceptar `WildBattleCommand`;
- enrutar ACTION a Battle Core;
- construir contexto confiable de CAPTURE desde estado vivo;
- aplicar RUN mediante `WildEscapeRuleset`;
- settlement de victoria/derrota;
- reconciliación de progresión;
- routing de ownership a Party/Storage;
- bloquear save mid-battle cuando el schema no puede representar la Battle activa;
- restaurar el agregado del jugador tras Load;
- lifecycle `READY -> BATTLE_ACTIVE -> COMPLETED -> READY`.

### Commands

`WildBattleCommand` diferencia:

- `ACTION`: envuelve `BattleAction` para MOVE/SWITCH;
- `CAPTURE`: intención de usar una ball;
- `RUN`: intención de huida del encuentro salvaje.

Una captura fallida obtiene exactamente una reacción rival a través del mismo pipeline de Battle. Una captura exitosa termina `CAPTURED` sin represalia.

RUN usa `calvo_escape_v1`. Si falla, ejecuta una reacción rival por el pipeline existente; si tiene éxito, termina `FLED`. Battle Core no contiene un `BattleAction.RUN` artificial.

## Progression

`ProgressionSystem` consume `BattleOutcome` después del combate y puede emitir eventos semánticos de XP, level-up, stats, aprendizaje y evolución.

`EvolutionSystem` y `LearnsetSystem` permanecen fuera de Battle. La identidad de la criatura se conserva cuando una evolución requiere sustituir el objeto; `PlayerCollection.replace_owned_same_identity()` actualiza el contenedor propietario sin cambiar `instance_id` ni posición lógica.

### Frontera todavía abierta

El dominio ya emite `MOVE_LEARN_CHOICE_REQUIRED` y `EVOLUTION_AVAILABLE`, pero el baseline no conserva todavía una cola de decisiones de progresión en la capa de aplicación. La presentación de Battle no debe resolver esta carencia manipulando moves/species directamente. El próximo contrato recomendado es una cola/estado explícito de decisiones post-battle y después su presentación.

## Capture, Party, Storage e Inventory

Capture es determinista y consume un contexto construido a partir de la Battle salvaje real. En éxito conserva la misma `CreatureInstance`; no rerollean IV/naturaleza/ability/moveset.

Party tiene máximo 6. Storage usa cajas ordenadas de 30 slots y cajas dinámicas. `PlayerCollection` agrega Party + Storage + Inventory y ofrece operaciones de transferencia con rollback.

El `instance_id` es la identidad persistente canónica. Save y validadores rechazan double ownership/corrupción en lugar de normalizarla silenciosamente.

## Savegame

Savegame actual: schema 2 / `calvo_save_v2`.

Características:

- registro canónico de criaturas serializado una vez;
- layouts Party/Storage por referencias de ID;
- Inventory persistente;
- carga all-or-nothing;
- rechazo defensivo de tipos/payloads inválidos;
- reemplazo de fichero con protección del último save bueno;
- migración histórica V1 -> V2 en memoria, sin inventar inventario que V1 nunca almacenó;
- save durante Battle activa bloqueado porque V2 no afirma poder reanudar estado transitorio de combate.

Las decisiones post-battle pendientes aún no tienen schema/lifecycle propio; ese punto debe definirse antes de permitir que una futura UI las pueda abandonar silenciosamente.

## Wild Encounters y Overworld

`WildEncounterSystem` decide, de forma determinista, si ocurre encounter, especie y nivel a partir de una tabla validada y RNG inyectado. No conoce mapas ni pasos.

`OverworldEncounterDirector` traduce pasos/zonas al sistema de encounters. `OverworldPlayer` usa movimiento físico y cuenta pasos por distancia realmente recorrida, incluidas posiciones intermedias cuando un frame cruza varios boundaries.

La escena técnica consume dataset normalizado y congela movimiento mientras una Battle está activa/completada hasta confirmación explícita.

## Battle Presentation

`BattlePresentationController` representa la `WildAdventureSession` real:

- HP/turno/moves/PP;
- log de `BattleEvent`;
- MOVE;
- CAPTURE con balls poseídas;
- SWITCH electivo;
- RUN;
- resultado y confirmación de retorno.

La presentación deriva sides/targets del estado autoritativo, conserva `instance_id` en selectores y no calcula catch probability ni escape odds.

El reemplazo forzado tras KO sigue siendo automático en Battle Core. Convertirlo en elección manual requerirá un estado/contrato de Battle explícito antes de tocar UI.

## Determinismo

La regla general es que mismo estado + mismas intenciones + mismo stream RNG produce el mismo resultado observable dentro del contrato de cada subsistema.

Los tests verifican, entre otros, continuidad de Battle snapshot, selección de encounters, Capture, RUN y separación de RNGs. Capture RNG y Escape RNG son dependencias distintas; un comando RUN no debe consumir RNG/inventario de Capture.

## Cobertura de mecánicas

El dataset contiene mucho más contenido que el runtime ejecutable. La existencia de `effect_summary` o de una definición importada nunca implica soporte de gameplay.

Promover un move/ability/item exige datos estructurados, handler/mapping explícito y tests. Ver:

- `MECHANICS_COVERAGE.md`;
- `MOVE_EFFECT_COVERAGE.md`;
- `EVOLUTION_COVERAGE.md`.

## Testing y CI

La regresión histórica conserva **470 PASS / 0 FAIL**. Las fases recientes usan suites dedicadas adicionales con gates propios, actualmente hasta Battle RUN Presentation **94 PASS / 0 FAIL**.

GitHub Actions usa Godot `4.7.stable.official.5b4e0cb0f`, importa headless, ejecuta la regresión y cada suite dedicada, y publica logs como artifact. Los gates usan mínimos cuando fases futuras pueden añadir checks.

Un primer CI verde no cierra por sí solo un bloque: se exige auditoría adicional, documentación del HEAD final y repetición del workflow cuando cambia el cierre.

## Source of truth

- estado agregado: `STATUS.md`;
- planificación: `ROADMAP.md`;
- decisiones: `ARCHITECTURE_DECISION_*.md`;
- evidencia por fase: `INFORME_FINAL_FASE*.md`;
- comportamiento ejecutable: código + tests + workflow del HEAD exacto.

Si documentación y runtime discrepan, se debe auditar y corregir la documentación o el código; no se rellena la diferencia por suposición.