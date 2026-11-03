## Validación CI del bloque 03

[GitHub Actions #41719545522](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41719545522), SHA `8b12bbb254f01ec39fa0d24b4959c6c548ee4eef`, **completed/success**. Recibos: `CAMP005_W03_PY PASS blocks=3 checks=63`, `CAMP005_GATE_PY_PASS`, `CAMP005_W03_GODOT PASS blocks=3 checks=63`, `CAMP005_GATE_GODOT_PASS`. Certifica el contrato de evolución lunar positivo y las fronteras pendientes; **Love Ball y Moon Ball todavía no obtienen efectos funcionales de captura**.

---

# IA3/W03 — CAMPAÑA_005 / BLOQUE 03 — Love Ball y Moon Ball

**Reserva autorizada:** `love_ball;moon_ball`. No se cuentan como objetos nuevos. Rama propia: `codex/calvo-items-20261103-w03-camp005`.

## Investigación funcional

**Love Ball:** el cálculo necesita confirmar que el Pokémon objetivo y el Pokémon activo pertenecen a la misma especie según la regla elegida, tienen sexos compatibles y no carecen de sexo. `CreatureInstance` posee `species_id` y `base_species_id()` con serialización, pero **no almacena sexo individual**; `CreatureFactory.create()` no lo genera. `CreatureSpecies.source_metadata` puede conservar la distribución estadística por especie, pero esta no equivale al sexo de un individuo y nunca debe utilizarse para asignarlo arbitrariamente. Productor faltante: sexo individual autoritativo, determinista y persistente para ambos participantes y validación de sexo desconocido. Consumidor: motor de captura, utilizando identidad de especie base y la normativa acordada. Requiere decisión de migración SaveV2, generación con RNG estable y tratamiento de formas/especies.

**Moon Ball:** el catálogo sí contiene `EvolutionRecord.item_id`, `version_group` y `conditions`. `EvolutionSystem.classify_record()` diferencia rutas ejecutables de datos condicionados; `EvolutionSystem.evolution_candidates()` acepta `item_id`, por lo que se puede probar de forma positiva que una ruta `moon_stone` es elegible y que `water_stone` no activa esa misma ruta. Sin embargo, `CaptureRuleset` no conecta `moon_ball` y falta definir qué versión de evoluciones considerar para la bonificación y si es válida cualquier ruta histórica o solo la ruta compatible vigente. No se debe confundir `moon_stone` existente con una bonificación de captura implementada.

## Pruebas añadidas

- Godot `_block_03`: catálogo/selección, serialización de `CreatureInstance` y ausencia de sexo individual; enumeración real de rutas de `moon_stone`, `EvolutionSystem.classify_record`, positivos con `item_id=moon_stone`, negativos con `water_stone` y constatación de contratos pendientes.
- Python: confirma reserva, características de `EvolutionRecord`, tipos de condiciones, ausencia de sexo individual en `CreatureInstance`, ruta real de evolución y cobertura del runner. No repite simplemente la auditoría `unknown_ball` de CAMP004.
- Regresiones CAMPAÑA_005 acumuladas en los bloques 01, 02 y 03, sin tocar las suites anteriores.

**Clasificación por ambos IDs:** `DEPENDENCIA_CONCRETA`. La ruta de evolución lunar constituye un productor **parcial verificable**, no una integración de Moon Ball funcional. No se crean generadores de sexo, metadatos SaveV2, reglas de combate ni efectos ficticios.

## Interfaz/decisiones solicitadas a IA6

1. Designar el productor del sexo individual, política de generación, serialización y reconstrucción histórica para Love Ball; fijar tratamiento de especie base/formas, género desconocido y diferencia de sexo.
2. Seleccionar `version_group` autoritativo, filtro de rutas Luna y regla exacta de bonificación Moon Ball. W03 puede integrar su multiplicador en `modules/capture/` al existir el contrato aprobado, con capturas positivas y negativas.

**CI:** comprobar que la ejecución definitiva emita `CAMP005_W03_PY PASS blocks=3` y `CAMP005_W03_GODOT PASS blocks=3` y ambas puertas IA6. No afirmar PASS antes de los recibos. No modificar `main`, V28, PR #118, producción ni otras ramas.
