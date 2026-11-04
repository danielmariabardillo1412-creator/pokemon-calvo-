# IA5/W05 — CAMPAÑA_006 · BLOQUE 05/10 (HITO DE REGRESIÓN)

**Fecha:** 2026-11-04. **Rama:** `codex/calvo-items-20261104-w05-camp006`. **Estado de publicación original:** PUBLICADO_PENDIENTE_CI. **Estado final certificado:** CI PASS VERIFICADA, incluidas regresiones 003/004/005. **Commit de pruebas:** `7aa578bdd801d81c3e3465f9176182e1620940b7`.

## Autorización y correspondencia canónica

Fila 05 de `CAMPAIGN_006_W05_QUEUE_APPROVED.csv`, cotejada con rama árbitra y el mapeo de `modules/inventory/item_connections_v1.json` activo `scarlet-violet`:

| MT | Movimiento |
| --- | --- |
| `tm222` | `breaking_swipe` |
| `tm223` | `metal_sound` |
| `tm224` | `curse` |
| `tm225` | `hard_press` |
| `tm226` | `dragon_cheer` |

Fixture `tests/fixtures/parallel_items/w05_campaign_006.json`: **5 bloques, 25 MT**, con los bloques 01 a 04 inalterados. No se modifican `FieldItemService.teach`, catálogos, learnsets, reglas o partidas reales.

## Contratos funcionales y regresiones obligatorias

- Runner Python W05 CAMP006: unicidad/reserva/orden de las 49 MT, perfil SV, compatibilidad por learnset, PP y exclusiones de política.
- Runner Godot W05 CAMP006: `FieldItemService.teach` con especie compatible real, movimiento correcto y PP, stock y consumo de una unidad, identidad/propiedad, rechazo sin mutación por falta de stock/especie incompatible/propietario ajeno/movimiento conocido, persistencia SaveV2.
- **Hito 05:** el workflow `.github/workflows/parallel-camp006-w05-autoci.yml` exige ejecutar **CAMPAÑA_005, CAMPAÑA_004 y CAMPAÑA_003**, Python+Godot completas (10/10 bloques cada una). No basta un PASS de la nueva familia si falla alguna regresión.
- Ningún runner ni aserción anterior se ha eliminado o relajado. Sin cambios de producción ni de otras ramas.

## Resultado CI del hito 05 — PASS certificado

[GitHub Actions #41785064826](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41785064826): `completed/success` para el SHA funcional `6495147a8e4a8423984147cea9c215d775855f73`, job `126425214446`, incluidas las **tres campañas de regresión**. Recibos comprobados directamente en logs:

- `CAMP006_W05_MANIFEST_PASS reserved=10 completed=5 ids=49 kind=NEW_IDS`
- `CAMP006_W05_PY PASS blocks=5 checks=245`
- `CAMP006_GATE_PY_PASS worker=W05 blocks=5 checks=245`
- `CAMP006_W05_GODOT PASS blocks=5 checks=916`
- `CAMP006_GATE_GODOT_PASS worker=W05 blocks=5 checks=916`
- `CAMP005_W05_PY PASS blocks=10 checks=580`
- `CAMP005_W05_GODOT PASS blocks=10 checks=2166`
- `CAMP004_W05_PY PASS blocks=10 checks=580`
- `CAMP004_W05_GODOT PASS blocks=10 checks=2166`
- `CAMP003_W05_PY PASS blocks=10 checks=580`
- `CAMP003_W05_GODOT PASS blocks=10 checks=2166`

Las regresiones 003/004/005 corresponden a los 60 IDs por campaña ya cubiertos en ellas, sin reproducir bloques como nuevas altas en CAMP006. Certificación local de enseñanza/SaveV2 y regresiones headless, sin reclamar inspección visual/GPU o integración global. El CSV conserva `EN_CI_AUTOMATICA` histórico de publicación; el PASS se documenta aquí.

**Siguiente `p` solo tras CI válida:** bloque 06 `tm227;tm228;tm229;tm01;tm02`. No merges ni cambios a `main`, V28, árbitra, otras ramas, políticas, 19 máquinas legacy o partidas.
