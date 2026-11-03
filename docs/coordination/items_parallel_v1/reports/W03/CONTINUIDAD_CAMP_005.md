## CI FINAL comprobada — CAMPAÑA_005_FINALIZADA

Ejecución [GitHub Actions #41742709006](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41742709006) sobre SHA funcional `5fe580ece1498eccdd4dce51fda630fa2b021416`: **completed/success**. Recibos literales: `CAMP005_W03_MANIFEST_PASS reserved=10 completed=10 ids=28 kind=FUNCTIONAL_BACKLOG`; `CAMP005_W03_PY PASS blocks=10 checks=169`; `CAMP005_GATE_PY_PASS`; `CAMP005_W03_GODOT PASS blocks=10 checks=208`; `CAMP005_GATE_GODOT_PASS`. Regresiones del hito final: `CAMP004_W03_PY PASS blocks=10 checks=187`, `CAMP004_W03_GODOT PASS blocks=10 checks=1344`, `CAMP003_W03_PY PASS blocks=10 checks=279`, `CAMP003_W03_GODOT PASS blocks=10 checks=986`.

**CI completa significa pruebas y contratos aprobados, no que los 28 objetos de backlog sean plenamente jugables**. Únicamente el bloque10 revalida Friend/Heal/Quick/Timer funcionales. No hay alta de objetos nuevos, modificación de producción ni certificación SaveV2 integral. STOP tras 10/10, pendiente de nueva campaña explícita de IA6.

---

# IA3/W03 — Continuidad final CAMPAÑA_005 — 10/10 preparado para CI

**Rama única:** `codex/calvo-items-20261103-w03-camp005`. **Bloque10:** `friend_ball;heal_ball;quick_ball;timer_ball` revalida funcionalidad de captura existente, no nuevos objetos. Friend establece amistad 200 solo al capturar; Heal restaura PS/estado/PP; Quick usa turno0×5 y Timer escalado hasta×4. Los tests propios Godot verifican captura real mediante inventario, consumo unitario, identidad, roundtrip de CreatureInstance, rechazo sin gasto ni RNG por contexto de turno inválido. Python contrasta los puntos de producción. `CreatureInstance.to_dict/from_dict` no equivale a SaveV2 integral. Reporte: `CAMP_005_ITER_10.md`.

**Gate final:** verificar `CAMP005_W03_PY PASS blocks=10` y `CAMP005_W03_GODOT PASS blocks=10`, gates IA6, **regresiones CAMP004 y CAMP003 completas**. CI09 previa [#41738147298](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41738147298), Python 153/Godot 179 PASS. Si el gate final falla, reparar únicamente arnés propio. Al obtener SUCCESS sobre el último SHA, comunicar `CAMPAÑA_005_FINALIZADA` y STOP. No aceptar otro `p` como nuevo bloque sin activación de IA6. No cambiar main, V28, PR118 ni ramas ajenas.

---

## Verificación final de CI del bloque 09

[GitHub Actions #41738147298](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41738147298), SHA `0c66c18a1e97533ed6422c7aded283593648f5aa`, terminó **completed/success**. Recibos: `CAMP005_W03_PY PASS blocks=9 checks=153`, `CAMP005_GATE_PY_PASS`, `CAMP005_W03_GODOT PASS blocks=9 checks=179`, `CAMP005_GATE_GODOT_PASS`. La validación confirma la huida salvaje de Cola Esponjosa existente y el rechazo seguro de campo, pero no implementa el retorno al mapa de Cuerda Huida.

---

# IA3/W03 — Continuidad CAMPAÑA_005 — bloque 09/10

**Rama única:** `codex/calvo-items-20261103-w03-camp005`. Bloque 09 `escape_rope;fluffy_tail` auditado y pruebas nuevas publicadas, sin contabilizar objetos nuevos. **Cola Esponjosa:** existe ruta real de huida salvaje garantizada con consumo unitario posterior a commit y sin RNG, por `battle_escape_profile.json` y `ShowdownAdventureSession._use_escape_item`. **Cuerda Huida:** carece de destino de mundo/mapa y transacción de traslado. Ambos rechazan uso en `FieldItemService` sin gasto. Estados `DEPENDENCIA_MUNDO_RETORNO` y `BATTLE_ESCAPE_EXISTING_FIELD_REJECTED`, respectivamente.

**CI del bloque 09:** comprobar `CAMP005_W03_PY PASS blocks=9`, `CAMP005_W03_GODOT PASS blocks=9` y gates IA6 sobre SHA con nueve filas de progreso. CI anterior bloque08 aprobada [#41733987301](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41733987301), Python139/Godot169. Si falla, corregir únicamente prueba propia, no producción.

**Siguiente `p`: bloque 10** `friend_ball;heal_ball;quick_ball;timer_ball`, hito final con regresiones obligatorias. No iniciar hasta comprobar CI09. Prohibido tocar main, V28, producción o ramas ajenas.

---

## CI verificada — bloque 08

[GitHub Actions #41733987301](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41733987301), SHA `f5e80a92a38c16caf6c7e2cb543eb28ab235844f`, terminó **completed/success** con `CAMP005_W03_PY PASS blocks=8 checks=139`, `CAMP005_GATE_PY_PASS`, `CAMP005_W03_GODOT PASS blocks=8 checks=169`, `CAMP005_GATE_GODOT_PASS`. La primera ejecución [#41733755176](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41733755176) falló por leer el perfil `battle_support_profile.json` desde la raíz en lugar de `items`; corregido el auditor en el SHA validado. **Flauta Azul funcional en campo**: cura sueño, no se consume, limpia reloj y rechaza no-op. Roja y Amarilla mantienen dependencia de interfaz de estados volátiles de combate.

---

# IA3/W03 — Continuidad CAMP005 08/10

Rama exclusiva `codex/calvo-items-20261103-w03-camp005`. Bloque08 `red_flute;yellow_flute;blue_flute`: **Azul tiene ejecución real** de curación de sueño en campo vía `FieldItemService.use_item`, no se consume y borra `sleep_clocks`; pruebas positivas y rechazo no-op publicadas. **Roja y Amarilla** son efectos volátiles de batalla (atracción y confusión respectivamente), sin ejecutor de campo; depende de interfaz battle bag/Showdown para conectar objetivos activos. Informes, fixture, Godot y Python publicados, no producción. CI 07 previa PASS [#41727546334](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41727546334), Python 126, Godot 148. Verificar CI 08 Python/Godot blocks=8, gates IA6 antes de certificar.

Siguiente `p`: solo bloque09 `escape_rope;fluffy_tail` después de comprobar CI08. No tocar main, V28, otros trabajadores ni sistemas compartidos.

---

## CI validada — bloque 07

[GitHub Actions #41727546334](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41727546334), SHA `2a944b4c1a70de7ba19ea65106e17ece8271e5ba`, **completed/success**. Recibos `CAMP005_W03_PY PASS blocks=7 checks=126`, `CAMP005_GATE_PY_PASS`, `CAMP005_W03_GODOT PASS blocks=7 checks=148`, `CAMP005_GATE_GODOT_PASS`. Las pruebas acreditan la regla existente de frecuencia de encuentros y las dependencias del mundo; no implementan los cinco efectos de campo.

---

# IA3/W03 — Continuidad CAMP005 bloque 07/10

**Rama:** `codex/calvo-items-20261103-w03-camp005`. Bloque07 `black_flute;white_flute;lure;super_lure;max_lure`. Suites Python y Godot publicadas con positivos del helper de probabilidad Cleanse Tag/Pure Incense (6000 → 4000), tabla de encuentros y conservación de la original. Los cinco objetos siguen `DEPENDENCIA_COMPARTIDA`: no existe productor del mundo para pasos/duración, mínimos pasos entre encuentros, fórmula versionada ni persistencia; no se ha implementado uso de campo. IA6 debe resolver reglas y contrato de coordinación con Repel (bloque06).

**CI anterior 06 verificada:** [#41726410961](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41726410961) Python 109 y Godot 119 PASS. **CI 07:** comprobar recibos `CAMP005_W03_PY PASS blocks=7` y `CAMP005_W03_GODOT PASS blocks=7`, gates IA6 y SHA con 7 filas CSV. Si falla, reparar test propio antes de continuar.

**Siguiente `p`: exclusivamente bloque08 `red_flute;yellow_flute;blue_flute`.** No editar main, V28, producción compartida ni ramas ajenas.

---

# IA3/W03 — Continuidad CAMPAÑA_005 06/10 — validado

Rama exclusiva `codex/calvo-items-20261103-w03-camp005`. Bloque 06 `repel;super_repel;max_repel`, reintento terminado con CI [#41726410961](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41726410961) PASS: Python 109/Godot 119, gates IA6 PASS y manifiesto 6/10. Fixture, runner, auditor e informe publicados; último commit de progreso `0bb581dc`.

**Estado de juego:** los tres repelentes NO se han conectado a los pasos. `WildEncounterSystem` demuestra un caso real con probabilidad cero y RNG inalterado y un encuentro garantizado con nivel, pero eso no sustituye el filtro dinámico por nivel líder. Falta el productor mundo de pasos restantes, duración versionada, persistencia y filtro previo. Registrar `DEPENDENCIA_COMPARTIDA` para IA6. Sin cambios en producción, `main`, V28 o ramas ajenas.

**Siguiente `p`: bloque 07** `black_flute;white_flute;lure;super_lure;max_lure`, exclusivamente. No repetir bloque 06 ni abrir otras campañas.

---

## Recibos verificados — hito 05

[GitHub Actions #41721510769](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41721510769), SHA `3d6989141f2919a7b35b4e03281fc339a9fce98c`, terminó **completed/success**. Resultado acumulado: `CAMP005_W03_PY PASS blocks=5 checks=93`, `CAMP005_W03_GODOT PASS blocks=5 checks=103`, gates Python y Godot IA6 PASS. Regresiones del hito obligatorias: `CAMP004_W03_PY PASS blocks=10 checks=187`, `CAMP004_W03_GODOT PASS blocks=10 checks=1344`, `CAMP003_W03_PY PASS blocks=10 checks=279`, `CAMP003_W03_GODOT PASS blocks=10 checks=986`.

El éxito de CI comprueba ×1,5 actualmente operativo y la dependencia de contexto especial, **no** garantiza validación de zona Safari/Concurso Bicho. IA6 debe decidir si el uso se limita a esas zonas.

---

# W03 CAMP005 — Continuidad 05/10

Bloque 05: safari_ball y sport_ball. Existe factor ×1,5 implementado en CaptureBallEffects y usado por CaptureSystem. El contexto no identifica zona Safari ni Concurso Bicho; el factor se aplica sin comprobar zona. IA6 debe decidir si el uso será libre o restringido y asignar productor autoritativo. Estado PARTIAL_EXISTING_EFFECT_UNGATED. Pruebas Godot/Python positivas del factor existente. Hito 05 requiere regresiones CAMP004/CAMP003. CI 04 previa PASS #41720389165. Siguiente p ejecutará solo bloque 06 si CI 05 se valida.

---

## CI validada — bloque 04

La ejecución [GitHub Actions #41720389165](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41720389165) en SHA `890824fb682faacf916c6430a9c34cff3962ad6b` terminó **completed/success**. Recibos: `CAMP005_W03_PY PASS blocks=4 checks=78`, `CAMP005_GATE_PY_PASS`, `CAMP005_W03_GODOT PASS blocks=4 checks=80`, `CAMP005_GATE_GODOT_PASS`. Esta aprobación verifica los contratos presentes y las dependencias concretas; **no** acredita efecto funcional de Beast Ball ni Heavy Ball.

---

# IA3/W03 — CONTINUIDAD CAMPAÑA_005 04/10

**Rama exclusiva:** `codex/calvo-items-20261103-w03-camp005`. Bloque 04 `beast_ball;heavy_ball`: ambos `DEPENDENCIA_CONCRETA`. Beast precisa taxonomía ultraente canónica/versionada; Heavy precisa peso por forma y versión de fórmula que modifica tasa. Godot/Python ahora comprueban positivamente el roundtrip de metadatos de especie, tasa y probabilidad determinista, pero NO los efectos Beast/Heavy. Ninguna implementación de producción.

**CI previa 03 confirmada:** [#41719545522](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41719545522), Python 63/Godot 63 PASS, gates IA6 PASS. **CI 04:** verificar `CAMP005_W03_PY PASS blocks=4`, `CAMP005_W03_GODOT PASS blocks=4` y gates sobre SHA con 4 filas CSV; reparar error propio si lo hay.

**Siguiente `p`: bloque 05** exactamente `safari_ball;sport_ball`. En el bloque05 el workflow exige además regresiones CAMP004 y CAMP003. No anticipar. No tocar main/V28, PR #118, otras ramas ni APIs compartidas.

---

## Validación CI del bloque 03

[GitHub Actions #41719545522](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41719545522), SHA `8b12bbb254f01ec39fa0d24b4959c6c548ee4eef`, **completed/success**. Recibos: `CAMP005_W03_PY PASS blocks=3 checks=63`, `CAMP005_GATE_PY_PASS`, `CAMP005_W03_GODOT PASS blocks=3 checks=63`, `CAMP005_GATE_GODOT_PASS`. Certifica el contrato de evolución lunar positivo y las fronteras pendientes; **Love Ball y Moon Ball todavía no obtienen efectos funcionales de captura**.

---

# IA3/W03 — CONTINUIDAD CAMPAÑA_005 03/10

**Rama única:** `codex/calvo-items-20261103-w03-camp005`. **Bloque 03:** `love_ball;moon_ball`, ya auditados antes; ahora dependencia precisa: Love requiere sexo individual persistente (ausente) y semántica de especie base; Moon dispone de `EvolutionRecord.item_id` y ruta `EvolutionSystem` verificable, pero precisa selector de versión y norma de bonificación. Suite Godot prueba evoluciones reales por Piedra Lunar y negativas con Piedra Agua. Ninguna de las dos bolas se declara funcional.

**CI anterior 02 confirmada:** [#41718649006](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41718649006): Python 48/Godot 35 PASS, puertas IA6 PASS. **CI bloque03:** verificar recibos Python/Godot blocks=3 sobre último SHA con tercera fila CSV. Reparar fallos del arnés propio. Informar dependencia a IA6; no editar productor sexo, SaveV2 ni reglas globales.

**Siguiente `p`: bloque04** `beast_ball;heavy_ball`. Un bloque por turno, sin inventar encargos. No tocar main, V28, PR #118 o ramas ajenas.

---

## CI verificada

Ejecución [#41718649006](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41718649006) sobre SHA `97a86e17e7e25659e34a088ace5245bc50ba930a`: **completed/success**. Recibos `CAMP005_W03_PY PASS blocks=2 checks=48` y `CAMP005_W03_GODOT PASS blocks=2 checks=35`, ambos gates de IA6 PASS. La validación demuestra pruebas de productores y ganancias de amistad existentes, **no** funcionamiento nuevo de Luxury Ball ni Lure Ball.

---

# IA3/W03 — CONTINUIDAD CAMP005 02/10

**Rama única:** `codex/calvo-items-20261103-w03-camp005`. Bloque02 `luxury_ball;lure_ball` publicado, **no son objetos nuevos**. Estado `DEPENDENCIA_CONCRETA`: Luxury exige origen de captura persistente en CreatureInstance + política de bonificación futura y migración SaveV2; Lure necesita origen de pesca autenticado por mundo/sesión. Nuevas pruebas positivas solo de amistad base, Campana Alivio y serialización existente, NO de funcionamiento Luxury/Lure. No modificar productores compartidos sin IA6.

Bloque01 validado [CI #41715717542](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41715717542), Python 28/Godot 18 PASS. Bloque02: verificar recibos `CAMP005_W03_PY PASS blocks=2` y `CAMP005_W03_GODOT PASS blocks=2` con gates en SHA definitivo de progreso. Reparar fallos de arnés propios; no confundir PASS con funcionamiento de bolas.

**Siguiente `p`: bloque03 `love_ball;moon_ball`**, sin adelantar en este turno. Prohibido tocar main, V28, PR #118 o ramas ajenas.

---

## Validación de CI — 2026-11-03

GitHub Actions [#41715717542](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41715717542), SHA `a1bf8989427464f32762b49550bc08b06629a4b4`, terminó **success**. Recibos: `CAMP005_W03_PY PASS blocks=1 checks=28`, `CAMP005_GATE_PY_PASS`, `CAMP005_W03_GODOT PASS blocks=1 checks=18`, `CAMP005_GATE_GODOT_PASS`. El primer intento [#41715500393](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41715500393) falló por un falso positivo del auditor al encontrar `unknown_ball` en un comentario; criterio reparado en el SHA validado. El PASS certifica únicamente los contratos fuente disponibles y las dependencias descritas, **no** efectos funcionales nuevos para las tres bolas.

---

# IA3/W03 — CAMPAÑA_005 / continuidad bloque 01

**Rama exclusiva:** `codex/calvo-items-20261103-w03-camp005`. **Identidad:** IA3/W03. **Último microbloque entregado:** 01 `dive_ball;dusk_ball;repeat_ball` — remedición de dependencias, NO tres objetos nuevos.

Verificar en este orden: `CAMP_005_PROGRESO.csv`, `tests/fixtures/parallel_items/w03_campaign_005.json`, tests propios Python/Godot y `CAMP_005_ITER_01.md`. Los tres siguen en `DEPENDENCIA_CONCRETA`. Se identificaron exactamente los productores que faltan: origen fiable del encuentro en agua, reloj y oscuridad/cueva del mundo, y Pokédex con historial de especies capturadas y SaveV2. La ruta existente de `ShowdownAdventureSession.capture` solo produce turno/nivel y datos básicos; no admite inferencias ficticias. Ningún módulo de producción ha cambiado.

**CI:** ejecutar/verificar `CAMP005_W03_PY PASS blocks=1` y `CAMP005_W03_GODOT PASS blocks=1`, más gate oficial en último SHA del CSV. Si falla, diagnosticar la prueba exacta y corregir en W03 antes de afirmar éxito. Un PASS valida el contrato pendiente, **no** efecto funcional de Dive/Dusk/Repeat.

**Siguiente `p` si procede:** bloque 02 `luxury_ball;lure_ball`. Un único bloque por `p`; no tocar `main`, V28, PR #118 ni otras ramas. Al llegar a 10/10, STOP y `CAMPAÑA_005_FINALIZADA`.
