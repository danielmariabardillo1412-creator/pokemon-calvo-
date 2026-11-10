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