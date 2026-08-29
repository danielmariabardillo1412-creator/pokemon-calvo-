# Architecture — Foundation V1

## Forma general

La arquitectura es **feature-first con límites hexagonales selectivos**. El dominio
se agrupa por capacidad (`creatures`, `battle`, `status`, `data`), no en carpetas
globales de managers. Las capas internas solo aparecen donde existe una frontera
real: intención de cliente, aplicación autoritativa, estado/reglas y presentación.

```text
Client/UI --BattleAction--> AuthoritativeBattleServer
                              | validates
                              v
                 BattleState + TurnExecutor + RNG
                    |       |       |
                    |       |       +--> StatusSystem
                    |       +----------> DefinitionCatalog --> Resources
                    v
                 BattleEvent[] --> Presentation
```

La dirección de la autoridad es unidireccional. `BattleClient` solo construye una
intención. `AuthoritativeBattleServer` valida turno, actor, movimiento y objetivo.
Solo el servidor ejecuta reglas y muta HP. La presentación recibe copias
serializables de hechos y no recibe `BattleState`.

## Reglas de dependencia

1. Las reglas y el estado mutable son `RefCounted`; nunca acceden a `SceneTree`,
   `NodePath`, señales globales, sprites, animación o input.
2. Los datos estáticos editor-friendly son `Resource` y se tratan como inmutables
   después de cargarlos. El estado guarda sus IDs explícitos, no referencias a
   Resources ni UIDs de Godot.
3. Los `Node` quedan para composición, mundo y UI. En V1 solo el runner de tests es
   un Node porque necesita iniciar y cerrar el árbol.
4. No hay autoloads. Una dependencia se construye y se pasa explícitamente.
5. Un módulo no debe depender de presentación. `battle/application` puede
   orquestar `status/application`; el módulo de status no modifica el resolver.
6. Todo origen de no determinismo debe pasar por `SeededRandomSource`.

Estas reglas deberían convertirse en comprobaciones automáticas de arquitectura
cuando crezca el equipo (por ejemplo, prohibir `extends Node` y APIs visuales bajo
`domain/` y `application/`).

## Modelo de objetos

- `CreatureSpecies`, `MoveDefinition`, `TypeDefinition` y `StatusDefinition` son
  `Resource`: configuración estática, versionable y cómoda para herramientas.
- `CreatureInstance`, `StatBlock`, `BattleState`, `BattleAction`, `BattleEvent`,
  resolvers, calculadores y sistemas son `RefCounted`: estado o lógica instanciable
  y ejecutable sin escena visual.
- Los futuros controladores de escena, HUD, personajes y animaciones serán `Node`.
  Ninguno será dueño de la verdad de combate.

`CreatureInstance` es deliberadamente `RefCounted`, no `Resource`: HP, estados y
movimientos son estado vivo por instancia. Compartir accidentalmente un Resource
mutable entre combates sería peligroso. Las especies sí son definiciones Resource.

## Datos masivos e IDs

Los IDs son cadenas estables en minúsculas (`embercub`, `poison`, `quick_strike`).
Son la identidad de red/save; una ruta, nombre visible o Resource UID nunca lo es.
Un ID publicado no se reutiliza. Renombrarlo exige una migración explícita.

Los `.tres` de V1 demuestran el contrato, no son la estrategia definitiva para más
de 1000 especies. El contrato de datos canónico ya está implementado en
`feature/data-pipeline-v1` (ver `docs/DATA_ARCHITECTURE.md` y `docs/ARCHITECTURE_DECISION_002_DATA_PIPELINE.md`):
fuente JSON + `DatasetManifest` versionado + `DataImporter` que valida y rechaza
lo inválido, catálogos enfocados (`SpeciesCatalog`, `MoveCatalog`, `TypeCatalog`,
`AbilityCatalog`, `ItemCatalog`, `StatusCatalog`) y `DefinitionCatalog` como fachada
de batalla. El dominio solo consume `DefinitionCatalog`, por lo que el formato de
autoría (JSON/CSV/SQL) no contamina las reglas. Para volumen real basta añadir un
adaptador que produzca el mismo `Dictionary` de entrada del importador.

## Determinismo y serialización

