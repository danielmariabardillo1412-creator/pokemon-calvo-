# CAMPAÑA_004_FINALIZADA — IA5/W05 · 10/10 · 60 MT · CI FINAL PASS

**ESTADO DEFINITIVO VERIFICADO (2026-11-03):** entregadas y verificadas 60 MT `tm82`–`tm141` de Scarlet/Violet, 10 bloques completos. La CI [GitHub Actions #41591821717](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41591821717), SHA funcional `5c9051ca2a0a186d31705372d2f0c350e2dd62db`, job `125770313243`, terminó **`completed/success`**; se verificaron personalmente los recibos reales del log:

- `CAMP004_W05_PY PASS blocks=10 checks=580`
- `CAMP004_GATE_PY_PASS worker=W05 blocks=10 checks=580`
- `CAMP004_W05_GODOT PASS blocks=10 checks=2166`
- `CAMP004_GATE_GODOT_PASS worker=W05 blocks=10 checks=2166`
- Regresión CAMP003 de las 60 MT anteriores: `CAMP003_W05_PY PASS blocks=10 checks=580` y `CAMP003_W05_GODOT PASS blocks=10 checks=2166`
- Regresión CAMP002: `Ran 11 tests` y `OK`

**DIFF/Y ALCANCE:** únicamente fixture y CSV CAMP004 propios, diez informes iterativos, informe final y continuidad W05. No se corrigió producción porque no hubo defecto demostrado. No se modificó `main`, V28, PR118, rama árbitra, otras W, catálogos, políticas, 19 máquinas legacy, workflows ni partidas reales. No hubo merge; IA6 debe auditar/integrar. Godot headless no acredita validación visual/GPU.

**CI PASS sobre SHA de pruebas**: los commits documentales posteriores no cambian fixture, CSV, runners, perfil o producción; el resultado válido sigue siendo el SHA de progreso `5c9051ca2a0a186d31705372d2f0c350e2dd62db`. La fila CSV 10 mantiene su estado histórico `EN_CI_AUTOMATICA` para no relanzar CI redundante; este informe prevalece en cuanto a veredicto final.

**STOP OFICIAL IA5/W05:** 10/10 autorizado completado, 60/60 verificados funcionalmente, ninguna `p` adicional puede crear bloque 11 o iniciar otra campaña. IA6 continúa con auditoría e integración; W05 permanece detenido.

---

# IA5/W05 — CAMPAÑA_004 · INFORME CONSOLIDADO 10/10

**ESTADO DOCUMENTAL:** diez microbloques entregados, 60 MT nuevas Scarlet/Violet (`tm82`–`tm141`). **ESTADO FUNCIONAL A PRIMERA PUBLICACIÓN:** CI final del décimo bloque pendiente de resultado; no atribuir 60/60 PASS sin comprobación del run.

## Alcance, identidad y fuentes
- Trabajadora IA5/W05, MT/libros; rama exclusiva `codex/calvo-items-20261103-w05-camp004`. Puerta IA6 `CAMPAIGN_004_W05_GATE.md`, cola `CAMPAIGN_004_W05_QUEUE_APPROVED.csv`, encargo `campaigns/CAMP_004_W05.md` y `AUTONOMOUS_REPAIR_V5.md` de `codex/calvo-items-20261101-arbitro`.
- CAMP003 10/10 (60 MT anteriores) permanece sin cambios y se prueba únicamente como regresión, igual que CAMP002. No se manipularon máquinas legacy ni datos/versiones originales.
- No se modificó código de producción: las pruebas W05 reutilizan el servicio real `FieldItemService.teach` y el perfil canónico SV ya existente. No se rebajaron aserciones.
- En total 10 bloques consecutivos de seis IDs cada uno: `01 tm82–tm87`, `02 tm88–tm93`, `03 tm94–tm99`, `04 tm100–tm105`, `05 tm106–tm111`, `06 tm112–tm117`, `07 tm118–tm123`, `08 tm124–tm129`, `09 tm130–tm135`, `10 tm136–tm141`.

## Último bloque
| MT | Movimiento canónico Scarlet/Violet |
| --- | --- |
| `tm136` | `electric_terrain` |
| `tm137` | `grassy_terrain` |
| `tm138` | `psychic_terrain` |
| `tm139` | `misty_terrain` |
| `tm140` | `nasty_plot` |
| `tm141` | `fire_blast` |

## Evidencia de trabajo y propiedades
- Fixture final `tests/fixtures/parallel_items/w05_campaign_004.json`, commit `6f1ae6afe42051e9e58b8a5a6e99e83bb343e701`.
- CSV `docs/coordination/items_parallel_v1/reports/W05/CAMP_004_PROGRESO.csv` con diez filas, commit `5c9051ca2a0a186d31705372d2f0c350e2dd62db`.
- Informes separados `CAMP_004_ITER_01.md` … `CAMP_004_ITER_10.md`; continuidad vigente `reports/W05/CONTINUIDAD.md`.
- Verificación estática post-commit: **60 IDs únicos**, orden y movimientos idénticos en las 10 filas de progreso, cola IA6, fixture y `modules/inventory/item_connections_v1.json` con `active_machine_version=scarlet-violet`. Sin duplicados o desviaciones.
- Runners acumulativos ya preparados por IA6: `tests/tools/test_parallel_items_w05_campaign_004.py` verifica mapeo, metadatos de ataques, política, PP, y al menos una especie con learnset real SV. `tests/gameplay/parallel_items_w05_campaign_004.gd` ejecuta el servicio real: enseñanza con especie compatible, rechazo de incompatible, de falta de stock y de propietario inexistente, consumo de una MT, PP, rechazo de doble enseñanza, identidad y persistencia SaveV2.
- Workflow `.github/workflows/parallel-camp004-w05-autoci.yml` ejecuta pruebas W05 nuevas y regresiones CAMP003 Python y Godot (60 MT anteriores), CAMP002 (11 tests), con Godot 4.7 headless y restauración de recursos.

## Puerta de calidad y estado
- **01–09 certificados por CI real**: [Actions #41589081119](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41589081119), SHA `cc092d4935036be18503965af3519852ecc9b39f`, `completed/success`; Python `CAMP004_W05_PY PASS blocks=9 checks=522`; Godot `CAMP004_W05_GODOT PASS blocks=9 checks=1951`; ambos gates PASS; CAMP003 Python 580 checks y Godot 2166 checks PASS; CAMP002 11 tests OK.
- **Run final sobre commit que contiene los diez bloques**: [Actions #41591821717](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41591821717), SHA `5c9051ca2a0a186d31705372d2f0c350e2dd62db`, inicialmente `pending`/`in_progress`.
- Para completar certificación funcional comprobar `completed/success`, los recibos `CAMP004_W05_PY PASS blocks=10 checks=N` y `CAMP004_W05_GODOT PASS blocks=10 checks=N`, ambos gates y regresiones CAMP003/CAMP002 **en el mismo run final**. Sólo después declarar `CAMPAÑA_004_FINALIZADA`.
- La fila final CSV mantiene `EN_CI_AUTOMATICA` como estado histórico de publicación; actualizarla sólo para reflejar PASS volvería a disparar CI y podría cancelar una ejecución; reflejar el estado posterior en este informe y continuidad, no reescribir CSV.

## Límites y entrega IA6
- **No integrar automáticamente**: validación CI W05 de su rama no equivale a aprobación de integración global. IA6 debe auditar diff y colisiones, y decidir merge, sin tocar `main`/V28/PR118 desde W05.
- Sin cambios a `main`, V28, rama árbitra, W01–W04, catálogos, políticas, partidas, 19 MT inactivas ni modificaciones de UI/GPU. Godot headless comprueba lógica y SaveV2, no interfaces visuales.
- Finalizado 10/10 documentalmente. No existe bloque 11; `p` posterior no autoriza iniciar nueva campaña ni rehacer pruebas anteriores. Tras CI final verde, `CAMPAÑA_004_FINALIZADA` y STOP.

**VALIDACIÓN FUNCIONAL FINAL: PENDIENTE DE RUN 10 AL PUBLICAR ESTE INFORME.**
