# IA5/W05 — AUTORUN TANDA 02 · CHECKPOINT DE ARRANQUE

Fecha: 2026-11-10. Rama exclusiva: codex/calvo-items-20261109-w05-books-ui.
Orden IA6: `IA6_AUTORUN.md` en esta rama; cola oficial `AUTONOMY_V1/QUEUE_W05_TANDA_02.md` en rama árbitra.

**Identidad verificada:** 229 MT scarlet-violet en machine_rows canónico, menos 49 certificadas TANDA01 = 180 nuevas, sin duplicados ni IDs inventados; 10 grupos de 18.

**Nuevo runner parametrizado** `tests/gameplay/parallel_items_w05_book_ui_autorun_v2.gd` reusa la secuencia de TANDA01: presenta libro/tipo, usa Pokémon real permitido y learnset SV, 4 slots/reemplazo, incompatibilidad, sin stock, field_locked, consumo 1, PP, propietario y SaveV2. Fixture `tests/fixtures/parallel_items/w05_book_ui_autorun_v2.json` generado exclusivamente de cola oficial y perfil activo. Control Python de unión 229 = 49 + 180. Workflow propio ejecuta nuevo runner más las regresiones originales 003/004/005/006, piloto01/02 y TANDA01.

Los estados **EN_CI** del CSV son provisionales y NO certifican enseñanza. Si la CI falla, analizar log y corregir solo archivos W05; bloquear IDs sin especie compatible realmente permitida, sin inventar learnset. No tocar FieldItemBag, FieldItemService, SaveV2, datos, política, main, V28, PR118, árbitra u otras ramas; sin merge.

**Cobertura headless de panel aislado**, no certificación visual ni rama integrada IA6.
