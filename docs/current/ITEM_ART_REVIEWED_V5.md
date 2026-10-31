# Integración de ilustraciones revisadas V5 — 2026-10-28

Se incorporan al catálogo de la demo existente las siete ilustraciones generadas
y las 350 entradas con ilustración de fuente revisada en V4. Total: **1.011
entradas con imagen**, accesibles mediante **F3 → Objetos**.

## Cambios y procedencia

Se conservan sin cambios los 654 registros anteriores y los bytes de sus PNG.
Las 357 entradas nuevas se copian al directorio del juego
`assets/local_item_catalog/icons/` y usan rutas `res://`; su carga no depende de
la carpeta externa de investigación. Los siete generados se identifican como
**Arte generado · beta**, con hashes de la referencia pequeña y rutas de los
prompts guardados. Los créditos distinguen estas reinterpretaciones de las
ilustraciones oficiales conservadas sin redibujar.

Fuentes nuevas: 302 E/P, 30 archivo PGL, cuatro Leyendas: Arceus, 14 PokéAPI y
siete generadas. Se conserva cada URL de origen y el SHA-256 del archivo elegido.
Los materiales de MT mantienen sus bolsas compartidas; los IDs siguen separados.
Objetos como el móvil de Rotom se señalan para una futura revisión histórica.
No se rediseñan MT/MO/DT ni otros objetos en esta fase.

La presentación no activa objetos: no cambia la selección de contenido,
inventarios, precios, tiendas, efectos, reglas de captura, estadísticas ni combate.
La presencia en la galería no certifica una mecánica ni decide que un objeto vaya
a aparecer en el juego final. Las 156 exclusiones artísticas se conservan.

## Comprobación

- Importación del proyecto en Godot 4.7, sin errores de script.
- Prueba sin ventana: **4.862 comprobaciones, PASS**, 1.011 imágenes.
- Prueba GPU con la demo real: **4.872 comprobaciones, PASS**, diez capturas.
- Revisadas las capturas nuevas de Duralium, Colonia Máxima, Vasija Castigo y
  material de Aipom, con vistas de 128 y 48 píxeles.
- Comprobados todos los hashes, dimensiones y texturas del catálogo; conservación
  de las 654 entradas previas, siete procedencias generadas y ausencia de las
  referencias pequeñas no seleccionadas y de los objetos excluidos.
- La galería conserva el bloqueo del mapa y no modifica equipo, inventario ni
  RNG. La mochila nativa conserva la selección de imagen y abrirla no consume
  objetos ni avanza el combate. El encuentro usado es efímero, sin guardar partida.
- Datos brutos/normalizados, filtros de contenido y escenas de combate permanecen
  iguales a sus hashes anteriores al lote.

Las comprobaciones de este lote certifican presentación e integración visual,
no todos los efectos de los objetos. No se atribuye una prueba funcional completa
a las 350 entradas nuevas solo por disponer de ilustración.

## Pendiente real

Rokikos conserva su icono provisional y sigue en la cola de mejora. Quedan 418
entradas con referencia pequeña, para buscar o rehacer únicamente si se conservan
sus sistemas; once rotopoderes tienen una revisión de acabado opcional. Las 337
máquinas pendientes y los 300 objetos de eventos/incursión permanecen aparte.
En total hay 1.055 entradas del dataset sin imagen preparada en el catálogo,
no 1.055 encargos de dibujo aprobados.

`ITEM_ART_COVERAGE_V5.json` y `ITEM_ART_REMAINING_REVIEW_V5.csv` contienen el
recuento posterior a la incorporación. El censo V1 y la revisión V4 son evidencia
histórica: sus cifras de «preparado/no instalado» ya no son el estado vivo.
`ITEM_ART_CURRENT_STATUS.json` apunta al cierre actual.

Reproducción de la instalación: `tools/item_audit/install_reviewed_art_v5.py`.
Es idempotente y no sobreescribe un PNG diferente. La instantánea previa y las
pruebas quedan en `.godot/item_art_reviewed_v5/`. El cierre durable con hashes
está en `ITEM_ART_REVIEWED_V5.json`; el plan exacto en
`ITEM_ART_REVIEWED_V5_PLAN.json`.
