# IA6 — separación auditable de CI V28 / integración W02

**Fecha:** 2026-11-11. **Objeto:** resolver el bloqueo `BLOCKED_CI_SCOPE_V28` de PR [#119](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/pull/119) sin debilitar el contrato histórico V28 y sin alterar `main`, V28, PR #118 o ramas W01–W05.

## Diagnóstico de origen

El script histórico `tools/item_audit/automation_v28.py` fija `BASE=47f42aef1a518eefb744ad310f89b6e2d3ce7108` y en `guard()` rechaza los paths producidos por `git diff --name-only BASE` fuera de `ALLOWED`. Por definición esa puerta solo es correcta en una rama que modifica exclusivamente los artefactos de la auditoría V28. La antigua rama IA6 ya acumulaba 295 rutas modificadas frente a BASE; el bloqueo estaba presente antes de W02.

Referencia de contrato histórico real: rama `codex/items-v28-from-main`, CI [#41262171581](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41262171581) SUCCESS, código `ba2909297bd5d0049b97517b59e6cc9ee2ca6bd7`. Las dos actualizaciones posteriores hasta `7d49a23d15432b9e7845f2c8cd6b0ee5a88e286e` modificaron solo dos documentos. La ejecución histórica verde incluye el contrato declarativo V28 en Linux y Windows.

**Rectificación posterior basada en el historial real:** el branch IA6 avanzó el 2026-11-11 a las 04:29 UTC desde `f4a5687...` mediante `2def474...` y `e63b2e6...`. El cambio excluye **deliberadamente** `dynamax_candy` por decisión del usuario y ajusta su suite de política a **45 excluidos**. El `refs/pull/119/merge` con padre `e63b2e6...` sí refleja el HEAD más reciente del branch IA6; la respuesta de metadatos PR conservaba un `base.sha` obsoleto. La CI roja #42959665153 mostró `canonical=2222 excluded=45` porque el auditor Item Closure V3 aún tenía una expectativa **obsoleta de 44**, no porque la política nueva fuera incorrecta. La referencia V27 de 44 se conserva como histórica; el conteo actual legítimo es 45.

## Solución publicada solamente en staging del PR #119

Rama `codex/calvo-ia6-w02-integration-20261111`; workflow editado `.github/workflows/item-closure-v3.yml`, código `tools/item_audit/ia6_v28_integrated_mechanics.py`.

1. **Checkout exacto:** Linux y Windows seleccionan `ref: ${{ github.event.pull_request.head.sha || github.sha }}` y verifican `git rev-parse HEAD` antes de cualquier prueba. Esto certifica el SHA propio de la rama sin confundirlo con el merge temporal; **requiere verificar aparte la nueva política de IA6**. En el segundo hito de integración, la rama staging incorporó el veto válido de `dynamax_candy`, la prueba Godot de 45 IDs y actualizó los dos controles Item Closure V3 para exigir **45 excluidos y el motivo exacto**. El test no altera la referencia V27 de 44.
2. **Funcionalidad real integrada:** correr todos los pasos nativos originales del workflow sobre el **head verdadero** del PR y un test Python adicional (`ia6_v28_integrated_mechanics.py`) que reutiliza los descriptores, casos Godot nativos, validadores positivos/negativos, hashes de evidencia, 8 IDs y 40 escenarios de `automation_v28.py`. El script exige >=1.935 comprobaciones y conserva hashes del código; **no invoca `guard()`** porque ese control git-diff no pertenece a un árbol integrado. El informe se identifica como `INTEGRATED_NATIVE_MECHANICS_ONLY`, no como `SCOPED_VERIFIED` histórico.
3. **Contrato histórico intacto:** el mismo workflow crea un *worktree* independiente en `RUNNER_TEMP/ia6-v28-historical` de SHA **fijo** `ba2909297bd5d0049b97517b59e6cc9ee2ca6bd7`. Prepara recursos pinneados y ejecuta el script original `automation_v28.py` con `guard()` y todas las pruebas/replay originales en Linux y Windows; no se edita el verificador, las fixtures ni V28.
4. **Comprobación doble obligatoria:** no permitir que un PASS histórico sustituya al PASS sobre mecánicas integradas o al revés. El workflow original sigue requiriendo V27 Portable Windows, inventario 2.222, regresión EV, objetos de protección/daño, familias nativas, reproducción, matriz de evidencias y artefactos.

## CI de recuperación y estado

- Fallo original: [#42955302952](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42955302952), `ITEM_AUTOMATION_V28 FAILED checks=0 Outside exact allowlist`; 20/21 CI restantes verdes.
- Ensayos #42959665153 y #42959916007 expusieron la evolución simultánea de la política IA6 (45 excluidos) frente al staging anterior (44). La causa quedó aclarada con los commits de IA6 `2def474` y `e63b2e6`; no se trataba de un nuevo error de datos.
- CI #42960177513 verificó checkout HEAD directo en Linux y etapa de inventario `PASS` (posteriormente cancelada por nueva edición de workflow; **no certificación global**).
- CI [#42960326195](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42960326195) **completed/SUCCESS** sobre SHA `2909d59702c5830ca7baf9b71a1401560316aca8`: 3335 checks V28 integrado, 3335 V28 histórico, 46 replay/1395 checks, V27 Windows, 2222 inventario y regresiones. **Ese código aún usaba política de 44 excluidos**.
- La rama staging PR #119 incorporó luego política IA6 vigente de **45** junto con la actualización auditada de `item_closure_v3.py` y su test, código SHA `16da5a0373ef92b33c308e96c95f60679dc85675`. Nueva CI [#42963526507](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42963526507): **IN_PROGRESS al registrar esta edición**, sin afirmar cierre.
- PR #119 sigue **DRAFT, NO MERGED**. No abrir PR a main ni modificar V28. Las CI de staging anterior `42955006505`, `42955272137` demostraron 43 checks W02 y regresiones cruzadas, pero no certifican las nuevas puertas hasta su ejecución final.

## Continuidad al recibir `p`

1. Consultar #42960326195 por jobs y logs, corregir errores sin reducir controles y repetir sobre nuevo SHA si es necesario.
2. Verificar todos los workflows del último HEAD PR #119 en GitHub. Si un control falla, mantener DRAFT y reproducir.
3. Si ambas puertas V28 y demás CI SUCCESS, revisar el resultado de `compare` contra la rama de integración IA6 y solo entonces evaluar **merge exclusivo a `codex/calvo-ia6-integration-20261109`**; el merge no autoriza tocar main.
4. Después del merge, verificar el SHA efectivo y ejecutar workflow en SHA real IA6. No confundir CI de staging o de un worktree histórico con evidencia del commit mergeado.

## Seguridad de destino del PR

La referencia de fusión temporal `refs/pull/119/merge` utilizó como padre `e63b2e6...`, que **sí era** el HEAD actualizado de IA6 a las 04:29 UTC. La discrepancia con `pulls/119.base.sha=f4a5687...` procedía de metadatos PR obsoletos, no de un destino ajeno. **Aun así**, no ejecutar la fusión a ciegas: comprobar que el HEAD actual de `codex/calvo-ia6-integration-20261109` coincide con el baseline validado, comparar la política real (45), y preferir escrituras condicionadas por SHA y rama explícita si persiste incertidumbre. Verificar que `main` permanece ajena a estas operaciones. Mantener PR #119 DRAFT hasta certificar la nueva CI de política45 y el resultado en la rama IA6.


---

## ✅ Cierre de bloqueo y fusión oficial IA6 (2026-11-11)

**Esta sección sustituye cualquier instrucción anterior de NO MERGE, DRAFT o `BLOCKED_CI_SCOPE_V28` en este documento. No confundir histórico con estado vigente.**

- PR [#119](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/pull/119): **MERGED**, base exclusiva `codex/calvo-ia6-integration-20261109`, HEAD staging `16da5a0373ef92b33c308e96c95f60679dc85675`.
- La CI de política actual y V28 [#42963526507](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42963526507) concluyó `completed/success` sobre ese HEAD: 20/20 workflows en el mismo SHA, incluyendo V28 histórico intacto en Linux y Windows, 8 IDs/40 escenarios nativos integrados y audit item scope 2222/45.
- **Merge SHA oficial `0028361ae69c2a63ca2aaf23710a4543157445ac`**, confirmado en GitHub; padres `e63b2e6c7e175fba318cc2f562bebd1769589092` (IA6 con veto `dynamax_candy`) + `16da5a0373ef92b33c308e96c95f60679dc85675` (staging certificado).
- No ha habido merge a `main`: se verificó `main=233b1a4f15ee4df7301e2c5acf8aed84a8f40626` antes y después. V28 y PR #118 no se han tocado.
- Se conserva `dynamax_candy` como excluido, 45 actuales; el documento V27 antiguo continúa con 44 históricos.
- Al primer push del merge GitHub canceló el workflow viejo `IA6 Integration - mint + rope` por colisión de grupo `concurrency: ia6-mint-rope-${{ github.ref }}` con el nuevo workflow. **No es un FAIL de pruebas**. La puerta nueva engloba las regresiones viejas y añade W02.
- Se reparó exclusivamente ese grupo de concurrencia en el workflow nuevo: commit IA6 **`33ecf65d9ca33aa80d7968c172726465099f812f`**, cambiando a `ia6-w02-selective-native-${{ github.ref }}`. Permite ejecutar la CI antigua y nueva sin cancelación cruzada en próximos commits pertinentes.
- Certificación **del SHA de IA6 posterior al merge:** [#42969055524](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42969055524) en `0028361...`; [#42969175343](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42969175343) en `33ecf65...`. **Ambas IN_PROGRESS en el momento de este checkpoint; no atribuir SUCCESS hasta leer GitHub**.

**Estado: `MERGED_IN_IA6_PENDING_POSTMERGE_CI`.** El bloqueo V28 quedó resuelto y aprobado por la CI del staging; la validación post-merge sobre el SHA oficial sigue separada. No reabrir PR #119, no realizar otro merge automático ni promocionar a `main`. La siguiente `p` consulta primero las dos CI post-merge, diagnostica cualquier FAIL, documenta el SHA final y después retoma el plan global IA6 de staging V4 sin pisar ramas ni inventar nuevos objetos.
