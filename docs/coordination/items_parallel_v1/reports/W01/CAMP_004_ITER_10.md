# IA1/W01 — CAMPAÑA_004 — Bloque 10/10

## Alcance y autorización
Rama exclusiva `codex/calvo-items-20261103-w01-camp004`. Cola aprobada por IA6: `black_belt;charcoal;magnet`. Sin cambios en producción, V28, main o ramas ajenas.

## Pruebas añadidas
Los tres potenciadores de tipo tienen descriptor nativo `onBasePower` y están seleccionados. Contrato funcional en el motor `gen9calvounifiedv1` con comprobación real de daño y cuatro invariantes: objeto solo activo, ninguna potencia desde reserva o ausencia, no consumo y proyección SaveV2 idéntica.

- Cinturón Negro: `brick_break` de tipo Lucha aumenta daño; `tackle` de tipo Normal y `reflect` no reciben bonificación.
- Carbón: `flamethrower` de tipo Fuego aumenta daño; `tackle` y `reflect` son controles negativos.
- Imán: `thunderbolt` de tipo Eléctrico aumenta daño; `tackle` y `reflect` son controles negativos.

Matriz del bloque 10: **9 casos, 12 pares semilla y 36 variantes**. Matriz completa CAMP004: **30 objetos, 79 casos, 185 pares y 555 variantes**. Antecedente de implementación de los tres: `tools/item_audit/held_effect_sweep_v2.cjs` (`booster`, `type_boost` y `type_boost_nonmatching`). Se preservan los tests de los nueve bloques anteriores.

## Puertas de aceptación
El bloque 09 se cerró con CI [#41726708467](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41726708467), SHA `30ee5f992dcd3f0e640b8f844c86cfed8c10cc94`, Godot 15.731 y Python 917 comprobaciones aprobadas.

**Estado inicial: EN_CI_AUTOMATICA.** Para certificar este bloque se requieren manifiesto PASS, `CAMP004_W01_PY PASS blocks=10`, `CAMP004_W01_GODOT PASS blocks=10`, puertas PASS, conclusión GitHub Actions `completed/success` y **regresión completa CAMPAÑA_003** Python/Godot del mismo run.

Si hay fallo, investigar logs y reparar solo dentro de la rama W01 conforme a V5, sin eliminar casos ni alterar motores compartidos. Incidencia heredada de SaveV2 en la fase de carga intermedia de Rayo Solar pendiente de IA6. La CI headless no certifica GPU/UI ni integración global.

Tras aprobar todas las puertas, registrar certificado CI en el cuaderno, marcar `CAMPAÑA_004_FINALIZADA` y detenerse. No iniciar otra campaña sin autorización.

## CERTIFICACIÓN FINAL — CAMPAÑA_004_FINALIZADA

CI [#41733777992](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41733777992) **completed/success**; SHA de pruebas `9770b71a7f7c6d5e9b6e93eeaef81e96d42a094b`.

Recibos observados en el job oficial:
- `CAMP004_W01_MANIFEST_PASS reserved=10 completed=10 ids=30`
- `CAMP004_W01_PY PASS blocks=10 checks=1028` y `CAMP004_GATE_PY_PASS worker=W01 blocks=10 checks=1028`
- `CAMP004_W01_GODOT PASS blocks=10 checks=16816` y `CAMP004_GATE_GODOT_PASS worker=W01 blocks=10 checks=16816`
- `CAMP003_W01_PY PASS blocks=10 checks=806` (regresión completa)
- `CAMP003_W01_GODOT PASS blocks=10 checks=12392` (regresión completa)

**Resultado verificado:** 10/10 microbloques; 30 equipables; 79 escenarios; 185 pares caso-semilla; 555 variantes de equipamiento. Prueba funcional nativa y SaveV2 de estados estables. Ninguna reducción de cobertura anterior. No se ha editado código de producción, main, V28 ni otras ramas.

**Cierre administrativo:** el CSV 10/10 se certifica en un commit exclusivamente documental posterior al SHA probado, evitando repetir por metadatos la CI ya aprobada. El commit de cierre usa `[skip ci]` y NO constituye una ejecución adicional; la evidencia válida es el run #41733777992 sobre el SHA anterior. Si IA6 necesita checks obligatorios sobre el HEAD documental, debe solicitar reejecución explícita.

**Incidencia residual escalada a IA6:** la proyección SaveV2 de Rayo Solar durante el turno de carga intermedio (bloque 03) no está resuelta; los tests estabilizan esa secuencia para la restauración. La CI headless no acredita test visual/GPU, integración en main/V28 ni retorno al mapa. La rama W01 queda lista para inspección y consolidación independiente por IA6, sin fusionar desde esta conversación.

**Estado: `CAMPAÑA_004_FINALIZADA`. STOP.** No ejecutar nuevos bloques ni campañas sin autorización de IA6.
