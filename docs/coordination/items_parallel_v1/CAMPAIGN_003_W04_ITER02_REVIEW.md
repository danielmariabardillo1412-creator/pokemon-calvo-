# IA6 — REVISIÓN DE W04, CAMPAÑA_003 bloque 02 y autorización del 03
**Fecha:** 2026-11-03. **Estado:** CI_DE_TESTS_PASS; DEPENDENCIA_OVAL_DOCUMENTADA; ITER_03_AUTORIZADO_CON_LIMITES.

## Verificación concreta en GitHub
- Rama de IA4 `codex/calvo-items-20261103-w04-camp003`; informe `reports/W04/CAMP_003_ITER_02.md`, progreso de **02/10**, HEAD documental `76b00bcb9f5ec0b13a35bc2d756d10328692c8c7`.
- [GitHub Actions #41556682246](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41556682246) **`completed/success`** en SHA de tests `75d50b9918660bf051132be6150fc44ae0a5d4b0`. Logs reales: `CAMP003_W04_MANIFEST_PASS reserved=10 completed=2 ids=30`, `CAMP003_W04_PY PASS blocks=2 checks=29`, `CAMP003_W04_GODOT PASS blocks=2 checks=54`, recibos estrictos por validador. HEAD posterior de IA4 cambia solo informe/cuaderno; no atribuir un PASS a pruebas posteriores inexistentes.
- IDs del bloque 02: `sun_stone`, `oval_stone`, `black_augurite`. Los resultados acreditan comprobación de catálogo, rutas directamente compatibles si existen y negativas; **no certifican que los tres tengan evolución jugable en su modalidad**. El runner registra explícitamente dependencias cuando encuentra reglas que no son `use_item`.

## Decisión sobre Piedra Oval
En `modules/creatures/progression/evolution_system.gd`, `classify_record()` solo considera `RUNTIME_SUPPORTED` un trigger admitido cuyas condiciones también son compatibles. `_conditions_are_runtime_compatible()` rechaza cualquier condición adicional distinta de `base_form` y `relative_physical_stats` en su modalidad permitida. En `modules/inventory/field_item_service.gd`, `evolution_options()` expone rutas `TRIGGER_USE_ITEM`, no todas las rutas por nivel con objeto equipado/tiempo. Por tanto es **correcto documentar `oval_stone` como `DEPENDENCIA_DE_CONTRATO`** cuando no existe ruta compatible, no inventar que su mera utilización en bolsa evoluciona la especie.

Esta dependencia **no bloquea la auditoría/test de otros IDs independientes**. No autoriza cambiar `EvolutionSystem`, `FieldItemService`, progresión ni guardados, ni sustituir la condición real por `use_item`. Si IA4 quiere implementar evolución por nivel con Piedra Oval, requiere gate funcional específico IA6; queda fuera de la campaña de solo pruebas.

## Instrucción operativa a IA4
**Autorizo continuar con una sola `p` para el microbloque 03/10**, de su cola exclusiva `CAMPAIGN_003_W04_ADDENDUM_QUEUE.csv`: `dragon_scale;dubious_disc;electirizer`. Debe mantener la dependencia `oval_stone` sin declararla resuelta, conservar todas las pruebas/recibos de 01–02, y revisar la CI de la última rama antes de publicar. Cualquier objeto de intercambio/evolución condicionada necesita contrato real; si falta, registrar `DEPENDENCIA_DOCUMENTADA` con evidencia, NO crear trigger falso ni cambiar producción.

Se mantiene **CI automática por rama y regla de `p` sucesiva hasta 10**, sin autorización extra por estados `queued/in_progress` siempre que el nuevo bloque sea independiente. En `failure` real: reparar tests propios sin reducir exigencia, o STOP si es defecto de producción/contrato compartido. Si se repite un STOP administrativo solo por esperar CI, remitir a esta decisión y al gate principal.

**Otras trabajadoras:** ninguna recibe nuevos IDs ni se altera su cola. IA1 e IA2 tienen CI nueva en curso; IA3 CI 04 PASS; IA5 CI 05 en curso. No tocar `main`, V28, PR #118 ni ramas worker desde IA6.
