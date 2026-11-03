# IA4/W04 — CAMPAÑA_003 / ITER_04

**Estado:** EN_CI_AUTOMATICA. **No se afirma PASS del bloque 04.**

## Objeto exacto del encargo
- `magmarizer`
- `protector`
- `reaper_cloth`

Bloques 01, 02 y 03 conservados. Se amplía exclusivamente el fixture, el runner GDScript y el validador Python de W04.

## Contrato de prueba
El runner examina los registros reales del catálogo activo por ID y clasifica cada evolución mediante `EvolutionSystem.classify_record`. Solo si hay trigger `use_item` y clasificación `RUNTIME_SUPPORTED` puede ejecutar un positivo en `FieldItemService.evolve`, consumo unitario, rechazo de destino/propietario, identidad/atributos y SaveV2.

Si las rutas son dependientes de intercambio u objeto equipado, **no se simula evolución por bolsa**: se exige que `evolution_options` no ofrezca el destino condicionado, que `evolve` lo rechace y que inventario y criatura permanezcan idénticos. Los casos ausentes del catálogo se imprimen como `DEPENDENCIA`, sin falsear éxito de evolución.

## Evidencia publicada
- Fixture: commit `134f3b936cc676208dd7d1c7d82582ec6cbf9012`.
- Prueba Godot: commit `f46c4605f961bf39f0946e650299bfb9e423297d`.
- Validador Python: commit `ce9efb7d1e73d815a0daa8b2f7d19c838523d994`.
- Progreso: commit `fa1b73aeb87df4ff506cd46078ab3e2c63b7c126`.

## Validación pendiente
- Ejecución local Python: NO REALIZADA en este chat.
- Ejecución Godot 4.7: NO REALIZADA en este chat.
- CI de este nuevo SHA: PENDIENTE DE CONFIRMACIÓN.
- Dependencias históricas Oval Stone e intercambio: documentadas; no se modifican módulos de producción, política, SaveV2 ni reglas canónicas.

**Próxima tarea por `p`:** bloque 05, `prism_scale;sachet;up_grade`, únicamente si no existe un FAIL real que obligue a detenerse.
