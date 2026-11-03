# W04 — CAMP003 ITER_02 — Solar / Oval / Mineral Negro

**Estado: DEPENDENCIA_DOCUMENTADA, pendiente de validación CI y decisión de IA6.**

- IDs oficiales: `sun_stone`, `oval_stone`, `black_augurite`.
- Se amplían exclusivamente los tests y el fixture autorizados, manteniendo pruebas acumulativas del bloque 01.
- El runner inspecciona registros reales y `EvolutionSystem.classify_record`. Una ruta solo se ejecuta cuando está respaldada por `TRIGGER_USE_ITEM` con soporte `RUNTIME_SUPPORTED`; las reglas sin compatibilidad se informan como dependencia, sin darles tratamiento de piedra común.
- **Punto crítico:** Oval Stone requiere un mecanismo condicionado (objeto equipado y evolución por nivel, según modalidad). No se puede prometer que `FieldItemService.evolve` lo ejecute como `use_item`. La clasificación exacta del catálogo activo requiere CI.
- Solar y Mineral Negro: descubrir pares reales a través del catálogo activo; verificar éxito y rechazo con consumo exacto, identidad, atributos y SaveV2 *solo* si la regla es ejecutable.
- Validación Python/Godot: **SIN EJECUTAR** en esta conversación, ninguna cifra PASS atribuible a este bloque. Estado del último workflow de la rama no verificado por API; no se declara aprobado.
- Commits de tests: `10b23f293dcb9c5a481e3877d0f35613781db34b` (fixture), `fcd4947d028473ad7959da2d785c02f69f69a6ac` (Godot), `fee9897f34148c9dda7b243c6a0bf67169430c00` (Python).
- No se ha cambiado producción, reglas, políticas, `main`, V28, ni ninguna rama ajena.

**PARADA:** Se solicita revisión de IA6 sobre la regla condicionada de Oval Stone y los logs de CI antes de habilitar ITER_03. No clasificar ausencia de ruta de uso directo como PASS de evolución.
