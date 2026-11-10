# IA5/W05 — AUTORUN TANDA 03 FINALIZADA · Robustez de 229 libros

**Fecha:** 2026-11-10. **Responsable:** IA5/W05. **Rama exclusiva:** `codex/calvo-items-20261109-w05-books-ui`.
**Estado:** `TANDA_03_FINALIZADA` — **10/10 examinados, 10/10 funcionales como hitos de robustez, 0 bloqueados**.
**SHA del código probado:** `93b13e63e175f5156146e3a6c8c5795e9efa8517`.
**CI final validada:** [GitHub Actions #42870136602](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42870136602), `completed/success`, job `130019050606`.
**No son 10 MT nuevas:** TANDA01 y TANDA02 mantienen la cobertura 49 + 180 = **229 MT SV**. Se comprueban robustez y presentación de su panel separado.

## Auditoría de los diez hitos

| Hito | Alcance | Estado | Comprobaciones Godot V3 |
|---|---|---|---:|
| 01 | rendimiento 229 | CERTIFICADO | 260 |
| 02 | apertura cierre | CERTIFICADO | 16 |
| 03 | stock obsoleto | CERTIFICADO | 19 |
| 04 | propietario retirado | CERTIFICADO | 28 |
| 05 | cuatro slots cancelar | CERTIFICADO | 92 |
| 06 | orden tipo stock | CERTIFICADO | 253 |
| 07 | rechazos | CERTIFICADO | 26 |
| 08 | textos es fallback | CERTIFICADO | 474 |
| 09 | SaveV2 abierto | CERTIFICADO | 22 |
| 10 | ci resiliencia | CERTIFICADO | 2 |

**Recibo final del runner V3:** `W05_BOOKS_AUTORUN_V3_GODOT PASS blocks=10 functional=10 blocked=0 checks=1195`.
**Puerta estructural:** `W05_BOOKS_AUTORUN_V3_PY PASS blocks=10 books=229 checks=21`.

Los diez recibos individuales (`W05_BOOKS_AUTORUN_V3_HIT block=01..10 status=CERTIFICABLE`) fueron extraídos de los logs de CI para el mismo SHA. Son 9 suites headless independientes y una décima puerta de cierre de CI. No atribuir al hito 10 una mecánica nueva de juego.

### Cambios de producción en el panel

- La vista conserva el **ID exacto** del libro y del Pokémon seleccionados entre ordenaciones y refrescos. Si la selección desaparece por gasto, filtro o movimiento de equipo, queda **vacía y bloqueada incluso tras múltiples refrescos**; nunca se sustituye silenciosamente por otro libro/Pokémon.
- El control `_ready` evita reconstruir el panel y crear señales duplicadas al reabrirlo/reanexarlo; tras enseñar, el segundo evento no consume otra unidad.
- El panel restringe destinos a `PARTY` para la UI de selección del equipo y rechaza la propiedad desaparecida o depositada en `STORAGE`. No se cambia la regla central de `FieldItemService.teach`; es una garantía de esta vista.
- Ordenación segura por ID, nombre, tipo y cantidad, con **filtro por tipos calculados del perfil canónico** y metadatos de selección por ID. No se cambia el catálogo.
- El texto muestra aviso `traducción española no verificada` si la fuente de localización no acredita un nombre español. No se inventaron traducciones ni se modificó `SpanishGameText`.

### Evidencias específicas

- **Rendimiento reproducible, Godot headless CI:** 229 libros visibles, 10 refrescos: mínimo **5709 μs**, media **5820 μs**, máximo **6201 μs**. Son tiempos observados en este runner Ubuntu/Godot, sin benchmark comparativo ni FPS GPU. No equivalen a rendimiento visual en Windows/Android.
- **Ciclo de vida:** reapertura sin duplicar controles ni señales; una enseñanza consume una unidad y un evento repetido conserva el inventario.
- **Stock obsoleto:** al agotarse el libro con otro presente, refrescar no cambia la selección automáticamente ni permite gastar el alternativo; tras reponer stock la selección explícita vuelve a habilitarse.
- **Propiedad obsoleta:** depósito Party→Storage y retirada de la identidad provocan rechazo sin gasto; también se prueba retirada directa desde Party. Se recupera la selección únicamente al escogerla de nuevo.
- **Sustitución:** slots **0, 1, 2 y 3**, cancelación de la selección, otros movimientos y sus PP sin cambios, nuevo movimiento con PP canónicos y exactamente un libro consumido.
- **Bloqueos:** campo `field_locked`, incompatible real, movimiento ya conocido, movimiento prohibido por política simulada de forma **local al runner**, ausencia temporal de learnset SV en memoria del test y posterior restauración; todas las negativas conservan stock.
- **Auditoría del texto:** **229** presentaciones examinadas; **11** con nombre español acreditado mediante los nombres conocidos de `SpanishGameText.CORE_MOVE_NAMES` o los dos pilotos `Divide Dolor` y `Garra Metal`; **218** sin traducción española verificada en dichas fuentes. Se muestran como *fallback no verificado* y no cuentan como localización completa. **Ticket IA6:** decidir fuente oficial de traducciones y validación artística/localización; no publicar nuevas traducciones sin procedencia.
- **SaveV2 manual:** guardar mientras el panel está abierto, cargar inventario/Party, volver a vincular el servicio, invalidar stock, rechazar la selección obsoleta sin consumo y volver a guardar/cargar cantidades e identidad.

### Regresiones en el mismo run

- TANDA01 (49 libros): `W05_BOOKS_AUTORUN_GODOT PASS blocks=10 ids=49 functional=49 blocked=0 checks=2869`, contrato Python de 114 checks.
- TANDA02 (180 libros): `W05_BOOKS_AUTORUN_V2_GODOT PASS blocks=10 ids=180 functional=180 blocked=0 checks=10467`, contrato Python de 225 checks.
- Pilotos UI01/02: Godot **143** y Python **23** PASS.
- CAMPAÑA_006: Godot **1781** y Python **481** PASS.
- CAMPAÑA_005, 004 y 003: cada una Godot **2166**, Python **580** PASS.
- Cada ejecución histórica mantiene sus recibos y cobertura sin `continue-on-error`, sin skips de grupos y sin quitar aserciones.

### Iteraciones de reparación (sin reescribir la historia)

- CI [#42869167254](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42869167254): Python V3 PASS; fallo de sintaxis en nuevo test Godot, no en motor; corrección de tipado y contador local.
- CI [#42869562111](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42869562111): 6/9 escenarios de robustez positivos, fallos reproducibles de selección obsoleta y una expectativa de identidad retirada. Se reparó el **panel** con memoria del estado invalidado y se añadió prueba directa de identidad eliminada, conservando estados rechazados.
- CI [#42870136602](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42870136602): todas las puertas, **10/10 hitos PASS**, 0 bloqueados.

### Frontera de propiedad e integración

Modificados exclusivamente `scenes/visual/field_machine_book_panel.gd`, nuevo runner `tests/gameplay/parallel_items_w05_book_ui_autorun_v3.gd`, contrato Python `tests/tools/test_parallel_items_w05_book_ui_autorun_v3.py`, workflow W05 y documentación/CSV de progreso. No se tocaron `FieldItemBag`, `FieldItemService`, módulos centrales de SaveV2, learnsets, catálogos, políticas, localización compartida, `main`, V28, PR118 ni ramas de otras trabajadoras. **Sin merges**.

La robustez L3 se acredita en el **panel aislado Godot headless**, no en la instancia del panel dentro de la mochila integrada, ni en una sesión visual/GPU humana. IA6 es propietaria del montaje definitivo en `FieldItemBag` y de incorporar selectivamente las correcciones, con CI de integración y validación visual posteriores.

**ENTREGA A IA6:** `W05 TANDA 03 FINALIZADA — 10/10 examinados — 10 funcionales — 0 bloqueados — SHA 93b13e63e175f5156146e3a6c8c5795e9efa8517 — CI #42870136602 SUCCESS — AUTORUN_V3_FINAL.md`.

**STOP:** no iniciar TANDA04 ni inventar movimientos. Esperar próxima nota `IA6_AUTORUN.md` de IA6.
