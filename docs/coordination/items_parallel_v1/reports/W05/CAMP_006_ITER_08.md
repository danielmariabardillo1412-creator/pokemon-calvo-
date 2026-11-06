# IA5/W05 — CAMPAÑA_006 · BLOQUE 08/10

**Fecha:** 2026-11-06. **Rama exclusiva:** `codex/calvo-items-20261104-w05-camp006`. **Estado de publicación:** EN_CI_AUTOMATICA (histórico). **Estado actual:** CI PASS VERIFICADA. **Commit de pruebas:** `c7f8e037d46a49c25bac4b3d64ef2a343a56a31c`.

## Autorización y correspondencia canónica

Fila 08 de la cola IA6 en rama árbitra, cotejada con `modules/inventory/item_connections_v1.json` para perfil activo `scarlet-violet`:

| MT | Movimiento SV |
|---|---|
| `tm09` | `thunder_fang` |
| `tm10` | `ice_fang` |
| `tm11` | `water_pulse` |
| `tm12` | `low_kick` |
| `tm13` | `acid_spray` |

Las numeraciones se reutilizan entre generaciones; únicamente se valida la asignación canónica `scarlet-violet`, sin reactivar ninguna de las 19 máquinas históricas excluidas.

## Contrato acumulativo

- Fixture `tests/fixtures/parallel_items/w05_campaign_006.json`: **8 bloques / 40 MT**, los 35 casos de 01–07 permanecen inalterados.
- Python `tests/tools/test_parallel_items_w05_campaign_006.py` coteja cola, unicidad, datos y mapeos SV, permisos, learnsets y PP canónicos para todas las MT.
- Godot `tests/gameplay/parallel_items_w05_campaign_006.gd` prueba para cada MT `FieldItemService.teach` real con especie compatible; movimiento/PP correcto, propiedad e identidad, inventario y consumo de una unidad, incompatibilidad y rechazo por falta de stock, propietario ajeno y movimiento ya conocido sin alterar el estado, más SaveV2.
- Se mantienen runners y pruebas anteriores sin relajación ni duplicación de nuevos IDs; no se han modificado código de producción, catálogo, learnsets, políticas, workflows, partidas, ramas ajenas ni `main`/V28.
- Regresiones completas CAMP003/004/005 ya certificadas en hito 05 [#41785064826](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41785064826). Hito siguiente obligatorio: bloque 10 (o parche `modules/`).

## Resultado CI bloque 08 — PASS verificado

[GitHub Actions #42232636595](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42232636595): `completed/success`, SHA funcional `7d8d38a0f131e82beda9ca619ac1f3ee9fa25332`, job `127942100036`. Recibos obtenidos del log real del trabajo:

- `CAMP006_W05_MANIFEST_PASS reserved=10 completed=8 ids=49 kind=NEW_IDS`
- `CAMP006_W05_PY PASS blocks=8 checks=392`
- `CAMP006_GATE_PY_PASS worker=W05 blocks=8 checks=392`
- `CAMP006_W05_GODOT PASS blocks=8 checks=1456`
- `CAMP006_GATE_GODOT_PASS worker=W05 blocks=8 checks=1456`

Regresiones completas CAMP003/004/005: `skipped` en este run según hitos 01/05/10 y ausencia de parche `modules/`. Las seis regresiones completas se certificaron en hito 05 [#41785064826](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41785064826); volverán en hito 10. CSV conserva estado `EN_CI_AUTOMATICA` histórico del push; PASS documentado aquí. Este PASS headless acredita contratos de enseñanza y SaveV2, no inspección visual/GPU ni integración global.

**Próxima `p` tras certificar CI:** bloque 09 `tm14;tm15;tm17;tm19;tm20`. Sin merge.
