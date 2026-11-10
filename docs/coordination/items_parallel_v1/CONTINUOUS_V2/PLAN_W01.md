# W01 — CAMPAÑA CONTINUA V2 · EQUIPABLES DE COMBATE
**Rama exclusiva:** `codex/calvo-items-20261110-w01-gems-autobatch01`. **Especialidad:** equipables con efecto de batalla. La TANDA04 (10 IDs `leftovers`→`sitrus_berry`) está **EN CURSO**; su CI de `leftovers` estaba `in_progress` al emitir la orden V2. **No interrumpir ni fingir su certificación.**

## Ejecución de cola
**Fase A:** finalizar la TANDA04 YA AUTORIZADA en `AUTONOMY_V1/QUEUE_W01_TANDA_04.md` de árbitra. Seguir su CSV y CI sin reiniciar `leftovers`, sin solapar otras W ni generar mensaje IA6 al completar 10/10. **Inmediatamente después** pasar a Fase B.
**Fase B:** los siguientes **26 IDs verificadamente presentes** en `item_connections_v1.json::holdable_ids` al emitir V2, en tres bloques 10+10+6:

| Bloque | IDs preautorizados | Cantidad |
|---|---|---|
| 01 | `ability_shield`, `absorb_bulb`, `adrenaline_orb`, `big_root`, `expert_belt`, `amulet_coin`, `pure_incense`, `luck_incense`, `cleanse_tag`, `draco_plate` | 10 |
| 02 | `dread_plate`, `earth_plate`, `fist_plate`, `flame_plate`, `icicle_plate`, `insect_plate`, `iron_plate`, `meadow_plate`, `mind_plate`, `pixie_plate` | 10 |
| 03 | `sky_plate`, `splash_plate`, `spooky_plate`, `stone_plate`, `toxic_plate`, `zap_plate` | 6 |

Las placas se autorizan **solo como potenciadores de tipo en combate** cuando corresponda: no modificar especie o forma de Arceus ni mecanismos de W04. `amulet_coin`, `pure_incense`, `luck_incense`, `cleanse_tag` pueden requerir dinero/encuentros/cría: si no hay productor verificable y es un objeto de otra familia, registrar `DEPENDENCIA_FUERA_W01` y seguir, **no inventar gold/encounter/egg**.

**Fase C (solo si queda tiempo y hay necesidad real):** auditar los 26 resultados y las 10 filas de TANDA04 en recorrido `FieldItemService.equip → combate nativo Showdown → liquidación → SaveV2`. Ejecutar pruebas positivas y negativas que falten. Hacer CI final del workstream con regresión CAMP003–005, gemas T01–03 y equipables nuevos; no contar regresiones como nuevos IDs.

## Reglas de propiedad y parada
Verificar antes de tocar: `config/item_selection_v1.json`, política de contenido activa, definición y **certificación anterior** de cada ID; `holdable` no implica que sea un usable del juego. Si `YA_CERTIFICADO`, aportar SHA+prueba y saltar implementación. Si `NO_APLICA`, no sustituir con IDs no listados. Evitar berries W02, balls W03 y evolution/forms W04.
Autorizar tests/fixtures/workflow/informes W01 y reparación mínima **de la ruta específica del ítem** de held ya propia W01. Backend `native_engine.cjs` solo arreglo local del ID demostrado por prueba roja sin variar regla global. Prohibido `FieldItemBag`, `CreatureInstance`, `PlayerCollection`, `SaveV2` central, otros módulos/ramas. Si aparecen más equipables fuera de las 26 tras terminar, **crear propuesta lista concreta para IA6**, no autoconsentir un barrido ciego de 631 IDs.
No pararse en 10: continuar por todos los bloques hasta procesar 10+26 IDs o topar con bloqueo protegido de lo restante. Si acaba el turno, checkpoint y siguiente p; terminar en `READY_FOR_IA6`.
