# ESTADO VIGENTE IA5/W05 — CAMPAÑA_003 · 10/10 ENTREGADOS (2026-11-03)

**Identidad:** IA5/W05 (familia MT/libros). **Rama exclusiva:** `codex/calvo-items-20261103-w05-camp003`. Autoridad de IDs: cola IA6 `CAMPAIGN_003_QUEUE_APPROVED.csv`; alcance y reparación: `campaigns/CAMP_003_W05.md` y `AUTONOMOUS_REPAIR_V5.md` de `codex/calvo-items-20261101-arbitro`. **Los diez microbloques están entregados. Ninguna nueva `p` puede crear un bloque 11 ni una nueva campaña.**

**ÚLTIMO BLOQUE 10 publicado:** `tm75;tm76;tm78;tm79;tm80;tm81` mapeados a `light_screen;rock_blast;dragon_claw;dazzling_gleam;metronome;grass_knot` en perfil Scarlet/Violet. Fixture propio acumulativo `tests/fixtures/parallel_items/w05_campaign_003.json` commit `f6f41b505173d303bf0f03062d4034fc63f182b4`, progreso `reports/W05/CAMP_003_PROGRESO.csv` commit `984a80a128f5c6847664325ae487956adb838f49`. Informe `CAMP_003_ITER_10.md` commit `55985e3de43d6f2c24650afb24248924fc6182de`. Informe consolidado `CAMP_003_FINAL.md` commit `05a361d8237c13f25c2b7c7b0271c050c9902ff3`.

**Control estático:** cotejados los 10 bloques del fixture y las 10 filas de progreso contra las diez asignaciones W05 de cola IA6 y `machine_rows[*]["scarlet-violet"]`. **60 IDs únicos, seis por bloque, cero discrepancias**. Tests Python/Godot W05 acumulativos mantenidos, sin modificar producción. La autorización V5 solo se usa si hay fallo comprobado; no implica inventar parches.

