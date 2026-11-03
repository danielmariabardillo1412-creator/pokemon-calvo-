# IA6 · AUDITORÍA DE INTEGRACIÓN Y DEPENDENCIAS DE OBJETOS (2026-11-03)

**Estado:** auditoría documental y de código real, **sin reejecutar** las suites ya verificadas. **Alcance:** trabajo de IA1/W01–IA5/W05 hasta el corte aproximado del 3 de noviembre de 2026, 22:30 CET. **No es certificación de jugabilidad visual/GPU ni dictamen de que todos los objetos estén ya en `main`.**

## 1. Dictamen ejecutivo

**La preocupación del usuario es fundada, pero no significa que todo el trabajo sea inútil.** Se están haciendo dos cosas distintas: (a) contrastes valiosos de servicios de juego que ya ejecutan efectos, con tests automáticos, y (b) auditorías negativas de objetos que no pueden funcionar hasta que existan servicios de sesión, mundo, especies, forma o decisiones de política.

El método actual maximiza bloques y casos, no necesariamente *objetos jugables añadidos*. **No seguir sumando objetos auditados como si fueran integraciones funcionales.** La cifra de bloques `10/10` y una CI `success` certifican solo el contrato de pruebas expresamente ejercitado.

**Matriz de [22 grupos y 95 IDs afectados](INTEGRATION_DEPENDENCY_GROUPS_2026-11-03.csv):** 7 grupos P0, 14 P1 y 1 P2. Los 95 son **IDs distintos de ejemplo con seguimiento**, no 95 bloqueos íntegros ni un inventario completo de todos los objetos del juego: la matriz contiene estados parcialmente positivos y pendientes de revisión integral. Una misma infraestructura puede desbloquear bastantes ID; las cifras NO deben sumarse al censo de nuevos objetos ni al de funcionales.

## 2. Comprobación de integración real entre Git y runtime

- `main` inspeccionada en SHA `233b1a4f15ee4df7301e2c5acf8aed84a8f40626`; rama IA6 en SHA previo a esta auditoría `5ee858de5af234c24ecd63e0d1a2b58c4e9e7a8a`. Comparación de GitHub a ramas actuales: las cinco derivan de un bloque compartido y **no aportan cambios nuevos de `modules/` ni `scenes/` frente a la rama IA6** en el corte. Sus novedades son principalmente fixtures, pruebas, informes y CI. No equivale a que su trabajo no tenga valor, pero **no se están incorporando tantas mecánicas nuevas como sugiere el recuento de casos**.
- Hay **lógica de uso de objetos ya en `main`**: `modules/inventory/field_item_service.gd` (mismo blob SHA `b682c3af...` en main y W03), `field_growth_effects.gd` y `field_ability_effects.gd` (mismos blobs), `EvolutionSystem` base, `ShowdownAdventureSession` y `scenes/visual/field_item_bag.gd`. El servicio `FieldItemService.teach` también está ya en main; valida perfil SV, learnset, stock, PP, identidad y consumo. El `README.md` describe `scenes/visual/field_demo.tscn` como demo técnica que ya posee movimiento, combate, captura, mochila y guardado, **no un juego completo**.
- En cambio, el auxiliar `modules/inventory/field_machine_book_profile.gd` está en las ramas de trabajo/IA6 pero **no existe en main**; es un adaptador puro de consulta/presentación, no el motor `teach`. `capture_ball_effects.gd` y `progression_system.gd` tienen diferencias frente a main, por lo que requieren un *diff* y pruebas de integración antes de cualquier incorporación. **No fusionar ramas enteras por tener CI verde**: los historiales son grandes y divergentes.
- `main` permanece sin esas campañas nuevas; el PR **#118** sigue en borrador hacia main, no es evidencia de que los trabajos W01–W05 se hayan integrado. El hecho de que un helper exista solo en rama no implica que el juego en main no posea ya el efecto relacionado, ni lo contrario.
- **Distinción obligatoria:** `EN_CATALOGO` ≠ `FUNCIONA_SERVICIO` ≠ `FUNCIONA_SESION_DEMO` ≠ `INTEGRADO_MAIN` ≠ `VALIDADO_VISUAL_PC`. Guardar esta clasificación por ID/efecto; los positivos de una prueba negativa no ascienden de categoría.

