# V17 — 17 consumibles equipados y contrato de pruebas compartido

Base: `32286f73`, en la copia organizada. Se continúa el puente de objetos
equipados con una lista revisada de 17 IDs; no se cambia el sistema de guardado,
datos, políticas, arte, paquetes instalados, algoritmos de combate o RNG.

## Alcance concreto

| Familia | IDs |
| --- | --- |
| Vitaminas (6) | calcium, carbos, hp_up, iron, protein, zinc |
| Mejoras de PP (2) | pp_up, pp_max |
| Subida de nivel (1) | rare_candy |
| Potenciadores de combate (8) | dire_hit, guard_spec, x_accuracy, x_attack, x_defense, x_sp_atk, x_sp_def, x_speed |

Los 17 reciben únicamente nombre, generación y potencia 30 de Lanzamiento en
`field_held_items.cjs`. No tienen callbacks ni efectos pasivos inventados. Llevar
Proteína no concede EV, llevar un Caramelo Raro no concede niveles y llevar un
objeto X no aumenta estadísticas automáticamente. Lanzamiento, Desarme, Truco,
Espacio Mágico y las transacciones los sigue resolviendo el motor nativo.

Los nueve consumibles de entrenamiento conservan los usos de campo ya conectados
en V7/V8/V9, incluyendo límites, amistad, decisiones de progresión y consumo. Los
ocho potenciadores X/Directo/Protección no ganan por este puente una acción de uso
desde mochila: campo los rechaza sin gastar, y su uso en combate sigue pendiente
de una conexión específica. Registrar un objeto equipado no implementa su acción
de uso. No se amplía el perfil de medicina de combate.

## Organización del verificador

Se extraen los seis escenarios nativos repetidos de V16 a
`held_item_contract.cjs`. Los datos esperados de cada familia viven en
`held_item_reference_rows.cjs`, separados del módulo productivo. V16 y V17 quedan
como dos entradas breves con sus listas y salidas propias. El contrato exige la
lista completa de descriptores revisados, metadatos sin callbacks, conservación
de los objetos nativos existentes y rechazo de IDs no revisados.

La prueba Godot de V16 comparte su caso de propiedad/restauración con V17 mediante
un parámetro explícito de soporte de uso de campo. Añade la comparación de nivel,
XP, IV, EV y naturaleza antes/después; no elimina las comprobaciones anteriores.
Se ejecuta de nuevo V16, además de la regresión de Campana, para verificar la
extracción. Los manifiestos e informes históricos permanecen sin resellar.

## Referencias y créditos

RHH y colaboradores, [pokeemerald-expansion items.h](https://github.com/rh-hideout/pokeemerald-expansion/blob/8654616bd38d9b28cc7dd8f3d0b4cb030aa2d40c/src/data/items.h),
commit `8654616bd38d9b28cc7dd8f3d0b4cb030aa2d40c`, SHA-256
`107f1b78a457f3a9c48749f325d674b62fe559b0ebfc365db13e82b00b19ecd3`.
En las 17 entradas, flingPower es 30 y holdEffect está omitido (valor cero de la
estructura C). La generación se contrasta con las cuatro fuentes pret ya fijadas
en V16: Red, Crystal, Emerald y Platinum. No hay nuevas descargas. Se documentan
los alias históricos X_DEFEND/X_SPECIAL y los hashes exactos de las copias leídas.

## Comprobación

`python tools/verification/run_field_held_v17.py`

Resultados reales, referencias y hashes en
[ITEM_FIELD_HELD_V17.json](ITEM_FIELD_HELD_V17.json).

- Inicio, restauración tras un turno y continuación determinista para cada ID
  en gen8customgame, gen9customgame y gen9calvounifiedv1: 51 combinaciones de formato/ID.
- Comparación contra un portador sin objeto: no hay curación, PP extra, cambios de
  estadísticas, etapas o habilidad por llevarlo. Lanzamiento usa un control nativo
  de potencia 30 y no cura al receptor. Transferir, desarmar y suprimir conservan
  la identidad real del objeto. Preparar/abortar no publica cambios prematuros.
- Las 17 entradas atraviesan el puente Godot con equipamiento de inventario real,
  revisión obsoleta rechazada, dos restauraciones y captura. Se alternan conservar,
  lanzar, transferir y desarmar. Las unidades consumidas no reaparecen al desequipar.
  Los ocho usos de campo no implementados se rechazan sin mutar el estado.
- Cuatro rutas del mapa: Proteína conservada, Más PP lanzado, Calcio transferido
  y Ataque X conservado. Guardar/cargar antes del combate y tras cambiar el objeto;
  después usar explícitamente desde mochila los consumibles soportados. Los EV/PP
  y la amistad se comprueban y persisten. Ataque X conserva su unidad al rechazar uso.
- Regresiones nativas de V16 y Campana; integración Godot V16; vitaminas, PP,
  caramelos, núcleo, campo y restauración. GPU repite las cuatro rutas de interfaz
  sin duplicar los casos no visuales.
- Manifiesto propio congelado antes de editar y verificación completa por hash
  del resto de archivos; informes e intentos fallidos se conservan por ejecución.

El primer intento Godot se rechazó por una variable del test sin tipo inferible;
se declaró CreatureInstance. No se interpretó como PASS ni se cambió el motor
para satisfacerlo. Se conserva la normalización temporal de protocolo del
contrato previo; no se omiten estado, RNG ni hashes de las comparaciones.

## Pendientes y límites

El registro alcanza 604 de los 625 equipables permitidos. Quedan 21 sin definición
nativa, detallados en el JSON: necesitan revisión propia; no se consideran neutros
por defecto. Los 42 descriptores del puente no certifican todos los efectos de esos
objetos ni completan los ocho usos de potenciadores en combate.

Se mantienen 76 efectos de campo y 16 bolas conectadas. Mentas/IV, condiciones de
formas/evolución, efectos de mundo y fidelidad completa de captura siguen separados.
