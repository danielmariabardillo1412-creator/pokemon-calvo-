# IA6 — ORDEN PERMANENTE ACTIVA W02 · TANDA 02

**IA6 HA REVISADO TU ENTREGA ANTERIOR Y PUBLICA AQUÍ LA NUEVA COLA COMPLETA.** Este archivo es tu punto fijo de entrada. Cuando recibas `p`, `sigue` o `continúa`: consulta la rama de GitHub, tu HEAD, esta nota y tu checkpoint; empieza en la primera fila pendiente de la **TANDA 02**, sin pedir permiso IA6 por cada fila. Tras completar 10, deja informe + CI real y STOP a esperar una TANDA nueva. No te limites a contestar «entendido».

**Rama autorizada:** `codex/calvo-items-20261109-w02-mints-integration`. **Protocolo maestro:** `docs/coordination/items_parallel_v1/AUTONOMY_V1/README.md` de `codex/calvo-items-20261101-arbitro`. **Orden central:** `docs/coordination/items_parallel_v1/AUTONOMY_V1/QUEUE_W02_TANDA_02.md` de árbitra. Esta copia tiene el mismo contenido y vale aunque cambie el contexto de la conversación.

No ejecutar en segundo plano ficticio: si un turno se agota, publicar checkpoint en GitHub y la siguiente `p` continúa. Un bloqueo de un productor compartido no te obliga a detener los otros hitos independientes: ticket, `BLOQUEADO`, próximo. Nunca presentar CI de otro SHA como actual ni fusionar `main`, V28, PR118 u otras ramas. Protecciones de archivos/funciones indicadas abajo son estrictas.

---

# IA6 W02 — TANDA 02: crecimiento, mochi y vitaminas después de mentas
Rama: codex/calvo-items-20261109-w02-mints-integration.
TANDA01 10/10 mentas L3 y migración histórica 288 escenarios, CI 42730263746 SUCCESS, SHA f8168c2b5cdb2dc74bc2820d94cc59e7bc7be19c. No repetir mentas ni reiniciar CAMP006.
PROTOCOLO COMÚN: Esta nota autoriza los 10 hitos sin pedir permiso por hito. Al recibir p/sigue, comenzar en primer hito pendiente, publicar checkpoint si termina el turno, retomar con siguiente p. Conservar pruebas, CI con SHA y contabilidad L1/L2/L3. Bloqueos reales se documentan y permiten pasar a hitos independientes. No main, V28, PR118 ni ramas ajenas. Al terminar emitir cierre de tanda y detenerse; no ejecutar en background.
Hallazgo IA6: FieldGrowthEffects.validation_error y FieldMochiEffects.validation_error recalculan stats con nature_id original, aunque el Pokémon real tras una menta usa effective_nature_id. Esto provoca rechazos potenciales. FieldTrainingEffects.apply también recalcula: comprobar que conserva estadística con naturaleza efectiva.
Diez hitos:
01 Test rojo menta->rare_candy y rechazo sin gasto.
02 Corrige SOLO Growth.validation_error: validar naturaleza original y efectiva, cálculo con efectiva si existe.
03 Prueba exp_candy_xs y xl tras menta, nivel100, HP y experiencia.
04 Crecimiento con aprender/sustituir movimiento o evolución, preservando PP/estado.
05 Test rojo menta->muscle_mochi y swift_mochi.
06 Corrige SOLO Mochi.validation_error con naturaleza efectiva.
07 Fresh Start Mochi reset de EV tras menta y SaveV2.
08 Protein y Carbos tras menta, prueba recálculo y amistad.
09 Secuencia real menta->crecimiento->mochi->vitamina->menta en PARTY/STORAGE, rollback, SaveV2.
10 CI con CAMP003–006, pilotos MINT-L3, TANDA01, informe AUTORUN_V2_FINAL.md.
Permisos excepcionales W02 limitados a módulos field_growth_effects.gd (validation_error/plan), field_mochi_effects.gd (validation_error/apply) y field_training_effects.gd::apply SOLO con prueba de fallo; runner/CI propios. Prohibido CreatureInstance, StatCalculator, ProgressionSystem, SaveV2 central, FieldNativeSave, FieldItemService, exp_share, motor o mochila. Un fallo en otro módulo protegido se documenta; no declarar guardado nativo de mundo antes de integración IA6.
