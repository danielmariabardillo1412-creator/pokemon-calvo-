# IA5/W05 — CAMPAÑA_003 · ITER_06/10 — seis MT Scarlet/Violet

**Estado: EN_CI_AUTOMATICA.** Se ha publicado el sexto microbloque autorizado sin cambiar producción, catálogo, CI ni ramas ajenas. El PASS de las seis MT nuevas depende del resultado de CI.

## Encargo y fuente exacta
Rama propia: `codex/calvo-items-20261103-w05-camp003`. Autoridad: `CAMPAIGN_GATE_003.md`, `CAMPAIGN_003_QUEUE_APPROVED.csv`, `campaigns/CAMP_003_W05.md` en la rama árbitra. La fila asignada **06,W05,MACHINE** contiene solamente:

| MT | Movimiento en scarlet-violet |
| --- | --- |
| `tm51` | `sandstorm` |
| `tm52` | `snowscape` |
| `tm53` | `smart_strike` |
| `tm54` | `psyshock` |
| `tm55` | `dig` |
| `tm56` | `bullet_seed` |

Los seis movimientos fueron leídos de `modules/inventory/item_connections_v1.json`, no inferidos de numeraciones históricas.

## Entregas de la iteración
- Fixture `tests/fixtures/parallel_items/w05_campaign_003.json`: sexto bloque añadido con seis pares ID/movimiento. **Sin tocar los bloques 01–05.** Commit `856c08cce2ac3b6b6ff6894d20c7debf2cb8a583`.
- Progreso `docs/coordination/items_parallel_v1/reports/W05/CAMP_003_PROGRESO.csv`: una fila adicional, bloque 06, `EN_CI_AUTOMATICA`. Commit `920a647db1bfa5f5ad9f34c13bab5d6b2fa48143`, que activa el workflow.
- **Sin reprogramación del motor:** se mantienen íntegros el validador Python y el runner Godot propios W05. Sus pruebas recorren dinámicamente los bloques del fixture y progreso, por lo que el objetivo acumulativo ahora es **6 bloques/36 MT distintas**. El runner exige especie con learnset SV real, enseñanza, PP, gasto, condiciones negativas, propiedad y SaveV2; los casos no validados deben producir FAIL.

## Verificaciones independientes
- **Verificación documental del bloque 06:** 6 filas contiguas de progreso, 6 bloques en fixture, 36 MT diferentes, mismo orden y IDs que la cola aprobada, y los 36 movimientos coinciden con el perfil original `scarlet-violet`; comprobado desde GitHub sin discrepancias.
- **CI anterior realmente superada:** [#41559168692](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41559168692), SHA `7692702bb5969de282a28604a93c44d01a8b092a`: `completed/success`, Python `PASS blocks=5 checks=290`, Godot 4.7 `PASS blocks=5 checks=1091`. Se consultaron los registros reales.
- **CI actual de bloque 06 pendiente:** [#41559866278](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41559866278), SHA `920a647db1bfa5f5ad9f34c13bab5d6b2fa48143`, inicialmente `pending`. El run del fixture [#41559852441](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41559852441) estaba `in_progress`, susceptible a cancelación por `concurrency.cancel-in-progress`. **Solo el run final del progreso y sus logs puede confirmar `PASS blocks=6`.**

## Para la próxima «p»
1. Consultar el resultado definitivo de la ejecución por SHA `920a647d...`, con recibos `CAMP003_W05_PY PASS blocks=6` y `CAMP003_W05_GODOT PASS blocks=6`. Ante fallo, reparar solo arnés propio sin relajar aserciones o STOP si es incidencia real del servicio, datos/SaveV2 o permisos.
2. Con `success`, ejecutar **únicamente bloque 07**: `tm57;tm58;tm59;tm60;tm61;tm62`. Si sigue `queued/in_progress`, la puerta permite como máximo un bloque independiente de tests sin PASS.
3. No editar `main`, V28, PR #118, otras ramas, árbitra, `modules/`, `data/`, `config/`, selección, tests compartidos, workflows ni partida real. No activar las 19 legadas ni dar por verificadas UI, gráficos, libros o GPU.

**Resultado: bloque 06/10 publicado; CI propia aún no certificada.**
