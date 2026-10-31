# ITEMS_V28 — punto único de reanudación (31-10-2026)

**Estado operativo:** V27 organizada es oficial en `main` (merge `233b1a4f15ee4df7301e2c5acf8aed84a8f40626`, PR #116). No sobrescribirla ni su historial. La antigua V3 (#117) está cerrada SIN MERGE y su rama preservada. Nueva misión de objetos autorizada: `codex/items-v28-from-main`, nacida del SHA oficial.

**Primero:** leer este archivo y `STATE.json` (breves). Leer la cola de `PROGRESS.md` para el siguiente paso; `RESULTADOS.json` solo para evidencias. Consultar `WORK_ORDER.md` antes de editar. No barrer `docs/current`, logs, 2.222 objetos ni los módulos del juego indiscriminadamente. En GitHub filtrar estados/jobs/steps, y logs solo en caso de fallo. Consultar archivos por símbolo/rangos. Comparar SHAs antes de repetir pruebas; guardar todo cambio/fallo con SHA y ejecución.

**Bloque inicial:** trasladar *sin reinterpretar* al nuevo desarrollo los siete archivos de código, herramientas y CI de V3 ya probados en `c554ab7635fb847aa395d2dbb5bc523b560bc6de`. El conjunto no está incluido en V27: recompensa EV tras KO, 6 Power, Macho Brace, inventario auditable y batería de objetos equipados/bayas, más preparación del gate Windows. El antiguo CI obtuvo 20/20 PASS, pero **V28 necesita sus propias ejecuciones tras el trasplante**. NO fusionar V3 ni su PR, no cambiar políticas, economía, EXP Share, guardados, EvolutionSystem, RNG, arte o simulador.

**Después del primer CI:** escoger una siguiente familia *con sistema disponible*, especificar efecto/contexto verificable, modificar únicamente lo que soporte el motor y documentar dependencias. Los 2.222 IDs de catálogo NO son 2.222 funciones verificadas. La revisión visual/GPU y pruebas de usuario local siguen pendientes.

**Control de contexto:** un commit funcional identificado + resultados CI + limitaciones y próximo paso son el checkpoint. No es un sistema de memoria nuevo, es documentación en Git. Link PR se añade al abrirla.
