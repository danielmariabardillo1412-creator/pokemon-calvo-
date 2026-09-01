# DATA FOUNDATION V3 — PokéAPI snapshot canonical import

**Estado:** VALIDADA.  
**Rama canónica:** `feature/data-foundation-v3`  
**PR de validación:** #32, cerrar sin merge únicamente si el HEAD documental vuelve a quedar 18/18 verde.  
**HEAD técnico previo a este documento:** `5afdc8b3adfd093f8ab0ca67b9900f44b793e546` — 18/18 workflows normales SUCCESS, incluida la regresión global de Godot 4.7.

> Este documento no almacena su propio SHA final para evitar una referencia circular. El criterio de cierre es que el commit que contiene este documento pase los 18 workflows normales sin cambios posteriores.

## Motivo

El adaptador PokéAPI anterior a V3 simplificaba información que es esencial para un juego Pokémon coherente. Los síntomas visibles fueron learnsets absurdos/repetidos (casos Gengar/Pinsir), especies legítimas descartadas por contener guiones y datos históricos/versionados mezclados como si pertenecieran a un único juego.

V3 sustituye esa interpretación por un pipeline reproducible y auditable basado en el snapshot completo incluido en el repositorio. Los JSON fuente no se corrigen a mano.

## Fuente inmutable

La fuente canónica queda versionada bajo:

- `data/api/v2`
- `data/schema/v2`
- licencia del snapshot PokéAPI

Provenance fijada:

- source commit: `2f218ec3765c01c894a42bbbd074f15ddf3f32d1`
- API tree: `8349ea1ce75716897fe96e02a15950d19edba6c3`
- schema tree: `02e031e1928d7e9456bf6f7486daacc4b8946c84`
- licencia: BSD 3-Clause

Regla: el snapshot es **solo lectura**. Toda adaptación ocurre en `tools/pokeapi_adapter_v3.py` y después en el `DataImporter` autoritativo de Godot.

## Pipeline V3

```text
data/api/v2 + data/schema/v2
        |
        v
 tools/pokeapi_adapter_v3.py
        |
        +--> data/raw/pokemon_api.json
        +--> data/manifests/pokemon_api_manifest.json
        +--> reports de cobertura/auditoría
        |
        v
 DataImporter (Godot)
        |
        v
 data/normalized/pokemon_api.json
        |
        v
 GameData / DefinitionCatalog / runtime
```

El adaptador usa rutas relativas al repositorio. Se elimina la dependencia anterior de una ruta local `F:\...`.

## Política de learnsets

V3 **no suma todos los learnsets de todas las generaciones**.

Para cada Pokémon base se selecciona un único `version_group` convencional/mainline coherente según `latest_conventional_mainline_per_species_v1`. Cada entrada conserva:

- `move_id`
- `method`
- `level`
- `order`
- `version_group`

Esto permite auditar la procedencia y evita que un Pokémon herede simultáneamente movimientos/niveles de múltiples juegos.

Casos de control:

- Gengar: `scarlet-violet`, 81 entradas totales, 17 por level-up, un único version-group.
- Pinsir: `brilliant-diamond-shining-pearl`, 56 entradas totales, 15 por level-up, un único version-group.

Los tests de progresión ya no fijan niveles históricos arbitrarios (por ejemplo, “Látigo Cepa siempre al nivel 13”); derivan el nivel del learnset canónico seleccionado y prueban la mecánica contra ese dato.

## Especies y formas

Se elimina la regla errónea `nombre con guion = forma alternativa`.

La clasificación usa los datos estructurados de PokéAPI (`pokemon-species.varieties[].is_default`). Por ello especies base legítimas como Mr. Mime, Ho-Oh y Porygon-Z no desaparecen por su nombre.

Las variantes/formas se contabilizan separadamente y no se inyectan silenciosamente en el catálogo base.

## Evoluciones

`EvolutionRecord` conserva ahora provenance y condiciones que el adaptador antiguo descartaba, incluido `version_group` y las condiciones estructuradas disponibles en la fuente.

Preservar el dato no implica que todas esas mecánicas estén ya ejecutadas por el runtime. `EvolutionSystem` sigue clasificando explícitamente qué condiciones son soportadas y cuáles permanecen pendientes; no se inventa una evolución simplificada para hacerla pasar.

