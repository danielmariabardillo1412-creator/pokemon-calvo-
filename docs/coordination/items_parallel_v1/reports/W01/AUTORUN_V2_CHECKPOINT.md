# IA1/W01 — TANDA02 CHECKPOINT VERIFICADO · 2026-11-10

## Autoridad y seguridad
- Rama exclusiva `codex/calvo-items-20261110-w01-gems-autobatch01`. Orden vigente: `docs/coordination/items_parallel_v1/IA6_AUTORUN.md`; consulta el protocolo de rama árbitra.
- **SHA funcional:** `0871aa6751faecb7342376134ddbcaa5acf1ce5a`. **CI:** [#42869207766](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42869207766). **NO declarar SUCCESS global** hasta que sus cuatro jobs terminen con éxito en ese SHA.
- El commit que actualiza este checkpoint es SOLO documental y NO acredita ejecución de tests sobre ese nuevo SHA. Mantener la distinción entre SHA funcional y SHA de checkpoint.
- No se han modificado `main`, V28, PR #118, ramas de otras trabajadoras, backend global, SaveV2 central ni fixtures/runner de CAMP004/CAMP005/TANDA01.

## Hitos 01–09 — pruebas funcionales ya verificadas en job independiente

Job `v2_new_gems` **completed/success**:
- `W01_V2_NATIVE_ROW PASS` para `ghost_gem`, `dragon_gem`, `dark_gem`, `steel_gem`, `fairy_gem`.
- `W01_V2_PY PASS rows=5 checks=82`.
- `W01_V2_GODOT PASS rows=5 checks=2012`, con efectos positivos reales, tres titulares/control y SaveV2.
- `W01_V2_NATIVE PASS rows=5 activations=10 negatives=10 snapshots=128`.
- `W01_V2_MATRIX PASS types=18 unique=18 old_c005=3 old_v1=10 new_v2=5`. Fairy Gem respaldada por perfil nativo real y movimiento Hada; no se inventó multiplicador.
- `W01_V2_IMMUNITY PASS cases=2`; `W01_V2_MISS PASS hits=52 misses=12`.
- `W01_V2_SLOTS PASS status_first=1 second_slot_trigger=1 switch_reentry=1`.
- `W01_V2_TRANSFORM PASS status_retains=1 transformed_hit_consumes=1 snapshots=2`.

Job `tanda01_regression` **completed/success**:
- `W01_AUTORUN_PY PASS rows=10 checks=85`.
- `W01_AUTORUN_GODOT PASS rows=10 checks=4002`.

## Hito 10 — puerta pendiente

En el último control, estos dos jobs todavía estaban en ejecución: `camp005_regression` y `camp004_regression`. **No hay aún certificación global**; por tanto, el CSV `AUTORUN_V2_PROGRESS.csv` conserva los estados `EN_CI_AUTOMATICA` para evitar atribuir CI verde antes de tiempo.

## Continuación automática sin repetir trabajo

1. Leer `IA6_AUTORUN.md` en HEAD propio; si IA6 publicó una tanda distinta, reconciliarla antes de actuar.
2. Consultar run `#42869207766` y el job exacto que falte; si FAILURE, reparar solo en archivos W01 propios sin debilitar aserciones ni cambiar historial; correr CI de nuevo.
3. Si los cuatro jobs están en SUCCESS sobre `0871aa6751faecb7342376134ddbcaa5acf1ce5a`, cerrar 10/10 en `AUTORUN_V2_PROGRESS.csv` y publicar `AUTORUN_V2_FINAL.md` con hashes, CI y límites L1/L2/L3.
4. Comprobar la eventual CI documental independiente; no repetir diez gemas ni iniciar otra tanda sin nueva cola.

**Progreso:** 9/10 hitos con pruebas completadas; 5/5 gemas funcionales verificadas en CI propia; bloqueos funcionales 0 por ahora; cierre global hito 10 pendiente.
