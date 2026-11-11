# IA6 — ESTADO OPERATIVO ACTUAL · 2026-11-11

**SE HAN PUBLICADO NUEVAS MISIONES EN LAS CUATRO RAMAS FINALIZADAS:** W02 V3 (participación real / EXP Share sin activar XP global), W03 V3 (Heavy/Moon/Beast con productor auténtico), W04 V3 (7 evoluciones regionales L3 con permiso mínimo compartido), W05 V3 (panel MT dentro de FieldItemBag solo en su rama). W01 sigue V2 Fase B (26 equipables autorizados, 2 placas con CI piloto SUCCESS y acumulativas en seguimiento); NO reiniciarla. **Las cinco notas IA6_AUTORUN.md fueron leídas y verificadas; hay checkpoint V3 para las cuatro renovadas.** Informe [CONTINUOUS_V3/IA6_HANDOFF_20261111.md](CONTINUOUS_V3/IA6_HANDOFF_20261111.md).

El usuario puede pulsar `p` para que W02–W05 arranquen nuevas fases, y W01 continúe la ya vigente. Sin STOP cada diez; STOP solo al agotar misión o topar arquitectura protegida. **Rama integrada IA6 aún no recertificada**: trabajo propio pendiente de integración selectiva W01–W05 y CI conjunta. main/V28/PR118 protegidas.

---

# IA6 — CAMPAÑAS CONTINUAS V2 ACTUALMENTE VIGENTES · 2026-11-11

**CAMBIO CONFIRMADO EN LAS CINCO RAMAS:** `docs/coordination/items_parallel_v1/IA6_AUTORUN.md` ahora incorpora `CONTINUOUS_V2/PLAN_W0X.md` y la regla **NO STOP CADA DIEZ**. Cada ventana avanza varias etapas preautorizadas por especialidad sin pedir otra tanda a IA6; escribe un checkpoint `docs/coordination/items_parallel_v1/CONTINUOUS_V2/STATE_W0X.md` en SU rama. Documentación maestra [CONTINUOUS_V2/README.md](CONTINUOUS_V2/README.md). Colas [W01](CONTINUOUS_V2/PLAN_W01.md) / [W02](CONTINUOUS_V2/PLAN_W02.md) / [W03](CONTINUOUS_V2/PLAN_W03.md) / [W04](CONTINUOUS_V2/PLAN_W04.md) / [W05](CONTINUOUS_V2/PLAN_W05.md).

**Situación al emitir:** W01 T04 en curso (leftovers primer ID con CI pendiente); tras T04, 26 candidatos W01. W02 T04 cerrada → 42 bayas W02. W03 T05 cerrada → 25 balls y fuentes de captura. W04 T05 cerrada → contratos/evoluciones de 57 formas regionales; L3 protegido IA6. W05 T05 cerrada → preparación de integración y QA export/panel; al agotar backlog READY_FOR_IA6. Prohibido transformar un 10/10 de hitos en 10 objetos; prohibido rellenar plan con auditorías vacías. Cambio de ventana: releer nota+STATE; sin ejecución automática entre turnos. **Integración IA6 aún pendiente; no tocar main/V28/PR118.**

---

# IA6 — RELEVO REAL PUBLICADO EN LAS 5 RAMAS · 2026-11-10

**CONFIRMACIÓN DE LECTURA REAL:** W01 sigue TANDA03 (no tiene cierre CI final de V3; no duplicar), W02 nueva TANDA04 `b1579efd264a324c3c3ef78e3a94d40881a3c3`, W03 nueva TANDA05 `393a764287a9a5060b7474dc7d62d11a6eeea5ee`, W04 nueva TANDA05 `a2a80caeb1589f4b5d14efd49060f9956a9282cc`, W05 nueva TANDA05 `be880dd58cd3ed5d8e24a61c7624d167a9813a88`. **Todas las 5 notas de `IA6_AUTORUN.md` han sido leídas de nuevo y contienen su cola correcta.** El usuario puede enviar `p` sin repetir prompts: cada ventana debe abrir su nota y comenzar el primer hito sin cerrar.

**BASELINE CERTIFICADO:** W02 T03 #42890511612 SUCCESS, W03 T04 #42891930750 SUCCESS, W04 T04 #42890685931 SUCCESS, W05 T04 #42894306446 SUCCESS. No asignar errores ya resueltos ni diez objetos ficticios. Novedades de las colas: W02 quitar recálculo duplicado de Growth tras evolución y menta; W03 Net Ball nativa real; W04 condiciones de evolución regional sin saltarse políticas; W05 export Windows/PCK real de nombres ES; W01 cerrar gemas desde mochila. Independencia técnica en ramas propias: IA6 sigue pendiente de integración selectiva de W02/W03/W04/W05 en `codex/calvo-ia6-integration-20261109` con CI conjunta, NO está certificada ni se ha realizado merge. Prohibido tocar `main`, V28, PR118.

---

# DECISIÓN PRIORITARIA IA6 · 2026-11-10 · NO ENCADENAR MÁS TANDAS CIEGAS

