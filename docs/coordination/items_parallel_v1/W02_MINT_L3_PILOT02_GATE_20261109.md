# IA6 — AUTORIZACIÓN W02 / PILOTO MINT-L3 02 · 2026-11-09

**Emite:** IA6, árbitra de Pokémon Calvo. **Trabajadora:** IA2/W02. **Rama de trabajo exclusiva:** `codex/calvo-items-20261109-w02-mints-integration`. **No se crea CAMPAÑA_007 ni rama nueva.** Mantener `main`, V28, PR #118, rama árbitra y ramas ajenas sin cambios.

## Precondición verificada

- Piloto MINT-L3 01 cerrado, tres IDs `lonely_mint`, `mild_mint`, `naive_mint`, commit funcional `9e2797a4972f22dbf14d5bc5f2d24bb212d29456`, [CI #42696681590](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42696681590) `completed/success`, Python 35, Godot 180. HEAD documental `1a550eb774736d89e6161d4a981559726e40e046`; la ausencia de nueva CI en este HEAD es esperable: `[skip ci]` y no cambia producción.
- IA6 ya llevó esas tres mentas al árbol mixto, mantuvo Cuerda Huida, Transformación y el panel de libros, y corrigió en el carril IA6 la validación de naturaleza efectiva del guardado de mundo. Evidencia conjunta [#42701239557](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42701239557) `SUCCESS`. **Ese arreglo de `modules/save/field_native_save.gd` es propiedad IA6**, no copiarlo ni editarlo en W02.
- CAMP006 W02 queda cerrada 10/10; `exp_share` sigue L1, pendiente IA6; `hasty_mint` y `lax_mint` todavía son dependencias históricas, no activarlos en este piloto para no falsear la regresión de CAMP006.

## Trabajo inmediato autorizado — MINT-L3 02, UN SOLO MICROBLOQUE

**Tres nuevos IDs exactamente:**
1. `adamant_mint` → naturaleza efectiva `adamant` (**+Ataque, −Ataque Especial**).
2. `modest_mint` → naturaleza efectiva `modest` (**+Ataque Especial, −Ataque**).
3. `timid_mint` → naturaleza efectiva `timid` (**+Velocidad, −Ataque**).

`ProgressionRuleset.NATURE_MODIFIERS` contiene las tres naturalezas; verificar que los tres objetos están permitidos en catálogo/política antes de activarlos. **No inventar ningún ID, datos, ratio o efecto.** Si alguno falta en el catálogo autorizado, abrir bloqueo concreto y no darlo por funcional.

Implementar el cambio mínimo únicamente en `modules/inventory/field_mint_effects.gd::MINTS` si se confirma que las rutas compartidas de `FieldItemService` y `CreatureInstance` ya admiten los tres casos. Conservar todos los mapeos anteriores (naughty/gentle/lonely/mild/naive/rash/sassy/serious).

### Pruebas obligatorias

- Prueba positiva auténtica `FieldItemService.use_item` por cada ID, tanto PARTY como STORAGE; rechazo sin stock y objetivo de slot inválido, estado temporal de combate inválido, nivel 100 válido cuando cambien estadísticas, criatura debilitada, estado incoherente y repetición `item_has_no_effect`.
- Comparar ambos modificadores con `StatCalculator.compute` independiente; `nature_id` original no cambia, `effective_nature_id` sí; conservar identidad, PS actuales/máximos, especie, IV, EV, experiencia, PP y propiedad.
- Descuento exactamente **uno** solo cuando hay efecto real; ningún descuento en rechazos o efecto idéntico. Sustitución secuencial de una menta del piloto 01 por una del piloto 02 (sin doble gasto), guardado y carga SaveV2 de snapshot propio; caso legacy sin `effective_nature_id` y corrupto rechazado.
- Añadir fixture y runners **nuevos, propios y acumulativos**: `tests/fixtures/parallel_items/w02_mint_pilot02_20261109.json`, `tests/tools/test_parallel_items_w02_mint_pilot02_20261109.py`, `tests/gameplay/parallel_items_w02_mint_pilot02_20261109.gd`. No reemplazar el piloto 01.
- Ampliar `.github/workflows/parallel-w02-mint-integration-20261109.yml` con una etapa estricta del piloto 02 y ejecutar todos los pasos anteriores. No usar `BOOTSTRAP_ONLY` como PASS funcional. Recibos distinguibles `W02_MINT_PILOT02_20261109_PY PASS checks=...` y `W02_MINT_PILOT02_20261109_GODOT PASS checks=...` en un SHA concreto.

### Regresión histórica: regla de no falseamiento

Los validadores existentes de CAMP006 y MINT-L3 01 **prohíben explícitamente** algunos IDs aún sin efecto. Como esta orden cambia el estado de `adamant_mint/modest_mint/timid_mint`, se autoriza ajustar **solo las comprobaciones de prohibición estática** para exceptuar esos tres ID ahora autorizados y exigir su mapeo positivo exacto. Conservar todos los restantes (en particular `hasty_mint`, `lax_mint`, `relaxed_mint`), y mantener sin alterar los **fixtures y recibos históricos** y sus rechazos originales. No eliminar casos negativos funcionales, no reducir escenarios, no reescribir CI pasada para presentarla como ejecución actual.

### Límites y entrega

- No editar `StatCalculator`, `ProgressionSystem`, `FieldGrowthEffects`, `FieldMochiEffects`, `SaveGameData`, `SaveGameRepository`, `field_native_save.gd`, backend Showdown, `FieldItemBag` ni otros componentes compartidos. `FieldItemService` y `CreatureInstance` solo lectura salvo nueva autorización. Ante fallo por otro consumidor, entregar caso rojo y API mínima a IA6.
- Probar lo que se puede en W02: ruta de servicio, propiedad y SaveV2 real. No atribuirte el flujo de guardado nativo de mundo o GPU que solo certifica IA6 en la rama conjunta.
- Publicar informe `reports/W02/MINT_L3_PILOT_02_20261109.md` con SHA, run, pruebas, positivos/negativos y dependencias; **detenerse después del piloto 02**. La siguiente `p` ejecuta únicamente este microbloque. La siguiente tarea requiere nueva puerta IA6.

**Prioridad:** desarrollar efectos positivos reales y mantener la regresión acumulativa; ninguna repetición de CAMPAÑA_006 ni trabajo en `exp_share` mientras IA6 no cierre su contrato de participación.
