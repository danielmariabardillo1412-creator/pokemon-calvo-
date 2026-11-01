# IA6 — Certificación de W05, CAMPAÑA_001 ITER_03 (2026-11-02)

**Fuente de los cambios:** rama `codex/calvo-items-20261101-w05` HEAD `2f7e2d32368916d7df01c13f8234ee24981d1bc4`. Único código nuevo de ITER_03: `tests/gameplay/parallel_items_w05_machine_books_v1.gd`, blob Git `10c1d7a7eeac79a83a2e9a1183f1c663aaf1955e`. Sin cambios en `modules/inventory/field_item_service.gd`, política de versiones, fuentes, sprites, selección, guardados ni ramas W.

## Validación CI directa
- [Actions #41364434498](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41364434498), SHA `83cb84fa25fbe3bd47bdfc0c35de298f953c0a7d`, staging `codex/calvo-items-20261102-w05-iter03-gate`: **completed/success** con Godot 4.7 headless.
- **W05: `W05 CAMP_001/03: 1083 comprobaciones, 0 errores`**. Verifica etiquetas previas (229 activas / 19 heredadas), y enseñanza por `FieldItemService.teach` para tm01, tm02 y tm77, PP, consumo unitario 2→1, propietario, rechazo atómico sin stock/con bloqueo/propietario incorrecto/movimiento repetido, SaveV2 y 19 máquinas históricas denegadas.
- Python `test_parallel_w05_machine_scope.py`: **14 tests PASS**; mapa comprobado 248=229 activas +19 heredadas. El solape `hm05`→`waterfall` / `tm77` permanece conforme a versiones y no habilita la MO heredada.
- Comando Godot y fixture exactos disponibles en el workflow efímero de staging `.github/workflows/w05-camp001-iter03-gate.yml`; no se incorpora ese workflow de staging a la rama árbitra.
- **Alcance:** evidencia funcional acotada sin GPU, inspección de UI, sprites, seis modelos de libro o combinatoria completa de especies y MT.

## Promoción a árbitra
El test nuevo se recibe como blob exacto `10c1d7a7eeac79a83a2e9a1183f1c663aaf1955e` y se actualiza simultáneamente la CI permanente `.github/workflows/parallel-items-w03-w05-verified.yml` para exigir etiqueta `CAMP_001/03` (antes `/01`) y no dejar falsos verdes. **Pendiente de CI sobre árbol integrado en el momento de la publicación.**

**W05:** microbloques 01, 02 y 03 entregados, `CAMPAÑA_001_FINALIZADA`, STOP. No autorizar `p`, ITER_04 ni CAMPAÑA_002. **W04:** 02/03, congelada por voluntad de la persona usuaria; no sustituirla ni modificar su rama. W01–W03: 03/03, STOP.
