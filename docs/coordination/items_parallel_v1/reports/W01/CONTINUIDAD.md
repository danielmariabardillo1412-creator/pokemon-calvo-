# W01 — CUADERNO DE CONTINUIDAD

## Identidad y autoridad

- **IA1/W01**, rama exclusiva `codex/calvo-items-20261101-w01`.
- Familia: `HELD_COMBAT_CANDIDATE`, objetos `assault_vest`, `loaded_dice`, `focus_sash`.
- Última orden oficial: `docs/coordination/items_parallel_v1/assignments/LOTE_002_W01.md` en rama árbitra, **blob de asignación `660203ce96aeff2f6bb42b88962b7b46f5e2eca4`**.
- Estado **LISTA_PARA_REVISION (tests escritos, Godot PENDIENTE_CI)**; IA6 aceptó únicamente LOTE_001 como auditoría documental. No autodeclarar LOTE_002 integrado.
- Base integrada IA6: `38188cc208e67b19002437ac75160898ce332ec2`; merge seguro propio `e40b82303aa5c12b2ec1faaa8bcea2554e9319a6` con los dos padres. Antiguo W01 preservado: `aa224efeb261a05a63e5d3cae928748ec195aeb1`; informe LOTE_001 blob `df56277c045c05e28499cfea71e99ddaaf18ce48`.
- Commit de tests nuevos: `5f306faa1a375bf4094d493c40e20341a006460c` (tres archivos autorizados). El commit documental del cierre será posterior; consultar HEAD actual.

## Mapa técnico — qué existe y cómo funciona

`docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv` (selección de contenido) → 
`modules/inventory/field_item_service.gd` (`holdable/equip/unequip`, propietario equipo/PC, consumo físico) → 
`modules/gameplay/showdown_adventure_session.gd` / backend `modules/battle/backends/showdown/showdown_backend.gd` (sesión) → 
`native_engine.cjs` / **@pkmn/sim 0.10.11** (hooks de efecto nativos) → 
`CreatureInstance` / `SaveGameRepository` (snapshot/propietario) → UI/escena mapa (fuera del lote).

**No duplicar** lógica del motor en GDScript. `field_held_items.cjs` registra metadatos de otros ítems, no contiene los tres efectos; los hooks nativos conocidos son:
- Chaleco: `assaultvest`, `onDisableMove|onModifySpD`.
- Dado: `loadeddice`, `onModifyMove`.
- Banda: `focussash`, `onDamage`.

Los inventarios `ITEM_INVENTORY.csv` y matriz `ITEM_FIELD_V8.csv.txt` certifican presencia/transferencia y ciertos escenarios antiguos, no funcionamiento exhaustivo. V28 añade harness común, pero su lista de cierre ampliado deja fuera estos tres IDs. V28 y el catálogo convivieron inicialmente en ramas divergentes, ahora comparten checkpoint Git; CI conjunta **sin verificar**.

### Adaptadores y pruebas reutilizables

- V27: `tools/item_audit/held_pilot.cjs`, `held_effect_sweep_v2.cjs`, `tests/gameplay/item_held_pilot_test_runner.gd`, `item_effect_projection_v2.gd`; PASS históricos acotados, **no repetirlos sin motivo**.
- V28: `tests/gameplay/item_automation_v28.gd`, `_fixture`, `_restore_probe`, `_write_evidence`, `FieldItemService`, `SaveGameRepository`, `Native`; `tools/item_audit/automation_v28.py` conserva contratos cerrados ajenos y no se ha editado.
- W01 nuevos: `tests/fixtures/parallel_items/w01_held_v1.json` (9 casos / 16 semillas combinadas / 3 variantes por ejecución), `tests/gameplay/parallel_items_w01_held_v1.gd` (runner que hereda los helpers), `tests/tools/test_parallel_items_w01_held_v1.py` (contratos/evidencia SHA). **No** nuevos handlers de objeto.

## Estado por ID

