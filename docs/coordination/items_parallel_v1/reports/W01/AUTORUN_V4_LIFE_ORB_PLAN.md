# W01 TANDA04 · fila 02 Life Orb (preparada, sin CI)

- **Base:** TANDA04 activa, rama `codex/calvo-items-20261110-w01-gems-autobatch01`.
- **Hito 01 Restos:** pruebas específicas `v4_leftovers` SUCCESS sobre SHA `197b908d949825631856d246d36144c88154ea0c`; CI global `42923382323` debe terminar con siete jobs SUCCESS antes de marcar `CERTIFICADO`.
- **Hito 02 Vidasfera:** fuentes del motor nativo `lifeorb` ya pilotadas en `tools/item_audit/held_pilot.cjs`; L1 seleccionado + holdable. No computar objeto nuevo sin efecto de producción faltante.
- **Pruebas preparadas:** `repro_w01_autorun_v4_life_orb_native.cjs` verifica daño aumentado, retroceso 1/10, inmunidad de Gengar, movimiento de estado, reserva, `prepare` puro y snapshots. `parallel_items_w01_autorun_v4_life_orb.gd` prueba equipamiento real, SaveV2 antes, sesiones nativas, daño/retroceso, victoria real, `settle_finished_battle`, SaveV2 después, identidad de titular.
- **Estado:** archivos preparados, **NO CI de fila 02**, ningún efecto nuevo certificado; workflow V4 todavía no referencia estos dos archivos para preservar la ejecución de fila 01 y sus regresiones.
- **Siguiente paso:** comprobar CI global `42923382323`; cuando esté finalizada, añadir job `v4_life_orb` a workflow con Python+Node+Godot y mantener siete jobs anteriores; crear nueva CI y validar sobre HEAD de ese commit. Si fallo, corregir solo tests propios en máximo tres iteraciones. No tocar producción protegida.
