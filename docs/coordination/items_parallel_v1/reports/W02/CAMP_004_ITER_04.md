# IA2/W02 — CAMPAÑA_004 | MICROBLOQUE 04 DE 10

**Rama propia:** `codex/calvo-items-20261103-w02-camp004`. **Autoridad:** `CAMPAIGN_004_W02_GATE.md`, fila 04 de `CAMPAIGN_004_W02_QUEUE_APPROVED.csv`, `campaigns/CAMP_004_W02.md` de IA6; reparación autónoma V5. No cambiar otras ramas, `main`, V28 ni PR #118.

**Estado:** `EN_CI_AUTOMATICA`. Se publicaron fixture, validador Python, runner Godot, controles y progreso. **No se declara PASS de este bloque ni de 02/03**: el conector GitHub devuelve `[]` al consultar runs asociados a commits de push porque esa consulta se limita a eventos PR; no se dispone de un run ID verificado de 02–04. No interpretar `[]` como éxito, fracaso o inexistencia de CI. El bloque 01 sí tiene recibos reales en [run #41573481223](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41573481223): CAMP004 Python 83, Godot 1022 y regresión CAMP003 Python 680, Godot 7306.

## Fila 04: 4 ID / 19 escenarios × 3 modos = 57 variantes preparadas

| Objeto | Escenarios | Contrato nativo / negativos |
| --- | ---: | --- |
| `burn_heal` | 4 | Cura solo quemadura `burn` y limpia estado; poison, sueño y sano deben rechazarse sin consumir ni mutar |
| `casteliacone` | 6 | Cura quemadura, envenenamiento grave, sueño y confusión; limpia sueño/reloj y casos combinados; sano debe rechazarse sin consumir |
| `elixir` | 4 | Recupera **10 PP en cada uno de dos movimientos** con límite por máximo; si uno está lleno sólo afecta al otro, ambos llenos sin efecto, pasar índice de movimiento a medicina `scope=all` se rechaza atómicamente |
| `energy_powder` | 5 | Recupera **60 PS** con límite máximo y amargor: amistad 100→95, 200→190, 0→0; al faltar solo 7 PS cura 7, amistad 199→194; PS completos = rechazo sin pérdida de amistad ni gasto |

**Contrato pinneado:** `modules/inventory/imported_recovery_v19.json` representa exactamente `burn_heal:{cure:[brn]}`, `casteliacone:{cure:all,confusion:true}`, `elixir:{pp:10,scope:all}` y `energy_powder:{heal:60,friendship_loss:[5,5,10]}`. Efectos de campo mediante `FieldItemService.use_item` / `FieldItemEffects.apply` existentes. No se ha duplicado ni reescrito producción.

**Cobertura diseñada:** tres situaciones por caso: con objeto y Pokémon en equipo; sin objeto; con objeto y Pokémon almacenado. Aceptación/rechazo, identidad, bolsa antes/después, estados/contadores, dos ranuras de PP, PS y amistad, EV preservados, original sin mutación, decodificación SaveV2 y recibo de evidencia SHA256. Para Energy Powder se exige acción `bitter_medicine`, no tratarla como medicina sin amargor.

## Commits y rutas de esta iteración

- Fixture `tests/fixtures/parallel_items/w02_campaign_004.json`, commit `2d804bebc55a8c20f396d762bd7d3acd3445df0b`.
- Runner `tests/gameplay/parallel_items_w02_campaign_004.gd`, commit `1e488420a421fc0eb998427631ce863385495a66`.
- Python `tests/tools/test_parallel_items_w02_campaign_004.py`, commit `34b384dceaf8e6a97dedb5d1f7854b1b7e3fdb8a`; contrato independiente de 19 escenarios y controles adversariales sobre efectos/IDs/amistad/PP.
- Progreso `docs/coordination/items_parallel_v1/reports/W02/CAMP_004_PROGRESO.csv`, commit `14ddaca6c00a19cf2b2ec380d88fe3df96aa5b3c`.
- Informe presente `CAMP_004_ITER_04.md`; cuaderno `CONTINUIDAD.md` actualizado por separado.

**Acumulado publicado:** bloques 01–04, 16 IDs, 61 escenarios y **183 variantes previstas**; no equivale a 16 objetos certificados. Razz del bloque 02 sigue con **dependencia de diseño**: las pruebas negativas no sustituyen funcionalidad positiva. Los bloques 02–04 no tienen PASS de CI consultable en este informe.

## Pendientes, siguiente tecla y restricciones

1. Acceder al run de GitHub Actions correspondiente al HEAD con bloque 04; verificar recibos **`CAMP004_W02_PY PASS blocks=4 checks>0`**, **`CAMP004_W02_GODOT PASS blocks=4 checks>0`**, y regresión completa `CAMP003_W02_PY/GODOT PASS blocks=10` con SHA coincidente.
2. Si aparece fallo de script/fixtures/servicio propio, corregir en W02 según V5 sin rebajar expectativas ni contaminar funciones ajenas. Si choque de API compartida, escalar a IA6.
3. GPU/interfaz, integración global y funcionalidades de Razz no verificadas.
4. **Siguiente `p`:** revisar primero CI y, si procede, ejecutar **solo el bloque 05** con `energy_root;ether;fresh_water;full_heal`. Nunca comenzar un bloque 06 por la misma orden.

**Cambios sobre producción, workflows, main, V28 y otras ramas:** ninguno.
