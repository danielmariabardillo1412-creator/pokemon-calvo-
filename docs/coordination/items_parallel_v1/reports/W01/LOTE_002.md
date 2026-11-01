# W01 / LOTE_002 — pruebas declarativas de equipables (entrega)

**Estado: LISTA_PARA_REVISION — código de prueba preparado; ejecución Godot PENDIENTE_CI.**  
**Trabajadora:** IA1/W01. **Rama exclusiva:** `codex/calvo-items-20261101-w01`.  
**Orden oficial:** `docs/coordination/items_parallel_v1/assignments/LOTE_002_W01.md` de la rama árbitra, blob `660203ce96aeff2f6bb42b88962b7b46f5e2eca4`.  
**Objetos únicos autorizados:** `assault_vest`, `loaded_dice`, `focus_sash`.

## 1. Sincronización no destructiva

- Inicio W01 tras LOTE_001 aceptado: `aa224efeb261a05a63e5d3cae928748ec195aeb1`.
- Checkpoint de IA6 incorporado con commit de **merge normal** `e40b82303aa5c12b2ec1faaa8bcea2554e9319a6`, padres W01 original + `38188cc208e67b19002437ac75160898ce332ec2`. **No** force, reset o rebase.
- Validación GitHub tras el merge: checkpoint -> W01 `ahead=3, behind=0`; base original W01 -> W01 `behind=0`. El blob de LOTE_001 se conservó exactamente: `df56277c045c05e28499cfea71e99ddaaf18ce48`.
- Confirmados en W01: `tools/item_audit/automation_v28.py` blob `ae181662b315f033172a5cfef4a87961088fe8fd`, `docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv` blob `8b9b723bf5944bbbde39aa2d49dfbb2f2a64e11b`, `NOTEBOOK_PROTOCOL_V1.md` blob `4fac0eba28ea30dc6d3a3bd749699874cf446e66`.
- **Checkpoint combinado sin ejecutar**: la fusión correcta en Git **no** demuestra compatibilidad funcional de Godot V27+V28.

## 2. Cambios hechos de verdad

**Commit de pruebas:** `5f306faa1a375bf4094d493c40e20341a006460c`.

| Ruta NUEVA (únicas rutas de pruebas autorizadas) | Contenido | SHA de blob Git |
|---|---|---|
| `tests/fixtures/parallel_items/w01_held_v1.json` | 9 contratos y semillas fijas; controles `active/none/reserve` | `9c318220dca51d2088f5b58f81c9fe9636d79bde` |
| `tests/gameplay/parallel_items_w01_held_v1.gd` | Un runner de escenarios; hereda helpers V28 sin tocar su código ni motor | `d9551db1ec5e08b1213e04829d031e3a6720188f` |
| `tests/tools/test_parallel_items_w01_held_v1.py` | Valida esquema, cobertura, identidad, pruebas negativas, snapshots brutos y SHA-256 de evidencias | `9d3230b0c9aeaa6848d4b3c3794d2ca403b9ef09` |

Los únicos otros archivos autorizados son este informe y `CONTINUIDAD.md` en `reports/W01/`. No se ha cambiado ningún script existente, lógica Showdown, fixture V28, workflow, selector, política, guardado o contenido canónico.

## 3. Escenarios y criterios de aceptación nuevos (NO PASS funcional todavía)

| ID | Caso | Criterio verificable |
|---|---|---|
| `assault_vest` | `vest_status_gate` | Movimiento de estado inhabilitado **solo** al portador activo; intento rechazado sin mutación y ataque normal autorizado. |
| `assault_vest` | `vest_special_defense` | Ataque especial real: portador activo recibe menos daño que la misma escena sin objeto; objeto en reserva no protege al activo; retención. |
| `assault_vest` | `vest_physical_control` | Dano físico de control igual con objeto activo, ninguno y objeto en reserva. |
| `loaded_dice` | `dice_bullet_seed` | Semilladora fuerza 4/5 golpes por la vía nativa, comparación `none`/`reserve` con mismas semillas y no consumo. Seis semillas. |
| `loaded_dice` | `dice_fixed_two` | Doble Patada conserva sus dos golpes con y sin objeto; no consumo. |
| `loaded_dice` | `dice_single_hit` | Placaje conserva el daño del control sin objeto y reserva; no consumo. |
| `focus_sash` | `sash_full_hp_ko` | KO potencial desde PS completos: 1 PS restante con Banda activa, 0 sin Banda activa; consumo de una sola unidad física. |
| `focus_sash` | `sash_partial_hp_ko` | KO desde PS reducidos: falla la protección y la Banda permanece sin gastar. |
| `focus_sash` | `sash_nonlethal` | Golpe no letal: sobreviven todos, no se consume Banda. |

**16 ejecuciones declaradas, 48 variantes de combate nativo previstas.** Cada una usa el mismo contrato de creación de criatura, semilla determinista, tres ubicaciones de objeto y snapshots `SaveGameRepository` + `restore_saved` heredados de V28. El runner comprueba la conservación del propietario de campaña (no publicación prematura) y que no se dupliquen unidades. Los resultados se generan en `.godot/parallel_items/w01_held_v1/` y **no** se versionan.

**Diferencia deliberada con el piloto histórico:** no hay una nueva fórmula de daño, dado, aguante o callback. Los oráculos comparativos miran resultados nativos de situaciones iguales con/sin objeto; se reutilizan `FieldItemService`, `Native` y el snapshot real. El validador Python exige el informe y las evidencias por archivo; un JSON incompleto no puede producir un PASS.

## 4. Pruebas ejecutadas hoy y no ejecutadas

