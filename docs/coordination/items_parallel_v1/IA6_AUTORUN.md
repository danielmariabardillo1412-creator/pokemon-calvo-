# IA6 · W03 — MODO CAMPAÑA CONTINUA V2 ACTIVADO

**ORDEN PERMANENTE: YA NO SE PARA POR 10/10.** Esta orden sustituye la obligación `STOP al cerrar TANDA X` de la versión anterior, sin derogar permisos técnicos ni pruebas. Identifícate como W03, utiliza SOLO la rama `codex/calvo-items-20261104-w03-camp006`. El plan de trabajo completo se copia abajo y tiene varios bloques; **cuando uno termina con CI, pasa directamente al siguiente bloque del MISMO plan SIN PEDIR IA6**.

Con cada `p` o `sigue`: (1) consulta tu HEAD y esta nota; (2) lee o crea `docs/coordination/items_parallel_v1/CONTINUOUS_V2/STATE_W03.md` de TU RAMA; (3) continúa la primera tarea pendiente de toda la CAMPAÑA, no solo de la última tanda; (4) trabaja secuencialmente mientras el turno lo permita, registrando checkpoints cada 10. Si el contexto se agota, publica estado y una próxima `p` reanuda desde GitHub. **No te quedes diciendo «esperando tanda siguiente» si quedan fases preautorizadas en este plan.**

**Protocolo IA6 V2 (prioritario):** rama árbitra `codex/calvo-items-20261101-arbitro`, `docs/coordination/items_parallel_v1/CONTINUOUS_V2/README.md`. **Plan central y único:** `docs/coordination/items_parallel_v1/CONTINUOUS_V2/PLAN_W03.md` en árbitra (copia íntegra abajo). Si en el futuro IA6 actualiza este mismo archivo con una misión más reciente, leer siempre HEAD y respetar la última versión.

**Control de seguridad:** no autoautorizar módulos protegidos, no fusionar ramas, no editar main/V28/PR118, no mover trabajo de otra W. No atribuir a IA6 integración no realizada. Si toda la misión termina o el resto exige exclusivamente una seam compartida, publicar `READY_FOR_IA6` y detenerse; no crear bucles de QA vacíos. Si hay más tareas independientes, continuar sin esperar. **Una `p` no mantiene ejecución asíncrona ni abre otra conversación automáticamente.**

**Contabilidad en cada respuesta:** `CAMPAÑA fase | bloque n/total | objetos nuevos | ya certificados | L3 verdaderos | bloqueados | CI SHA | integración IA6 pendiente`. Un 10/10 de bloque no es 100% de campaña.

---

# W03 — CAMPAÑA CONTINUA V2 · CAPTURA Y CAMPO
**Rama:** `codex/calvo-items-20261104-w03-camp006`.
**Baseline:** TANDA05 `net_ball` L3 nativa certificada CI #42922912695 SUCCESS, 128 checks nuevos, 0 objetos nuevos; Repeat Ball L3 previa con captura real, ledger y SaveV2. No repetir esa suite para inflar conteos.

## Cola de cobertura nativa — 25 IDs conocidos o condicionados por productores
Primeros 18 IDs figuran en `CaptureRuleset.ordered_ball_ids()` actual. Últimos 7 son objetos cuyo comportamiento regional requiere contexto productor; **NO** convertirlos en soporte nativo por aparecer solo en un inventario.

| Bloque | IDs | Total |
|---|---|---|
| 01 | `poke_ball`, `great_ball`, `ultra_ball`, `master_ball`, `nest_ball`, `fast_ball`, `dream_ball`, `heal_ball`, `premier_ball`, `friend_ball` | 10 |
| 02 | `safari_ball`, `sport_ball`, `cherish_ball`, `quick_ball`, `timer_ball`, `level_ball`, `net_ball`, `repeat_ball`, `dive_ball`, `dusk_ball` | 10 |
| 03 | `lure_ball`, `love_ball`, `moon_ball`, `heavy_ball`, `beast_ball` | 5 |

Para `poke/great/ultra/master/nest/fast/dream/heal/premier/friend/quick/timer/level` comprobar camino de captura real con especie del catálogo, multiplier/guaranteed correctos, consumo, PP/estado, propiedad, SaveV2, lanzamiento fallido, no stock y regresión Repeat/Net. `safari_ball` y `sport_ball` aplican x1.5 sin evento de zona; registrar `PARCIAL` si el productor de zona requerido no existe.
Para `dive/dusk/lure/love/moon/heavy/beast`, registrar primero si existe origen pesca/surf/noche/cueva/sexo/piedra lunar/peso/ultraente **producido por el mundo** y versión canónica. Si no existe, ticket por productor común y `BLOCKED_CONTEXT`, seguir con otra bola; no inventar eventos de campo ni banderas de prueba. En caso de que falte selector de movimientos de encuentro (Magikarp `move_policy`), reproducir y aislar con test propio, pero NO editar la política ni el motor general.

Permisos: tests/fixtures/CI W03, adaptador **local específico de ball** de captura ya propiedad W03, corrección excepcional de `showdown_adventure_session.gd::capture` solo para un ID si prueba roja muestra dispatch defectuoso, sin alterar RNG/otras bolas. Prohibido tocar `SaveV2`, `FieldItemBag`, `PlayerCollection`, `CreatureInstance`, generadores de encuentros compartidos, reloj/sexo/mundo, rama de otra W y reglas globales.

**Continuidad:** tras cada 10, completar manifiesto y continuar siguiente 10 automáticamente hasta terminar estos 25. QA solo cuenta como QA, ID preexistente funcional no es nuevo. Si al agotar 25 no hay otra familia independiente con productor real, `READY_FOR_IA6`, no más tandas inventadas.


