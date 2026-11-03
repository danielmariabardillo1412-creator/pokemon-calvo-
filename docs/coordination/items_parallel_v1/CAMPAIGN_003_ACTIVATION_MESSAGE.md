# Mensaje universal para copiar en cuatro chats — CAMPAÑA_003 (V4)

Continúa con tu **identidad previa W01, W02, W03 o W05** del proyecto Pokémon Calvo. La árbitra **IA6 ha activado CAMPAÑA_003 con 10 microbloques por trabajadora**. La CAMPAÑA_002 ya ha finalizado y NO debes ampliarla con un cuarto bloque.

Repositorio: `danielmariabardillo1412-creator/pokemon-calvo-`.

Lee primero, en `codex/calvo-items-20261101-arbitro`:
- `docs/coordination/items_parallel_v1/CAMPAIGN_GATE_003.md`
- `docs/coordination/items_parallel_v1/CAMPAIGN_003_BRANCH_MANIFEST.md`
- `docs/coordination/items_parallel_v1/CAMPAIGN_003_QUEUE_APPROVED.csv`
- `docs/coordination/items_parallel_v1/campaigns/CAMP_003_W0X.md` (sustituye W0X por tu identidad).

**Tu única rama de escritura nueva es `codex/calvo-items-20261103-w0x-camp003`**, con base de partida `41c1efeba0346349490f863131179ed7a8fc274c`. Comprueba que existe y verifica su progreso. No escribas ni fusiones antiguas ramas 20261102 ni ramas ajenas.

**Ejecuta AHORA únicamente el BLOQUE 01**, primera fila de tu trabajadora en la cola oficial. Publica código de pruebas, fixture, una fila de `CAMP_003_PROGRESO.csv` e informe en tu rama, con commit. Conserva las aserciones y distingue efectos ya probados de pendientes; no reprogramar producción. La CI GitHub Actions automática de la misma rama se disparará tras el push de pruebas o progreso.

**A partir del siguiente mensaje `p`, ejecuta el siguiente bloque de la misma cola de forma secuencial y sin esperar permiso administrativo de IA6, hasta el BLOQUE 10.** Consulta siempre la CI reciente: SUCCESS→seguir; QUEUED/IN_PROGRESS→puedes preparar un bloque de pruebas independiente sin atribuir PASS; FAILURE→diagnosticar y reparar solo tus pruebas, STOP y aviso IA6 si es defecto funcional, contrato compartido o permisos. Nunca declarar éxito si no se ejecutó.

El validador de IA6 exige que `--ci` de tu Python imprima `CAMP003_W0X_PY PASS blocks=N checks=M` y Godot imprima `CAMP003_W0X_GODOT PASS blocks=N checks=M`, N el número de bloques entregados y M positivo. Nada de imprimir PASS ficticio: las comprobaciones deben existir y ser ejecutadas.

**Al llegar a 10/10, comunica `CAMPAÑA_003_FINALIZADA` y STOP.** No inventes bloque 11 ni CAMPAÑA_004. IA4 no participa. No tocar `main`, V28, PR #118, guardados reales, producción, catálogo, workflow/validador IA6 ni ramas de otras trabajadoras.