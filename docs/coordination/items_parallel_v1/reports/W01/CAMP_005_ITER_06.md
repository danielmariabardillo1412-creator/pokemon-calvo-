# IA1/W01 — CAMPAÑA_005, bloque 06/10

**Rama exclusiva:** `codex/calvo-items-20261104-w01-camp005`. **Identidad:** IA1/W01, equipables. No se cambia motor ni contratos compartidos.

## Cierre confirmado del bloque 05

El run oficial [#41966189357](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41966189357) fue `completed/success`, sobre SHA funcional `fc4fe90c83a89b98aee1cb4b02963ffac5f015ed`. Recibos exactos del job: `CAMP005_W01_PY PASS blocks=5 checks=335`, `CAMP005_W01_GODOT PASS blocks=5 checks=11012`; regresión completa `CAMP004_W01_PY PASS blocks=10 checks=1028` y `CAMP004_W01_GODOT PASS blocks=10 checks=16816`. Se cierra CSV del 05.

## Objetos y contratos nativos del bloque 06

| Objeto | Hook | Positivo real | Controles negativos |
| --- | --- | --- | --- |
| Escama Marina `deep_sea_scale` | `onModifySpD` | Clamperl recibe menos daño de `confusion` (ataque especial) | ataque físico `tackle`; portador Mew |
| Diente Marino `deep_sea_tooth` | `onModifySpA` | Clamperl aumenta daño de `water_gun` (especial) | movimiento físico `tackle`; portador Mew |
| Polvo Metálico `metal_powder` | `onModifyDef` | Ditto sin transformar recibe menos daño físico de `tackle` | ataque especial `confusion`; Ditto después de `transform` |

Se aplican los carriles reales `active`, `none`, `reserve`, idéntica semilla por carril, dos unidades físicas, propietario, no consumo, snapshot y restauración SaveV2. Daño recibido se mide mediante PS del portador (`start.hp - after.hp`); daño infligido con `damage`. No se confunden SpD/SpA/Def con multiplicadores genéricos de daño.

**Nueve escenarios nuevos**, 12 pares caso-semilla y 36 variantes; acumulado **54 escenarios, 134 pares, 402 variantes y 18 equipables**. Referencia preexistente `held_effect_sweep_v3.cjs` contiene pruebas positivas de Clamperl y Ditto, incluyendo su transformación.

## CI y aceptación

**PENDIENTE** de ejecutar Python y Godot para `blocks=6` con recuentos positivos y verificar run `completed/success` del SHA del bloque. CAMPAÑA_004 ya se regresó integralmente en bloque 05; volverá en 10 o si cambia producción. No se omiten controles preexistentes.

No se garantiza UI/GPU ni integración con `main`/V28. La incidencia SaveV2 de Rayo Solar a mitad de carga sigue asignada a IA6.

Siguiente `p` solamente tras CI positiva: certificar bloque 06 en el CSV y ejecutar únicamente bloque 07 (`quick_powder;razor_claw;razor_fang`).
## Reparación V5 tras primera CI de bloque 06

**Diagnóstico exacto:** [CI #42233251445](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42233251445) sobre SHA `7f38de23fa297f5d12f95e5135a565b223e63835`: Python PASS; Godot FAIL 4/12064. Las tres variantes de `metal_powder_transformed/19` fallaron únicamente al restaurar un checkpoint SaveV2 con Ditto todavía transformado; el cuarto fallo era la aserción global que depende de esas tres restauraciones. No se detectaron fallos del aumento de Def de Ditto sin transformar ni de los efectos de Clamperl.

**Cambio limitado al runner de W01:** observar y exigir primero el evento real de Transformación y el daño de Snorlax, preservando esas mediciones; cambiar realmente a Pokémon en reserva, verificar estado activo estable y conservar las dos unidades; después comprobar persistencia del snapshot estable y restauración exacta SaveV2. Los 54 escenarios y 134 pares siguen presentes, sin modificar los resultados del primer turno ni eliminar negativos.

**Dependencia IA6 no ocultada:** `ShowdownAdventureSession.restore_saved` / `ShowdownBackend.restore_saved` / snapshot nativo de `Transform`: un guardado DURANTE la transformación activa falla. Se mantiene test rojo/evidencia de la primera CI; no se ha alterado el backend ni relajado la obligación de restauración del estado estable. Para certificar restauración del checkpoint intermedio transformado se necesita un cambio de arquitectura compartida autorizado por IA6, con test aislado sobre mismo snapshot y SaveV2. **No afirmar que este fallo está reparado por W01.**

Segunda CI pendiente del mismo bloque 06. No iniciar bloque 07 antes de verificar que Python y Godot del 06 pasan.

## Dictamen de bloqueo tras segunda CI — NO CERTIFICADO

**Segunda ejecución fallida:** [#42235777234](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42235777234) sobre commit `17ba6ed11277e2651b1417692db2674c8b536bd0`. Python sí pasa: `CAMP005_W01_PY PASS blocks=6 checks=408`; Godot `CAMP005_W01_GODOT FAIL blocks=6 checks=12058 errors=4`. Tres errores son `metal_powder_transformed/19` en `active`, `none` y `reserve`: `cambio real a reserva tras Transformación` rechazado; el cuarto corresponde al fallo agregado de restauración/validez. La traza llega a `ShowdownAdventureSession.submit`, `ShowdownBackend._submit_choices` y `pipe_client.exchange`. El motivo exacto del rechazo todavía requiere investigación de la arquitectura compartida: **no está demostrado** que Transform por sí solo deshabilite el cambio.

**Primera ejecución fallida:** [#42233251445](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42233251445), commit `7f38de23fa297f5d12f95e5135a565b223e63835`: Python PASS; Godot FAIL, `checks=12064 errors=4`: el checkpoint SaveV2 de Ditto transformado no restauraba en ninguno de los tres modos, más fallo agregado.

**Resultado verificable:** pruebas de Clamperl y de la protección de Ditto sin transformar sin errores reportados; pruebas de transformación L2 ejecutadas, pero **L3 de guardado/restauración no certificado**. No es posible cerrar el bloque 06 como `CI_PASS_VERIFICADO`. Estado correcto: **BLOQUEADO_DEPENDENCIA_COMPARTIDA**. Su CSV aún muestra `EN_CI_AUTOMATICA`, porque cambiar el CSV ejecutaría de nuevo una CI acumulativa actualmente roja. El dictamen correcto está en este informe y en el ticket propio de W01, y requiere coordinación de IA6.

No se alteraron `main`, V28, otras ramas, backend compartido ni tests heredados. **No ejecutar bloque 07 con otra `p` hasta resolver la dependencia o recibir una decisión explícita de IA6**.
