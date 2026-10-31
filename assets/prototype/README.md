# Arte mínimo de la prueba visual

Los seis PNG de `pokemon/` son copias del snapshot local de
[`PokeAPI/sprites`](https://github.com/PokeAPI/sprites):
commit de origen `c10459b9b0129eaca5c5d9b1cac65336debb1d08`.

- `sprites/pokemon/1.png`, `4.png`, `7.png`, `16.png`;
- `sprites/pokemon/back/1.png`, `back/4.png` (renombrados `1-back`, `4-back`).

Se conserva `pokemon/LICENCE.txt` completo: el repositorio de sprites se distribuye
como CC0, pero los contenidos de imagen pertenecen a The Pokémon Company según
su propio aviso. No se presentan como arte propio ni como permiso comercial.
La selección ocupa 3.188 bytes de imágenes; la biblioteca completa permanece local.

Mapa y personaje están dibujados mediante código Godot en `scenes/visual/`.
Son arte provisional propio, sin descargas ni dependencia de las bibliotecas externas.
Si se elige otra especie en el laboratorio, se muestra un marcador explícito
«Sprite pendiente» en lugar de atribuirle una imagen de otra especie.