## 3. Evidencias positivas, parciales y negativas representativas

| Evidencia | Valor certificado | Lo que NO prueba |
| --- | --- | --- |
| IA5/W05 CAMP003 + CAMP004 + CAMP005 hasta 06 | **60 + 60 + 36 = 156 MT distintas** con prueba de enseñanza en servicio real para especies de learnset compatible, PP, consumo/rechazo y SaveV2; la última [CI 06 #41722664035](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41722664035) fue PASS. La implementación `teach` base ya existía | Que sean compatibles con TODAS las especies, que haya libro gráfico definitivo, integración visual de cada MT o novedad de producción por cada ID |
| IA2/W02 CAMP004 y CAMP005 primeros bloques | Suite CAMP004 completa [#41589286005](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41589286005) PASS; en CAMP005 hay ruta real de `ability_capsule`, `ability_patch`, `rare_candy`, `pp_up`, posteriormente caramelos/PP, con ramas de efectos de campo que ya están en main | Que `razz_berry` y `hopo_berry` tengan efecto positivo: quedaron como contratos sin conectar |
| IA3/W03 `blue_flute` | Curación efectiva de sueño, reusable y sin consumo, en `FieldItemService`; auditoría CAMP004 bloque 02 | Que Flauta Negra/Blanca o Cuerda Huida funcionen. La Cuerda retorna `DEPENDENCY_MISSING / field_effect_not_connected` |
| IA3/W03 `safari_ball`, `sport_ball` | El multiplicador ×1,5 **sí existe** en `CaptureBallEffects`, comprobado [CI 05 #41721510769](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41721510769) | Control de zona Safari/Concurso y rechazo fuera de contexto; actualmente no hay productor autoritativo de zona especial |
| IA4/W04 CAMP004 | [CI final #41611102944](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41611102944): 36 ID auditados, **1 efecto recuperador real** `rage_candy_bar` (ya presente), **31 dependencias**, cuatro auditorías de datos/legacy | Que los 36 tengan sus efectos centrales, ni que las 16 dependencias anteriores de CAMP003 hayan desaparecido |
| IA3/W03 18 fragmentos Tera | Se puede añadir, retirar y guardar su cantidad en inventario | Teracristalización, cambio de tipo o uso en batalla: **no hay ejecutor conectado** |

**Fuente de los estados por bloque:** `reports/W02/CAMP_004_PROGRESO.csv`, `reports/W03/CAMP_004_ITER_02.md`, `reports/W03/CAMP_005_ITER_01.md`, `reports/W03/CAMP_005_ITER_05.md`, `reports/W04/CAMP_004_FINAL.md`, `reports/W04/CAMP_005_ITER_01.md`, `reports/W04/CAMP_005_ITER_03.md`, `reports/W05/CAMP_004_FINAL.md` y `reports/W05/CAMP_005_ITER_06.md` en ramas correspondientes. Se contrastaron además archivos reales de código y GitHub Actions. El corte puede quedar obsoleto si otros chats siguen publicando bloques.

## 4. Dependencias compartidas que más conviene solucionar

La [matriz CSV adjunta](INTEGRATION_DEPENDENCY_GROUPS_2026-11-03.csv) detalla IDs, frontera productora, consumidor y decisión para 22 subgrupos. **No resolver objeto por objeto donde el bloqueo es el mismo.**

**P0-A · Mundo/sesión de exploración, pasos y retorno.** `OverworldPortal` y `OverworldTraversalController` **sí existen en main**, con transición, coordenadas y guardas de movimiento. Para **Cuerda Huida** faltan la regla de destino seguro, un ancla por región y la transacción de inventario + transición + persistencia. Para Repelentes/Colonias/Flautas de encuentros faltan contador de pasos, modificador versionado de frecuencia, fase/caducidad y restauración. Puede compartirse un `OverworldItemContext` autorizado, pero NO hay que mezclar semánticas de regreso y de frecuencia: son dos consumidores separados. Un mapa mundial terminado NO es requisito para construir un **piloto en la demo actual** con una única región.

**P0-B · Contexto de captura.** `ShowdownAdventureSession.capture()` produce turno y nivel; `CaptureBattleContext` no tiene origen acuático/pesca, ambiente noche/cueva, ni un registro previo de especies capturadas. `dive_ball`, `dusk_ball` y `repeat_ball` están **bloqueadas por productores compartidos**, no por tres errores de fórmula independientes. `lure_ball`, `love_ball`, `moon_ball`, `beast_ball`, `heavy_ball` y la validación de Safari/Sport añaden información de especie, sexo, peso y reglas de modalidad. Separar **contexto de encuentro/mundo**, **contexto de especie** y **Pokédex persistente** para no inventar booleanos de test. El productor debe ser autoritativo y reconstruible de SaveV2.

**P0-C · Evolución real, identidad y condiciones.** La política válida `docs/current/ITEM_TRADE_RESTORATION_V27.json` manda convertir intercambio en **subida de nivel conservando el objeto equipado**. Los niveles definitivos están **`null`** y la implementación está marcada `DEFERRED`. Por tanto, nueve objetos de intercambio **no se pueden implementar correctamente hasta elegir los niveles**, el requisito `held_item` de `level_up_context` y una semántica de consumo/cancelación. Además `CreatureInstance` no guarda sexo y `EvolutionSystem` no interpreta de manera ejecutable `gender`, `time_of_day`, `held_item` ni luna llena. `oval_stone`, `dawn_stone`, `peat_block`, confites Alcremie y variantes forman un **sistema común de contexto evolutivo**, no decenas de fallos dispersos.

**P1-D · Formas y fusiones.** IA4 ha verificado algunos equipamientos/SaveV2; no sus transformaciones. Los orbes, `dna_splicers`, `reins_of_unity`, `rotom_catalog`, etc. dependen de un contrato de cambios de forma o una transacción de **dos criaturas**, con identidad, desfusión y rollback. Construir ese servicio una vez, con pruebas positivas para una pareja/forma piloto, antes de declarar otros objetos funcionales.

**P2-E · Teracristalización.** Los 18 fragmentos cuentan como almacenables, NO como mecánica. El Randomlock aún requiere definir si/cuándo implementarla. No asignar a W03 decenas de pruebas negativas adicionales de Tera sin decisión de arquitectura.

**P1-F · Integración visible, libros y recursos.** 156 MT han tenido rutas de enseñanza positivas hasta el corte en tests, pero W05 indica presentación textual y seis diseños/artes visuales aún sin cerrar. No confundir esa tarea visual/UI con rehacer la enseñanza que ya tiene servicio operativo.

## 5. Riesgo de seguir igual

**Riesgo ALTO de desperdiciar trabajo en W03/W04 si cada `p` solo añade otros negativos y otro informe de DEPENDENCIA.** No hace falta esperar a que W01 termine para auditar/integrar módulos compartidos, pero sí hay que **resolver el contrato del sistema productor ANTES de intentar implementar 20 consumidores que dependen de él**.

**Riesgo MEDIO de falso progreso en el dashboard:** `checked=PASS` mide controles, no objetos utilizables; `10/10` significa cola ejecutada, no feature lista. No extrapolar de los 156 ejemplos de enseñanza a TODO el catálogo, ni de 36 negativos seguros a 36 formas jugables.

**Riesgo MEDIO/ALTO de merge indiscriminado:** IA6 y las cinco ramas tienen historiales divergentes; las diferencias respecto a `main` incluyen cambios de producción compartidos y muchas suites. No fusionar ramas completas, mucho menos simultáneamente; utilizar un **carril de integración exclusivo** con cherry-picks/diffs limitados, contratos, smoke test de demo y control de SaveV2.

## 6. Plan de corrección recomendado por IA6

**Paso 1 — Registro único por ID (sin repetir pruebas):** de los informes existentes extraer `id`, `rama_sha`, `nivel_funcional`, `evidencia_ci`, `sistema_bloqueador`, `quien_decide`, `siguiente_prueba_necesaria`. Clasificar en cinco niveles:
- **L0 Catálogo/alcance:** seleccionado o inventariable, sin efecto.
- **L1 Rechazo seguro:** negativo, no consume ni corrompe; NO equivale a funcional.
- **L2 Efecto de dominio positivo:** función real Godot/Python, por ejemplo enseñanza o curación.
- **L3 Conexión de demo/sesión:** ejecutar el efecto desde mochila/combate/captura real y guardar/cargar el resultado.
- **L4 Integrado en `main` y comprobado visualmente en PC**. La integración a main y la prueba GPU son requisitos separados que deben constar, no asumirse.

**Paso 2 — Congelar la repetición improductiva, NO todo el trabajo:** IA2 y IA5 pueden seguir probando sus objetos con evidencia positiva y cobertura incremental. IA1 puede cerrar sus equipables. IA3/IA4 deben dedicar los siguientes hitos a los contratos/productores comunes, o declarar en un solo informe por grupo que no hay regla autoritativa. **No gastar una campaña entera en duplicar pruebas negativas de 20 objetos.**

**Paso 3 — Tres integraciones piloto de mínimo coste:**
1. **Cuerda Huida** en la demo: definir un `return_anchor` validado, reutilizar `OverworldTraversalController`, transacción atómica del ítem y SaveV2. Prueba positiva desde bolsa de demo y negativa sin destino, en combate, con mochila corrupta; confirmar posición y cantidad tras recarga. No precisa un mundo completo.
2. **Una Poké Ball contextual** (preferiblemente Dusk después de definir `world_time`/tipo de zona; o Repeat tras Pokédex de capturas). Conectar productor real → `CaptureBattleContext` → resolver → inventario/RNG. Regression de bolas previas y save.
3. **Una evolución con requisito compuesto** solo **tras** la decisión de niveles e identidad/consumo. Comenzar por una de las nueve trade→level y usar el mismo adaptador para las restantes; no inventar umbrales. Alternativamente, una evolución de contexto ya completamente definido.

**Paso 4 — Carril de integración IA6 (una rama, un contrato a la vez):** no tocar `main`/V28, primero revisar diff entre rama de integración y base; incluir patch mínimo y tests específicos + regresión focalizada de módulos afectados. Demostrar en `field_demo.tscn` mochila → efecto/encuentro → SaveV2 → recarga; tras CI headless y prueba visual local, proponer integración a rama de coordinación. En ningún caso marcar L4 por éxito aislado de CI.

**Paso 5 — Cuadro de mando real:** mostrar por grupo `IDs L0/L1/L2/L3/L4`, contratos resueltos, productores pendientes, CI más reciente, conflictos entre IA y evidencia visual. La métrica más útil será **sistemas desbloqueados × objetos efectivamente utilizables**, no número de microbloques.

## 7. Regla nueva propuesta, pendiente de decisión del usuario

Cuando un mismo contrato bloquea **3 o más IDs**, IA6 debería detener nuevas *auditorías negativas equivalentes* de esos IDs y abrir **un solo ticket de integración del productor común**, con ownership por función y criterio L3. Si la política de juego no está decidida (ej. niveles intercambio, Tera), decidirla primero; si requiere subsistema compartido, asignar un implementador y prohibir que cinco ramas lo cambien al mismo tiempo. Esta auditoría **no cancela ni altera unilateralmente** las colas CAMP005 vigentes; señala qué conviene reorientar.

## 8. Fuentes auditadas y límites

- [Rama coordinadora IA6](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/tree/codex/calvo-items-20261101-arbitro) y ramas W01–W05 correspondientes, comparación API GitHub por SHA de ramas (corte de 2026-11-03).
- [Main `FieldItemService`](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/main/modules/inventory/field_item_service.gd), [OverworldTraversalController](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/main/modules/overworld/overworld_traversal_controller.gd), [CaptureBattleContext](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/main/modules/capture/capture_battle_context.gd), [EvolutionSystem](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/main/modules/creatures/progression/evolution_system.gd), [Main README](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/main/README.md), [política de intercambio V27](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/main/docs/current/ITEM_TRADE_RESTORATION_V27.json).
- Informes de W03 CAMP004 y CAMP005, W04 CAMP004 y CAMP005, W02 CAMP004/005, W05 CAMP004/005; verificaciones de éxito Actions citadas arriba. **No se han reejecutado** tests ni completado inspección visual de cada objeto o escena desde este entorno. El recuento de objetos funcionales de TODO el catálogo no puede afirmarse con rigor hasta consolidar las fichas por ID y comprobar L3/L4.

**Protección:** ningún archivo de producción de juego modificado en esta auditoría; `main`, V28 y PR118 sin cambios. Solo documentación de coordinación IA6.
