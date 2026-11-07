# IA2/W02 — CAMPAÑA_006 | BLOQUE 09/10: habilidades y Menta Amable

**Rama:** `codex/calvo-items-20261104-w02-camp006`. Puerta CI anterior: [run 42254167309](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42254167309) `completed/success` en `d1f9ea1f2ecbed44e21cf9e6d6398dfff4fdd19f`.

## Tres efectos auténticos (pruebas publicadas)

- `ability_capsule`: Growlithe con `intimidate` cambia a `flash_fire` por ruta real `FieldItemService.ability_preview` → `use_item`, con transición atómica y `stamp` de inventario. Probar stale stamp, slot inválido y SaveV2.
- `ability_patch`: Growlithe `intimidate` → habilidad oculta `justified` desde la mochila, con los mismos negativos y SaveV2. No modificar producción compartida del adaptador.
- `gentle_mint`: `hardy` → `gentle` (+Defensa Especial / −Defensa) como **naturaleza efectiva**, sin alterar `nature_id`. Solo se añade un mapeo de ID/naturaleza en el helper propio de W02 `field_mint_effects.gd`, reutilizando el piloto autorizado de bloque04. `CreatureInstance` y `FieldItemService` no se modifican. Calcular estadística real vía `StatCalculator.compute`, comparar contra criatura recargada de SaveV2, exigir consumo de una unidad y rechazo sin consumo de menta duplicada.

Tres objetos × 3 contextos (PARTY/STORAGE/sin stock) con **6 positivos + 3 negativos**. CI incluye 288 escenarios CAMP005, anteriores bloques 01–08, Godot 4.7 y regresiones CAMP004/003.

## Continuidad y límites

El documento histórico del bloque02 conserva la evidencia original sobre `gentle_mint` cuando *no existía* un ejecutor. Su test negativo de regresión se traslada al ID `hasty_mint`, que aún es dependencia, y la prueba positiva nueva de `gentle_mint` vive en el bloque09. Los otros IDs de fila02 (`hasty_mint`, `lax_mint`) y los de fila03 no quedan certificados. No reescribir los recibos antiguos como si hubieran sido funcionales en aquella CI.

**Estado actual: PRUEBAS PUBLICADAS, CI GLOBAL PENDIENTE**. No declarar PASS funcional de este bloque hasta ejecución `completed/success` del workflow en su SHA. Solo rama W02; sin tocar `main`, V28, rama árbitra, StatCalculator, SaveV2 compartido, motor de batalla ni ramas ajenas. Tras PASS, siguiente `p` inicia bloque10.
