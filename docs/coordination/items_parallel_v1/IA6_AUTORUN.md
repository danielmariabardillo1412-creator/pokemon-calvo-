# IA6 — V4 STAGING PREASIGNADA, PERO TODAVÍA NO ACTIVA · W01 · 2026-11-11
**NO ABANDONES TU CAMPAÑA ACTUAL.** IA6 ha preparado un relevo para DESPUÉS del cierre real READY_FOR_IA6 de tu misión V2 (held + gate 38/38 + ledger). Continúa EN ESTA RAMA original y completa las pruebas/CI y checkpoint antes de cambiar.
Cuando esté cerrada, **sin esperar otra nota IA6**, puedes usar la rama nueva ya creada codex/calvo-ia6-staging-20261111-w01-held; allí te espera docs/coordination/items_parallel_v1/IA6_AUTORUN.md con plan íntegro y docs/coordination/items_parallel_v1/CONTINUOUS_V4/STATE_W01.md. Activación condicionada a SHA+CI y working tree limpio. Si no está cerrada, la siguiente p sigue TU trabajo actual. Nunca reportar la staging como integrada en IA6.

---

# IA6 — VETO CARAMELO DINAMAX / dinamax_candy — 2026-11-11

**ORDEN VINCULANTE A W01:** el usuario descartó `dynamax_candy`. Ya está en `config/item_selection_v1.json::excluded_ids` de TU rama y el test de política exige rechazo de generación. No seleccionarlo, no incluirlo en nuevas colas de objetos ni invertir trabajo en su arte/función; los CSV antiguos `CANDIDATE`/`RETAIN_FOR_FUNCTIONAL_REVIEW` son auditorías HISTÓRICAS, no autorización. Excluye solo este ítem, no Rare Candy/Exp Candy/otras mecánicas no discutidas. Dictamen completo en rama árbitra: `docs/coordination/items_parallel_v1/IA6_EXCLUSION_DYNAMAX_CANDY_20261111.md`. El resto de TU plan continuo sigue vigente.

---

# IA6 · W01 — MODO CAMPAÑA CONTINUA V2 ACTIVADO

**ORDEN PERMANENTE: YA NO SE PARA POR 10/10.** Esta orden sustituye la obligación `STOP al cerrar TANDA X` de la versión anterior, sin derogar permisos técnicos ni pruebas. Identifícate como W01, utiliza SOLO la rama `codex/calvo-items-20261110-w01-gems-autobatch01`. El plan de trabajo completo se copia abajo y tiene varios bloques; **cuando uno termina con CI, pasa directamente al siguiente bloque del MISMO plan SIN PEDIR IA6**.

Con cada `p` o `sigue`: (1) consulta tu HEAD y esta nota; (2) lee o crea `docs/coordination/items_parallel_v1/CONTINUOUS_V2/STATE_W01.md` de TU RAMA; (3) continúa la primera tarea pendiente de toda la CAMPAÑA, no solo de la última tanda; (4) trabaja secuencialmente mientras el turno lo permita, registrando checkpoints cada 10. Si el contexto se agota, publica estado y una próxima `p` reanuda desde GitHub. **No te quedes diciendo «esperando tanda siguiente» si quedan fases preautorizadas en este plan.**

**Protocolo IA6 V2 (prioritario):** rama árbitra `codex/calvo-items-20261101-arbitro`, `docs/coordination/items_parallel_v1/CONTINUOUS_V2/README.md`. **Plan central y único:** `docs/coordination/items_parallel_v1/CONTINUOUS_V2/PLAN_W01.md` en árbitra (copia íntegra abajo). Si en el futuro IA6 actualiza este mismo archivo con una misión más reciente, leer siempre HEAD y respetar la última versión.

**Control de seguridad:** no autoautorizar módulos protegidos, no fusionar ramas, no editar main/V28/PR118, no mover trabajo de otra W. No atribuir a IA6 integración no realizada. Si toda la misión termina o el resto exige exclusivamente una seam compartida, publicar `READY_FOR_IA6` y detenerse; no crear bucles de QA vacíos. Si hay más tareas independientes, continuar sin esperar. **Una `p` no mantiene ejecución asíncrona ni abre otra conversación automáticamente.**

**Contabilidad en cada respuesta:** `CAMPAÑA fase | bloque n/total | objetos nuevos | ya certificados | L3 verdaderos | bloqueados | CI SHA | integración IA6 pendiente`. Un 10/10 de bloque no es 100% de campaña.

---

# W01 — CAMPAÑA CONTINUA V2 · EQUIPABLES DE COMBATE
**Rama exclusiva:** `codex/calvo-items-20261110-w01-gems-autobatch01`. **Especialidad:** equipables con efecto de batalla. La TANDA04 (10 IDs `leftovers`→`sitrus_berry`) está **EN CURSO**; su CI de `leftovers` estaba `in_progress` al emitir la orden V2. **No interrumpir ni fingir su certificación.**

