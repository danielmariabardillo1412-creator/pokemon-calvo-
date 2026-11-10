# IA6 — AUDITORÍA TANDA 01 W03/W04/W05 Y RELEVO TANDA 02 · 2026-11-10

## Evidencia consultada (verificados GitHub Actions y HEAD)
| W | Rama HEAD previa al relevo | CI código/reporte de cierre | Resultado funcional honesto |
|---|---|---|---|
| W03 | `d009f948e8f4390f2e00a69fa5d3cb48a21dec45` | [#42729137809](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42729137809) `completed/success` SHA `0114c3331d3d641569a0e967c111bb9836a6a572` | Diez filas auditadas, **0 nuevos efectos**, 5 bloqueadas, 1 parcial, 1 grupo previamente funcional y 3 QA. No subir bloques CAMP006 04–10 como funcionales. |
| W04 | `19246f6158874edf71d37d7fafed3af12833e102` | [#42729967922](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42729967922) `completed/success` SHA `3385011da12ed6f3d0d68a82c33348c7c23e17fc` | Diez filas auditadas, **0 cambios de forma/evoluciones/fusiones L3 nuevos**. 2 QA positivos de funciones anteriores; CAMP006 sigue `completed=3`. |
| W05 | `91c8b1803dd93e3ec5a6d68338c41f38fe3f8e4f` | [#42730140482](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42730140482) `completed/success`, HEAD documental posterior a código probado `fd6a04317b21d8afa15af43a25cbe777ae64c4f6` | Diez grupos **49/49 MT** con positivo real en panel aislado Godot headless. No implica imagen/GPU manual ni que W05 nuevo panel esté integrado en `FieldItemBag` final de IA6. |

Los tres runs tienen job `verify`, `completed/success`, sin pasos fallidos. Informes propios `reports/W03|W04|W05/AUTORUN_V1_FINAL.md`, progresos CSV y tickets. Los commits documentales posteriores no deben presentarse como nuevo código ejecutado.

## Decisión IA6 — no pagar 10 auditorías negativas por tanda
- **W03:** prioridad al único productor capturable y persistente con efecto claro de la lista: historial de capturas exitosas `caught_base_species_ids` → `Repeat Ball`. Diez pasos TANDA02, permiso excepcional restringido de agregados/SaveV2/captura en **su propia rama**; protegido `field_native_save._valid_creature` (IA6). Detalle vinculante [QUEUE_W03_TANDA_02.md](QUEUE_W03_TANDA_02.md).
- **W04:** prioridad al seam transversal `CreatureInstance.form_id` opcional y canónico → identidad y persistencia real; diez pasos TANDA02 y piloto real si existe fuente auténtica. Permiso restringido a `CreatureInstance`, Factory, `SaveGameData.validate` aditivo y `FieldNativeSave._valid_creature` para forma; **no** borrar fix IA6 de naturaleza efectiva. [QUEUE_W04_TANDA_02.md](QUEUE_W04_TANDA_02.md).
- **W05:** siguiente universo válido es **180 de 229 MT** `scarlet-violet`, excluyendo las 49 certificadas. Selección calculada de `modules/inventory/item_connections_v1.json::machine_rows` y `CAMPAIGN_006_W05_QUEUE_APPROVED.csv`, 10 grupos de **18 IDs exactos** (ninguna numeración inventada). [QUEUE_W05_TANDA_02.md](QUEUE_W05_TANDA_02.md). Panel propio, no FieldItemBag.

## Handoff directo y estado
IA6 ha sobrescrito `docs/coordination/items_parallel_v1/IA6_AUTORUN.md` en **cada una de las tres ramas W03/W04/W05** con la cola completa TANDA02; ninguna ventana necesita que el usuario pegue un nuevo prompt. Al recibir `p`, leer nota, reanudar primera fila pendiente y persistir checkpoint. No pedir autorización intra-tanda; no work en background implícito.

**Riesgo de integración consciente:** W03 y W04 usan seams diferentes de `SaveGameData` y `field_native_save.gd`, y IA6 ya cambió `_valid_creature` para naturaleza efectiva. **Prohibido merge automático entre ramas**. IA6 inspeccionará diffs y rehará la prueba conjunta antes de atribuir L3 en el árbol integrado. No se han modificado `main`, V28 ni PR118, ni integradas todavía las modificaciones de W03/W05 de sus ramas más recientes. Estas nuevas notas son órdenes, no CI de ejecución de TANDA02.

**Próximo aviso usuario:** basta «IA3 terminó la tanda 02»; IA6 verificará commits, CI y actualización de cola. Si encuentra solo informe de bloqueo, no asignará otra tanda idéntica: habrá que resolver el productor o cambiar la prioridad.
