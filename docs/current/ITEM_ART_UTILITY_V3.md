# Arte de utilidad y tesoros V3 — 2026-10-28

Se revisa primero el cierre V2 interrumpido: las 609 entradas ya pasaban carga,
pruebas y capturas GPU. Se conserva ese resultado en `ITEM_ART_EXPANSION_V2.json`
y se actualiza el estado acumulado antes de iniciar este lote.

## Añadido a la misma beta

Se incorporan **45 entradas**, conservando sin cambios las 609 anteriores:
35 tesoros/materiales de intercambio y diez objetos de campo. Total: **654**.
Se incluyen chapas, fragmentos, Escama Corazón, Rama de Galanuez, monedas,
reliquias, tesoros vendibles, flautas, repelentes y objetos de huida.

Origen: 18 imágenes de E/P y 27 del archivo de ilustraciones PGL de Serebii.
La carpeta `pgl` identifica el archivo proveedor; no prueba por sí sola la
historia de publicación o autoría original de todos los objetos posteriores.
Se mantienen los créditos del catálogo y las URL individuales de cada recurso.

Las imágenes nuevas ocupan 336.656 bytes. El lote se inspeccionó en una hoja y
se verificó una captura GPU de Chapa Plateada dentro de **F3 → Objetos**. No se
generan dibujos ni se modifican los PNG originales. Incorporar Chapa Plateada
en el catálogo visual no implementa el entrenamiento extremo; los tesoros
tampoco introducen precios, tiendas o intercambios nuevos.

## Depuración de contenido

Se apartan dos cartas de hoja decorativas de los compañeros de Let's Go:
`leaf_letter_pikachu` y `leaf_letter_eevee`. Sus definiciones están clasificadas
como loot, pero sus textos primarios describen cartas. Se aplica el criterio
de cartas del usuario, sin borrar el dataset. El plan artístico acumula **156**
entradas descartadas; el filtro de ejecución sigue teniendo los 43 vetos de V1.

Quedan ocho recuerdos de compañero sin papel decidido para este juego, no
vetados definitivamente: Beach Glass, Chalky Stone, Lone Earring, Marble,
Polished Mud Ball, Small Bouquet, Stretchy Spring y Tropical Shell. Sus textos
no justifican inventarles una función nueva en nuestro juego.

Las seis bayas de captura doradas/plateadas de Let's Go quedan en revisión de
política de captura. No se transfieren sus efectos automáticamente a las
fórmulas de capturas en combate. Los 14 casos de revisión de contenido permanecen
anotados aunque no se haya buscado integrar sus imágenes en este lote.

Las hojas de oro y plata se conservan como candidatas: tienen valor de venta;
no se descartan en bloque con los regalos. Las chapas, fragmentos y Escama
Corazón también conservan sus papeles de entrenamiento/aprendizaje/intercambio,
aunque aparezcan en categorías de botín o colección.

## Siete candidatos pendientes de estilo

Para estos siete objetos se encontraron iconos pequeños válidos, pero no una
ilustración suficientemente afín en las fuentes comprobadas. No se presentan
como imágenes inexistentes ni como objetos que haya que dibujar obligatoriamente:

- Duralium (`armorite_ore`).
- Hoja de Oro y Hoja de Plata.
- Colonia, Supercolonia y Colonia Máxima.
- Trozo Deseo (`wishing_piece`).

Se revisaron además candidatos de similitud visual dentro del paquete HD items
de Verdep ya descargado. **Todos se rechazaron**: eran objetos distintos con
colores o contornos parecidos. No se usa un repelente como si fuera Colonia,
una pluma como si fuera Hoja de Oro ni otra gema como si fuera Duralium.
La hoja `community_candidates.png` conserva la comparación; el algoritmo solo
propone inspecciones, no certifica identidad. No se añaden créditos de uso de
Verdep por este lote, porque no se incorporó ninguna de esas alternativas.

## Evidencias, reproducción y pendientes generales

`ITEM_ART_UTILITY_V3_PLAN.json` conserva los 52 candidatos iniciales, 45 IDs
elegidos, dos exclusiones, 14 revisiones de contenido y siete de estilo.
La investigación queda en
`D:\Proyectos\Pokemon Calvo Auditoria Visual\comparacion_objetos_v1\utility_v3\`.
`prepare_utility_v3.py` reutiliza el resolutor de páginas observadas de V2.

Instalación reproducible:
`tools/item_audit/append_art_batch.py --prepared <prepared.json> --plan docs/current/ITEM_ART_UTILITY_V3_PLAN.json --evidence .godot/item_art_utility_v3`.
El importador conserva entradas anteriores, verifica bytes originales y rechaza
IDs descartados/diferidos. El catálogo utiliza rutas `res://` y no depende de la
carpeta externa de investigación para ejecutarse.

Prueba: `tests/gameplay/item_art_beta_test_runner.gd -- --art-utility-v3`.
Para capturas reales añadir `--capture` junto al argumento del lote.
El informe `ITEM_ART_UTILITY_V3.json` comprueba el estado final y los hashes;
`ITEM_ART_CURRENT_STATUS.json` es el punto de continuación actualizado.

Sigue pendiente la revisión de objetos clave según los mapas/historia y las
relaciones MT/MO/DT por versión. Los 20 casos de entrenamiento especial de V2,
los 14 de contenido de V3 y los siete de estilo no se confunden con material
ya integrado. Rokikos conserva el icono provisional anterior.
No cambia combate, captura, guardado, inventarios, Trainer AI ni datasets.

Fuentes de clasificación: definiciones locales y textos primarios de PokéAPI
para los objetos 1024–1035; [Hoja de Oro en ItemDex](https://www.serebii.net/itemdex/goldleaf.shtml)
para confirmar su carácter vendible. La selección de arte registra cada página
del objeto en `assets/local_item_catalog/manifest.json`.
