# IA1/W01 — AUTORUN V2 · TANDA 02 FINALIZADA

**Estado oficial:** **TANDA FINALIZADA — 10/10 examinadas — 5 gemas funcionales — 0 bloqueadas.**

El lote tiene cinco objetos nuevos y cinco hitos de auditoría, no diez objetos.

## Identidad y evidencia auditada

- Repositorio: `danielmariabardillo1412-creator/pokemon-calvo-`.
- Rama exclusiva: `codex/calvo-items-20261110-w01-gems-autobatch01`.
- **Commit funcional inmutable:** `0871aa6751faecb7342376134ddbcaa5acf1ce5a`.
- **CI funcional conjunta:** [#42869207766](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42869207766) — `completed/success` sobre exactamente `0871aa6751faecb7342376134ddbcaa5acf1ce5a`.
- Jobs aprobados en ese run: `v2_new_gems`, `tanda01_regression`, `camp005_regression`, `camp004_regression` — todos `completed/success`.
- El commit de cierre documental de esta misma rama es posterior: los registros del CSV referencian la SHA funcional y su CI original, **no atribuyen la prueba histórica a la SHA documental**.
- Orden recibida: `docs/coordination/items_parallel_v1/IA6_AUTORUN.md`, TANDA 02, y protocolo `AUTONOMY_V1/README.md` de árbitra.

## Diez hitos

| Hito | Resultado | Evidencia real |
|---|---|---|
| 01 `ghost_gem` | **CERTIFICADO**, objeto funcional | 2 ataques positivos con daño Fantasma, controles tipo distinto y estado, nativo + Godot/SaveV2 |
| 02 `dragon_gem` | **CERTIFICADO**, objeto funcional | 2 ataques positivos Dragón y controles negativos, nativo + Godot/SaveV2 |
| 03 `dark_gem` | **CERTIFICADO**, objeto funcional | 2 ataques positivos Siniestro y controles negativos, nativo + Godot/SaveV2 |
| 04 `steel_gem` | **CERTIFICADO**, objeto funcional | 2 ataques positivos Acero y controles negativos, nativo + Godot/SaveV2 |
| 05 `fairy_gem` | **CERTIFICADO**, objeto funcional | Definición nativa y tipo Hada verificados, 2 ataques positivos Hada + controles; sin fabricar una gema o un multiplicador |
| 06 Matriz | **CERTIFICADO**, control técnico | `W01_V2_MATRIX PASS types=18 unique=18 old_c005=3 old_v1=10 new_v2=5` |
| 07 Consumo y negativos | **CERTIFICADO**, control técnico | 10 activaciones, 10 negativos de tipo/estado; 2 inmunidades; hierro `iron_tail`: 52 aciertos y 12 fallos con semillas reales |
| 08 SaveV2 y Transformación | **CERTIFICADO**, control técnico | 128 snapshots nativos; reentrada, PP y Transformación; Godot prueba guardado y restauración manual |
| 09 Backend y slots | **CERTIFICADO**, control técnico | `W01_V2_SLOTS PASS status_first=1 second_slot_trigger=1 switch_reentry=1`, active/none/reserve |
| 10 CI conjunta | **CERTIFICADO**, control técnico | Cuatro jobs CI aprobados sobre la misma SHA funcional; no se omiten las regresiones antiguas |

## Recibos literales

```text
W01_V2_PY PASS rows=5 checks=82
W01_V2_NATIVE PASS rows=5 activations=10 negatives=10 snapshots=128
W01_V2_IMMUNITY PASS cases=2
W01_V2_MISS PASS hits=52 misses=12
W01_V2_SLOTS PASS status_first=1 second_slot_trigger=1 switch_reentry=1
W01_V2_TRANSFORM PASS status_retains=1 transformed_hit_consumes=1 snapshots=2
W01_V2_GODOT PASS rows=5 checks=2012
W01_AUTORUN_PY PASS rows=10 checks=85
W01_AUTORUN_GODOT PASS rows=10 checks=4002
CAMP005_W01_PY PASS blocks=10 checks=668
CAMP005_W01_GODOT PASS blocks=10 checks=24723
CAMP004_W01_PY PASS blocks=10 checks=1028
CAMP004_W01_GODOT PASS blocks=10 checks=16816
```

## Contabilidad de niveles y limitaciones

- **L1:** Los cinco IDs y su selección en `RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv` y `ITEM_INVENTORY.csv` cotejados; Gema Hada no se asumió válida sin definición comprobada.
- **L2:** Motor real Showdown transaccional; daños del tipo correcto frente a ausencia/reserva, daño no potenciado de tipo distinto, estados que no consumen, snapshots, PP, inmunidades y fallos de precisión. La matriz no modifica porcentajes ni reglas globales.
- **SaveV2 / L3 limitado:** La capa Godot prueba las tres modalidades de titularidad y guardado/restauración de estado de batalla en entorno headless, incluido consumo entre turnos. **No se declara una prueba visual, recorrido de campo o inventario de mochila en una interfaz real**.
- La validación de orden cubre estado en primer slot, golpe en segundo slot y reentrada. No equivale a una auditoría exhaustiva de todos los posibles efectos simultáneos.
- **0 bloqueos** en la tanda. **0 modificaciones de producción** para demostrar la mecánica: el backend ya ofrecía los perfiles. Los fixtures y runners históricos de CAMPAÑA_004, CAMPAÑA_005 y TANDA 01 permanecieron intactos.
- **Sin merge ni integración en `main` o V28**; PR #118, rama árbitra y ramas de otras trabajadoras sin modificar.

## Archivos nuevos y seguimiento

- `tests/fixtures/parallel_items/w01_autorun_v2.json`.
- `tests/tools/repro_w01_autorun_v2_native.cjs`.
- `tests/tools/test_parallel_items_w01_autorun_v2.py`.
- `tests/gameplay/parallel_items_w01_autorun_v2.gd`.
- `.github/workflows/w01-autorun-v2-gems.yml`.
- `docs/coordination/items_parallel_v1/reports/W01/AUTORUN_V2_PROGRESS.csv`.
- `docs/coordination/items_parallel_v1/reports/W01/AUTORUN_V2_CHECKPOINT.md`.
- Este archivo `AUTORUN_V2_FINAL.md`.

**TANDA 02 cerrada para revisión IA6. STOP.** No iniciar TANDA 03 sin cola nueva publicada en el mismo `IA6_AUTORUN.md`.
