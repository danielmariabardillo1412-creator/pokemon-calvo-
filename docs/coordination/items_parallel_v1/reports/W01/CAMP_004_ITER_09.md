# IA1/W01 — CAMPAÑA_004 — Bloque 09

Rama: `codex/calvo-items-20261103-w01-camp004`.

Objetos: `white_herb`, `wise_glasses`, `zoom_lens`.

Cobertura nueva: 8 escenarios, 36 pares caso-semilla, 108 variantes activo/ausente/reserva con SaveV2. Acumulado: 9 bloques, 27 equipables, 70 escenarios, 173 pares y 519 variantes.

Pruebas de Hierba Blanca: Rompecoraza, Gruñido, ausencia de caída de estadísticas, consumo. Gafas Especiales: Confusión con daño potenciado, Placaje y Reflejo sin bonificación, no consumo. Telescopio: Hydro Pump de portador lento y rápido, 28 semillas, control de orden y testigo RNG diferencial. Fuentes: `held_pilot.cjs`, `held_effect_sweep_v2.cjs`, `held_effect_sweep_v3.cjs`.

Bloque 08 certificado con CI #41722166088 en commit `6b484eab6899d3ac653a3cf0b13cf5ea4c75668b`, 12.485 Godot y 818 Python. Fila 08 actualizada.

Bloque 09 pendiente de validación por GitHub Actions. No declarar PASS hasta contar con conclusión `success`, manifiesto y recibos funcionales Python/Godot. Regresión CAMPAÑA_003 completa obligatoria en hito 10. Limitación previa SaveV2 durante carga intermedia de Rayo Solar pendiente de IA6. No se modifican producción, `main`, V28, árbitra ni ramas ajenas.

## Bloque 09/10 — CI aprobada y certificación de pruebas

- GitHub Actions [#41726708467](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41726708467) terminó `completed/success` sobre SHA de pruebas `30ee5f992dcd3f0e640b8f844c86cfed8c10cc94`.
- Recibos exactos: `CAMP004_W01_MANIFEST_PASS reserved=10 completed=9 ids=30`; `CAMP004_W01_PY PASS blocks=9 checks=917`; `CAMP004_GATE_PY_PASS worker=W01 blocks=9 checks=917`; `CAMP004_W01_GODOT PASS blocks=9 checks=15731`; `CAMP004_GATE_GODOT_PASS worker=W01 blocks=9 checks=15731`.
- Acumulado verificado **9/10 bloques, 27 objetos, 70 escenarios, 173 pares y 519 variantes**, con controles Godot real, ausencia, reserva, consumos y SaveV2. Se conservaron todos los bloques anteriores.
- El CSV mantiene la fila 09 temporalmente en `EN_CI_AUTOMATICA` para evitar una ejecución adicional disparada por metadatos. En el siguiente bloque 10 autorizado mediante `p`, cerrar a `CI_PASS_VERIFICADO` con SHA y run oficiales antes de agregar la fila 10.
- Próxima `p`: únicamente bloque 10/10 `black_belt;charcoal;magnet`, con regresión completa de CAMPAÑA_003 obligatoria. Tras 10/10, comunicar CAMPAÑA_004_FINALIZADA y STOP. No tocar main, V28 ni ramas ajenas.
- Incidencia previa SaveV2 en fase intermedia de Rayo Solar sigue pendiente para IA6. La CI no demuestra GPU/UI ni integración global.
