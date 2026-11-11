# W05 — CAMPAÑA CONTINUA V4 / STAGING FINAL · READY_FOR_IA6_MERGE
Fecha: 2026-11-11 (Europe/Madrid)
**ESTADO: A+B+C COMPLETADAS EN STAGING; NO INTEGRADO EN RAMA OFICIAL IA6.**

- Staging exclusiva: codex/calvo-ia6-staging-20261111-w05-books
- Base fija de IA6 oficial: e63b2e6c7e175fba318cc2f562bebd1769589092
- Fuente W05 V3 ya verde: 803561dd6a0253458c576762d74b3c62435299fa, CI #42957930359
- **SHA de código V4 realmente probado: 81d781e2d6c6c0be20eb77f001b6bd6c968f89c8**
- **CI V4: https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42965926888 — completed/success; verify SUCCESS.**
- Los commits posteriores de reportes/STATE son documentos; no sustituyen la CI del SHA funcional.

## Contabilidad honesta

| Concepto | Valor |
| --- | --- |
| Fases V4 | A/B/C: 3/3 |
| Libros MT nuevos | **0** |
| Libros SV previamente certificados, preservados y revalidados en staging | 229/229 |
| L3 autenticado en staging | Godot technical FieldDemo real + FieldItemBag real + FieldItemService real + SaveV2 manual; NO reemplazo por una fachada |
| Nuevo runner V4 real | **366 checks PASS** |
| Regresiones W05 históricas | T01–T04 PASS; CAMP003/004/005/006 Python y Godot PASS |
| Veto dynamax_candy | Sigue excluido y Python PASS; no se modificó config/item_selection_v1.json |
| Bloqueos funcionales internos W05 | 0 |
| Integración oficial IA6 | **NO** |
| W03 repelentes en base staging | Ausentes; **NO** acreditados como L3 conjunto |

## Fase A — Diff selectivo sin duplicar panel ni alterar Rope

Se partió de la mochila REAL de IA6, que YA contenía un panel **_books_panel**, botón Abrir libro y función _apply_escape_rope. No se importó el FieldItemBag entero desde W05. En staging hay un único BookPanel.new() y una única conexión teaching_finished al callback.

Cambios funcionales localizados de la mochila:

1. **_ready:** señal de selección registra ID real; cambio de objetivo o slot 0–3 actualiza el panel abierto. Se conserva un solo _books_panel.
2. **open_bag:** revalida selección/binding y reabre sin duplicar controles.
3. **_refresh_choices:** rechaza acceso a libro removido de inventario sin perder compatibilidad con selección programática histórica de IA6; muestra nombre ES a partir del helper autorizado. **Usar** global se deshabilita para MT. Mantiene el return específico de Cuerda Huida.
4. **_apply:** preserva el caso await _apply_escape_rope; una MT intenta pasar a la única interfaz de libros, devolviendo machine_panel_required si se fuerza la ruta global. No crea un segundo FieldItemService.
5. **_open_machine_books:** comprueba servicio vigente, libro activo y stock, selecciona ID real, Pokémon Party y slot sin depender del índice de objeto.
6. **_on_book_teaching_finished:** solo mensaje localizado, refresh y HUD; NO invoca teach/use_item ni consume unidades.

La prueba Python compara el cuerpo de **_apply_escape_rope** byte a byte con la base fija e63b2e6: **idéntico**.

Panel de libros: se sustituyeron **solo** los métodos con funcionalidades distintas de W05 V3 (_ready, select_book, select_creature, refresh, _refresh_preview, _refresh_compatibility, teach_selected) y sus variables de estado/filtro. Se preservaron los demás métodos de la rama de IA6. El panel conserva IDs estables, estado obsoleto, selección explícita y exactamente una llamada autorizada a FieldItemService.teach.

Perfil: solo se adapta **FieldMachineBookProfile.presentacion** para consultar nombre español autenticado. Se añaden el helper independiente MachineMovesEsSvW05 y JSON 229 entradas de PokeAPI (con hashes del blob fuente), sin alterar SpanishGameText global ni datos de PokeAPI.

## Archivos de producción modificados (comparación GitHub base → staging)

| Archivo | Cambio |
| --- | --- |
| scenes/visual/field_item_bag.gd | 47 líneas añadidas / 7 eliminadas (54 líneas de diff); funciones de libros |
| scenes/visual/field_machine_book_panel.gd | 167 añadidas / 32 eliminadas; protección estado y UI ES |
| modules/inventory/field_machine_book_profile.gd | 6 añadidas / 1 eliminada; presentacion |
| modules/localization/machine_moves_es_sv_w05.gd | fichero nuevo de helper, 42 líneas |
| data/localization/machine_moves_es_sv_v1.json | fichero nuevo con 229 ES PokeAPI, 1.617 líneas |

