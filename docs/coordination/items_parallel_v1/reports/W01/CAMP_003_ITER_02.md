# IA1/W01 — CAMPAÑA_003, microbloque 02/10

**Rama exclusiva:** `codex/calvo-items-20261103-w01-camp003`. **Estado:** `EN_CI_AUTOMATICA` (sin certificar el nuevo SHA de pruebas). **IDs exactos:** `blunder_policy;booster_energy;cell_battery` de `CAMPAIGN_003_QUEUE_APPROVED.csv`. No se implementó ninguna nueva mecánica ni se tocó producción.

## Auditoría de fuentes anteriores y pruebas nuevas

| Objeto | Evidencia ya existente (solo lectura) | Escenarios añadidos | Control causal nuevo |
|---|---|---|---|
| `blunder_policy` (Seguro Fallo) | `held_effect_sweep_v3.cjs` `accuracy_miss_trigger` con `zap_cannon`, subida de `spe +2` **solo si hay miss** | 2 casos, 9 pares-semilla | Detectar `|-miss|` del actor y comprobar +2/consumo **condicional**, frente a golpe de precisión 100 y modos none/reserve |
| `booster_energy` (Energía Potenciadora) | `held_effect_sweep_v3.cjs` prueba `great_tusk/protosynthesis`, `iron_hands/quark_drive`, `wrong_ability` | 3 casos, 5 pares-semilla | Activación por habilidad pertinente al entrar, volátil nativo, consumo de exactamente una unidad; no activación sin habilidad y controles none/reserve |
| `cell_battery` (Pila) | `held_effect_sweep_v2.cjs` prueba `thunder_shock`, `boosts.atk == 1` y consumo | 3 casos, 4 pares-semilla | +1 Ataque real por impacto eléctrico; sin activación por golpe Normal o movimiento de estado; reserva y ausencia |

**Subtotal de este bloque:** ocho casos, 18 pares caso-semilla, 54 variantes de equipamiento. **Acumulado con 01:** 15 casos, 28 pares caso-semilla, 84 variantes. Los 7 casos del bloque 01 no fueron alterados.

**Control de precisión:** Seguro Fallo utiliza ocho semillas para contrastar resultados de `zap_cannon` según el evento de fallo que emite el simulador. No se presupone que un seed falle; se coteja cada ejecución con su log real. La prueba compara `active`, `none`, `reserve` en idéntica semilla y se mantiene estricta respecto a consumo y Speed +2.

## Archivos y commits de pruebas

- `tests/fixtures/parallel_items/w01_campaign_003.json` actualizado, commit `6d5c6f2aa592e3f9786833f345af508e5054c8c0`, blob `07ea3df454b4e83e0e71aac8887dc341c822ca53`. Nuevos campos de habilidad solo en casos aplicables; preserva 01.
- `tests/gameplay/parallel_items_w01_campaign_003.gd` actualizado, commit `0c295546387b64ced2f6f412ff1a75ab84ecd1ab`, blob `12f59a4997e8f5aebf5659af9c554e0689bb1386`. Mantiene `FieldItemService`, `Native` y restauración SaveV2; observa eventos `miss`, `boosts` y `volatiles` del checkpoint nativo.
- `tests/tools/test_parallel_items_w01_campaign_003.py` extendido, commit `963c8c772eda9775f7b9ad2f115710591131c56e`, blob `c3b5621bc757aa01839e2a2714a74ac955d19f80`. Fija ocho escenarios/semillas/abilities y rechaza desviaciones de cola, inventario y metadata histórica.
- CSV `CAMP_003_PROGRESO.csv`: bloque 01 ahora `CI_PASS_VERIFICADO` por [#41553771307](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41553771307), Godot 872 verificaciones PASS; bloque 02 `EN_CI_AUTOMATICA`. Último commit de tests/progreso `594c6772f3b64c9cabc2b31d23d435634bc53bee`.

## CI y límites

- El workflow inmutable de IA6 ejecuta contratos Python `--ci`, Godot 4.7 headless y validador de salida estricta `blocks=2`, `checks>0`. **Último run iniciado** [#41555265598](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555265598) para SHA `594c6772f3b64c9cabc2b31d23d435634bc53bee`; `pending` al redactar. Los runs más antiguos cancelados no significan PASS ni FAIL funcional.
- Auditoría estática de tres archivos con GitHub: **12/12 comprobaciones de integridad PASS**, no sustituye ejecución Python ni Godot de nuevo SHA.
- Si CI falla por especie o efecto nativo: no alterar `modules/`, `data/`, catálogo ni hooks; identificar la causa y pedir IA6 si es dependencia compartida. Si es problema exclusivo del script de pruebas, corregir sin eliminar la aserción causal y verificar nueva CI.
- No se certifican UI/GPU, vuelta a mapa, distribución estadística completa, otros formatos ni todas las habilidades.

**Siguiente `p`:** consultar primero el último run; si no hay FAIL y el bloque 02 quedó confirmado o su ejecución continúa sin dependencia, ejecutar solamente **03**: `clear_amulet;covert_cloak;eject_button`. No adelantarlo aquí.

## Incidencia de CI y corrección propia

- [Actions #41555265598](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41555265598) concluyó **FAIL en Python** con `CAMP003_W01_PY FAIL Semillas ausentes o excesivas`, antes de Godot. Causa reproducida por lectura: tope general de 4 semillas heredado del bloque 01 que rechazaba las 8 fijadas para `blunder_accuracy_event`. **No hubo fallo funcional nativo demostrado** en ese run.
- Corrección propia de contrato, **sin suprimir cobertura:** commit `95de5b7581b54183a7fd108ccf6066a1ddb32154`, valida 1–8 semillas solo para el caso de Seguro Fallo y mantiene 1–4 para los demás; el mapa `SCENARIOS_02` sigue obligando a sus 8 semillas exactas.
- La fila del CSV fue ligada al nuevo SHA de tests en commit `45e06d1b14f1969a0ee178caf42543a69139cdbb`, que dispara CI final por rama. **Estado: EN_CI_AUTOMATICA**, sin reclamar PASS de bloque 02 hasta veredicto del último run. Los runs previos `cancelled` se deben a `concurrency.cancel-in-progress`.

