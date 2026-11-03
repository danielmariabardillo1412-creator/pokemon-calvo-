# W04 CAMPAÑA_003 — ITER_03

**Fecha:** 2026-11-03. **Estado:** EN_CI_AUTOMATICA, no certificado todavía en Godot.

## Orden y estado anterior
La revisión oficial de IA6 `CAMPAIGN_003_W04_ITER02_REVIEW.md` autoriza la iteración 03. CI previa [#41556682246](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41556682246): completed/success, Python 29 checks y Godot 54 checks sobre SHA `75d50b9918660bf051132be6150fc44ae0a5d4b0`. La dependencia de `oval_stone` sigue abierta, sin bloquear este grupo.

## Tres IDs autorizados
- `dragon_scale`
- `dubious_disc`
- `electirizer`

## Pruebas acumuladas
- `tests/fixtures/parallel_items/w04_campaign_003.json`: añade bloque 03 sin modificar filas previas (commit `5fa98639326a1338be6623c76bb1d0d15f5b427e`).
- `tests/gameplay/parallel_items_w04_campaign_003.gd`: inspecciona catálogo activo, trigger real, condiciones y clasificación con `EvolutionSystem.classify_record`. Si hay ruta `use_item` RUNTIME_SUPPORTED, ejecuta comprobaciones positivas, rechazos, gasto, identidad y SaveV2. Si el único contrato es condicionado (intercambio/objeto equipado u otro), exige rechazo de uso directo y snapshot de inventario/propietario idéntico (commit `21a7821a947fbe9b17b02cb56f2efc25159981af`).
- `tests/tools/test_parallel_items_w04_campaign_003.py`: exige fila 03, fixture y presencia de aserciones sobre rechazo condicionado; emite recibo `CAMP003_W04_PY PASS blocks=3 checks=M` solo al ejecutarse y pasar (commit `5cd61817ec494e3092c9e2c0a2632a3a068b92e7`).

**Importante:** un `CAMP003_W04_GODOT PASS` del runner con dependencias no equivale a soporte funcional de intercambio. No se ha programado ningún trigger ni asumido que portar un objeto equivale a usarlo.

## Verificación y seguimiento
- Python en el checkout: SIN_EJECUTAR aquí.
- Godot 4.7 para el nuevo bloque: SIN_EJECUTAR aquí.
- CI automática: disparada por cambios en pruebas/progreso; **resultado aún no consultado ni certificado**.
- La única escritura se limita a fixture, GDScript, validador, informe y progreso propios. No se han editado archivos de producción, SaveV2, V28, `main`, política, catálogos ni ramas ajenas.
- Si la CI informa fallo funcional o de contrato, escalar con logs a IA6. Si queda queued/in_progress, el siguiente bloque independiente puede prepararse cuando se solicite `p`, sin declarar PASS anticipado.
