# IA6 — ORDEN PERMANENTE ACTIVA W05 · TANDA 03

**IA6 HA REVISADO TU ENTREGA ANTERIOR Y PUBLICA AQUÍ LA NUEVA COLA COMPLETA.** Este archivo es tu punto fijo de entrada. Cuando recibas `p`, `sigue` o `continúa`: consulta la rama de GitHub, tu HEAD, esta nota y tu checkpoint; empieza en la primera fila pendiente de la **TANDA 03**, sin pedir permiso IA6 por cada fila. Tras completar 10, deja informe + CI real y STOP a esperar una TANDA nueva. No te limites a contestar «entendido».

**Rama autorizada:** `codex/calvo-items-20261109-w05-books-ui`. **Protocolo maestro:** `docs/coordination/items_parallel_v1/AUTONOMY_V1/README.md` de `codex/calvo-items-20261101-arbitro`. **Orden central:** `docs/coordination/items_parallel_v1/AUTONOMY_V1/QUEUE_W05_TANDA_03.md` de árbitra. Esta copia tiene el mismo contenido y vale aunque cambie el contexto de la conversación.

No ejecutar en segundo plano ficticio: si un turno se agota, publicar checkpoint en GitHub y la siguiente `p` continúa. Un bloqueo de un productor compartido no te obliga a detener los otros hitos independientes: ticket, `BLOQUEADO`, próximo. Nunca presentar CI de otro SHA como actual ni fusionar `main`, V28, PR118 u otras ramas. Protecciones de archivos/funciones indicadas abajo son estrictas.

---

# IA6 W05 — TANDA 03: robustez del panel completo de 229 libros
Rama: codex/calvo-items-20261109-w05-books-ui.
TANDA01 49/49 y TANDA02 180/180 = 229/229 MT activas Scarlet/Violet con enseñanza positiva en panel aislado Godot headless, CI TANDA02 42734399078 SUCCESS. No hay otras MT SV por implementar; no inventar tm230+.
PROTOCOLO COMÚN: Esta nota autoriza los 10 hitos sin pedir permiso por hito. Al recibir p/sigue, comenzar en primer hito pendiente, publicar checkpoint si termina el turno, retomar con siguiente p. Conservar pruebas, CI con SHA y contabilidad L1/L2/L3. Bloqueos reales se documentan y permiten pasar a hitos independientes. No main, V28, PR118 ni ramas ajenas. Al terminar emitir cierre de tanda y detenerse; no ejecutar en background.
Diez hitos independientes NUEVOS, no repetir 229 teaching tests como supuestos objetos nuevos:
01 Rendimiento/lista de 229 libros, medición headless reproducible sin afirmar FPS GPU.
02 Apertura/cierre repetidos sin doble señal, duplicado ni segundo consumo.
03 Inventario/stock modificado mientras panel abierto, rechazo de selección obsoleta.
04 Pokémon retirado de Party/storage mientras panel abierto, propiedad validada.
05 Cuatro movimientos, slots 0–3, reemplazo y cancelación, PP intacto.
06 Ordenación/filtro por tipo/stock SI es seguro, no alterar IDs ni catálogo.
07 Campo bloqueado, incompatible, movimiento conocido/prohibido, sin datos SV.
08 Auditoría de textos ES reales y fallback; no inventar traducciones.
09 SaveV2 manual con panel abierto, selección obsoleta y cantidad conservada.
10 CI resiliencia más regresiones 229, pilotos UI01/02 y CAMP003–006, informe AUTORUN_V3_FINAL.md.
Solo editar field_machine_book_panel.gd y tests/helpers/workflow W05. No editar FieldItemBag, FieldItemService, SaveV2 central, learnsets, catálogos, política, otras ramas. IA6 es responsable de montaje final en mochila integrada; esta tanda no acredita GPU/manual ni 229 combinaciones por especie.
