# IA5/W05 — CAMPAÑA_002 · ITER_02 · enseñanza parametrizada Godot

**Estado: PREPARADO_PENDIENTE_CI.** El runner GDScript se ha publicado, **no se ha ejecutado Godot 4.7 en esta sesión**. La muestra Python del bloque 01 sí fue validada por IA6 en [Actions #41484879741](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41484879741); aquella prueba NO acredita estos casos de enseñanza.

- Rama de escritura exclusiva: `codex/calvo-items-20261102-w05-camp002`. Punto de partida verificado por relevo IA6: `16b4b6ec4f595cbb0306cec68dba7b0b6f18365a`.
- Runner nuevo: `tests/gameplay/parallel_items_w05_campaign_002.gd`, commit `61caf12770e0d70c6d0d41dc0e6d5402596429cd`.
- Reutiliza el fixture CAMP002 ITER01 (18 candidatos y fuente de IDs), el catálogo de especies normalizado y el perfil SV; encuentra determinísticamente la primera especie permitida con learnset machine/SV para seis IDs distintos. Verifica mapeo exacto, tipo, política, y no usa `tm01/tm02/tm77`.
- Para cada pareja, llama al **servicio existente** `FieldItemService.teach` sin modificarlo. Comprueba falta de stock, Pokémon no perteneciente al propietario, especie propia incompatible con contexto SV, enseñanza, movimiento, PP actual/máximo, gasto exacto 2→1, identidad/equipo y segundo uso sin consumo.
- Guarda y vuelve a cargar cada caso mediante `SaveGameRepository.save_collection/load` (SaveV2), verifica instancia, PP/movimiento y cantidad de MT; limpia `user://w05_camp002_iter02_temporal.json` y sus temporales `.tmp/.bak` después de cada caso. El reporte de la ejecución se escribe solo en `user://w05_camp002_iter02_reporte.json`.
- No modifica producción, datos canónicos, arte/UI, otras ramas ni las 19 máquinas históricas. **Sin captura GPU.**
- **Para IA6 CI:** `godot --headless --path . --script res://tests/gameplay/parallel_items_w05_campaign_002.gd` y revisar exit code, stdout, stderr y reporte. Fallo de parseo Godot, selección menor de seis o alguna aserción = **FAIL**, no fingir PASS ni lanzar ITER03.
- La prueba de seis candidatos es independiente del censo de 12 creado por Python; comparar los `item_id/species_id` del reporte con el `--report` Python de ITER01 en la integración. Si hay divergencias de criterio, abrir bloqueo para IA6.
- No se ha ejecutado prueba Python/Godot de esta nueva iteración: **PREPARADO_PENDIENTE_CI**. La validación funcional corresponde exclusivamente a IA6.

**STOP tras ITER02.** No iniciar ITER03 sin nueva puerta de IA6.
