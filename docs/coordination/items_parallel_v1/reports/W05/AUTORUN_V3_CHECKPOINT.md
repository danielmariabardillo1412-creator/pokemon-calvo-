# W05 — TANDA03 robustez 229 libros · Checkpoint inicial de CI

**Fecha:** 2026-11-10. Rama de trabajo `codex/calvo-items-20261109-w05-books-ui`. Orden oficial: `IA6_AUTORUN.md`, TANDA03, central `AUTONOMY_V1/QUEUE_W05_TANDA_03.md`. Las tandas 01 y 02 están finalizadas y no se reimplementan los 229 movimientos.

Se ha publicado el panel reforzado y un runner V3 de diez hitos: rendimiento 229 (microsegundos headless, no GPU), reapertura, inventario obsoleto, Party/Storage, cancelación y slots 0–3, orden/filtro de catálogo, bloqueos variados, auditoría de textos con aviso de fallback, SaveV2 manual con panel abierto y gate final de CI. La CI W05 ejecuta además TANDA01 49 + TANDA02 180 + pilotos UI01/02 y CAMP003–006 sin omisiones.

**Estado inicial:** tests preparados; todos los hitos quedan `EN_CI` hasta ejecutar y revisar el job del SHA de esta rama. No se atribuyen 10 funcionales por crear pruebas ni se afirma revisión visual/GPU. Cualquier fallo debe corregirse solo en panel, tests y workflow W05; si depende de un archivo protegido marcar `BLOQUEADO`.

**Protección:** sin cambios `FieldItemBag`, `FieldItemService`, SaveV2 central, datos, política, localización compartida, `main`, V28, PR118 u otras ramas; sin merge.
