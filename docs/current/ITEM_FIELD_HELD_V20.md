# V20 — Doce equipables revisados en bloque

Base `aeb2c8b1`, copia organizada en D:. Se continúa el piloto por familias:
el importador prepara doce definiciones revisadas y el motor nativo conserva
la autoridad de Lanzamiento, Desarme, Truco, supresión y transacciones.

## Alcance

Se añaden cinco pañuelos (azul, verde, rosa, rojo, amarillo), cinco flautas
(negra, azul, roja, blanca, amarilla), Cola Skitty y Poké Muñeco. La fuente RHH
no declara un efecto pasivo equipado para ninguno de esos doce. Los pañuelos
tienen potencia 10 de Lanzamiento; los otros siete, potencia 30.

El registro nativo pasa de 606 a **618 de 625** equipables permitidos.
Los siete pendientes son `amulet_coin`, `cleanse_tag`, `exp_share`, `linking_cord`,
`luck_incense`, `pure_incense` y `smoke_ball`. No se convierten en objetos neutros:
necesitan efectos propios o una revisión adicional del perfil de evolución.

Registrar los doce no implementa sus usos especiales. Siguen separados:

- Negra/blanca: condiciones y frecuencia de encuentros del mundo.
- Roja/amarilla: uso desde mochila en combate para atracción/confusión.
- Cola Skitty/Poké Muñeco: uso desde mochila para huir.
- Pañuelos: concursos, fuera de los sistemas disponibles del juego.
- Azul: conserva el uso de campo de V19, despertando sin consumo. Ahora además
  entra correctamente equipada en nativo y atraviesa guardar/cargar/combate.

No se habilitan los ocho potenciadores de combate ni otros usos no implementados.
El total de efectos de campo sigue siendo 77. No se añade ninguno de estos
objetos a pools de obtención automáticamente ni se cambian las exclusiones.

## Importación y propiedad

`tools/item_import/import_held_v20.py` transforma las filas fijadas en
`modules/battle/backends/showdown/field_misc_items_v20.json`. La selección consta
de doce IDs revisados, no de todo objeto desconocido. Exige hashes, permiso,
capacidad de equipar, ausencia de efecto pasivo y correspondencia exacta entre
nombre nativo e ID; no ejecuta código externo ni interpreta descripciones.
El generador separa sus contextos de campo/mochila de los metadatos equipados.

El adaptador existente importa esas definiciones, las congela y conserva su
política de conflicto/cachés. No se modifica NativeEngine ni Node instalado,
callbacks de combate, RNG, datos canónicos, arte, políticas o schema de guardado.
La UI y los servicios de campo no se modifican en esta fase.

Poké Muñeco encontró un fallo real: el nombre RHH «Poké Doll» se convertía en
`pokdoll` al filtrar caracteres en el simulador. El generador translitera el nombre
inglés a «Poke Doll» y exige que derive exactamente `pokedoll`. Los nombres
españoles y el ID canónico no cambian. La primera ejecución fallida se conserva;
no se altera el normalizador del motor ni se acepta el ID erróneo como alias.

## Pruebas

```text
python tools/item_import/import_held_v20.py --check
python tests/tools/test_held_import_v20.py
python tools/verification/run_field_held_v20.py
```

El importador reutiliza los encabezados locales fijados en V13 y las referencias
de generación de V16. `--check` recompila sin escribir; `--write` solo actualiza
el manifiesto propio. Para jugar no se necesitan esas fuentes ni el importador.

El contrato nativo verifica cada ID en tres perfiles, checkpoints y continuación
determinista, ausencia de activación de uso de mochila por estar equipado,
Lanzamiento con control independiente de potencia 10/30, Truco, Desarme,
Sala Mágica, objetos ya consumidos, preparar/abortar/confirmar, cachés y rechazo
de los siete no revisados. Los controles existentes de potencia 30 se conservan.

La integración Godot usa el contrato de propiedad existente para los doce IDs,
con captura, transferencia, persistencia del cambio de objeto y ausencia de
duplicación. Cuatro rutas de la escena real verifican mochila, equipar,
guardar/cargar antes y durante combate, liquidación y usos especiales rechazados.
Flauta Azul vuelve a probar su cura de sueño y ausencia de consumo después de
la liquidación nativa. También hay ejecución GPU y regresiones.

Resultados y fuentes: [ITEM_FIELD_HELD_V20.json](ITEM_FIELD_HELD_V20.json).
Resultado final: **11 grupos PASS**; contrato nativo 74, regresión nativa previa
14, integración del lote 267 y GPU 71 comprobaciones. Las pruebas del compilador
tienen cuatro métodos. El guard comprobó 23.050 archivos protegidos por hash
completo y conservó 15.647 ausentes con skip-worktree. Captura revisada: Flauta
Azul equipada, dos unidades en mochila y uso reutilizable tras el combate.
Los 189 escenarios históricos de efectos equipados siguen siendo un contador
aparte; no se suman doce efectos nuevos por añadir doce definiciones.
Ejecuciones preservadas: `.godot/field_held_v20/runs/` y `node_runs/`.
El guard de esta fase conserva el resto contra `aeb2c8b1`; no se resellan fases
anteriores. Los probes de registro V16–V18 actualizan el inventario esperado
actual, conservando los escenarios y los informes/baselines históricos.

## Fuentes y créditos

RHH / rh-hideout y colaboradores, **pokeemerald-expansion**,
`8654616bd38d9b28cc7dd8f3d0b4cb030aa2d40c`, `src/data/items.h`: nombre,
ausencia de efecto equipado, potencia y contextos. Procedencia y SHA-256 van
incorporados al manifiesto. Fuente:
[RHH](https://github.com/rh-hideout/pokeemerald-expansion/tree/8654616bd38d9b28cc7dd8f3d0b4cb030aa2d40c).

pret y colaboradores: referencias locales fijadas de **pokered**, **pokecrystal**
y **pokeemerald**, reutilizadas de V16 para presencia/ausencia por generación.
Poké Muñeco consta en Gen 1; los otros once constan en Gen 3 y no en las dos
referencias anteriores. Se conservan sus hashes exactos, sin ejecutar los juegos.
Mantener estos agradecimientos en los créditos del proyecto.
