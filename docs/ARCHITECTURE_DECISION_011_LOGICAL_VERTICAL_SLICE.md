# ADR-011 — Logical Vertical Slice V1

Estado: ACEPTADO / VALIDADO EN CI  
Fecha: 2026-08-29  
Rama: `feature/vertical-slice-core-v1`

## Contexto

Tras FASE 10 existían por separado Encounter, Battle, Progression, Capture, Party, Storage, Inventory y Savegame V2. El siguiente riesgo ya no era la ausencia de subsistemas, sino que sus fronteras no formasen un ciclo coherente cuando se conectaran de verdad.

La meta de FASE 11 es demostrar el flujo lógico completo antes de construir Overworld/UI:

`Encounter → Battle → Capture/Victory → Progression/Evolution → Ownership → Save → Load → Continue`

## Decisión

### 1. Capa de aplicación, no nuevo dominio

Se introduce `WildAdventureSession` como orquestador headless. No reimplementa reglas de captura, batalla, XP, evolución, almacenamiento ni guardado. Compone las APIs existentes y construye contextos de confianza desde el estado que ya posee.

No es `Node`, autoload, UI ni singleton.

### 2. Encounter y Battle comparten las mismas instancias

El encounter crea el `CreatureInstance` salvaje mediante `CreatureFactory`. Esa misma referencia entra en `BattleState` y, si se captura, esa misma identidad termina en Party/Storage.

La Party del jugador aporta también las mismas instancias persistentes al Battle Core. HP, PP y status mutados durante combate son por tanto estado real que luego cruza la frontera post-battle.

### 3. La sesión construye el contexto de captura

El caller de UI futuro solicita `ball_id`; no aporta hechos como `is_wild`, ownership o resultado. `WildAdventureSession` construye `CaptureBattleContext` a partir de su batalla salvaje activa y delega en `CaptureInventoryService` + `CaptureOwnershipRouter`.

Captura fallida mantiene la batalla activa. Captura exitosa solo completa el ciclo si la criatura queda realmente en Party o Storage.

### 4. BattleOutcome es la única frontera hacia Progression

La victoria se resuelve por `AuthoritativeBattleServer`. Solo cuando `BattleState.phase == FINISHED` se construye `BattleOutcome` y se entrega a `ProgressionSystem.reconcile_battle_result`.

La derrota no concede XP.

### 5. Reconciliación post-battle real

Al conectar los sistemas se detectó que `CreatureInstance.reconcile_post_battle()` eliminaba estados volátiles pero no reiniciaba stat stages. Eso podía persistir, por ejemplo, un `+4 Attack` fuera de combate y dentro de un save.

Se corrige la frontera para reiniciar `StatStages` además de limpiar volátiles y clamp de HP/PP. Los status persistentes continúan conservándose.

### 6. Evolución y ownership por stable identity

`EvolutionSystem` devuelve deliberadamente un objeto nuevo con el mismo `instance_id`. Hasta esta fase Party/Storage no tenían una operación explícita para reemplazar el objeto detrás de esa identidad.

Se añaden operaciones `replace_same_identity` en Party y Storage, y `PlayerCollection.replace_owned_same_identity`. El reemplazo:

- conserva el orden exacto de Party;
- conserva box/slot exactos en Storage;
- rechaza ownership ausente o doble;
- nunca cambia el `instance_id`.

Además se corrige `EvolutionSystem.apply_evolution` para preservar el índice paralelo `move_ids`, held item y status IDs. Antes se copiaban los `BattleMoveSlot` pero `move_ids` podía quedar vacío.

### 7. Eventos de evolución no son autoridad suficiente

`apply_evolution_event` no acepta ciegamente un `species_id` contenido en un evento. Vuelve a comprobar que el target está entre los candidatos de evolución actualmente elegibles de la especie/level reales.

Esto evita que un evento fabricado convierta un Pokémon en una especie arbitraria y prepara una frontera útil para multiplayer futuro.

### 8. No se guarda una batalla activa en V2

Savegame V2 serializa estado persistente del jugador, no un encounter/battle transitorio. `WildAdventureSession.save_game()` rechaza `active_wild_battle` en vez de crear un save que parezca válido pero pierda la batalla en curso.

Una eventual reanudación mid-battle requerirá un contrato explícito/versionado; no se finge en FASE 11.

### 9. Load vuelve a un estado jugable

Tras un load válido, la sesión publica el `PlayerCollection` reconstruido y vuelve a `READY`. La suite demuestra que el Pokémon evolucionado, su identidad y el inventario sobreviven, y que puede iniciarse otro encounter inmediatamente.

## Incidencias descubiertas por integración

La vertical slice reveló y cerró tres huecos que los tests aislados no cubrían:

1. no existía reemplazo seguro de la instancia evolucionada dentro de su contenedor propietario;
2. evolución preservaba `moveset` pero no el índice `move_ids`, creando dos representaciones divergentes;
3. stat stages no se limpiaban en el límite post-battle.

Este es precisamente el objetivo del bloque: descubrir defectos de composición antes del Overworld.

## Validación

GitHub Actions, Godot `4.7.stable.official.5b4e0cb0f`:

- regresión histórica: **470 PASS / 0 FAIL**
- Inventory: **47 PASS / 0 FAIL**
- Savegame V2: **40 PASS / 0 FAIL**
- Savegame adversarial: **8 PASS / 0 FAIL**
- Wild Encounters: **54 PASS / 0 FAIL**
- Logical Vertical Slice: **62 PASS / 0 FAIL**
- import headless: PASS
- workflow: SUCCESS

La vertical suite cubre victoria real mediante Battle Core, XP/level, evolución Bulbasaur→Ivysaur, persistencia/save/load/continue, captura a Party, captura con Party llena a Storage, consumo/fallo de Poké Ball, ausencia de objeto sin RNG, derrota sin XP, bloqueo de save mid-battle y rechazo de evolución forjada.

## Fuera de alcance

No Overworld, escenas, mapas, movimiento, NPCs, UI, assets, encuentros de entrenador, mundo persistente ni networking real.

## Consecuencia

El siguiente bloque puede construir **FASE 12 — Overworld Core** sobre un ciclo lógico Pokémon ya probado, en vez de usar escenas para ocultar integraciones incompletas.
