# IA2/W02 — CAMPAÑA_003: CONTINUIDAD VIGENTE / BLOQUE 10 DE 10 — CI PENDIENTE

**Fila 10 EJECUTADA/PUBLICADA, NO CIERRE CERTIFICADO.** Rama `codex/calvo-items-20261103-w02-camp003`. No más filas: STOP al 10. Trabajo pendiente: verificar CI acumulativa y reparar cualquier fallo antes de declarar `CAMPAÑA_003_FINALIZADA`. El usuario ya autorizó avanzar al último bloque si la CI09 había terminado; el run09 [#41566220523](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41566220523) terminó `failure`, fue diagnosticado como comparación de vector Starf en la capa de evidencias y reparado en arnés (`13dc40ee663cd73379e4d21337e8f89ea667a067`). El run de reparación aislado se canceló al publicar bloque10 independiente; **la CI10 debe acreditar también 09**, no dar falso PASS.

**IDs exactos de fila 10:** `yache_berry;grepa_berry;hondew_berry;pomeg_berry`. Yache hielo equipada con positivos/negativos nativos; Grepa (EV Def. Especial), Hondew (EV At. Especial) y Pomeg (EV PS) son uso directo de bolsa `FieldItemService.use_item`, no held battle. Aprovechar ruta `modules/inventory/field_item_effects.gd` y evidencia histórica `tests/gameplay/item_field_effects_v4.gd` sin duplicar 28×6 tests. Nuevos 11 escenarios, 33 variantes, 87 casos y 261 variantes totales previstas en 40 IDs.

**Controles nuevos:** Yache activa/ausente/reserva, Ice Shard vs Tackle; EV bayas en equipo con objeto, equipo sin objeto (rechazo), almacenadas con objeto, EV−10 con límite 0, amistad 100→105/200→202, sin efecto a EV=0 amistad=255, Pomeg desde 1 PS nunca KO, copia original sin mutación, consumo exacto, SaveV2 con ubicación/EV/amistad/HP y recibos SHA256. Fuera de alcance: bonificadores de amistad de origen no resueltos, GPU, campo/clima.

**Commits:** fixture `773a3ed100637761e2f10b71a2febda01c370ab7`; runner W02 `3ccac60d4324f8f3916f556aee1a06c352b4e819`; Python `cd70cb65eeb30e962ddac5bb5f1964d8bb437aec`; CSV con 10 filas `680713149f39e742d92a9c64503e4caeb78d8aee`; informe ITER10 `f49589f14ecc5ff66eb2f60bdc7041fb353f0540`.

**CI actual:** [Actions #41570674107](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41570674107) sobre SHA `680713149f39e742d92a9c64503e4caeb78d8aee`. Exigir `completed/success`, `CAMP003_W02_PY PASS blocks=10 checks=N`, `CAMP003_W02_GODOT PASS blocks=10 checks=M` y gates de manifiesto correctos. No aceptar un run de SHA anterior o cancelado. Último éxito total acreditado hasta este punto: [#41563958549](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41563958549) blocks=8, Python 535, Godot 5795.

**Autonomía V5:** reparar in situ fallos propios, tanto test como función de bayas reservadas, sin cambiar trabajo ajeno/arquitectura. Si error de import/script/permiso, diagnosticar; si error de EV/SaveV2, distinguir infraestructura compartida frente a regla de baya, no inventar semántica. Mantener `main`, V28 y ramas ajenas intactas. IA6 editó previamente el workflow en `43876a6d833958d2d7ad86ce15014b011778007a`; autoría separada.

**Siguiente acción:** consultar y depurar CI10. Cuando PASS real, publicar `CAMP_003_FINAL.md`, actualizar cuaderno, reportar `CAMPAÑA_003_FINALIZADA`, STOP hasta nuevo encargo. No existe fila 11.

---

## HISTÓRICO — ESTADO 09/10 Y ANTERIORES

# IA2/W02 — CAMPAÑA_003: CONTINUIDAD VIGENTE / BLOQUE 09 DE 10

**Estado:** bloque **09/10 publicado** en `codex/calvo-items-20261103-w02-camp003`; último SHA tests/progreso `93bd706149928f63c2cf5cd318ce4a32fa013bc8` `EN_CI_AUTOMATICA`. **No atribuir PASS al bloque 09 hasta resultado nativo del último SHA.** La siguiente `p` autoriza exactamente bloque **10/10**, no otra campaña.

**Autoridad:** cola `CAMPAIGN_003_QUEUE_APPROVED.csv` blob `ea06a0a000fc4f3b8bab48e45e21fb549d753559`, encargo W02 blob `62498ebd44288a86e59986379dbc1b70e111ef1f`, reparación V5 `AUTONOMOUS_REPAIR_V5.md` blob `ebe71ace6949cc9311eb9831068799081bca8ba7`. V5 permite arreglar código funcional de nuestras bayas en la propia rama sin permiso administrativo repetitivo, no cambiar mecánicas globales ni las de otra trabajadora.

**Bloque 09 exacto:** `starf_berry` (al 20% PS un solo atributo aleatorio +2, no fijo; con PS altos nada), `tanga_berry` (Bicho `bug_buzz` vs Normal `tackle`), `wacan_berry` (Eléctrico `thunder_shock` supereficaz a Gyarados vs Normal), `wiki_berry` (Adamant confunde tras curar 1/3 PS con Endeavor/HP1 de Snorlax; Hardy no confunde; con PS altos no activa). **9 escenas nuevas, 27 variantes**. Históricos reales V2 para Tanga/Wacan y V3 para Starf/Wiki. Fixture de Wiki reusa configuración Endeavor que ya corrigió y validó Mago.

**Prueba nativa específica Starf:** `_native_starf_boosts()` obtiene los cinco valores `atk,def,spa,spd,spe` de `_checkpoint.roster.pokemon.boosts` del ID `own` real; se exigen un único +2 y suma +2, cuatro ceros, y cero en `none/reserve`. Se comprueba vector idéntico tras SaveV2 checkpoint y recibo SHA256; RNG fija semilla pero no se presupone estadística concreta.

**Suite acumulada:** 9 bloques consecutivos, **36 IDs**, 9+8+8+9+8+9+8+8+9 = **76 escenarios**, **228 variantes** `active/none/reserve` previstas. Incluye consumo, stock, reserva inerte, restauración, cierre FLED, no doble consumo, SaveV2 e identidad del portador, evidencias JSON + SHA256; campo/UI/GPU no certificados.

**Última CI VERIFICADA:** [Actions #41563958549](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41563958549), `completed/success`, SHA `992b31cde4984d1c6ca3e1f87a192b96247f71f4`. Recibos `CAMP003_W02_PY PASS blocks=8 checks=535`, `CAMP003_W02_GODOT PASS blocks=8 checks=5795`. Certifica 01–08, incluidas correcciones Mago/Maranga/Occa. **No certifica 09**.

**CI bloque 09:** [Actions #41566220523](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41566220523), SHA `93bd706149928f63c2cf5cd318ce4a32fa013bc8`, inicialmente pendiente. Exigir `CAMP003_W02_PY PASS blocks=9 checks=M` y `CAMP003_W02_GODOT PASS blocks=9 checks=M`; si falla, leer error real, investigar y reparar rama propia según V5. Cancelaciones por pushes anteriores no implican FAIL ni PASS.

**Commits 09:** fixture `62aa15f89b2ab49e1c097f4f888ff1ff33263e1d`, Godot `9af9ddf3df656ba416acf217df0a86b1ede749a1`, Python `df292337f4f2ccb69bb35e8e04e807051f7daee6`, progreso `93bd706149928f63c2cf5cd318ce4a32fa013bc8`, informe `00c42de22a84a877ddafc8cd16ecf5d8c0455abe`. Solo rutas W02 para este bloque. Existe un cambio ajeno de workflow `43876a6d833958d2d7ad86ce15014b011778007a` incorporado por IA6, no tocarlo ni presentarlo como propio.

**Próxima `p`:** bloque **10/10**: `yache_berry;grepa_berry;hondew_berry;pomeg_berry`. Revisar resultado de CI 09 antes, preservar regresiones y al terminar crear `CAMP_003_FINAL.md`; entonces parar y comunicar `CAMPAÑA_003_FINALIZADA`. Nunca iniciar fila 11 ni campaña nueva por impulso.

---

## ARCHIVO HISTÓRICO — ESTADOS 08/10 Y ANTERIORES

> **ACTUALIZACIÓN DE CI VERIFICADA (2026-11-03):** [Actions #41563958549](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41563958549), SHA de pruebas/progreso `992b31cde4984d1c6ca3e1f87a192b96247f71f4`, `completed/success`. Recibos auténticos: `CAMP003_W02_PY PASS blocks=8 checks=535`, `CAMP003_GATE_PY_PASS worker=W02 blocks=8 checks=535`, `CAMP003_W02_GODOT PASS blocks=8 checks=5795`, `CAMP003_GATE_GODOT_PASS worker=W02 blocks=8 checks=5795`. Certificados los bloques 01–08, incluidas las reparaciones del arnés del bloque 06. Las referencias anteriores a "CI pendiente" de este documento describen el estado histórico al publicarse, ya reemplazado por este PASS. **No se ha ejecutado la fila 09.** Se incorpora `AUTONOMOUS_REPAIR_V5.md` (blob `ebe71ace6949cc9311eb9831068799081bca8ba7`) como autorización vigente para reparar pruebas y código funcional de las bayas propias exclusivamente en esta rama, con regresiones y sin modificar `main`, V28 ni funciones de otra IA.

> **EXCEPCIÓN DE AUTORÍA EN LA RAMA:** además de los 13 archivos W02, existe un cambio de workflow publicado directamente por IA6/usuario en commit `43876a6d833958d2d7ad86ce15014b011778007a`: `.github/workflows/parallel-camp003-worker-autoci.yml` añade `modules/**` a los triggers de CI. **W02 no realizó ni revirtió ese cambio.** Por tanto no presentar la totalidad del diff de rama como de autoría W02. La CI vigente del bloque 08 sigue siendo [#41563958549](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41563958549), SHA de tests/progreso `992b31cde4984d1c6ca3e1f87a192b96247f71f4`.

# IA2/W02 — CAMPAÑA_003: CONTINUIDAD VIGENTE / BLOQUE 08 DE 10

**Estado de entrega:** **08/10 PUBLICADO** en rama exclusiva `codex/calvo-items-20261103-w02-camp003`; octava fila de progreso `EN_CI_AUTOMATICA`. **CI nativa 06–08 aún no certificada**. La siguiente `p` ejecutará únicamente la fila 09; no ejecutar 10 hasta orden separada.

**Autoridad:** fila 08 de `CAMPAIGN_003_QUEUE_APPROVED.csv` blob `ea06a0a000fc4f3b8bab48e45e21fb549d753559` y `campaigns/CAMP_003_W02.md` blob `62498ebd44288a86e59986379dbc1b70e111ef1f`. Gate permite pruebas independientes durante CI pending, sin declarar PASS. Todas las ramas y producción ajenas prohibidas.

**Cuatro objetos de bloque 08:** `roseli_berry` (Hada vs Garchomp, `dazzling_gleam` positiva, `tackle` negativa); `rowap_berry` (devolución 1/8 del HP máximo del atacante tras `confusion` especial; `tackle` físico no dispara); `salac_berry` (1/5 PS, +1 Velocidad `p1a|spe|` y consumo; PS altos no); `shuca_berry` (Tierra vs Pikachu, `bulldoze` positiva, `tackle` negativa). Preferir Bulldoze a Earth Power para evitar KO del control y garantizar FLED; mantiene supereficacia y exigencia de reducción de daño.

**Suite acumulativa:** 32 bayas, 67 escenarios (9+8+8+9+8+9+8+8), 201 variantes `active/none/reserve`. SaveV2, checkout/checkpoint, FLED, inventario, consumo único, reserva inerte, recibos JSON SHA256. Rowap lee HP del enemigo del motor; Salac lee `|-boost|p1a:...|spe|` sin contaminar con movimientos. Campo/UI/GPU no cubiertos.

**Último PASS funcional previo:** [CI #41559377763](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41559377763), `completed/success` sobre bloques 01–05, Python 327 PASS, Godot 3612 PASS.

**FALLO REAL de bloque 07 (NO OMISIÓN):** [CI #41560981081](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41560981081), Python 463 PASS blocks=7, Godot FAIL blocks=6 checks=5073. Causas del arnés en bloque 06: Mago autolesión por confusión afecta cálculo de HP, Maranga falso boost SpD de Amnesia, Occa KO del Scizor sin baya. Reparación test-only: `dd0c3e9eaca1724fb525b24f1b56cd8238133feb`, `9773e00baf10b23185a43657a473b5fff5852284`, `5faad6d8f95d8976e521c391611ca5affc1ca251`. Se mantienen todas las expectativas: Mago debe curar 1/3 PS con Endeavor de Snorlax a 1 HP, Maranga gana SpD sin Amnesia, Occa reduce golpe de fuego sin KO del testigo. Reejecuciones intermedias canceladas por pushes `cancel-in-progress`, **sin PASS todavía**.

**Bloque 08 commits:** fixture `6623c6a8b8a2e8f7db2c7e989736807a3a117f78`, GDScript `19e266594e233e375e5b1e21f6259d6f146d5aac`, validador Python `6049e1cdd2a14ad43088535c476c0ccaad7ef34d`, octava fila CSV `992b31cde4984d1c6ca3e1f87a192b96247f71f4`, informe `d0fcc6ee66511123a96bd0793d4b87c478ac569f`. Ningún cambio fuera de archivos W02.

**CI actual:** [#41563958549](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41563958549), SHA de tests/progreso `992b31cde4984d1c6ca3e1f87a192b96247f71f4` (primer commit con 8 filas). Exigir **`CAMP003_W02_PY PASS blocks=8 checks=M` y `CAMP003_W02_GODOT PASS blocks=8 checks=M`** para considerar verificados 06–08. Si falla, inspeccionar el log y reparar exclusivamente tests propios sin reducir exigencia; defecto compartido de motor/SaveV2 => STOP y consultar IA6. Cancelled no es éxito ni defecto funcional.

**Siguiente `p`:** fila **09/10**: `starf_berry;tanga_berry;wacan_berry;wiki_berry`. Revisar CI primero, seguir solo si no hay un fallo funcional irresuelto. No tocar `main`, V28, PR #118, producción, catálogo, CI compartida, IA6, W04 ni otras ramas.

---

## HISTÓRICO — ESTADO 07/10 Y ANTERIORES

# IA2/W02 — CAMPAÑA_003: CONTINUIDAD VIGENTE / BLOQUE 07 DE 10

**ESTADO:** 07/10 ENTREGADO, `EN_CI_AUTOMATICA` en rama propia `codex/calvo-items-20261103-w02-camp003`. La `p` siguiente autoriza únicamente **08/10** y exige consultar primero el resultado de CI de los bloques 06–07. No iniciar 09 con la misma orden.

**Autoridad:** `CAMPAIGN_003_QUEUE_APPROVED.csv` blob `ea06a0a000fc4f3b8bab48e45e21fb549d753559`, encargo `campaigns/CAMP_003_W02.md` blob `62498ebd44288a86e59986379dbc1b70e111ef1f`. W04 fue reincorporado con cola/CI independiente sin afectar la fila 07 W02.

**Bloque 07 exacto:** `passho_berry` (Charizard/Surf Agua sí, Tackle no), `payapa_berry` (Gengar/Psychic Psíquico sí, Tackle no), `petaya_berry` (Mew al 20 % PS +1 SpA al portador, PS casi máximos no), `rindo_berry` (Blastoise/Energy Ball Planta sí, Tackle no). Origen `tools/item_audit/held_effect_sweep_v2.cjs`, prueba anterior de efectos equipados nativos; ninguna implementación nueva. Petaya usa movimiento propio `amnesia`, que no sube SpA; el runner escucha `|-boost|p1a:` y `|spa|` exclusivamente. Se añaden 11 mutaciones adversariales Python contra falsos PASS.

**Suite acumulativa:** 7×4 = **28 bayas**, 9+8+8+9+8+9+8 = **59 escenarios**, **177 variantes** de `active/none/reserve`. Mantener todo lo anterior, incluido Micle de dos turnos. Se exigen consumo único, no gasto desde reserva, SaveV2, restauración de checkpoint, FLED y recibos de JSON SHA256. Campo/GPU/UI no testeados.

**Último PASS real:** [GitHub Actions #41559377763](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41559377763) `completed/success`, bloques **01–05**, Python **327 comprobaciones**, Godot **3612 comprobaciones**.

**Bloque 06 no certificado todavía:** [Actions #41560377509](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41560377509) se **canceló por un push posterior** sin recibo Godot final; Python **398 checks PASS** sí observado. `cancelled` no significa `functional failure` pero tampoco `PASS`. El último run completo debe verificar ambos bloques 06 y 07.

**CI actual:** [Actions #41560981081](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41560981081), SHA tests/progreso `d7820e1b2aecc5cff13f13f1c289609a22c3a9ad`, inicialmente pendiente. Exigir `CAMP003_W02_PY PASS blocks=7 checks=M` y `CAMP003_W02_GODOT PASS blocks=7 checks=M` para confirmar 07/10. Si falla en test, corregir **solo W02** sin bajar exigencias. Si falla motor o SaveV2 compartido, STOP y solicitar IA6. No confundir runs cancelados/0 bootstrap con pruebas.

**Commits del bloque 07:** fixture `18a84e704a43240b66fe0d0265fe563eaff85ba8`; runner `76fbf729fa843772e8bf5ba53f7d27d58fc20f9b`; Python `96f2a528b8a81e5e7dbb5a81e4f60e864726c711`; CSV `d7820e1b2aecc5cff13f13f1c289609a22c3a9ad`; informe `a4ce690a7b62e86586baeefe410b65bb18545219`. Solo los seis archivos W02 habituales (fixture, runner, validador, progreso, informe, cuaderno).

**Siguiente `p`:** bloque 08 exacto `roseli_berry;rowap_berry;salac_berry;shuca_berry`. Antes revisar CI del último SHA. No tocar `main`, V28, producción, catálogo canónico, workflow, otras ramas ni IA4.

---

## ARCHIVO HISTÓRICO — ESTADO 06/10 Y ANTERIORES

# IA2/W02 — CAMPAÑA_003: CONTINUIDAD VIGENTE / BLOQUE 06 DE 10

**ESTADO:** 06/10 ENTREGADO en `codex/calvo-items-20261103-w02-camp003`, `EN_CI_AUTOMATICA`. El siguiente `p` puede ejecutar **solo el bloque 07** tras verificar semáforo del último workflow; no saltar ningún bloque.

**Autoridad:** `CAMPAIGN_003_QUEUE_APPROVED.csv` blob `ea06a0a000fc4f3b8bab48e45e21fb549d753559`; encargo `campaigns/CAMP_003_W02.md` blob `62498ebd44288a86e59986379dbc1b70e111ef1f`. W04 reincorporado por addendum independiente, sin alterar W02.

**BLOQUE 05 CI REAL CONFIRMADA:** [Actions #41559377763](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41559377763), `completed/success`, SHA `fd6fd0b6a40b2e5a0780607d268c9eb60d51204f`; recibos **Python 327 checks PASS, Godot 3612 checks PASS, 5 bloques**.

**Bloque 06 cuatro IDs:** `mago_berry` (Brave rechazo de sabor y confusión/H ardy sin confusión/PS altos); `maranga_berry` (especial `confusion` +1 SpD vs físico `tackle`); `micle_berry` (PS bajos, efecto diferido `micleberry` tras `reflect`, checkpoint restaurado y consumo del efecto en segundo turno con `hydro_pump`, frente a PS altos); `occa_berry` (Fuego supereficaz contra Scizor vs Normal).

**Cobertura:** nueve nuevos escenarios, 27 variantes; 6 bloques acumulados (9+8+8+9+8+9) = **51 escenarios, 153 variantes, 24 IDs distintos**. Modos `active/none/reserve`, consumo y posición, `SaveGameRepository` SaveV2, restauración sin falsear, FLED, evidencias JSON + SHA256. Se conserva todo lo anterior. Para Micle, `_native_volatile()` lee `_checkpoint.roster` de Godot como proyección nativa de `volatiles` por `instance_id`; comprueba si el efecto persiste después de cargar y termina tras el próximo movimiento. No afirmar incremento porcentual de precisión con un solo movimiento.

**Referencias históricas (read-only):** `held_effect_sweep_v3.cjs` (Mago y Micle, múltiples semillas), `held_effect_sweep_v2.cjs` (Maranga/Occa). No crear callbacks nuevos: los efectos ya están en el motor.

**Pruebas publicadas:** fixture commit `66fbae22a05e84326fdbf9b6a21e9a886238f42e`; Godot `744057924c583f0e73e8900ce4d89b71f19cbd07`; Python `e0791b6d88b680b06bfc8fd5436532adf0e0bcc6`; CSV `e1bd985da220fcff2578be97cd4de4f53167b1af`; informe `ce68e6996f70cd288f5ba6a4b2a7b3106e5a6c61`. Solo rutas de escritura W02.

**CI bloque 06:** [Actions #41560377509](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41560377509) sobre SHA `e1bd985da220fcff2578be97cd4de4f53167b1af`, inicialmente `pending`. Exigir **`CAMP003_W02_PY PASS blocks=6 checks=M` y `CAMP003_W02_GODOT PASS blocks=6 checks=M`**. Si failure, inspeccionar log exacto. Un problema de arnés corregible se repara sin rebajar aserciones; defecto compartido de motor/SaveV2, detener e informar a IA6. No reinterpretar cancelaciones de CI intermedia como fallos funcionales.

**Siguiente `p`:** BLOQUE **07/10** exclusivamente `passho_berry;payapa_berry;petaya_berry;rindo_berry`; verificar CI/progreso antes de escribir. No tocar `main`, V28, PR #118, producción, catálogo, IA6, W04, otras ramas o workflows. Campo e imágenes GPU fuera de alcance.

---

## ARCHIVO HISTÓRICO — ESTADO 05/10 Y ANTERIORES

# IA2/W02 — CAMPAÑA_003: CONTINUIDAD VIGENTE / BLOQUE 05 DE 10

**Estado:** BLOQUE **05/10 PUBLICADO**, `EN_CI_AUTOMATICA` del SHA con cinco filas de progreso, `fd6fd0b6a40b2e5a0780607d268c9eb60d51204f`. Solo la `p` siguiente autoriza **bloque 06** si semáforo CI lo permite. Rama exclusiva `codex/calvo-items-20261103-w02-camp003`.

**Autorización:** cola `CAMPAIGN_003_QUEUE_APPROVED.csv` (blob `ea06a0a000fc4f3b8bab48e45e21fb549d753559`) y `campaigns/CAMP_003_W02.md` (blob `62498ebd44288a86e59986379dbc1b70e111ef1f`). IA4 reincorporada por addendum distinto; nada cambia en la cola W02.

**Bloque 04 CONFIRMADO en CI:** [#41558465659](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41558465659), `completed/success`, SHA `1e1e71d9c29bf00e764f5fe6039a8648feed1f46`; Python **256 comprobaciones PASS**, Godot **2925 comprobaciones PASS**, `blocks=4`. Un PASS previo no certifica el 05.

**Bloque 05 exacto:** `kebia_berry` (Poison supereficaz contra Clefable/no coincidente), `kee_berry` (golpe físico +1 Defensa vs especial), `lansat_berry` (PS bajos +focusenergy vs PS altos), `liechi_berry` (PS bajos +1 Ataque vs altos). Dos escenas por ID: **8 escenarios ×3 modos de dueño = 24 variantes nuevas**.

**Matriz acumulativa:** bloques 01–05, **20 IDs**, 9+8+8+9+8 = **42 escenarios**, **126 variantes nativas previstas**. Mantener todas las anteriores; equipamiento `active,none,reserve`, checkpoint/restore, SaveV2, cierre FLED, inventario y consumo atómico, recibos con SHA256. En bloque 05 los movimientos propios son `amnesia` para que la subida de Ataque de Liechi no se confunda con Swords Dance. Boosts/volatile se atribuyen solo a `p1a`.

**Referencias reales (read-only):** `tools/item_audit/held_effect_sweep_v2.cjs`: `kebia_berry`, `kee_berry`, `liechi_berry`; `tools/item_audit/held_effect_sweep_v3.cjs`: `lansat_berry` con `critical_focus/full_hp`. Reutilizar motor fijado, nunca escribir callbacks nuevos.

**Commits del bloque 05:** fixture `4ef4dae9861d422c1d940a2e3dc67c90f2170db0`, Godot `829d52379bb90bb99ddc10631e400c9961aa1024`, Python `78edab9ff8df12ee202552ca55642ccb7503d9af`, CSV `fd6fd0b6a40b2e5a0780607d268c9eb60d51204f`, informe `57491cb24a3a7e569484e65c4cc3437ef9dbbc58`. Solo seis archivos W02 modificados en este bloque (fixture, runner, Python, CSV, informe y cuaderno).

**CI bloque 05:** [#41559377763](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41559377763), run asociado al SHA de pruebas/progreso `fd6fd0b6a40b2e5a0780607d268c9eb60d51204f`. Verificar `completed/success` y recibos `CAMP003_W02_PY PASS blocks=5 checks=M`, `CAMP003_W02_GODOT PASS blocks=5 checks=M`. Hasta entonces estado de CI pendiente. FAIL real: reparar SOLO tests/fixtures W02 sin rebajar contrato; defecto compartido o persistencia → detener y escalar a IA6. Cancelled intermedios no equivalen a FAIL.

**Siguiente `p`:** bloque **06/10**, `mago_berry;maranga_berry;micle_berry;occa_berry`. Nunca bloque 07 simultáneo ni nuevos IDs fuera de reserva. Prohibidos `main`, V28, PR #118, production `modules/`, `data/`, `config/`, catálogo, IA6, workflows, ramas ajenas. Campo/GPU sin cobertura de esta suite.

---

## HISTÓRICO — ESTADO 04/10 Y ANTERIORES

# IA2/W02 — CAMPAÑA_003: CONTINUIDAD VIGENTE / 04 DE 10

**Estado operativo:** bloque **04/10 ENTREGADO**, `EN_CI_AUTOMATICA` hasta verificar `completed/success` del SHA `1e1e71d9c29bf00e764f5fe6039a8648feed1f46`. Rama exclusiva `codex/calvo-items-20261103-w02-camp003`. Una `p` posterior ejecutará únicamente **05/10**, nunca dos bloques en una orden.

**Autoridad:** cola `CAMPAIGN_003_QUEUE_APPROVED.csv` blob `ea06a0a000fc4f3b8bab48e45e21fb549d753559`; encargo W02 `campaigns/CAMP_003_W02.md` blob `62498ebd44288a86e59986379dbc1b70e111ef1f`; gate V4 vigente. La incorporación separada de IA4 no altera las diez filas de W02.

**Última CI anterior VERIFICADA:** [Actions #41556875512](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41556875512) `completed/success`, SHA `44482761ab0217323335d9a1bc63f060cbcad513`. Recibos `CAMP003_W02_PY PASS blocks=3 checks=187` y `CAMP003_W02_GODOT PASS blocks=3 checks=2071`. No representa el nuevo bloque 04.

**Bloque 04 entregado:** `haban_berry` (resiste Dragón supereficaz), `iapapa_berry` (PS bajos, rechaza sabor en `lonely`, neutra `hardy`, PS altos control), `jaboca_berry` (daño físico al atacante `floor(maxHP/8)`, no especial), `kasib_berry` (resiste Fantasma supereficaz). **9 escenas nuevas, 27 variantes**; acumuladas **34 escenas/102 variantes** en 16 bayas. Todas incluyen `active/none/reserve` y SaveV2.

**Fuentes:** `tools/item_audit/held_effect_sweep_v2.cjs` para Haban/Kasib, `held_effect_sweep_v3.cjs` para Iapapa/Jaboca. Reutilizar lógica existente, nunca crear efectos nativos. Para Jaboca verificar PS del enemigo real; para Iapapa filtrar confusión y recalcular stats de naturaleza.

**Archivos W02 ya publicados:** fixture commit `35e019737ff554ee784870df113ffd7a100be78d`, runner `8e4b99d66025b43cb5cdbcb641465adf64e9d374`, Python `d4af169883004f0929371738b66b2eb48585f8fb`, CSV bloque 04 `1e1e71d9c29bf00e764f5fe6039a8648feed1f46`, informe `fb3be6a30bc57b80e4f5edbb0b5ccd58a9c417c6`. Rutas: `tests/fixtures/parallel_items/w02_campaign_003.json`, `tests/gameplay/parallel_items_w02_campaign_003.gd`, `tests/tools/test_parallel_items_w02_campaign_003.py`, `docs/coordination/items_parallel_v1/reports/W02/CAMP_003_PROGRESO.csv`, `CAMP_003_ITER_04.md` y este cuaderno.

**CI actual:** [Actions #41558465659](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41558465659), SHA de progreso `1e1e71d9c29bf00e764f5fe6039a8648feed1f46`. Exigir `CAMP003_W02_PY PASS blocks=4 checks=M` y `CAMP003_W02_GODOT PASS blocks=4 checks=M`. Hasta logs y SHA, **no afirmar PASS nuevo**. Cancelaciones de runs de test intermedios son esperadas.

**Siguiente `p`:** solo bloque **05** `kebia_berry;kee_berry;lansat_berry;liechi_berry`, verificar último workflow primero, no repetir bloques 01–04; cualquier fallo de prueba propia se repara sin reducir expectativas y cualquier dependencia de producción detiene y avisa IA6.

**Protecciones:** jamás tocar `main`, V28, PR #118, IA6, otras ramas, W04, `modules/`, `data/`, `config/`, catálogo, producción o workflows compartidos. Campo, pantalla y GPU no probados por este arnés.

---

## HISTÓRICO — ESTADO 03/10 Y ANTERIORES

# W02 — CAMPAÑA_003: CONTINUIDAD VIGENTE / 03 DE 10

**Estado:** bloque **03/10 ENTREGADO**, `EN_CI_AUTOMATICA` para SHA que incorpora tres filas de progreso. **Solo la siguiente `p` ejecutará bloque 04** si el último run no es FAILURE. Rama exclusiva `codex/calvo-items-20261103-w02-camp003`.

**Autoridad:** `CAMPAIGN_003_QUEUE_APPROVED.csv` blob `ea06a0a000fc4f3b8bab48e45e21fb549d753559`, `campaigns/CAMP_003_W02.md` blob `62498ebd44288a86e59986379dbc1b70e111ef1f`. IA6 mantiene íntegra W02 bajo ampliación de W04; no modifica la cola de 40.

**Bloques precedentes verificados:** 01/02 en [Actions #41555493832](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555493832), SHA `926ad81488c1e83d777177bfa5a2eff35b028eca`, **Python 122 checks PASS, Godot 1406 checks PASS, 2 bloques**. El filtro Apicot solo `p1a` sigue conservado (error anterior ya reparado; no volver a modificar por cuenta propia).

**BLOQUE 03 nuevos:** `colbur_berry` Siniestro contra Mew/ataque no coincidente; `custap_berry` orden de acción Snorlax lento vs Gengar rápido al 1/5 de PS/PS máximos; `enigma_berry` curación tras `thunder_shock` eléctrico supereficaz a Gyarados vs `tackle` no disparador; `ganlon_berry` subida de Defensa al cruzar 1/4 PS vs PS altos. Hay **ocho escenarios nuevos, 24 variantes**.

**Acumulado:** 3 bloques, 12 bayas diferentes, 25 escenarios, 75 variantes `active,none,reserve`; pruebas de consumo único, actor correcto en el log, no gasto de reserva, cierre FLED, SaveV2 y recibos SHA256. No pruebas de campo, GUI, GPU ni producción.

**Contratos de referencia:** `tools/item_audit/held_effect_sweep_v2.cjs`: Colbur/Ganlon; `held_effect_sweep_v3.cjs`: Custap/Enigma. Son pruebas de mecanismo existente; no se implementaron nuevas mecánicas.

**Archivos W02 escritos:** `tests/fixtures/parallel_items/w02_campaign_003.json` commit `cd837d26ca2283296a11dbd41af8672208694de0`; `tests/gameplay/parallel_items_w02_campaign_003.gd` commit `94d107df596ced40283845430e8cb36e9e7a686f`; `tests/tools/test_parallel_items_w02_campaign_003.py` commit `8e5b6b111c17259d0f73c08d8bb307a64155afa7`; `CAMP_003_PROGRESO.csv` tercera fila commit `44482761ab0217323335d9a1bc63f060cbcad513`; `CAMP_003_ITER_03.md` commit `88f5654fcaccff06ac8a3e297825e129864377f9`. Ningún otro archivo autorizado para escribir.

**CI automática:** comprobar run más reciente de la rama, en SHA de pruebas/progreso `44482761ab0217323335d9a1bc63f060cbcad513`. Se exige `CAMP003_W02_PY PASS blocks=3 checks=M` y `CAMP003_W02_GODOT PASS blocks=3 checks=M`. Si FAILED, inspeccionar log, reparar solo prueba propia sin rebajar aserciones; si defecto compartido, STOP y ticket IA6. Cancelled de runs previos por nuevo push no equivale a FAIL.

**Siguiente `p`:** bloque 04 de cola exacta `haban_berry;iapapa_berry;jaboca_berry;kasib_berry`; consultar progreso y último run. No iniciar bloque 05 ni 11, ni tocar `main`, V28, producción/catálogo/IA6/ramas ajenas ni W04.

---

## HISTÓRICO — 02/10 Y ANTERIORES

> **CI POSTERIOR VERIFICADA — 2026-11-03:** [Actions #41555493832](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555493832) `completed/success` sobre SHA de tests/progreso `926ad81488c1e83d777177bfa5a2eff35b028eca`. Recibos auténticos de logs: `CAMP003_W02_PY PASS blocks=2 checks=122` y `CAMP003_W02_GODOT PASS blocks=2 checks=1406`. El estado anterior `EN_CI_AUTOMATICA` de este documento/CSV describe la entrega inicial y está superado por esta ejecución. Para evitar otra CI redundante, el CSV de progreso no se reescribe: la evidencia de PASS queda aquí y en el cuaderno. **Próxima `p`: bloque 03/10 solamente.**

# IA2/W02 — ESTADO ACTUAL DE CAMPAÑA_003 (02/10)

**BLOQUES PUBLICADOS:** 01 y 02 de 10. La siguiente `p` autoriza SOLO bloque 03 si semáforo CI permite continuar. Rama `codex/calvo-items-20261103-w02-camp003`, exclusivamente pruebas/fixture/progreso/informes W02. No inventar bloque 11 ni modificar CI compartida.

**Reparación anterior verificada:** CI #41553745691 FALLÓ en Apicot por atribución a `p2a` de boost SpD de Amnesia del rival; filtrado en prueba `|-boost|p1a:` commit `2449baf285ef9eaffdb4fa030f78dfe3ee8c551c`; [CI #41554998986](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41554998986) `completed/success`. Ningún cambio en producción.

**Bloque 02:** `charti_berry`, `chilan_berry`, `chople_berry`, `coba_berry`; histórico `held_effect_sweep_v2.cjs` ya verifica resistencia ante Roca/Normal/Lucha/Volador. Positivos `smack_down/tackle/brick_break/aerial_ace`, controles negativos `tackle/surf/tackle/tackle`, portadores `charizard/mew/snorlax/venusaur`. Chilan protege de Normal sin supereficacia.

**Suite acumulativa:** 9 casos del bloque 01 (4 IDs) + 8 casos del bloque 02 (4 IDs) = **17 escenarios, 51 variantes nativas previstas** (`active/none/reserve`). Integridad SHA256 de recibos, recuperación y SaveV2; solo equipadas. Campo/UI/GPU no probados. Python obliga cumplimiento exacto de 8 casos y 6 controles adversariales nuevos; evita falsos PASS de bloque futuro.

**Pruebas publicadas:** fixture commit `919f36e444a572b973852b3ef4f114c83d6f6707`; runner `ed5c2f2dd1ca8620f6fcb0d066942dd721734fcd`; validador Python `feddccce4d23571d989784e89919305dceede825`; CSV `926ad81488c1e83d777177bfa5a2eff35b028eca`; informe `d5d76f0940653b60af1018f845d986f663576038`.

**CI del bloque 02:** [#41555493832](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555493832), inicialmente pending, SHA de pruebas publicado con bloque 02 en CSV `926ad81488c1e83d777177bfa5a2eff35b028eca`. Exige `CAMP003_W02_PY PASS blocks=2 checks=M` y `CAMP003_W02_GODOT PASS blocks=2 checks=M`, sin inventar PASS antes de resultado. Los runs previos del mismo bloque se cancelan por concurrencia.

**Siguiente `p`:** bloque **03** de cola IA6: `colbur_berry;custap_berry;enigma_berry;ganlon_berry`. Consultar run más reciente, detener si FAIL real, reparar test propio si demuestra bug del arnés. Nada de producción, `main`, V28, PR #118, otras ramas o IA4.

---

# ARCHIVO HISTÓRICO — ESTADO AL FINAL DEL BLOQUE 01

# IA2/W02 — CONTINUIDAD VIGENTE / CAMPAÑA_003

**ESTADO HISTÓRICO:** BLOQUE **01/10 ENTREGADO**, `EN_CI_AUTOMATICA`, pendiente verificación de GitHub Actions #41553745691 (primer SHA con CSV 1/10). Los PASS de bootstrap 00/10 no acreditan funcionamiento.

**Rama exclusiva:** `codex/calvo-items-20261103-w02-camp003`. Arranque de IA6 `41c1efeba0346349490f863131179ed7a8fc274c`. No fusionar CAMP001/CAMP002. La rama contiene el workflow/validador global de IA6 que **no puede editar W02**.

**Autoridad:** `CAMPAIGN_GATE_003.md` blob `390f7ce6897462e1ae8e3cc7e3cd5f799b6c2213`; `campaigns/CAMP_003_W02.md` blob `62498ebd44288a86e59986379dbc1b70e111ef1f`; cola `CAMPAIGN_003_QUEUE_APPROVED.csv` blob `ea06a0a000fc4f3b8bab48e45e21fb549d753559`. Diez bloques fijos: `p` ejecuta SOLO el siguiente. W04 no participa.

**BLOQUE 01 IDs:** `aguav_berry`, `apicot_berry`, `aspear_berry`, `babiri_berry`. Nuevos nueve escenarios, 27 variantes previstas de portador activo/sin objeto/reserva, consumo, curación/confusión, boost SpD, cura freeze, resistencia Steel, SaveV2/recibos SHA256. **No pruebas de campo ni cambios de producción**.

**Fuente técnica:** `tools/item_audit/held_effect_sweep_v3.cjs` (Aguav Naughty/Hardy); `held_effect_sweep_v2.cjs` (Apicot SpD, Aspear freeze, Babiri acero sobre Clefable). Reutiliza `tests/gameplay/item_automation_v28.gd` y `item_automation_opponent_v28.gd`; motor `@pkmn/sim` sigue fijado. Fuentes existentes no equivalen al PASS de nuevas variantes.

**Archivos de escritura permitidos:** `tests/gameplay/parallel_items_w02_campaign_003.gd`, `tests/tools/test_parallel_items_w02_campaign_003.py`, `tests/fixtures/parallel_items/w02_campaign_003.json`, `reports/W02/CAMP_003_PROGRESO.csv`, informes `reports/W02/CAMP_003_ITER_XX.md`, `CONTINUIDAD.md`. No escribir workflow, manifiesto global, otro worker ni producción.

**Commits:** fixture `da00c3ab3565d46d42000e1a9f21c399bbc9270d`; Godot `a580fb13d27e074f5d847ce491bac04bd0128d76`; Python `3c8f2808a2011803b0450fd3d3a10726a4be0374`; CSV `a278495a20345e86458d13e536198140d78ae5f9`; informe `3e092736549f219778504b5ccaa9d7052400b7e2`. El HEAD final se consulta GitHub, no se incrusta recursivamente.

**CI:** [run #41553745691](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41553745691). Exige recibos `CAMP003_W02_PY PASS blocks=1 checks=M` y `CAMP003_W02_GODOT PASS blocks=1 checks=M`. Si FAIL por pruebas reparables, corregir SOLO pruebas W02 sin relajar contrato; defecto nativo/SaveV2 compartido, STOP y pedir IA6.

**Siguiente `p`:** bloque 02 por cola oficial: `charti_berry;chilan_berry;chople_berry;coba_berry`. Leer CSV/último SHA de CI antes de escribir, ampliar arnés acumulativo y documentar. No saltar a bloque 03 ni iniciar fuera de 10/10.

**Prohibiciones:** `main`, V28, ramas ajenas, `modules`, `data`, `config`, guardados reales, catálogo, Mega, CI compartida, IA4. Fines visuales/GPU fuera del alcance headless.

---

## ARCHIVO HISTÓRICO ANTERIOR (LOTE_002, no concede autoridad CAMP003)

# W02 / IA2 — Cuaderno de continuidad (bayas y consumo)

> Memoria operativa exclusiva de `codex/calvo-items-20261101-w02`. La **autoridad de encargos** sigue siendo IA6 en `codex/calvo-items-20261101-arbitro`; este cuaderno no concede permisos nuevos.

## 1. Identidad, base y estado

- **Rol:** IA2/W02. **Familia:** BERRY; objeto de estos dos lotes: `sitrus_berry`, `lum_berry`, `colbur_berry`.
- **Lote vigente al cierre:** `LOTE_002_W02`, [encargo oficial](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-arbitro/docs/coordination/items_parallel_v1/assignments/LOTE_002_W02.md), blob `6615339c816bb9159467c3c3e99477efb95e4792`.
- **Estado:** `LISTA_PARA_REVISION` con `PENDIENTE_CI`. IA6 aceptó LOTE_001 **como auditoría documental**; no hay todavía aceptación del LOTE_002.
- **Base oficial combinada:** `38188cc208e67b19002437ac75160898ce332ec2`; merge exclusivamente en W02 `98a45388df091697c660a28cd30e958240bf6dad`, sin force/rebase.
- **Conservación:** el informe LOTE_001 mantiene blob `8b49a29d9cbf98dac85ad3947e6b872bba8a6735` y commit de entrega histórico `dd9d1616e405f5ac2d455185abbc7f5a39449233`.
- **Último commit conocido antes de escribir este cuaderno:** informe LOTE_002, `b1ac9003b2d47a756d0412344e2f16ef0067b0a7`. El SHA definitivo del cuaderno es el HEAD posterior en GitHub; no incrustar un SHA autorreferencial.
- **Último commit funcional efectivamente ejecutado por W02:** **NINGUNO**. No se alteró producción ni se obtuvo PASS nuevo con Godot.
- **Escritura permitida por LOTE_002:** sólo `tests/gameplay/parallel_items_w02_berries_v1.gd`, `tests/tools/test_parallel_items_w02_berries_v1.py`, `tests/fixtures/parallel_items/w02_berries_v1.json`, `reports/W02/LOTE_002.md` y este cuaderno. Un lote futuro requiere asignación diferente.

## 2. Mapa técnico — localizar antes de programar

```text
RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv (selección de contenido; no implica mecánica terminada)
  → config/item_selection_v1.json (política runtime existente; NO editar)
  → FieldItemService (equipar, usar campo, dueño, mochila, PC, consumo transaccional)
      → FieldItemEffects + imported_recovery_v19.json: Zidra/Ziuela voluntarias de campo
      → showdown_adventure_session + native_engine.cjs + @pkmn/sim@0.10.11:
          Zidra/Ziuela/Dillo EQUIPADAS: hooks y RNG nativos, sin duplicar callbacks
  → snapshot y SaveGameRepository / SaveV2 → publicación tras combate → mochila/UI
```

**Código de referencia de la línea V27:**
- `modules/inventory/field_item_service.gd` blob `b682c3af93b7af170c8aea66a130176c908b0745`: `configure`, `holdable`, `equip`, `unequip`, `use_item`, `_apply_field_effect`.
- `modules/inventory/field_item_effects.gd` blob `0c0eec6e7718144f2edd62b99f44984c39cdda33` usa `modules/inventory/imported_recovery_v19.json` blob `328c82722c068925415cc64bcec9a0c5790f84cd`; Dillo NO pertenece al perfil de curación voluntaria.
- `modules/battle/backends/showdown/native_engine.cjs` blob `1eacd1654d005b53324b4914c1af8db531d00068`, simulador fijado `@pkmn/sim@0.10.11`.
- `modules/inventory/item_connections_v1.json` blob `0525b37021edfc2e74c4fc2cb96e62f6f5b3e261`, los tres son equipables. La política activa no se modificó.
- Infraestructura heredada de V28: `tests/gameplay/item_automation_v28.gd`, `tests/gameplay/item_case_replay_v28.gd`, `tests/gameplay/item_automation_opponent_v28.gd`, `tools/item_audit/replay_v28.py`. **Son zonas compartidas de SOLO LECTURA**.

## 3. Estado verificado por ID

| ID | Qué existe | Evidencia exacta | Límite / acción futura |
| --- | --- | --- | --- |
| `sitrus_berry` | Hook nativo, recuperación cuarto de PS por objeto equipado, perfil de campo, traspaso y consumo. | `held_pilot.cjs:31`, histórico V1; `item_field_recovery_v5.gd:40–168` V5 (equipo/PC, tope, UI/guardar). Nueva prueba W02 `sitrus_low_hp/high_hp` **SIN_EJECUTAR**. | Probar CI y luego umbral atravesado por golpe/turno, no duplicar campo ya cubierto. |
| `lum_berry` | Hook nativo para limpiar estado, curación voluntaria completa de campo, stock. | `held_pilot.cjs:33` V1 (veneno y gasto); V5 para múltiples estados en campo. Nueva prueba W02 `lum_poison/healthy` **SIN_EJECUTAR**. | Falta prueba nueva de confusión/status alternos EQUIPADA, no dar por cubierto con V5. |
| `colbur_berry` | Hook nativo reducción Siniestro supereficaz, no consumo por tipo no coincidente; no uso de recuperación en campo. | `held_effect_sweep_v2.cjs:12,32–35`, V2; V28 replay 4 casos, [Actions #41255004688](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41255004688) PASS **histórico limitado**. Nuevos `super_dark/neutral_dark/other_type` **SIN_EJECUTAR**. | Comprobar neutralidad Siniestro, portador reserva y stock tras FLED; ampliar otros contextos sólo con nueva orden. |

**Clasificación:** hay `FUNCION_Y_PRUEBA` **histórica y acotada** en los tres, y `CONEXION_PARCIAL` para cierre global. Ni LOTE_001 ni la redacción de tests nuevos los hacen `FUNCIONALES_CERTIFICADOS`.

## 4. Historial y material reutilizable

| Lote | Cambios verdaderos | Evidencia/commit | Pruebas y revisión |
| --- | --- | --- | --- |
| 001 | Solo `reports/W02/LOTE_001.md`. Auditó código, estado y regresiones existentes. | `dd9d1616e405f5ac2d455185abbc7f5a39449233` | 22/22 verificaciones **estáticas**; 0 Godot nuevo. **ACEPTADA POR IA6 como auditoría**. |
| 002 | Merge conservador + fixture de 7 escenarios + runner Godot con 3 variantes + validador Python con 13 tests + informe + este cuaderno; 0 producción. | Merge `98a45388...`, [informe LOTE_002](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w02/docs/coordination/items_parallel_v1/reports/W02/LOTE_002.md) | 12/12 inspecciones **estáticas GitHub**. **Python, Godot y GPU SIN_EJECUTAR**; revisión IA6 pendiente. |

**Rutas nuevas:**
- `tests/fixtures/parallel_items/w02_berries_v1.json` blob `0d8d52767b768967437e1719b8cab001fac6a512`: 7 casos por activo/sin objeto/reserva.
- `tests/gameplay/parallel_items_w02_berries_v1.gd` blob `12cab8469836d8b57b42ef467b0e3a4eaded191d`: sesión real, comparaciones nativas, cierre FLED y SaveV2.
- `tests/tools/test_parallel_items_w02_berries_v1.py` blob `a6d346a74909902971b4db600c25a5cddd00a011`: verificación estricta de evidencias e integridad del contrato, pruebas sintéticas negativas. No transforma un JSON en una mecánica Pokémon.

## 5. Comandos y estado de pruebas

Desde raíz de checkout aprobado por IA6 (requiere runtime `@pkmn/sim@0.10.11` y Godot 4.7):

```bash
python tests/tools/test_parallel_items_w02_berries_v1.py --fixture-only
python tests/tools/test_parallel_items_w02_berries_v1.py --unittest
godot --headless --path . --script res://tests/gameplay/parallel_items_w02_berries_v1.gd
python tests/tools/test_parallel_items_w02_berries_v1.py --result .godot/parallel_items/w02_berries_v1/godot.json
```

**Estado:** los cuatro comandos `SIN_EJECUTAR` sobre el checkout completo; no hay reporte `godot.json` auténtico ni SHA de ejecución W02. No repetir CI por cada commit documental: **una sola ejecución consolidada** una vez revisada por IA6, con logs y raw.

## 6. Deuda, colisiones y siguiente relevo

- Checkpoint integrado `38188cc...` **no certificado por CI**. No asumir que V28 y catálogo funcionan combinados por el mero hecho de un merge sin conflictos.
- El runner actual compara siete contextos, no todos los de Pokémon (dobles, estado alternativo, sustituto, inmunidades, victoria/derrota, reentrada, ataque que cruza umbral de Zidra y UI/GPU siguen abiertos).
- Las tres bayas comparten infraestructura de simulador y guardado; **no añadir callbacks por objeto en GDScript ni cambiar `native_engine` o `FieldItemService` sin orden**.
- Prohibido tocar `main`, V28, árbitra, otras ramas, `QUEUE_V1.csv`, catálogos originales, config, arte, schema, guardados, workflow o tests antiguos.
- **Retomar:** 1) consultar encargo más reciente de IA6 en su rama y verificar blob; 2) leer este cuaderno y último informe; 3) comprobar HEAD y compare del checkpoint; 4) IA6 debería revisar diff y ejecutar/supervisar Python + Godot en CI consolidada; 5) registrar run SHA, PASS/FAIL y defectos concretos, sin promover falsamente los tres IDs a certificado; 6) empezar LOTE_003 **solo** si IA6 publica nuevo permiso.

**Próximo paso reproducible:** revisión de IA6 y prueba consolidada del código W02. Si falla un escenario, localizar primero fixture, inicialización de estado, contrato nativo o persistencia; solicitar autorización si corregirlo necesita producción.

**Verificación visual/GPU:** pendiente; no se ha hecho en LOTE_002.
