# Siete huecos con candidatos preparados — 2026-10-28

Actualización posterior: los siete se incorporaron al catálogo en
`ITEM_ART_REVIEWED_V5.md`. Este documento conserva el cierre de su preparación.

Se continúa el piloto aceptado por el usuario: Duralium y Colonia V2 conservan
su selección. Se generan los otros cinco objetos con la herramienta integrada
`image_gen`, una llamada por objeto, manteniendo sus iconos originales como
referencia de identidad. No se usa generación por API ni CLI.

## Cinco nuevos

- Hoja de Oro: hoja única dorada, tallo inferior izquierdo y punta superior derecha.
- Hoja de Plata: misma familia y acabado, con la paleta plateada del original.
- Supercolonia: cuerpo azul y tapón azul claro, siguiendo la forma de Colonia V2.
- Colonia Máxima: cuerpo rojo y tapón amarillo, siguiendo su referencia original.
- Trozo Deseo: roca azul oscura irregular, con borde claro y planos interiores discretos.

No fue necesario reutilizar la Colonia V1 de banda blanca como otro nivel ni
asignar una imagen de un objeto diferente. Las cinco primeras generaciones de
este lote resultan legibles; se conservan sin correcciones adicionales.
Son reinterpretaciones de los sprites, no copias oficiales de alta resolución.

## Comprobación

Las siete versiones seleccionadas están preparadas a 160×160, conservando el
alfa original y reduciendo con Lanczos. Se conservan las salidas completas y
los iconos fuente. Comprobados PNG decodificables, transparencia real, margen
del contorno visible, integridad de las copias y hashes de las versiones elegidas.

Inspección visual: originales frente a candidatos de 128/48/40/32 px; revisión
de los cinco nuevos sobre fondos claro y oscuro. Las dos hojas se distinguen
por color y las tres colonias por su paleta. Trozo Deseo es el más oscuro:
su contorno sigue visible, aunque los planos internos pierden detalle a 32 px.

Captura real con Godot 4.7, siete filas y controles de 96/48/40/32 px, usando
filtro lineal como la galería. Se comprueban las medidas reales después de que
Godot actualice el tamaño mínimo. Resultado `ITEM_ART_SEVEN_GPU_PASS`, sin
errores ni advertencias. Es una vista de revisión, no una integración en mochila.

## Archivos y continuación

Carpeta del lote: `art_review/item_icons_generated_completion_v1/`.

- `*_generated_v1.png`: cinco salidas completas sin modificar.
- `*_160_v1.png`: cinco iconos candidatos reducidos.
- `*_original.png`: referencias copiadas del trabajo V3.
- `prompts.json`: instrucciones completas, referencias y ubicación de cada salida.
- `comparison.png`: los cinco nuevos frente al original y a tamaños pequeños.
- `all_seven.png`: resumen de los siete a 128/48 px.
- `godot_preview.png`, `preview.gd`, `gpu.log`: revisión en Godot reproducible.
- `review.json`: selección de los siete, hashes, estado y límites de la revisión.

Los otros dos candidatos siguen en `art_review/item_icons_generated_pilot_v1/`:
`armorite_ore_160_v2.png` y `lure_160_v2.png`. La selección conjunta referencia
esos mismos archivos, sin duplicarlos ni cambiar versiones silenciosamente.

Estado: **siete preparados, todavía sin instalar**. El catálogo del juego conserva
las 654 entradas y el hash del cierre V3. Datos, configuración de selección y
escenas de juego permanecen iguales. Este lote satisface la preparación de los
siete huecos, no certifica todos los objetos del catálogo ni sus mecánicas.
Rokikos conserva su icono provisional independiente de este grupo.

Diseños originales: The Pokémon Company / Nintendo / Game Freak. Referencias
pequeñas: investigación V3 conservada. Nuevos candidatos: generados mediante
`image_gen` para el proyecto; no se atribuyen como ilustraciones oficiales.
