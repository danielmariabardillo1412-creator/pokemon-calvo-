> **CI DEFINITIVA VERIFICADA — BLOQUE 04/10 (2026-11-03):** [GitHub Actions #41720191745](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41720191745), SHA funcional `fc87f105b9f5b979d7f5dc6f0f73f5b026dbca48`, job `126210891293`, `completed/success`. Recibos reales de log: `CAMP005_W05_MANIFEST_PASS reserved=10 completed=4 ids=60 kind=NEW_IDS`, `CAMP005_W05_PY PASS blocks=4 checks=232`, `CAMP005_GATE_PY_PASS worker=W05 blocks=4 checks=232`, `CAMP005_W05_GODOT PASS blocks=4 checks=876`, `CAMP005_GATE_GODOT_PASS worker=W05 blocks=4 checks=876`. **24/24 MT de CAMP005 cubiertas por pruebas funcionales headless.** Las regresiones completas CAMP004/003 no se ejecutaron en este bloque por política del workflow; deben ejecutarse en el siguiente hito 05/10. Este veredicto posterior prevalece sobre notas históricas inferiores de CI pendiente. Sin modificaciones de producción ni rebaja de aserciones.

# IA5/W05 — CAMPAÑA_005 · ITER_04/10

**Estado de publicación: EN_CI_AUTOMATICA.** No se atribuye PASS funcional hasta verificar el run y recibos Python/Godot.

## Mandato IA6 y asignación

Rama exclusiva `codex/calvo-items-20261103-w05-camp005`; autoridad `CAMPAIGN_005_W05_GATE.md`, `CAMPAIGN_005_W05_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W05.md` y `AUTONOMOUS_REPAIR_V5.md`, en rama árbitra.

| MT | Movimiento Scarlet/Violet |
| --- | --- |
| `tm160` | `hurricane` |
| `tm161` | `trick_room` |
| `tm162` | `bug_buzz` |
| `tm163` | `hyper_beam` |
| `tm164` | `brave_bird` |
| `tm165` | `flare_blitz` |

Los seis pares corresponden al mapeo SV de `modules/inventory/item_connections_v1.json` y a la fila 04 aprobada.

## Commits y calidad
- `tests/fixtures/parallel_items/w05_campaign_005.json`: añadido exclusivamente bloque 04, sin alterar 01–03. Commit `f01eb2223d6b5e44a8f55b58c049bf7a9d08e05b`.
- `docs/coordination/items_parallel_v1/reports/W05/CAMP_005_PROGRESO.csv`: añadida una fila 04, commit `fc87f105b9f5b979d7f5dc6f0f73f5b026dbca48`, que activa CI.
- Control estático posterior en GitHub: **4 bloques, 4 filas, 24 MT únicas**, seis por bloque, sin desviaciones del orden, IDs ni movimientos respecto al perfil y cola IA6.
- Tests Python y Godot acumulativos CAMP005 conservados: mapeo y política SV, especies con learnset real, tipo/clase/PP, `FieldItemService.teach`, positivos y negativos de compatibilidad/stock/propietario, consumo, identidad, rechazo de movimiento ya conocido y SaveV2. No se tocaron ejecutores ni producción. El cotejo estático no sustituye a la CI funcional.

## CI y regresiones
- Bloques 01–03 certificados en [Actions #41719102271](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41719102271): `completed/success`, SHA `245b77936642d59990cde21471c86c2c5491dd7f`, Python `CAMP005_W05_PY PASS blocks=3 checks=174`, Godot `CAMP005_W05_GODOT PASS blocks=3 checks=661`, ambos gates PASS.
- Bloque 04: [Actions #41720191745](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41720191745), SHA de progreso `fc87f105b9f5b979d7f5dc6f0f73f5b026dbca48`, primera consulta `pending`. El run intermedio #41720124312 puede cancelarse por concurrencia sin fallo funcional.
- La certificación de las 24 MT exige run de progreso `completed/success`, recibos `CAMP005_W05_PY PASS blocks=4 checks=N`, `CAMP005_GATE_PY_PASS worker=W05 blocks=4 checks=N`, `CAMP005_W05_GODOT PASS blocks=4 checks=N` y `CAMP005_GATE_GODOT_PASS worker=W05 blocks=4 checks=N`, N positivo.
- Regresiones completas CAMP004 y CAMP003 previstas por workflow en hitos 05/10 y parches de producción propios; no afirmar ejecución en 04 si no hay logs.

## Próximo bloque y restricciones

Siguiente `p`: comprobar primero CI 04, después ejecutar exclusivamente bloque **05** `tm166;tm167;tm168;tm169;tm170;tm171`, con regresiones CAMP004/003 al ser hito. Ante fallo funcional, diagnosticar logs y reparar bajo V5 solo ámbito W05, sin relajar aserciones. No modificar `main`, V28, PR118, rama árbitra, otras W, catálogo canónico, learnsets, políticas, 19 máquinas legacy, workflows ni partidas reales; sin merge. Al 10/10 `CAMPAÑA_005_FINALIZADA` y STOP.
