# IA1/W01 — CAMPAÑA_002 · ITER_03 — SaveV2 y recibos de restauración

**Estado de entrega:** ITER_03 PUBLICADA, `EN_CI_AUTOMATICA`. **No afirmar PASS de ITER_03 hasta comprobar workflow para SHA de tests.**
**Rama única:** `codex/calvo-items-20261102-w01-camp002`. **Autoridad:** `CAMP_002_W01.md`; `CI_AUTOPILOT_V3.md` en árbitra. La `p` recibida autoriza este bloque 03, no un 04.

## Cambios y observaciones
- `tests/gameplay/parallel_items_w01_campaign_002.gd`: para cada `id/seed/mode` guarda checkpoint y propietario con `_restore_probe` de V28, cierra sesión, decodifica SaveV2, restaura sesión nativa y coteja **snapshot exacto**, fotograma native, propietario inalterado y stock físico.
- `tests/tools/test_parallel_items_w01_campaign_002.py`: cada variante exige **dos recibos** `<id>_<seed>_<mode>.json` y `<id>_<seed>_<mode>_savev2.json`, cada uno con SHA-256 verificable; el segundo debe contener exactamente el mismo checkpoint que el primero. Rechaza ausencia de archivos, divergencia de hash, propiedad, restauración y consumo.
- **Cobertura:** `ability_shield` 2 escenarios/3 semillas; `absorb_bulb` 3/4; `adrenaline_orb` 2/3. TOTAL 7 escenarios, 10 ejecuciones, 30 variantes; potenciales **60 recibos** si todos los tests terminan.
- Se preserva la corrección previa del runner `W01_C002_OUTPUT`, blob inicial confirmado `cc9fb835e5e999e991e1aa5ac58056ec5855da97`; motor `@pkmn/sim`, catálogo, selección, SaveV2 y servicios originales SIN MODIFICAR.
- Commits de tests ITER_03: Godot `72f15884b29a94054220baf0a4208eb9b294347a`; Python `ee760fc8aebe7fb9d5700aadf25053c13a43f6b7`.
- Blobs Git de tests ahora: fixture `74c91b2cfb69d7525ee4d42cc1e57f442c4a808d` (intacto); runner `a020292d65f2d4f09e12d6716d15101a8f32a500`; Python `27bd3bc373db74bc3c93298b07e30e71df129188`.
- **Auditoría estática al publicar:** 22/22 invariantes comprobados desde blobs GitHub: IDs, semillas, tres modos, SaveV2, hashes, stock, control de consumo y contrato nativo. **No es ejecución Godot/Python del nuevo SHA**.

## Pruebas verificadas y prueba nueva
- ITER_01: CI [#41484879741](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41484879741) SUCCESS, 7 casos, 10 ejecuciones, 30 variantes en contrato Python; sin Godot W01.
- ITER_02: staging [#41493879869](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41493879869) PASS Godot 687 checks, 10 ejecuciones, 0 errores y recibos Python 30/30. CI automática de rama [#41539775567](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41539775567) `completed/success` en SHA `69e017d5697f2d0279557b8c60def6ab623ad511`.
- ITER_03: nueva ejecución automática disparada por los pushes de tests; último run asociado al validador `ee760fc8...`: [#41547041337](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41547041337). **EN_CI_AUTOMATICA al redactar**; no utilizar el PASS de ITER_02 para certificar SaveV2 recién añadido. El run de push anterior puede cancelarse por `concurrency`.
- Workflow propio ya instalado por IA6 exige Godot PASS y `--native` con exit code 0. Si fallan las restauraciones o el motor compartido, conservar artefactos y detenerse; cualquier modificación posterior necesita orden de corrección concreta.

**Pendiente fuera del contrato:** inspección GPU/UI, asentamiento de victoria en mapa, trucos/cambio de portador, todas las habilidades y situaciones de batalla, y guardado del usuario real. ITER_03 solo restaura SaveV2 dentro de batalla aislada.

**Cierre obligatorio:** `CAMP_002_FINAL.md`, CSV 03/03 y cuaderno W01; `CAMPAÑA_002_FINALIZADA` como entrega. STOP hasta orden nueva de IA6; no modificar `main`, V28, ramas ajenas, W04 ni producción.
