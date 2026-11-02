# IA6 — FOTO FINAL CAMPAÑA_002 / auditoría real del 3 de noviembre de 2026

**Estado: cuatro de cuatro trabajadoras de CAMP_002 entregaron 03/03 y sus últimas CI individuales terminaron `completed/success`.** La quinta trabajadora W04 cerró CAMPAÑA_001 03/03 y pasó Godot anteriormente. **No iniciar CAMPAÑA_003 por pulsar `p`**: los contratos actuales ordenan STOP al finalizar 03/03.

| IA | Branch, HEAD documental | Último SHA de pruebas | Evidencia Godot 4.7 |
| --- | --- | --- | --- |
| W01 | `codex/calvo-items-20261102-w01-camp002`, `7d3e59b4e3464562be655ff241266e43b9fd246a` | `ee760fc8aebe7fb9d5700aadf25053c13a43f6b7` | [#41547041337](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41547041337) **success**: 1017 checks, 10 corridas, 0 errores; Python y recibos PASS |
| W02 | `codex/calvo-items-20261102-w02-camp002`, `28256f2e5aec16f984d37abdfbdcf4aa68891340` | `3ccbaafa268bd6566afbf211abd6f7b1a2d74488` | [#41547218742](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41547218742) **success**: 838 checks, 9 casos, 0 errores; fixture/unittest/recibos PASS |
| W03 | `codex/calvo-items-20261102-w03-camp002`, `0ee6b4717a2961bc56c6dab8b7a2ca7f776bf25c` | `754b1ece5039a01da79144e9db60ea774cca6b13` | [#41547276442](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41547276442) **success**: 58 checks negativos, 0 errores, 14 pruebas Python. `new_balls_functional:false`, Dusk/Repeat/Dive NO implementadas; dependencias de contexto pendientes |
| W04 | `codex/calvo-items-20261101-w04`, `3c6aa9c3b9754a197a4d34c9bd0c0a7606af1d1f` | Prueba final corregida en staging árbitra | [#41538151097](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41538151097) **success**: 559 checks, 12 casos SaveV2, 0 errores, test corregido solo en árbitra |
| W05 | `codex/calvo-items-20261102-w05-camp002`, `ffcbe93642f6267b4143bcb01abe974d00e8b01b` | `0af3e48aa60508601e494a81fd3bf52ee668465a` | [#41547169973](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41547169973) **success**: 703 checks, 12 enseñanzas de MT, 0 errores. 229 activas en catálogo y 19 históricas rechazadas; **no son 229 enseñanzas probadas** |

**Comprobación de sincronización:** comparación del SHA sometido a CI contra HEAD final de cada W01/W02/W03/W05: **0 commits de retroceso y únicamente los informes `CAMP_002_ITER_03.md`, `CAMP_002_FINAL.md`, `CAMP_002_PROGRESO.csv` y `CONTINUIDAD.md` cambiados** (ningún test/producción tras el último SHA verificado). La interfaz del chat conservaba mensajes `EN_CI_AUTOMATICA` obsoletos: GitHub ya resolvió las ejecuciones.

## Causa exacta de las paradas
- `campaigns/CAMP_002_W0X.md` y `CAMPAIGN_GATE_002.md` limitan a **tres microbloques por trabajadora** y mandan `CAMPAÑA_002_FINALIZADA / STOP`. No dependen del color del chat.
- `PREPARADO_PENDIENTE_CI` solo significa trabajo publicado aún no ejecutado; no es FAIL ni obligación de esperar si el siguiente trabajo independiente ya está autorizado.
- `CI_AUTOPILOT_V3.md` instaló workflows por rama. Los cuatro workflows se disparan en push de tests/fixtures y ya han verificado ITER_03; el paso de CI automático sí funciona.
- El **nuevo cuello de botella** ya no es CI sino la amplitud de la autorización. Continuar con `p` sin nuevos encargos daría permiso inexistente para trabajar objetos no asignados, con riesgo de duplicados y solapes.

## Recomendación de IA6
Preparar una única `CAMPAÑA_003` **más larga** (por ejemplo, hasta 10–12 microbloques por trabajadora) con una lista **explícita, verificada y sin solapamientos** de IDs, rutas propias y tipos de pruebas; así cada `p` avanza un bloque y el workflow corre automáticamente. La nueva campaña requerirá una única autorización antes de su inicio, nunca otra por cada tres `p`. Tras un fallo real de CI/contrato/permisos/producción compartida, STOP de la W afectada y diagnóstico IA6. Propuesta de diseño en `LONG_CAMPAIGN_V4_DRAFT.md`, **no activada**.

**Protección vigente:** `main`, V28, PR #118 y ramas ajenas no se modifican por este informe. No afirmar que la suite Godot headless certifica gráficos, UX o todas las combinaciones nativas.
