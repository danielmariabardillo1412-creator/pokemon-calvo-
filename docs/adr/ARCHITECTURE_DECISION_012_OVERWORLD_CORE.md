# ADR-012 — Overworld Core V1

Fecha: 2026-08-29  
Rama: `feature/overworld-core-v1`  
Base: `feature/vertical-slice-core-v1`  
Estado: **ACCEPTED / VALIDATED**

## Contexto

FASE 11 dejó validado el ciclo lógico completo de una aventura salvaje, pero todavía no existía una superficie de juego visible que produjera encuentros desde movimiento físico real. El siguiente límite debía conectar Godot 2D con `WildAdventureSession` sin trasladar reglas de Battle, Capture, Progression o Save al árbol de escenas.

## Decisión

El Overworld V1 se divide en tres responsabilidades explícitas:

1. **Movimiento físico (`OverworldPlayer`)**
   - `CharacterBody2D` con cuatro direcciones cardinales.
   - `move_and_collide` decide el desplazamiento realmente ejecutado.
   - la cadencia de pasos se calcula con distancia real recorrida, no con input ni tiempo;
   - si un frame cruza varios límites de paso, cada evento conserva la posición intermedia real de ese límite.

2. **Superficie de encuentro (`OverworldEncounterZone`)**
   - cada zona usa un `zone_id` estable;
   - V1 admite `RectangleShape2D` deliberadamente;
   - la escena pregunta qué zona contiene la posición de cada paso completado.

3. **Orquestación (`OverworldEncounterDirector`)**
   - registra `WildEncounterTable` validadas por `zone_id`;
   - una posición sin zona o una zona desconocida no consume RNG;
   - solo pide un encounter cuando `WildAdventureSession` está `READY`;
   - delega al sistema de encounters y a la vertical slice existente;
   - `battle_started=true` solo si existe una Battle lógica real activa.

El Overworld no calcula probabilidades, no crea Pokémon por su cuenta, no resuelve turnos, no captura, no concede XP y no guarda criaturas.

## Runtime data

La escena técnica consume el dataset canónico ya normalizado:

`res://data/normalized/pokemon_api.json`

mediante `GameData.from_dict()`.

La importación/normalización (`DataImporter`, adapters, raw PokeAPI) sigue siendo responsabilidad de build/QA. No se reconstruye el dataset masivo al arrancar la escena jugable.

Esta elección es adecuada para V1 técnico. El JSON normalizado (~15.8 MB en el repositorio actual) no se declara como formato final de shipping; una fase posterior puede empaquetarlo/optimizarlo sin cambiar los contratos de Overworld.

## Escena técnica

`res://scenes/overworld/technical_overworld.tscn` es la `main_scene` de esta fase.

Es intencionadamente asset-free y contiene:

- jugador físico;
- obstáculo con colisión;
- límites básicos;
- zona visual de encuentro;
- label de estado.

La tabla técnica usa un encuentro garantizado con Pikachu Lv.4 únicamente para que el handoff pueda probarse de forma determinista. No es balance de juego definitivo.

Al arrancar Battle, el movimiento del jugador se congela. FASE 12 demuestra el handoff `Overworld -> Battle`; todavía no presenta ni permite jugar visualmente el combate.

## Invariantes

- chocar contra una pared no genera pasos falsos;
- la frecuencia de encuentros no depende de FPS;
- un frame grande no pierde la posición de los pasos intermedios;
- fuera de zona no se consume RNG de encounter;
- no puede iniciarse un segundo encounter mientras la sesión no esté `READY`;
- un encounter marcado como iniciado corresponde a una Battle real de `WildAdventureSession`;
- el runtime no depende del pipeline de importación raw;
- los assets Pokémon/romanos masivos no son dependencia del Core ni de CI.

## Consecuencias

### Positivas

- primera escena ejecutable que conecta input/collision de Godot con los sistemas Pokémon ya validados;
- mapas finales pueden sustituir la escena técnica sin rediseñar Battle/Capture/Progression;
- zonas pueden generarse más adelante desde TileMap o datos manteniendo el contrato por `zone_id`;
- CI puede probar movimiento, colisiones y handoff sin sprites ni librerías gráficas pesadas.

### Límites aceptados

- solo cuatro direcciones;
- `RectangleShape2D` para encounter zones;
- no hay NPCs, puertas, transitions, cámara avanzada ni world-state persistente;
- no hay Battle UI ni assets finales;
- el dataset normalizado JSON es suficiente para V1, no una decisión irreversible de distribución final.

## Evidencia

CI final de código de FASE 12:

- historical regression: **470 PASS / 0 FAIL**
- Inventory: **47 PASS / 0 FAIL**
- Savegame V2: **40 PASS / 0 FAIL**
- Savegame V2 adversarial: **8 PASS / 0 FAIL**
- Wild Encounters: **54 PASS / 0 FAIL**
- Logical Vertical Slice: **62 PASS / 0 FAIL**
- Overworld: **59 PASS / 0 FAIL**
- Godot: `4.7.stable.official.5b4e0cb0f`
- import headless: PASS
- workflow: SUCCESS

Los dos defectos encontrados durante la auditoría previa al cierre —posición de pasos múltiples en frames grandes y ejecución del importador raw al arrancar runtime— fueron corregidos antes de aceptar esta decisión.
