## CORRECCIÓN CI DE BLOQUE 02 — CONTRATO DE SEMILLAS

**Fallo real de contrato Python, no de mecánica:** [CI #41555265598](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555265598) `failure`, porque el validador W01 exigía máximo 4 semillas en todos los casos y `blunder_accuracy_event` reserva exactamente 8. La CI se detuvo antes de Godot. Corrección solo de test, sin bajar controles: commit `95de5b7581b54183a7fd108ccf6066a1ddb32154`; límite 8 para ese caso, pero lista exacta inmutable en `SCENARIOS_02`. Resto sigue tope 4. CSV actualizado `45e06d1b14f1969a0ee178caf42543a69139cdbb`. **Nueva CI de último SHA debe pasar antes de atribuir PASS de 02**; si falla motor/contrato ajeno, detenerse.

---

## ACTUALIZACIÓN MÁS RECIENTE — CAMPAÑA_003 02/10 (2026-11-03)

**Identidad:** IA1/W01. Única rama de escritura `codex/calvo-items-20261103-w01-camp003`. Cola aprobada IA6 `CAMPAIGN_003_QUEUE_APPROVED.csv`, fila W01/02; ID exactos `blunder_policy;booster_energy;cell_battery`. Se ejecutó UNA iteración nueva tras recibir la `p`. **No iniciar 03 hasta próxima `p`.**

- **CI del bloque 01 confirmada:** [Actions #41553771307](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41553771307) SUCCESS en SHA de tests/progreso `f9316279e97564f7b12ff71ad0692f572881afa2`; Godot 4.7 `CAMP003_W01_GODOT PASS blocks=1 checks=872`. CSV de 01 corregido a `CI_PASS_VERIFICADO`.
- **Bloque 02 publicado:** fixture 8 casos nuevos / 18 pares-semilla, 54 variantes; total acumulativo con bloque 01: **15 casos / 28 pares-semilla / 84 variantes**. No se modifican los 7 anteriores. Informes `CAMP_003_ITER_01.md` y `CAMP_003_ITER_02.md` son la entrada más rápida para otra IA.
- **Mecánicas existentes:** Seguro Fallo `held_effect_sweep_v3.cjs` cambia `spe +2` y consume únicamente al fallar `zap_cannon`; test contrastado contra log `|-miss|` con ocho semillas, y sin objeto/reserva. Energía Potenciadora tiene pruebas V3 con Great Tusk/Protosíntesis, Iron Hands/Carga Cuark, control sin habilidad; ahora se exige activación al entrar, volátil y consumo real. Pila tiene prueba V2 con `thunder_shock` y `atk +1`; controles Normal/estado. No se implementaron hooks nuevos.
- **Pruebas nuevas autorizadas (acumulativas):** `tests/fixtures/parallel_items/w01_campaign_003.json` blob `07ea3df454b4e83e0e71aac8887dc341c822ca53` (commit `6d5c6f2aa...`); `tests/gameplay/parallel_items_w01_campaign_003.gd` blob `12f59a4997e8f5aebf5659af9c554e0689bb1386` (commit `0c29554638...`); `tests/tools/test_parallel_items_w01_campaign_003.py` blob `c3b5621bc757aa01839e2a2714a74ac955d19f80` (commit `963c8c772e...`). CSV 2 filas, actualización de progreso SHA `594c6772f3b64c9cabc2b31d23d435634bc53bee`.
- **CI de bloque 02:** último run [#41555265598](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555265598) sobre último commit de progreso; **EN_CI_AUTOMATICA** al crear cuaderno. Las ejecuciones intermedias canceladas por `concurrency.cancel-in-progress` no son fallos funcionales. Auditoría estructural 12/12 PASS; **no afirmar PASS nativo de bloque 02 antes de resultado real**.
- **Próxima `p`:** consultar gate y último run. Si `success`, ejecutar exclusivamente W01/03 `clear_amulet;covert_cloak;eject_button`; si `queued/in_progress` se puede preparar un bloque de tests independientes sin declarar PASS; si `failure`, revisar la causa y reparar únicamente propio TEST o STOP por dependencia compartida. Sin cambios en `main`, V28, otras ramas, producción, `modules/`, `data/`, CSV canónicos ni workflow; W04 reincorporada por IA6 mediante addendum, fuera de nuestras asignaciones.
- **Regla límite:** 10 bloques totales; una `p` autoriza solo el siguiente. Tras 10/10 `CAMPAÑA_003_FINALIZADA` y STOP. No crear nuevas tareas de forma autónoma.

---

# CUADERNO VIGENTE — IA1/W01 · CAMPAÑA_003 (2026-11-03)

## ACTUALIZACIÓN VIGENTE — IA1 W01 / CAMPAÑA_003 BLOQUE 01

**Identidad:** IA1/W01; rama exclusiva `codex/calvo-items-20261103-w01-camp003`, nacida del SHA `41c1efeba0346349490f863131179ed7a8fc274c`. **Campaña ACTIVADA 10 bloques** por IA6 y usuario. Autoridad: `CAMPAIGN_GATE_003.md` blob `390f7ce6897462e1ae8e3cc7e3cd5f799b6c2213`; `CAMPAIGN_003_BRANCH_MANIFEST.md` blob `9b797b4d32fbab022e12d580e46b10f063f5690f`; encargo `campaigns/CAMP_003_W01.md` blob `b638d5525b0aec87dd730b5573a99cca53c0522e`; cola aprobada `CAMPAIGN_003_QUEUE_APPROVED.csv` blob `ea06a0a000fc4f3b8bab48e45e21fb549d753559`. No mezclar ramas CAMP001/002; el texto histórico que sigue NO es asignación vigente.

**Avance:** `01/10` bloque 01 publicado; siguiente bloque autorizado con otra `p` es **02**, IDs `blunder_policy;booster_energy;cell_battery`. Si CI FAIL, corregir solo test propio o STOP por problema compartido, nunca pasar a 02 bajo fallo real.
- **Bloque 01:** `air_balloon`, `assault_vest`, `binding_band`. Globo y Chaleco ya tienen CI histórica: registrar `YA_VERIFICADO_NO_DUPLICAR`; Banda tiene evidencia de residual `held_effect_sweep_v3.cjs`. No han sido reprogramados; hay **nuevas pruebas nativas** de integración y SaveV2 de los tres.
- **Archivos de prueba de esta campaña:** `tests/fixtures/parallel_items/w01_campaign_003.json` (7 escenarios, 10 pares-semilla, 30 variantes), `tests/gameplay/parallel_items_w01_campaign_003.gd`, `tests/tools/test_parallel_items_w01_campaign_003.py`. El CSV `reports/W01/CAMP_003_PROGRESO.csv` tiene una fila. Informe `reports/W01/CAMP_003_ITER_01.md`. Commits respectivos `36baab52`, `3ab97738`, `c374c1ed`, `f9316279`, informe `4e5900c0`.
- **Test del bloque:** `Native` usa motor `@pkmn/sim`; _fixture equipa con `FieldItemService`; controles activo/ausente/reserva, restricción Chaleco/PS Globo/trampa Banda, lectura y restauración SaveV2 con `_restore_probe`. Python fija cola, campos, hashes y contratos de la fixture. CI workflow por rama es propiedad de IA6.
- **Pruebas:** auditoría estática de blobs 16/16 PASS. Última CI al escribir [#41553771307](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41553771307), SHA `f9316279e97564f7b12ff71ad0692f572881afa2`: `EN_CI_AUTOMATICA`, sin PASS confirmado hasta revisar conclusión. Los runs intermedios sin progreso 01 solo certifican bootstrap. Godot headless no prueba interfaz/GPU, mapa, otros eventos.
- **Reglas siguientes:** cada `p` uno de los bloques 02..10 siguiendo fila exacta de cola/progreso. No inventar nuevos IDs, no modificar V28, main, PR #118, producción (`modules/`, `data/`, `config/`) ni otras W, ni tocar workflow/manifest. Después de 10/10 `CAMPAÑA_003_FINALIZADA` y STOP. IA4 no participa.

---

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
