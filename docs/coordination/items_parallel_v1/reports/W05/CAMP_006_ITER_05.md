# IA5/W05 — CAMPAÑA_006 · BLOQUE 05/10 (HITO DE REGRESIÓN)

**Fecha:** 2026-11-04. **Rama:** `codex/calvo-items-20261104-w05-camp006`. **Estado:** PUBLICADO_PENDIENTE_CI; ningún PASS nuevo atribuido antes de revisar el run. **Commit de pruebas:** `7aa578bdd801d81c3e3465f9176182e1620940b7`.

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

## Criterio de cierre

Se requiere `completed/success` en CI del SHA con fixture y progreso, recibos `CAMP006_W05_PY PASS blocks=5 checks=N` y `CAMP006_W05_GODOT PASS blocks=5 checks=N`, ambos gates con N positivo, y seis recibos de regresión `CAMP005_W05_[PY|GODOT] PASS blocks=10`, `CAMP004_W05_[PY|GODOT] PASS blocks=10`, `CAMP003_W05_[PY|GODOT] PASS blocks=10`, verificados en mismo run.

**Siguiente `p` solo tras CI válida:** bloque 06 `tm227;tm228;tm229;tm01;tm02`. No merges ni cambios a `main`, V28, árbitra, otras ramas, políticas, 19 máquinas legacy o partidas.
