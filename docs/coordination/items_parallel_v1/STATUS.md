# IA6 — CAMPAÑA_004 W05 ACTIVADA Y BOOTSTRAP VALIDADO (2026-11-03)

**Nueva instrucción vigente:** el usuario autoriza dar trabajo inmediato a IA5/W05 sin esperar a otras IA. CAMPAÑA_003 W05 está **10/10**, 60 MT con CI Godot/Python [#41565822563](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41565822563) SUCCESS. Nueva CAMPAÑA_004 **solo W05**, reserva [60 MT `tm82`–`tm141`, 10 bloques](CAMPAIGN_004_W05_QUEUE_APPROVED.csv), [gate](CAMPAIGN_004_W05_GATE.md), [encargo](campaigns/CAMP_004_W05.md), [activación](CAMPAIGN_004_W05_ACTIVATION_MESSAGE.md), [manifiesto](CAMPAIGN_004_W05_BRANCH_MANIFEST.md). Nueva rama W05 `codex/calvo-items-20261103-w05-camp004` creada desde HEAD de CAMP003; colas y scripts CAMP004 presentes allí. La CI de arranque [#41570901863](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41570901863) `completed/success`, SHA `e91c103ca7085d9ef9dd3b809efaa37063cc0bd6`: **solo bootstrap 0/10, NO funcional**. La primera orden ejecuta bloque 01, después `p` avanza uno hasta 10. W01/W02/W03/W04 conservan CAMP003 y ramas/IDs; no se modifican. Protocolo V5 vigente. Nada a main, V28 o PR118. El fallo YAML del primer intento #41570776523 quedó corregido, no se debe confundir con fallo de Godot.

---

# IA6 — AUTORREPARACIÓN V5 ACTIVADA (2026-11-03)

**Orden operativa vigente:** [AUTONOMOUS_REPAIR_V5.md](AUTONOMOUS_REPAIR_V5.md), incorporada a [CAMPAIGN_GATE_003.md](CAMPAIGN_GATE_003.md), [adendo W04](CAMPAIGN_003_W04_ADDENDUM_GATE.md) y encargos W01–W05. Las cinco IA pueden diagnosticar y corregir tests, fixtures y defectos reales **de sus IDs y especialidad en su propia rama**, incluido el código de producción estrictamente perteneciente al dominio autorizado; conservando contrato, tests, regresiones y CI, sin pedir permiso IA6 por cada arreglo. **No** se autoriza modificar otra rama, `main`, V28, reglas globales sin definir ni funciones ajenas con conflicto. El límite 10 bloques permanece.

**CI de módulos:** los filtros del workflow en W01/W02/W03/W05 y el baseline árbitra se ampliaron para disparar pruebas al cambiar `modules/**`, además de pruebas. **W04 es una excepción comprobada:** una edición del workflow de su propia rama fue **DENEGADA por controles de seguridad de la herramienta**; NO debe intentar evadir ese control. La CI W04 existente sigue activa por cambios en su test/fixture/progreso, y un parche acompañado de pruebas sobre su SHA puede verificarse así. También fue denegada la escritura del archivo `COORDINATOR.md`; los demás documentos de autoridad se actualizaron. **Un protocolo no altera permisos/controles de seguridad reales de GitHub o herramientas.**

**Estado W04 tras consulta:** su rama `codex/calvo-items-20261103-w04-camp003` publicó pruebas del bloque 05 y el último workflow [#41560419495](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41560419495) terminó `completed/success`; la hoja de progreso a esa lectura aún reflejaba 04/10. Los commits exitosos demuestran capacidad general para publicar en su rama, pero no garantizan escritura de cada archivo. Evitar detenerse por prohibiciones antiguas no aplicables, respetando bloqueos técnicos reales.

---

# IA6 — REVISIÓN DE PROGRESO CAMP003 2026-11-03

**Comprobación GitHub:** IA1 04/10 (`eject_pack;electric_seed;focus_band`, CI nueva en curso), IA2 04/10 publicados y comenzó pruebas de 05/10 (CI nueva en curso), IA3 04/10 (`level_ball;nest_ball`) CI [#41558471582](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41558471582) **SUCCESS**, 122 checks Python + 490 Godot; IA4 02/10 (Sol, Oval, Mineral Negro) CI [#41556682246](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41556682246) **SUCCESS** 29 Python + 54 Godot, dependencia Piedra Oval correctamente sin resolver; IA5 05/10 MT, última CI en curso (04/10 había pasado). Ver [decisión IA4 para seguir con `p`](CAMPAIGN_003_W04_ITER02_REVIEW.md). Ninguna IA tiene 10/10.

**Regla:** no pedir permisos administrativos cada microbloque; `p` avanza un bloque de la cola ya autorizada si independiente. Una dependencia documentada NO se convierte en PASS funcional ni exige detener toda la familia si el siguiente bloque es autónomo. CI in_progress ≠ FAIL. Un FAIL real con raíz en producción/contratos compartidos sí exige STOP. Sin cambios a `main`, V28 ni ramas ajenas.

---

# IA6 — 2026-11-03: CAMPAÑA_003 AMPLIADA A CINCO IAs

**Corrección obligatoria del estado:** W04 sí está **recuperada y disponible**; había completado CAMP001 03/03 y pasó CI 559/0 en [#41538151097](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41538151097). Su antiguo informe `PENDIENTE_CI` es histórico. A petición del usuario se reincorpora a CAMP003 con [gate específico](CAMPAIGN_003_W04_ADDENDUM_GATE.md), [10 bloques/30 IDs nuevos](CAMPAIGN_003_W04_ADDENDUM_QUEUE.csv) y rama nueva `codex/calvo-items-20261103-w04-camp003`. [CI #41554077520](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41554077520) confirma `completed/success` de la **configuración W04 0/10**, NO funcional. Un primer run #41553918508 falló por dos nombres de pasos YAML sin comillas y fue corregido antes del SUCCESS.

**Estado operativo:** cinco trabajadoras W01/W02/W03/W04/W05; cada una con diez bloques autorizados, **50 bloques en total** y **180 IDs reservados**. La cola original de 40/150 para W01/W02/W03/W05 no cambia. La cola aditiva W04 es independiente para no interrumpir los chats ya activados. **Solo IA4 necesita el mensaje inicial [CAMPAIGN_003_W04_ACTIVATION_MESSAGE.md](CAMPAIGN_003_W04_ACTIVATION_MESSAGE.md)**; ejecutará su bloque 01, después `p` del 02 al 10. Ninguna modificación a las otras cuatro ramas, `main`, V28 o producción.

---

# IA6 — CAMPAÑA_003 LARGA ACTIVADA / AUTOPILOTO CI COMPROBADO (2026-11-03)

**Autoridad actual:** [GATE_003](CAMPAIGN_GATE_003.md), [manifiesto y cuatro arranques SUCCESS](CAMPAIGN_003_BRANCH_MANIFEST.md), [cola de 40 bloques/150 IDs](CAMPAIGN_003_QUEUE_APPROVED.csv), [mensaje único a cuatro chats](CAMPAIGN_003_ACTIVATION_MESSAGE.md). **W01/W02/W03/W05: 00/10**, sus ramas nuevas `codex/calvo-items-20261103-w0x-camp003` existen y están listas. IA4 CAMP001 **03/03 cerrada**, sin encargo nuevo.

**Nueva cadencia:** una activación inicial por trabajadora ejecuta bloque 01; cada `p` posterior ejecuta exclusivamente el siguiente de 02 a 10, sin nueva aprobación de IA6. Automatización al hacer push de test/fixture/progreso. Un run pendiente no significa fallo, y uno verde de bootstrap 00/10 **no certifica mecánica**. Falta de contexto/learnset o test fallido con causa de producción → STOP y auditoría; nunca modificar módulos compartidos sin permiso. Al 10/10 STOP.

**CI bootstrap 4/4 PASS (únicamente manifiesto):** W01 [#41551945208](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41551945208), W02 [#41551952771](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41551952771), W03 [#41551961372](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41551961372), W05 [#41551975872](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41551975872); no ejecutaron pruebas nuevas de Godot por no haber bloques.

**Límites:** CI y cola no prueban implementación de 150 IDs, ni 60 enseñanzas individuales, ni bolas sin contexto; W05 verifica compatibilidad según learnsets antes de enseñar. No tocar `main`, V28, PR #118, ramas viejas, reglas Mega, producción ni datos canónicos. Las entradas inferiores de CAMP002 03/03 y «CAMPAÑA_003 V4 no activada» ahora son históricas.

---

# IA6 — 2026-11-03: CAMPAÑA_002 03/03 TODAS, CI VERDE; V4 SIN ACTIVAR

**VERDAD ACTUAL (prevalece sobre estados antiguos `EN_CI_AUTOMATICA`, `PENDIENTE`, `02/03` que se ven más abajo):** [fotografía exacta de cierre](CAMPAIGN_002_FINAL_CI_SNAPSHOT_20261103.md). W01, W02, W03, W05 han publicado **03/03 de CAMPAÑA_002** y su última CI de GitHub Actions pasó en sus ramas: W01 [#41547041337](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41547041337) 1017/0, W02 [#41547218742](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41547218742) 838/0, W03 [#41547276442](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41547276442) 58/0 **negativos de tres bolas NO implementadas**, W05 [#41547169973](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41547169973) 703/0 (12 MT enseñadas). W04 finalizó CAMPAÑA_001 03/03 y tiene [CI #41538151097](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41538151097) PASS (559/0, SaveV2). Los HEAD posteriores a CI son **solo informes**, sin nuevos tests.

**No dar `p` a ninguna para otra iteración de CAMPAÑA_002:** los encargos actuales establecen STOP en 03/03. No es un problema de Godot ni de CI. IA6 preparó una [PROPUESTA de campañas de 10–12 bloques con cola auditada y `p` continua](LONG_CAMPAIGN_V4_DRAFT.md), **NO ACTIVADA**, para dejar de interrumpir cada tres bloques. Hace falta una autorización única de la nueva campaña y su manifiesto con IDs/rutas exactos. Se mantiene [CI_AUTOPILOT_V3.md](CI_AUTOPILOT_V3.md) ya probada; no crear trabajos sin encargos ni tocar `main`, V28, W04 o producción.

---

# CI AUTOPILOTO ACTIVO — 2026-11-02

**Operativa preferente:** [CI_AUTOPILOT_V3.md](CI_AUTOPILOT_V3.md) + [CAMPAIGN_GATE_002.md](CAMPAIGN_GATE_002.md). Cuatro workflows de ejecución por rama `parallel-camp002-worker-autoci.yml` ya instalados y **verificados mediante CI real**: [W01 #41539775567](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41539775567) SUCCESS, [W02 #41539808520](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41539808520) SUCCESS, [W03 #41539840311](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41539840311) SUCCESS, [W05 #41539925530](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41539925530) SUCCESS. **No requieren que IA6 monte un staging para cada `p`.** CI se dispara al subir tests/fixtures; no por informes. W01/W02 ya sincronizadas con sus runners corregidos (blobs `cc9fb835` y `73171d57`) sin alterar producción.

**Semáforo:** W01/W02/W03/W05 permanecen con **02/03 entregados CAMP002** según últimos CSV, y pueden ejecutar **una sola `p` para ITER03** en su rama. Mientras CI corre, puede avanzar un bloque exclusivamente de tests si no depende de resultado previo; debe declarar `EN_CI_AUTOMATICA`, nunca PASS sin comprobar SHA/run. En FAIL reparar script propio o bloquear si la causa no es aislable. **W04 CAMP001 03/03 finalizada, STOP.** Tras ITER03, cuatro workers STOP hasta nueva campaña autorizada; no autoasignar IDs.

**Para IA6:** supervisión por excepción y al final de campaña; no realizar cinco CI manuales por ronda. `main`, V28 y las ramas CAMP001 antiguas no se han modificado con este protocolo.

---

# ESTADO VIGENTE IA6 — 2026-11-02, CAMP_002 ITER_02 Y W04 CAMP_001 FINAL

**Puertas de verdad:** [CAMP002/ITER02 de W01–W03](CAMPAIGN_002_ITER02_CI_GATE.md) y [relevo W04 final / W05 ITER02](CAMPAIGN_HANDOFF_CI_GATE_20261102.md). **CI #41493879869 SUCCESS:** W01 Godot 687/0 y recibos Python, W02 800/0 y recibos Python, W03 37/0 negativos. **CI #41538151097 SUCCESS:** W04 SaveV2 559/0 en 12 casos, W05 MT 177/0 en seis enseñanzas; W05 selector 12 y Python 11 PASS. Los cinco conjuntos de pruebas se integraron en árbol árbitra como blobs exactos de staging, **sin modificar las ramas W ni producción**.

| Trabajadora | Estado confirmado | Orden próxima |
| --- | --- | --- |
| IA1/W01 | CAMP002 02/03, test 687/0 PASS en staging | `p` ITER03 **tras sincronizar el único runner corregido** desde árbitra blob `cc9fb835e5e999e991e1aa5ac58056ec5855da97` |
| IA2/W02 | CAMP002 02/03, test 800/0 PASS | `p` ITER03 **tras sincronizar solo el runner corregido** blob `73171d57101dab742bb9a27ce8a3027198b639de` |
| IA3/W03 | CAMP002 02/03, 37/0 pruebas negativas PASS; bolas sin implementar | `p` ITER03 de auditoría, prohibida implementación |
| IA4/W04 | CAMP001 03/03, SaveV2 559/0 PASS | **STOP definitivo de CAMP001**; no entra en CAMP002 |
| IA5/W05 | CAMP002 02/03, seis MT enseñadas 177/0 PASS | `p` ITER03 (ampliación de muestras y regresiones), sin modificar servicio |

**Importante:** pasar CI en staging no actualiza automáticamente las ramas W01/W02/W04. W01 y W02 deben leer [gate ITER02](CAMPAIGN_002_ITER02_CI_GATE.md) y aplicar la corrección mínima en sus ramas antes del tercer bloque, o STOP si hay conflicto. W04 no debe recibir más `p`. IA5 no debe confundir 6 enseñanzas verificadas con 229 enseñanzas individuales, ni con arte/UI aprobada. La nueva entrega ITER03 requiere otra CI. No iniciar CAMP003.

**Protección:** `main`, V28, PR #118, partidas y producción intactas durante esta coordinación. Las pruebas son Godot 4.7 headless y no sustituyen revisión visual/GPU.

---

> **IA6 / CI NUEVA DE ITER_02: BLOQUEO W01/W02 (2026-11-02).** El primer run [#41492689274](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41492689274) fue `FAIL`: W01 error de sintaxis al redefinir `OUT`; W02 sesiones `figy_berry` no arrancan con determinadas naturalezas; W03 37 tests negativos Godot PASS. [Diagnóstico completo](CAMPAIGN_002_ITER02_CI_DIAGNOSTIC.md) y reintento [#41493314741](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41493314741) con corrección/diagnóstico aislados (resultado pendiente al anotar). **No `p` para bloque 03 de W01 o W02 hasta nueva puerta.** El relevo IA4-CAMP001 y IA5-CAMP002 sí está autorizado.

# IA6 — RELEVO DE CHATS Y CAMP002 02/03 (2026-11-02)

**Puerta vigente para recuperar IA4 e IA5:** [CAMPAIGN_HANDOFF_GATE_20261102.md](CAMPAIGN_HANDOFF_GATE_20261102.md); [relevo exclusivo IA4](RELEVO_IA4_W04.md), [relevo exclusivo IA5](RELEVO_IA5_W05.md). El usuario ha pedido nuevas conversaciones para IA4/IA5: **se levanta únicamente la congelación de IA4 a fin de completar CAMP_001/ITER_03**; IA4 NO entra en CAMP_002 ni tiene rama nueva. Se conserva su rama antigua y 02/03 ya publicados. La prohibición histórica de reabrir IA4 que figura más abajo queda sustituida por esta puerta nueva para ese único bloque.

**Estado de GitHub hoy:** IA1/W01 CAMP_002 **02/03** (runner Godot de tres equipables nuevo, `PREPARADO_PENDIENTE_CI`); IA2/W02 CAMP_002 **02/03** (Leppa/Figy, CI nueva PENDIENTE), IA3/W03 CAMP_002 **02/03** (contratos de Dusk/Repeat/Dive, CI nueva PENDIENTE), IA5/W05 CAMP_002 **01/03** (selector Python y 12 parejas reales PASS #41484879741), IA4/W04 CAMP_001 **02/03** pendiente de SaveV2.

**CI anterior de ITER_01:** [#41484879741](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41484879741) PASS para cuatro familias. NO acredita los runners/reportes nuevos de ITER_02. IA1 no tiene FAIL probado: su naranja indica solo que falta CI. El próximo gate de pruebas lo dirige IA6, no cada trabajadora. IA4 no debe repetir ITER_01/02, IA5 no debe repetir ITER_01.

**Protección:** no editar `main`, V28, PR #118, ramas ajenas ni producción, y no activar CAMPAÑA_003. Relevo de identidad no equivale a reinicio de rama.

---

# IA6 — CAMPAÑA_002 / ITER_01 CI FINALIZADA (2026-11-02)

**Nuevo gate de continuación:** [CAMPAIGN_002_ITER01_CI_GATE.md](CAMPAIGN_002_ITER01_CI_GATE.md), respaldado por [Actions #41484879741](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41484879741) `success`. **W01 01/03, W02 01/03, W03 01/03, W05 01/03**: todos los microbloques 01 recibidos e integrados documentalmente/de pruebas en árbitra commit `60baf5b5`. Única corrección: W02 debe incorporar en **su rama nueva** el blob de runner `2e0ac1d2` de árbitra antes de continuar; no requiere cambiar producción, ni duplicar CI completa. Un `p` normal habilita ITER_02 bajo obligación de leer este gate. W04 congelada por decisión del usuario, nunca escribir en su rama.

**Alcance:** W01 contrato estático, W02 Godot 350/4 y Python 13, W03 contrato 9, W05 Python 11 y selector de 12 MT compatibles por catálogo. Solo W02 ejecutó nuevas mecánicas en Godot en ITER_01. Resto de las pruebas funcionales se harán en ITER_02/03. La previa [CI #41484446568](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41484446568) falló por el runner W02 comparando `[1]` con `[1.0]`, arreglado en staging y validado en la segunda ejecución. No afirmar que todos los efectos están finalizados.

---

# OPERATIVA VIGENTE — IA6 / CAMPAÑA_002 ACTIVADA (2026-11-02)

**Orden vigente:** [CAMPAIGN_GATE_002.md](CAMPAIGN_GATE_002.md); [manifiesto comprobado](CAMPAIGN_002_BRANCH_MANIFEST.md); [mensaje único a cuatro chats](CAMPAIGN_002_ACTIVATION_MESSAGE.md). La CAMPAÑA_001 se conserva cerrada/suspendida según GATE_005, no se reabre.

**IA1/W01, IA2/W02, IA3/W03, IA5/W05:** CAMPAÑA_002 autorizada, **00/03 cada una** hasta recibir la orden inicial de activación en su conversación. Cuatro **ramas nuevas** `codex/calvo-items-20261102-w01-camp002`, `w02-camp002`, `w03-camp002`, `w05-camp002`, todas creadas y verificadas en SHA inicial `67959eb8f19abfd2ae391872747a14f603fcab01`. No reusar ramas 20261101 ni mezclar informes de campaña antigua. **IA4/W04 congelada**, sin nueva rama ni encargado.

**Evidencia/triaje:** [CAMPAIGN_002_PRETRIAGE_VERIFIED.md](CAMPAIGN_002_PRETRIAGE_VERIFIED.md) separa fuentes existentes de pruebas pendientes, y [overlay de 267 IDs CAMP_001](CAMPAIGN_001_EVIDENCE_OVERLAY_V1.csv) evita duplicados. La cola histórica `QUEUE_V1.csv` y V27 no prueban que falten efectos. En esta campaña hay **12 microbloques potenciales**, solo nuevos tests/fixtures/reports, sin escritura de producción. Ninguna prueba CAMP_002 ejecutada aún.

**CI base:** Godot 4.7 #41364601482 y #41364601486 SUCCESS sobre `a8e09dbf`, seguidos únicamente de commits documentales. No representa PASS de pruebas aún no escritas. IA6 consolida CI por paquete; visual/GPU aparte.

**Activación en chats:** enviar una vez el texto universal a IA1, IA2, IA3 e IA5; ejecutan bloque 01 inmediatamente. Después `p` para 02 y 03 por chat. **No enviar nada a IA4** ni `p` aislada antes de esta reasignación.

---

> **PRETRIAJE PREVENTIVO IA6 — 2026-11-02:** [overlay exacto de 267 evidencias CAMP_001](CAMPAIGN_001_EVIDENCE_OVERLAY_V1.csv) contrastado con 744 filas de la selección, y [propuesta de CAMPAÑA_002 no activada](CAMPAIGN_002_PRETRIAGE_DRAFT.md). **W04 permanece congelada; ninguna W tiene nuevos permisos ni debe recibir `p`.** No sobrescribir `QUEUE_V1.csv` ni interpretar 226 MT sin prueba de enseñanza individual como funcionalidades sin implementar. `main` y V28 intactas.

> **RELEVO Y CONTROL ANTIDUPLICADOS (2026-11-02):** [CAMPAIGN_001_CLOSEOUT_AUDIT.md](CAMPAIGN_001_CLOSEOUT_AUDIT.md). IA6 ha cotejado las CI reales con el árbol integrado: W01/W02/W03/W05 03/03 STOP, W04 02/03 congelada, 14/15 preparados. `QUEUE_V1.csv` y el estado V27 son **anteriores a estas certificaciones**; no reasignar por su etiqueta histórica ni abrir CAMP_002 sin nueva orden. Todos los commits después del último SHA con CI PASS modificaron solo documentación.

# ESTADO VIGENTE — IA6 / CAMPAÑA_001, GATE_005 (2026-11-02)

**Autoridad actual:** [CAMPAIGN_GATE_UPDATE_005.md](CAMPAIGN_GATE_UPDATE_005.md). Los estados `PREPARADO_PENDIENTE_CI` de IA5 que figuran más abajo son históricos y quedan sustituidos por prueba real.

**Progreso publicado 14/15:** IA1 03/03 STOP; IA2 03/03 STOP; IA3 03/03 STOP; IA4 **02/03 CONGELADA, NO SUSTITUIR** a petición de la persona; IA5 03/03 STOP. La campaña global no se declara terminada 15/15. **No repartir `p` ni abrir nueva campaña** sin autorización expresa.

**IA5 tercera iteración VERIFICADA:** [staging #41364434498](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41364434498) y [CI sobre integración árbitra #41364601482](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41364601482), ambas `completed/success`; Godot 4.7 **1083 comprobaciones/0 errores**, Python 14 tests, mapa 248=229 activas SV+19 heredadas rechazadas. W05 test integrado commit `a8e09dbf`, mismo blob, sin editar `FieldItemService.teach`.

**Regresión general histórica** [#41364601486](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41364601486): **completed/success** sobre SHA integrado `a8e09dbf8b15c61f1b18207d34548ff8a7ca46e4`, con W01–W04 y veredicto consolidado PASS. CI específica W03/W05 [#41364601482](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41364601482) también PASS en el mismo SHA. Visual/GPU, interfaz real y modelos de libro siguen sin validar.

---

# IA6 — Auditoría del 2 de noviembre: doble CI verde, IA4 congelada

**Última decisión:** no ampliar campaña ni pulsar `p` en IA1, IA2 o IA3 (03/03 cerradas). IA4 sigue `CONGELADA_A_PETICION_USUARIO`, 02/03, sin reemplazo. IA5 aún 02/03 en rama propia `fe0ddcb26ea97543979fb20859675ca20d6613e9`; el único `p` permitido sigue siendo **ITER_03** del encargo original.

**CI de regresión antigua:** [#41362404118](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41362404118), árbol árbitra `7cf9586137532d95dc43b7a785d732b7ef45f32e`: `completed/success`, W01–W04.

**Nueva CI permanente y ligera:** [#41362733419](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41362733419), SHA `ef823e0d045c9d63b72905db638db5255ff10f06`: `completed/success` ejecutando W03 contrato + caracterización 34/0 + suite final Net Ball 60/0, y W05 Python 14 tests + libros 959/0. Nuevo workflow `.github/workflows/parallel-items-w03-w05-verified.yml` en rama árbitra, se dispara solo por cambios relevantes W03/W05; la CI histórica permanece intacta. La prueba de W05 **ITER_03 no existe aún**: estos resultados certifican exclusivamente ITER_02.

**Restricciones:** `main`, V28, PR #118, ramas W y archivos de IA4 sin modificaciones. Los PASS son de Godot 4.7 headless y pruebas declaradas, no GPU/visual, arte definitivo, pantalla de libros ni campaña completa.

---

# ESTADO ACTUAL — IA6 GATE_004, 2026-11-02

**Leer primero:** [CAMPAIGN_GATE_UPDATE_004.md](CAMPAIGN_GATE_UPDATE_004.md). **13/15 microbloques publicados.** W01/W02/W03 **03/03 cerradas, STOP**; W04 **02/03 congelada a petición del usuario**; W05 **02/03 verificado, autorizada solo ITER_03 al recibir un nuevo `p`**.

**CI recién terminada:** [#41362240030](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41362240030) Godot 4.7 PASS sobre staging `3dba6164...`. W03 nueva suite Malla Ball 60 comprobaciones/0 errores; W05 presentación 959/0; Python W05 14/14. Integración secuencial de esos mismos blobs en IA6 commits `60e2082e` (W03) y `5ebc65b4` (W05). No se han tocado ramas de las trabajadoras, main, V28 ni PR #118.

**Advertencia:** documentos antiguos más abajo contienen estados obsoletos `PREPARADO_PENDIENTE_CI`; prevalece esta puerta con su evidencia y SHA. Nunca abrir CAMPAÑA_002 por pulsar `p`. No hay verificación GPU/visual de libros.

---

# IA6 — Estado vigente (2026-11-01)

**Fuente de órdenes actual:** [CAMPAIGN_GATE_UPDATE_003.md](CAMPAIGN_GATE_UPDATE_003.md). La información de fallos y bloqueos en secciones antiguas de este archivo es HISTÓRICA; la puerta 003 prevalece para próximos `p`.

**Integración acumulada comprobada:** W03 Net Ball `82f9eea2`; W05 libros solo lectura `39df72c1`; W01/W04 pruebas `7b360f90`; W02 pruebas reparadas `52a5515e`. Los cambios de producción son exclusivamente W03/W05 previamente autorizados. Las ramas W01–W05, `main`, V28 y PR #118 no fueron modificadas por IA6 en este cierre.

**Evidencia reciente:** W01 2428 checks/24 filas PASS, W04 313/12 PASS, W03 V11 32406 + V15 51901 PASS, W05 18 checks PASS, W02 Godot 1544/16 PASS y Python 18 + validador PASS. **Importante:** pertenecen a runs concretos de staging y se detallan en [integración W01/W04](integration/CAMP_001_W01_W04.md), [W03/W05](integration/CAMP_001_W03_W05.md) y [W02](integration/CAMP_001_W02.md). No sumar estos números como si fueran comprobaciones únicas del juego entero.

**Regresión en SHA de árbitra posterior a W02:** [GitHub Actions #41354759130](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41354759130), SHA `52a5515e7615f988c3da907930979b86664a6430`: pendiente al publicar esta cabecera. Comprobar antes de certificar el árbol final como PASS. Sin prueba GPU/visual.

**Trabajadoras:** W01/03/04 pueden recibir un `p` para ITER_03; W05 puede recibir un `p` para ITER_02; W02 está terminada y no debe recibir más `p`. IA4 puede recuperarse con [relevo V2](PROMPT_RELEVO_W0X_V2.md) si el chat anterior es irrecuperable.

---

# IA6 — Nueva verificación de rama árbitra (2026-11-01)

**PASS confirmado en árbol integrado `7b360f90b74e18085f5b741722fd67fded88d23b`:** GitHub Actions [#41353674663](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41353674663), `completed/success` con Godot 4.7 y la regresión original LOTE_002. W01/W04 nuevas pruebas 01–02 ya tenían PASS de sus steps sobre staging #41350981613; W02 nuevo test quedó fuera de esa integración al fallar.

**Diagnóstico W02:** el JSON de semilla se lee en Godot como floats; `automation.seed == [23,19,29,43]` da falso por tipos. Para Persim, el espejo `showdown_backend._mirror()` solo proyecta `substitute` entre estados volátiles, mientras que el log nativo sí registra la confusión en los tres modos. El runner W02 de prueba corregido, sobre staging y con el test sin modificar en producción, pasó `1544 comprobaciones/16 casos` en [#41353949072](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41353949072). La versión más estricta con recibos del log nativo y validador Python sigue **PENDIENTE de PASS**: ejecución [#41354434516](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41354434516). No declararla integrada ni modificar ramas W.

---
# IA6 — VEREDICTO ACTUAL Y CAMPAÑA_001 (2026-11-01)

**Orden vigente:** [CAMPAIGN_GATE_UPDATE_002.md](CAMPAIGN_GATE_UPDATE_002.md), complementa `CAMPAIGN_GATE_001.md`. El texto histórico más abajo donde dice W03/W05 `STOP hasta CI` corresponde al período **anterior** al PASS y se ha sustituido por esta nueva puerta. Se conservan los registros históricos para trazabilidad.

**W03 y W05: INTEGRADAS y VERIFICADAS en IA6.** Commit W03 `82f9eea2`; W05 `39df72c1`. CI sobre árbol integrado [#41350909378](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41350909378): `completed/success`, SHA `71332b256621e49e98676ef5f0af48c145d1e86f`. W03 autorizada para ITER_03 tras nuevo `p`, W05 para ITER_02 tras nuevo `p`, conservando sus límites; ambas pruebas no implican GPU/visual.

**W01 y W04: tests 01–02 VERIFICADOS en staging y ahora INTEGRADOS como tests en IA6**, commit `7b360f90b74e18085f5b741722fd67fded88d23b`. Staging [#41350981613](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41350981613) tuvo W01 PASS (`2428 checks, 24 filas`) y W04 PASS (`313 checks, 12 casos`). Su resultado global es FAIL **por W02**. CI posterior de árbitra [#41353674663](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41353674663), veredicto PENDIENTE al documentar este estado. W01 puede preparar ITER_03; W04 también mediante relevo del chat si lo requiere.

**W02: CAMPAÑA_001_FINALIZADA como preparación, pero DEFECTO EN PRUEBAS / MECÁNICA PENDIENTE DE CLASIFICAR**. En paquete #41350981613 su Godot emitió `CAMP_001_W02 FAIL checks=1544 cases=16`; tres anomalías fuente: comparación de `seed` del fixture, escenario Persim ante `confuse_ray`, y cobertura derivada `per_item`. Los Python unitarios (18) pasaron; no equivale a PASS de Godot. **No enviar otro `p`, no integrar test fallido ni cambiar producción para forzar PASS.** Diagnóstico en staging [#41353549834](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41353549834), con aserciones originales preservadas, pendiente resultado al escribir este documento.

**Regla de trabajo:** IA6 gestiona CI/diagnóstico/integración, [protocolo V2](CI_AND_HANDOFF_PROTOCOL_V2.md), [relevo universal](PROMPT_RELEVO_W0X_V2.md). Ninguna de las cinco conversaciones funciona como agente autónomo de fondo; los nuevos `p` se entregan manualmente solo a chats que tengan bloque permitido. `main`, V28 y las ramas W son intocables para la coordinadora, salvo autorización expresa de recuperación excepcional.

---

# IA6 — Recepción parcial y CI consolidada preparadas (2026-11-01)

**Artefactos vigentes:** [protocolo V2](CI_AND_HANDOFF_PROTOCOL_V2.md), [mensaje único de relevo](PROMPT_RELEVO_W0X_V2.md), [acta W03/W05](integration/CAMP_001_W03_W05.md).

**W03 y W05 integradas parcialmente en árbitra**, sin modificar sus ramas de trabajo: W03 commit `82f9eea26d10976e6eb2702adce911bd7e1ed173` (Malla Ball + regresiones V11/V15 + puerta Python); W05 commit `39df72c1edda278108c74f29ed4b6053724528f6` (adaptador solo lectura y prueba Godot). Staging comprobado con Godot 4.7, [run #41350463036](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41350463036) `success`, SHA `c25f1616366a4c4432ee63fd49c001083d55647b`; V11 32.406 checks PASS, V15 51.901 PASS, Net 34 checks sin errores, W05 18 sin errores y mapa 248/229/19. Sin GPU/manual.

**CI exacta de integración árbitra:** [run #41350909378](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41350909378), ejecutada sobre commit funcional-documental `71332b256621e49e98676ef5f0af48c145d1e86f` **SIN VEREDICTO AL PUBLICAR ESTE REGISTRO**. No certificar como `INTEGRADO_VERIFICADO` ni levantar STOP W03/W05 hasta revisar resultado real.

**Prueba de paquete completo de cinco familias:** workflow [parallel-items-campaign-package.yml](../../../.github/workflows/parallel-items-campaign-package.yml), staging `codex/calvo-items-20261101-ci-camp001-pack`, SHA `6ea4cb1b9b68e0d1e33ef6a5228dcf57503a3456`, [run #41350981613](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41350981613). Se incorporaron solo pruebas propias de W01/W02/W04 para obtener cinco veredictos separados. **SIN VEREDICTO AL PUBLICAR ESTE REGISTRO.** No es permiso para reescribir producción ajena ni ejecutar otra campaña.

**Estado actual:** W01 02/03; W02 03/03 `CAMPAÑA_001_FINALIZADA` como entrega pendiente de prueba; W03 02/03 y W05 01/03 con CI de sus adaptadores favorable en staging y pendiente gate de integración; W04 02/03, chat de origen con error y rama preservada. Mantener STOP de W03/W05 por seguridad hasta verificación, W02 detenida por cierre, W04 recuperable por cuaderno, W01 03 solo bajo su campaña.

---

# ACTUALIZACIÓN DE IA6 — puerta de ejecución y relevo v2 (2026-11-01)

**Nuevo procedimiento oficial:** [CI_AND_HANDOFF_PROTOCOL_V2.md](CI_AND_HANDOFF_PROTOCOL_V2.md). Los cambios de producción y la certificación por CI son responsabilidad de IA6; las W publican microbloques y evidencias. Relevo de un chat con error: [PROMPT_RELEVO_W0X_V2.md](PROMPT_RELEVO_W0X_V2.md). No modifica las asignaciones vigentes ni permite exceder 3 microbloques por W.

**Estado de ramas comprobado:** W01 02/03, W02 03/03 con `CAMP_001_FINAL.md` (preparación cerrada), W03 02/03 con `net_ball` nueva sin PASS de CI, W04 02/03 preservada con problema de conversación, W05 01/03 con adaptador de lectura nuevo sin PASS de CI. **10/15 microbloques preparados; no 10/15 funcionalmente verificados.**

**CI antecedente #41349870689 = FAIL ENTORNO:** fallaron pruebas V11 tras `worker_handshake`, porque al staging le faltaba preparar simulador Node, y W05 se saltó por dependencia secuencial. No constituye un veredicto funcional negativo de Net ni de libros.
**CI corregida:** staging `codex/calvo-items-20261101-ci-camp001-smoke` commit `c25f1616366a4c4432ee63fd49c001083d55647b` y [run #41350463036](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41350463036). Incluye simulador fijado, setup Node y tests W03/W05 independientes; **estado pendiente hasta consultar resultado real**.
**STOP W03/W05:** seguir reteniendo siguiente microbloque hasta prueba de sus módulos y orden expresa IA6. W02 no recibe más `p`; W04 puede retomarse con mismo ID al abrir nueva conversación sin repetir 01–02; W01 tiene bloque 03 autorizado, pendiente de CI.

---

## Control operativo IA6 — 2026-11-01, actualización de campaña

**Estado comprobado en ramas:** W01 ITER_02/03 publicada (PREPARADO_PENDIENTE_CI); W02 03/03, `CAMP_001_FINAL.md` entregado (no PASS funcional); W03 02/03 con adaptación net_ball escrita y CI pendiente; W04 02/03, conversación con error referido por el usuario, ramas/commits preservados, no intervenir de momento; W05 01/03 recuperado, perfil de lectura de libros pendiente de CI. **Total 10 de 15 microbloques documentados.** La frase `PREPARADO_PENDIENTE_CI` no denota fallo del código; `BLOQUEADO_PENDIENTE_CI` es una puerta de control antes de continuar.

**Prueba de desbloqueo aislada:** staging `codex/calvo-items-20261101-ci-camp001-smoke`, commit `f7a46e7c6ccbd7cb356df14b42f97ab3e8679974`, CI [#41349870689](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41349870689). Coteja en Godot 4.7 únicamente adaptación W03 net_ball, tests V11/V15 y W05 perfil de consulta; `main`, V28, árbitra (producción) y ramas W inalteradas. **No declarar PASS ni levantar bloqueo hasta leer conclusión por SHA y logs.** No usar resultados de staging para certificar W01/W02/W04.

**Siguiente acción exclusiva IA6:** leer conclusión + logs de #41349870689; si FAIL, localizar causa y solicitar corrección estrictamente acotada; si PASS, registrar SHA, revisar diff y decidir integración de W03/W05 en árbitra antes de nueva autorización. W02 cerrado y pendiente de gate propio de seis bayas. La interrupción de chat W04 no invalida sus commits y su trabajo puede retomarse desde cuaderno sin volver a implementar los bloques 01–02.

---
# ESTADO CENTRAL — CAMPAÑA_001 ACTIVADA (1-XI-2026)

**Resultado de puerta:** PASS GitHub Actions [#41341842320](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41341842320), código `ac34fabbe1a27e69614f0239abee21c29d6fe65e`. Import Godot 4.7 y Node/Python verificados. W01 1332 checks PASS; W02 503 PASS; W03 caracterización de captura PASS **sin implementación de net_ball**; W04 100 PASS; W05 Python 248 MACHINE PASS estático. No se ha hecho GPU/visual.
**Integración de LOTE_002:** commit `30efddb618f0b3f397a3090568a070818c5cc36a` con 29 rutas de las cinco W; cuadernos `reports/W0X/CONTINUIDAD.md` presentes. Se corrigieron exclusivamente errores de test W02 (LoadResult) y W03 (orden constructor WildEncounterSlot) antes de PASS.
**Rama oficial:** `codex/calvo-items-20261101-arbitro`; `main` y V28 original intactas.

## Instrucciones vigentes

- **Puerta actual:** [CAMPAIGN_GATE_001.md](./CAMPAIGN_GATE_001.md) — `ACTIVADA`.
- **Campañas con tres microbloques por IA:** [W01](./campaigns/CAMP_001_W01.md) · [W02](./campaigns/CAMP_001_W02.md) · [W03](./campaigns/CAMP_001_W03.md) · [W04](./campaigns/CAMP_001_W04.md) · [W05](./campaigns/CAMP_001_W05.md).
- **Una sola activación de instrucciones:** [PROMPT_ACTIVACION_CAMP_001.md](./PROMPT_ACTIVACION_CAMP_001.md). Después, cada `p` = exactamente un microbloque de la campaña propia. No anticipar 002, no saltar bloqueo y parar tras 3.
- Las W trabajan **en sus propias ramas**, no en árbitra. Cada iteración publica `reports/W0X/CAMP_001_ITER_0N.md`, `reports/W0X/CAMP_001_PROGRESO.csv`, `CONTINUIDAD.md` y commit. IA6 revisará manifiestos compactos/diffs al cerrar un paquete o por fallo, no cada mensaje.
- **Permisos:** W01/W02/W04 tests propios; W03 captura Net Ball de alcance exacto; W05 perfil de lectura de libros. Modificar módulo compartido, política o guardado requiere nueva orden central.
- Un PASS de preparación sin ejecución real no certifica nuevas mecánicas. Toda nueva función se prueba tras integración en gate con SHA y evidencias.

## Estado inicial
W01, W02, W03, W04, W05: **CAMPAÑA_001_ASIGNADA, microbloque 01 pendiente**. Ninguna trabajadora ha ejecutado sus microbloques por crear estos documentos. Máximo 3 por W (15 totales), sin obligación de gastar toda la cuota de CI por cada documento.
**Conflictos cerrados temporalmente a producción:** `beast_ball` contradictoria, 19 máquinas legacy, Mega universal aplazada, Lujo/Ocaso con dependencias de contexto y guardado.

## Incidencia W05 — recuperación excepcional de publicación (2026-11-01)

Por solicitud expresa de la persona usuaria, IA6 intervino una sola vez sobre **las rutas ya autorizadas de W05** tras bloqueos de escritura de esa conversación. No se modificaron main, V28, otras W ni código compartido.
- W05 publicó previamente el adaptador de solo lectura en `318e6b96`; IA6 consiguió publicar el probe Godot (`62741e4d`), informe `CAMP_001_ITER_01.md`, CSV y actualización de cuaderno (`7ffd45a0`). Esto demuestra escrituras GitHub válidas desde el conector de IA6; no determina el motivo exacto de los rechazos de la sesión W05.
- El bloque 01 de W05 queda **PREPARADO_PENDIENTE_CI**, no integrado ni probado en Godot. El cotejo del perfil confirma 248 MACHINE = 229 SV + 19 históricas sin activar.
- **Gate:** antes de certificar o permitir avanzar a un microbloque que dependa del nuevo adaptador, ejecutar prueba Godot del SHA integrado y atender cualquier fallo. Los tests de la CI histórica no cubren este adaptador nuevo. W05 sigue siendo propietaria de su rama; esta intervención no autoriza cambios entre ramas de forma habitual.

