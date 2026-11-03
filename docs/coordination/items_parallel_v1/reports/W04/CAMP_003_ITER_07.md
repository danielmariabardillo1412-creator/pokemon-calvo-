# IA4/W04 — CAMPAÑA_003 / Microbloque 07

**Fecha:** 2026-11-03. **Rama exclusiva:** `codex/calvo-items-20261103-w04-camp003`.

**IDs autorizados:** `galarica_cuff`, `galarica_wreath`, `peat_block`.

**Estado de entrega:** 07/10 publicados; `EN_CI_AUTOMATICA`. No declarar PASS del bloque 07 hasta finalizar su propia CI.

## Puerta previa: bloque 06
La ejecución real de GitHub Actions [#41570072932](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41570072932) (SHA `2703d9692cf3c1101ae494575af2bc8b29942d09`) terminó `completed/success` con `CAMP003_W04_PY PASS blocks=6 checks=67` y `CAMP003_W04_GODOT PASS blocks=6 checks=102`, incluyendo evoluciones positivas de `auspicious_armor` (Charcadet a Armarouge), `malicious_armor` (Charcadet a Ceruledge) y `metal_alloy` (Duraludon a Archaludon). La CI de bloque 05 también está acreditada por [#41565823249](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41565823249).

## Pruebas acumulativas añadidas
- Runner `tests/gameplay/parallel_items_w04_campaign_003.gd`, commit `6cf17867a995ed4e999d4b4f5b359e31f6c0728f`: añade bloque 07 preservando 01–06. Evalúa registros evolutivos reales con `EvolutionSystem.classify_record`, aplica positivos y SaveV2 solo para rutas `TRIGGER_USE_ITEM` y `RUNTIME_SUPPORTED`, y comprueba el rechazo condicionado sin consumo cuando hay condiciones no ejecutables.
- Negativo nuevo sobre una especie real del catálogo (Eevee) sin evolución por estos tres objetos: verifica `evolution_options` vacío, `evolve` rechazado, cantidad constante 2 y serialización `SaveGameData` sin cambios. No supone que la región, la luna ni otras condiciones estén implementadas.
- Fixture `tests/fixtures/parallel_items/w04_campaign_003.json`, commit `33c8bc355ad5e8dba280e265a4dbc9d33fe8fbb6`.
- Validador `tests/tools/test_parallel_items_w04_campaign_003.py`, commit `36b51e2b304c21363e0ab3b750a109824db4ab12`: exige progreso 07, IDs correctos, fixture concordante y presencia de aserciones negativas.
- Progreso reconciliado con CI histórica de bloques 05 y 06 y fila 07 registrada, commit `5f71282d1d77e89610a586618c95bd666991478a`.

## Restricciones y comprobación pendiente
No se ha editado producción, motor, guardados, catálogo, políticas, workflow, `main`, V28, otra rama ni objetos fuera de la cola W04. Evolución regional de Slowpoke y requisito nocturno/lunar para Ursaring **no se dan por funcionales solo por existir sus objetos**: se clasifican mediante las reglas reales y cualquier ausencia de modalidad queda como dependencia.

**Ejecución 07:** la publicación del progreso activa GitHub Actions en la rama; verificar el nuevo `head_sha` y los recibos `CAMP003_W04_PY PASS blocks=7 checks=M` / `CAMP003_W04_GODOT PASS blocks=7 checks=M` antes de afirmar éxito. Si falla el runner, corregirlo sin debilitar las aserciones según `AUTONOMOUS_REPAIR_V5.md`.

**Próximo bloque por `p`:** 08/10: `chipped_pot`, `cracked_pot`, `masterpiece_teacup`, salvo fallo real pendiente.
