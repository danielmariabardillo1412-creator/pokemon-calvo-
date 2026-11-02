# IA3/W03 — CAMPAÑA_002_FINALIZADA (entrega 03/03)

**Estado técnico:** `03/03 ENTREGADO`; `ITER_03_CI_PASS` sobre el SHA exacto de pruebas `754b1ece5039a01da79144e9db60ea774cca6b13`. **La finalización documental no implica tres bolas funcionales.**

| Iteración | Resultado | Evidencia real |
| --- | --- | --- |
| 01 — procedencia | 9 contratos Python de ausencia de contexto; falsos positivos prohibidos | [CI #41484879741](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41484879741) PASS `967002fc` |
| 02 — referencia/negativos | fuente Essentials por SHA, 11 contratos Python, 37 negativos Godot, sin gasto/RNG | [CI #41493879869](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41493879869) PASS `6a5562dd`; [W03 auto #41539840311](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41539840311) PASS `b0897ea` |
| 03 — decisiones y regresión | contratos independientes de Ocaso/Acopio/Buceo; Python 14 pruebas; regresión Godot de Net (Agua/Bicho/Normal/doble tipo) y expectativas V11/V15 | [CI W03 #41547276442](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41547276442) **SUCCESS** en `754b1ece...`: Python **14 PASS**, Godot 4.7 **58 checks/0 errores PASS**, nuevas bolas no funcionales |

**Conclusión por bola:** `dusk_ball` = `DEPENDENCIA_DE_CONTEXTO` (reloj o cueva); `repeat_ball` = `DEPENDENCIA_DE_CONTEXTO` (historial persistente de especies capturadas); `dive_ball` = `DEPENDENCIA_DE_CONTEXTO` (medio subacuático del encuentro). **Ninguna conectada ni funcional, por orden.**

**Comprobaciones existentes:** Net Ball implementada y con CI anterior PASS (CAMP_001). ITER_03 vuelve a contrastar su adaptador, consumo, RNG y expectativas de V11/V15 sin editarlas. No agrega fórmula, multipliers ni estados artificiales.

**Petición concreta a IA6:** leer [ITER_03](./CAMP_002_ITER_03.md), [fixture](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261102-w03-camp002/tests/fixtures/parallel_items/w03_campaign_002.json) y [cuaderno](./CONTINUIDAD.md); revisar la **CI verificada #41547276442 del SHA de tests** y decidir aceptación de campaña **como auditoría y pruebas**, sin promover las bolas pendientes. No promover las tres bolas; emitir gate posterior para proveniencia mundo, historial Pokédex/SaveV2 y medio submarino, con decisiones de esquema.
 
**Protección de integridad:** toda edición de ITER03 en rama `codex/calvo-items-20261102-w03-camp002`; cero cambios a main/V28, producción, sesiones, catálogo, guardado, IA4 o ramas antiguas.

**STOP:** `CAMPAÑA_002_FINALIZADA`. Ninguna nueva `p` tiene efecto ejecutor hasta otra orden oficial.
