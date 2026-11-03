# IA3/W03 — CAMPAÑA_005, bloque 04 — Beast Ball y Heavy Ball

**Cola autorizada, backlog previo:** `beast_ball;heavy_ball` en la rama `codex/calvo-items-20261103-w03-camp005`. No sumar objetos nuevos.

## Frontera funcional comprobada

`CaptureSystem.resolve()` obtiene especie base y su `capture_rate`, aplica `BallEffects.multiplier` y `CaptureRuleset.catch_probability` sobre PS/estado y RNG. `CreatureSpecies` ofrece `source_metadata` genérico serializable, pero **no un contrato normalizado `is_ultra_beast`, `weight_hectograms` ni perfil de fórmulas por generación**. `CaptureRuleset` no registra Beast/Heavy y no existe implementación fiable que dependa de esas propiedades. Un metadato arbitrario sin validación no equivale a productor autoritativo.

**Beast Ball:** productor requerido: clasificación canónica de ultraentes por especie/forma y versión de reglas; consumidor: modificador de captura de `modules/capture/`. IA6 debe fijar el perfil de bonus/penalización para ultraentes y el resto, su versión y su encaje con `calvo_capture_v1`. No inferir ultraente por el nombre, tipo o evolución.

**Heavy Ball:** productor requerido: peso canónico por especie y forma, con unidad declarada (hectogramos); consumidor: fórmula de tasa modificada en captura. IA6 debe elegir la generación/versión y bandas de peso, caps y límites de tasa, preservando estado/RNG y distinguiendo modificación de **tasa base de captura** de un multiplicador final. Introducir `weight_kg` provisional o un factor genérico sería una regresión semántica.

## Pruebas propias nuevas

El runner Godot `_block_04` comprueba catálogo/selección de ambas bolas y explora atributos reales de `CreatureSpecies` (sin inventar campos), roundtrip `CreatureSpecies.to_dict/from_dict` de `capture_rate` y `source_metadata`, `CaptureRuleset.is_valid_capture_rate` y el cálculo determinista de probabilidad al 100 % de PS frente a la expresión existente. Python comprueba consumidor real de la tasa, campos normalizados ausentes, ausencia de factor registrado y contrato mínimo por objeto.

**Resultado de cada ID:** `DEPENDENCIA_CONCRETA`. Hay un contrato positivo de datos y probabilidad, **no efecto funcional de Beast Ball ni Heavy Ball**. No se repiten las matrices `unknown_ball` del bloque 01 de CAMP004.

## Intervención necesaria de IA6

Acordar taxonomía y versión de ultraentes, fuente de peso/formas y versión de fórmula Heavy Ball. Asignar productores de datos canónicos y definir la interoperabilidad con el motor `calvo_capture_v1`; solo entonces W03 debe registrar las dos bolas con tests positivos de probabilidad, condición, consumo, guardado y RNG. Sin cambios en producción, `main`, V28, PR #118, catálogo, workflows o ramas ajenas.

**CI:** requiere recibos Python/Godot de `blocks=4` y gates de IA6 sobre SHA con cuarta fila del CSV; hasta entonces no afirmar PASS.
