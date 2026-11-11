# IA5/W05 — CONTINUOUS_V3_FINAL · Libro MT dentro de mochila real (rama W05)
Fecha: 2026-11-11, Europa/Madrid.
Estado: **B01/FASE A + B02/FASE B + B03/FASE C COMPLETADAS EN W05 · READY_FOR_IA6.**
Rama exclusiva: `codex/calvo-items-20261109-w05-books-ui`.
**SHA de código realmente probado:** `803561dd6a0253458c576762d74b3c62435299fa`.
**CI definitiva:** https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42957930359 · **completed/success**; jobs `verify` y `W05 TANDA05 - Windows PCK/runtime isolation` ambos SUCCESS.
Los commits posteriores para informe, auditoría de colisiones y STATE son exclusivamente documentales y no cambian código probado.

## Contabilidad (NO confundir objetos y QA)
- Fases V3 completadas: **3/3** (A, B, C).
- **Objetos nuevos: 0.** Las 229 MT activas de Scarlet/Violet ya se habían certificado en campañas anteriores.
- **229/229** MT existentes conservan pruebas históricas de enseñanza/PP/SaveV2; localización ES verificada y disponible en PCK.
- Nuevo comportamiento L3 comprobado en W05: `FieldItemBag` Godot real monta panel W05, se enlaza a un `FieldItemService` real y enseña mediante una única transacción. **El FieldDemo del runner se sustituye SOLO por una fachada mínima de sesión**, no se probó el recorrido visual completo en mapa.
- Nuevos checks V3: **173** Godot + puerta estructural Python PASS. Cuatro índices 0,1,2,3; cancelación sin gasto, bloqueo de botón global Usar, emisión y no duplicación, stock consumido x1, rechazo de segundo evento, PP canónicos, identidad de propietario, Party→Storage, falta de existencias, bloqueo de sesión, selección caducada, SaveV2 manual y ausencia de autosave.
- Bloqueos internos del plan W05: **0**. Dependencias de integración IA6 y prueba real Windows/GPU quedan pendientes.

## Fase A — De base roja a una instancia montada
La mochila histórica W05 `scenes/visual/field_item_bag.gd` no importaba ni instanciaba `field_machine_book_panel.gd`; `tests/tools/test_parallel_items_w05_continuous_v3.py` incluye puerta de ausencia `--expect-red` para la revisión base, mientras la puerta normal exige una instancia, señal única y bloqueo de doble consumo. La ausencia previa está acreditada por la comparación de contenido base, **sin afirmar que se ejecutara una CI roja nativa de Godot**.
Permiso IA6 excepcional aplicado solo a `FieldItemBag`: registro `MachinePanel`, variables locales de selección, `_ready`, `open_bag`, `_refresh_choices`, `_apply` y callback `_on_machine_teaching_finished`. No se tocó `FieldItemService`, `SaveV2`, `FieldNativeSave`, `PlayerCollection`, `GameData` ni el catálogo.

## Fase B — Recibos funcionales reales de mochila
Del job `verify`:
`W05_V3_BAG_STRUCTURAL PASS mount=1 service_shared=1 callback=1 item_use_nonmachine_preserved=1`
`W05_V3_NATIVE_BAG_GODOT PASS slots=4 real_bag=1 owner=1 spent_once=1 double_spend=0 storage=1 stale=1 lock=1 savev2=1 signals=1 checks=173`
Runner: `tests/gameplay/parallel_items_w05_continuous_v3.gd` (extiende los fixtures canónicos W05 V3, no crea mecánicas ni datos sintéticos).
Las regresiones históricas W05, CAMP003–006 y las pruebas V2 se conservan; por ejemplo CAMP006 Godot 1781 PASS.
Dos iteraciones previas quedaron trazadas: #42957381981 falló por inferencia de tipo Godot `is_book`; se corrigió con `bool` explícito. La CI #42957563964 verificó el montaje original con 168 checks de Godot; la iteración final añade cancelación y ausencia de autosave y certifica 173 con ambos jobs verdes.

## Fase C — Paquete Windows y análisis multirrama
Job de exportación del mismo SHA:
- EXE Windows técnico: **635.399.144 bytes**, cabecera `MZ` verificada; anterior V2 **635.389.864** (+9.280 bytes).
- PCK Windows técnico: **526.379.480 bytes**.
- PCK montado en proyecto Godot independiente: 229 nombres españoles, helper de localización real, cuatro muestras. `W05_V5_PCK_PROBE PASS records=229 runtime_samples=4 helper=1 source=pck_only`.
- Guarda de crecimiento EXE 10% respecto al baseline histórico: **PASS**, pero NO constituye presupuesto objetivo de distribución.
- EXE generado en runner Linux para plataforma Windows, **no ejecutado manualmente en Windows**. No certifica GPU/FPS, usabilidad final ni Android.

**Auditoría de colisiones:** `docs/coordination/items_parallel_v1/CONTINUOUS_V3/W05_COLLISION_AUDIT.md`.
Evidencia de lectura de ramas ajenas: IA6 integrada **ya tiene un panel propio** (`_books_panel`, botón Abrir libro) y Cuerda Huida, mientras la rama W03 incluye además repelentes. No afirmar que UI IA6 esté certificada por esta CI. **Prohibido copiar FieldItemBag de W05 entero encima de IA6:** podría duplicar panel y perder Cuerda Huida/Repelentes. IA6 debe integrar selectivamente por función, ejecutar su propia prueba nativa de campo y publicar CI sobre su SHA.

## Límites finales y relevo IA6
1. W05 L3 acreditado = mochila `FieldItemBag` de SU rama, panel y servicio real, más fachada mínima del campo. NO prueba completa de mundo.
2. IA6 ya dispone de un panel en SU rama: reconciliar ambas variantes, un solo `teaching_finished`, los cuatro slots, prioridad de `Usar`, estabilidad de IDs, consumo y SaveV2.
3. Reconciliar Cuerda Huida y repelentes W03 en HEAD IA6, y añadir pruebas conjuntas IA6.
4. Queda pendiente ejecución EXE en Windows/GPU y examen de distribución, además de preset Android.
5. No se modificaron `main`, V28, PR118, ramas W03/IA6, motores, SaveV2 o política Randomlock, ni se hizo merge.

**READY_FOR_IA6:** el plan V3 autorizado W05 se agotó con CI completa. No iniciar tandas inventadas ni asumir que el proyecto integrado está certificado. Una futura `p` deberá leer primero `IA6_AUTORUN.md` y `CONTINUOUS_V3/STATE_W05.md`.
