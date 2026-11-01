# IA1/W01 — CAMPAÑA_001_FINALIZADA

**Fecha:** 2026-11-01. **Identidad:** IA1/W01. **Rama:** `codex/calvo-items-20261101-w01`.
**Orden de IA6:** `campaigns/CAMP_001_W01.md`, blob `4faaae234c3021944d7f4724789c3b2c5d0652fd`; última puerta `CAMPAIGN_GATE_UPDATE_003.md`, blob `59c553bd7a931ebe4ac10bf4b2b3ce43815220dc`.
**Cierre de trabajo:** tres microbloques entregados, ninguno restante. **No hay autorización para ITER_04 ni CAMP_002.**

## Matriz de cobertura validada

| ID | Microbloque | Contratos concretos | Casos | Pares caso-semilla | Evidencia |
|---|---|---|---:|---:|---|
| `black_sludge` | 01 | Curación Veneno, PS completos, daño a no Veneno | 3 | 5 | PASS staging acotado |
| `shell_bell` | 01 | Daño con recuperación, estado sin daño, inmunidad Normal/Fantasma | 3 | 4 | PASS staging acotado |
| `big_root` | 01 | Drenaje aumentado con Absorber, control sin drenaje | 2 | 3 | PASS staging acotado |
| `eviolite` | 02 | Preevolución frente a final, físicos y especiales | 4 | 6 | PASS staging acotado |
| `expert_belt` | 02 | Supereficaz frente a neutral | 2 | 3 | PASS staging acotado |
| `safety_goggles` | 02 | Espora, tormenta de arena, control sin efecto | 3 | 3 | PASS staging acotado |
| **Total** | **01–02** | Activo, ninguno, reserva y restauración SaveV2 | **17** | **24** | **72 variantes PASS** |

El microbloque **03** consolida documentación, CI, hashes y matrices; **no añade casos** ni modifica el código de las pruebas. Los tres informes de iteración son `CAMP_001_ITER_01.md`, `CAMP_001_ITER_02.md`, `CAMP_001_ITER_03.md`.

## Integridad de artefactos y pruebas

- Fixture JSON, blob Git `c8360512855aa2339e8644e0fe4f117542985866`.
- Runner GDScript, blob Git `d2a4bae5e99182c55d37c01c1f67f075bc41ea43`.
- Validador Python, blob Git `d6f5cd51d8d9141a1f691f613bad47216f586a22`.
- Esos tres blobs coinciden **exactamente** entre commit staging `6ea4cb1b9b68e0d1e33ef6a5228dcf57503a3456`, commit árbitra `7b360f90b74e18085f5b741722fd67fded88d23b` y rama W01 actual.
- En [Actions #41350981613](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41350981613), **W01 step SUCCESS**: Godot 4.7 `W01_CAMP_001 PASS checks=2428 rows=24 errors=0`; contratos Python 17/24/72; seis mutaciones negativas rechazadas; evidencia nativa SHA-256 PASS 24/72. **Run total FAILURE por W02**, no implica fallo de W01.
- Integración de pruebas por IA6 registrada en `integration/CAMP_001_W01_W04.md`. Regresión [#41353674663](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41353674663) SUCCESS en `7b360f90...` y [#41354759130](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41354759130) SUCCESS en `52a5515e...`, **ambas de harness histórico**, no de campaña.

**Auditoría de consolidación:** 15 invariantes estructurales PASS (IDs, semillas enteras, sin duplicados, 8+9 casos, tres variantes, cobertura de callbacks y aserciones, rutas, digest de fixture y recibos, controles negativos). Ningún cambio a producción; informes LOTE_001/002 originales preservados.

## Qué está cerrado y qué NO

- **Cerrado:** preparación de las tres iteraciones, pruebas de los seis objetos y auditoría documental; **efectos observados en el alcance definido de CI staging**.
- **NO cerrado:** totalidad de interacciones competitivas, supresión/Truco, reparto de ítems en más formatos, todas las habilidades y RNG, victoria y asentamiento fuera de batalla, UI manual/GPU. Los hooks y fórmulas siguen en simulador nativo fijado `@pkmn/sim@0.10.11`; ninguna lógica se duplicó en GDScript.
- **Nivel de certificación:** `VERIFICADO_EN_STAGING` + **tests integrados en árbitra**. No extrapolar a `PASS de todo el juego`, a GPU o a funcionalidad completa de campaña.

## Entrega y parada obligatoria

Publicados `CAMP_001_ITER_03.md`, `CAMP_001_FINAL.md`, `CAMP_001_PROGRESO.csv` y `CONTINUIDAD.md` en rama W01, sin alterar `main`, PR #118, V28 original, ramas ajenas o archivos de producción.

**Estado final:** `CAMPAÑA_001_FINALIZADA` — **STOP** hasta una nueva autorización exacta de IA6. Si IA6 detecta un fallo posterior, responder solo bajo una corrección explícitamente acotada.
