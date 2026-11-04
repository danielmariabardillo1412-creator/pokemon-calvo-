# IA6 — recuperación CI y arranques W01/W02/W04 (2026-11-04)

Verificación directa de GitHub Actions, no solo mensajes de los chats trabajadores. No se editó `main`, V28, PR118 ni código de producción.

## IA2/W02 — puerta CAMP005 recuperada
- Rama `codex/calvo-items-20261104-w02-camp006`.
- Run [#41763921080](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41763921080), SHA `2abcc2ae9644b8821d9dae6f26214b1a8fa347fc` **completed/success**. Job `126357720929` aprobó `Recuperación integral Python CAMP005 10/10`, `Recuperación integral Godot CAMP005 10/10`, `Prueba nativa Godot CAMP006 01/10` y `Regresión CAMP004 y CAMP003 - Python y Godot`.
- La falla antigua [#41742682811](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41742682811) tenía dos aserciones erróneas `exp_candy_xl_level99_gain` (activo y reserva). Los 30.000 XP no cubren la brecha de 32.757 XP nivel 99→100; el fallo agregado `relaxed_mint_level100: bloque íntegro` no prueba defecto separado en la menta. Se conservan 288 escenarios y caso 50XP-al-tope.
- **Decisión IA6:** bloque01 CI recuperada, autorizar bloque02 de CAMP006. La naturaleza efectiva sigue sin handler; no inventar funcionalidad.

## IA4/W04 — CI nueva, integración L3 comprobada
- Rama `codex/calvo-items-20261104-w04-camp006`.
- IA6 creó el workflow `.github/workflows/parallel-camp006-w04-autoci.yml`, commit `73db15112ac09b641e25a050bb59f344030edf28`. Run [#41767573680](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41767573680) **completed/success**; log `CAMP006_W04_PY PASS blocks=1 checks=52`, `CAMP006_W04_GODOT PASS blocks=1 checks=91`, regresión `CAMP005_W04_PY PASS blocks=10 checks=673`, `CAMP005_W04_GODOT PASS blocks=10 checks=1423`.
- La prueba ejecutó demo `field_demo.tscn`, mochila, servicio y SaveV2 sobre tres evoluciones positivas ya existentes: `sweet_apple` → Appletun, `tart_apple` → Flapple, `syrupy_apple` → Dipplin. **L3 certificado dentro del headless**, no supone revisión visual de PC ni merge.
- **Decisión IA6:** autorizar bloque02 CAMP006. Cuando cambie progreso de 01/10 a 02/10, W04 debe adaptar las comprobaciones acumulativas del runner y estado CI, sin relajar los casos anteriores.

## IA1/W01 — workflow recuperado, ejecución pendiente de cierre
- Rama `codex/calvo-items-20261104-w01-camp005`.
- IA6 creó `.github/workflows/parallel-camp005-w01-autoci.yml`, commit `bd33aeb3f993804c3c85217b81892356af39aac5`.
- Run [#41767517526](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41767517526): **en ejecución durante este registro**. Completadas con `success` la puerta de identidad, preparación, `CAMP005 Python equipables` y `CAMP005 Godot portador tipo daño y SaveV2`. En ejecución regresión `CAMP004 completa obligatoria al inicio y en hitos`.
- **Decisión IA6:** el bloque01 sigue `PENDIENTE_CI_GLOBAL` hasta `completed/success`. No autorizar bloque02 anticipadamente. La prueba y el progreso del bloque01 fueron publicados por W01 en commit `201eca50768d6a090c8542bc6f4aabdf0aa50d70`; el workflow es un commit posterior de la misma rama, sin modificar producción.
- Al publicar bloque02, W01 debe ampliar el runner acumulativo, que actualmente valida 01/10; nunca reescribir los recibos previos para simular ejecución.

## Notas de propiedad
- IA6 ha escrito **solo workflows de CI en ramas W01 y W04** y este informe en árbitra; no editó `main`, V28 ni producciones.
- La cola CAMP006 W04 está en la rama árbitra; la copia local de su rama sigue ausente tras una denegación previa. La prueba 01 funciona sin esa copia y su runner valida los IDs; no intentar evadir controles al sincronizar archivos.
- W03/W05 tienen CI propia; ninguna intervención en ellas.