**NO** se editó FieldItemService, PlayerCollection, SaveV2, FieldNativeSave, EvolutionSystem, motor Showdown, main, V28, PR118, rama W03 ni rama oficial IA6.

## Fase B — Comprobaciones efectivamente pasadas en CI V4

Recibos originales del job verify:

- W05_V4_BASELINE_RED EXPECTED missing_machine_use_guard=1 (compara base fija con staging, no simula una CI Godot roja).
- W05_V4_SOURCE_ES PASS ids=229 exact_pokeapi=229 excluded_dynamax_candy=1 rope_unmodified=1
- W05_V4_BAG_CONTRACT PASS panel=1 signals=1 double_spend_guard=1 stable_ids=1 callback_ui_only=1
- W05_BOOKS_AUTORUN_V2_GODOT PASS blocks=10 ids=180 functional=180 blocked=0 checks=10467
- W05_BOOKS_AUTORUN_V3_GODOT PASS blocks=10 functional=10 blocked=0 checks=1193
- W05_BOOKS_AUTORUN_V4_GODOT PASS groups=10 translated=229 missing=0 checks=2316
- CAMP003_W05_PY/GODOT PASS: 580/2166 checks
- CAMP004_W05_PY/GODOT PASS: 580/2166 checks
- CAMP005_W05_PY/GODOT PASS: 580/2166 checks
- CAMP006_W05_PY/GODOT PASS: 481/1781 checks
- IA6_BOOK_BAG PASS checks=20 features=real_bag,w05_panel,one_teach,savev2
- IA6_INTEGRATION PASS checks=65 features=mint_effective_nature,escape_rope_bag_savev2
- W05_V4_REAL_FIELD_BAG PASS slots=4 es=229 one_panel=1 no_double_spend=1 stale=1 party_storage=1 savev2=1 no_autosave=1 rope_preserved=IA6_SMOKE checks=366
- W05_V5_PCK_PROBE PASS records=229 runtime_samples=4 helper=1 source=pck_only

La nueva suite cubre los cuatro slots, selección y cancelación, PP, propietario, Party→Storage, stock agotado, bloqueo de sesión, doble click, selección caducada, 229 traducciones presentes, SaveV2 manual y no escritura automática del save de prueba.

**Windows:** W05_V4_WINDOWS_EXPORT PASS exe_bytes=635426312 pck_bytes=526406648 visual=UNVERIFIED android=UNVERIFIED. EXE y PCK temporales certificados técnicamente; **NO hubo ejecución visual/GPU en Windows, distribución final ni exportación Android**. El EXE sigue siendo pesado (~635 MB), sin presupuesto final aprobado.

## Fase C — Entrega precisa a IA6; NO hacer cherry-pick del archivo entero

1. Revisar solo estos cinco archivos de producción de la staging frente al HEAD actual de IA6. Comparación base exacta e63b2e6; revisar diferencias posteriores antes de integrar.
2. Conservar **un único panel**: la interfaz _books_panel de IA6 es la utilizada. Evitar importación simultánea de _machine_panel de V3.
3. Trasplantar los hunks arriba descritos, revalidar que Cuerda Huida conserva guardas de sesión, retorno y rollback y que la ruta global Usar no consume MT.
4. **Ticket pendiente repelentes W03:** comparar la última rama W03 y la integrada para trasladar la lógica de repel/super_repel/max_repel en _refresh_choices/_apply y _apply_repel; W05 no está autorizado para editar esa ruta. Repetir CI cruzada con libros + Rope + Repel, no declarar este tercer efecto integrado hasta pasar pruebas propias.
5. Mantener el veto dynamax_candy heredado de base sin reactivarlo; no añadir más MT nuevas por segunda vez.
6. Certificar la nueva versión integrada de IA6 con CI exacta y luego prueba manual Windows; sin merges a main/V28/PR118 hasta la puerta general.

**READY_FOR_IA6_MERGE:** W05 V4 agota sus tres fases. La staging queda como entrega contrastable, no producto oficial. No crear más tandas repetidas ni realizar integración por cuenta de W05. Una futura p recupera la orden IA6_AUTORUN.md y CONTINUOUS_V4/STATE_W05.md.