## Ejecución de cola
**Fase A:** finalizar la TANDA04 YA AUTORIZADA en `AUTONOMY_V1/QUEUE_W01_TANDA_04.md` de árbitra. Seguir su CSV y CI sin reiniciar `leftovers`, sin solapar otras W ni generar mensaje IA6 al completar 10/10. **Inmediatamente después** pasar a Fase B.
**Fase B:** los siguientes **26 IDs verificadamente presentes** en `item_connections_v1.json::holdable_ids` al emitir V2, en tres bloques 10+10+6:

| Bloque | IDs preautorizados | Cantidad |
|---|---|---|
| 01 | `ability_shield`, `absorb_bulb`, `adrenaline_orb`, `big_root`, `expert_belt`, `amulet_coin`, `pure_incense`, `luck_incense`, `cleanse_tag`, `draco_plate` | 10 |
| 02 | `dread_plate`, `earth_plate`, `fist_plate`, `flame_plate`, `icicle_plate`, `insect_plate`, `iron_plate`, `meadow_plate`, `mind_plate`, `pixie_plate` | 10 |
| 03 | `sky_plate`, `splash_plate`, `spooky_plate`, `stone_plate`, `toxic_plate`, `zap_plate` | 6 |

Las placas se autorizan **solo como potenciadores de tipo en combate** cuando corresponda: no modificar especie o forma de Arceus ni mecanismos de W04. `amulet_coin`, `pure_incense`, `luck_incense`, `cleanse_tag` pueden requerir dinero/encuentros/cría: si no hay productor verificable y es un objeto de otra familia, registrar `DEPENDENCIA_FUERA_W01` y seguir, **no inventar gold/encounter/egg**.

**Fase C (solo si queda tiempo y hay necesidad real):** auditar los 26 resultados y las 10 filas de TANDA04 en recorrido `FieldItemService.equip → combate nativo Showdown → liquidación → SaveV2`. Ejecutar pruebas positivas y negativas que falten. Hacer CI final del workstream con regresión CAMP003–005, gemas T01–03 y equipables nuevos; no contar regresiones como nuevos IDs.

## Reglas de propiedad y parada
Verificar antes de tocar: `config/item_selection_v1.json`, política de contenido activa, definición y **certificación anterior** de cada ID; `holdable` no implica que sea un usable del juego. Si `YA_CERTIFICADO`, aportar SHA+prueba y saltar implementación. Si `NO_APLICA`, no sustituir con IDs no listados. Evitar berries W02, balls W03 y evolution/forms W04.
Autorizar tests/fixtures/workflow/informes W01 y reparación mínima **de la ruta específica del ítem** de held ya propia W01. Backend `native_engine.cjs` solo arreglo local del ID demostrado por prueba roja sin variar regla global. Prohibido `FieldItemBag`, `CreatureInstance`, `PlayerCollection`, `SaveV2` central, otros módulos/ramas. Si aparecen más equipables fuera de las 26 tras terminar, **crear propuesta lista concreta para IA6**, no autoconsentir un barrido ciego de 631 IDs.
No pararse en 10: continuar por todos los bloques hasta procesar 10+26 IDs o topar con bloqueo protegido de lo restante. Si acaba el turno, checkpoint y siguiente p; terminar en `READY_FOR_IA6`.



---

## Histórico vinculante de TANDA04 ya en curso — no reiniciar

# IA6 — W01 · TANDA 04 ACTIVA · ORDEN PERMANENTE

**IA6 ha certificado tu TANDA 03**: 10/10 hitos, CI #42918737459 `completed/success` sobre SHA `dd0eab2509e50e44597de3d8d39366b7f3f823b3`. No repitas la tanda 03: tu nueva asignación es TANDA 04.

**ACTIVADOR:** en cuanto recibas `p`, `sigue` o `continúa`, abre ESTE archivo en TU rama, comprueba HEAD y checkpoint de TANDA04, y comienza inmediatamente el primer hito pendiente. Trabaja los 10 sin pedir permisos por microbloque. Ante interrupción publica checkpoint y reanuda con la siguiente `p`; no existe trabajo en segundo plano garantizado. Si una fila está bloqueada por arquitectura protegida, ticket y siguiente objeto independiente; prohibido falsear PASS.

**Rama exclusiva:** `codex/calvo-items-20261110-w01-gems-autobatch01`. **Protocolo general:** `docs/coordination/items_parallel_v1/AUTONOMY_V1/README.md` en rama árbitra `codex/calvo-items-20261101-arbitro`. **Cola autorizada central:** `docs/coordination/items_parallel_v1/AUTONOMY_V1/QUEUE_W01_TANDA_04.md`. La copia integral de la cola está a continuación. No tocar main, V28, PR118 ni otras ramas. Al cerrar 10 filas, informe final, CI SHA correcta y STOP hasta nueva orden IA6.

---

# IA6 — W01/IA1 · AUTORUN TANDA 04: equipables competitivos, 10 candidatos reales
Fecha: 2026-11-11. Rama exclusiva: `codex/calvo-items-20261110-w01-gems-autobatch01`.

