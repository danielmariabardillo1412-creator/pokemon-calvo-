# V21 — Tres consumibles de huida en la mochila de combate

Base `167487e4`, copia organizada en D:. Se conecta una familia con el sistema
de encuentros salvajes existente: **Poké Muñeco, Cola Skitty y Poké Señuelo**
(`poke_doll`, `fluffy_tail`, `poke_toy`). No son nuevas imágenes ni tres registros
equipados adicionales: son tres usos funcionales desde la mochila nativa.

## Comportamiento

Al usar uno en un encuentro salvaje permitido, termina como FLED y se consume
una unidad de la mochila. La huida es segura incluso bajo atrapamiento y sin
comparar velocidades, gastar RNG ni ejecutar otro ataque del rival. No entrega
XP y conserva los PS/estados/PP reales que existían al salir.

Solo se permite en una frontera de elección de acción con un Pokémon activo
vivo. Se rechaza ante entrenadores, durante reemplazo obligatorio, interrupción,
otro comando en curso, revisión obsoleta, cambio externo de colección, falta de
objeto, objetivo ajeno/reserva o selección de movimiento. El rechazo no gasta
objetos ni turnos. El juego actual no modela encuentros guionizados con un flag
adicional de huida prohibida; no se declara implementado ese futuro contexto.

`Run` ordinario conserva su perfil `calvo_escape_v1`, tiradas y atrapamiento.
Bola Humo permanece pendiente como objeto equipado: no se activa por esta ruta.
El backend legado no dispone de una orden de mochila equivalente; no se añade
allí ni se afirma cobertura de los tres objetos fuera del combate nativo.

## Organización

`tools/item_import/import_escape_v21.py` descubre la familia por
`EFFECT_ITEM_ESCAPE` en el RHH fijado, exige los tres IDs revisados y comprueba
política/consumo/contexto. Genera exclusivamente el perfil propio
`modules/inventory/battle_escape_profile.json`, sin cambiar el dataset canónico.
La interpretación «salvaje, huida segura» se contrasta con Essentials; no se
deduce de la descripción del objeto ni se ejecutan C/Ruby externos.

`battle_escape_profile.gd` expone soporte y permiso usando la política existente.
AdventureSession valida el dueño y prepara una copia del inventario. Reutiliza
su liquidación síncrona: solo publica y registra consumo cuando termina la huida.
Una medicina gastada previamente y aún pendiente también se publica exactamente
una vez al salir. No se agregan callbacks ni se cambia NativeEngine, paquetes,
algoritmos de combate, generadores RNG o schema de guardado.

Los consumibles de huida no pueden aparecer como gasto en un checkpoint activo:
su uso termina el encuentro. Se conserva la validación anterior que rechaza un
checkpoint manipulado para fingir ese gasto sin terminar el combate.

La vista consulta al servicio qué objetos están disponibles. La mochila se titula
«Objetos de combate», oculta Pokémon/PP para esta familia, explica el consumo y
anuncia la huida. Conserva los controles de medicina al cambiar de selección.
Una llamada antigua a la mochila tras finalizar/cerrar el combate se rechaza sin
acceder a una sesión nula ni gastar otra unidad. La UI no decide la liquidación.

## Cobertura y contadores

- Tres usos de mochila de combate nuevos; 18 IDs de uso directo con las 15
  medicinas anteriores. Las bolas mantienen su selector y contador aparte.
- Siguen **77 efectos de campo**, **618/625 definiciones equipadas** y siete
  huecos nativos. Estos contadores no se suman para fingir objetos distintos.
- Los ocho potenciadores de combate, IV/mentas, formas, usos de mundo/concursos
  y los otros objetos pendientes no se certifican aquí.

## Verificar

```text
python tools/item_import/import_escape_v21.py --check
python tests/tools/test_escape_import_v21.py
python tools/verification/run_item_escape_v21.py
```

Se usan las copias locales de V13. `--check` no escribe; `--write` solo regenera
el perfil propio. Para jugar no son necesarias las fuentes externas.
Evidencia: [ITEM_ESCAPE_V21.json](ITEM_ESCAPE_V21.json),
`.godot/item_escape_v21/runs/` y capturas por objeto en esa carpeta de fase.

El lote prueba los tres IDs en tres perfiles nativos, con restauración antes de
usar y atrapamiento real por Mal de Ojo. Comprueba consumo único, ausencia de XP,
turno/RNG y efectos ajenos, fronteras negativas, KO con reemplazo, gasto previo
de medicina y rechazo de un checkpoint con gasto terminal inventado. Cada objeto
se usa en la mochila de `field_demo.tscn`, tras guardar/cargar, con vuelta al mapa,
comandos de UI obsoletos y otra carga que conserva la cantidad final.

Se preservan los intentos fallidos. El runner inicial usó una serialización
inexistente del agregado; se corrigió a sus tres componentes. La prueba de mapa
conservaba una referencia anterior a cargar y retenía la animación en pausa;
además debía leer el texto procesado de RichTextLabel. Se corrigió la prueba,
sin debilitar las comprobaciones de consumo ni cambiar reglas para hacerla pasar.

La primera pasada completa dio verde técnico, pero la revisión de capturas
detectó una pregunta de objetivo aún visible y un panel demasiado alto por la
ayuda con ajuste de línea. Se corrigieron ambos y se repitió la suite completa.
Las capturas anteriores se conservan junto a esa ejecución con sus hallazgos.

Resultado definitivo: **11 grupos PASS**, 218 comprobaciones del lote, 46 de
huida en GPU y cuatro métodos de prueba del importador. Las regresiones de
aventura, medicinas, núcleo, campo, restauración y medicina visual pasan también;
son 1.995 comprobaciones Godot entre todos los grupos. Se revisaron las tres
capturas de huida finales y la selección de Éter: panel compacto, sin pregunta
de objetivo al huir y con selección de Pokémon/PP conservada en medicinas.
El guard final comprobó 23.063 archivos protegidos por hash completo y conservó
15.647 ausentes con skip-worktree.

## Fuentes y créditos

RHH / rh-hideout y colaboradores, **pokeemerald-expansion**,
`8654616bd38d9b28cc7dd8f3d0b4cb030aa2d40c`, `src/data/items.h`:
los tres `EFFECT_ITEM_ESCAPE` son consumibles y no tienen uso de campo.
SHA-256 incorporados al perfil generado.
[RHH](https://github.com/rh-hideout/pokeemerald-expansion/tree/8654616bd38d9b28cc7dd8f3d0b4cb030aa2d40c).

Maruno17 y colaboradores, **Pokémon Essentials**,
`8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b`,
`Data/Scripts/013_Items/003_Item_BattleEffects.rb`: CanUseInBattle de POKEDOLL
exige salvaje/canRun; comparte con FLUFFYTAIL/POKETOY. UseInBattle termina como
huida. SHA-256 local:
`acd6f3d2f49e2d8084310b8b62f269973a26fa9c7a1ec4191a64d0b119f223e0`.
[Essentials](https://github.com/Maruno17/pokemon-essentials/tree/8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b).
Conservar ambos agradecimientos para los créditos del juego.