`SeededRandomSource` usa `lcg32_v1`, es inyectable, reproducible y no criptográfico.
Daño y modificadores usan basis points para reducir diferencias de redondeo. Un
snapshot incluye `schema_version`, `ruleset_id`, `rng_algorithm`, estado del RNG,
turno, fase, ganador, participantes, estadísticas, HP, movimientos y estados.

Esto permite continuar una simulación, replay o reconciliación, siempre que el
servidor use el mismo ruleset y catálogo. El snapshot es un `Dictionary` apto para
JSON y no contiene objetos visuales. Aun así, V1 es independiente de `SceneTree`,
no del runtime de Godot/GDScript; un servidor escrito en otro lenguaje tendría que
implementar los mismos contratos y reglas.

## Status y ECS

Poison se procesa en un `StatusSystem` pequeño y sin estado. Este patrón aísla las
reglas transversales sin adoptar un runtime ECS. No hay ECS en batalla ni overworld.
Para el overworld solo se reconsiderará después de medir una necesidad real (muchas
entidades homogéneas o coste de actualización); Godot Nodes y composición siguen
siendo el punto de partida.

## Battle Core V2

Battle usa ahora `BattleRuleset(calvo_v1)`, un pipeline de phases estable y specs
componibles. `BattleState` schema 2 modela parties/active, PP, stages, status,
ability e item runtime. `DefinitionCatalog` expone también abilities/items, pero la
lógica solo usa mappings/specs estructurados por stable ID; nunca `effect_summary`.

La arquitectura mantiene 0 autoloads y 0 Nodes fuera de tests. Detalle y reglas:
`BATTLE_ARCHITECTURE.md`, `BATTLE_EFFECTS.md` y `BATTLE_RULESET_CALVO_V1.md`.

## Progression Core (FASE 6)

`CreatureSpecies` (inmutable) vs `CreatureInstance` (mutable, identidad `instance_id`) vs lógica en
`modules/creatures/progression/*`. El Battle emite `BattleOutcome`; la Progresión lo consume después
(`ProgressionSystem.reconcile_battle_result`). 0 autoloads, 0 Nodes fuera de tests, mismo contrato de
separación que Battle Core. Detalle y reglas: `PROGRESSION_ARCHITECTURE.md`, `PROGRESSION_RULESET_CALVO_V1.md`,
`EVOLUTION_COVERAGE.md` y `ARCHITECTURE_DECISION_005_PROGRESSION.md`.

## Capture + Party Core (FASE 7)

`modules/capture/*` (resolución determinista de captura, 100% pura: sin UI/Nodes/autoload) y
`modules/creatures/party/*` (roster persistente, máx 6, identidad por `instance_id`). La captura es
una preocupación *post-batalla*: el Battle Core muta la `CreatureInstance` viva (HP/status/PP) y
luego `CaptureSystem.resolve` la lee; el `BattleOutcome` NO se extiende con captura. La clienta solo
envía `ball_id` + `target_id`; el target real y el `CaptureBattleContext` se resuelven en servidor, así
el resultado no se forja. En éxito, `res.captured` es la MISMA `CreatureInstance` (IV/EV/naturaleza/
ability/moveset/PP preservados). Party llena ⇒ `STORAGE_REQUIRED` (sin auto-reemplazo; Storage es FASE 8).
Detalle y reglas: `CAPTURE_ARCHITECTURE.md`, `CAPTURE_RULESET_CALVO_V1.md`, `PARTY_ARCHITECTURE.md`,
`CAPTURE_DATA_AUDIT.md` y `ARCHITECTURE_DECISION_006_CAPTURE_PARTY.md`.

## Tests

El runner ligero actual evita incorporar un addon para 13 pruebas fundacionales y
corre como escena headless. GUT será razonable cuando hagan falten fixtures,
parametrización, dobles complejos o integración CI más rica. Cambiar el framework no
debe cambiar el dominio. Battle Core V2 añade una suite separada de unidades y
escenarios golden; Progression Core (FASE 6) añade `ProgressionTestSuite`; Capture + Party Core
(FASE 7) añade `CapturePartyTestSuite`. El total actual es **286 PASS / 0 FAIL**.
