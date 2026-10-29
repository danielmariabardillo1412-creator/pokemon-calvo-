# V14 — Campana/Cascabel Alivio y equipados de campo

Base: `cff1b50`. La continuación automática del objetivo pide corregir el fallo
y continuar con objetos. Se corrige el rechazo `Unknown held item` al iniciar
combate con `soothe_bell` equipada; no se elimina, cambia por otro ID ni convierte
en un objeto vacío. La naturaleza, IV, EV, amistad y las reglas de combate no se
reescriben para conseguir que arranque.

## Cambio y fuente

El simulador competitivo instalado no incluye este objeto de campo. El módulo
propio `field_held_items.cjs` registra únicamente su nombre, generación 3 y
metadato de Lanzamiento de potencia 10. No contiene callbacks de mecánicas.
La fuente del dato es `src/data/items.h` de rh-hideout/pokeemerald-expansion,
commit `8654616bd38d9b28cc7dd8f3d0b4cb030aa2d40c`; créditos RHH y colaboradores.
La amistad de campo sigue siendo responsabilidad de `FieldFriendship`.

`native_engine.cjs` instala esa definición antes de crear/restaurar combates.
La instalación es local al proceso, idempotente, contempla Dexes ya cargadas y
no reemplaza definiciones nativas existentes. Un conflicto explícito falla;
un ID no revisado continúa rechazándose. Se invalidan solo las cachés necesarias
para descubrir la definición añadida. Los descriptores previos se conservan.

No se editan los paquetes instalados de Node/Showdown, fórmulas, IA, RNG,
perfil de combate, datos, arte o esquema de guardado. El cambio del adaptador
propio es una carga de metadatos; Lanzamiento, Desarme, Truco y Espacio Mágico
siguen ejecutándose con los manejadores originales del motor.

## Evidencia funcional

- Inicio, restauración y continuación en gen8customgame, gen9customgame y
  gen9calvounifiedv1; Campana activa y ya consumida. Una consumida no reaparece.
- Lanzamiento consume el objeto y usa potencia 10, contrastada contra Muda
  Concha. Sin objeto falla. Espacio Mágico, provocado con su movimiento real,
  bloquea Lanzamiento y conserva la Campana.
- Desarme retira el objeto y aplica su incremento normal de daño. Truco lo
  entrega al destinatario en lugar de borrarlo.
- Preparar/abortar no publica un objeto perdido; confirmar sí publica el estado
  nativo preparado. Hay Campanas independientes en las reservas de ambos bandos
  y se conserva su dueño por instance_id al cambiar de Pokémon.
- La escena real equipa desde la mochila, usa Proteína con el multiplicador de
  amistad existente, guarda/carga, entra al combate y guarda/restaura allí.
  Se ejecutan tres rutas: conservar, lanzar y entregar al salvaje con Truco para
  después capturarlo. Se cuentan las Campanas físicas en inventario, equipo y PC:
  dos se conservan o transfieren; tras Lanzamiento queda una. Retirar un equipado
  ya perdido no devuelve otra copia. El receptor capturado sí puede devolver su
  Campana una vez. Las partidas posteriores retienen esas cantidades.

El verificador nativo usa un proceso nuevo para comparar una traza ordinaria con
el adaptador exacto de `cff1b50`: estados, RNG, daño, objetos y hashes coinciden.
Se excluyen solo tiempo de ejecución y marcas de reloj del protocolo, no estado
del juego. Las restauraciones gen8/gen9 históricas se comparan semánticamente en
su punto inicial por el orden conocido de formatid; no se modifican sus hashes
históricos. El perfil unificado conserva comparación exacta de hash.

La prueba V13 que reproducía el rechazo se actualiza a exigir el inicio correcto,
con Campana en el espejo y campaña intacta. No se cambia su informe histórico ni
se retiran sus aserciones EV. La prueba real V14 añade la cadena completa.

## Barrido adicional de definiciones

Se compararon los IDs equipables del perfil con el Dex nativo, incluyendo el
alias de cristales Z. Resultado tras el arreglo: 631 IDs en la lista bruta;
625 permitidos por la política; 563 tienen definición y **62 no la tienen**.
Los cuatro IDs ausentes restantes de la lista bruta están vetados y no se activan.

Esto es inventario estático, no certificación de 563 efectos. Los 62 ausentes
incluyen medicinas, vitaminas, objetos de entrenamiento, flautas y accesorios.
No se registran automáticamente como neutros: hay que contrastar sus metadatos
y separar efectos de campo, economía, evolución u otros sistemas aún pendientes.
El listado, categorías y hashes de las entradas se conservan en el JSON V14 y
en `.godot/field_held_v14/remaining_held_inventory.json`.

## Reproducción y límites

```text
python tools/verification/run_field_held_v14.py
```

Se ejecutan once casos nativos, pruebas Godot de integración y regresiones de
núcleo, caramelos, mochis, entrenamiento, campo y restauración, además de GPU.
Manifiesto propio, sin resellar fases anteriores. Resultados reales, hashes y
captura: [ITEM_FIELD_HELD_V14.json](ITEM_FIELD_HELD_V14.json).

Los fallos iniciales del comprobador se conservan: comparación de tiempos/orden
de serialización heredado, montaje manual incompleto de Espacio Mágico y supuesto
erróneo de que la reserva mantenía el índice de array tras cambiar. Se corrigió
la preparación y comparación, sin cambiar el motor para satisfacer esas pruebas.

Siguen siendo 76 los efectos de campo y doce las bolas conectadas. Este arreglo
no añade un efecto pasivo de combate nuevo ni resuelve la paridad de amistad de
mochis con SV. No se certifican todos los equipados por corregir una definición.
