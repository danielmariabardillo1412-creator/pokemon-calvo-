# IA1/W01 — CAMPAÑA_005 — ITER_10 (CI PENDIENTE)

**Objetos:** `normal_gem`, `fire_gem`, `water_gem`. **Rama:** `codex/calvo-items-20261104-w01-camp005`.

Objetivo B10: validar por combate real de Showdown el boost de tipo del primer golpe, el consumo único de la gema, ausencia de activación en reserva o sin objeto, control de tipo incorrecto y de movimiento de estado del mismo tipo (`swords_dance`, `sunny_day`, `rain_dance`). No basta con comprobar metadatos.

Pruebas positivas: Mew vs Mew en `gen9calvounifiedv1` con semillas 19/23; Placaje para Gema Normal, Puño Fuego para Gema Fuego, Surf para Gema Agua. Tras el primer ataque, comprobar `held_item_consumed`, remoción de item nativo y exactamente **una** unidad física gastada; restaurar SaveV2 **entre primer y segundo ataques**, y repetir ataque real para demostrar que no reaparece ni se consume otra unidad. Restaurar SaveV2 también tras el segundo turno. Los controles sin objeto y con objeto en reserva no deben consumir ni potenciar.

Nueve escenarios nuevos, 12 pares caso-semilla, 36 modalidades; totales acumulados previstos: 90 escenarios, 272 pares, 816 variantes. Se exige además regresión completa CAMPAÑA_004 (Python/Godot), reproducible B06 y B07, y prueba nativa de B09, sin alterar `native_engine.cjs` ni subsistemas compartidos.

**Estado:** `EN_CI_AUTOMATICA` hasta confirmar `completed/success` y recibos Python, Godot y CAMP004 sobre el mismo SHA. Si la CI falla, no declarar `CAMPAÑA_005_FINALIZADA`: documentar reproducción y reparar solo lo autorizado, o elevar dependencia a IA6.
