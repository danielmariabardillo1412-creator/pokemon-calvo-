# IA1/W01 — TANDA03 — RECIBOS FUNCIONALES PARCIALES

**Estado:** 9/10 hitos con pruebas de subsistemas aprobadas, **0 objetos nuevos**, integración IA6 **NO**, hito 10 pendiente de cuatro regresiones acumulativas.

## Fuente de verdad

- Rama W01 `codex/calvo-items-20261110-w01-gems-autobatch01`.
- SHA FUNCIONAL `20bfd7c3a08250c79a0a3d4f0dbf120f70850138`, CI [#42893188116](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42893188116). Los recibos siguientes pertenecen **solo a esta SHA y a ese run**; si termina en fallo global, no declararlo SUCCESS.
- Nota vigente: `docs/coordination/items_parallel_v1/IA6_AUTORUN.md` TANDA03.

### Puerta L3 real, aprobada

- Job `v3_l3_field_path`: **completed/success**.
- `W01_V3_PY PASS items=18 milestones=10 checks=94`
- `W01_V3_GODOT PASS ids=18 rejections=5 legacy=1 checks=574`
- 18/18 filas `W01_V3_L3_ROW PASS` para 3 CAMP005, 10 T01, 5 T02.
- Ruta ejercida: bolsa real `PlayerInventory` → `FieldItemService.equip` → guardado/reapertura V2 en disco → `FieldNativeSession` → ataque auténtico y consumo → `settle_finished_battle` → propietario persistido → guardado/carga V2 → `unequip` sin devolución de gema consumida → reequipamiento de segunda unidad con estado limpio.
- Negativos: propiedad ajena, re-equipar un item que ya está equipado, bolsa agotada, sustitución reversible con conteos exactos; legacy V1 migra a bolsa vacía y no resucita gemas gastadas.

### Puerta de condiciones de batalla, aprobada

- Job `v3_field_boundaries`: **completed/success**.
- `W01_V3_BOUNDARIES PASS cases=3 captures=2 defeats=1 transforms=1 checks=64`
- `reserve_capture`: equipado desde `FieldItemService` en reserva, cambio al portador, golpe que consume, cambios de miembro sin reaparición, captura con Master Ball y guardado/carga V2 de la criatura consumida.
- `defeat`: el portador pierde antes de atacar y conserva su gema, con liquidación y SaveV2 reales.
- `transform_capture`: Ditto equipado mediante el servicio, Transformación real, guardado y restauración a mitad de combate, posterior ataque Fantasma con consumo, captura y reconciliación del Ditto original al guardar.

### Regresiones de cierre pendientes a última comprobación

- `camp004_regression`: en ejecución, aún sin PASS global.
- `camp005_regression`: en ejecución, aún sin PASS global.
- `tanda01_regression`: en ejecución, aún sin PASS global.
- `v2_new_gems`: en ejecución, aún sin PASS global.

**Nota técnica:** La primera batería de límites mostró dos aserciones rojas por selección de slot al volver de reserva. Se sustituyeron por `_switch_choice` (identidad de criatura, no índice supuesto) y se corrigió el contador para que jamás imprima PASS por fila si hay aserciones fallidas. La segunda batería es la que obtuvo SUCCESS. No se modificó producción ni se redujo cobertura.

## Siguiente `p`

1. Leer nota `IA6_AUTORUN.md`, branch HEAD y este recibo; no repetir IDs ya aprobados.
2. Consultar **CI #42893188116 sobre SHA 20bfd7c3a08250c79a0a3d4f0dbf120f70850138**. Si los 6 jobs son `completed/success`, completar el CSV T03 (10 hitos, 0 objetos nuevos), publicar informe final `AUTORUN_V3_FINAL.md` y STOP.
3. Si cualquier job falla, analizar log y reparar SOLO en tests/fixtures/workflow W01; no modificar backend/SaveV2/proveedores compartidos sin autorización. No dar por terminada T03 hasta CI total.

**Precisión:** Este documento solo acredita integración L3 por las APIs reales de campo, no un recorrido manual por interfaz, ni merge en la rama árbitra IA6. El commit documental que publica este recibo NO representa una nueva CI funcional aprobada.
