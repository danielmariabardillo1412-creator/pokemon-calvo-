# IA2/W02 — CAMPAÑA_004 | BLOQUE 06/10

**Autoridad vigente:** IA6 `CAMPAIGN_004_W02_GATE.md`, fila 06 `CAMPAIGN_004_W02_QUEUE_APPROVED.csv`, `campaigns/CAMP_004_W02.md` y reparación V5. **Rama exclusiva:** `codex/calvo-items-20261103-w02-camp004`. Se ha publicado solo el bloque 06, sin modificar producción, `main`, V28, ramas ajenas, catálogos ni workflow.

## Resultado de trabajo: 4 IDs / 20 escenarios × 3 variantes de propiedad = 60 variantes PREPARADAS

| ID | Escenarios | Comportamiento sometido a prueba |
| --- | ---: | --- |
| `full_restore` | 6 | Recupera HP hasta máximo y/o elimina estado persistente + confusión. Se cubren media vida+veneno+confusión, sueño (con reloj), quemadura con HP completo, media vida sin estado, confusión con HP completo y rechazo sano con HP completo |
| `heal_powder` | 7 | Cura estados/confusión, reduce amistad si tuvo efecto: **-5** (<200) o **-10** (≥200); amistad no baja de 0. Se cubren veneno, sueño, confusión, estado combinado, amistad inicial 0/100/199/200 y rechazo sin pérdida ni consumo |
| `hopo_berry` | 3 | **DEPENDENCIA — SIN CONTRATO FUNCIONAL CONECTADO.** Se exige rechazo atómico al usarla en bolsa, HP/status/PP/stock intactos. No simular curación de PP ni declarar PASS funcional; ver fuentes |
| `hyper_potion` | 4 | Recupera **120 PS** sin curar estado; media vida, recuperación limitada al máximo, HP completo sin efecto y un objetivo envenenado al que sólo cura PS |

Los tres modos de cada caso son `active` (PARTY con dos unidades), `none` (PARTY sin ítem), `reserve` (STORAGE con dos unidades). El runner llama a `FieldItemService.use_item` y `FieldItemEffects.apply`, y verifica aceptación/rechazo, transacción, dueño, inventario, PP, EV, amistad, HP, estados, guardado SaveV2, identidad y recibos SHA256. Las pruebas nuevas se integran acumulativamente con los bloques 01–05; las 10 filas anteriores de CAMP003 mantienen su workflow de regresión independiente.

### Dependencia funcional confirmada: Hopo Berry

En `modules/inventory/imported_recovery_v19.json`, no existe `hopo_berry`. El registro importado `data/api/v2/item/2278/index.json` sólo aporta categoría `pp-recovery` y `effect_entries: []`; **no documenta magnitud, selección, consumo en batalla o condiciones de activación**. `docs/current/ITEM_FIELD_V8.csv.txt` ya la clasifica `FIELD_USE_NOT_CONNECTED`, `NOT_CERTIFIED`. Por tanto no hay base técnica para crear un efecto por analogía con Leppa o Éter. **Requiere decisión de IA6** (contrato adicional/retirada de alcance). El negativo prueba que no se aplica ni consume, pero no certifica la funcionalidad. Se mantiene también la dependencia previa de `razz_berry` del bloque 02.

## Commits de bloque 06

- `tests/fixtures/parallel_items/w02_campaign_004.json`, 20 escenarios explícitos, commit `cfcfd451bd4fb4478c57d08229d5c09961d46296`.
- `tests/gameplay/parallel_items_w02_campaign_004.gd`, `heal_full`, amargor de `heal_powder` y negativos de `hopo_berry`, commit `bd251617fa51af00e30d3021ec1659c619931ed1`.
- `tests/tools/test_parallel_items_w02_campaign_004.py`, golden independiente de los 20 escenarios, perfiles, datos de Hopo y 10 mutaciones adversariales, commit `1532cbd2cc16d1d2f7772747c2c447d55cdd32f0`.
- `docs/coordination/items_parallel_v1/reports/W02/CAMP_004_PROGRESO.csv`, fila 06 publicada, commit `f2f427848f9bc1c4790ad452e1157d4e1821f88a`.

## Estado CI: NO CONFUNDIR PUBLICACIÓN CON VALIDACIÓN

**CAMP004 W02 01:** run [#41573481223](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41573481223) terminado `completed/success`; Python `blocks=1 checks=83`, Godot `blocks=1 checks=1022` y regresión CAMP003 `blocks=10`, Python 680, Godot 7306.

**CAMP004 W02 02–06:** pruebas subidas a GitHub, **sin CI verificada**. Las consultas GitHub disponibles de `fetch_commit_workflow_runs` sólo incluyen runs disparados por PR; no resultan adecuadas para enumerar los runs por push de la rama. La consulta pública por URL de GitHub Actions tampoco estuvo accesible desde el entorno de consulta. Que un commit exista no prueba que Godot lo haya ejecutado, importado o aprobado.

**Acumulado publicado:** 6 microbloques, 24 IDs, 101 escenarios y 303 variantes de ejecución definidas. No son 24 objetos completados/validados. Dos dependencias en esta campaña: `razz_berry` y `hopo_berry`.

## Próxima tecla `p`

Localizar run real y validar sobre el SHA actual: `CAMP004_W02_PY PASS blocks=6 checks=N`, `CAMP004_W02_GODOT PASS blocks=6 checks=M`, `CAMP003_W02_PY/GODOT PASS blocks=10`, con N/M positivos. Si falla, reparar exclusivamente pruebas/funciones W02 según V5, sin retirar negativos ni rebajar esperados; si necesita función compartida, coordinar con IA6. Ejecutar **sólo bloque 07** autorizado: `ice_heal;lava_cookie;lemonade;lumiose_galette`. La UI y GPU siguen pendientes de pruebas en el PC.
