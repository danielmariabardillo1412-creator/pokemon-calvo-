# IA1/W01 — CAMPAÑA_005 — Bloque 03/10

**Rama exclusiva:** `codex/calvo-items-20261104-w01-camp005`.

**IDs de IA6:** `poison_barb;sharp_beak;silk_scarf`. El encargo y la cola están en `CAMPAIGN_005_W01_GATE.md` y `CAMPAIGN_005_W01_QUEUE_APPROVED.csv`; autonomía limitada por `AUTONOMOUS_REPAIR_V5.md`. No se alteran reglas, main, V28, rama árbitra ni ramas ajenas.

## Bloque 02 — certificación cerrada
Run [#41778911208](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41778911208), SHA `69438bfb81921456a87eb7da18b3442f50c79873`, `completed/success`; `CAMP005_W01_PY PASS blocks=2 checks=148` y `CAMP005_W01_GODOT PASS blocks=2 checks=2207`. Se cierra la fila 02 con ese run; el informe no considera que la CI del bloque anterior demuestre efectos nuevos.

## Ensayo funcional nativo del bloque 03

Los tres equipables tienen soporte `onBasePower` en `ITEM_INVENTORY.csv`, están seleccionados en `RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv` y aparecen en los `booster` y `attack` de `tools/item_audit/held_effect_sweep_v2.cjs`. El motor nativo y el sistema SaveV2 ya existentes se reutilizan con Mew a nivel 100 y formato `gen9calvounifiedv1`.

| Equipable | Golpe positivo del tipo correcto (2 semillas) | Control de tipo distinto (1 semilla) | Control no dañino (1 semilla) |
| --- | --- | --- | --- |
| Flecha Venenosa (`poison_barb`) | `sludge_bomb` (Veneno) | `tackle` (Normal) | `reflect` |
| Pico Afilado (`sharp_beak`) | `aerial_ace` (Volador) | `tackle` (Normal) | `reflect` |
| Pañuelo de Seda (`silk_scarf`) | `tackle` (Normal) | `water_gun` (Agua) | `reflect` |

**Aclaración crítica:** para `silk_scarf`, Placaje es el ataque positivo, nunca un control negativo. El control de tipo distinto es Pistola Agua; usar Placaje para negar su bonificación daría un falso negativo y violaría la regla canónica.

Cada prueba usa sesiones nativas independientes con el objeto equipado, sin objeto y en reserva, misma semilla, comparación del daño real, no-consumo, identidad de portador e inventario, seguido de snapshot y proyección SaveV2 restaurada. El test positivo exige `damage_active > damage_none == damage_reserve`; el negativo exige daño igual entre tres controles y daño cero en Reflejo.

**Matriz nueva:** 9 escenarios, 12 pares caso-semilla, 36 variantes. **Acumulado CAMP005:** 9 objetos, 27 escenarios, 36 pares, 108 variantes; se mantienen íntegras las matrices de bloques 01 y 02. No se ha editado producción ni workflow.

## Estado de CI y continuidad

**PENDIENTE DE CI** sobre el SHA de este bloque. Solo se certificará con `CAMP005_W01_PY PASS blocks=3 checks=N` y `CAMP005_W01_GODOT PASS blocks=3 checks=N` (N positivos), más run `completed/success` para el mismo SHA. El workflow ya existe en la rama W01; regresión CAMP004 obligatoria en hitos 05 y 10 o ante cambios de producción, no en 03 sin parches.

Riesgos residuales ajenos al bloque: SaveV2 de Rayo Solar a mitad de carga para IA6, pruebas visuales/GPU e integración `main`/V28 sin certificar. Si falla la CI, reparar propio runner/efecto según V5 sin retirar controles y sin tocar otras ramas.

Próxima `p` tras PASS: exclusivamente bloque 04 `silver_powder;soft_sand;spell_tag`. No iniciar anticipadamente.

## Bloque 03 — certificación de CI real

La CI [#41783664400](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41783664400) concluyó **`completed/success`** sobre el SHA de pruebas `67d0fe6041e690cc8059fd626eea7cdd4a840db2`. Se verificaron los recibos literales del job:
- `CAMP005_W01_SCOPE PASS blocks=3`
- `CAMP005_W01_PY PASS blocks=3 checks=208`
- `CAMP005_W01_GODOT PASS blocks=3 checks=3305`

Se mantiene el acumulado **3/10 bloques, 9 equipables, 27 escenarios, 36 pares caso-semilla y 108 variantes**, con comprobaciones funcionales de efecto positivo y SaveV2. No hubo modificaciones del motor ni de las pruebas heredadas. La regresión CAMP004 en el hito 03 se omitió legítimamente por la política del workflow (fue SUCCESS en el hito 01, run #41767517526; se repetirá al 05 y 10 o ante parche de producción).

Para evitar una CI redundante por metadatos, la fila 03 del CSV seguirá provisionalmente `EN_CI_AUTOMATICA`; con la próxima `p` se cerrará como `CI_PASS_VERIFICADO`, SHA `67d0fe6041e690cc8059fd626eea7cdd4a840db2` y run `41783664400`, antes de añadir el bloque 04 `silver_powder;soft_sand;spell_tag`. **No iniciar bloque 04 sin `p` explícita**.

Incidencia histórica SaveV2 de Rayo Solar a media carga pendiente de IA6; sin certificación visual/GPU ni fusión a main o V28.
