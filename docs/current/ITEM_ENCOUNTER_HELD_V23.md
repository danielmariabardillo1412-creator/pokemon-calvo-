# Amuleto e Incienso Puro — entrada nativa V23

Estado: **PASS de entrada nativa; tasa de encuentros aún parcial.** Base nueva: `2fee506c7f309c966efc2a348a13aaf6018b8415`.
La misión ITEM_CLOSURE_V2 está cerrada; no se resellan sus guardas ni se reescribe
su evidencia. La nueva guarda vive en `.godot/encounter_held_v23/scope_base.json`.

## Problema y cambio

Los dos IDs ya se podían equipar y reducían la tasa del encuentro a 2/3, pero
el adaptador rechazaba el combate por `Unknown held item`. Se añade un manifiesto
nuevo y dos descriptores al registro propio, sin callbacks ni cambios de motor,
RNG, datos, políticas, arte o schema. Los efectos de encuentro siguen teniendo
como dueño `encounter_item_modifiers.gd`; no se registra un efecto pasivo ficticio.

Amuleto: generación 2, Lanzamiento 30. Incienso Puro: generación 4, Lanzamiento 10.
El importador verifica fuentes por SHA-256 y falla ante otro nombre, efecto o potencia.
Los manifiestos históricos de V20/V2 se conservan como snapshots de sus fases.

## Referencias y créditos

- [RHH pokeemerald-expansion](https://github.com/rh-hideout/pokeemerald-expansion/tree/8654616bd38d9b28cc7dd8f3d0b4cb030aa2d40c):
  metadatos de ambos objetos, `HOLD_EFFECT_REPEL` y potencias de Lanzamiento.
- pret [pokecrystal](https://github.com/pret/pokecrystal/blob/master/constants/item_constants.asm),
  [pokered](https://github.com/pret/pokered/blob/master/constants/item_constants.asm),
  [pokeemerald](https://github.com/pret/pokeemerald/blob/master/include/constants/items.h) y
  [pokeplatinum](https://github.com/pret/pokeplatinum/blob/main/generated/items.txt):
  prueba local de generación. Los hashes exactos están en el manifiesto V23.
- Se conserva la adaptación parcial de Essentials ya documentada en V2 y su crédito;
  el simulador @pkmn/sim 0.10.11 sigue resolviendo Lanzamiento, Truco y Desarme.

## Alcance que sigue parcial

Solo se representa la tasa de encuentro del perfil actual. Las condiciones de
pasos mínimos y la crianza de Incienso Puro siguen fuera del sistema disponible.
Los otros cuatro descriptores pendientes conservan sus dependencias: Amulet Coin,
Exp. Share, Linking Cord y Luck Incense. No se certifican todos los efectos de objetos.

## Verificación

`python tools/verification/run_encounter_held_v23.py` — PASS.

- 9 grupos y 1.559 comprobaciones ejecutadas: 17 nativas, 253 de integración
  de equipamiento/mapa y 45 con GPU, más importación y regresiones de encuentros,
  mapa nativo, restauración y objetos de apoyo.
- Tres perfiles nativos: Gen8, Gen9 y unificado. Guardado/carga y continuidad
  determinista; Lanzamiento 30/10, Truco, Desarme y rechazo de revisión obsoleta.
- 8 rutas directas y 6 desde el mapa; las capturas repiten 2 rutas de conservar.
  Se prueba fallo de encuentro y encuentro real con el objeto, y que la tabla
  original permanece intacta. Un objeto perdido/transferido deja de afectar al líder.
- 621/625 equipables permitidos reconocidos; quedan exactamente los cuatro
  huecos enumerados arriba. No se añaden descriptores neutros para esos cuatro.
- Guarda nueva `--full` PASS: 23.119 archivos protegidos y 15.647 ausentes
  preservados. Los informes y sellos V2 históricos permanecen intactos.
- Capturas de ambas mochilas vistas: icono, cantidad y equipamiento correctos,
  sin recortes. El mensaje genérico tras intentar «Usar» aún dice que la función
  está pendiente; se refiere al uso directo rechazado y queda como deuda de texto.
  No se interpreta ese mensaje como comprobación del efecto pasivo.

Informe parseable: `ITEM_ENCOUNTER_HELD_V23.json`, con rutas y SHA-256 de las
fuentes probadas, capturas y logs. Los grupos se solapan con pruebas anteriores;
no equivalen a certificar 1.559 objetos distintos.


El intento inicial del test de mapa llamó a una API incorrecta del puente; se
corrigió el test para consultar `occupied()`. La ejecución fallida se conserva,
y no cuenta como PASS. La prueba de identidad de caché se limita a objetos del
simulador: el instalador puede recrear sus propios descriptores revisados.

Checkpoint funcional local: `b9ca439c52ac10aea2da3f1f37c6f1de3090f34f`.
