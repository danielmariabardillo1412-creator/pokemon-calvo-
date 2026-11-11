# IA6 — separación auditable de CI V28 / integración W02

**Fecha:** 2026-11-11. **Objeto:** resolver el bloqueo `BLOCKED_CI_SCOPE_V28` de PR [#119](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/pull/119) sin debilitar el contrato histórico V28 y sin alterar `main`, V28, PR #118 o ramas W01–W05.

## Diagnóstico de origen

El script histórico `tools/item_audit/automation_v28.py` fija `BASE=47f42aef1a518eefb744ad310f89b6e2d3ce7108` y en `guard()` rechaza los paths producidos por `git diff --name-only BASE` fuera de `ALLOWED`. Por definición esa puerta solo es correcta en una rama que modifica exclusivamente los artefactos de la auditoría V28. La antigua rama IA6 ya acumulaba 295 rutas modificadas frente a BASE; el bloqueo estaba presente antes de W02.

Referencia de contrato histórico real: rama `codex/items-v28-from-main`, CI [#41262171581](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41262171581) SUCCESS, código `ba2909297bd5d0049b97517b59e6cc9ee2ca6bd7`. Las dos actualizaciones posteriores hasta `7d49a23d15432b9e7845f2c8cd6b0ee5a88e286e` modificaron solo dos documentos. La ejecución histórica verde incluye el contrato declarativo V28 en Linux y Windows.

Se detectó **segundo problema crítico independiente**: `actions/checkout@v4` en evento `pull_request` usaba el checkout de fusión temporal `refs/pull/119/merge`, con padre `e63b2e6c7e175fba318cc2f562bebd1769589092` (añade `dynamax_candy` a la lista de exclusiones), aunque GitHub declaraba como base de PR #119 `codex/calvo-ia6-integration-20261109` en SHA `f4a5687bff1aaf0fb443c36ca4c2873f5d0ac54e`. El head directo tiene 8 exclusiones individuales; el merge temporal 9. De ahí la CI #42959665153 con `canonical=2222 excluded=45` y `item_closure_v3.py` línea 70 FAILED, frente a contrato `excluded=44`. **No modificar el catálogo para corregir un checkout incorrecto.**

## Solución publicada solamente en staging del PR #119

Rama `codex/calvo-ia6-w02-integration-20261111`; workflow editado `.github/workflows/item-closure-v3.yml`, código `tools/item_audit/ia6_v28_integrated_mechanics.py`.

1. **Checkout exacto:** Linux y Windows seleccionan `ref: ${{ github.event.pull_request.head.sha || github.sha }}` y verifican `git rev-parse HEAD` antes de cualquier prueba. Así los cambios de política no deseados del merge temporal no contaminan la certificación. Se mantiene el gate de 2.222 IDs y 44 excluidos, sin alterar assertions.
2. **Funcionalidad real integrada:** correr todos los pasos nativos originales del workflow sobre el **head verdadero** del PR y un test Python adicional (`ia6_v28_integrated_mechanics.py`) que reutiliza los descriptores, casos Godot nativos, validadores positivos/negativos, hashes de evidencia, 8 IDs y 40 escenarios de `automation_v28.py`. El script exige >=1.935 comprobaciones y conserva hashes del código; **no invoca `guard()`** porque ese control git-diff no pertenece a un árbol integrado. El informe se identifica como `INTEGRATED_NATIVE_MECHANICS_ONLY`, no como `SCOPED_VERIFIED` histórico.
3. **Contrato histórico intacto:** el mismo workflow crea un *worktree* independiente en `RUNNER_TEMP/ia6-v28-historical` de SHA **fijo** `ba2909297bd5d0049b97517b59e6cc9ee2ca6bd7`. Prepara recursos pinneados y ejecuta el script original `automation_v28.py` con `guard()` y todas las pruebas/replay originales en Linux y Windows; no se edita el verificador, las fixtures ni V28.
4. **Comprobación doble obligatoria:** no permitir que un PASS histórico sustituya al PASS sobre mecánicas integradas o al revés. El workflow original sigue requiriendo V27 Portable Windows, inventario 2.222, regresión EV, objetos de protección/daño, familias nativas, reproducción, matriz de evidencias y artefactos.

## CI de recuperación y estado

- Fallo original: [#42955302952](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42955302952), `ITEM_AUTOMATION_V28 FAILED checks=0 Outside exact allowlist`; 20/21 CI restantes verdes.
- Ensayos intermedios #42959665153 y #42959916007 detectaron checkout temporal inesperado `excluded=45`. Se documentaron y corrigieron, sin cambiar datos.
- CI #42960177513 verificó checkout HEAD directo en Linux y etapa de inventario `PASS` (posteriormente cancelada por nueva edición de workflow; **no certificación global**).
- Nueva CI candidata sobre SHA `2909d59702c5830ca7baf9b71a1401560316aca8`: [#42960326195](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42960326195). **PENDIENTE de completed/success al registrar este documento**; no atribuirle éxito sin consultar.
- PR #119 sigue **DRAFT, NO MERGED**. No abrir PR a main ni modificar V28. Las CI de staging anterior `42955006505`, `42955272137` demostraron 43 checks W02 y regresiones cruzadas, pero no certifican las nuevas puertas hasta su ejecución final.

## Continuidad al recibir `p`

1. Consultar #42960326195 por jobs y logs, corregir errores sin reducir controles y repetir sobre nuevo SHA si es necesario.
2. Verificar todos los workflows del último HEAD PR #119 en GitHub. Si un control falla, mantener DRAFT y reproducir.
3. Si ambas puertas V28 y demás CI SUCCESS, revisar el resultado de `compare` contra la rama de integración IA6 y solo entonces evaluar **merge exclusivo a `codex/calvo-ia6-integration-20261109`**; el merge no autoriza tocar main.
4. Después del merge, verificar el SHA efectivo y ejecutar workflow en SHA real IA6. No confundir CI de staging o de un worktree histórico con evidencia del commit mergeado.