**CI bloques 01–09 VERIFICADA:** [#41563688381](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41563688381), SHA `ad5b3164f3ac116b79deef8538b8f36aca93c8e4`, `completed/success`. Logs `CAMP003_W05_PY PASS blocks=9 checks=522` y `CAMP003_W05_GODOT PASS blocks=9 checks=1951`. 54 MT con CI PASS en ese SHA.

**CI bloque 10:** [#41565822563](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41565822563), SHA `984a80a128f5c6847664325ae487956adb838f49`, `in_progress` en consulta previa. El run anterior de fixture #41565804120 quedó cancelado por nueva ejecución. Solo declarar 60/60 MT CI PASS si se comprueba `completed/success` y logs `CAMP003_W05_PY PASS blocks=10` / `CAMP003_W05_GODOT PASS blocks=10`. Informes posteriores no alteran los tests ni disparan CI.

**Regla de cierre:** `CAMPAÑA_003_FINALIZADA` como **entrega de diez bloques**, sin declarar certificada la CI final aún. **STOP de nuevos microbloques**. Si falla el run final, diagnóstico y reparación autónoma permitida en dominio W05 según V5, sin rebajar aserciones, sin tocar otras funciones de fichero compartido y con CI real tras parche. IA6 integra/revisa en lote. No modificar `main`, V28, PR118, ramas ajenas, catálogos, `data/`, `config/`, saves ni 19 máquinas legacy; UI/arte/GPU fuera de alcance.

---

# ACTUALIZACIÓN PREVALENTE W05 — AUTONOMOUS_REPAIR_V5 (2026-11-03)

**Estado oficial:** leído `docs/coordination/items_parallel_v1/AUTONOMOUS_REPAIR_V5.md` de la rama IA6 `codex/calvo-items-20261101-arbitro`, blob `ebe71ace6949cc9311eb9831068799081bca8ba7`. **Prevalece sobre la prohibición antigua de tocar cualquier producción:** W05 puede diagnosticar y reparar autónomamente fallos de su familia de MT/libros **solo en su rama**, limitando los cambios a `modules/inventory/field_machine_book_profile.gd` y **solo la función `teach`** de `modules/inventory/field_item_service.gd`, si hay evidencia de fallo real, con diff mínimo, regresión que falle antes/pase después, casos positivos y negativos intactos, y CI de SHA que incluya tests y producción. No modificar otras funciones de ese archivo compartido, APIs ajenas, `main`, V28, ramas de otras trabajadoras, catálogos, políticas o 19 máquinas legacy; no inventar compatibilidad ni reglas de juego.

**Fallos locales:** diagnosticar error exacto de Godot/Python/API, corregir dentro de propiedad W05 sin permiso rutinario IA6, comprobar todas las regresiones y ejecutar GitHub Actions. Si hay conflicto concurrente en la misma función, cambio general de arquitectura/contrato, regla ambigua, migración de saves o permisos realmente denegados que no puedan repararse lícitamente, STOP solo para esa operación y elevar hallazgo concreto a IA6. No saltar seguridad ni hacer force push. La CI `queued/in_progress` permite avanzar un solo bloque independiente; `failure` obliga a diagnosticar y reparar antes de trabajo dependiente.

**CI bloque 09 VERIFICADA EN LOGS:** [#41563035302](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41563035302), SHA `d17bffb0134d80b03f762c8c5f650e4e07f5e34f`, `completed/success`, Python `CAMP003_W05_PY PASS blocks=9 checks=522`; Godot 4.7 `CAMP003_W05_GODOT PASS blocks=9 checks=1951`. Además IA6 editó **exclusivamente el workflow de W05**, commit `ad5b3164f3ac116b79deef8538b8f36aca93c8e4`, para activar CI ante modificaciones del módulo W05; run [#41563688381](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41563688381) `completed/success`, confirma otra vez Python 522, Godot 1951. **Ninguna reparación de producción ha sido necesaria ni realizada por W05 todavía.** Esta modificación de workflow la publicó IA6, no W05.

**Progreso actualmente:** CAMP003 **09/10 publicados y CI PASS**, 54 MT con comprobaciones funcionales acumuladas. **SIGUIENTE `p` ejecuta únicamente el bloque 10/10:** `tm75;tm76;tm78;tm79;tm80;tm81`, según la cola IA6. No ejecutar bloque 10 por este mensaje de actualización de protocolo, pues no contiene la tecla `p`. Tras entrega del 10 y revisión de CI final, `CAMPAÑA_003_FINALIZADA` y STOP; no crear bloque 11.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_003 · 09/10 PUBLICADOS (2026-11-03)

**Identidad:** IA5/W05, familia de MT/libros. **ÚNICA rama:** `codex/calvo-items-20261103-w05-camp003`. Encargo/cola IA6: `CAMPAIGN_GATE_003.md`, `CAMPAIGN_003_QUEUE_APPROVED.csv`, `campaigns/CAMP_003_W05.md` en rama `codex/calvo-items-20261101-arbitro`. Esta cabecera prevalece sobre los históricos inferiores.

**BLOQUE 09 ENTREGADO:** `tm69;tm70;tm71;tm72;tm73;tm74` mapeadas en Scarlet/Violet a `ice_punch;sleep_talk;seed_bomb;electro_ball;drain_punch;reflect`. Fixture acumulativo de **9 bloques / 54 MT distintas**, commit `cdcd2ed0ce02913c0508e5da297a4d54b37dddf2`, y fila `09` del progreso `reports/W05/CAMP_003_PROGRESO.csv`, commit `d17bffb0134d80b03f762c8c5f650e4e07f5e34f`. Informe `CAMP_003_ITER_09.md`, commit `b7670550c6765b6e93d5aed1d41f2a7de08f7134`. Scripts Python/Godot propios sin cambios; continúan leyendo fixture/progreso acumulativamente. **Cotejo estático verificado:** 54 IDs no repetidos, nueve filas y mapeos idénticos a cola IA6 y fuente SV. No equivale a PASS funcional de seis nuevas enseñanzas.

**CI BLOQUES 01–08 VERIFICADA:** [#41560433553](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41560433553), SHA `aeaa0ec2a4add2ab134ceb4b8d06c12afca6e40c`, `completed/success`, logs Python `CAMP003_W05_PY PASS blocks=8 checks=464`, Godot 4.7 `CAMP003_W05_GODOT PASS blocks=8 checks=1736`. Se conservaron estados históricos `EN_CI_AUTOMATICA` de los primeros ocho bloques en el CSV para evitar nuevos runs redundantes; el veredicto real queda aquí.

**CI BLOQUE 09 AÚN SIN PASS:** [#41563035302](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41563035302), SHA de progreso `d17bffb0134d80b03f762c8c5f650e4e07f5e34f`, inicialmente `pending`; el run intermedio de fixture #41563021095 puede cancelarse por concurrencia. Para certificar exigir `completed/success` y ambos recibos `PASS blocks=9`. El progreso, informe y HEAD posteriores no equivalen a CI exitosa.

**Próxima `p`:** consultar CI del SHA del progreso 09/10; si `success`, ejecutar solo el **último bloque 10** `tm75;tm76;tm78;tm79;tm80;tm81`. Si en curso, un único bloque independiente de tests sin PASS; si FAIL del arnés, corregir sin perder aserciones; si falla servicio, SaveV2, catálogo o lógica compartida STOP y comunicar IA6. Una vez publicado bloque 10, anunciar `CAMPAÑA_003_FINALIZADA` **como entrega**, verificar CI final aparte y STOP. Nunca bloque 11 ni nueva campaña.

**Protección:** `main`, V28, PR118, árbitra, W01–W04, producción, `modules/`, `data/`, `config/`, CI/manifest compartidos, partidas reales, 19 MT legacy y arte/GPU/UI intactos.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_003 · 08/10 PUBLICADOS (2026-11-03)

**Identidad:** IA5/W05, MT/libros. **Única rama autorizada:** `codex/calvo-items-20261103-w05-camp003`. Reglas: `CAMPAIGN_GATE_003.md`, `CAMPAIGN_003_QUEUE_APPROVED.csv`, `campaigns/CAMP_003_W05.md` en rama árbitra. Cada `p` = solo primer bloque pendiente de cola (máximo 10, después STOP). Esta cabecera prevalece sobre las históricas inferiores.

**BLOQUE 08 ENTREGADO:** `tm63;tm64;tm65;tm66;tm67;tm68`, mapeo real SV `psychic_fangs;bulk_up;air_slash;body_slam;fire_punch;thunder_punch`. Fixture acumulativo `tests/fixtures/parallel_items/w05_campaign_003.json` ampliado a **8 bloques/48 MT**, commit `75082f500b06d27c80de3b117c2ce8a25d67ec56`. CSV `reports/W05/CAMP_003_PROGRESO.csv` con una sola fila nueva `08`, commit `aeaa0ec2a4add2ab134ceb4b8d06c12afca6e40c`. Informe `CAMP_003_ITER_08.md`, commit `cab17daf4bfe7155e452192d4e084f7cd8ede16d`. Scripts Python/Godot acumulativos **sin cambios**, no reprogramar `FieldItemService.teach`. **Validación estática comprobada:** 48 IDs únicos y correspondencia exacta con cola IA6, orden de filas y perfil SV. Esto NO implica CI funcional del bloque 08.

**CI BLOQUES 01–07 CONFIRMADA:** GitHub Actions [#41560159198](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41560159198), SHA `fc41a3e6cd53ee85cfccd08ca6da3a3fac2521e0`, `completed/success`; Python `CAMP003_W05_PY PASS blocks=7 checks=406`, Godot 4.7 `CAMP003_W05_GODOT PASS blocks=7 checks=1521`, ambos leídos en los registros. 42 MT cubiertas en ese SHA. Los estados históricos `EN_CI_AUTOMATICA` del CSV se preservan para no disparar CI innecesaria; el resultado real está verificado aquí.

**CI BLOQUE 08 PENDIENTE:** [#41560433553](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41560433553), SHA de progreso `aeaa0ec2a4add2ab134ceb4b8d06c12afca6e40c`, inicialmente `pending`. La ejecución anterior #41560420588 puede quedar `cancelled` por `concurrency.cancel-in-progress`. Exigir ambos recibos Python/Godot `PASS blocks=8` en último SHA para certificar 48 MT. Informes no activan CI.

**SIGUIENTE `p`:** revisar último run del SHA de progreso. Con `success`, ejecutar solamente **bloque 09** (`tm69;tm70;tm71;tm72;tm73;tm74`) y anexar exactamente seis casos y una fila nuevos. Si el run continúa, solo bloque independiente de tests sin PASS; si falla arnés W05, corregir sin reducir aserciones; fallo de servicio, catálogo, SaveV2 o contrato compartido implica STOP y notificación a IA6. Límite 10/10, `CAMPAÑA_003_FINALIZADA` y STOP.

**PROTECCIÓN:** `main`, V28, PR118, rama árbitra, otras W, producción, `modules/`, `data/`, `config/`, workflows, guardados reales, 19 legacy y arte/GPU/UI intactos.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_003 · 07/10 PUBLICADOS (2026-11-03)

**Identidad:** IA5/W05, MT/libros. **Rama exclusiva:** `codex/calvo-items-20261103-w05-camp003`. Única autoridad para los diez bloques: gate y `CAMPAIGN_003_QUEUE_APPROVED.csv` / `campaigns/CAMP_003_W05.md` de IA6. Esta sección prevalece sobre los historiales inferiores.

**BLOQUE 07 ENTREGADO:** `tm57;tm58;tm59;tm60;tm61;tm62` → `false_swipe;brick_break;zen_headbutt;u_turn;shadow_claw;foul_play`, mapeos reales en perfil Scarlet/Violet. Fixture ampliado a 7 bloques/42 MT, commit `05bb0662f3a4089146d1968bf651e3280f9dac11`. Una única nueva fila de progreso `07`, commit `fc41a3e6cd53ee85cfccd08ca6da3a3fac2521e0`. Informe `CAMP_003_ITER_07.md`, commit `a3d615d99f322132789d30933384852322df7ff9`. Scripts Python/Godot propios no reescritos, acumulan las 42 muestras. **Consistencia documental** verificada: 42 IDs distintos, siete filas y correspondencia idéntica a la cola y los movimientos del perfil; no implica enseñanza ejecutada del bloque 07.

**CI BLOQUES 01–06 VERIFICADA:** GitHub Actions [#41559866278](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41559866278) sobre `920a647db1bfa5f5ad9f34c13bab5d6b2fa48143`, `completed/success`; logs `CAMP003_W05_PY PASS blocks=6 checks=348` y `CAMP003_W05_GODOT PASS blocks=6 checks=1306` (Godot 4.7). 36 MT verificadas funcionalmente en ese commit.

**CI BLOQUE 07 PENDIENTE HASTA RESULTADO DEL SHA DE PROGRESO:** `fc41a3e6cd53ee85cfccd08ca6da3a3fac2521e0`, workflow `.github/workflows/parallel-camp003-worker-autoci.yml`. Exigir `completed/success` y ambos recibos `PASS blocks=7`; no atribuir PASS de 42 MT antes. Run del commit de fixture puede ser `cancelled` por `concurrency.cancel-in-progress`.

**Próxima `p`:** verificar run del SHA de progreso del bloque 07; con success ejecutar solamente el **bloque 08** `tm63;tm64;tm65;tm66;tm67;tm68` (una nueva fila CSV, seis entradas fixture, informe y continuidad propios). Si CI sigue en curso, solo bloque independiente de tests sin PASS; si falla test propio, corregir sin reducir aserciones; defectos reales en servicio, SaveV2, fuente canónica o dependencia compartida → STOP y elevar IA6. Al llegar a diez bloques declarar `CAMPAÑA_003_FINALIZADA` y STOP.

**Protección:** `main`, V28, PR118, árbitra, ramas otras W, producción, `modules/`, `data/`, `config/`, CI/manifest compartidos, partidas reales, 19 legacy y UI/GPU intocados.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_003 · 06/10 PUBLICADOS (2026-11-03)

**Identidad:** IA5/W05, MT/libros. **ÚNICA rama de escritura:** `codex/calvo-items-20261103-w05-camp003`. Gate/cola autorizados por IA6 en `codex/calvo-items-20261101-arbitro`, `CAMPAIGN_GATE_003.md`, `CAMPAIGN_003_QUEUE_APPROVED.csv`, `campaigns/CAMP_003_W05.md`. Historial más abajo es obsoleto para la siguiente autorización.

**BLOQUE 06 entregado (sin PASS CI aún):** `tm51;tm52;tm53;tm54;tm55;tm56` con mapeo SV `sandstorm;snowscape;smart_strike;psyshock;dig;bullet_seed`. Se añadió al fixture propio `tests/fixtures/parallel_items/w05_campaign_003.json` commit `856c08cce2ac3b6b6ff6894d20c7debf2cb8a583` y al progreso `reports/W05/CAMP_003_PROGRESO.csv` commit `920a647db1bfa5f5ad9f34c13bab5d6b2fa48143`. Informe `CAMP_003_ITER_06.md` commit `104b52ef08f6ceaa915e78c4b8a6d41ba6f2cd0e`. Las suites Python/Godot siguen **acumulativas, sin ediciones de script**, para 6 bloques y 36 MT. Consistencia documental exacta entre fixture, progreso, cola y perfil SV: **verificada, 36 IDs únicos**.

**CI BLOQUES 01–05 VERIFICADA:** GitHub Actions [#41559168692](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41559168692) `completed/success`, SHA `7692702bb5969de282a28604a93c44d01a8b092a`. Logs leídos: Python `CAMP003_W05_PY PASS blocks=5 checks=290`, Godot 4.7 `CAMP003_W05_GODOT PASS blocks=5 checks=1091`. Los campos históricos de estado `EN_CI_AUTOMATICA` del CSV de bloques 01–05 no se han reescrito para no disparar ejecuciones repetidas.

**CI BLOQUE 06:** último run del SHA `920a647db1bfa5f5ad9f34c13bab5d6b2fa48143` [#41559866278](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41559866278); observado inicialmente como `pending`. El run intermedio de fixture #41559852441 puede cancelarse por política de concurrencia. No declarar 36 MT PASS sin `completed/success` y los dos recibos `blocks=6` sobre último SHA de progreso.

**SIGUIENTE `p`:** verificar CI exacta 06/10, luego ejecutar **solo bloque 07** `tm57;tm58;tm59;tm60;tm61;tm62` de la cola autorizada. Si CI en curso, la puerta permite como máximo un bloque de tests independiente, sin PASS; si falla runner propio, corregir sin quitar aserciones; si se detecta problema real de motor, SaveV2, catálogo, permisos o dependencia compartida → STOP y comunicar IA6. Nunca inventar nuevas MT ni avanzar más de un bloque por tecla. Límite diez bloques, después `CAMPAÑA_003_FINALIZADA` y STOP.

**Seguridad:** ninguna modificación en `main`, V28, PR118, árbitra, otras ramas, producción, `modules/`, `data/`, `config/`, workflows, guardados reales o catálogo canónico. Las 19 legacy siguen inactivas; visual/GPU no comprobada.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_003 · 05/10 PUBLICADOS (2026-11-03)

**Identidad:** W05/IA5, libros MT. **Rama EXCLUSIVA:** `codex/calvo-items-20261103-w05-camp003`. Cola y gate IA6 de CAMPAÑA_003, 10 bloques autorizados, seis IDs SV por bloque, uno por `p`. Los estados históricos inferiores no sustituyen esta cabecera.

**BLOQUE 05 ENTREGADO:** `tm45;tm46;tm47;tm48;tm49;tm50` = `venoshock;avalanche;endure;volt_switch;sunny_day;rain_dance` de versión Scarlet/Violet. Fixture acumulativo de 30 IDs, commit `4c305e29a1b418ccd531593071355220692c8f4b`; fila 05 del progreso, commit `7692702bb5969de282a28604a93c44d01a8b092a`. Informe `CAMP_003_ITER_05.md` en commit `ff3c12276c1e15cf6eb0744474545dea64ec46b5`. **Consistencia documental comprobada:** 5 bloques/30 IDs sin duplicados, mapeos SV iguales a cola IA6 y perfil. No se han reescrito scripts acumulativos ni código compartido.

**CI BLOQUES 01–04 VERIFICADA:** [#41558194753](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41558194753), SHA `d9c38c6cb606bbe3081eebc16d4560944370a48a`, `completed/success`; `CAMP003_W05_PY PASS blocks=4 checks=232` y `CAMP003_W05_GODOT PASS blocks=4 checks=876` leídos de logs.

**CI BLOQUE 05:** estado del progreso `EN_CI_AUTOMATICA` hasta confirmar nueva ejecución del SHA `7692702bb5969de282a28604a93c44d01a8b092a`. Exigir `CAMP003_W05_PY PASS blocks=5` y `CAMP003_W05_GODOT PASS blocks=5`, sin atribuir éxito al bootstrap ni a ejecuciones canceladas de fixture. El informe y esta cabecera no disparan otra CI.

**Siguiente `p`:** primero revisar el último workflow por rama sobre el SHA del progreso. Si success, ejecutar exclusivamente bloque **06** (`tm51;tm52;tm53;tm54;tm55;tm56`) añadiendo seis casos a fixture y una fila de progreso. Si en curso, se admite solo bloque independiente de pruebas sin PASS; un fallo real de arnés propio se repara con aserciones intactas; fallo de motor, guardados o catálogo compartido implica STOP y arbitraje IA6. Al 10/10 declarar `CAMPAÑA_003_FINALIZADA` y detenerse.

**Protección:** `main`, V28, PR118, árbitra, otras ramas, producción, `modules/`, `data/`, `config/`, CI inmutable, 19 legacy, guardados reales y arte/GPU/UI intocados.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_003 · 04/10 PUBLICADOS (2026-11-03)

**Identidad:** IA5/W05 · MT/libros. **Única rama de escritura:** `codex/calvo-items-20261103-w05-camp003`. Activación IA6 de diez microbloques según `CAMPAIGN_GATE_003.md`, `campaigns/CAMP_003_W05.md` y `CAMPAIGN_003_QUEUE_APPROVED.csv`. Historias previas inferiores no tienen autoridad para bloques siguientes.

**BLOQUE 04 publicado, estado EN_CI_AUTOMATICA:** `tm38;tm39;tm40;tm41;tm42;tm43` mapeados en SV a `flame_charge;low_sweep;air_cutter;stored_power;night_shade;fling`. Fixture acumulativo ampliado a **4 bloques/24 MT** en commit `e74d3d4cbdb38bd71624cbb31516b335c121b1ed`. Una sola fila nueva del progreso en commit `d9c38c6cb606bbe3081eebc16d4560944370a48a`. Informe `CAMP_003_ITER_04.md` publicado commit `e68362958e8f2a019f3cc437a92d91f930ed8d66`. Scripts Python/Godot de W05 permanecen intactos; su contrato es acumulativo y no se ha vuelto a implementar `FieldItemService.teach`.

**CI bloques 01–03 VERIFICADA:** [#41556713903](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41556713903) SUCCESS, SHA `c3c48e92ddf48708d7d941554e58420a994e55ed`, Python **174** checks, Godot 4.7 **661** checks, `blocks=3`, cero errores. Recibos leídos directamente de logs.

**CI bloque 04 pendiente al publicar:** [#41558194753](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41558194753), SHA `d9c38c6cb606bbe3081eebc16d4560944370a48a`, inicialmente `pending`. La CI intermedia [#41558142876](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41558142876) puede quedar `cancelled` por cancelación deliberada de runs anteriores. No declarar PASS de 24 MT sin verificar `completed/success` y logs Python/Godot `blocks=4`. El cotejo estático de **24 IDs únicos**, 4 filas y perfil SV sí fue coherente.

**Próxima `p`:** verificar último run SHA del progreso del bloque 04. Si success, ejecutar solo **bloque 05** de la cola (`tm45;tm46;tm47;tm48;tm49;tm50`). Si todavía corre, un único bloque siguiente independiente permitido, sin declararlo PASS; FAIL de arnés propio se corrige sin reducir aserciones, FAIL funcional compartido → STOP e intervención IA6. Al completar 10/10, `CAMPAÑA_003_FINALIZADA` y STOP.

**Intocables:** `main`, V28, árbitra, otras W, producción, `modules/`, `data/`, `config/`, catálogo canónico, PR118, workflow/validador de manifiesto, saves reales y 19 legacy. Arte/GPU/UI no verificados.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_003 · 03/10 PUBLICADOS (2026-11-03)

**Identidad:** IA5/W05, libros/MT. **Única rama de escritura:** `codex/calvo-items-20261103-w05-camp003`. Autorización de la cola IA6 `CAMPAIGN_003_QUEUE_APPROVED.csv`/encargo `campaigns/CAMP_003_W05.md`, no modificar otras ramas ni producción.

**BLOQUE 03 entregado:** `tm30;tm32;tm33;tm34;tm35;tm37` = `snarl;swift;magical_leaf;icy_wind;mud_shot;draining_kiss` según versión Scarlet/Violet del perfil original. Se añadió el bloque 03 al fixture propio `tests/fixtures/parallel_items/w05_campaign_003.json` commit `f4668498b84ca92dc114ed4cac7edff4b001e109`, y una única tercera fila a `reports/W05/CAMP_003_PROGRESO.csv` commit `c3c48e92ddf48708d7d941554e58420a994e55ed`. Informe `CAMP_003_ITER_03.md`, commit `f9c2e665365d3bf41a5ee99f7ff0ab4b966fa15d`. No se tocaron runners previos: acumulan exactamente 18 casos para 03/10.

**CI bloques 01 y 02 VERIFICADA:** GitHub Actions [#41555043090](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555043090) `completed/success`, SHA `131b4420e2d4878972199bec9aa6fb4ccf86ae4a`, Python `PASS blocks=2 checks=116`, Godot 4.7 `PASS blocks=2 checks=446`. Se leyó el registro real. Los dos primeros renglones del CSV conservan estado histórico `EN_CI_AUTOMATICA` para evitar otra CI redundante, **pero su resultado real es SUCCESS**.

**CI bloque 03:** [#41556713903](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41556713903) sobre `c3c48e92ddf48708d7d941554e58420a994e55ed`; **`pending` al primer vistazo**, no declarar PASS sin revisar la nueva conclusión y logs Python/Godot. El run anterior del fixture #41556696614 podrá ser `cancelled` por `concurrency.cancel-in-progress`. Contrato estricto: `blocks=3`, 18 casos, positiva y negativas completas, SaveV2, cero errores. Consistencia estática entre los 18 IDs de cola, fixture, progreso y perfil SV: **comprobada**, no equivale a resultados de enseñanza.

**Próxima `p`:** leer estado actual del último run del SHA del progreso; si `success`, ejecutar sólo **bloque 04**: `tm38;tm39;tm40;tm41;tm42;tm43`. Si aún en curso, se permite preparar un bloque independiente de pruebas sin PASS. Ante FAIL real, analizar logs: arreglar solo arnés W05 o STOP y reportar IA6 por dependencia de código compartido. No duplicar ID, borrar aserciones, modificar motor, versiones, políticas, catálogo, CI, arte, guardados reales, `main`, V28 o ramas ajenas. Campaña límite 10/10.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_003 · 02/10 PUBLICADOS (2026-11-03)

**Identidad:** IA5/W05, MT/libros. **Rama exclusiva:** `codex/calvo-items-20261103-w05-camp003`. Activación IA6 de diez microbloques en la cola `CAMPAIGN_003_QUEUE_APPROVED.csv` y `campaigns/CAMP_003_W05.md` (rama árbitra).

**BLOQUE 02 publicado, estado EN_CI_AUTOMATICA, sin PASS confirmado:** `tm24;tm25;tm26;tm27;tm28;tm29` mapeadas a `fire_spin;facade;poison_tail;aerial_ace;bulldoze;hex` en Scarlet/Violet. Se añadieron al fixture acumulativo (commit `f006f83ab42290609c65ab159652a68dc9017d64`) y al progreso (commit `131b4420e2d4878972199bec9aa6fb4ccf86ae4a`). **Bloque 01 conservado completo**; son 12 MT repartidas en dos bloques, todavía no doce enseñanzas certificadas por CI. Informe `CAMP_003_ITER_02.md`, commit `0f76b80eb15c7a77ae97efcfa7e0247495a3a970`.

**Control real ejecutado:** lectura y cotejo de los 12 IDs y movimientos en fixture, cola IA6, CSV de progreso y perfil SV: **coherentes**. No equivale a ejecución de Godot ni a verificación de learnsets. Se intentó obtener el veredicto de la CI anterior, pero no se recibió resultado fiable de Actions; por ello se avanzó solo **un bloque independiente de tests** y NO se marcó `CI_PASS_VERIFICADO`. El workflow `.github/workflows/parallel-camp003-worker-autoci.yml` se dispara por los pushes de fixture/progreso; no se ha tocado.

**Siguiente `p`:** consultar el último run real de CI para el último SHA de pruebas/progreso de **02/10**. Con `success`, ejecutar solo **bloque 03** (`tm30;tm32;tm33;tm34;tm35;tm37`) y anexar al fixture y CSV sin borrar previos. Con `queued/in_progress`, aplicar el gate V4 de independencia y no inferir PASS. Con `failure` de contrato compartido, motor o SaveV2, STOP y elevar a IA6; reparar solo test propio si error aislado. No acumular indefinidamente trabajo si sigue inaccesible el estado de CI.

**Protección:** `main`, V28, PR118, árbitra, otras W, `modules/`, `data/`, `config/`, catálogo canónico, scripts de workflow y partida real intactos. 19 legacy siguen inactivas. GPU/arte/UI excluidos.

---

# ESTADO VIGENTE IA5/W05 — CAMPAÑA_003 · 01/10 PUBLICADO (2026-11-03)

**Identidad:** W05, MT/libros. **ÚNICA rama de escritura:** `codex/calvo-items-20261103-w05-camp003`. Activación IA6 en `CAMPAIGN_GATE_003.md`, `CAMPAIGN_003_BRANCH_MANIFEST.md` y `campaigns/CAMP_003_W05.md`. Diez bloques, seis MT cada uno; completar uno por `p` y STOP en 10/10. **El historial CAMP001/002 más abajo es obsoleto para permisos y rama.**

**BLOQUE 01 entregado, CI sin resultado comprobado:** `tm07;tm16;tm18;tm21;tm22;tm23`. Fixture `tests/fixtures/parallel_items/w05_campaign_003.json`, Python `tests/tools/test_parallel_items_w05_campaign_003.py`, Godot `tests/gameplay/parallel_items_w05_campaign_003.gd`, informe `CAMP_003_ITER_01.md`, progreso `CAMP_003_PROGRESO.csv`. Commit Python final `c622e29bd06c5a40c189ff780a4effc8755d0275`, Godot final `a43b182e532d9bc123d64acc9a89bdc602bad08d`, trigger del progreso `a2047a58a02760380b3a55f4620417051984dea7`. **No afirmar CI PASS** hasta comprobar resultado del SHA exacto. No se pudieron verificar especies/PP manualmente en JSON normalizado por límite del conector: la CI Python y el runner verifican learnsets, metadatos, consumo y SaveV2 reales.

**Siguiente `p`:** primero consultar resultado CI de `codex/calvo-items-20261103-w05-camp003`. Si success, ejecutar **bloque 02** reservado `tm24;tm25;tm26;tm27;tm28;tm29`, anexando al fixture, conservando y probando bloque01 en scripts acumulativos. Si CI queued/in_progress, puede preparar solo bloque independiente sin PASS. Si fallo funcional o dependencia compartida, STOP y comunicar a IA6. Nunca adelantar más de un bloque por mensaje ni editar scripts de otras W o motor.

**CI inmutable:** `.github/workflows/parallel-camp003-worker-autoci.yml`, validador de manifiesto compartido inmutable. Pruebas con recibo estricto `CAMP003_W05_PY/GODOT PASS blocks=N checks=M` y N igual a progreso. No tocar `main`, V28, PR118, otras ramas, producción, datos, config, catálogo, saves reales ni activar las 19 legacy. Arte/UI/GPU no validados.

---

# IA5 / W05 — CUADERNO DE CONTINUIDAD · MACHINE

## 1. Identidad, alcance y autoridad

- **Identidad:** IA5 / W05; familia MACHINE (máquinas/libros de movimientos).
- **Rama de trabajo exclusiva:** `codex/calvo-items-20261101-w05`.
- **Última orden oficial leída:** [`assignments/LOTE_002_W05.md`](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-arbitro/docs/coordination/items_parallel_v1/assignments/LOTE_002_W05.md), blob **`b8f8df20cc70ab9ca7004c7b692a59537fc3efd7`**.
- **Estado:** `LISTA_PARA_REVISION` de LOTE_002 (todavía NO integrado ni certificado en Godot). No hay LOTE_003 asignado.
- **Base inicial propia:** `d6d6d5f9285d71b97db3ac18c6bbb70274ab19af`. **Checkpoint autorizado IA6:** `38188cc208e67b19002437ac75160898ce332ec2`. **Fusión segura en W05:** `239edd8083a0980e556dfe04079e03f04b09e89e` (dos padres; sin `--force`, LOTE_001 intacto).
- **Último commit de informe previo a este cuaderno:** `9435b86350c11edd35b190e10acdae1edca8cf41`. Para recuperar el HEAD final leer la rama W05 en GitHub; el propio documento no puede contener su SHA futuro de forma autorreferencial.
- **Pruebas funcionales ejecutadas sobre la base combinada:** **NINGUNA**. Estado de verificación completo: `PENDIENTE_CI`.
- **Rutas permitidas para este lote:** solo `tools/item_audit/parallel_w05_machine_scope.py`, `tests/tools/test_parallel_w05_machine_scope.py`, `tests/fixtures/parallel_items/w05_machine_scope_v1.json` y `reports/W05/{LOTE_002.md,CONTINUIDAD.md}`. Prohibido producción.

## 2. Mapa de implementación existente (NO rehacer)

**Fuentes:** `docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv` (248 seleccionadas), `docs/current/ITEM_FIELD_V8.csv.txt`, `docs/current/ITEM_INVENTORY.csv`, `modules/inventory/item_connections_v1.json` (338 IDs con mapas por versión, solo SV activo), `tests/fixtures/item_connections_v1/primary/sources.json` (fuente PokéAPI fijada).

**Adaptador:** `tools/item_audit/prepare_connections_v1.py` regenera relaciones canónicas `ID→versión→move_id` y fixtures de máquinas activas, sin tocar datos fuente. La ruta nativa ya se implementó antes de W05: `modules/inventory/field_item_service.gd:machine_move(),teach(),use_item()` selecciona versión, valida movimientos, especie, propiedad, estado de mochila y ranura; prepara criatura/bolsa y consume una unidad al éxito, no al rechazo.

**UI/guardado:** `scenes/visual/field_item_bag.gd` presenta una acción de enseñar y previsualiza el movimiento correcto; `tests/gameplay/item_connections_test_runner.gd` incluye una ruta `tm01` de mochila, guardado/carga e integración, **no 229 pruebas por ID en PC/guardado ni libros visuales**. Existe `scenes/visual/item_art_catalog.gd` y manifest de arte; de las 248 solo `tm01` tenía entrada gráfica registrada en LOTE_001.

**Propiedad de archivos:** `field_item_service.gd`, `field_item_bag.gd`, `item_connections_v1.json`, `assets/local_item_catalog/manifest.json`, políticas, tests anteriores y configuración de CI son compartidos/reservados. IA6 debe serializar cualquier edición de producción futura. En LOTE_002 se dejaron intactos.

## 3. Estado comprobable por subfamilia

| Subfamilia | Cantidad seleccionada | Fuente de prueba/estado | Límite actual |
| --- | ---: | --- | --- |
| MT `tm01`–`tm229` | 229 | `ITEM_FIELD_V8.csv.txt` + `ITEM_CONNECTIONS_V1.json` y `item_connections_test_runner.gd:172–197`, **PASS histórico V27 (2026-10-28)** | Una especie/MT en evidencia anterior; no PASS funcional del checkpoint combinado |
| MT antigua `tm00` | 1 | Perfil mapeado en `sword-shield`, no `scarlet-violet` | `DEPENDENCIA`: norma de versión/aprendizaje y consumo |
| MO `hm01/hm04/hm05/hm06/hm08` | 5 | Mapa histórico existente; `hm05` enseña `waterfall` en ORAS y solapa `tm77` SV | No habilitar efecto de campo ni enseñar sin política. `hm08` usa fuente `ruby-sapphire` |
| DT `tr13/tr19/tr28/tr31/tr39/tr41/tr44/tr50/tr72/tr83/tr85/tr91/tr93` | 13 | Mapa `sword-shield`; metadatos nativos de DT existentes | No son jugables en el perfil SV; entrada nativa ≠ ruta de uso |
| 90 máquinas canónicas fuera de selección | 90 | Total 338 mapeadas − 248 seleccionadas | No asignadas: no activarlas por accidente |
| Presentación gráfica tipo libro | 0 certificadas | Solo propuesta; sin escena/art nuevo | Consulta a IA6/diseño, no implementación actual |

**Interpretación obligatoria:** 248 seleccionadas **no** son 248 mecánicas certificadas. 229 pruebas históricas de enseñanza acotadas; 19 requieren perfil/reglas. La ausencia de 247 entradas en manifest no prueba ausencia de imagen fallback.

## 4. Historial de trabajos y pruebas

| Lote | Cambios reales | Prueba y alcance | Informe / estado |
| --- | --- | --- | --- |
| LOTE_001 | Auditoría de 248 IDs, CSV con mapeo/risks y reservas | Cruce **estático**; sin Godot nuevo | [LOTE_001](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w05/docs/coordination/items_parallel_v1/reports/W05/LOTE_001.md), commit `d9fffd2da1c9e4f2c120557503503292a34844f6`; **ACEPTADO por IA6 como documental** |
| LOTE_002 | Fusión checkpoint y creación de validador Python de solo lectura + suite de negativos + fixture versionado | Python 3.13.5 local **13 PASS + 1 SKIP** (12 controles unitarios más CLI y test real pendiente); cruce independiente de **datos GitHub reales** PASS estático 248/229/19 y solape | [LOTE_002](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w05/docs/coordination/items_parallel_v1/reports/W05/LOTE_002.md); **LISTA_PARA_REVISION**, pendiente IA6 |

**Rutas de LOTE_002:**
- [`tools/item_audit/parallel_w05_machine_scope.py`](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w05/tools/item_audit/parallel_w05_machine_scope.py) · blob `e1d6015a125f7fe4b5d1d0f9e34b94079f68858f`.
- [`tests/tools/test_parallel_w05_machine_scope.py`](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w05/tests/tools/test_parallel_w05_machine_scope.py) · blob `e150dd766c976f1fccf7d9fa2d08f633acc95ed4`.
- [Contrato JSON de regresión](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w05/tests/fixtures/parallel_items/w05_machine_scope_v1.json) · blob `0dbd1f4d299569b63a7b0f0341bf2112e51c9319`.

**Comandos reproducibles, desde raíz del checkout completo:**
```sh
python tools/item_audit/parallel_w05_machine_scope.py
python -m unittest discover -s tests/tools -p 'test_parallel_w05_machine_scope.py' -v
```

**Ejecución exacta hasta ahora:** el módulo Python y su suite se ejecutaron en contenedor aislado con tests sintéticos; 14 casos, 13 PASS, 1 SKIP (`test_ruta_real_248_si_disponible`, por no estar montado el repo). El chequeo estático **independiente** en sesión leyó blobs reales de GitHub `8b9b723...` y `0525b370...`, confirmó 248/229/19, detectó 5 mutaciones negativas; **no sustituye ejecutar el Python publicado con los 248 del checkout**. Godot 4.7 y GPU **SIN_EJECUTAR**. No se lanzó ningún workflow nuevo, por economía de CI.

## 5. Interfaz futura de libros — PROPUESTA, NO AUTORIZACIÓN

Implementar solo tras decisión IA6 y encargo nuevo, como **capa de presentación** sobre máquina existente, nunca una función de enseñanza por libro:

1. Entrada: `item_id` canónico existente en mochila; leer `machine_rows[item_id][perfil_aprobado]`, `move_id` y tipo del movimiento desde `DefinitionCatalog`; si el perfil no lo autoriza, UI indica «No disponible» y no ofrece usarlo.
2. Modelo de vista sugerido `LibroMovimientoVista` (estructura de datos, **no clase escrita**): `item_id`, `move_id`, `tipo`, `estilo_base_libro`, `paleta_tipo`, `texto_localizado`, `habilitado`, `motivo_bloqueo`. Variantes visuales reutilizables: seis bases de libro y colores por tipo si se confirma el diseño; sin 248 texturas/escenas exclusivas como requisito.
3. Acción: botón de la mochila llama al servicio actual `teach()`, no realiza reglas/consumo en el widget. Persistir únicamente ID y estado de criatura ya existentes, sin schema de guardado nuevo.
4. Validación futura: vista para ID normal/inactivo, color y tipo correctos, rendimiento de 248 entradas, acceso a PC, cancelación/rechazo sin gasto, persistencia y visual/GPU. La regla de MO de campo se diseña separadamente, nunca inferida del libro.
5. Duplicidad `hm05`/`tm77`: IA6 decide contenido; el verificador la mantiene visible y no elimina ningún ID automáticamente. `scarlet_book` y `violet_book` son objetos de historia, no sustitutos de MT.

## 6. Bloqueos, riesgos, siguiente turno

- **BLOQUEO DE VERIFICACIÓN:** el checkpoint V27+V28 está combinado sin CI. Para validar el Python publicado con los 248, hace falta checkout completo en ejecutor; GitHub Actions consolidada de IA6 o entorno Windows del usuario. No afirmar PASS de Godot a partir de test Python.
- **BLOQUEO DE POLÍTICA:** activar 19 legadas exige perfil, compatibilidad learnset, consumo, posibles duplicados y decisión sobre MO/campo. Ningún movimiento antiguo se asigna por similitud de número.
- **Riesgo de colisión:** servicio de inventario, vistas, tests compartidos, arte y políticas; las otras W trabajan familias vecinas. No escribir allí sin contrato de propiedad.
- **Riesgo de snapshot:** si cambian catálogo o versión, el contrato espera 248/229/19 y solape revisado; un FAIL puede indicar evolución legítima, **no** arreglarlo cambiando cifras a ciegas.
- **No tocar:** `main`, `codex/items-v28-from-main`, la árbitra, ramas ajenas, guardados, `config/`, `data/`, `assets/`, `.github/`, reglas Mega y decisiones de selección; no crear 248 scripts ni regenerar bibliotecas.

### Retomar en la siguiente conversación

1. Leer `STATUS.md` y **nuevo encargo oficial** en la rama árbitra; verificar SHA y permisos. Si no hay LOTE_003 asignado, **no trabajar**.
2. Leer este cuaderno y el [último informe](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/blob/codex/calvo-items-20261101-w05/docs/coordination/items_parallel_v1/reports/W05/LOTE_002.md), no volver a procesar todo el historial.
3. Confirmar HEAD W05 e identidad de checkpoint `38188cc...`; verificar que IA6 acepte el reporte/runner y confirme si realizó CI consolidada.
4. Ejecutar ambos comandos Python en checkout con datos reales; documentar resultado y logs por commit. Mantener separada evidencia de lógica Python, evidencia de Godot y prueba visual.
5. Solo bajo nueva autorización, preparar contrato funcional/aprendizaje de 19 legacy y diseño de libro por tipo, con propiedad exclusiva de archivos.

**Último paso reproducible:** ejecutar primero `python tools/item_audit/parallel_w05_machine_scope.py` y luego `python -m unittest discover -s tests/tools -p 'test_parallel_w05_machine_scope.py' -v` sobre el checkout completo de W05; entregar resultados a IA6 para integración. **PENDIENTE_CI; LISTA_PARA_REVISION.**
