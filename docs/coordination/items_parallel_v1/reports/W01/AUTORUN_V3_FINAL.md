# IA1/W01 — AUTORUN V3 · TANDA 03 FINALIZADA

**Estado:** **TANDA FINALIZADA — 10/10 hitos certificados — 0 objetos nuevos — 10 hitos de pruebas/trazabilidad — 0 bloqueos — integración IA6: NO.**

**Rama exclusiva:** `codex/calvo-items-20261110-w01-gems-autobatch01`.
**SHA funcional probado:** `20bfd7c3a08250c79a0a3d4f0dbf120f70850138`.
**CI funcional comprobada:** [#42893188116](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42893188116) — **completed/success**, `head_sha=20bfd7c3a08250c79a0a3d4f0dbf120f70850138`, seis de seis jobs `completed/success`.
**Este informe es un commit documental posterior** y no atribuye el resultado del run al SHA de documentación.

## Evidencia de CI y trazabilidad

| Job de CI | Estado | Recibo literal |
|---|---|---|
| `v3_l3_field_path` | SUCCESS | `W01_V3_PY PASS items=18 milestones=10 checks=94`; `W01_V3_GODOT PASS ids=18 rejections=5 legacy=1 checks=574`; **18/18** `W01_V3_L3_ROW PASS` |
| `v3_field_boundaries` | SUCCESS | `W01_V3_BOUNDARIES PASS cases=3 captures=2 defeats=1 transforms=1 checks=64` |
| `tanda01_regression` | SUCCESS | `W01_AUTORUN_PY PASS rows=10 checks=85`; `W01_AUTORUN_GODOT PASS rows=10 checks=4002` |
| `v2_new_gems` | SUCCESS | `W01_V2_PY PASS rows=5 checks=82`; `W01_V2_GODOT PASS rows=5 checks=2012` |
| `camp004_regression` | SUCCESS | `CAMP004_W01_PY PASS blocks=10 checks=1028`; `CAMP004_W01_GODOT PASS blocks=10 checks=16816` |
| `camp005_regression` | SUCCESS | `CAMP005_W01_PY PASS blocks=10 checks=668`; `CAMP005_W01_GODOT PASS blocks=10 checks=24723` |

## Las diez filas de la orden

| Hito | Resultado | Prueba / entrega |
|---|---|---|
| 01. Trazabilidad | CERTIFICADO | Camino `PlayerInventory` → `PlayerCollection` → `FieldItemService.equip` → `FieldNativeSession` → motor Showdown → `settle_finished_battle` → SaveV2, con proveedores reales trazados en `AUTORUN_V3_TRACE.md`. |
| 02. Tres gemas CAMP005 | CERTIFICADO | `normal_gem`, `fire_gem`, `water_gem` 3/3 L3. El ciclo funciona: no se finge una prueba roja donde no hubo fallo. |
| 03. Primeras cinco T01 | CERTIFICADO | `electric_gem`, `grass_gem`, `ice_gem`, `fighting_gem`, `poison_gem` 5/5 L3. |
| 04. Últimas cinco T01 | CERTIFICADO | `ground_gem`, `flying_gem`, `psychic_gem`, `bug_gem`, `rock_gem` 5/5 L3. |
| 05. Cinco T02 | CERTIFICADO | `ghost_gem`, `dragon_gem`, `dark_gem`, `steel_gem`, `fairy_gem` 5/5 L3. |
| 06. Equipamiento negativo | CERTIFICADO | Cinco rechazos del runner, bolsa agotada, titularidad ajena, equipamiento repetido, sustitución reversible y contabilidad sin duplicación. |
| 07. Límites del combate | CERTIFICADO | Captura, derrota, Transformación, entrada desde reserva y persistencia del consumo en 3 escenarios genuinos. |
| 08. SaveV2 y legacy | CERTIFICADO | Guardado/carga de disco antes/después de liquidar; `unequip` sin devolución de gema gastada; legacy V1 no crea unidades fantasma. |
| 09. Sesión real existente | CERTIFICADO | `FieldNativeSession` y `settle_finished_battle` existentes, sin construir UI ficticia. |
| 10. Regresión conjunta | CERTIFICADO | Cuatro regresiones históricas más dos jobs V3, los seis finalizados en SUCCESS sobre la **misma SHA funcional**. |

## Inventario de niveles y límites

- **L1:** Dieciocho IDs históricos en fixture, sin repetir ni sumar objetos como nuevos.
- **L2:** Daño y consumo del backend de combate conservados; controles positivos/negativos de tandas anteriores y regresión completa.
- **L3 genuino comprobado:** inventario → equipamiento mediante servicio real → criatura → adaptador de sesión existente → efecto y consumo → reconciliación → SaveV2 → recarga. Los tests cubren 18/18 gemas, cinco rechazos, un caso legacy y los límites específicos.
- **No certificado:** recorrido visual manual por pantalla UI ni integración/merge en la rama árbitra IA6. El contrato solicitaba adaptador de sesión, no una pantalla inventada.
- **Sin modificaciones de producción** para esta certificación, sin alterar `FieldItemService`, `PlayerCollection`, `CreatureInstance`, `SaveGameRepository`, SaveV2, motor global, `main`, V28, PR #118 ni ramas ajenas.
- **Pruebas históricas preservadas**; ningún skip genérico, PASS simulado ni cambio de denominador.

## Archivos y orden de cierre

- `tests/fixtures/parallel_items/w01_autorun_v3.json`, `tests/gameplay/parallel_items_w01_autorun_v3.gd`, runner de límites, auditoría Python y workflow W01 ya probados en `20bfd7c3a08250c79a0a3d4f0dbf120f70850138`.
- `AUTORUN_V3_TRACE.md` y `AUTORUN_V3_GATE_20261110.md` documentan ruta y recibos; `AUTORUN_V3_PROGRESS.csv` marca los 10 hitos sobre `20bfd7c3a08250c79a0a3d4f0dbf120f70850138` y CI `42893188116`.
- **STOP:** TANDA 03 cerrada en rama W01; IA6 debe revisar la integración y publicar otra cola en `IA6_AUTORUN.md` antes de iniciar nuevas filas. No asumir merge.

**Entrega a IA6:** W01 TANDA 03 FINALIZADA — 10/10 hitos — 0 objetos nuevos — 10 QA/trazabilidad — 0 bloqueos — SHA `20bfd7c3a08250c79a0a3d4f0dbf120f70850138` — CI #42893188116 SUCCESS — informe `AUTORUN_V3_FINAL.md` — integración IA6 NO.
