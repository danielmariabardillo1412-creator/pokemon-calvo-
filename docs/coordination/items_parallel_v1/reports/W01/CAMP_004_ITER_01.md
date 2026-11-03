# IA1/W01 · CAMPAÑA_004 · Microbloque 01/10

**Estado al publicar:** `EN_CI_AUTOMATICA`; no se afirma todavía PASS funcional. **Rama exclusiva:** `codex/calvo-items-20261103-w01-camp004`. **IDs exactos del gate IA6:** `light_ball;lucky_punch;thick_club`. No se toca `main`, V28, CAMPAÑA_003, otras ramas ni código compartido.

## Evidencia nativa previa y escenarios

| Item | Referencia histórica del código existente | Pruebas propias y control negativo |
|---|---|---|
| **Bola Luminosa** (`light_ball`) | `tools/item_audit/held_effect_sweep_v3.cjs`: `species_boost_pikachu_thunder_shock` y `species_boost_pikachu_tackle` | **Pikachu** con Rayo Impacto (`thunder_shock`, especial) y Placaje (`tackle`, físico) aumenta daño únicamente equipado, controles sin objeto/reserva. En **Mew**, la misma Bola Luminosa no cambia daño |
| **Hueso Grueso** (`thick_club`) | `held_effect_sweep_v3.cjs`: `species_boost_cubone_tackle`, `species_boost_marowak_tackle` y `wrong_holder` | **Cubone** y **Marowak** aumentan daño de Placaje solo con objeto activo. **Mew** no obtiene aumento. No se consume |
| **Puño Suerte** (`lucky_punch`) | `held_effect_sweep_v3.cjs`: `critical_stage`, **Chansey**, `focus_energy` y `tackle`, `wrong_species` | Tras un turno de **Foco Energía**, segundo turno Placaje para **Chansey**, registrar críticos desde log de eventos reales en 16 semillas y exigir testigos de crítico exclusivo del portador (comparación sin equipar/reserva). **Mew** con el mismo objeto no debe alterar críticos ni daño respecto a controles (8 semillas) |

Las mecánicas se ejecutan mediante `Native.begin_wild` y `Native.submit` del motor ya integrado, usando `FieldItemService` para equipar. Se comprueban propiedad, consumo (son equipables retenidos), dos unidades físicas, ausencia de asentamiento anticipado y restauración **SaveV2** exacta de snapshot y propietario para los tres modos `active/none/reserve`. Las semillas son deterministas; no se inventan compatibilidades con otros Pokémon ni se implementa un simulador alternativo.

**Bloque 01:** ocho escenarios, 34 pares caso-semilla y **102 variantes nativas con SaveV2**. Se mantiene la infraestructura de CAMP003 como herencia de pruebas **sin alterar sus archivos**; la CI de CAMP004 ejecuta regresión completa de CAMP003 solo en hitos 05/10 o tras cambios funcionales, según el gate IA6. Es incorrecto atribuir la cobertura anterior a este nuevo bloque.

## Archivos y versiones

- Fixture `tests/fixtures/parallel_items/w01_campaign_004.json`, commit `d6672b8abe9cce169e7cc2c8456370559adf9416`, blob `0e59ed989700f16c8ee0fbe5f29d171ea05f6859`; fuentes canónicas con hashes: inventario `2aaf18643bb2b071226118a1ad556cffca4707dd`, alcance `8b9b723bf5944bbbde39aa2d49dfbb2f2a64e11b`, histórico nativo V3 `fd5d9d0b1eecf8b84f14e606631df93b40728586`.
- Python `tests/tools/test_parallel_items_w01_campaign_004.py`, commits `5113cf337ee273b829018624b0a4b0691635f525` y `2c6f3ffee09c405ea145c8b0ee65e801f30ad708`. Contrata especie y movimiento, ocho escenarios exactos, 34 pares, 3 modos, hashes de fuentes nativas, cola y progreso.
- Godot `tests/gameplay/parallel_items_w01_campaign_004.gd`, commit `97c7141dcbf8af6ca770fa5c0f05cac294ece4e2`. Runner exclusivo que hereda infraestructura CAMP003 sin ejecutarla por duplicado; contrasta efectos y restaura snapshot SaveV2.
- Progreso `reports/W01/CAMP_004_PROGRESO.csv`, commit disparador `0ecd21867673ae226a3d9db481846308dcb84fe1`, fila **01 `EN_CI_AUTOMATICA`**.

**CI automática:** [#41579895025](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41579895025), inicialmente `in_progress`. La CI de arranque [#41578986117](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41578986117) solo certificó `BOOTSTRAP_VALIDADO_SIN_NINGUN_BLOQUE_FUNCIONAL`, no los nuevos efectos. Para acreditar el bloque 01 deben constar `CAMP004_W01_PY PASS blocks=1 checks=M` y `CAMP004_W01_GODOT PASS blocks=1 checks=M` con conclusión `success`.

## Criterios de continuación

Si el motor muestra fallo real, diagnosticar logs SHA y repararlo dentro de la especialidad W01 bajo V5, conservando controles. En caso de dependencia de arquitectura o conflicto con otras IAs, escalar a IA6 sin modificar módulos compartidos por cuenta propia. **Siguiente `p` únicamente bloque 02** (`damp_rock;float_stone;icy_rock`) y **solo tras revisar CI01**. No iniciar bloque 03 ni completar campaña antes de 10/10. Sin validación GPU/UI, mapa ni integración global.

## Reparación autónoma V5 tras primera CI

El primer run funcional [#41579895025](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41579895025) concluyó `failure`: **Python `CAMP004_W01_PY PASS blocks=1 checks=111`**, mientras Godot emitió `CAMP004_W01_GODOT FAIL blocks=1 checks=2905 errors=34`. Los **34 errores eran todos `Semilla válida`**: Godot deserializa números del JSON como `float` (`19.0`) aunque representan enteros, y el arnés usaba la condición incorrecta `value is int`. Los otros **2.871 checks**, incluidos positivo/negativo por especie, control de críticos, consumo e integridad SaveV2, no fallaron.

**Parche V5 local, sin rebajar el contrato:** commit `525991c4ad55dd8952ed2f62a4fc7f2a820540f3`, modifica exclusivamente `tests/gameplay/parallel_items_w01_campaign_004.gd`: acepta `int` o `float` solo si `float(value) == float(int(value))`, con límite `1..65535`; conserva rechazo de valores fraccionarios y normaliza el nombre del caso a entero. Fixture, ocho escenarios, 34 pares, 102 variantes, semillas declaradas, aserciones de especies, críticos y SaveV2 permanecen idénticos.

**CI completa de verificación del parche:** [#41580332632](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41580332632), SHA `525991c4ad55dd8952ed2f62a4fc7f2a820540f3`, inicialmente en cola. No declarar `CI_PASS_VERIFICADO` hasta ver los recibos `CAMP004_W01_PY PASS blocks=1` y `CAMP004_W01_GODOT PASS blocks=1` y `completed/success`.
