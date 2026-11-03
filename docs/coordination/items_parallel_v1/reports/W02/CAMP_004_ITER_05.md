# IA2/W02 — CAMPAÑA_004 / MICROBLOQUE 05/10

**Rama exclusiva:** `codex/calvo-items-20261103-w02-camp004`. **Autoridad:** IA6, `CAMPAIGN_004_W02_GATE.md`, `CAMPAIGN_004_W02_QUEUE_APPROVED.csv` fila 05 y `campaigns/CAMP_004_W02.md`.  Se ha ejecutado exclusivamente bloque 05. No se modifica main, etiqueta V28, PR #118, workflows, catálogos ni ramas de otras trabajadoras.

**Estado:** `EN_CI_AUTOMATICA` / **no certificado por Godot**. Los nuevos casos son contratos y pruebas **publicados, no necesariamente superados**. Las herramientas GitHub disponibles no permiten listar los runs de push a la rama por SHA (la consulta del conector enumera exclusivamente runs de PR); por tanto ningún resultado CI de 02–05 se presume. Único PASS de CAMP004 confirmado: bloque 01 en [run #41573481223](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41573481223), Python 83/Godot 1022, con regresión CAMP003 Python 680/Godot 7306. Sin prueba visual/GPU ni integración global.

## Cuatro IDs de medicina — 20 escenarios × tres modos = 60 variantes previstas

| ID | Escenarios | Contrato nativo verificable |
| --- | ---: | --- |
| `energy_root` | 5 | Recupera hasta **120 PS** con tope máximo. Por amargor quita amistad 10 (tramo inferior a 200) o 15 (amistad inicial 200+). Pruebas amistad inicial 0, 100, 199 y 200, incluido suelo cero y recuperación truncada a 7 PS; PS completos se rechazan sin gasto ni pérdida de amistad |
| `ether` | 5 | Recupera **10 PP de una única ranura seleccionada** (scope `one`), no del otro movimiento. Probar primer/segundo movimiento, seleccionado lleno aunque otro vacío, rechazo sin indicar ranura y ranura inválida 99, sin consumos espurios |
| `fresh_water` | 3 | Recupera exactamente **30 PS** con máximo; media vida, sólo 7 PS ausentes y PS completos sin efecto ni consumo |
| `full_heal` | 7 | Cura estados persistentes y confusión: poison, badly_poisoned, sleep con limpieza de reloj, burn, confusión sola y combinación poison+confusion. Objetivo sano/no confundido rechaza sin consumir |

**Fuentes de verdad contrastadas en rama:** `modules/inventory/imported_recovery_v19.json`:
- `energy_root = {"heal":120,"friendship_loss":[10,10,15]}`
- `ether = {"pp":10,"scope":"one"}`
- `fresh_water = {"heal":30}`
- `full_heal = {"cure":"all","confusion":true}`

## Pruebas, propietarios y guardado

Todos los escenarios de campo usan `FieldItemService.use_item` y `FieldItemEffects.apply`. Se repiten en tres contextos: Pokémon en PARTY con 2 unidades de ítem; PARTY sin ítem; y Pokémon en STORAGE con 2 unidades. Controles de aceptación/rechazo, rechazo atómico, consumo de una unidad sólo tras efecto, identidad, ubicación, HP/PP/amistad, EV y otros estados no alterados, original sin mutación, SaveV2 decodificado y recibos JSON autenticados SHA256. Éter comprueba explícitamente la ranura `0` o `1`, mientras Elixir del bloque 04 conserva `scope=all` (regresión del runner); Raíz Energía se trata como `bitter_medicine`, no se oculta su pérdida de amistad.

**Rutas modificadas exclusivamente de W02:**
- `tests/fixtures/parallel_items/w02_campaign_004.json`, bloque 05 añadido en commit `38e83a85ab58421f5b39730936c9103f32740fbf`.
- `tests/gameplay/parallel_items_w02_campaign_004.gd`, parche limitado a scope un movimiento y raíz amarga en commit `aaf2881d4f82e396f5e6547b36734a9e5b9f251a`.
- `tests/tools/test_parallel_items_w02_campaign_004.py`, contrato exacto de 20 casos, perfiles nativos y 10 controles adversariales nuevos, commits `306b4cf56b5d16a26291ef7fc5994c1668d60173` y corrección de una referencia histórica inexacta a Agua Fresca `d2bb09d504f9e8e6351735d5303cfcbaa13f3184`.
- `docs/coordination/items_parallel_v1/reports/W02/CAMP_004_PROGRESO.csv`, quinta fila `EN_CI_AUTOMATICA`, commit `ff862ec7063841701ac2dbeb83d4c170eccea43b`.

**Acumulado publicado:** 5 microbloques, 20 IDs asignados, 81 escenarios (15+12+15+19+20), 243 variantes de prueba previstas. **No son 20 objetos funcionales certificados**: únicamente 01 de CAMP004 tiene CI verificada. Razz `razz_berry` sigue con DEPENDENCIA funcional registrada desde el bloque 02, y no se ha inventado un efecto para cumplir la cola.

## Próxima orden y condiciones de éxito

Al recibir otra `p`, revisar antes la CI real del HEAD y sus errores; se exige `CAMP004_W02_PY PASS blocks=5 checks=N` y `CAMP004_W02_GODOT PASS blocks=5 checks=M` con N/M positivos, además de `CAMP003_W02_PY/GODOT PASS blocks=10`, mismo SHA de pruebas. Si falla, diagnosticar y reparar en rama propia mediante V5 sin rebajar aserciones; escalación IA6 si exige cambio en API compartida. Tras ello ejecutar **únicamente bloque 06/10** (`full_restore;heal_powder;hopo_berry;hyper_potion`). STOP tras bloque 10 o si conflicto real.
