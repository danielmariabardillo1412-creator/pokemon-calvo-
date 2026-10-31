# Regionales y shiny disponibles

Extensión local del catálogo: 57 regionales normales, 57 regionales shiny y 1.011
parejas shiny de especies base, usando únicamente imágenes ya existentes. No
se crean versiones shiny de los 14 candidatos renderizados por nosotros.

Constructor: `tools/visual/build_pokemon_variants.py`. Procedencia y hashes en
`.godot/pokemon_variant_checks/build.json`. Mantiene fotogramas, transparencia y
duraciones originales. Las escalas derivan de las referencias del pack existente;
no son alturas físicas reales. F3 permite alternar normal/shiny y comparar lados.

Los archivos se cargan bajo demanda; `.gdignore` evita su importación masiva.
Arte de terceros con la misma procedencia de las fuentes Showdown/PokéAPI del
catálogo base. Se conserva el pendiente de revisión de créditos y redistribución
antes de empaquetar/publicar el juego. No publicar automáticamente estas imágenes.

La presencia de un recurso no habilita una especie excluida por el randomlock ni
implementa mecánicas especiales de formas de combate, megas, Gigamax o disfraces.
