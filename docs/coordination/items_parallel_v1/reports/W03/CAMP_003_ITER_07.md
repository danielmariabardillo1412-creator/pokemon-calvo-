# IA3/W03 — CAMPAÑA_003 / ITER_07: Safari Ball y Sport Ball

**Identidad y rama:** IA3/W03; `codex/calvo-items-20261103-w03-camp003`. **Cola aprobada:** `07,W03,CAPTURE_BALL,safari_ball;sport_ball` (`CAMPAIGN_003_QUEUE_APPROVED.csv`). Solo pruebas, fixture e informes; no producción, catálogo ni contexto inventado.

## Hallazgo decisivo: factor implementado, recinto sin verificar

- `modules/capture/capture_ball_effects.gd` blob `4e96b60ffe7b947817774d630b8e8afcca8d8591`: ambos IDs están registrados y el efecto devuelve **×1,5 sin condición de recinto** (`&"safari_ball", &"sport_ball": return 1.5`). `CaptureRuleset` blob `aaa848d77ff31349dae9720be001ff31658f55a9` registra exactamente una definición para cada ID, base ×1, no garantizada.
- `modules/capture/capture_battle_context.gd` blob `0a1ac1e2710e3a1f370fd8443ba0efde6dba4533` carece de indicador de Zona Safari / concurso de captura. `CaptureSystem.validate_attempt` blob `59d0149f27dd8f6bcdf8334b89c07cc1f88917cf` no exige un entorno así. Los productores Wild/Showdown actuales no entregan una señal específica a CaptureBattleContext.
- **Consecuencia:** es legítimo decir «el factor genérico ×1,5 y la captura por inventario funcionan» si pasa CI; **NO** decir «restricción de Zona Safari/Concurso implementada». Queda `DEPENDENCIA_DE_CONTEXTO`: `encounter_is_safari` y `encounter_is_bug_catching_contest` con autoridad del estado de mundo/encuentro y definición de política de uso fuera de esos entornos. IA6 debe emitir nuevo gate antes de programarlo. No confundir esta decisión con defecto demostrado del multiplicador actual.

## Cobertura incremental sin repetir V11

- El fixture acumulativo preserva 01–06 y añade solo 07: Mew (tasa baja) y Caterpie (tasa alta), PS completos/1, estados normal/dormido, dos contextos auténticamente disponibles (contexto de captura por defecto y turnos/nivel de capturador). **Ninguno representa Safari o Concurso**, intencionadamente.
- Godot contrasta factor real ×1,5, fórmula independiente `calvo_capture_v1`, una bola y una tirada RNG, resultado y propiedad de la misma instancia, inmutabilidad del Pokémon (ambas bolas sin efecto postcaptura), y **paridad Safari/Sport con el mismo estado y semilla**.
- Negativos en ambas: entrenador, mochila sin bola, KO y combate finalizado. Rechazo exacto sin consumo, RNG ni mutación.
- Python comprueba ausencia de campo de recinto en contexto, registro y factor, rutas originales de `CaptureSystem`, evidencia histórica V11 sin replicar su matriz, prohibición de falsos positivos y dependencia de IA6.
- **No hay test positivo de pertenencia a Zona Safari/Concurso**: no existe señal autoritativa; fabricar un campo para hacer pasar el test violaría el encargo. El éxito de los tests nuevos certifica solo el factor vigente y los rechazos.

## Referencias y ejecución

| Archivo W03 permitido | Blob SHA |
| --- | --- |
| `tests/fixtures/parallel_items/w03_campaign_003.json` | `5e1ec32c47d9771f223645bf5a39c6ffaaac46b5` |
| `tests/gameplay/parallel_items_w03_campaign_003.gd` | `399513bae1fe5ef55fd17078a3b233bad29ec1c1` |
| `tests/tools/test_parallel_items_w03_campaign_003.py` | `d11302526a1f6216b1a12f3a9ba55c725d333c25` |

**CI anterior comprobada:** [#41560663065](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41560663065) SHA `922e1d8d1561a16c014faa6f10ca9045811fceb7`: Python **180** y Godot **735** PASS para 6 bloques, no aplica automáticamente a los tests nuevos.

**CI del 07:** al publicar, `EN_CI_AUTOMATICA`, debe verificar en el SHA del commit con siete filas `CAMP003_W03_PY PASS blocks=7 checks=M` y `CAMP003_W03_GODOT PASS blocks=7 checks=M`. No declarar PASS hasta recibir veredicto y logs reales. Reportes no deben disparar una nueva CI.

**Solicitud a IA6 / dependencia:** definir si Safari y Sport pueden usarse fuera de sus recintos, cómo se detectan zonas y concursos desde encuentros Wild y Showdown, cómo se mantienen tras guardar/cargar, y cómo fallan sin gastar si no hay señal confiable. Prohibidos cambios de `CaptureBattleContext`, sesiones o reglas sin nuevo gate.

**Siguiente `p`:** exactamente bloque 08 de la cola aprobada, previa consulta de la CI del 07; STOP ante falla funcional compartida. Permanecen protegidos `main`, V28, producción, catálogos, workflows, árbitra y otras ramas.
