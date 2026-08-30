# INFORME FINAL — FASE 12: Overworld Core V1

Fecha: 2026-08-29  
Rama: `feature/overworld-core-v1`  
Base: `feature/vertical-slice-core-v1`  
PR: #6  
Motor CI: `4.7.stable.official.5b4e0cb0f`

## Estado

**FASE_12_STATUS = CLOSED / VALIDATED**

## Qué demuestra esta fase

El proyecto ya tiene una primera escena física e interactiva de Godot que conecta:

`input -> movimiento -> colisión -> distancia real -> step -> encounter zone -> WildEncounterSystem -> WildAdventureSession -> Battle real`

No es todavía el mapa romano final ni una demo visual completa de combate. Es el primer Overworld técnico que utiliza los sistemas persistentes y de batalla construidos en fases anteriores sin duplicarlos.

## Runtime añadido

### `OverworldPlayer`

- `CharacterBody2D`.
- cuatro direcciones cardinales usando acciones `ui_*` de Godot;
- `move_and_collide` para movimiento y colisiones físicas;
- señal `step_completed(world_position)` basada en distancia realmente recorrida;
- caminar contra una pared no incrementa el contador de pasos;
- movimiento deshabilitable al entrar en Battle.

La auditoría detectó que el primer diseño emitía todos los pasos cruzados por un frame grande en la posición final. Se corrigió: ahora cada boundary conserva su posición intermedia sobre el segmento realmente recorrido, haciendo la detección de zonas independiente del framerate.

### `OverworldEncounterZone`

- `Area2D` con `zone_id` estable;
- V1 valida `RectangleShape2D`;
- consulta geométrica explícita de si un paso pertenece a la zona.

### `OverworldEncounterDirector`

- registra tablas de encounter validadas;
- traduce `step + zone_id` al `WildAdventureSession` existente;
- no consume RNG en suelo normal, zona desconocida o sesión ocupada;
- no inicia un segundo encounter mientras existe Battle/completion pendiente;
- solo informa `battle_started=true` si la Battle existe de verdad.

### Escena técnica

`res://scenes/overworld/technical_overworld.tscn` es la `main_scene` de FASE 12.

Contiene únicamente geometría técnica:

- jugador;
- obstáculo físico;
- bordes;
- grass/encounter zone;
- texto de estado.

La zona técnica fuerza Pikachu Lv.4 para que el handoff sea determinista. Al entrar en Battle, el jugador se congela y el label informa `BATTLE ACTIVE`. La presentación de Battle queda fuera de esta fase.

## Datos runtime

La escena carga `res://data/normalized/pokemon_api.json` con `GameData.from_dict()`.

Durante auditoría se eliminó una primera versión que ejecutaba `DataImporter` contra el raw dataset en cada arranque. El pipeline de importación queda donde corresponde: build/QA. Runtime consume el resultado canónico ya normalizado.

El repositorio no necesita ni incorpora la librería gráfica local masiva de Pokémon/arte; la escena técnica y sus tests son asset-free.

## Cobertura Overworld

La suite dedicada valida, entre otros:

- registro/rechazo de encounter zones;
- stable `zone_id`;
- no RNG fuera de zona o en zona desconocida;
- encuentro garantizado -> Battle real;
- misma `CreatureInstance` del encounter dentro de Battle;
- bloqueo de segundo encounter durante Battle;
- semantic NONE para chance 0;
- party sin criatura viva rechazada sin consumir RNG;
- lifecycle `COMPLETED -> READY` explícito;
- cardinalización sin diagonales;
- geometría de encounter zone;
- movimiento físico;
- emisión de pasos por distancia;
- colisión contra obstáculo;
- movimiento deshabilitado;
- carga/instanciación de escena técnica;
- main scene correcta;
- step dentro de grass -> Battle activa;
- freeze de Overworld al entrar en Battle;
- frame grande -> 3 pasos con posiciones exactas 16/32/48;
- runtime usa normalized dataset;
- runtime no ejecuta `DataImporter` ni lee raw dataset;
- manifest normalizado válido y especies técnicas disponibles.

## Gates finales de código

- Historical regression: **470 PASS / 0 FAIL**
- Inventory: **47 PASS / 0 FAIL**
- Savegame V2: **40 PASS / 0 FAIL**
- Savegame V2 adversarial: **8 PASS / 0 FAIL**
- Wild Encounters: **54 PASS / 0 FAIL**
- Logical Vertical Slice: **62 PASS / 0 FAIL**
- Overworld: **59 PASS / 0 FAIL**
- Import headless: **PASS**
- Godot exacto: `4.7.stable.official.5b4e0cb0f`
- Workflow: **SUCCESS**
- Merge a `main`: **NO**

La salida de error del test histórico de JSON corrupto sigue siendo deliberada y termina en PASS. Los avisos Node.js de `actions/checkout@v4` / `actions/upload-artifact@v4` son warnings del runner, no fallos del producto.

## Auditoría previa al cierre

Se encontraron y corrigieron dos problemas antes de cerrar:

1. **Frame-rate correctness:** múltiples pasos en una sola llamada de movimiento utilizaban la misma posición final. Corregido con posiciones intermedias sobre el desplazamiento real.
2. **Runtime/build boundary:** la escena reconstruía los datos mediante `DataImporter` al arrancar. Corregido para consumir `data/normalized/pokemon_api.json` directamente.

Ambas correcciones tienen regresiones dedicadas y el workflow completo volvió a verde.

## Fuera de alcance

- mapa final de Roma;
- sprites/tilesets Pokémon o romanos finales;
- NPCs, diálogos, puertas y transiciones entre mapas;
- Battle UI/presentation y controles visuales de combate;
- audio;
- persistencia de posición/world-state;
- multiplayer/networking;
- optimización del formato de datos para un build final.

## Próximo bloque

No existe todavía una FASE 13 oficial documentada en el repositorio. El siguiente bloque debe definirse antes de abrir rama.

La continuación técnica más natural es **Battle Presentation / transición visual Overworld <-> Battle**, porque FASE 12 ya inicia una Battle real pero deliberadamente se detiene en un label técnico. Esa propuesta no se considera aprobada ni iniciada por este informe.
