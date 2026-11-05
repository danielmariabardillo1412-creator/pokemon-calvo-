# IA5/W05 — CAMPAÑA_006 · BLOQUE 07/10

**Fecha:** 2026-11-05. **Rama exclusiva:** `codex/calvo-items-20261104-w05-camp006`. **Estado inicial:** ENTREGADO_PENDIENTE_CI. **Estado actual:** CI PASS VERIFICADA. **Commit fixture:** `7fc0f0a07371e820f18c400bbae710adc878ae64`.

## Autorización IA6 y mapeo Scarlet/Violet

Fila 07 de `CAMPAIGN_006_W05_QUEUE_APPROVED.csv` en rama árbitra, cotejada con `modules/inventory/item_connections_v1.json` sin modificarla:

| MT | Movimiento SV |
|---|---|
| `tm03` | `fake_tears` |
| `tm04` | `agility` |
| `tm05` | `mud_slap` |
| `tm06` | `scary_face` |
| `tm08` | `fire_fang` |

Estas MT tienen otros movimientos en ediciones anteriores; únicamente se prueba su perfil `scarlet-violet`. No se activan máquinas históricas.

## Cobertura funcional prevista

- Fixture acumulativo `tests/fixtures/parallel_items/w05_campaign_006.json`: siete bloques / **35 MT**, preservando íntegros los seis bloques previos.
- Python W05 CAMP006 valida identidad y cuota de cola, mapeo SV real, PP, política, compatibilidad de learnset y unicidad.
- Godot W05 CAMP006 ejecuta `FieldItemService.teach` real por MT y especie compatible. Prueba PP y movimiento enseñado, consumo exacto de 1 unidad, propiedad/identidad, ausencia de stock, incompatibilidad, movimiento conocido, rechazos sin mutación y guardado/carga SaveV2.
- Se conservan runners y contratos de los 30 casos previos, sin cambios en motor, catálogo, learnsets, política, workflows, save reales ni otras ramas.
- Las regresiones CAMP003/004/005 completas pasaron en hito 05 [#41785064826](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41785064826); su próximo hito obligatorio es 10 salvo parche `modules/`.

## CI del bloque 07 — PASS funcional certificado

[GitHub Actions #41965283619](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41965283619): `completed/success` en SHA funcional `2c802f1d4dde50c6a6cee78c53dd6ef1934352e2`, job `127040761436`. Recibos exactos del log:

- `CAMP006_W05_MANIFEST_PASS reserved=10 completed=7 ids=49 kind=NEW_IDS`
- `CAMP006_W05_PY PASS blocks=7 checks=343`
- `CAMP006_GATE_PY_PASS worker=W05 blocks=7 checks=343`
- `CAMP006_W05_GODOT PASS blocks=7 checks=1276`
- `CAMP006_GATE_GODOT_PASS worker=W05 blocks=7 checks=1276`

Regresiones CAMP003/004/005 en este run: `skipped`, correctamente en bloque 07 sin cambios `modules/`. Hito 05 pasó las seis regresiones completas en [#41785064826](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41785064826). CSV conserva `EN_CI_AUTOMATICA` como registro histórico del push; PASS certificado aquí. No confundir Godot headless con UI/GPU ni con integración global.

**Próxima `p` tras certificación:** bloque 08 `tm09;tm10;tm11;tm12;tm13`. Sin merge.
