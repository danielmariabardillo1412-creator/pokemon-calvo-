# IA3/W03 — CAMPAÑA_003 / ITER_06: Amigo Ball y Sana Ball

**Identidad:** IA3/W03. **Rama exclusiva:** `codex/calvo-items-20261103-w03-camp003`.
**Autorización:** fila exacta 06 del CSV IA6: `friend_ball;heal_ball`; alcance `AUDITORIA_CONTRATOS_Y_PRUEBAS_NO_PRODUCCION`. Se preservan sin cambio los cinco bloques previos.

## Evidencia real existente, no reimplementar

- `modules/capture/capture_ball_effects.gd`, blob `4e96b60ffe7b947817774d630b8e8afcca8d8591`: Amigo establece **amistad exactamente 200 tras éxito**, incluso desde 240 o 255. Sana, tras éxito, repone PS, limpia estado persistente/IDs y restaura PP al **máximo de cada movimiento** sin alterar dicho máximo.
- `CaptureSystem.resolve`, blob `59d0149f27dd8f6bcdf8334b89c07cc1f88917cf`: llama `BallEffects.on_catch` únicamente si éxito, antes de enrutar al equipo o almacenamiento. `CaptureInventoryService`, blob `5898e23f3d935bd48df4a5f9e13c5b2cab7c852d`, controla posesión, gasto y rollback.
- V11 `tests/gameplay/item_capture_v11.gd`, blob `44ad0d5fe48bd81239ecea9b57bb6690817af6a1`, ya contiene matriz de 10.760 escenarios, Sana al PC con PP máximo ampliado y pruebas de UI/guardado. **No duplicar** esas suites ni tocar producción.

## Nueva cobertura incremental concreta

- **Amigo:** amistad inicial 0,117,200,240,255; tras éxito amistad 200 manteniendo PS/PP/estado y toda la identidad. Caso de fallo con amistad 240 comprueba **ningún cambio postcaptura**.
- **Sana:** sueño persistente, veneno y objetivo normal; PP actual 0/1/3 con máximo 64. Tras éxito se restablecen PS, estado y PP sin reducir el máximo; tras fallo permanecen idénticos. Una captura ordinaria puede tener probabilidad 1 y aun así debe consumir su tirada RNG.
- **Ambas:** éxito con equipo completo de seis Pokémon → disposición `STORAGE_REQUIRED`, luego `CaptureOwnershipRouter` real y almacenamiento de la misma instancia sin duplicar dueño; negativos entrenador, sin bola y KO sin gasto, RNG ni mutaciones.
- **Validación de datos:** Amigo amistad `-1` y `256` rechazada `invalid_ball_friendship_state`; Sana PP `-1/64`, `65/64` y `0/0` rechazada `invalid_ball_pp_state`. No se repara ni consume inventario en intento inválido.
- **Determinismo:** semillas elegidas buscando un resultado deseado con `RandomNumberGenerator` real en rango `1..4096`, y comparando la tirada independiente con el estado RNG de producción; ni probabilidades ni estados se falsean.

## Publicación

- Fixture acumulativo `tests/fixtures/parallel_items/w03_campaign_003.json`, blob `2edc944346c64fd71a01e4a086d086a38b251cf0`.
- Runner Godot `tests/gameplay/parallel_items_w03_campaign_003.gd`, blob `c7b3049aefe85bdfbcd34e14b00e18c9a47157ca`.
- Validador Python `tests/tools/test_parallel_items_w03_campaign_003.py`, blob `a87e67c12247f396d64cb6cb073ff980eafdb19b`.
- CSV `reports/W03/CAMP_003_PROGRESO.csv`, sexta fila 06 `EN_CI_AUTOMATICA`, blob `c927c8396fa29ddf4f4e53836e04ba4e87c424f3`.
- **Commit de pruebas y CSV:** `922e1d8d1561a16c014faa6f10ca9045811fceb7`. [GitHub Actions #41560663065](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41560663065), disparado en ese SHA.

**Veredicto al redactar:** última CI de 05 [#41559647462](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41559647462) SUCCESS, Python 148 y Godot 619. **El bloque 06 aún no tiene PASS declarado**: se requieren en logs de CI `CAMP003_W03_PY PASS blocks=6 checks=M` y `CAMP003_W03_GODOT PASS blocks=6 checks=M`, y ambas puertas IA6. Comprobar el SHA del run; cancelaciones intermedias no equivalen a fallo.

**Siguiente `p`:** ejecutar únicamente el bloque oficial 07 previa consulta a la última CI. Fallo de test propio: corregirlo sin rebajar controles; problema en módulo compartido: detenerse y avisar a IA6. No tocar `main`, V28, `.github`, catálogo canónico, producción, ni otra rama.
