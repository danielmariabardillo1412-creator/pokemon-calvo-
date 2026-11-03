# IA2/W02 — CAMPAÑA_004 / MICROBLOQUE 07/10

**Rama de escritura:** `codex/calvo-items-20261103-w02-camp004` (exclusiva W02). **Encargo:** `CAMPAIGN_004_W02_QUEUE_APPROVED.csv`, fila 07, bajo gate de IA6 `CAMPAIGN_004_W02_GATE.md`, `campaigns/CAMP_004_W02.md`, autonomía `AUTONOMOUS_REPAIR_V5.md`. **Solo se publica fila 07.** No se modifican `main`, V28, PR #118, rama árbitra, otras trabajadoras, producción, arquitectura ni workflows.

## Ítems y criterios: 4 IDs, 22 escenarios × 3 modos = 66 variantes diseñadas

| ID | Casos | Contrato nativo y controles positivos/negativos |
| --- | ---: | --- |
| `ice_heal` | 5 | **Congelación** `freeze` curada; confusión simultánea debe **permanecer**; `poison`, `burn` o Pokémon sano no producen efecto ni consumo |
| `lava_cookie` | 7 | Cura quemadura, tóxico, sueño (incluyendo reloj), congelación, confusión y veneno+confusión; sano se rechaza |
| `lemonade` | 4 | Recupera **70 PS** desde media vida, o sólo PS faltantes cuando quedan 7 para el máximo; PS completos rechazan; envenenamiento concomitante permanece |
| `lumiose_galette` | 6 | Cura veneno, tóxico, sueño (incluyendo reloj), confusión y veneno+confusión; sano se rechaza |

**Fuentes de datos reales:** `modules/inventory/imported_recovery_v19.json`: `ice_heal:{cure:[frz]}`, `lava_cookie:{cure:all,confusion:true}`, `lemonade:{heal:70}`, `lumiose_galette:{cure:all,confusion:true}`, con `consume:true` en las cuatro entradas. `modules/inventory/field_item_effects.gd` mapea `frz→freeze`, cura estados/confusión y recupera PS mediante los métodos del Pokémon; `tests/gameplay/item_field_effects_v4.gd` conserva la regresión previa explícita de Antihielo. **No se atribuyen** casos antiguos de Galleta Lava, Limonada o Galette Luminalia cuando no figuran en ese test histórico.

**Arnès de ejecución:** `tests/gameplay/parallel_items_w02_campaign_004.gd` ya despacha `field_medicine` con `FieldItemService.use_item` nativo; no necesita código de producción ni modificaciones para estos cuatro ítems. Se prueban tres contextos por caso: `active` (Pokémon PARTY y 2 unidades de ítem), `none` (PARTY sin ítem), `reserve` (STORAGE con 2 unidades), con aceptación/rechazo, cantidad de bolsa, dueño, estado persistente y confusión, PP/HP/amistad/EV no contaminados, serialización SaveV2 y recibos JSON/SHA256.

**Integridad del contrato Python:** `tests/tools/test_parallel_items_w02_campaign_004.py` guarda una copia independiente y exacta de los 22 escenarios, comprueba los cuatro perfiles y rutas nativas, y añade 13 mutaciones adversariales sobre IDs, casos, fuentes, curación de estado, confusión, PS70, rechazo y reloj de sueño. No se retiran pruebas de bloques 01–06 ni la regresión de CAMP003.

## Commits en GitHub

- `tests/fixtures/parallel_items/w02_campaign_004.json`: bloque 07 con 22 casos, commit `28e8e4e7cb2790dd44c9801d65c9f578656a30ff`.
- `tests/tools/test_parallel_items_w02_campaign_004.py`: 22 contratos y 13 negativos, commit `d109e4b008a41fb2496911a21ed6956d4f5eaa29`.
- `docs/coordination/items_parallel_v1/reports/W02/CAMP_004_PROGRESO.csv`: nueva fila 07 `EN_CI_AUTOMATICA`, commit `7c02e7ea1dd7c2a94a4d2d920c26f13a2d3cda36`.

## Qué está certificado y qué no

**Publicado acumulado:** bloques 01–07 = 28 IDs, 123 escenarios y 369 variantes **diseñadas para ejecutarse**. No equivale a 28 ítems certificados.

**CAMP004 bloque 01:** CI realmente confirmada como `completed/success` en GitHub Actions [#41573481223](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41573481223) (`CAMP004_W02_PY PASS blocks=1 checks=83`, `CAMP004_W02_GODOT PASS blocks=1 checks=1022`, regresión CAMP003 10/10 con checks Python 680/Godot 7306). **Bloques 02–07:** publicados pero **sin prueba de CI verificable**; las herramientas disponibles filtran runs por PR y no retornan los de push, y la consulta pública de Actions quedó bloqueada. Ni PASS ni FAIL se presumen. Si la CI detecta errores, reparar solo nuestra rama conforme a V5, sin rebajar las expectativas.

**Dependencias registradas:** `razz_berry` (bloque 02) y `hopo_berry` (bloque 06) solo tienen evidencia negativa de falta de efecto funcional; requieren decisión técnica de IA6. No inventar efectividad de captura/PP para completar el catálogo. Integración global y GPU/UI aún no verificadas.

## Continuación

Con la siguiente `p`, buscar y comprobar el resultado de GitHub Actions para el HEAD 07 y exigir `CAMP004_W02_PY/GODOT PASS blocks=7` y regresión `CAMP003_W02_PY/GODOT PASS blocks=10`, con SHA y logs reales. Si hay fallos de nuestra especialidad, repararlos. Como máximo **ejecutar fila 08**: `max_elixir;max_ether;max_potion;moomoo_milk`. No iniciar 09 sin nueva instrucción.
