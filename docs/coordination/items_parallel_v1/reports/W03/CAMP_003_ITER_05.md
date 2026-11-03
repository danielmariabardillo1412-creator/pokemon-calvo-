# IA3/W03 — CAMPAÑA_003, microbloque 05/10

**Rama exclusiva:** `codex/calvo-items-20261103-w03-camp003`. **Fila IA6:** `05,W03,CAPTURE_BALL,fast_ball;dream_ball`; autorizado solo auditar, documentar y crear tests. Sin ediciones en producción ni catálogo.

## Reutilización y cobertura nueva

`CaptureBallEffects` ya reconoce los dos objetos (`modules/capture/capture_ball_effects.gd`, blob `4e96b60ffe7b947817774d630b8e8afcca8d8591`). La matriz histórica V11 de 10.760 escenarios y la distinción sueño/Bostezo existen en `tests/gameplay/item_capture_v11.gd`, blob `44ad0d5fe48bd81239ecea9b57bb6690817af6a1`. **Estado:** `YA_VERIFICADO_NO_DUPLICAR`. No se ha repetido esa matriz ni implementado lógica nueva.

- **Rapid Ball / fast_ball:** Pikachu (velocidad base 90, ×1), Mew (100, ×4) y Raichu (110, captura 75, factor limitado a 255/75 = ×3,4). Contraste sobre `species.base_speed`, nunca estadísticas del individuo, y factor de captura final con PS completos/1 PS.
- **Ensueño Ball / dream_ball:** normal ×1, Bostezo volátil ×1, sueño persistente ×4. El sueño además proporciona bonus general de estado ×2, comprobado independientemente; no es un segundo multiplicador de Ensueño. Dos especies (Mew/Caterpie), PS completos/1 PS.
- **Integración:** para ambos objetos, `CaptureInventoryService.resolve` real, misma semilla en RNG independiente y del motor, probabilidad según `calvo_capture_v1`, consumo exacto de una bola, tirada única, resultado, identidad y estado del Pokémon.
- **Negativos:** entrenador, bola no poseída y Pokémon debilitado. Rechazo `INVALID`, sin consumo ni avance RNG, sin mutación del objetivo o equipo.

## Archivos publicados y evidencia

| Archivo autorizado | SHA del blob |
| --- | --- |
| `tests/fixtures/parallel_items/w03_campaign_003.json` | `0aa75d9f67bdc6d7c04693db58675628604819f7` |
| `tests/gameplay/parallel_items_w03_campaign_003.gd` | `66bba61156102ddc7f3d668b683f5881cd49db55` |
| `tests/tools/test_parallel_items_w03_campaign_003.py` | `bb6460ee07c63b496a6d85fa57f2b273b0b3af49` |
| `reports/W03/CAMP_003_PROGRESO.csv` | `922ccad449b1c845f6fd04b2caa0f425e501bc22` |

El CSV conserva bloques 01–04, añade únicamente 05 y dispara CI con SHA `d3a9ce8bee76564a18cc5e997cdcd0bef5dd5c74`; [GitHub Actions #41559647462](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41559647462).

**Estado al publicar:** `EN_CI_AUTOMATICA`, sin veredicto nuevo todavía. La revisión estructural de rutas/dispatcher/fixture/Python fue correcta, pero **no es ejecución funcional**. El workflow debe mostrar `CAMP003_W03_PY PASS blocks=5 checks=M` y `CAMP003_W03_GODOT PASS blocks=5 checks=M` para dictaminar PASS. Última CI anterior: [#41558471582](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41558471582), 4 bloques, 122 Python + 490 Godot PASS.

**Próximo `p`:** verificar resultado de la CI del 05 y ejecutar solo la fila oficial 06. Si el fallo es de tests propios, repararlos sin quitar verificaciones; si surge fallo de producción/contrato compartido, detenerse y solicitar IA6. No tocar `main`, V28, otras W o workflows.
