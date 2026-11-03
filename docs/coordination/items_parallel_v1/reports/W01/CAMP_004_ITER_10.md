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