| ID | Ya existía (histórico) | Test W01 añadido (no ejecutado en Godot) | Pendiente |
|---|---|---|---|
| `assault_vest` | Bloqueo de estado/turno rechazado (V1); callback nativo de Defensa Especial | bloqueo/ataque permitido, reducción de daño especial comparativa, daño físico control, reserva, restore | CI + asentamiento en campaña, supresión/Truco y efectos complejos |
| `loaded_dice` | 4–5 golpes Semilladora (V2) | seis semillas, control sin objeto/reserva, dos golpes fijos, golpe simple, restore y retención | CI + distribución estadística, otros ataques/habilidades |
| `focus_sash` | 1 PS y gasto al evitar KO (V1) | PS máximos/reducidos, golpe no letal, guardado de consumo y unidades activas/reserva | CI + cierre real del combate y gasto único persistido en campaña |

## Historial y evidencia

| Lote | Entrega | Evidencia actual | Autoridad IA6 |
|---|---|---|---|
| 001 | Informe `reports/W01/LOTE_001.md`, commit `aa224efe...`; solo lectura del código | PASS antiguos identificados, sin runtime nuevo | ACEPTADO **documental**, no funcional |
| 002 | Pruebas y fixture nuevos en `5f306faa...`; `reports/W01/LOTE_002.md` y este cuaderno | `python -m py_compile` PASS; `python tests/tools/test_parallel_items_w01_held_v1.py --contracts` PASS 9/16; 4 manipulaciones negativas rechazadas; comando sin reporte termina con error por ausencia de evidencia; **Godot SIN_EJECUTAR** | PENDIENTE_REVISION |

**Comandos futuros reproducibles** desde checkout combinado:

```bash
python -B tests/tools/test_parallel_items_w01_held_v1.py --contracts
godot --headless --path . --import
godot --headless --path . --script res://tests/gameplay/parallel_items_w01_held_v1.gd
python -B tests/tools/test_parallel_items_w01_held_v1.py
```

Se necesita Godot 4.7, `@pkmn/sim@0.10.11` fijado y `POKEMON_CALVO_NODE` correctamente configurado. Reutilizar staging/restauración del workflow V28, sin descargar/alterar datasets originales. La salida de Godot debe producir `.godot/parallel_items/w01_held_v1/report.json` y evidencias; Python sin `--contracts` debe revalidar los hashes. Ningún RUN de Godot nuevo disponible; prueba visual/GPU **NO REALIZADA**.

## Riesgos, dependencias y siguiente paso

1. IA6 debe validar la base fusionada mediante **una CI consolidada** y registrar commit, run, log y posibles fallos de parser/GDScript (no ejecutado aquí).
2. Si un test falla por fixture o regla del motor, conservar su salida y diagnosticar: **no** alterar callback, RNG, selección, ni cambiar el criterio para forzar PASS. Solicitar propietario de motor a IA6 si fuera necesario.
3. El harness W01 hereda de V28. Si se modifica V28/una API compartida, revisar compatibilidad antes de integrar.
4. Falta confirmar liquidación de combate y guardado de campaña después de consumo de Banda. El test actual verifica snapshots/restauración y ausencia de publicación prematura, no el ciclo completo de mapa.
5. La prueba de seis semillas de Dado no certifica porcentaje exacto de distribución; faltan casos de habilidades, movimientos especiales y dobles.
6. El próximo trabajo es **revisar informe 002 + diff y ejecutar CI**; solo después IA6 puede autorizar LOTE_003.

**NO HACER EN OTRO CHAT:** no tocar `main`, V28, árbitra, otras W, `modules/`, `scenes/`, `data/`, `assets/`, `config/`, docs actuales, políticas ni guardados sin nuevo encargo. No reprogramar efectos nativos que ya existen; no asumir LOTE_003 por un simple «sigue».

**Último siguiente paso reproducible:** IA6 revisa `LOTE_002.md`, el fixture y el validador del commit `5f306faa...`, y ejecuta una única CI para obtener el primer PASS/FAIL funcional nuevo. Hasta entonces, estado **LISTA_PARA_REVISION / PENDIENTE_CI**.
