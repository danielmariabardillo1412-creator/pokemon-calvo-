# IA6 — W05 V4 · traslado selectivo de libros MT a ensayo IA6

Fecha: 2026-11-11. Estado de este documento: `W05_SELECTIVE_INTEGRATION_STAGING_TESTING`, **NO MERGED**.

## Base y procedencia auditable

- Repositorio: `danielmariabardillo1412-creator/pokemon-calvo-`.
- Rama IA6 oficial: `codex/calvo-ia6-integration-20261109`, SHA origen fijo `33ecf65d9ca33aa80d7968c172726465099f812f` (PR #119 W02 integrado y postmerge certificado). No alterar esta rama hasta nuevo gate.
- Rama staging W05 V4: `codex/calvo-ia6-staging-20261111-w05-books`, **último código con CI verde** `81d781e2d6c6c0be20eb77f001b6bd6c968f89c8`; [run #42965926888](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42965926888) `completed/success`. Commits W05 posteriores son documentales; blob SHA de los cinco archivos de producción y pruebas principales coinciden con el código verde.
- **Nueva rama AISLADA, no oficial**: `codex/calvo-ia6-w05-integration-20261111`, creada desde HEAD IA6 anterior. Primer commit de traslado `791214b9ce782ea4e0dab9bca2c0099cc4cd3de2`; workflow reparado en `58ef7a496ec13a1a8db1552ac0d3f031865bfecd`.
- La comparación exacta confirmó que los cinco archivos actuales en IA6 y en la base anterior usada por W05 (`e63b2e6...`) tienen **los mismos blobs**. Así no se pisa ningún cambio posterior de esos cinco archivos. Se trasplantaron **los blobs W05 que contienen sus hunks locales validados**: equivalen a aplicar los hunks sobre base idéntica. No se copiaron `FieldItemService`, SaveV2, `FieldNativeSave`, `EvolutionSystem`, motor Showdown, `main` ni V28.

## Modificaciones de producción W05: cinco rutas exactas

1. `scenes/visual/field_item_bag.gd`: panel único MT; filtro de Usar global, estado obsoleto, selección estable y conservación de `_apply_escape_rope`.
2. `scenes/visual/field_machine_book_panel.gd`: cuatro slots, interfaz ES, selección caducada/validación de inventario.
3. `modules/inventory/field_machine_book_profile.gd`: presentación localizable (sin cambiar sistema global de traducciones).
4. `modules/localization/machine_moves_es_sv_w05.gd`: helper ES PokeAPI.
5. `data/localization/machine_moves_es_sv_v1.json`: 229 entradas españolas comprobadas contra fuentes.

**Libros nuevos: 0**; se mejora y verifica la integración de los 229 ya existentes. No toca repeles W03 ni proclama esa seam como terminada. Se copiaron únicamente las pruebas, fixtures, progreso W05 y workflow propios de la entrega certificada, en un único commit aislado. No se copiaron `IA6_AUTORUN.md` ni `CONTINUOUS_V4/STATE_W05.md` de la trabajadora.

## CI staging propia

- Primer run [#43067019165](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43067019165) `FAILURE` **sin jobs**: la primera publicación de YAML mediante Git tree produjo duplicación/truncamiento de un bloque; fallo estructural de CI sin ejecución de mecánicas. El archivo quedó reconstruido desde el workflow W05 V4 original certificado, **158 líneas y un único ejemplar de cada etapa**, mediante `update_file`, sin tocar los cinco archivos de producción.
- **Run actual** [#43067373789](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43067373789) sobre SHA `58ef7a496ec13a1a8db1552ac0d3f031865bfecd`, `in_progress` al registrar esta nota. Consultar GitHub: no afirmar PASS hasta `completed/success`.
- Requiere original W05 T01–04; CAMP003–006 Python/Godot; W05 366 checks reales sobre mochila; 229 etiquetas ES; fallback sin datos; prueba export PCK Windows; IA6 smoke panel/libros y Rope, más audit 2222/45 y test W02 efectivo mint → mochi → evolución → SaveV2. El export no acredita GPU visual ni Android.
- El workflow usa grupo de concurrencia propio `ia6-w05-selective-${{ github.ref }}`, no colisiona con IA6 W02 ni smoke viejo.

## Dependencias y siguiente acción de IA6

1. Esperar el **resultado real actual** de #43067373789 y, si falla, consultar logs; reparar en **esta rama aislada**, nunca forzar/verdes, nunca editar fuente W05.
2. Ante SUCCESS, comprobar integridad de archivo `field_item_bag.gd`: una instancia del panel y conservación de la ruta `_apply_escape_rope`; comparar con nuevos cambios sobre IA6 oficial antes de promover.
3. Revisar dependencias W03: `WildAdventureSession` sigue con 6 aserciones legacy rojas, y repeles W03 requieren fusión dedicada de _refresh_choices/_apply sobre mochila. **No** tratar CI W05 verde como certificación conjunta W03+W05.
4. Si se autorizan todos los checks, promover únicamente los hunks W05 sobre rama IA6 con SHA esperado y luego CI postmerge. Mantener `main`, V28 y PR118 intocables.
5. W01 staging tiene 0 hunks de producción confirmados y requiere cierre suite. W02 V4 sigue `PENDIENTE_ACTIVACION` hasta cierre V3 EXP Share. W04 está `READY_FOR_IA6_MERGE_CANDIDATE` con 396 checks pero falta prueba cruzada. No fusionar ramas completas W03/W04/W05 sin revisar concurrencia de FieldItemBag, EvolutionSystem y SaveV2.

**Estado de interrupción:** nueva rama W05 con código/hunks y QA real preparada. Solo el resultado de su CI decide promoción. No hay trabajo ChatGPT en segundo plano.


## PR oficial de revisión creado (sin fusión)

- [PR #120](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/pull/120): **OPEN / DRAFT / NOT MERGED**.
- `head=codex/calvo-ia6-w05-integration-20261111`; `base=codex/calvo-ia6-integration-20261109`. Head al abrir: `58ef7a496ec13a1a8db1552ac0d3f031865bfecd`.
- Se dispararon además los workflows generales del PR, incluido `Item Closure V3` (requiere V28 scope dual) y compilación Windows. Todos deben alcanzar `completed/success` antes de cualquier integración.
- [CI directa W05 #43067373789](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43067373789) ha pasado la preparación, la política 45, el runner W02 nativo, T01–04, CAMP003–006, el smoke IA6 panel/rope, la prueba W05 real de 366 checks y fallback ES; **estaba ejecutando la exportación técnica PCK/EXE al último chequeo**. No declarar SUCCESS global mientras siga en curso.
- Próxima `p`: verificar CI directa y todos los jobs generales del PR #120 sobre el HEAD exacto; si hay un fallo, obtener log y repararlo solo en rama W05 de ensayo. Si todo verde, confirmar que IA6 oficial no avanzó, revisar el diff limitado, fusionar únicamente en IA6 y exigir CI postmerge. W03 repeles/legacy y W04 evolución deben pasar por otro gate; ninguna promoción a main.


### Puerta W05 propia certificada (actualización posterior)

- [#43067373789](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/43067373789) **completed/success**, HEAD `58ef7a496ec13a1a8db1552ac0d3f031865bfecd`. Superó workflow completo con T01–T04, CAMP003–006, bolsa W05 real, W02, Rope IA6, policy45, fallback y export Windows técnico.
- [PR #120](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/pull/120) abierto `draft=true` a IA6; las CI generales del PR sobre SHA exacto mostraban **17/21 completed/success, 4 in_progress, 0 failures** en la última consulta: `Trainer Team Composition`, `Godot 4.7`, `Windows Build`, `Item Closure V3`.
- **Puerta restante: todas las CI del PR y posterior CI del merge IA6**. No inferir estado final de esos cuatro runs a partir de la CI W05 verde. Mientras tanto, mantener DRAFT / NO MERGE. W03 repeles y wild legacy siguen bloqueados fuera de W05.