**W04 y W05 TANDA04 verificadas contra código y logs reales**: W04 cuatro variantes regionales desbloqueadas por habilidad normal, 55/56 nativas positivas y 1 bloqueada; CI #42890151094 y #42890685931 SUCCESS. W05 229 etiquetas españolas de PokeAPI local, 0 MT nuevas, CI #42893621203 y #42894306446 SUCCESS, visual headless panel aislado, no GPU. Ver [auditoría completa](AUTONOMY_V1/IA6_AUDIT_W04_W05_TANDA04_REALITY_GATE_20261110.md).

**Siguiente prioridad IA6:** integrar selectivamente trabajo certificado aislado de W02/W03/W04/W05 en rama `codex/calvo-ia6-integration-20261109` y ejecutar CI conjunta de campo, batalla, SaveV2, naturaleza efectiva, formas, Repeat Ball y libros MT ES. **No publicar aún TANDA05 W04/W05**, porque cerraron y su limitación real es la integración, no falta de otras diez verificaciones. No tocar main, V28, PR118. Aclaración de progreso: 10/10 son hitos, NO 10 objetos, NO 10 tandas.

---

# IA6 — ÚLTIMO RELEVO COMPLETO 2026-11-10

**LAS CINCO RAMAS TIENEN ORDEN ACTIVA NUEVA:** W01=TANDA03, W02=TANDA03, W03=TANDA04, W04=TANDA04, W05=TANDA04. W04 finalizó TANDA03 **51/56 formas regionales canónicas, 5 bloqueos por política** y tiene CI #42876057234 y #42876625902 SUCCESS; su nota fue renovada en commit `b4e9837bad9609565200e0e3c50167e8a8a3937b`. Las demás notas nuevas fueron comprobadas en sus ramas. [Auditoría completa actualizada](AUTONOMY_V1/IA6_AUDIT_RELAY_20261110_1922.md).

**Para reanudar:** el usuario solo envía `p` a cada trabajadora. Ellas consultan su propio `docs/coordination/items_parallel_v1/IA6_AUTORUN.md`. No existe renovación automática sin una nueva escritura IA6. Distinguir 10 hitos / cantidad de objetos reales / integración conjunta. No se ha hecho merge a main/V28/PR118.

---

# IA6 — RELEVO ACTUAL 2026-11-10 · 19:22 EUROPE/MADRID

**AUDITORÍA:** [AUTONOMY_V1/IA6_AUDIT_RELAY_20261110_1922.md](AUTONOMY_V1/IA6_AUDIT_RELAY_20261110_1922.md). Certificadas TANDA02 W01 (5 gemas, 5 QA), W02 (9 hitos funcionales con mentas, 1 QA), TANDA03 W03 (Repeat Ball L3, QA07/08 parciales), W05 (229 MT ya existentes, 10 QA). **W04 NO se cierra:** TANDA03 con CI de último HEAD aún no certificada.

**Colas ACTUALIZADAS YA EN RAMAS PROPIAS:** W01=T03 `QUEUE_W01_TANDA_03.md`; W02=T03 `QUEUE_W02_TANDA_03.md`; W03=T04 `QUEUE_W03_TANDA_04.md`; W05=T04 `QUEUE_W05_TANDA_04.md`. W04 sigue T03 sin modificar, bajo supervisión. Todas utilizan `docs/coordination/items_parallel_v1/IA6_AUTORUN.md` de su propia rama. Usuarios pueden dar `p` solo a W01/W02/W03/W05 para trabajo **nuevo**; W04 puede seguir en su cola actual. Hitos != objetos nuevos != integración conjunta IA6.

