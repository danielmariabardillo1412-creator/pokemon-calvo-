# IA2/W02 — CAMPAÑA_005 · MICROBLOQUE 09/10

**Autorización:** IA6, `CAMPAIGN_005_W02_GATE.md`, `CAMPAIGN_005_W02_QUEUE_APPROVED.csv` (fila 09), `campaigns/CAMP_005_W02.md` y `AUTONOMOUS_REPAIR_V5.md`. **Rama de escritura única:** `codex/calvo-items-20261103-w02-camp005`. Este `p` corresponde exclusivamente al bloque 09. Sin modificaciones en `main`, V28, producción, rama árbitra, otras trabajadoras, APIs compartidas ni workflows.

## Resultado: cuatro dependencias funcionales, no cuatro mentas integradas

| ID | Naturaleza cuyo efecto estadístico se solicita | Estado real en campo | Casos |
|---|---|---|---:|
| `timid_mint` | Miedosa (Velocidad +, Ataque −) | `DEPENDENCY_MISSING` | 8 |
| `bold_mint` | Osada (Defensa +, Ataque −) | `DEPENDENCY_MISSING` | 8 |
| `calm_mint` | Serena (Defensa Especial +, Ataque −) | `DEPENDENCY_MISSING` | 8 |
| `careful_mint` | Cauta (Defensa Especial +, Ataque Especial −) | `DEPENDENCY_MISSING` | 8 |

**32 escenarios nuevos y 96 variantes programadas**, sin afirmar aceptación ni consumo de ninguno de estos cuatro ítems. Ocho patrones por objeto: naturaleza original neutra, naturaleza original coincidente, naturaleza original diferente, amistad 0, amistad 254, ranura movimiento 0, ranura 1 y nivel 100. Se prueban las tres modalidades de propietario: `active` (PARTY con dos unidades), `none` (PARTY sin objeto) y `reserve` (STORAGE con dos unidades). En todos se esperan `accepted=false`, `status=DEPENDENCY_MISSING`, `reason=field_effect_not_connected`, estado íntegro y no consumo.

## Prueba del bloqueo real

1. `FieldItemService.use_item` despacha crecimiento, efectos de campo, pasivos, máquinas y evoluciones; cuando no hay ejecutor, finaliza con `_deny("field_effect_not_connected", "DEPENDENCY_MISSING")`. Ninguno de los cuatro IDs figura en `FieldItemService`, `FieldItemEffects`, `FieldGrowthEffects` o `FieldMochiEffects`.
2. `config/item_selection_v1.json` **no los excluye** por ID ni por categoría. Por tanto, el problema no es la política de selección, sino la ausencia de ruta funcional.
3. `CreatureInstance` persiste `nature_id` y calcula sus estadísticas mediante `StatCalculator`; no tiene campo `effective_nature_id` ni puente de menta. La naturaleza original no debe sobrescribirse como solución improvisada. `ProgressionRuleset.NATURE_MODIFIERS` sí reconoce las cuatro naturalezas como reglas de cálculo base, pero eso no crea automáticamente la mecánica de menta.
4. El runner propio `tests/gameplay/parallel_items_w02_campaign_005.gd` usa la naturaleza inicial real indicada por el caso (`spec.nature`), invoca `FieldItemService.use_item`, contrasta código/estado de rechazo, igualdad de instantánea completa y propietario, inventario y SaveV2 sin alteraciones. No se cambia el runner de producción ni se simula un éxito.

## Pruebas y commits publicados

- Fixture acumulada `tests/fixtures/parallel_items/w02_campaign_005.json`, bloque 09 con 32 contratos negativos: commit `41f4ffc81a3a1281ce9ffd745184396fb5da1fa1`.
- Python `tests/tools/test_parallel_items_w02_campaign_005.py`: golden independiente `EXPECTED_09` (commit `0bb461929928f47b375125972ec66e2db08afcb8`), validación exacta de fila (commit `e92f847437d22766c81d71245254e858f51d2012`), guardas de código, tabla de naturalezas, persistencia y falta de handler (commit `6e393fe2c7a63bea57495cadefbcf02b69b5faa6`), y **16 mutaciones adversariales** (commit `4d3eeee97fe829fe34e54c5cc89df202f91169d6`).
- Progreso `docs/coordination/items_parallel_v1/reports/W02/CAMP_005_PROGRESO.csv`: fila 09 en `DEPENDENCIA_DOCUMENTADA`, `ci_run=AUTOMATICA_PENDIENTE`, commit `60e15a0405fb2d2eed687fa09d606d369f2d2438`.
- Godot no requiere cambio nuevo de runner: desde bloque 08 cubre `kind=mint_dependency`, naturaleza inicial variable, verificaciones de rechazo atómico, PARTY/STORAGE y SaveV2. Los cuatro IDs del bloque 09 se incorporan por fixture, no por falsa implementación de un handler.

Se realizó una comprobación estática final antes del informe: **14 criterios correctos**, nueve golden exactos, **36 IDs únicos**, 256 escenarios y 768 variantes de uso programadas. Estos resultados **no equivalen a una ejecución real de Python/Godot**.

## Estado de CI, riesgos y siguiente orden

**CI CAMP005 W02 sin certificación**: al consultar los runs y estados del commit anterior `7dd33cf4c988c7f7db0c7cddd88205578963c4c1`, GitHub devolvió `workflow_runs=[]` y `statuses=[]`; eso no demuestra que la CI no se haya ejecutado, ni PASS, ni FAIL. No se han recuperado logs Python/Godot del bloque 09 ni de regresiones CAMP004/CAMP003 del hito 05. No afirmar funcionalidad de las cuatro mentas por pasar contratos de rechazo. Sin pruebas GPU/UI, ni integración global en main/V28.

**Dependencia a elevar a IA6 (acumulada de bloques 08–09):** definir `effective_nature_id` separado de `nature_id`, persistencia SaveV2, recálculo de estadísticas y uso en combate, política de mentas redundantes, estado original tras evolución/intercambio, transacción de inventario y tests de regresión. Mientras no se implemente por responsable de código compartido, estas mentas no están conectadas.

**Próxima `p`:** revisar resultados reales de CI y ejecutar **solamente bloque 10/10** `brave_mint;quiet_mint;impish_mint;relaxed_mint`; comprobar primero la fuente en GitHub por posibles cambios. Es el hito de regresión final de CAMP003/CAMP004. No iniciar otra campaña ni modificar `main`/V28. Al terminar, emitir `CAMPAÑA_005_FINALIZADA` solo respecto al trabajo asignado y distinguir las dependencias de las pruebas efectivamente aprobadas.
