# Diez evolutivos de intercambio — revisión V26

**PASS: los diez objetos revisados quedan excluidos del conjunto utilizable.**

Su función específica es el requisito evolutivo de intercambio. El simulador
instalado los describe así y no define callbacks propios de combate para ellos.
Todos permiten Lanzamiento, con distintas potencias; ese uso genérico no se
considera suficiente para conservar objetos que sobran en el diseño elegido.

## Objetos apartados

| Objeto | ID | Potencia de Lanzamiento reconocida |
| --- | --- | --- |
| Escama Dragón | `dragon_scale` | 30 |
| Disco Extraño | `dubious_disc` | 50 |
| Electrizador | `electirizer` | 80 |
| Magmatizador | `magmarizer` | 80 |
| Escama Bella | `prism_scale` | 30 |
| Protector | `protector` | 80 |
| Tela Terrible | `reaper_cloth` | 10 |
| Saquito Fragante | `sachet` | 80 |
| Mejora | `up_grade` | 30 |
| Dulce de Nata | `whipped_dream` | 80 |

La política impide generarlos incluso si el llamador los declara utilizables,
equiparlos o usarlos mediante las APIs de mochila/evolución. No se borran sus
definiciones de los datos originales ni se purgan objetos de partidas antiguas.
Se mantienen los vetos previos, incluido Cordón Unión; no se añaden otros.

## Objetos conservados

- Revestimiento Metálico: potencia ataques de Acero.
- Roca del Rey: probabilidad de retroceso en ataques compatibles.
- Diente Marino: Ataque Especial de Clamperl.
- Escama Marina: Defensa Especial de Clamperl.

Sus efectos existen en el simulador y son independientes de la evolución. Las
cartas/revivir conservan los vetos anteriores; no se confunde Poké Muñeco con
decoración. Los pañuelos de concurso y otras familias no se excluyen en este lote.

## Evoluciones: todavía aplazadas

No se programa la sustitución del intercambio por nivel ni se cambia su tabla.
Ver [TRADE_EVOLUTIONS_FUTURE.md](TRADE_EVOLUTIONS_FUTURE.md). Más adelante se
contrastarán otros juegos y se definirán los niveles/destinos adecuados. El
intercambio como disparador no exige por sí mismo un nivel mínimo oficial;
los posibles niveles de fases previas no son una tabla de conversión ya definida.

## Verificación

- 5 grupos PASS y 6931 comprobaciones, incluidas regresiones.
- Diez casos de límites de política y conservación de inventario, con sus
  especies pertinentes; ningún método de uso/equipar/evolucionar evita el veto.
- Se conservan la evolución normal por nivel y por piedra y los cuatro objetos
  con otro papel en combate. No se introduce evolución provisional de Haunter.
- 54 objetos excluidos; 614 equipables permitidos, 611 reconocidos por el
  backend. Amulet Coin, Exp. Share y Luck Incense siguen como dependencias.
- Guarda completa PASS: 23.133 archivos protegidos y 15.647 ausentes preservados.
  No se modifica el motor, EvolutionSystem, especies, movimientos, habilidades,
  RNG, arte, datos canónicos ni formato de guardado. Sí cambia, por diseño, la
  política de selección de estos diez objetos.

La lista de funciones y callbacks procede del paquete local @pkmn/sim 0.10.11,
protegido por la guarda. El informe JSON conserva descripciones y comandos.
No se certifican todos los objetos por pasar esta revisión. Los informes V25
y anteriores describen sus checkpoints; no se regeneran con los vetos nuevos.

Informe: [ITEM_TRADE_EXCLUSIONS_V26.json](ITEM_TRADE_EXCLUSIONS_V26.json).
Evidencia: `.godot/trade_item_exclusions_v26/results.json`.
