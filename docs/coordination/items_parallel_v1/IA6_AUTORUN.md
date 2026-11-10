# IA6 — ORDEN PERMANENTE ACTIVA W03 · TANDA 03

**IA6 HA REVISADO TU ENTREGA ANTERIOR Y PUBLICA AQUÍ LA NUEVA COLA COMPLETA.** Este archivo es tu punto fijo de entrada. Cuando recibas `p`, `sigue` o `continúa`: consulta la rama de GitHub, tu HEAD, esta nota y tu checkpoint; empieza en la primera fila pendiente de la **TANDA 03**, sin pedir permiso IA6 por cada fila. Tras completar 10, deja informe + CI real y STOP a esperar una TANDA nueva. No te limites a contestar «entendido».

**Rama autorizada:** `codex/calvo-items-20261104-w03-camp006`. **Protocolo maestro:** `docs/coordination/items_parallel_v1/AUTONOMY_V1/README.md` de `codex/calvo-items-20261101-arbitro`. **Orden central:** `docs/coordination/items_parallel_v1/AUTONOMY_V1/QUEUE_W03_TANDA_03.md` de árbitra. Esta copia tiene el mismo contenido y vale aunque cambie el contexto de la conversación.

No ejecutar en segundo plano ficticio: si un turno se agota, publicar checkpoint en GitHub y la siguiente `p` continúa. Un bloqueo de un productor compartido no te obliga a detener los otros hitos independientes: ticket, `BLOQUEADO`, próximo. Nunca presentar CI de otro SHA como actual ni fusionar `main`, V28, PR118 u otras ramas. Protecciones de archivos/funciones indicadas abajo son estrictas.

---

# IA6 W03 — TANDA 03: Repeat Ball en captura nativa Showdown
Rama: codex/calvo-items-20261104-w03-camp006.
TANDA02 CI 42736177949 SUCCESS, SHA 4d6ee28064706e336ec8cf8ac89862356e886017. Se certificó ledger de capturas y Repeat Ball ×3.5 en WildAdventureSession, pero native_capture_l3=false (NO L3 de combate nativo). Ticket AUTORUN_V2_NATIVE_REPEAT_SEAM_BLOCKER.md revisado.
PROTOCOLO COMÚN: Esta nota autoriza los 10 hitos sin pedir permiso por hito. Al recibir p/sigue, comenzar en primer hito pendiente, publicar checkpoint si termina el turno, retomar con siguiente p. Conservar pruebas, CI con SHA y contabilidad L1/L2/L3. Bloqueos reales se documentan y permiten pasar a hitos independientes. No main, V28, PR118 ni ramas ajenas. Al terminar emitir cierre de tanda y detenerse; no ejecutar en background.
IA6 AUTORIZA excepcionalmente editar exclusivamente modules/gameplay/showdown_adventure_session.gd::capture y, si es absolutamente necesario, SOLO el commit de captura en ::_finish para integrar historial real de especies. No alterar medicina, escape, motor de batalla, trainer, generadores RNG ni reglas de otras bolas.
Diez hitos:
01 Preflight de capture->CaptureInventoryService.resolve->_finish->PlayerCollection.
02 Prueba roja de native Repeat (primera captura, otras especies, stock).
03 Contexto previously_caught_base_species desde player ANTES de resolver y gastar RNG.
04 Registrar ledger solo si _finish aceptado y CaptureResult.SUCCESS, con rollback.
05 Primera captura nativa real -> ledger -> SaveV2 manual.
06 Guardar/cargar -> segunda captura nativa misma especie con bonus ×3.5 y distinta x1.
07 Negativos de captura fallida, party y storage llenos, inventario corrupto, sin bola.
08 Recuperación de sesión/Transformación, no doble bonus ni consumo.
09 Convivencia con repelentes L3, Cuerda Huida, captura y SaveV2.
10 CI nueva con caso nativo positivo y regresiones CAMP005/CAMP006/native, informe AUTORUN_V3_FINAL.md.
FieldNativeSave y el ledger W03 TANDA02 solo lectura en esta tanda salvo test propio. Prohibido tocar módulos/save, FieldItemBag, CreatureInstance, W04, backend Showdown genérico. Si funciones autorizadas no bastan, prueba roja/ticket, seguir QA seguro. No etiquetar L3 hasta prueba real de captura nativa SUCCESS.
