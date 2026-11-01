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

