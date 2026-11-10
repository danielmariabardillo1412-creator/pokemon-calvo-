# IA6 — ORDEN PERMANENTE ACTIVA W01 · TANDA 02

**IA6 HA REVISADO TU ENTREGA ANTERIOR Y PUBLICA AQUÍ LA NUEVA COLA COMPLETA.** Este archivo es tu punto fijo de entrada. Cuando recibas `p`, `sigue` o `continúa`: consulta la rama de GitHub, tu HEAD, esta nota y tu checkpoint; empieza en la primera fila pendiente de la **TANDA 02**, sin pedir permiso IA6 por cada fila. Tras completar 10, deja informe + CI real y STOP a esperar una TANDA nueva. No te limites a contestar «entendido».

**Rama autorizada:** `codex/calvo-items-20261110-w01-gems-autobatch01`. **Protocolo maestro:** `docs/coordination/items_parallel_v1/AUTONOMY_V1/README.md` de `codex/calvo-items-20261101-arbitro`. **Orden central:** `docs/coordination/items_parallel_v1/AUTONOMY_V1/QUEUE_W01_TANDA_02.md` de árbitra. Esta copia tiene el mismo contenido y vale aunque cambie el contexto de la conversación.

No ejecutar en segundo plano ficticio: si un turno se agota, publicar checkpoint en GitHub y la siguiente `p` continúa. Un bloqueo de un productor compartido no te obliga a detener los otros hitos independientes: ticket, `BLOQUEADO`, próximo. Nunca presentar CI de otro SHA como actual ni fusionar `main`, V28, PR118 u otras ramas. Protecciones de archivos/funciones indicadas abajo son estrictas.

---

# IA6 W01 — TANDA 02: gemas restantes
Rama: codex/calvo-items-20261110-w01-gems-autobatch01.
Evidencia TANDA01: CI 42730773059 SUCCESS, SHA 9d1a9dae8b9d9abed09a12b082f7a719aa047981, native 10 filas y 20 activaciones, Godot 4002 checks; CAMP005/004 regresiones PASS. El CSV AUTORUN_V1_PROGRESS.csv todavía dice EN_CI_AUTOMATICA; antes de nuevos cambios cerrar la documentación con recibos y AUTORUN_V1_FINAL.md SIN volver a adjudicar tests antiguos a una SHA nueva.
PROTOCOLO COMÚN: Esta nota autoriza los 10 hitos sin pedir permiso por hito. Al recibir p/sigue, comenzar en primer hito pendiente, publicar checkpoint si termina el turno, retomar con siguiente p. Conservar pruebas, CI con SHA y contabilidad L1/L2/L3. Bloqueos reales se documentan y permiten pasar a hitos independientes. No main, V28, PR118 ni ramas ajenas. Al terminar emitir cierre de tanda y detenerse; no ejecutar en background.
Diez hitos:
01 ghost_gem: efecto real Fantasma.
02 dragon_gem: efecto real Dragón.
03 dark_gem: efecto real Siniestro.
04 steel_gem: efecto real Acero.
05 fairy_gem: solo con perfil canónico validado (no inventar Fairy Gem).
06 matriz de gemas de 18 tipos: no duplicar NORMAL/FIRE/WATER ni diez gemas TANDA01.
07 consumo único, fallo, inmunidad, tipo incompatible.
08 Guardado SaveV2, restauración, reserva, Transformación y PP.
09 regresión de backend nativo, active/reserve, cambios de slot, orden de efectos.
10 CI conjunta CAMP004/CAMP005/TANDA01/TANDA02 e informe AUTORUN_V2_FINAL.md.
Reglas: estos cinco IDs aparecen en item_connections_v1.json como holdable, pero NO se presume que tengan efecto de motor ni estén seleccionados. Verificar DefinitionCatalog, política y referencia real. Exigir daño del tipo correcto/incorrecto, consumo, SaveV2 y negativos. Solo ediciones de consumo held específico, tests y workflow W01; si exige backend global protegido, ticket y no mutación. Diez filas revisadas no equivalen a cinco gemas funcionales.