**Riesgo prioritario IA6:** integración `codex/calvo-ia6-integration-20261109` sigue en SHA `f4a5687bff1aaf0fb443c36ca4c2873f5d0ac54e` (#42701239557 SUCCESS) y NO incorpora automáticamente las nuevas ramas posteriores. El relevo autónomo de trabajadoras NO es un merge. Cada incorporación debe reconstruirse por función y comprobarse con CI conjunta, sin tocar main/V28/PR118.

---

# IA6 — ACTUALIZACIÓN VERIFICADA · 2026-11-10 · CINCO TANDAS PUBLICADAS

**Prioridad de continuidad:** [AUTONOMY_V1/IA6_AUDIT_FIVE_WORKERS_AND_HANDOFF_20261110.md](AUTONOMY_V1/IA6_AUDIT_FIVE_WORKERS_AND_HANDOFF_20261110.md). Confirmados: W01 TANDA01 CI #42730773059 SUCCESS **pero CSV sin cerrar**; W02 TANDA01 10 mentas L3 #42730263746 SUCCESS; W03 TANDA02 Repeat Ball L2, native L3 bloqueado, #42736177949 SUCCESS; W04 TANDA02 forma real Slowpoke Galar y SaveV2, no evolución por objeto, #42735277975 SUCCESS; W05 TANDA02 180 MT + 49 previas = 229/229 positivas en panel aislado, #42734399078 SUCCESS. Las cinco CI se verificaron por jobs/logs, no solo informes.

**YA PUBLICADAS EN CADA RAMA:** `docs/coordination/items_parallel_v1/IA6_AUTORUN.md` con tandas W01=02, W02=02, W03=03, W04=03 y W05=03. Una `p` basta para reanudar; sin orden adicional por microbloque. W01 documento cierre previo; W02 interoperabilidad Growth/Mochi; W03 Repeat Ball nativo; W04 56 formas regionales fuente; W05 robustez UI de 229. No hay merge a main/V28/PR118 ni integración conjunta de estos cambios posteriores; no confundir CI de ramas aisladas con CI de producto integrado.

---

# ACTUALIZACIÓN IA6 — TANDA 02 ACTIVADA EN W03/W04/W05 · 2026-11-10

**Tandas cerradas y verificadas:** W03 #42729137809 SUCCESS (10 revisadas/0 nuevas), W04 #42729967922 SUCCESS (10 revisadas/0 formas o fusiones nuevas), W05 #42730140482 SUCCESS (49/49 MT panel headless). Auditoría [IA6_AUDIT_BATCH01_AND_HANDOFF_BATCH02_20261110.md](AUTONOMY_V1/IA6_AUDIT_BATCH01_AND_HANDOFF_BATCH02_20261110.md).

**Notas permanentes TANDA02 escritas en cada rama:** W03 = [QUEUE_W03_TANDA_02.md](AUTONOMY_V1/QUEUE_W03_TANDA_02.md), captura persistente/Repeat Ball; W04 = [QUEUE_W04_TANDA_02.md](AUTONOMY_V1/QUEUE_W04_TANDA_02.md), identidad de forma persistente; W05 = [QUEUE_W05_TANDA_02.md](AUTONOMY_V1/QUEUE_W05_TANDA_02.md), otras 180 MT restantes de un total de 229. Usuario solo pulsa `p`; cada trabajadora lee su propio `IA6_AUTORUN.md`. No duplicar auditoría anterior ni atribuir L3 a nuevos productores antes de CI.

**Conflicto controlado:** W03 y W04 pueden tocar funciones distintas de `SaveGameData` / `field_native_save.gd` en ramas propias; **IA6 integrará selectivamente** conservando naturaleza efectiva y todos los tests, nunca merge automático. No se ha llevado todavía el código de estas nuevas ramas a `codex/calvo-ia6-integration-20261109`, `main` ni V28.

---

# ESTADO VIGENTE IA6 — TANDAS AUTÓNOMAS · 2026-11-10

**CAMBIO DE OPERACIÓN:** ya no pedir autorización a IA6 al finalizar cada microbloque. Se han publicado **cinco colas de diez filas**, una por trabajadora, y copiado la orden a `docs/coordination/items_parallel_v1/IA6_AUTORUN.md` de SU rama. Protocolo vinculante: [AUTONOMY_V1/README.md](AUTONOMY_V1/README.md). IA6 verifica una sola vez al cerrar diez filas, con CI de SHA. `p` o `sigue` reanuda cola; no es una orden nueva de una sola fila. Un bloqueo local se registra y se salta, sin falso PASS ni modificaciones fuera de permiso.

**Estados de partida comprobados:** W01 CAMP005 10/10 (última CI funcional #42717306543 SUCCESS), nueva rama exclusiva `codex/calvo-items-20261110-w01-gems-autobatch01`; W02 MINT-L3 02 tiene tres mentas positivas (39 Python, 223 Godot) pero CI global #42715490604 FAILURE por 3 expectativas negativas históricas: la política de doble puerta queda AUTORIZADA en cola W02; W03 repelentes L3 CI #42716742131 SUCCESS, B04/B05 aún bloqueados; W04 resolver Milcery puro L2 CI #42715401401 SUCCESS sin productor L3, completed=3; W05 LIBROS UI02 CI #42714738745 SUCCESS, panel mejorado todavía pendiente de incorporar en rama IA6. No confundir la CI integrada anterior V3 (#42701239557 SUCCESS) con estas ramas más recientes.

**Ramas y notas:** ver [AUTONOMY_V1/QUEUE_W01.md](AUTONOMY_V1/QUEUE_W01.md), [W02](AUTONOMY_V1/QUEUE_W02.md), [W03](AUTONOMY_V1/QUEUE_W03.md), [W04](AUTONOMY_V1/QUEUE_W04.md), [W05](AUTONOMY_V1/QUEUE_W05.md). No hay merge a main.

---

# IA6 — REFERENCIA OPERATIVA VIGENTE · 9 DE NOVIEMBRE DE 2026

**INTEGRACIÓN CERTIFICADA MÁS RECIENTE:** [IA6_INTEGRATION_CERTIFICATION_V3_20261109.md](IA6_INTEGRATION_CERTIFICATION_V3_20261109.md). CI [#42701239557](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42701239557) `completed/success` en SHA `f4a5687bff1aaf0fb443c36ca4c2873f5d0ac54e` de `codex/calvo-ia6-integration-20261109`. Test de menta desde bolsa a **FieldNativeSave real** 18 PASS, además de W01 Transform, W02 3 mentas, W03 Cuerda Huida y W05 Libros mochila L3, V18 y conexiones. Ningún merge a main/V28/PR118; no toda la campaña de objetos está integrada.

**NUEVA ORDEN AUTORIZADA PARA W03:** [CAMPAIGN_006_W03_BLOCK03_REPEL_L3_WORLD_SEAM_AUTH_20261109.md](CAMPAIGN_006_W03_BLOCK03_REPEL_L3_WORLD_SEAM_AUTH_20261109.md) permite solo en rama W03 los seams de `field_demo.gd` y `field_native_bridge.gd` listados para terminar 03 L3, con RNG consumido una vez, SaveV2 `world.repel` compatible y sin modificar `modules/save/**`. No acreditar L3 antes de pruebas reales.

**PENDIENTE IA6:** gate global de regresiones W01/W02 en árbol combinado, revisión visual GPU, integración segura productor de encuentros, sistema de sexo/día/luna y política de niveles de intercambio, EXP Share con participación real. Informes V2 y anteriores debajo son históricos y no sustituyen esta puerta.

---

# IA6 — ESTADO VIGENTE TRAS INTEGRACIÓN CONJUNTA · 2026-11-09

**Referencia PRIORITARIA para continuidad:** [IA6_INTEGRATION_CERTIFICATION_V2_20261109.md](IA6_INTEGRATION_CERTIFICATION_V2_20261109.md). GitHub Actions [#42700066031](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42700066031) `completed/success`, SHA exacto `251617a8bdff0b095f3f70273f3dc29fafcf74d0` en **rama aislada** `codex/calvo-ia6-integration-20261109`.

**Integraciones certificadas en árbol conjunto:** W01 Restore/Transform nativo (3 casos/10 transacciones), W02 mentas antiguas y nuevas `lonely/mild/naive`, W03 Cuerda Huida desde bolsa a mundo con SaveV2 manual y W05 panel de libros desde `FieldItemBag` real (20 checks L3). Regresiones V18 8755 y ITEM_CONNECTIONS 4993 PASS. W05 pilot autónomo 88 checks PASS; W02 piloto independiente 180 Godot PASS.

**Pendientes NO certificados:** repasos completos W01/CAMP005 y W02/CAMP006 sobre **este mismo árbol**; UI GPU/visual y arte final; W03 repelentes L3 y productor real de encuentros; W04 condiciones sexo/día/luna, intercambios→nivel y formas; `exp_share` L1 por falta de participación autenticada. No atribuir a todas las MT la cobertura UI del piloto de libros. Ningún merge a `main`, V28 o PR118.

**Fuentes de decisión:** [reactivación W02–W05](IA6_REACTIVATION_W02_W05_W03_W04_20261109.md), [contrato EXP Share](IA6_EXP_SHARE_PARTICIPATION_CONTRACT_20261109.md), [certificación anterior V1](IA6_INTEGRATION_CERTIFICATION_20261109.md). La documentación histórica debajo conserva estados del pasado y no revoca el PASS mixto de V2.

---

# IA6 — CIERRE CONFIRMADO W02 CAMPAÑA_006 (9 NOVIEMBRE 2026)

- **W02 detenida / 10 de 10 certificados:** [GitHub Actions #42437567862](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42437567862) `completed/success` sobre `a571d33266bc445207ed9e8d03cd34e33ac8b071`. Documento final `reports/W02/CAMP_006_ITER_10.md` actualizado en rama exclusiva W02 mediante commit **documental** `7842438faddc004815985fc850feb95e81578643` (`[skip ci]`). Sin nueva CI, sin CAMPAÑA_007, sin merge a main.
- **No sobrecontar funcionalidad:** `lucky_egg` y `soothe_bell` con efectos positivos probados; `exp_share` únicamente equipamiento + SaveV2, reparto XP a no participantes **L1 DEPENDENCIA IA6**. Mentas sin positivo propio siguen dependientes, salvo las validadas específicamente (por ejemplo `gentle_mint`).
- **Próxima intervención IA6:** diseñar contrato de `ProgressionSystem.reconcile_battle_result` para EXP Share (fuente de participantes, elegibles no participantes, política de reparto/identidad/XP), integrar de forma selectiva y probar regresiones, no asignar otra cola W02 sin cerrar decisiones compartidas. W02 STOP.

---

# IA6 — REANUDACIÓN 9 NOVIEMBRE 2026 / DECISIONES TRAS PAUSA

**Comprobación de GitHub en fecha 2026-11-09**, sin reejecutar suites: ramas W01–W05 e historial reciente Actions. `main`, V28 y PR118 no alterados por esta reanudación.

| IA | Campaña y estado real | Último run decisivo | Orden IA6 |
| --- | --- | --- | --- |
| W01 | CAMP005: 5/10 PASS; 06 reportado con 3 FAIL consecutivos, TypeError `undefined.id` al restaurar/escoger tras Transform | [#42252938911](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42252938911) FAIL | [permiso de reproducción y reparación controlada](CAMPAIGN_005_W01_BLOCK06_NATIVE_TRANSFORM_REPAIR_AUTH_20261109.md), NO 07 antes de PASS |
| W02 | CAMP006: 10/10 filas publicadas, `exp_share` L1, `lucky_egg` y `soothe_bell` positivos | [#42437567862](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42437567862) SUCCESS sobre último HEAD `a571d332` | Registrar `CAMPAÑA_006_FINALIZADA` y STOP, SIN 11, conservar ticket `exp_share` |
| W03 | CAMP006: 3/10 CI PASS, Cuerda Huida L3 y repelentes L2 sin L3; 04 bloqueado por reglas de flautas/señuelos y productor encuentros | [#41965873289](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41965873289) SUCCESS en último funcional | [aplazar 04, autorizar 05 captura](CAMPAIGN_006_W03_BLOCK04_DEFER_CAPTURE_GATE_20261109.md); 04 NO cuenta |
| W04 | CAMP006: 3/10; 04 bloqueado por `level_values_selected:null` y `future_evolution_implementation:DEFERRED` V27 | [#41785614844](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41785614844) SUCCESS tras fila 03 | [aplazar 04, autorizar 05 condicionada](CAMPAIGN_006_W04_BLOCK04_DEFER_CONDITIONS_GATE_20261109.md); no inventar niveles ni contar 04 |
| W05 | CAMP006: 10/10, 49/49 MT activas certificadas en rama, seis regresiones aprobadas, sin integración main/visual | [#42417890877](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42417890877) SUCCESS | STOP, sin `p`, próxima tarea corresponde a IA6 integración |

**Nota de CI:** los CSV de progreso de W02 y W05 conservan `CI_PENDIENTE` por el push que los lanzó, pero Actions y reportes finales confirman SUCCESS; no disparar otra ejecución solo por cambiar el estado. La rama árbitra conserva la cola original de diez bloques para trazabilidad, y estas excepciones permiten ejecutar el **ID 05** de W03/W04 mientras el **ID 04** queda aplazado, *sin rellenar el hueco con falso PASS ni cambiar el denominador*. Cualquier validador que exija secuencia contigua debe evolucionar a lista real de bloques ejecutados + ledger de aplazados.

**Prioridad técnica IA6 posterior:** (1) bug compartido Showdown/Transformación; (2) productor de encuentros que desbloquee repelentes, flautas y señuelos; (3) política concreta de niveles + objeto equipado para trade evolutions; (4) `exp_share` real para no participantes; (5) integración selectiva y pruebas visuales de MT/Libros. No mezclar sin revisión código de ramas paralelas, especialmente `CreatureInstance`, `FieldItemBag` y `native_engine.cjs`.

---

# IA6 — AUTORIZACIONES PARA DESBLOQUEO W03 Y MENTAS W02 (2026-11-04)

**W03 / WORLD_RETURN, CAMPAÑA_006 bloque02:** ticket verificado en rama `codex/calvo-items-20261104-w03-camp006`, `reports/W03/CAMP_006_BLOCK_02_IA6_INTERFACE_BLOCKER.md`. Piloto de Cuerda Huida retorno/posición funciona; UI no ejecuta ni gasta cuerda. **IA6 autoriza explícitamente** `FieldItemBag._refresh_choices/_apply` limitado a `escape_rope` + NUEVO helper `modules/overworld/field_world_item_transaction.gd` y piloto W03 en **su rama exclusivamente**, bajo [contrato oficial](CAMPAIGN_006_W03_BLOCK02_SHARED_SEAM_AUTHORIZATION.md). Guardado *manual* después del uso; sin autosave ni promesa falsa de transacción disco+estado vivo. Si no se puede revertir fallo de travesía/consumo con APIs actuales, prueba roja y revisión IA6. Se preserva `fluffy_tail` positivo en batalla, sin uso en mundo. Requiere tests Godot L3 de mochila+retorno+consumo+SaveV2, negativos y regresiones, CI acumulativa bloque02. Modificado solo gate IA6; no producción. **W03 autorizada para trabajar en 02, no declarada PASS.**

**W02 / MINT_EFFECTIVE_NATURE_STATE_SAVEV2_006_W02:** run [#41784043391](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41784043391), SHA `5d3e8f44a233477fa8a40fe83059c78b2907ede5`, **completed/success**. Logs `CAMP006_W02_DEPENDENCY BLOCKED block=02` y `block=03`; el runner certificó recuperación `PASS blocks=1` y regresiones CAMP005/004/003, **no efectos positivos de seis mentas**. IA6 aprueba arquitectura [naturaleza original + naturaleza efectiva separadas](CAMPAIGN_006_W02_EFFECTIVE_NATURE_ARCHITECTURE_GATE.md). **W02 autorizada para intentar piloto en bloque04** con nuevo helper de menta y cambios acotados en `CreatureInstance`/ruteo de `FieldItemService` de su rama. Sin permisos para `StatCalculator`, SaveV2 central, sesión/batalla ni arquitectura de otras IA; elevar un contrato preciso cuando surja. No generar tercera tanda de negativos redundantes. Los 288 escenarios anteriores permanecen protegidos. **Bloque03 sigue DEPENDENCIA; bloque04 no es PASS hasta L2+CI.**

**Protección:** no modificar `main`, V28, PR118, ramas ajenas ni código de producción desde IA6. Dos nuevos documentos y puertas oficiales actualizadas; al completar los pilotos hay que auditar diffs compartidos antes de integrar, sin hacer merge automático.

---

# IA6 — desbloqueo de CI CAMP005 W01 / CAMP006 W04 y recuperación W02 (2026-11-04)

- **W02**: cierre de recuperación validado en run [#41763921080](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41763921080), SHA `2abcc2ae9644b8821d9dae6f26214b1a8fa347fc`, `completed/success`. Pasaron CAMP005 Python/Godot 10/10, CAMP006 bloque01 Godot y regresiones CAMP004/CAMP003 Python/Godot. Diagnóstico: expectativa errónea del Caramelo XL al inicio del nivel99, no defecto positivo de `relaxed_mint`. **Puerta de bloque02 desbloqueada**, pero mentas siguen sin ejecutor de naturaleza efectiva: no inventar funcionalidad.
- **W01**: trabajador publicó bloque01 en commit `201eca50768d6a090c8542bc6f4aabdf0aa50d70`, CI no existía. IA6 creó `.github/workflows/parallel-camp005-w01-autoci.yml` en su rama `codex/calvo-items-20261104-w01-camp005`, commit `bd33aeb3f993804c3c85217b81892356af39aac5`. Run [#41767517526](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41767517526) activado; exige Python+Godot CAMP005 y regresión completa CAMP004 bloque01. **No declarar bloque01 PASS hasta `completed/success` y recibos reales.**
- **W04**: trabajador publicó prueba de integración L3 de manzanas en commit `9cf485c814be53e9318b54228a36f2b6feb5b480`, CI no existía. IA6 creó `.github/workflows/parallel-camp006-w04-autoci.yml` en su rama `codex/calvo-items-20261104-w04-camp006`, commit `73db15112ac09b641e25a050bb59f344030edf28`. Run [#41767573680](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41767573680) activado; prueba escena real, uso de mochila, SaveV2 y regresión CAMP005. **No declarar integración L3 hasta `completed/success`.** La cola CAMP006 W04 está autorizada en árbitra, pero su copia de rama W04 no está sincronizada; no forzar escritura en áreas previamente denegadas.
- **Protección:** workflows solo en ramas W01/W04 asignadas; no cambios en `main`, V28 ni PR118 ni funciones de producción. W03/W05 mantienen CI propias y no requieren intervención. Al recibir resultado fallido, identificar log y corregir configuración de CI sin relajar pruebas de juego.

---

# IA6 — AUDITORÍA DE INTEGRACIÓN/DEPENDENCIAS PUBLICADA (2026-11-03, ~22:30 CET)

**Prioridad actual:** evitar confundir objetos auditados con implementados. Auditoría verificada en [INTEGRATION_DEPENDENCY_AUDIT_2026-11-03.md](INTEGRATION_DEPENDENCY_AUDIT_2026-11-03.md) y matriz [INTEGRATION_DEPENDENCY_GROUPS_2026-11-03.csv](INTEGRATION_DEPENDENCY_GROUPS_2026-11-03.csv). **22 subgrupos / 95 IDs distintos ilustrativos** (incluye positivos parciales, dependientes y revisiones; no son 95 bloqueados ni censo completo): 7 P0, 14 P1, 1 P2. Comparaciones GitHub de rama árbitra contra W01–W05 no mostraron modificaciones nuevas de `modules/` ni `scenes/`; el trabajo reciente se concentra en tests, informes y CI. Eso no desmiente efectos existentes en `main`, por ejemplo `FieldItemService.teach/use_item`, crecimiento, habilidades y mochila de demo.

**Ejemplos clave:** `escape_rope` sin conexión al destino/guardado, aunque el prototipo `OverworldTraversalController` ya existe; W03 campo/encuentros espera un productor común de pasos/zonas/tiempo; captura contextual espera origen y Pokédex persistente; W04 intercambio→nivel exige niveles todavía `null` en política V27 y held-item/consumo; formas/fusiones tienen frontera no implementada; 18 Tera son almacenables pero sin motor. W05 tiene pruebas positivas en 60+60+36=156 MT compatibles hasta CAMP005 bloque 06, sin acreditar UI o todas las especies. W04 CAMP004 1 recuperación positiva y 31 dependencias de 36.

**Recomendación para próximos `p`:** IA1/IA2/IA5 pueden seguir con funciones positivas/regresión; reconsiderar continuar W03/W04 con más auditorías negativas equivalentes sin resolver los productores/contratos compartidos. **NO se modificaron sus colas ni las reglas de autonomía:** esta auditoría es un aviso técnico y plan, no una orden de parada ni cambio de asignación. Para cualquier cambio de propiedad compartida o política se requiere aprobación. Primero decidir contratos P0; después prototipos de Cuerda Huida (sobre demo), una bola contextual y una evolución; smoke test de demo → SaveV2 → recarga; integración selectiva en rama sin tocar `main`/V28/PR118.

---

# IA6 — CAMPAÑA_005 PREPARADA PARA CUATRO TRABAJADORAS · BOOTSTRAP PASS (2026-11-03)

**Solicitud vigente:** el usuario confirma que CAMP004 ha terminado para IA2/IA3/IA4/IA5 y solo IA1 continúa. IA6 comprobó sus cuatro CI final `completed/success`: W02 [#41589286005](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41589286005) Python 648/Godot 12.282; W03 [#41579566584](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41579566584) Python 187/Godot 1.344; W04 [#41611102944](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41611102944) Python 387/Godot 1.090; W05 [#41591821717](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41591821717) Python 580/Godot 2.166. No confundir CI verde con plena funcionalidad de objetos dependientes o integración a `main`.

| IA | Nueva rama | CAMP005 | Bootstrap 0/10 |
| --- | --- | --- | --- |
| W02 | `codex/calvo-items-20261103-w02-camp005` | 10 × 4 = **40 TRAINING nuevos** | [#41711262719](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41711262719) PASS SHA `a89a158ff0836e879eeada7958e32f01a03f2507` |
| W03 | `codex/calvo-items-20261103-w03-camp005` | **28 IDs antiguos** captura/campo, 10 tareas de integración/reparación | [#41711308425](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41711308425) PASS SHA `22625c9e2a83af2c71e383291f3d8c18f4376cd8` |
| W04 | `codex/calvo-items-20261103-w04-camp005` | **46 IDs antiguos** evolución/formas, 10 tareas de dependencias | [#41711566627](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41711566627) PASS SHA `c8136c56ec41c8f0d06ac7af98a0d890d422f8c8` |
| W05 | `codex/calvo-items-20261103-w05-camp005` | 10 × 6 = **60 MT nuevas tm142–tm201** | [#41711755340](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41711755340) PASS SHA `c1db16b52a43671c895f667de9d74595b0c988b4` |

**Total CAMP005 nuevo:** 100 IDs. **Trabajo adicional de remediación:** 74 IDs ya auditados, **no sumar al censo de nuevos objetos**. Los cuatro CI bootstrap comprobaron identidad, secuencia y reservas 0/10; **los pasos funcionales Python/Godot fueron SKIPPED por diseño**. Los fallos iniciales de creación de YAML, la clasificación de W04 y la distinción de metadatos vs enseñanza W05 fueron corregidos; no son regresiones de juego.

Los documentos por IA son `CAMPAIGN_005_W0X_GATE.md`, `CAMPAIGN_005_W0X_QUEUE_APPROVED.csv`, `campaigns/CAMP_005_W0X.md`, `CAMPAIGN_005_W0X_ACTIVATION_MESSAGE.md` y `CAMPAIGN_005_W0X_BRANCH_MANIFEST.md`, con X=2,3,4,5. Se copiaron gate/cola/encargo a cada rama propia, junto con fixture y progreso 0/10. **Enviar mensaje de activación correspondiente a cada chat y comenzar bloque 01**; cada `p` posterior ejecuta uno hasta 10, con autonomía de reparación V5 por función. NO esperar a W01.

**W01 sigue en CAMP004, 7/10 publicados**, último progreso fila 07 `sticky_barb;terrain_extender;throat_spray`; la CI [#41711361003](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41711361003) estaba en curso durante la comprobación, y el último éxito anterior [#41707616043](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41707616043). No asignar CAMP005 W01 hasta cierre real 10/10; no modificar su rama.

**Protección:** `main`, V28, PR118, ramas ajenas, catálogos canónicos y SaveV2 compartido no se tocaron. No hacer merge automático; IA6 debe auditar diffs, dependencias, colisiones y pruebas visuales después.

---

# IA6 — LAS CINCO CAMPAÑAS_004 PREPARADAS / W01 BOOTSTRAP PASS (2026-11-03)

El usuario confirma cierre de IA1 CAMP003. GitHub Actions [#41575150716](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41575150716) SUCCESS, 10 bloques / 30 equipables, Python 806, Godot 12.392. La última fila CAMP003 sigue documentalmente `EN_CI_AUTOMATICA`, pero el run funcional posterior confirmó PASS. IA6 preparó W01 **CAMPAÑA_004** de 10 bloques / 30 equipables; [gate](CAMPAIGN_004_W01_GATE.md), [cola](CAMPAIGN_004_W01_QUEUE_APPROVED.csv), [encargo](campaigns/CAMP_004_W01.md), [mensaje](CAMPAIGN_004_W01_ACTIVATION_MESSAGE.md), [manifiesto](CAMPAIGN_004_W01_BRANCH_MANIFEST.md). Rama exclusiva `codex/calvo-items-20261103-w01-camp004`, fuente HEAD W01 CAMP003 `e20a51286f573cb6c81469f2287fcab2fcb5f90f`. **CI bootstrap W01 [#41578986117](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41578986117) `completed/success`**, SHA `d290099ce8f93c048339b694797337abbc48336c`, `reserved=10 completed=0 ids=30` (solo configuración, NO mecánica). Borrador de cola W01 inicialmente coincidía con 3 equipables de CAMP002; IA6 los reemplazó antes del arranque por `light_ball;lucky_punch;thick_club`. Ahora hay **cinco CAMP004 independientes** autorizadas y preparadas: W01 30, W02 40, W03 36, W04 36, W05 60 = **202 IDs reservados**, no 202 implementaciones. Sin cambios a `main`, V28, PR118 u otras ramas. `p` solo una fila por turno de cada chat, al 10/10 STOP.

---

# IA6 — CAMPAÑA_004 W04 ACTIVADA · CI BOOTSTRAP PASS (2026-11-03)

**Actualización vigente:** usuario confirma fin de IA4/W04 CAMP003 10/10. CI [#41574086468](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41574086468) SUCCESS sobre SHA `42e98b468d934765c04cd3f45fa4a3b3cd7767a5`, 120 Python, 270 Godot y 559 regresión CAMP001. **14 de los 30 objetos con evolución positiva; 16 siguen con dependencia**, no confundir CI verde con todos funcionales. IA6 activó **CAMPAÑA_004 exclusiva W04**, diez bloques y 36 IDs diferentes, según [cola](CAMPAIGN_004_W04_QUEUE_APPROVED.csv), [gate](CAMPAIGN_004_W04_GATE.md), [encargo](campaigns/CAMP_004_W04.md), [manifiesto](CAMPAIGN_004_W04_BRANCH_MANIFEST.md), [mensaje](CAMPAIGN_004_W04_ACTIVATION_MESSAGE.md). Rama nueva `codex/calvo-items-20261103-w04-camp004` creada desde HEAD anterior `f359775396935cc6e8c382ce96377a29fdd33a35`; reserva sin solapes con CAMP001/CAMP003 ni CAMP004 otras W. **CI bootstrap [#41574901308](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41574901308) `completed/success`** en `748e320b4042185f259eca5a7dc43e4bfa5f119e`, `reserved=10 completed=0 ids=36`; NO función nueva verificada. Primer run #41574785492 falló por falta de snapshots read-only de colas W02/W03/W05, ya corregido. La activación del usuario a W04 ejecutará bloque 01, después `p` por bloque hasta 10/10. Cambios W04 en evolución solo bajo V5, sin tocar subsistemas ajenos, `main`, V28, PR118. W02/W03/W05 CAMP004 independientes y W01 CAMP003 conservadas, sin merges.

---

# IA6 — CAMPAÑA_004 W02 ACTIVADA Y CI BOOTSTRAP PASS (2026-11-03)

El usuario confirma que W02 ha terminado CAMP003 10/10. Última CI antigua [#41570972406](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41570972406) SUCCESS en SHA `291146f2efe617dbb7528050068e09e80a64022c`, 7.306 checks Godot. IA6 reservó nueva [cola CAMP004 W02](CAMPAIGN_004_W02_QUEUE_APPROVED.csv) de **10 bloques / 40 objetos**: 8 BERRY no asignadas/ya cubiertas y 32 MEDICINE. [Gate](CAMPAIGN_004_W02_GATE.md), [encargo](campaigns/CAMP_004_W02.md), [manifiesto](CAMPAIGN_004_W02_BRANCH_MANIFEST.md) y [mensaje](CAMPAIGN_004_W02_ACTIVATION_MESSAGE.md) publicados. Rama `codex/calvo-items-20261103-w02-camp004` creada desde cierre W02 CAMP003; fixtures/progreso/manifest CI de CAMP004 preparados. [CI bootstrap #41572529404](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41572529404) `completed/success`, SHA `0a546247ccd4c9efa0cb93dd6ea5ce9e41d743a3` **configuración 0/10, no efecto funcional**. La primera orden ejecuta bloque 01; `p` avanza de 02 a 10. W03/W05 siguen en sus CAMP004 independientes, W01/W04 conservan las CAMP003. Respetar AUTONOMOUS_REPAIR_V5, evitar API compartida sin coordinación, no modificar `main`, V28, PR118 u otras ramas. Sin merge a producción.

---

# IA6 — CAMPAÑA_004 W03 AUTORIZADA, BOOTSTRAP PASS (2026-11-03)

**Actualización vigente:** usuario confirma IA3/W03 CAMP003 10/10 y solicita continuidad sin esperas, según mismo criterio que W05. GitHub W03 CAMP003 [CI #41570102206](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41570102206) SUCCESS para bloques 1..10; no implica bolas dependientes implementadas. Nueva rama W03 `codex/calvo-items-20261103-w03-camp004` fundada desde `6d47ff595537bf1c6eb936b9c7cbec377db7f707`. [Nueva cola](CAMPAIGN_004_W03_QUEUE_APPROVED.csv) de **10 bloques y 36 IDs**: 3 bolas restantes, 15 objetos de campo y 18 fragmentos Tera. [Gate](CAMPAIGN_004_W03_GATE.md), [encargo](campaigns/CAMP_004_W03.md), [mensaje](CAMPAIGN_004_W03_ACTIVATION_MESSAGE.md) y [manifiesto](CAMPAIGN_004_W03_BRANCH_MANIFEST.md) publicados. [Bootstrap Actions #41571597653](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41571597653) `completed/success`, SHA `ff328e2fb74137dee44d5a548d85b73525fd8f21`, **solo configuración 0/10, NO efecto funcional**. Primera orden ejecuta bloque 01; cada `p` siguiente ejecuta uno hasta 10/10. Autonomía V5 para captura propia, no arbitrar unilateralmente APIs compartidas campo/Tera. CAMPAÑA_004 W05 sigue independiente y protegida; otras tres IAs mantienen CAMP003. Sin cambios a `main`, V28 ni PR118.

---

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

