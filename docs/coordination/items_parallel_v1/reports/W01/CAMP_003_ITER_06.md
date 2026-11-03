# IA1/W01 — CAMPAÑA_003 — Microbloque 06/10

**Estado:** ENTREGADO; CI acumulativa pendiente. **Rama exclusiva:** `codex/calvo-items-20261103-w01-camp003`. IDs autorizados por IA6: `grip_claw;heat_rock;heavy_duty_boots`.

## Cobertura nueva

| Objeto | Referencia existente (solo lectura) | Pruebas añadidas |
| --- | --- | --- |
| Garra Garfio (`grip_claw`) | `tools/item_audit/held_effect_sweep_v3.cjs`: `partial_trap_duration` | Infestación más seis turnos con Reflejo: verificar siete daños residuales y mayor daño al portador; Tackle no atrapa; activo/ausente/reserva |
| Roca Calor (`heat_rock`) | `held_effect_sweep_v3.cjs`: `weather_duration` con `sunny_day` | +3 turnos de sol según estado nativo, sin efecto ni consumo con Reflejo; controles de portador y reserva |
| Botas Gruesas (`heavy_duty_boots`) | `tools/item_audit/held_pilot.cjs`: Trampa Rocas y dos cambios reales | Tras Trampa Rocas, cambio a reserva y regreso: solo Pokémon con botas mantiene PS; sin peligros de entrada no hay daño; no consumidas |

**Incremento:** 6 casos, 9 pares caso-semilla y 27 variantes. **Acumulado 01..06:** 42 casos, 89 pares, 267 variantes. Cada ejecución reutiliza el motor nativo, los servicios de equipamiento y el mecanismo de restauración SaveV2; no se añadió ninguna regla de combate.

## Publicación y pruebas

- Fixture: `tests/fixtures/parallel_items/w01_campaign_003.json`, blob `fdad6ee5d646f470e8050c034a3edd023a5116fd`; commits `99f7d1c893bbfed321c1bf3d7ce2918853fcf9fa` y `4378ee810e86bf6635a4b8ca916764f86b7d912a`. Fuente nueva del piloto Git blob `c8a59a18f546d772ff34e4f8640a4246a00a822b`.
- Runner Godot: blob `76546c05325c8ad09834c034c98d523fd9deedd7`, commit `7c1f662b144629b600d933dd2231f22de9988050`. Ejecuta los siete turnos de atrapamiento y los dos cambios de Pokémon; verifica el estado nativo y SaveV2.
- Contrato Python: blob `4ec0f71a1b39c4dba986d10eeb352c6a865eed30`, commit `99bbfa8117f8b30a2c4d0f0d05caee7a70696c5b`. Exige IDs, causas, semillas y hashes de fuentes históricas.
- CSV progreso: 6 filas, commit `d76dfb5fc3ed0621b5c171a5a02da0046731803c`.
- Auditoría estructural: **24/24**, no equivale a pruebas ejecutadas de Godot/Python.

**CI:** bloques 01..03 verificados, último run exitoso [#41556859548](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41556859548) con 3217 verificaciones. Runs 04 [#41558549785](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41558549785) y 05 [#41559578486](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41559578486) cancelados por nuevos pushes, por lo que siguen **pendientes de revalidación**; no se presume PASS. Run 06 [#41560388772](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41560388772), aún sin veredicto al publicar. Exigir `CAMP003_W01_PY/GODOT PASS blocks=6` y conclusión exitosa.

**Fuera de alcance:** pruebas GPU/UI, liquidación de combate y mapa, todos los estados posibles. Ninguna modificación a producción, `main`, V28, workflows, catálogo o ramas ajenas. Ante fallo de simulador/SaveV2 compartido, STOP y escalar a IA6.

**Siguiente `p`:** comprobar CI; ejecutar solo bloque 07 `iron_ball;lagging_tail;light_clay` si no hay fallo real no resuelto.
