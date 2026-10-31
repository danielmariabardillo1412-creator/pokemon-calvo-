# Cordón Unión V24 — adaptador de evolución

Estado: **PASS — ocho rutas conectadas; cuatro formas diferidas.** Base `ac6365997a08aa926fd27272884bf071f293c19d`.
Guarda nueva `.godot/linking_cord_v24/scope_base.json`. No se resellan las fases
V2/V23 ni se modifican sus manifiestos, fuentes canónicas, arte o evidencia.

## Comportamiento

El servicio de objetos reutiliza EvolutionSystem y su publicación de una
criatura nueva con la misma identidad. El helper de Cordón solo acepta las
rutas declaradas por la referencia y respaldadas por una arista `trade` simple
del catálogo vigente. No crea intercambios ni modifica registros canónicos.

Ocho rutas: Kadabra → Alakazam, Machoke → Machamp, Graveler → Golem,
Graveler de Alola → Golem de Alola, Haunter → Gengar, Boldore → Gigalith,
Gurdurr → Conkeldurr y Phantump → Trevenant. Se consume una unidad de mochila
únicamente después de una evolución válida. Llevarlo equipado no lo activa.

Se conserva nivel/EXP, IV/EV, naturaleza, amistad, shiny, movimientos/PP, estado,
PS e identidad; se recalculan estadísticas y se aplica la regla de habilidad
existente del sistema. No se rehacen progresión ni combate.

La Piedra Eterna activa bloquea el adaptador salvo Kadabra, siguiendo la
excepción moderna explícita de la referencia RHH. Una piedra ya consumida no
bloquea. Los debilitados y estados temporales de combate no se pueden usar para
revivir mediante este adaptador, conforme al límite del proyecto.

## Rutas que no se simplifican

Las cuatro rutas de tamaños de Pumpkaboo/Gourgeist están en la fuente, pero esas
formas no están representadas en el catálogo de ejecución. Se conservan como
DEPENDENCY_MISSING: no se sustituye su identidad por la forma base ni se consume.
Los intercambios que exigen un objeto o una especie compañera (Slowking, Steelix,
Escavalier/Accelgor, etc.) tampoco se convierten en rutas de Cordón por deducción.

## Presentación y otros objetos

Amuleto e Incienso Puro devuelven un motivo semántico de «equipar para efecto
pasivo» al intentar uso directo, y la vista muestra «Su efecto se activa al
llevarlo equipado; no se usa directamente». El rechazo no consume ni cambia al
Pokémon. El efecto de tasa y la deuda de pasos mínimos de V23 no cambian.

## Referencias y créditos

- [RHH, commit 8654616b](https://github.com/rh-hideout/pokeemerald-expansion/tree/8654616bd38d9b28cc7dd8f3d0b4cb030aa2d40c):
  `gen_1_families.h`, `gen_5_families.h`, `gen_6_families.h`, `items.h`,
  `pokemon.c` y `include/config/pokemon.h`. Se extraen 12 pares explícitos de
  intercambio/Cordón; 8 se pueden resolver y 4 quedan diferidos. Metadatos de
  Lanzamiento 30, nombre y uso evolutivo contrastados con la misma fuente.
- [PKHeX, ItemStorage8LA](https://github.com/kwsch/PKHeX/blob/master/PKHeX.Core/Items/ItemStorage8LA.cs)
  y [nombres de objetos](https://github.com/kwsch/PKHeX/blob/master/PKHeX.Core/Resources/text/items/text_Items_en.txt):
  identidad 1611 en el inventario de Legends: Arceus, generación 8. Se fijan los
  bytes descargados por SHA-256 en el compilador; no se consulta master al ejecutar.
- Los créditos anteriores de @pkmn/sim, Essentials y los recursos gráficos se
  mantienen. No se ejecuta código C/C# ni se descarga o regenera otro dataset.

## Verificación

`python tools/verification/run_linking_cord_v24.py` — PASS.

- 10 grupos / 10.946 comprobaciones, con regresiones solapadas: no son objetos
  distintos certificados. 2.453 del bloque de Cordón, 34 con GPU y 8 nativas.
- Barrido de 1.082 especies/formas: solo las ocho previstas ofrecen la ruta;
  las previsualizaciones no mutan. Evolución desde equipo y almacenamiento,
  invariantes persistentes, repetición sin gasto y rechazos de objetivo incorrecto,
  falta de objeto, guard bloqueado, debilitado, transformación y condición extra.
- Piedra Eterna activa/consumida y excepción de Kadabra; las condiciones de
  intercambios ajenos y formas pendientes no se descartan.
- Entrada nativa, guardar/cargar y continuación determinista en Gen8, Gen9 y
  perfil unificado; Lanzamiento/Truco/Desarme y ausencia de evolución al equipar.
- Dos recorridos reales del mapa: Haunter/Gengar y Graveler/Golem de Alola,
  mochila → evolución → guardar/cargar → combate → captura → liquidación.
- Cuatro capturas revisadas: evolución y cantidad restante de Cordón en ambos
  casos, más los avisos corregidos de Amuleto e Incienso Puro. Sin recortes.
- Guarda nueva con hashes completos: PASS, 23.125 archivos protegidos y
  15.647 ausentes preservados. No cambian motor, datos, políticas, arte o schema.
- Inventario nativo: 622/625 equipables permitidos reconocidos; quedan Amulet
  Coin, Exp. Share y Luck Incense, sin descriptores neutros.

Informe parseable: `ITEM_LINKING_CORD_V24.json`, con grupos, comandos, hashes,
fuentes, capturas y rutas de ejecución. Las capturas no certifican todo el arte.

El primer intento de mapa configuraba la demo entre evolución y combate, lo que
reinicia deliberadamente el equipo. Se movió esa preparación al inicio del test;
los cuatro fallos del intento quedan conservados y no cuentan como PASS.
Los datos de evolución del juego no se cambiaron para ajustar expectativas.
