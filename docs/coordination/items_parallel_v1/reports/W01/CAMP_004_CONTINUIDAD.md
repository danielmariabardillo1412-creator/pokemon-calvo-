# IA1/W01 — Continuidad CAMPAÑA_004

## Estado vigente: bloque 01/10 publicado, CI en curso

**Especialidad:** objetos equipables de combate. **Rama:** `codex/calvo-items-20261103-w01-camp004`. **Autoridad:** gate `CAMPAIGN_004_W01_GATE.md`, cola `CAMPAIGN_004_W01_QUEUE_APPROVED.csv`, encargo `campaigns/CAMP_004_W01.md` y autonomía `AUTONOMOUS_REPAIR_V5.md` de la rama árbitra `codex/calvo-items-20261101-arbitro`.

- Bloque 01/10 entregado: `light_ball;lucky_punch;thick_club`; **8 escenarios, 34 pares, 102 variantes** activo/ausente/reserva, con SaveV2 en cada prueba. Certifica efectos de daño de Pikachu (físico/especial), Cubone, Marowak, negativos Mew y críticos de Chansey tras Foco Energía; Puño Suerte en Mew es control de especie errónea.
- Archivos propios: `tests/fixtures/parallel_items/w01_campaign_004.json`, `tests/tools/test_parallel_items_w01_campaign_004.py`, `tests/gameplay/parallel_items_w01_campaign_004.gd`, `reports/W01/CAMP_004_PROGRESO.csv`, `reports/W01/CAMP_004_ITER_01.md` y este `CAMP_004_CONTINUIDAD.md`. Ningún archivo CAMP003, producción, workflow, `main`, V28 ni otra rama fue editado. GitHub CI arranque PASS [#41578986117](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41578986117) (0 bloques); **CI de bloque 01** [#41579895025](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41579895025) pendiente al redactar.
- Fuente `held_effect_sweep_v3.cjs` ancla compatibilidades históricas. El Python valida hashes de inventario, alcance y este histórico antes de emitir PASS. El Godot exige por especie, crítico, no consumo, identidad y SaveV2 con motor real. No declarar PASS mientras no haya dos recibos y conclusión exitosa.
- **Próximo `p`:** comprobar primero últimos logs y runs de CAMP004 W01; si FAIL, reparar bajo V5 en rama propia conservando pruebas. El siguiente bloque autorizado es **02/10 `damp_rock;float_stone;icy_rock`**. Una `p` equivale a un microbloque, no toda la cola. Tras 10/10 STOP y `CAMPAÑA_004_FINALIZADA`.
- CAMPAÑA_003 W01 tiene CI final [#41575150716](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41575150716) PASS (10 bloques, 12.392 Godot/806 Python), no repetir trabajos ni deshacer arreglos de Botas Gruesas, Bola Férrea, Cola Plúmbea y Casco Dentado. Regresión completa CAMP003 en hitos 05/10 y tras reparación funcional W01.

## Reparación V5 en curso — W01 CAMP004 bloque 01

- El run [#41579895025](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41579895025) ejecutó la matriz completa: Python 111 PASS, Godot 2905 checks con 34 fallos **todos y solo** en el tipo `value is int` para semillas deserializadas como `19.0`. Las 2871 aserciones restantes pasaron, incluso especies, críticos y SaveV2.
- Parche mínimo del arnés `tests/gameplay/parallel_items_w01_campaign_004.gd`, commit `525991c4ad55dd8952ed2f62a4fc7f2a820540f3`: acepta float con valor entero exacto y rango 1..65535, rechaza fracciones. Sin cambiar fixture ni resultados nativos.
- Nueva CI [#41580332632](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41580332632). **Estado pendiente.** Solo `success` y recibos reales Python/Godot autorizan declarar PASS. No comenzar bloque 02 hasta nueva `p`; si persiste fallo propio, reparar conforme a V5 sin nueva autorización.
