> **PUERTA DE CONTINUACIÓN 01→02 — IA6 / 2026-11-02:** consulta [CAMPAIGN_002_ITER01_CI_GATE.md](CAMPAIGN_002_ITER01_CI_GATE.md) antes del siguiente `p`. El staging de las cuatro familias pasó CI [#41484879741](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41484879741) `completed/success`: W01 contratos 7 escenarios, W02 Godot 350 checks/4 casos + Python 13 tests, W03 Python 9 tests, W05 Python 11 tests + selector 12 MT reales. Se integró el paquete en árbitra commit `60baf5b5ccf0f4755bbb758a274705736910f040`. **W02:** antes de su ITER_02 debe sincronizar SOLO `tests/gameplay/parallel_items_w02_campaign_002.gd` desde árbitra (blob `2e0ac1d2142dad96f110254e7eb4f2a3c5f04c47`), para corregir comparación `[1.0]` vs `[1]`. IA6 no reescribe su rama. El resto puede avanzar con su `p` normal, uno por iteración. Estas pruebas no certifican iteraciones nuevas ni GPU.

# CAMPAÑA_002 — PUERTA DE ACTIVACIÓN OFICIAL (IA6)
**ESTADO GLOBAL:** `ACTIVADA` por solicitud explícita del usuario el 2026-11-02.
**CHECKPOINT ANTERIOR A LA PUERTA:** `a48fe60dba286df777a774842f75962c13bcf97a`, rama `codex/calvo-items-20261101-arbitro`. El commit de este gate y los cuatro encargos forman la base autorizada; las ramas nuevas se crean exactamente desde el SHA de este gate. Ver registro de SHAs en `CAMPAIGN_002_BRANCH_MANIFEST.md` (se publica en árbitra tras crearlas). **Sin otras escrituras funcionales desde el código que pasó las CI**.
**CI BASE VALIDADA:** Godot 4.7 [#41364601482](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41364601482) y [#41364601486](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41364601486), ambas `completed/success`, SHA de código `a8e09dbf8b15c61f1b18207d34548ff8a7ca46e4`. Los cambios posteriores y el checkpoint son **documentales**. **Esa CI NO valida los tests nuevos de CAMP_002**, que aún no existen.

## Identidades autorizadas y ramas NUEVAS (no reusar ramas 20261101)
| Trabajadora | Nueva rama exclusiva | Encargo exacto |
| --- | --- | --- |
| IA1 / W01 | `codex/calvo-items-20261102-w01-camp002` | `campaigns/CAMP_002_W01.md` (tres equipables, tests) |
| IA2 / W02 | `codex/calvo-items-20261102-w02-camp002` | `campaigns/CAMP_002_W02.md` (cuatro bayas, tests) |
| IA3 / W03 | `codex/calvo-items-20261102-w03-camp002` | `campaigns/CAMP_002_W03.md` (tres bolas, solo contratos/auditoría) |
| IA5 / W05 | `codex/calvo-items-20261102-w05-camp002` | `campaigns/CAMP_002_W05.md` (MT, pruebas de muestra nueva) |
**IA4/W04: `CONGELADA_A_PETICION_USUARIO`. No crear rama CAMP_002 W04, no enviarle activación ni `p`, no escribir su rama antigua ni sustituirla.** Su CAMP_001 queda 02/03 y no se transfiere aquí.

## Reanudación operativa sin conflictos
1. Las antiguas ramas CAMP_001 divergieron de la árbitra y conservaron sus propios informes; las nuevas ramas nacen **limpias** desde este gate. Es intencional: W02 antigua conserva pruebas previas a correcciones de IA6. **No merge/rebase/force-push de las ramas 20261101 al nuevo trabajo.**
2. Cada trabajadora necesita recibir una **única activación de CAMPAÑA_002 en su conversación antigua** para sustituir el STOP de CAMPAÑA_001 y empezar a trabajar en su rama nueva. El mensaje debe nombrar este gate; no interpretar una `p` aislada, antes del reconocimiento de CAMP_002, como autorización para ejecutar nada.
3. Al recibir activación: leer este gate en árbitra + `CAMPAIGN_002_PRETRIAGE_VERIFIED.md` + encargo propio + overlay de CAMPAÑA_001. Confirmar que la rama nueva existe y su HEAD corresponde al checkpoint; fijar la rama de escritura. Consultar antigua rama solo para historial, sin copiar ficheros de pruebas viejos.
4. **Se permite iniciar ITER_01 en el mismo mensaje de activación**; posteriores `p`/ `sigue` ejecutan **un** microbloque secuencial, 02 y 03. Nunca iniciar una cuarta iteración, ni otra campaña, automáticamente.
5. Un bloque no debe escribirse antes de verificar rama e IDs. Al publicar: commit, resumen máximo 10–30 líneas, CSV y cuaderno propio. Si tests no ejecutados en Godot 4.7: `PREPARADO_PENDIENTE_CI`, que NO significa PASS. IA6 integra CI por paquete; un FAIL funcional, dependencia de código compartido o conflicto Git obliga STOP y comunica motivo y SHA.
6. Los cuatro archivos de pruebas Python/GDScript/fixture están **disjuntos** por W. No reutilizar rutas de CAMP_001, no modificar `CONTINUIDAD.md` de otra W, no crear workflow desde W. Los reports de CAMP_001 siguen como archivo histórico en las ramas antiguas.
7. **Límite de campaña 3 microbloques por W (12 nuevos máximo)**. Cierre local `CAMPAÑA_002_FINALIZADA` significa tres entregas, NO verificación funcional final. IA6 publicará puerta de CI y consolidación separadas antes de promover implementación.

## Semáforo IA6 de objetos y contexto
- **W01:** 3 equipables ya tienen alguna referencia nativa histórica. Prioridad: evaluar paridad y pruebas, **no reimplementarlos**.
- **W02:** Sitrus/Lum constan en LOTE_002 previo, Leppa tiene prueba nativa de PP, Figy exige contrato de naturaleza. Diferenciar mochila/campo/equipado.
- **W03:** Dusk/Repeat/Dive requieren contextos no presentes explícitamente en `CaptureBattleContext`. Se autoriza caracterización y plan de contrato, **ningún cambio a producción/captura**.
- **W05:** 229 MT activas con etiquetas probadas; solo tm01/tm02/tm77 ya tienen test individual de enseñanza. Ampliar muestra, **no** duplicar `FieldItemService.teach` ni activar las 19 históricas.

## Protección
Está prohibido tocar `main`, `codex/items-v28-from-main`, PR #118, ramas CAMP_001, W04, catálogo/selección, scripts compartidos, simulador fijado, saves reales, arte/UI, economía sin contrato, o reglas de las **dos** piedras Mega universales. Solo IA6 podrá consolidar resultados tras revisar diff y CI de SHA. Las pruebas visuales/GPU permanecen fuera de Godot headless.

**Siguiente acto:** IA6 crea las cuatro ramas desde el commit de esta puerta y publica `CAMPAIGN_002_BRANCH_MANIFEST.md`. Hasta comprobar su existencia, la activación no está lista para reenviarse a las trabajadoras. Sin la orden inicial, no se pulsa `p` en los chats cerrados.
