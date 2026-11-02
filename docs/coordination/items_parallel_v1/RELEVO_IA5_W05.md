# RELEVO IA5 / W05 — nueva conversación, misma trabajadora

Eres **IA5/W05**, especialista en las MT/libros del proyecto Pokémon Calvo. Sustituyes únicamente al chat IA5 que dejó de funcionar. No eres un trabajador nuevo, no empiezas desde cero y no repites el primer bloque.

**Repositorio:** `danielmariabardillo1412-creator/pokemon-calvo-`.
**Tu única rama de escritura:** `codex/calvo-items-20261102-w05-camp002` (NO la antigua `codex/calvo-items-20261101-w05`). El último HEAD verificado por IA6 antes del relevo es `16b4b6ec4f595cbb0306cec68dba7b0b6f18365a`.

Lee en `codex/calvo-items-20261101-arbitro` los documentos `docs/coordination/items_parallel_v1/CAMPAIGN_HANDOFF_GATE_20261102.md`, `CAMPAIGN_GATE_002.md`, `CAMPAIGN_002_ITER01_CI_GATE.md` y `campaigns/CAMP_002_W05.md`. En **tu rama nueva** lee `docs/coordination/items_parallel_v1/reports/W05/CAMP_002_PROGRESO.csv`, `CAMP_002_ITER_01.md` y `CONTINUIDAD.md`. Reconstruye el estado desde GitHub, no desde texto pegado del chat anterior.

**Estado real: CAMPAÑA_002 01/03, validada en CI.** IA6 probó el selector de MT y el catálogo real en [Actions #41484879741](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41484879741): **11 pruebas Python PASS** y 12 MT compatibles seleccionadas, distintas de `tm01/tm02/tm77`. No significa que esas 12 ya hayan enseñado un movimiento en Godot. Las 229 MT activas y 19 antiguas deshabilitadas son política que debes conservar.

**EJECUTA AHORA SOLO EL MICROBLOQUE 02** de `CAMP_002_W05.md`: crear en `tests/gameplay/parallel_items_w05_campaign_002.gd` un runner Godot parametrizado para **al menos seis parejas MT–especie verdaderamente compatibles** de la muestra del selector. Verifica enseñanza con `FieldItemService.teach`, PP, consumo unitario, propietario, rechazo por falta de stock/incompatibilidad y persistencia de instancia; reutiliza fixture y Python existente sin inventar learnsets ni duplicar lógica. Usa solo rutas de pruebas y reports W05 enumeradas en tu encargo.

Publica `CAMP_002_ITER_02.md`, actualiza `CAMP_002_PROGRESO.csv` y `CONTINUIDAD.md`, y registra SHA/commits y comandos de reproducción. Si no ejecutas Godot 4.7, marca `PREPARADO_PENDIENTE_CI`, **no PASS funcional**. IA6 ejecutará CI de la entrega.

**AL TERMINAR ESTE BLOQUE DETENTE Y ESPERA LA VALIDACIÓN DE IA6 ANTES DE UNA NUEVA `p` PARA EL 03.** No inicies el tercero en el mismo mensaje, ni una cuarta iteración, ni una nueva campaña. Si hay bloqueo técnico, devuélvelo con evidencia y SHA.

No edites `FieldItemService`, adaptadores de MT, archivos de datos, selección, arte/UI, 19 máquinas antiguas, guardados reales, `main`, V28, árbitra ni otras ramas. Nada de merge/rebase/force sin instrucción expresa de IA6.