# IA1/W01 — CAMPAÑA_005 — BLOQUE 09 (pendiente de CI)

**Rama:** `codex/calvo-items-20261104-w01-camp005`. **Estado:** `EN_CI_AUTOMATICA`, sin certificación funcional todavía.

**Objetos:** `sea_incense` (Incienso Marino), `full_incense` (Incienso Lento) y `lax_incense` (Incienso Suave).

- Marino: incremento real de ataques de Agua con `water_gun`, sin aumento de `tackle` ni de `reflect`.
- Lento: Mew más veloz actúa al final si ambos comandos tienen prioridad normal; con `quick_attack` (+1) conserva la prioridad superior. Sin daño o consumo añadido.
- Suave: medir `|-miss|p2a:` real del simulador frente a Placaje de precisión nominal 100; exigir fallos y aciertos naturales, sin alterar RNG. Golpe Aéreo infalible y Amnesia como controles negativos.
- Todas las modalidades (activo/ausente/reserva), titularidad, identidad, dos unidades no consumidas, SaveV2 completo mediante el runner heredado.

Nuevos: **9 escenarios, 26 pares semilla-caso, 78 carriles**. Acumulado: **81 escenarios, 260 pares, 780 carriles**. Reproductor B09 independiente ejecuta 64 semillas nativas para auditar ambas ramas RNG, velocidad de ejecución y daño de agua; no inventa estadísticas ni sustituye los casos Godot.

Los 72 casos previos quedan íntegros; no se modifica producción, el parche `native_engine.cjs`, políticas de combate ni SaveV2. CAMP004 se conserva; la última regresión completa fue `42679854792`; siguiente hito obligatorio 10 salvo edición de producción.

**Certificado pendiente:** run y SHA de GitHub Actions que ejecuten ambos runners con éxito. Si hay fallo, se repara el bloque 09 antes de avanzar a 10. Sin necesidad de autorización de IA6 salvo modificación de subsistema compartido.
