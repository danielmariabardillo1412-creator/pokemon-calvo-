# IA2/W02 — CAMPAÑA_004 / MICROBLOQUE 01 DE 10

**Rama exclusiva:** `codex/calvo-items-20261103-w02-camp004`. **Estado:** `EN_CI_AUTOMATICA`. Contratos publicados, no dar PASS funcional hasta recibir recibos reales Godot y Python del mismo SHA. **Autoridad:** `CAMPAIGN_004_W02_GATE.md`, `CAMPAIGN_004_W02_QUEUE_APPROVED.csv`, `campaigns/CAMP_004_W02.md`; V5 permite reparar sólo familia propia. La cola no autoriza bloque 02 hasta una nueva `p`.

## Cuatro IDs exactos, 15 escenarios reales

| ID | Escenarios (propiedad: activo/ausente/reserva; para campo: equipo con item/equipo sin item/almacén con item) | Ruta canónica |
|---|---|---|
| `figy_berry` | 3: Mew `modest` (rechaza picante) / `hardy`, recibe `Endeavor` de Snorlax con 1 PS; la baya debe curar exactamente `floor(maxHP/3)` y confundir sólo en `modest`. Con PS altos, no dispara | Combate equipado real `@pkmn/sim`, verificadores de sabor y checkpoint/SaveV2 heredados de W02 CAMP003 |
| `kelpsy_berry` | 3: EV Ataque 20→10 y amistad 100→105; EV=0 amistad=200→202; EV=0 amistad=255 rechazo atómico sin gasto | `FieldItemService.use_item` y `_ev_berry` reales; equipo/PC/bolsa/SaveV2; misma clase de prueba real certificada en CAMP003 para otras bayas EV |
| `leppa_berry` | 4: PP 0→10, PP 3→13, PP máximos sin efecto, índice de movimiento ausente rechazado. Guardar PP, estado y una unidad de bolsa | `imported_recovery_v19.json`: `pp:10,scope:one`; uso real de campo en `FieldItemService`. El precedente de Leppa equipada está en `held_effect_sweep_v3.cjs`, sin atribuir todavía certificado de modalidad equipada a esta suite |
| `lum_berry` | 5: equipada cura estado persistente `poison` y consume; equipada sin estado retiene; en campo cura `poison` y confusión, sin estado/confusión rechaza sin consumir | Combate `@pkmn/sim` + uso real de campo con `imported_recovery_v19.json` (`cure:all,confusion:true`), FLED sólo para combate |

**Método:** 15 casos × tres modos de propiedad = **45 variantes**. Cada caso se ejecuta contra servicio real de inventario/batalla según el tipo, control de dueño, rechazo sin mutación, una unidad de stock cuando el efecto se aplica, preservación de otros PP/EV/amistad/PS, guardado `SaveGameRepository.decode_snapshot` (SaveV2), y recibo JSON/SHA256. El runner nuevo hereda sólo helpers verificados de `tests/gameplay/parallel_items_w02_campaign_003.gd`: **no ejecuta CAMPAÑA_003 en lugar de CAMPAÑA_004**. La regresión íntegra CAMP003 se ejecuta después, en el workflow dedicado, sin modificar ninguna prueba antigua.

**Ficheros nuevos y modificaciones limitadas a W02:**
- Fixture `tests/fixtures/parallel_items/w02_campaign_004.json`: `6ab8d1b9cb563c8925dcbac9072a0761ad250921`.
- Runner Godot `tests/gameplay/parallel_items_w02_campaign_004.gd`: `61d2162d85ab1f144c9c819052dcdfa0919aa903`.
- Validador Python `tests/tools/test_parallel_items_w02_campaign_004.py`: `30d8e8293b837f7bd1f42feff84d5e7aa462eacf`, corrección de override de naturaleza/foe `9af8486c1ea2a5fa677d64f28b0c18ade3107d2e`.
- Progreso `docs/coordination/items_parallel_v1/reports/W02/CAMP_004_PROGRESO.csv`: fila 01, `4fc799c5a7ef6d2705ef598864cdac93bab4d486`.

## Semáforo de CI

Bootstrap [#41572529404](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41572529404) `success` con 0 bloques: **NO es prueba funcional**.

**CI funcional abierta:** [Actions #41573481223](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41573481223), SHA de tests/progreso `4fc799c5a7ef6d2705ef598864cdac93bab4d486`. Se requieren recibos **`CAMP004_W02_PY PASS blocks=1 checks=N` y `CAMP004_W02_GODOT PASS blocks=1 checks=M`**, más `CAMP003_W02_PY/GODOT PASS blocks=10` de regresión, ambos con N/M positivos. Mientras no se tengan los cuatro, mantener `EN_CI_AUTOMATICA` y reparar propios si hay errores. Los workflows previos con 0 bloques no cubren los 15 casos.

**Límites reconocidos:** no se verifican las 40 IDs futuras, el modo de Leppa equipada en combate queda amparado por precedente histórico pero no nuevo recibo de este bloque, origen de amistad especial no certificado, sin GPU ni inspección visual. No hay cambios en `main`, V28, W01/W03/W04/W05, la árbitra, producción, catálogo ni workflow.

**Próxima `p`:** exactamente bloque **02/10**, `qualot_berry;razz_berry;sitrus_berry;tamato_berry`, revisando CI 01 primero. Si error funcional de otra familia o edición concurrente de API compartida, escalar a IA6, nunca editar rama ajena.
