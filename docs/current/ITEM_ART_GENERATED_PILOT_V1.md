# Piloto de imágenes generadas de objetos — 2026-10-28

Continuación: `ITEM_ART_GENERATED_COMPLETION_V1.md` registra los otros cinco y
la revisión conjunta de los siete. Este documento conserva el cierre del piloto.

Petición: probar Duralium y Colonia antes de preparar los otros cinco huecos de
estilo. Se usa la herramienta integrada `image_gen`, con el icono pequeño original
como referencia de identidad y Piedra Fuego/Repelente del catálogo como estilo.
Son reinterpretaciones generadas, no ilustraciones oficiales recuperadas.

## Resultado

Dos candidatos legibles, con una corrección por objeto (cuatro generaciones).
Duralium V1 inclinaba la piedra y desplazaba la cara blanca; V2 recupera la
orientación vertical y el brillo superior. Colonia V1 inventaba una banda blanca
en U; V2 la elimina y conserva reflejos laterales, cuello claro y cuerpo verde.
El detalle no es una copia exacta del sprite y queda sujeto a revisión artística.

Se han comparado originales ampliados, candidatos a 128/48/40/32 píxeles y arte
existente. Los contornos y colores se reconocen al reducirlos. La apariencia de
Duralium es más facetada y oscura que la referencia pixelada; esto es una
diferencia visible, no una certificación de identidad perfecta.

La vista GPU de Godot 4.7 usa TextureRect y filtro lineal para los candidatos,
nearest para el original. Comprueba las dimensiones reales de cada control antes
de capturar; las etiquetas 48/40/32 corresponden a esas medidas. Las imágenes
cargan y se muestran sin errores de Godot. Es una vista de revisión, no una
prueba de integración en la mochila o de efectos del objeto.

Los archivos generados conservan su alfa. Las copias de 160×160 se reducen con
Lanczos sin repintar ni quitar el fondo por color. Los originales completos se
conservan. El primer intento de captura no tenía las medidas finales correctas;
se corrigió el script y solo `godot_preview_final.png` es la evidencia GPU final.

## Archivos guardados en el proyecto

Carpeta: `art_review/item_icons_generated_pilot_v1/`.

- `armorite_ore_160_v2.png` y `lure_160_v2.png`: candidatos seleccionados.
- `*_generated_v1.png`, `*_generated_v2.png`: salidas completas sin modificar.
- `*_original.png`: referencias pequeñas conservadas para comparar.
- `comparison_v2.png`: comparación a varios tamaños y con el catálogo existente.
- `godot_preview_final.png`, `gpu.log`, `preview.gd`: comprobación visual en Godot.
- `prompts.json` y `prompts_v2.json`: instrucciones completas de cada intento.
- `review.json`: hashes, resultado, correcciones y limitaciones.

No se sustituyen recursos ni se añaden estas dos entradas al manifest. El hash
del catálogo coincide con el cierre V3 y sus 654 entradas siguen iguales. Los
siete huecos de estilo continúan registrados; dos tienen ahora candidatos.
Faltan por generar Hoja de Oro, Hoja de Plata, Supercolonia, Colonia Máxima y
Trozo Deseo si se continúa con este acabado. No cambian mecánicas ni datasets.

Diseños originales: The Pokémon Company / Nintendo / Game Freak. Referencias
pequeñas: fuentes conservadas en la investigación V3. Candidatos nuevos:
generados con `image_gen` para este proyecto. No se mezclan con los créditos de
las ilustraciones oficiales sin redibujar que ya utiliza el catálogo.
