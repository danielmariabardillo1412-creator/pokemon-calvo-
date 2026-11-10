# W01 — CONTINUOUS_V2 / ESTADO OPERATIVO VERIFICADO

- **worker:** W01 / IA1
- **branch:** `codex/calvo-items-20261110-w01-gems-autobatch01`
- **mission_version:** `CONTINUOUS_V2/PLAN_W01.md` (orden copiada en `IA6_AUTORUN.md`)
- **phase:** A — completar TANDA04 (10 IDs); al cerrar la Fase A pasar sin STOP a Fase B (26 IDs en 10+10+6)
- **block:** TANDA04 equipables competitivos, **1/10 certificado, fila 02 pendiente de puerta conjunta**
- **next_id:** `life_orb` (fila 02: piloto real verde; falta resultado de CI acumulativa), luego `choice_band` (fila 03)
- **checked/functional/new/blocked:** 1/10 filas completas; 1 recorrido L3 certificado (`leftovers`); 0 objetos nuevos implementados; 0 bloqueos. `life_orb` aporta otro piloto L3 aprobado, sin contar aún como certificado global.
- **last_green_code_sha:** `197b908d949825631856d246d36144c88154ea0c`
- **last_green_run_id:** `42923382323`, `completed/success` con 7/7 jobs; Leftovers L3 Python 40/Node 4 variantes/Godot 76.
- **separate_green_pilot:** `life_orb` [CI #42926044147](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42926044147), SHA `2a8578db6a53fcb0cfe1b66b1ccc22dee1d6eb64`, `completed/success`; Python 24, Node 5 modos y Godot 92 comprobaciones con 4 recorridos L3.
- **ci_pending:** [CI acumulativa #42926374158](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42926374158), código SHA `46e4204a77743656de68d2026f6533f712c618cd`: 8 jobs; última consulta: `v4_life_orb`, `v4_leftovers`, V2, V3 y T01 SUCCESS; CAMP004 y CAMP005 aún en ejecución. **No afirmar SUCCESS global antes de comprobarlo.**
- **current_branch_note:** IA6 ha publicado sobre esta rama la orden continua V2 y este STATE inicial; HEAD `bd408a910910d3a38cc3b306b1658c20c5845350` antes del presente checkpoint documental. **No usar CI de SHA antigua para atribuir un PASS nuevo al HEAD de notas.**
- **owned_files_changed:** `tests/fixtures/parallel_items/w01_autorun_v4.json`, tests Python/Node/Godot para Restos y Vidasfera, `.github/workflows/w01-autorun-v4-held.yml`, `.github/workflows/w01-autorun-v4-life-orb-pilot.yml`, CSV/checkpoint W01 V4 y notas de piloto. No se ha modificado producción.
- **attempted_row03:** durante la preparación de `choice_band` GitHub cambió HEAD debido a la publicación concurrente de IA6; la operación de publicación falló. **No hay ningún archivo de piloto de Cinta Elegida confirmado en HEAD.** Preparar/publicar de nuevo solo después de releer HEAD, sin forzar historia.
- **protected_tickets:** ninguno; sin cambios en motor global, SaveV2, FieldItemService, otras ramas, `main`, V28 ni PR #118.
- **next_safe_action:** verificar CI `42926374158`; si 8/8 SUCCESS, marcar fila 02 `CERTIFICADO` en `AUTORUN_V4_PROGRESS.csv` con SHA funcional y CI, y continuar fila 03 `choice_band` (potencia física, bloqueo tras movimiento y reset real al cambiar). Si CI falla, revisar logs y reparar solo pruebas/fixtures/workflow propios; no reescribir las regresiones ni falsear certificados.
- **integration_IA6:** NO; una CI en W01 no sustituye integración selectiva ni pruebas cruzadas en rama árbitra.
- **checkpoint_policy:** continuar Fase A y luego Fases B/C sin nuevo relevo por cada diez; `p` reanuda desde este archivo, nunca desde supuestos de ejecución asíncrona.
