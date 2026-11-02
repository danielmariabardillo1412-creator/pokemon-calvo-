# IA5/W05 — CAMPAÑA_002 / ITER_03 · ampliación de MT y regresiones

**Estado al publicar: EN_CI_AUTOMATICA / no hay PASS de ITER_03 confirmado.** Microbloque 03 de 03 entregado; no existe permiso para una cuarta iteración.

## Autoridad y procedencia verificable
- Encargo: `campaigns/CAMP_002_W05.md` en rama `codex/calvo-items-20261101-arbitro`; operativa posterior `CI_AUTOPILOT_V3.md` y cabecera actual de `STATUS.md` en la misma rama.
- Rama exclusiva: `codex/calvo-items-20261102-w05-camp002`.
- Base de pruebas funcionales 02: Godot 4.7 **177 checks / 6 casos / 0 errores**, [CI propia #41539925530](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41539925530) `completed/success`, SHA `47909dce0c8331e8b7084233309ee36122b6572f`. Staging de IA6 [#41538151097](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41538151097) también PASS. **Ninguna de ellas prueba ITER_03.**
- Cambio de runner ITER_03: `tests/gameplay/parallel_items_w05_campaign_002.gd`, commit `0af3e48aa60508601e494a81fd3bf52ee668465a`. Este commit dispara el workflow automático de rama, cuya conclusión hay que comprobar sobre su SHA.

## Ensayos que el nuevo runner ejecutará en Godot
- Muestra deterministicamente hasta **12 IDs diferentes** y especies compatibles a partir de las 18 candidaturas de ITER_01; si no alcanzan, completa desde las MT **activas y seleccionadas** ordenadas por tipo, clase e ID, siguiendo la prioridad del selector Python, sin elegir máquinas no seleccionadas.
- Para cada pareja, usa exclusivamente `FieldItemService.teach`: falta de stock, criatura no perteneciente al propietario, incompatibilidad con especie y versión, consumo exacto 2→1, identidad/equipo, rechazo de doble enseñanza, PP correctos.
- Persistencia de cada caso por `SaveGameRepository.save_collection/load` (SaveV2) con identidad, movimiento, PP y stock verificados, borrando temporal `user://w05_camp002_iter03_temporal.json` y sus sufijos `.tmp/.bak`.
- Regresión de las **19 MACHINE seleccionadas sin mapeo scarlet-violet** mediante el mismo servicio en contexto legado negativo, comprobando rechazo explícito, que no se pierda stock/estado y que no se enseñe movimiento activo. No se activan MT/MO/DT históricas.
- Matriz generada en reporte con tres conjuntos **mutuamente excluyentes**: `probado_en_ensenanza` (objetivo 12), `solo_metadatos` (objetivo 217) y `legacy_negativos` (objetivo 19). Así se evita confundir las 229 etiquetas con enseñanzas realmente ejercitadas.
- Validadores duros: 248 seleccionadas, 229 activas, 19 legadas, muestra 12, 12 casos ejecutados, 217 solo metadatos, unicidad de IDs y ningún legacy entre enseñadas. Ante cualquier fallo Godot termina con código 2.
- Reporte aislado: `user://w05_camp002_iter03_reporte.json` con casos, errores, checks y matriz. No se escribe `res://`, archivos de producción, UI, datos ni guardados reales.

## Reproducción y límites
```bash
python -B -m unittest discover -s tests/tools -p 'test_parallel_items_w05_campaign_002.py' -v
python -B tests/tools/test_parallel_items_w05_campaign_002.py --report
godot --headless --path . --script res://tests/gameplay/parallel_items_w05_campaign_002.gd
```
Workflow ya instalado: `.github/workflows/parallel-camp002-worker-autoci.yml` (propiedad IA6, **no modificado**). Su filtro externo acepta 6+, pero la aserción **interna del runner exige 12**, de modo que una regresión a 6 da salida de error aun si el log parece válido.

**No se ha ejecutado Godot de ITER_03 en esta conversación.** Solo los seis casos ITER_02 y el selector Python de 12 tienen PASS previo verificado; 12 enseñanzas y 19 nuevos negativos están **pendientes de la nueva CI de SHA**. GPU, UI, arte libro y 229 enseñanzas exhaustivas quedan fuera del alcance.

**STOP: CAMPAÑA_002 03/03 publicada; no ITER_04, no CAMPAÑA_003.** IA6 revisará CI y consolidación, sin cambiar producción.
