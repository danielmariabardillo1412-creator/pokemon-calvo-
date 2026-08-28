# Foundation V1 status

Fecha de validación: 2026-08-29  
Rama: `foundation/core-v1`  
Motor: `4.7.stable.official.5b4e0cb0f`

## Resultado

- Arquitectura auditada: **VALIDADA CON CAMBIOS**
- Importación/editor Godot 4.7: **PASS**, exit 0, sin errores de parseo
- Ejecución headless: **PASS**, exit 0
- Tests: **13 PASS / 0 FAIL**
- Battle minimal: **PASS**
- RNG determinista y empate de velocidad: **PASS**
- Snapshot JSON y restauración: **PASS**
- Autoloads: **0**
- Código/recursos externos incorporados: **0**

## Cobertura demostrada

- Definiciones de especie, tipo, movimiento y status como Resource
- Instancia mutable y estadísticas como RefCounted
- prioridad y velocidad
- daño, STAB y efectividad
- KO y final de combate
- Poison aislado en `StatusSystem`
- mismos seed/acciones producen mismos eventos y snapshot
- `BattleEvent` consumible por presentación
- snapshot con esquema, ruleset, algoritmo/estado RNG e IDs estables
- rechazo autoritativo de movimiento forjado sin mutación de HP/turno
- payload cliente sin daño, HP ni resultado

## Fuera de alcance

No hay networking, UI, mapas, assets, datos masivos, savegame general, captura,
party, inventario ni contenido Pokémon. No se debe iniciar la siguiente fase ni
mezclar esta rama en `main` sin autorización.