## Punto de partida CERTIFICADO
La TANDA03 anterior está **CERRADA**: 10/10 hitos; 18 gemas históricas comprobadas por recorrido real `PlayerInventory → FieldItemService.equip → FieldNativeSession/Showdown → settle_finished_battle → SaveV2`. **0 objetos nuevos en esa tanda**. CI final [#42918737459](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42918737459) completada SUCCESS sobre HEAD `dd0eab2509e50e44597de3d8d39366b7f3f823b3`, seis jobs SUCCESS. Informe `reports/W01/AUTORUN_V3_FINAL.md`. **No repetir las gemas** ni CAMPAÑAS 003/004/005.

## 10 objetos equipables a examinar, uno por fila
Todos los IDs siguientes aparecen en `modules/inventory/item_connections_v1.json::holdable_ids` del HEAD auditado, **pero holdable NO es una certificación funcional ni equivale a seleccionado en política**. Antes de implementarlos comprobar política efectiva, código de batalla, pruebas preexistentes y si ya se certificaron en CAMP001/002 u otra tanda. La prioridad es completar efectos reales faltantes sin reescribir funcionalidades que ya existen.

| Fila | ID | Criterio positivo de la mecánica real |
|---|---|---|
| 01 | `leftovers` | recuperación al final de turno con PS perdidos; control PS completos |
| 02 | `life_orb` | potencia de daño y retroceso propio; inmunidad/fallo sin daño según regla nativa |
| 03 | `choice_band` | potencia física y bloqueo real de movimiento; cambio/reset válido |
| 04 | `choice_specs` | potencia especial y bloqueo real de movimiento; reserva/cambio |
| 05 | `choice_scarf` | velocidad/orden y bloqueo real; prioridad e independencia de velocidad |
| 06 | `shell_bell` | curación proporcional a daño realmente causado; controles sin daño |
| 07 | `eviolite` | Defensa/Def. Esp. solo en especies que pueden evolucionar conforme al catálogo |
| 08 | `safety_goggles` | bloqueos canónicos de polvo/efectos de clima; no bloquear ataques ajenos |
| 09 | `black_sludge` | recuperación Poison y penalización no Poison; dueño y tick correctos |
| 10 | `sitrus_berry` | activación real por umbral HP, consumo una vez, sin doble disparo al restaurar |

**Regla antirrepetición:** Para cada ID, si ya existe efecto completo y probado en escenarios L3 comparables, registrar `YA_CERTIFICADO` con SHA+CI+prueba y no contar como objeto nuevo; ejecutar únicamente el test faltante de integración si procede. Si está excluido, `NO_APLICA`. Si no hay soporte real, implementar y probar en seam local autorizado. Si varias filas resultan `YA_CERTIFICADO`, los **únicos suplentes preseleccionados** son `adrenaline_orb`, `absorb_bulb`, `rowap_berry` (también holdable): sustituir como máximo 3 filas ya certificadas, documentando la correspondencia; NUNCA contar dos veces. No ampliar más la tanda sin IA6.

## Contrato técnico y autonomía
1. `p`/`sigue` significa: leer `IA6_AUTORUN.md` de tu propia rama, comprobar checkpoint y ejecutar **la primera fila pendiente y las siguientes hasta 10** sin pedir autorización por objeto. Si acaba turno, guardar checkpoint y reanudar con otra `p`. Sin ejecución ficticia entre turnos.
2. Por cada objeto: efecto positivo del motor **nativo que ya usa el juego**, control sin objeto/tipo/portador/condición, consumos y resets correctos, uso desde `FieldItemService.equip` con propietario real, batalla, `settle_finished_battle` y SaveV2/legacy cuando proceda, no RNG fabricado; compatibilidad con Transformación/reserva cuando aplique. Usar fuente de reglas ya fijada en el repo; **no inventar multiplicadores ni simplificar efectos**.
3. Pruebas nuevas Python + Godot + nativo Showdown para cada efecto L2/L3, y CI acumulativa de CAMP003/004/005, T01/02/03, sin bajar denominadores ni `continue-on-error`.
4. **Permiso de modificación:** solo adaptadores/funciones **específicas del ítem** dentro del seam de held W01 ya usado y propio; tests/fixtures/runner/workflow e informes W01. `modules/battle/backends/showdown/native_engine.cjs` se permite **exclusivamente si un test rojo reproduce un fallo localizado del ID y el arreglo no cambia reglas globales ni otros objetos**. `FieldItemService`, `FieldItemBag`, `PlayerCollection`, `CreatureInstance`, `SaveGameRepository`, `SaveV2`, captura W03, formas W04 y panel W05 son solo lectura. Si un objeto exige seam protegido más amplio, prueba roja + ticket y sigue con otro.
5. Al finalizar: `reports/W01/AUTORUN_V4_PROGRESS.csv`, `reports/W01/AUTORUN_V4_FINAL.md`, SHA funcional, CI final real. Métricas separadas: **10 filas examinadas | N objetos nuevos implementados | M ya certificados | K bloqueados | efectos L3 realmente nuevos | integración en rama IA6: NO**. No se atribuye a W01 la integración conjunta de IA6. STOP tras las 10 filas.

**Protegido:** `main`, V28 y PR #118 intactos, no merges ni escritura en otras ramas. La integración final de W01/W02/W03/W04/W05 será una puerta independiente de IA6.
