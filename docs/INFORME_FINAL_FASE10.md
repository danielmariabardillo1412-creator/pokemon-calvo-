# INFORME FINAL — FASE 10: Wild Encounters Core V1

Fecha: 2026-08-29  
Rama: `feature/wild-encounters-v1`  
Base: `feature/inventory-savegame-v2`  
PR: #4  
Motor CI: `4.7.stable.official.5b4e0cb0f`

## Estado

**FASE_10_STATUS = CLOSED / VALIDATED**

## Implementado

- `WildEncounterRuleset` versionado (`calvo_wild_encounters_v1`).
- `WildEncounterSlot`: stable `slot_id`, `species_id`, peso y rango de nivel.
- `WildEncounterTable`: stable `zone_id`, probabilidad en basis points y slots ordenados.
- validación de datos antes de consumir RNG;
- validación de especies contra `SpeciesCatalog`;
- selección ponderada determinista;
- nivel inclusivo `min_level..max_level`;
- creación de la criatura mediante el `CreatureFactory` ya existente;
- `instance_id` derivado del stream RNG para replay exacto, sin depender del contador global del factory;
- resultado semántico `INVALID / NONE / ENCOUNTER`;
- serialización estable de tablas;
- manejo de payloads con tipos hostiles;
- handoff probado `Encounter → Capture → Party` con inventario real y consumo de Master Ball.

## Frontera arquitectónica

El caller/overworld futuro decide **cuándo** se solicita una tirada y qué `zone_id` está activo. El subsistema de encounters decide **si ocurre**, **qué especie**, **qué nivel** y crea el `CreatureInstance`.

No conoce pasos, hierba, mapas, animaciones, UI ni escenas de Battle.

`CreatureFactory` continúa siendo la única fuente de verdad para IV, Nature, Ability, stats y moveset inicial.

## Determinismo

- tabla inválida: rechazo antes de RNG;
- `chance = 0`: `NONE` sin RNG;
- `chance = 10000`: se omite la tirada de chance innecesaria;
- mismo estado RNG + misma tabla: mismo slot, especie, nivel, identidad y rasgos del Pokémon;
- encuentros consecutivos sobre un mismo stream: IDs distintos.

## Gates finales

- Regresión histórica: **470 PASS / 0 FAIL**
- Inventory 9A: **47 PASS / 0 FAIL**
- Savegame V2: **40 PASS / 0 FAIL**
- Savegame V2 adversarial: **8 PASS / 0 FAIL**
- Wild Encounters: **54 PASS / 0 FAIL**
- Import Godot headless: **PASS**
- Workflow: **SUCCESS**
- Godot: `4.7.stable.official.5b4e0cb0f`
- Merge a `main`: **NO**

## Fuera de alcance

No mapas, triggers de pasos/hierba, sprites, clima/hora, repelentes, habilidades que modifiquen encuentros, hordas, cadenas, UI ni batalla de entrenador.

## Siguiente paso

**FASE 11 — Vertical Slice lógico completo**

Conectar en una capa de aplicación y probar end-to-end:

`Encounter → Battle → Capture/Victory → Progression → Party/Storage/Inventory → Save → Load → Continue`.

La meta de FASE 11 no es añadir presentación: es demostrar que las piezas existentes forman un ciclo Pokémon coherente y persistente antes de construir Overworld/UI.
