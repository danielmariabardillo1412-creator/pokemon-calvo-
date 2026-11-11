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

## Corrección de estado — comprobación completa del PR #119

El checkpoint anterior de 19 SUCCESS y 2 IN_PROGRESS queda **superado y sustituido** por estos resultados definitivos, verificados en GitHub para el mismo HEAD `f3eb3248a43bfbb453bac539318cc641777b6fe3`:

- **20/21 workflows SUCCESS**. `Trainer Team Composition #42955302921` y build Windows concluyeron SUCCESS.
- **1/21 workflow FAILURE:** [Item Closure V3 #42955302952](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42955302952), en dos jobs `Declarative item families` (Windows y Linux).
- Mensaje reproducido en ambos: `ITEM_AUTOMATION_V28 FAILED checks=0`, `Outside exact allowlist`.
- El guardia de `tools/item_audit/automation_v28.py` define `BASE=47f42aef1a518eefb744ad310f89b6e2d3ce7108` y rechaza cualquier archivo no incluido en `ALLOWED` al comparar **todo el checkout** contra BASE, sin llegar a las verificaciones funcionales.
- **Preexistencia demostrada por comparación de commits**: la rama base de IA6, SHA `f4a5687bff1aaf0fb443c36ca4c2873f5d0ac54e`, difiere de ese BASE en **295 archivos**, entre ellos `native_engine.cjs`, `creature_instance.gd`, `field_item_service.gd`, `field_native_save.gd`, todos fuera del allowlist. La rama PR #119 suma 300 rutas diferentes contra BASE. El fallo se reproduciría en el punto de partida IA6: no está causado únicamente por las cuatro reparaciones W02.
- **Pruebas relevantes verdes en HEAD exacto del PR**: [IA6 W02 crossworker #42955272137](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42955272137) SUCCESS y el resto de las 19 CI globales; **no equivalen a cerrar la puerta V28**.
- PR [#119](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/pull/119) convertido a **DRAFT**, abierto, no fusionado, con comentario técnico [#6786707200](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/pull/119#issuecomment-6786707200).
- La rama `codex/calvo-ia6-integration-20261109` permanece en SHA `f4a5687...` antes del merge; `main`, V28 y PR #118 intactos.

### Decisión y siguiente trabajo autorizado

**ESTADO: `BLOCKED_CI_SCOPE_V28` — NO MERGE.** No repetir campañas W02 ni cambiar leyes de combate/SaveV2. No ampliar el allowlist de V28, falsificar PASS, hacer `continue-on-error` o saltar esa gate.

Para proseguir, preparar una propuesta de **separación del alcance de CI**, preservando el contrato histórico V28 en un checkout con modificaciones exclusivamente permitidas, y ejecutando en la rama de integración las regresiones funcionales nativas/crossworker sobre el verdadero SHA integrado. Esa adaptación de infraestructura deberá mantener pruebas verificables en su propio SHA y quedar aprobada como cambio explícito, no como excepción encubierta. Hasta entonces, dejar el PR en DRAFT.
