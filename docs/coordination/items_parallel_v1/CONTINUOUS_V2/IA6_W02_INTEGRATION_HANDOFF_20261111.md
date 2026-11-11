# IA6 — INTEGRACIÓN SELECTIVA W02 / CHECKPOINT 2026-11-11

## Contexto recuperable
W02 terminó `CONTINUOUS_V2` de 42 bayas en su rama `codex/calvo-items-20261109-w02-mints-integration`. Cierre: CI #42937706214 SUCCESS SHA `bd2a525858a5b08ff85fc2121a23ddf6a10d7c5d`. Las bayas no se implementan otra vez y esta integración **no añade objetos**.

La rama previa IA6 `codex/calvo-ia6-integration-20261109` HEAD de partida `f4a5687bff1aaf0fb443c36ca4c2873f5d0ac54e` carecía de cuatro ajustes W02:
1. `modules/inventory/field_growth_effects.gd` — usa naturaleza efectiva para validar y evita recálculo redundante tras evolucionar;
2. `modules/inventory/field_mochi_effects.gd` — valida naturaleza efectiva;
3. `modules/creatures/progression/evolution_system.gd` — copia naturaleza efectiva y calcula stats resultantes con ella;
4. `modules/inventory/field_mint_effects.gd` — todas las 21 mentas ya probadas en W02.

Se integraron esos cuatro archivos **exclusivamente** en rama de ensayo `codex/calvo-ia6-w02-integration-20261111`, conservando otros módulos del árbol IA6, incluida la corrección propia de `modules/save/field_native_save.gd`.

## Pruebas y PR hacia IA6

- CI verde #42955006505, SHA `2f8cd72c0c95b51cf02eaeea1e599d9c74e8ed74` en staging: 43 checks IA6 W02, 65 smoke IA6 W02/W03, 18 SaveV2 nativo, 88 UI W05, 20 books/bag, 4.993 conexiones, Showdown 10 y repro W01 3.
- El siguiente commit `f3eb3248a43bfbb453bac539318cc641777b6fe3` únicamente amplió la activación del workflow para que se ejecute también sobre la rama integradora IA6; nueva CI específica #42955272137 **SUCCESS** sobre ese SHA.
- PR [#119](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/pull/119) apunta **de staging a `codex/calvo-ia6-integration-20261109`**, no a `main`; `main`, V28, PR118 y ramas trabajadoras no se han modificado.
- GitHub disparó 21 ejecuciones generales adicionales sobre SHA `f3eb3248...`: al último chequeo **19 SUCCESS, 2 IN_PROGRESS**, sin FAIL; pendientes:
  - CI #42955302952 `Item Closure V3 (EV, inventory and regressions)`.
  - CI #42955302921 `Trainer Team Composition Tests`.

## Estado y siguiente acción

**PR #119 ABIERTO / NO MERGED** mientras queden esas dos CI. No afirmar integración en la rama original IA6 ni aplicación a main.

Para reanudar con `p`:
1. consultar primero estado exacto de las dos CI pendientes y todas las ejecuciones del PR en GitHub (SHA `f3eb3248...`); identificar cualquier falla real.
2. Si todas SUCCESS, revisar HEAD PR y base; mergear **solo a la rama de integración IA6** si sigue limpio y el PR sigue mergeable. Nunca a main/V28/PR118.
3. Verificar el SHA de merge, lanzar/revisar la nueva CI sobre SHA real de la rama IA6 (workflow `ia6-w02-selective-integration-20261111.yml`) y registrar resultado. No reciclar CI de staging como certificación del commit mergeado.
4. Si falla integración o hay conflicto, mantener PR abierto y reportar causa concreta. No reescribir sistemas protegidos ni rebajar tests.

La actividad **no** constituye autorización para integrar globalmente en main; es una consolidación selectiva en la rama de IA6. No hay trabajo asíncrono de este chat.
