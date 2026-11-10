# IA5/W05 — AUTORUN TANDA 04 FINALIZADA · 229 nombres ES oficiales de los libros MT

**Fecha:** 2026-11-10. **Rama exclusiva:** `codex/calvo-items-20261109-w05-books-ui`.
**Métrica exigida:** hitos **10/10** · **MT nuevas 0** · QA/localización **229/229** · integración IA6 **no** · bloqueados **0**.
**SHA de código y tests ejecutado:** `0952232ed648e7997e1db470ce18c0b53ac4848a`.
**GitHub Actions:** [#42893621203](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42893621203) `completed/success`, job `130100845813`. Confirmados diez recibos individuales y recibos completos del job.

## Manifest 10 grupos oficiales

Orden `IA6_AUTORUN.md` de la rama W05 y `AUTONOMY_V1/QUEUE_W05_TANDA_04.md` de árbitra. Los IDs son los originales `tm01`–`tm229`; no hay ningún `tm230+`.

| Hito | MT | Nombres ES con fuente verificada | Sin fuente ES | Estado |
|---|---|---:|---:|---|
| 01 | `tm01`–`tm23` | 23 | 0 | PASS |
| 02 | `tm24`–`tm46` | 23 | 0 | PASS |
| 03 | `tm47`–`tm69` | 23 | 0 | PASS |
| 04 | `tm70`–`tm92` | 23 | 0 | PASS |
| 05 | `tm93`–`tm115` | 23 | 0 | PASS |
| 06 | `tm116`–`tm138` | 23 | 0 | PASS |
| 07 | `tm139`–`tm161` | 23 | 0 | PASS |
| 08 | `tm162`–`tm184` | 23 | 0 | PASS |
| 09 | `tm185`–`tm207` | 23 | 0 | PASS |
| 10 | `tm208`–`tm229` | 22 | 0 | PASS |

**Totales:** 10/10 examinados y certificados. **229** nombres procedentes de `names[]` cuyo `language.name == "es"`, **0** sin fuente, **0** objetos MT nuevos.

## Procedencia exacta y arquitectura

- `modules/inventory/item_connections_v1.json` determina la relación de cada libro con `move_id` en `scarlet-violet`. Los **229 movimientos son distintos**, 0 ausentes.
- `data/api/v2/move/index.json` — índice local PokeAPI de **937** movimientos — resuelve el slug para lookup sustituyendo `_` por `-` únicamente durante la búsqueda, nunca en la identidad canónica.
- **229 archivos originales** `data/api/v2/move/{id}/index.json` inspeccionados individualmente. Se comprobó `id`, `name`, exactamente una entrada `names.es` y la firma Git blob SHA1 de los bytes originales. Las variantes `es-419` y `en` no alimentan el idioma español de estos libros.
- Tabla nueva `data/localization/machine_moves_es_sv_v1.json`: `move_id → nombre_es, source_api_id, source_path, source_blob_sha, item_id`, versión de esquema 1, locale es. Sus **229 filas** tienen origen verificable.
- Helper nuevo `modules/localization/machine_moves_es_sv_w05.gd` resuelve textos por `move_id` sin modificar el ID, la compatibilidad, los PP o el inventario. Si no puede validar la fuente, devuelve **fallback identificado como no verificado**.
- Cambio estrictamente en `FieldMachineBookProfile.presentacion` para devolver `nombre_movimiento`, `traduccion_es_verificada`, `nombre_source_api_id` y `nombre_source_locale`; el panel W05 toma ese texto para lista, título, sustitución y confirmación. **No modifica `FieldItemService.teach`.**

## Comparación con textos anteriores: discrepancia de fuente

Se compararon las nueve claves relevantes que ya tenían traducción en `SpanishGameText.CORE_MOVE_NAMES` y las dos etiquetas piloto.
**Única diferencia detectada:**

| Movimiento | Antes (global) | Ahora en libro MT (PokeAPI es) |
|---|---|---|
| `light_screen` · `tm75` | `Pantalla Luz` | **`Pantalla de Luz`** |

La nueva presentación de libros usa `Pantalla de Luz` por ser la entrada local `names.es` del archivo PokeAPI. **`SpanishGameText.CORE_MOVE_NAMES` no se modifica** y podrá requerir reconciliación posterior del producto global por IA6.

Las dos etiquetas piloto `pain_split = Divide Dolor` y `metal_claw = Garra Metal` coinciden exactamente con `names.es` de PokeAPI. El resto no son traducciones inventadas: la etapa anterior auditaba 11 nombres como verificados por sus fuentes disponibles y 218 como fallback **no verificado**; la tabla actual aporta la nueva evidencia de esos 218.

## Pruebas y CI

Del **mismo run SUCCESS**, SHA `0952232ed648e7997e1db470ce18c0b53ac4848a`, job `130100845813`:
- `W05_BOOKS_AUTORUN_V4_PY PASS groups=10 ids=229 translated=229 missing=0 mismatches=1 checks=1620` — cada entrada con documento local, idioma e identidad y SHA exactos. Diez filas `W05_BOOKS_AUTORUN_V4_PY_GROUP block=NN translated=23/22 missing=0`.
- `W05_BOOKS_AUTORUN_V4_GODOT PASS groups=10 translated=229 missing=0 checks=2316` — 10 recibos por hito, 229 nombres en la pantalla de selección real de un `PanelContainer` Godot, nombres por `presentacion`, fuente ES, tipo, stock, traducción no inventada, enseñanza positiva de control, rechazo de repetición y guardado/carga SaveV2.
- TANDA01: `W05_BOOKS_AUTORUN_GODOT PASS blocks=10 ids=49 functional=49 blocked=0 checks=2869`.
- TANDA02: `W05_BOOKS_AUTORUN_V2_GODOT PASS blocks=10 ids=180 functional=180 blocked=0 checks=10467`.
- TANDA03: `W05_BOOKS_AUTORUN_V3_GODOT PASS blocks=10 functional=10 blocked=0 checks=1193`.
- Pilotos LIBROS-UI 01/02: Python 23, Godot 143 PASS.
- CAMP006: Python 481 y Godot 1781 PASS, diez grupos.
- CAMP005, CAMP004 y CAMP003: cada una Python 580, Godot 2166 PASS.

**Migración histórica sin silenciar las pruebas:** el runner V3 original acreditó 11 traducciones conocidas y 218 fallbacks en su versión congelada CI #42870869700; al activar PokeAPI ES, en el HEAD actual la aserción V3 fue reemplazada por **cobertura positiva explícita para los 218 promocionados** y un negativo para un `move_id` desconocido. El runner V4 verifica las 229 claves contra los archivos fuente individualmente. El piloto histórico que buscaba `Divide Dolor` y `Garra Metal` escritos *dentro del panel* se corrigió para comprobar exactamente esos valores contra `names.es` original, conservando los tests Godot de enseñanza. No se altera el fixture antiguo ni se retiran regresiones.

**Intento y reparación:** CI [#42893150624](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42893150624) falló solo por la aserción antigua de texto literal dentro del panel, heredada del piloto; tras migrar a comprobación PokeAPI ES, CI [#42893621203](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/42893621203) es SUCCESS.

## Permisos, pendientes y relevo

Se han cambiado únicamente los archivos autorizados por IA6: tabla JSON nueva, helper nuevo, método `presentacion`, panel W05, tests/runners propios y su workflow/documentación. **No se alteraron** `SpanishGameText` global, `FieldItemBag`, `FieldItemService`, SaveV2 central, catálogos, política, learnsets ni datos originales PokeAPI. No se tocó `main`, V28, PR118 ni ramas de otras trabajadoras; **sin merges**.

**L1:** tabla ES verificada 229/229. **L2:** reglas de aprendizaje y consumo preservadas (regresiones). **L3:** panel W05 aislado certificado con Godot headless, **no** la versión incorporada en la mochila de IA6 ni inspección manual/GPU. Para exportar el juego a Windows/Android habrá que comprobar que la tabla JSON es incluida en el paquete, tarea de integración/QA fuera de los archivos autorizados.

**Aviso a IA6:** `W05 TANDA 04 FINALIZADA — hitos 10/10 — 229/229 traducciones es verificadas — MT nuevas 0 — bloqueadas 0 — SHA 0952232ed648e7997e1db470ce18c0b53ac4848a — CI #42893621203 SUCCESS — AUTORUN_V4_FINAL.md`.

**STOP:** no iniciar TANDA05 sin otra cola oficial en `IA6_AUTORUN.md`.
