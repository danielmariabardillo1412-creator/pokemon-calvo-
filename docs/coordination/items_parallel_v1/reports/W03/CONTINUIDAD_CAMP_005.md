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
