# IA5/W05 — AUTORUN V5 FINAL · TANDA 05 / Windows export de nombres españoles

Fecha: 2026-11-11 (Europe/Madrid).
Rama exclusiva: `codex/calvo-items-20261109-w05-books-ui`.
**Estado:** TANDA05, 10/10 hitos QA examinados/certificados en su alcance; MT nuevas **0**; 229/229 nombres españoles de movimientos en datos originales y en PCK; bloqueados de la tanda **0**.
**SHA funcional validado:** `42466cfe9b012949472f12480a3d5e3b91573c92`.
**CI:** [#42923848244](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42923848244) `completed/success`, jobs `verify` y `W05 TANDA05 - Windows PCK/runtime isolation` ambos SUCCESS.
**CI del checkpoint documental:** [#42924399433](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42924399433), también `completed/success`, sobre SHA `0256e7ec32df3959914eb97e771a12c19545f503`, ambos jobs SUCCESS. Los commits posteriores de informe/continuidad son exclusivamente documentales y no alteran código ni exportación.

## Resultado de los 10 hitos

| Hito | Resultado | Evidencia y límite exacto |
|---|---|---|
| 01 Export preset / ignores | PASS | `export_presets.cfg` Windows tiene `export_filter="all_resources"`, no excluye tabla. `include_filter` no nombra `data/localization/machine_moves_es_sv_v1.json`; export **real** confirma inclusión, por lo que **no hay cambio justificado del preset** |
| 02 Integridad 229 y portabilidad | PASS | `test_parallel_items_w05_book_ui_autorun_v5.py`: 229 filas, mapeos SV, ruta `res://`, nombres `names.es` exactos, 229 fuentes locales y Git blob SHA sin alteraciones. `W05_BOOKS_AUTORUN_V5_PY PASS rows=229 portable=1 original_sources=229 pck_inclusion=UNVERIFIED`; esa última palabra identifica exclusivamente el *preflight* |
| 03 Exportación Windows | PASS | `--export-pack` y `--export-release` sobre preset Windows 4.7, ambos a archivos **temporales**; ningún entregable existente sobrescrito |
| 04 Inspección PCK | PASS | Un **proyecto Godot vacío** monta el PCK generado y lee su tabla desde el paquete, no desde los archivos de trabajo. `W05_V5_WINDOWS_EXPORT PASS output=temp_pck` |
| 05 Resolución de ES en runtime exportado | PASS acotado | `W05_V5_PCK_PROBE PASS records=229 runtime_samples=4 helper=1 source=pck_only`. El script de localización real, cargado desde PCK, resuelve `tm01` Derribo, `tm75` Pantalla de Luz, `tm202` Divide Dolor y `tm229` Palma Rauda, todos verificados. **No es una prueba visual del EXE en Windows** |
| 06 Fallback | PASS | Dos ejecuciones separadas Godot sobre helper real: JSON ausente y JSON de esquema inválido retornan fallback sin atribuir origen ES. `W05_V5_FALLBACK PASS mode=missing` y `mode=invalid` |
| 07 Reapertura / Party / Storage | PASS acotado | Regresiones previas de panel V3 en CI actual (`1193` checks Godot) cubren reentrada, señales, selección estable, retirada/depósito de Pokémon, rechazo sin consumo y refresh. Sigue siendo panel **aislado** |
| 08 Enseñanza / PP / stock / SaveV2 | PASS acotado | En el mismo `verify` CI, T01 49/49 (Godot 2869), T02 180/180 (Godot 10467), T03 Godot 1193 y T04 Godot 2316, más pilotos y CAMPAÑAS 006/005/004/003 completos. El efecto `FieldItemService.teach` se prueba **en Godot headless**, no mediante pulsación humana en EXE |
| 09 Contrato IA6 / FieldItemBag | PASS del contrato; integración pendiente | `W05_V5_IA6_INTEGRATION_CONTRACT PASS service_binding=1 stable_book_selection=1 teach_seam=1 FieldItemBag_edit=0`. API del panel: `bind_existing_service`, `select_book`, `select_creature`, `select_replacement_slot`, `teaching_finished`. **IA6 debe incorporar panel a FieldItemBag**, W05 no modifica mochila |
| 10 CI y cierre | PASS | Run #42923848244 SUCCESS sobre SHA funcional indicado; documentación y CSV en `reports/W05` |

## Windows EXE: verificación y tamaño

`godot --headless --path . --export-release "Pokemon Calvo Technical Test Windows" "$EXE"` terminó con éxito. Archivo temporal `W05-PokemonCalvo-Windows-Export-Probe.exe` generado de **635.385.472 bytes**; su cabecera `MZ` y tamaño se comprobaron:
`W05_V5_WINDOWS_EXE PASS header=MZ size=635385472`.

**Advertencia:** esta prueba certifica la generación del ejecutable Windows, **no su arranque en Windows, ni GPU, interfaz, instalador ni calidad del paquete final**. Los 635 MB aproximados requieren una auditoría posterior del peso de distribución y del empaquetado de recursos `all_resources`. No se cambia la selección de recursos sin un test de contenido equivalente. No hay preset Android acreditado.

## Regressiones de la misma CI

- TANDA01 (49 libros): `W05_BOOKS_AUTORUN_GODOT PASS blocks=10 ids=49 functional=49 blocked=0 checks=2869`.
- TANDA02 (180 libros): `W05_BOOKS_AUTORUN_V2_GODOT PASS blocks=10 ids=180 functional=180 blocked=0 checks=10467`.
- TANDA03 (robustez): `W05_BOOKS_AUTORUN_V3_GODOT PASS blocks=10 functional=10 blocked=0 checks=1193`.
- TANDA04 (ES): `W05_BOOKS_AUTORUN_V4_GODOT PASS groups=10 translated=229 missing=0 checks=2316`.
- CAMP006 Python 481 / Godot 1781; CAMP005, CAMP004 y CAMP003 Python 580 / Godot 2166 cada una, todas PASS.
- Los pilotos de libros-UI previos y sus pruebas Python también siguen certificados por el job `verify`.

## Código y autorización

Archivos nuevos/actualizados únicamente bajo W05: pruebas Python/Godot V5, sondas PCK/fallback, workflow W05 y documentos de progreso/cierre. **Ningún cambio a producción**, tablas PokeAPI, `export_presets.cfg`, `FieldItemBag`, `FieldItemService`, SaveV2 global, catálogos, `SpanishGameText`, main, V28, PR118 ni ramas ajenas. **No merge**.

Hubo dos incidencias de instrumentación durante la ejecución: aserción del parser del preset que no eliminaba comillas y una construcción incorrecta de YAML en el workflow. Se repararon en los tests/CI de W05, sin alterar reglas del juego, y los dos jobs completos pasan en CI final.

## Pendientes para IA6 / relevo

1. **Integración real de `field_machine_book_panel.gd` con la `FieldItemBag` de IA6**, conservando los cambios de otras trabajadoras; la interfaz estable está testada pero no integrada.
2. **Prueba manual de EXE en Windows y de UI/GPU**, incluyendo lista, Party/Storage y botones de enseñar.
3. **Auditoría de distribución por tamaño (~635 MB)**. Comprobar recursos realmente necesarios antes de reducir `all_resources`.
4. **Reconciliación de textos globales**: `light_screen` usa `Pantalla de Luz` en tabla MT PokeAPI ES, mientras `SpanishGameText.CORE_MOVE_NAMES` sigue con `Pantalla Luz`. No modificar global sin puerta IA6.
5. No se certifica exportación Android.

**Aviso para árbitra:** `W05 TANDA05 TERMINADA — 10/10 QA — 229/229 nombres ES empaquetados en Windows PCK — MT nuevas 0 — 0 bloqueos internos — SHA 42466cfe9b012949472f12480a3d5e3b91573c92 — CI #42923848244 SUCCESS — AUTORUN_V5_FINAL.md — integración FieldItemBag y prueba Windows visual pendientes IA6`.

**STOP:** no crear TANDA06 ni modificar otra rama sin nueva orden de IA6.