## Habilidades

La ingesta conserva la metadata de slots de habilidad, incluyendo `is_hidden` y `slot`, además de la lista compatible usada por el dominio actual.

La información se conserva para futuras decisiones de generación de Pokémon/entrenadores sin convertir una habilidad oculta en una habilidad normal por pérdida de metadata.

## Tipos y movimientos laterales

El runtime utiliza exactamente los 18 tipos estándar de combate definidos por el proyecto.

El snapshot contiene 18 movimientos Shadow de Pokémon XD con tipo `shadow`. V3 los conserva en la fuente original pero los clasifica como `EXCLUDED_NON_STANDARD_TYPE` y **no** los importa al catálogo runtime. No se renombran ni se convierten fraudulentamente a otro tipo.

## Localización

Siempre que PokéAPI proporciona `names` por idioma, V3 puede conservar/usar el nombre español oficial para presentación. Los IDs internos permanecen estables y normalizados para no romper persistencia, referencias o replays.

## Dataset canónico certificado

Importación V3 limpia:

| Entidad | Total |
|---|---:|
| Especies base | 1025 |
| Formas detectadas | 326 |
| Tipos runtime | 18 |
| Movimientos runtime | 919 |
| Habilidades | 373 |
| Objetos | 2222 |
| Entradas de learnset | 61,102 |
| Evoluciones preservadas | 554 |
| Referencias rotas | 0 |
| Definiciones rechazadas | 0 |

Los 18 movimientos Shadow excluidos no forman parte de los 919 movimientos runtime.

## Migración de regresiones históricas

Al persistir V3, la suite global detectó 18 expectativas ligadas al dataset antiguo. No se modificó el dataset correcto para satisfacerlas.

Se migraron las pruebas para verificar invariantes V3:

- source/ruleset/provenance correctos;
- catálogos reales, no conteos V2;
- formas por metadata estructurada, no por guiones;
- movimientos laterales excluidos explícitamente;
- evolución preservada frente a catálogo real;
- niveles de aprendizaje derivados del learnset seleccionado.

El smoke test de la migración quedó en **472 PASS / 0 FAIL** antes de persistir los cambios.

Los workflows y scripts temporales usados exclusivamente para la migración/persistencia fueron eliminados antes de la certificación del HEAD técnico limpio.

## Gates de aceptación

En `5afdc8b3adfd093f8ab0ca67b9900f44b793e546` pasaron los **18/18 workflows normales**:

1. Data Foundation V3
2. Godot 4.7 global
3. Spanish Types Foundation
4. Trainer Battle Session
5. Trainer Intelligence Foundation
6. Trainer Tactical Intelligence
7. Trainer Belief Inference
8. Trainer Search Foundation
9. Trainer Search Depth Budget
10. Trainer Self Play Evaluation
11. Trainer Evaluation Corpus
12. Trainer Search Limit Benchmark
13. Trainer Adaptive Branching
14. Trainer Public Coverage Beliefs
15. Trainer Item Actions
16. Trainer Strategic Switching V2
17. Trainer Loadouts
18. Trainer Team Composition

El cierre de PR #32 exige repetir este mismo conjunto sobre el HEAD que contiene este documento.

## Límites conscientes

- `latest_conventional_mainline_per_species_v1` es una política de coherencia por especie, no un ruleset global que pretenda reproducir una generación única completa.
- Conservar datos de habilidades, objetos y evoluciones no significa que todas sus mecánicas estén implementadas todavía.
- Los datos fuente permanecen separados de los datos `raw`/`normalized` consumidos por el juego.
- No se modifica Battle Core para “acomodar” datos inválidos; los límites del runtime deben seguir siendo explícitos.

## Siguiente trabajo

Tras cerrar DATA FOUNDATION V3:

1. hacer una fase separada de organización/limpieza del repositorio;
2. identificar documentos, scripts, ramas de trabajo y archivos generados obsoletos sin borrar baselines canónicos ni provenance;
3. consolidar documentación de datos antigua que haya quedado superada por V3;
4. volver después a FASE 34 — Trainer Archetypes / Difficulty Tiers sobre la nueva base de datos certificada.
