# V16 — 24 medicinas equipadas compatibles con el combate nativo

Base: `d0b1d8b`, en la copia organizada. Se continúa la conexión de objetos
disponibles autorizada por el usuario. Las medicinas de este lote ya tenían
uso de campo; faltaban sus definiciones cuando un Pokémon las llevaba equipadas.

## Cambio concreto

Se añaden 24 descriptores revisados al módulo existente `field_held_items.cjs`.
Solo contienen nombre, generación y potencia de Lanzamiento (30). No tienen
callbacks, curación automática, consumo al equipar adicional ni efectos propios
de combate. El adaptador ya instalaba este módulo desde V14; no se modifica
`native_engine.cjs` ni los paquetes instalados del simulador.

| Familia | IDs revisados |
| --- | --- |
| Recuperación de PS (11) | potion, super_potion, hyper_potion, max_potion, full_restore, fresh_water, soda_pop, lemonade, moomoo_milk, energy_powder, energy_root |
| Estados (9) | antidote, awakening, burn_heal, ice_heal, paralyze_heal, full_heal, heal_powder, lava_cookie, old_gateau |
| PP (4) | ether, max_ether, elixir, max_elixir |

Llevar una Poción no la bebe ni cura al portador; llevar una medicina amarga no
baja su amistad. Su uso explícito desde la mochila sigue perteneciendo al
servicio de objetos y conserva sus cantidades, curas, PP y penalización por
amargor. Lanzamiento, Desarme, Truco y Espacio Mágico los resuelve el motor
nativo con esos datos; no se copian sus reglas a Godot.

La instalación conserva los descriptores nativos existentes y las comprobaciones
de conflicto/cache de V14. No se admiten IDs desconocidos. Revivir y otros objetos
vetados no se registran ni se habilitan por aparecer cerca en la tabla original.

## Fuentes y créditos

Potencia de Lanzamiento y ausencia de efecto equipado: RHH y colaboradores,
[pokeemerald-expansion, items.h](https://github.com/rh-hideout/pokeemerald-expansion/blob/8654616bd38d9b28cc7dd8f3d0b4cb030aa2d40c/src/data/items.h),
commit `8654616bd38d9b28cc7dd8f3d0b4cb030aa2d40c`, SHA-256
`107f1b78a457f3a9c48749f325d674b62fe559b0ebfc365db13e82b00b19ecd3`.
En las 24 entradas, flingPower vale 30 y holdEffect está omitido (cero por
inicialización de la estructura C). holdEffectParam de algunos consumibles es
un parámetro de su uso; no se interpreta como un efecto equipado inexistente.

Generación: contraste de presencia en las fuentes de pret y colaboradores de
[Red](https://github.com/pret/pokered/blob/master/constants/item_constants.asm),
[Crystal](https://github.com/pret/pokecrystal/blob/master/constants/item_constants.asm),
[Emerald](https://github.com/pret/pokeemerald/blob/master/include/constants/items.h) y
[Platinum](https://github.com/pret/pokeplatinum/blob/main/generated/items.txt).
Se registran URLs, bytes y SHA-256 de las copias leídas. Los nombres históricos
PARLYZ_HEAL/ELIXER/MAX_ELIXER/ENERGYPOWDER se cruzan explícitamente con sus IDs
actuales. No se ejecuta código de estas referencias ni se regenera un dataset.

## Verificación reproducible

`python tools/verification/run_field_held_v16.py`

El JSON [ITEM_FIELD_HELD_V16.json](ITEM_FIELD_HELD_V16.json) contiene resultados,
hashes, lista revisada, prueba de fuentes, rutas, capturas y límites.

- Cada medicina entra, guarda/restaura y continúa de forma determinista en
  gen8customgame, gen9customgame y gen9calvounifiedv1.
- Las 24 se prueban equipadas con PS/PP reducidos y veneno: no curan ni restauran
  automáticamente. Lanzamiento hace el mismo daño que el control nativo de
  potencia 30 y no cura al receptor. Se comprueban Truco, Desarme con su aumento
  de daño, Espacio Mágico y preparar/abortar/confirmar sin publicar por adelantado.
- Las vistas Godot reciben el ID exacto de las 24, con inventario real, revisión
  obsoleta rechazada, dos restauraciones por caso y captura final. Se alternan
  conservar/lanzar/transferir/desarmar, contando unidades en mochila/equipo/PC.
  Retirar un slot consumido no devuelve una unidad ficticia; el receptor capturado
  puede devolver su objeto transferido. El amargor no actúa por estar equipado.
- Cuatro rutas del mapa con mochila y guardar/cargar: Poción conservada,
  Elixir Máximo lanzado, Cura Total transferida y Raíz Energía conservada. Después
  se usa otra unidad explícitamente desde la mochila para verificar su efecto
  de campo y se vuelve a guardar/cargar el resultado. GPU repite estas rutas.
- Regresiones de Campana Alivio, traza ordinaria previa al puente, medicina y
  recuperación de campo, medicina nativa, núcleo, entrada y restauración.
- Manifiesto congelado antes de editar y comprobación completa por contenido de
  los archivos protegidos; los guards históricos no se resellan.

Se conservan los intentos fallidos: la primera comparación nativa incluía marcas
de reloj reales en vistas restauradas; se normalizó solo ese protocolo temporal,
conservando estado/RNG/hashes. Una primera carga Godot detectó una variable sin
tipo inferible en el test; se declaró int. No se cambió el motor para dar verde.

## Cobertura y pendientes

El registro pasa de 563 a 587 equipables permitidos con definición nativa, de
625 permitidos; quedan 38 sin definición. Esto es cobertura del registro y de
los escenarios descritos, no una certificación general de todos los efectos.
El inventario de pendientes se recalcula incluyendo alias de cristales Z y
mantiene los vetos actuales. No se etiquetan los 38 restantes como neutros.

Siguen siendo 76 los efectos de campo y 16 las bolas conectadas. V16 no añade
una medicina nueva de uso directo ni convierte las nueve medicinas de campo que
faltan del menú de medicina en combate en usos de combate admitidos. La interfaz
de medicina conserva su perfil explícito actual. Mentas, IV, mundo, formas,
evoluciones condicionadas y fidelidad de captura siguen como tareas separadas.
