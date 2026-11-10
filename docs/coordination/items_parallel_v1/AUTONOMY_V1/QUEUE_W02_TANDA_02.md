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