Comandos locales efectivamente ejecutados sobre copias idénticas de los archivos recién publicados:

```text
python -m py_compile tests/tools/test_parallel_items_w01_held_v1.py
python tests/tools/test_parallel_items_w01_held_v1.py --contracts
```

- **PASS REAL (solo PYTHON/CONTRATO)**: `W01_CONTRACTS_PASS scenarios=9 runs=16 godot=SIN_EJECUTAR`.
- **PASS REAL (solo validador de CONTRATO)**: 4 mutaciones deliberadas (ID duplicado, objeto distinto, movimiento distinto y caso ausente) rechazadas con `ValueError` durante una prueba ad hoc sin modificar el código versionado.
- **PASS REAL**: `py_compile` del fichero Python. No certifica GDScript.
- **NEGATIVO REAL**: ejecución sin `--contracts`, al faltar `report.json` nativo, termina con código 1 y `W01_SIN_EJECUTAR: falta report.json de Godot; no se declara PASS de efecto`.
- **SIN_EJECUTAR / PENDIENTE_CI**: importación/parseo de GDScript, carga de simulador y 48 combates Godot 4.7, integración y guardado real durante combate, comparador contra evidencia nativa, acciones de campo/UI, regresiones combinadas. Este entorno **no tiene binario Godot ni checkout con `.godot/battle_reference/runtime/node_modules/@pkmn/sim`**; no se ha disparado una CI nueva.
- **PASS HISTÓRICO, NO NUEVO**: `docs/current/ITEM_FOUNDATION_V1.json` (piloto Chaleco/Banda), `ITEM_VERIFICATION_V2.md` (Dado), `ITEM_VERIFICATION_V3.md` (regresiones V1/V2); también V28 registra otros IDs, **sin cierre ampliado** de estos tres. Ver LOTE_001 para su desglose.
- **GPU/visual:** `NO REALIZADA`. Las vistas, iconos, controles de mapa y representación gráfica no están cubiertos por el runner.

### Comandos para una ejecución aprobada por IA6 (en checkout W01 con Godot 4.7, Node y simulador preparados)

```bash
python -B tests/tools/test_parallel_items_w01_held_v1.py --contracts
godot --headless --path . --import
godot --headless --path . --script res://tests/gameplay/parallel_items_w01_held_v1.gd
python -B tests/tools/test_parallel_items_w01_held_v1.py
```

**Condiciones:** instalar/recuperar los recursos y el runtime fijado conforme al workflow V28 existente antes del import; establecer `POKEMON_CALVO_NODE` con la ruta del Node si no es la predeterminada. El tercer comando solo puede considerarse PASS si finaliza con código 0 y publica `PARALLEL_ITEMS_W01 PASS` sin errores; el cuarto compara las evidencias en disco y sus hashes. La prueba de Godot no se ha ejecutado en esta entrega, por lo que las aserciones GDScript aún no han superado un parser/runtime real.

## 5. Riesgos, conflictos y lo que falta

1. **BLOQUEO DE VERIFICACIÓN:** fusion V27/V28 aún sin batería Godot consolidada. IA6 debe ejecutar una única CI (no 20 workflows por trabajadora), registrar commit/run/log y corregir si el test nuevo falla **solo dentro de sus permisos**.
2. **Riesgo de fixture:** la combinación de semillas y criaturas puede descubrir incompatibilidades de perfil (por ejemplo registro `hitcount`, legalidad de movimientos, KO/recoil o importación de estado). Si falla, guardar error literal y valor observado; **no** alterar producción ni maquillar el fixture para convertirlo en PASS.
3. **Persistencia acotada:** el runner intenta escribir/leer snapshots nativos y colección de propietario SaveV2 en cada variante, pero **no** certifica todavía el asentamiento al ganar/abandonar en la partida real, ni el reintento de gasto tras cerrar victoria. El patrón `map_bag_owner_save` V28 es reutilizable en un futuro lote con autorización, no se copia ahora.
4. **Mecánica no exhaustiva:** las seis semillas de Semilladora no demuestran una distribución probabilística exacta; faltan interacciones con habilidades, supresión de objeto, cambios por Truco/Desarme y otros formatos.
5. **Propiedad de archivos compartidos:** W02 y otras W podrían necesitar V28, `field_item_service.gd`, `native_engine.cjs` y `event_adapter.gd`; IA6 debe asignar propietario explícito antes de abrir código de producción o modificar harness común.
6. **Riesgo de mantener V28:** el runner **hereda helpers** de `item_automation_v28.gd`. Si IA6 cambia su interfaz al integrar o actualizar, hay que revisar compatibilidad y ejecutar prueba antes de aceptar.

**SOLICITUD_IA6 (no implementada):** programar la CI consolidada para W01 + las otras W, suministrar Godot 4.7/Node fijado y ejecutar primero el import del árbol combinado, después la batería y el validador Python; revisar después eventual falta de asentamiento en mapa o fallos encontrados. Mantener hasta entonces el estado `PENDIENTE_CI`.

## 6. Autocontrol

`main`, `codex/items-v28-from-main`, `codex/calvo-items-20261101-arbitro`, demás W, módulos de producción, políticas, datasets, arte, guardados, fixtures previos y CI histórica **intactos**. La rama W01 contiene su LOTE_001 sin alteración, una fusión no destructiva aprobada y archivos nuevos dentro de la lista blanca del LOTE_002.

**Estado: `LISTA_PARA_REVISION`** de la entrega de tests y documentación, **no** `FUNCIONALES_CERTIFICADOS`. No tomar LOTE_003 hasta orden de IA6.
