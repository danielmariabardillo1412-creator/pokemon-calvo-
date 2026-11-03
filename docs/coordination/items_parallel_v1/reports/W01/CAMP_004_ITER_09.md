# IA1/W01 — CAMPAÑA_004 — Bloque 09

Rama: `codex/calvo-items-20261103-w01-camp004`.

Objetos: `white_herb`, `wise_glasses`, `zoom_lens`.

Cobertura nueva: 8 escenarios, 36 pares caso-semilla, 108 variantes activo/ausente/reserva con SaveV2. Acumulado: 9 bloques, 27 equipables, 70 escenarios, 173 pares y 519 variantes.

Pruebas de Hierba Blanca: Rompecoraza, Gruñido, ausencia de caída de estadísticas, consumo. Gafas Especiales: Confusión con daño potenciado, Placaje y Reflejo sin bonificación, no consumo. Telescopio: Hydro Pump de portador lento y rápido, 28 semillas, control de orden y testigo RNG diferencial. Fuentes: `held_pilot.cjs`, `held_effect_sweep_v2.cjs`, `held_effect_sweep_v3.cjs`.

Bloque 08 certificado con CI #41722166088 en commit `6b484eab6899d3ac653a3cf0b13cf5ea4c75668b`, 12.485 Godot y 818 Python. Fila 08 actualizada.

Bloque 09 pendiente de validación por GitHub Actions. No declarar PASS hasta contar con conclusión `success`, manifiesto y recibos funcionales Python/Godot. Regresión CAMPAÑA_003 completa obligatoria en hito 10. Limitación previa SaveV2 durante carga intermedia de Rayo Solar pendiente de IA6. No se modifican producción, `main`, V28, árbitra ni ramas ajenas.
