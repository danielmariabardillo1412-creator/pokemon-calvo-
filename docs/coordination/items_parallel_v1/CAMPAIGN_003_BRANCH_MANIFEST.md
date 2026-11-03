# IA6 — CAMPAÑA_003 / MANIFIESTO DE RAMAS VERIFICADAS

**ACTIVADA:** sí, por autorización expresa del usuario el 2026-11-03.
**Base exacta comprobada mediante GitHub branches:** `41c1efeba0346349490f863131179ed7a8fc274c`, commit del [gate](CAMPAIGN_GATE_003.md) en la rama árbitra. Las ramas se han creado limpias, sin merge ni rebase de las anteriores.

| IA | Rama exclusiva ya existente | SHA inicial | Trabajo |
| --- | --- | --- | --- |
| IA1 / W01 | `codex/calvo-items-20261103-w01-camp003` | `41c1efeba0346349490f863131179ed7a8fc274c` | 10 bloques / 30 equipables |
| IA2 / W02 | `codex/calvo-items-20261103-w02-camp003` | `41c1efeba0346349490f863131179ed7a8fc274c` | 10 bloques / 40 bayas |
| IA3 / W03 | `codex/calvo-items-20261103-w03-camp003` | `41c1efeba0346349490f863131179ed7a8fc274c` | 10 bloques / 20 bolas, solo contratos/auditoría |
| IA5 / W05 | `codex/calvo-items-20261103-w05-camp003` | `41c1efeba0346349490f863131179ed7a8fc274c` | 10 bloques / 60 MT activas |

**IA4/W04**: CAMPAÑA_001_FINALIZADA, **ninguna rama nueva**, ningún bloque autorizado. Sus datos antiguos permanecen en `codex/calvo-items-20261101-w04`.

## Fuentes de continuidad
- [CAMPAIGN_003_QUEUE_APPROVED.csv](CAMPAIGN_003_QUEUE_APPROVED.csv): autoridad exclusiva de los IDs y 40 filas. No asignar objetos adicionales sin nueva orden.
- `campaigns/CAMP_003_W0X.md`: instrucciones por IA. Solo pruebas nuevas en rutas w0x, fixture propio y reportes `reports/W0X/CAMP_003_*`.
- `reports/W0X/CAMP_003_PROGRESO.csv`: empieza con **0 bloques**; el primer mensaje de activación ejecuta 01. Después una `p` por bloque siguiente 02 a 10.
- `CI_AUTOPILOT_V3.md` queda como histórico del patrón; el [GATE_003](CAMPAIGN_GATE_003.md) y workflow `.github/workflows/parallel-camp003-worker-autoci.yml` son la instrucción actual. Cada nueva rama parte con validador automático.

**ATENCIÓN:** un run de `BOOTSTRAP_VALIDADO_SIN_NINGUN_BLOQUE_FUNCIONAL` solo acredita archivo de workflow, propiedad de cola y conteo; ninguna mecánica. Cuando la primera trabajadora entregue sus pruebas, el push disparará Godot 4.7 y exigirá recibos de Python/Godot con el número exacto de bloques. CI `failure` no es permiso para cambiar producción.

La [orden de activación única](CAMPAIGN_003_ACTIVATION_MESSAGE.md) se debe pegar **una vez** en IA1, IA2, IA3 e IA5. **No enviar `p` suelta a las conversaciones antiguas hasta esa activación**. Después solo `p`; IA6 supervisa únicamente dependencias y resultados.

## CI de arranque verificada (2026-11-03)

Las cuatro primeras ejecuciones **con 0 bloques** terminaron `completed/success`:
- W01 [#41551945208](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41551945208), SHA `c4f60f36301ce507519cdfa99a6978e0ec5e601d`.
- W02 [#41551952771](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41551952771), SHA `b34a96396a7a28a422970ab2db9435c3d4b773e2`.
- W03 [#41551961372](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41551961372), SHA `dea12b6ca6a4925e2ae75e26a463dc154087f056`.
- W05 [#41551975872](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41551975872), SHA `24d4e41c82a30c47e6537aebf1836cb77cbc339a`.

Cada commit de arranque solo creó su `CAMP_003_BOOTSTRAP.md` local. Estos runs validaron manifiesto/propiedad/contabilidad, y **NO ejecutaron suites funcionales de Godot** al no existir aún tareas completadas. Los primeros `p` originarán nuevas ejecuciones al publicar pruebas/progreso.
