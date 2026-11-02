# IA5 / W05 — CUADERNO ACTUAL · CAMPAÑA_002

## Autoridad y rama (2 de noviembre de 2026)

- **Identidad:** IA5/W05, familia MACHINE. **Nueva rama exclusiva:** `codex/calvo-items-20261102-w05-camp002`. Base verificada `67959eb8f19abfd2ae391872747a14f603fcab01`. **No trabajar en `codex/calvo-items-20261101-w05`.**
- **Puerta:** `CAMPAIGN_GATE_002.md` blob `ebc787803599e2b13cbd24c169b69112d18f7a42`; manifiesto `CAMPAIGN_002_BRANCH_MANIFEST.md` blob `bb9471862d3116b982f90e1867d512e278f801e0`; encargo `campaigns/CAMP_002_W05.md` blob `b085227766b28e9d4757cefb8d0cdb7c206967c4`, todo en rama árbitra.
- **Estado real:** ITER_01/03 **`PREPARADO_PENDIENTE_CI`**, sin Python/Godot de CAMP_002 ejecutado. Siguiente `p`: **solo ITER_02**, salvo FAIL o nueva orden central. IA6 hace CI y diagnóstico.
- **Código de producción:** ninguno modificado; todas las escrituras pertenecen exclusivamente a tests/fixture/reportes W05 de CAMP_002. `main`, V28, árbitra, W04 y ramas antiguas intactas.
- **Base anterior certificada:** las tres MT `tm01/tm02/tm77` ya tienen test individual en CAMP_001, [CI #41364601482](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41364601482) PASS; 229 etiquetas y rechazo de 19 heredadas no equivalen a 229 aprendizajes probados. No copiar pruebas antiguas.

## Entrega ITER_01

- **Fixture:** `tests/fixtures/parallel_items/w05_campaign_002.json`, commit `790e64769bc9670aac6a2392c052897bcf23c7a3`: 18 candidatos, uno por tipo, con movimientos físicos, especiales y estado. Objetivo exactamente 12 MT NUEVAS válidas, excluidas las 3 antiguas.
- **Generador/test:** `tests/tools/test_parallel_items_w05_campaign_002.py`, commit `cf83fb213ff362c47a3480e8d91b074f04577184`: lectura del censo, perfil, `data/normalized/pokemon_api.json` y política, empareja movimiento con especie por learnset real `machine/scarlet-violet`, descarta las incompatibles con motivo, rellena determinísticamente desde 229 activas y falla si no obtiene 12. Contiene 10 pruebas sintéticas + 1 con checkout real.
- **Informe y progreso:** `reports/W05/CAMP_002_ITER_01.md`, `reports/W05/CAMP_002_PROGRESO.csv`. Cotejo **ejecutado** contra map/CSV fuente: 248=229 activas+19 legacy, 18/18 candidaturas corresponden a ID/movimiento/tipo/clase; sin repetición de `tm01/tm02/tm77`. No inferir compatibilidad de especie individual de esa comprobación.
- **No ejecutado:** Python contra el JSON normalizado real (12 MB compactos), Python unittest del script nuevo, Godot 4.7, GPUs y pantalla de libro. `PREPARADO_PENDIENTE_CI` no equivale a funcionalidad probada.
- **Reproducción desde checkout:** `python -m unittest discover -s tests/tools -p 'test_parallel_items_w05_campaign_002.py' -v`, `python tests/tools/test_parallel_items_w05_campaign_002.py --report`. IA6 debe capturar las 12 parejas `item_id/move_id/type_id/species_id` reales, el descarte y SHA. Si hay menos de 12, documentar y STOP sin bajar umbral.

## Próximo microbloque 02 y límites

- **Solo con nuevo `p`:** runner Godot `tests/gameplay/parallel_items_w05_campaign_002.gd` parametrizado para al menos 6 parejas válidas de la muestra real. Reutilizar `FieldItemService.teach`; comprobar PP, gasto 1, pertenencia, rechazo sin stock/incompatibilidad y persistencia de instancia. No introducir procesos externos; usuario temporal `user://` y limpiar.
- **ITER_03 posterior a otro `p`:** ampliar a 12 si el catálogo lo permite, regresión SaveV2 / rechazo 19 heredadas sin copiar toda la suite de CAMP_001; finalizar y STOP.
- **Permisos de escritura:** únicamente `tests/gameplay/parallel_items_w05_campaign_002.gd`, `tests/tools/test_parallel_items_w05_campaign_002.py`, `tests/fixtures/parallel_items/w05_campaign_002.json` y `reports/W05/CAMP_002_ITER_01/02/03.md`, `CAMP_002_PROGRESO.csv`, `CAMP_002_FINAL.md`, `CONTINUIDAD.md`. No escribir ninguna otra ruta.
- **Prohibiciones:** 19 máquinas antiguas desactivadas, nada de `FieldItemService`, catálogo normalizado, fuentes, política de selección, reglas de Mega, arte/UI, guardados reales, workflows, CI, `main`, V28, PR #118, W04, ramas de otras IAs ni las antiguas 20261101.
- **Cuaderno histórico CAMP_001:** queda conservado en su rama original; no arrastrar sus informes a esta campaña. La autoridad actual es IA6 y este cuaderno no crea nuevos permisos.
