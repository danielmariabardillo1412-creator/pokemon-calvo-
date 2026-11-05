# IA4/W04 — CAMPAÑA_006 — bloque 04 EN ESPERA DE POLÍTICA IA6

**Fecha de comprobación:** 2026-11-05. **Rama exclusiva:** `codex/calvo-items-20261104-w04-camp006`.
**Fila autorizada:** `04,W04,INTEGRATION_BACKLOG,TRADE_LEVEL_GATE,dubious_disc;magmarizer;protector;reaper_cloth;prism_scale;sachet;up_grade,extender_trade_level_solo_con_politica_aprobada`.

## Decisión de puerta: NO INICIAR IMPLEMENTACIÓN NI CONTABILIZAR 04/10

Se revisaron las versiones actuales de `docs/current/ITEM_TRADE_RESTORATION_V27.json` tanto en esta rama como en `codex/calvo-items-20261101-arbitro`. **Ambas coinciden** en el blob `e3c9c356f806edac4b71f7edad31ba98afa179d4` y mantienen:
- `level_values_selected: null`
- `future_evolution_implementation: "DEFERRED"`
- `correct_future_rule`: sustituir *solo* intercambio; mantener exigencia del objeto equipado y sumar nivel que se apruebe posteriormente; nunca hacerlo item-free.

La referencia `docs/current/TRADE_EVOLUTIONS_FUTURE.md` de árbitra sigue indicando que la conversión se pospone hasta resolver los objetos; no se adopta nivel común, 37 ni mínimos de etapas anteriores.

`CAMPAIGN_006_W04_GATE.md` ordena no elegir niveles ni consumos y **detener una familia si dos bloques seguidos demuestran la misma dependencia sin una ruta nueva**. Bloque 03 ya demostró una nueva ruta L3 positiva: equipar/quitar/reequipar `dragon_scale` y `electirizer` desde la demo con SaveV2, sin evolución por nivel. Su CI fue [#41785445720](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41785445720) SUCCESS (Python 127, Godot 281), confirmada de nuevo con CSV consolidado por [#41785614844](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41785614844).

**Extender equip/unequip a siete objetos no cumpliría `extender_trade_level_solo_con_politica_aprobada` y no debe computarse como evolución positiva.** No se añaden tests negativos redundantes, fixture 04, fila 04 al CSV ni código de producción. El progreso oficial permanece **03/10**, sin ningún estado `PASS` inventado para 04. No se ha ejecutado CI04 ni existe SHA de implementación04.

## Ticket único a IA6 — decisiones bloqueantes

**Objetos afectados (fila04):** `dubious_disc`, `magmarizer`, `protector`, `reaper_cloth`, `prism_scale`, `sachet`, `up_grade`.

1. **Niveles:** aprobar explícitamente una tabla `source_species, target_species, required_held_item, min_level` para cada ruta de la fila04 (y, si se desea resolver toda la familia, también las dos de fila03). No deducirlos de PokeAPI ni randomizadores.
2. **Objeto tras la evolución:** definir para evolución confirmada, cancelada y operación fallida la semántica de `held_item_id` y `held_item_consumed`: conservar equipado, consumir o retornar al inventario, así como rollback. Los valores anteriores describen el sistema vigente y **no autorizan inventar** la regla futura.
3. **Fronteras y propietario:** validar la interfaz que emite `ProgressionSystem.gain_experience` y `EvolutionSystem.level_up_context` para incluir `held_item_id`, y la transacción de reemplazo/SaveV2 del propietario compartido. IA6 debe reservar los cambios compartidos antes de autorizar a W04 la función de evaluación concreta en `modules/creatures/progression/evolution_system.gd`.
4. **Criterio de recepción:** para cada ruta aprobada, test **positivo L2/L3 de evolución por nivel real con held correcto**, negativo un nivel antes/sin held/ítem erróneo, preservación de identidad y SaveV2, y verificaciones de consumo/rollback. Conservar todos los casos existentes de bloques 01–03.

**Estado y recomendación:** `BLOQUE04_BLOQUEADO_POLITICA_IA6`. Solicitar resolución expresa en árbitra; si IA6 decide aplazar evolución por nivel hasta terminar objetos, indicar nueva instrucción autorizada para **saltar formalmente** la fila04 y continuar con el bloque05 independiente. No reinterpretar `p` como permiso para ese salto.

## Integridad y continuidad

No se editan `main`, V28, otras ramas, `docs/current/`, `modules/`, `scenes/visual/`, fixture de campaña, validadores ni `CAMP_006_PROGRESO.csv`. El último CI de pruebas acumulativas continúa siendo el bloque03; no se presenta como CI04.
