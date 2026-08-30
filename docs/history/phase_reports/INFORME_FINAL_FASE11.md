# INFORME FINAL — FASE 11: Logical Vertical Slice V1

Fecha: 2026-08-29  
Rama: `feature/vertical-slice-core-v1`  
Base: `feature/wild-encounters-v1`  
PR: #5  
Motor CI: `4.7.stable.official.5b4e0cb0f`

## Estado

**FASE_11_STATUS = CLOSED / VALIDATED**

## Ciclo demostrado

La suite end-to-end ejecuta con sistemas reales:

`WildEncounterSystem`
→ `BattleState` / `AuthoritativeBattleServer`
→ victoria o captura
→ `BattleOutcome` / `ProgressionSystem`
→ level/evolución
→ Party/Storage/Inventory
→ Savegame V2
→ Load
→ nuevo encounter.

No se simula el final de Battle escribiendo directamente su estado en el escenario principal: el KO se produce mediante una acción aceptada por el servidor autoritativo y `TurnExecutor` finaliza la batalla.

## Capa de aplicación

Se añadió `WildAdventureSession` para orquestar el ciclo sin absorber reglas de dominio.

Responsabilidades:

- pedir/resolver encounters;
- construir Battle con referencias persistentes reales;
- delegar turnos al servidor autoritativo;
- construir el contexto de captura desde estado confiable;
- enrutar captura a Party/Storage;
- convertir Battle finalizada a `BattleOutcome`;
- invocar Progression;
- aplicar una evolución elegible al contenedor propietario;
- proteger Savegame V2 frente a un guardado mid-battle que perdería estado transitorio;
- restaurar el agregado del jugador tras Load.

## Defectos reales encontrados y corregidos

### 1. Evolution object replacement

`EvolutionSystem` devuelve una nueva instancia con el mismo `instance_id`, pero Party/Storage no tenían contrato para sustituir el objeto detrás de esa identidad.

Corrección:

- `CreatureParty.replace_same_identity`
- `CreatureStorage.replace_same_identity`
- `PlayerCollection.replace_owned_same_identity`
- `PlayerCollection.owned_creature`

Se conservan orden de Party y box/slot de Storage.

### 2. Move index perdido durante evolución

La evolución copiaba `moveset`, pero no reconstruía `move_ids`. Eso podía producir una criatura cuya lista de slots y su índice de movimientos no coincidieran.

Corregido; también se preservan held item y status IDs.

### 3. Stat stages persistían post-battle

`reconcile_post_battle()` limpiaba volatile status pero no `StatStages`.

Corregido: stages se reinician al salir de Battle; HP/PP se clampan y status persistentes se mantienen.

### 4. Evolución forjada

La capa de aplicación no confía en un `species_id` arbitrario contenido en un evento. Vuelve a validar que el target sea un candidato real de evolución en el estado actual antes de aplicarlo.

### 5. Save mid-battle

Savegame V2 no contiene un contrato para reanudar un Battle/Encounter activo. En vez de perder silenciosamente ese estado, la sesión devuelve `active_wild_battle` y no guarda.

## Escenarios end-to-end validados

- jugador sin Pokémon vivo: encounter rechazado sin consumir RNG;
- Encounter crea una batalla usando las mismas referencias persistentes;
- segundo encounter rechazado durante Battle activa sin tocar su RNG;
- settlement antes de FINISHED rechazado;
- victoria real por Battle Core;
- XP y level-up;
- Bulbasaur → Ivysaur;
- misma identidad tras evolución;
- move index y held item conservados;
- save/load de evolución + inventario;
- continuar con otro encounter después de cargar;
- Master Ball → Party → save/load;
- Party llena → Master Ball → Storage → save/load;
- Poké Ball fallida consume exactamente una y Battle continúa;
- ball no poseída no consume RNG y Battle continúa;
- save bloqueado durante Battle activa;
- derrota cierra sin conceder XP;
- KO persistente tras derrota;
- stat stages eliminados post-battle;
- evolución en Party conserva orden;
- evolución en Storage conserva box/slot;
- evolución forjada a especie arbitraria rechazada;
- status persistente conservado por evolución.

## Gates

- Historical regression: **470 PASS / 0 FAIL**
- Inventory: **47 PASS / 0 FAIL**
- Savegame V2: **40 PASS / 0 FAIL**
- Savegame V2 adversarial: **8 PASS / 0 FAIL**
- Wild Encounters: **54 PASS / 0 FAIL**
- Logical Vertical Slice: **62 PASS / 0 FAIL**
- Import headless: **PASS**
- Workflow: **SUCCESS**
- Unexpected parse/runtime errors: **0**
- Merge a main: **NO**

Nota: el diagnóstico de parse JSON emitido por el test histórico de JSON corrupto es intencionado y termina en PASS (`json_parse_error`).

## Fuera de alcance

No movimiento visual, mapas, colisiones, grass triggers, NPCs, UI, sprites, audio, historia, world-state persistente ni multiplayer.

## Siguiente paso

**FASE 12 — Overworld Core V1**

Construir la capa lógica/escena mínima que convierta desplazamiento por el mundo en zonas/triggers y llame a la vertical slice ya validada, manteniendo el núcleo independiente de los assets romanos finales.
