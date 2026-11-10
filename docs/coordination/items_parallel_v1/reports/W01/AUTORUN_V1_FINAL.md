# IA1/W01 — AUTORUN V1 — TANDA 01 FINALIZADA

**10/10 filas examinadas; 10/10 funcionales; 0 bloqueadas.** Documentación de cierre posterior al certificado, sin trasladar la certificación a un commit distinto.

- Rama: `codex/calvo-items-20261110-w01-gems-autobatch01`.
- **SHA funcional exacto:** `9d1a9dae8b9d9abed09a12b082f7a719aa047981`.
- **CI funcional:** [#42730773059](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42730773059), `completed/success` sobre ese mismo SHA. `autorun_gems` y `historical_regression` PASS.
- `W01_AUTORUN_NATIVE PASS rows=10 activations=20 negatives=20 reentries=20 pp_checks=120 snapshots=120`.
- `W01_AUTORUN_PY PASS rows=10 checks=85`.
- `W01_AUTORUN_GODOT PASS rows=10 checks=4002`, incluyendo SaveV2, tres modalidades de propiedad, consumos y controles.
- CAMPAÑA_005 y CAMPAÑA_004 reejecutadas completas en el job `historical_regression` — SUCCESS.

**IDs certificados:** `electric_gem`, `grass_gem`, `ice_gem`, `fighting_gem`, `poison_gem`, `ground_gem`, `flying_gem`, `psychic_gem`, `bug_gem`, `rock_gem`.

El inventario y perfiles nativos ya existían; los nuevos recibos certifican su efecto en combate a través de pruebas, no una modificación innecesaria de producción. No se edita ningún fixture ni runner histórico; `main`, V28, PR #118 y ramas ajenas sin tocar. No significa merge ni prueba de interfaz gráfica.

**Cierre administrativo:** el CSV se marca `CERTIFICADO` mediante commit documental posterior; sus celdas `sha_pruebas` y `ci_run` apuntan SIEMPRE al commit funcional original y su CI real. IA6 ha publicado la TANDA 02 en `IA6_AUTORUN.md`; se trabajará en nuevos archivos `w01_autorun_v2`.
