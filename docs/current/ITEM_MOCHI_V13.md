# Objetos V13 — siete rutas de EV de mochis

Base: `c1f71c74`. Se conectan los seis mochis de mejora y Mochi Reinicio al
servicio existente. Se verifican sus cambios de EV, estadísticas derivadas,
consumo, propiedad y persistencia; **no se certifica paridad completa de amistad
con Escarlata/Púrpura**. No cambia naturaleza, IV, esquema, datos, arte, políticas,
motor nativo, RNG ni la generación de inventario.

## Contrato fijado y discrepancia de referencias

Se utiliza la tabla de efectos de **rh-hideout/pokeemerald-expansion**, commit
`8654616bd38d9b28cc7dd8f3d0b4cb030aa2d40c`:
`src/data/items.h`, `src/data/pokemon/item_effects.h`,
`include/constants/item_effects.h` y el intérprete de `src/pokemon.c`.
Los seis efectos añaden diez EV y no contienen flags de amistad; Reinicio
restablece las seis estadísticas sin esos flags. Se consultaron archivos de
referencia en `.godot/item_mochi_v13/references/`, sin ejecutar/importar ese motor.

| ID canónico | Efecto |
| --- | --- |
| `health_mochi` | +10 EV PS |
| `muscle_mochi` | +10 EV Ataque |
| `resist_mochi` | +10 EV Defensa |
| `genius_mochi` | +10 EV Ataque especial |
| `clever_mochi` | +10 EV Defensa especial |
| `swift_mochi` | +10 EV Velocidad |
| `fresh_start_mochi` | Todos los EV existentes a cero |

Rigen los límites comunes de 252 por estadística y 510 totales. Si solo cabe
parte del incremento, se añade esa parte y se consume una unidad. Si no hay
cambio de EV, no se consume ni se reemplaza la criatura. Reinicio sobre todos
los EV a cero tampoco tiene efecto. No se normaliza un reparto corrupto.

**Amistad pendiente de contraste:** la copia consultada de Generation 9 Pack
(Caruban y colaboradores, distribuida en
`Manurocker95/Pokemon-Essentials-21-With-Unofficial-EBDX`, commit
`ebf87d8d2402457e7413577d6b98ab4595d044d3`) enlaza los seis a vitaminas y añade
amistad incluso en Reinicio. La tabla de RHH no lo hace. También se encontraron
tablas públicas con otros valores. No se declara que esos motores sean
equivalentes ni que una copia comunitaria pruebe las reglas oficiales.
V13 conserva la amistad según la referencia de efectos RHH; no extrapola el
5/3/2 de vitaminas ni el 3/2/1 de plumas del perfil local. Confirmar paridad real
queda registrado antes de dar por certificados todos los efectos del catálogo.

Se recalculan estadísticas con `StatCalculator` mediante el método existente de
criatura. Se conserva el déficit de PS, con mínimo 1 al reducir el máximo.
Un Pokémon KO se rechaza: el objeto no revive. Se preservan PP máximos/gastados,
estado persistente, relojes, amistad, naturaleza, IV, identidad, shiny y equipo.

## Arquitectura

`field_mochi_effects.gd` reúne las reglas puras y valida el origen antes de que el
serializador pueda convertir EV/IV inválidos. Reutiliza validación de entrenamiento
y el calculador existente. No recibe inventario, UI, IO, RNG ni otros servicios.
`field_item_effects.gd` lo despacha por la transacción de `FieldItemService`;
el servicio conserva su autoridad de copia, propiedad, publicación y consumo.
La mochila distingue mejora de Reinicio y comunica que la amistad no cambia.

No se añade otra transacción de crecimiento, evoluciones implícitas ni cambios
en `field_demo.gd`. La escena real verifica toda la cadena hasta combate/captura.

## Verificación y dependencia encontrada

30.128 casos: 1.076 especies/formas permitidas × siete objetos × cuatro repartos
de EV. Hay casos sin efecto, límites 252/510, incrementos parciales y reinicio.
El oráculo calcula las seis estadísticas con fórmula entera independiente.
Otras 756 combinaciones cubren equipo/PC, amistad, Campana Alivio activa/consumida,
naturalezas, PP aumentados/gastados, sueño y relojes, con estado completo.
Se rechazan KO, transformación, inventario inválido, falta de propiedad/objeto,
slot de movimiento, EV/IV inválidos, total excedido, stats incoherentes y PP nulo.

Controles nativos usan EV de Ataque 252, 0 tras Reinicio y 10 tras mochi. Con
misma semilla, el daño observado es 15, 12 y 12. La mejora de diez EV no promete
un punto de daño adicional en cada ataque; también se verifica la estadística
recibida por el motor.

**Campana Alivio pendiente del puente nativo:** equipada, el motor rechaza el
inicio con `Unknown held item`. V13 reproduce ese rechazo y comprueba que no
muta campaña; no descarta el objeto ni cambia el worker para simular soporte.
La Campana sí se conserva en los casos del servicio de campo. El recorrido real
de mochila/guardar/cargar/combate/restaurar/capturar utiliza Restos, admitido por
el motor, y conserva sus datos. No se anuncia la Campana como funcional en nativo.

El primer intento falló por una anotación de tipo ausente del verificador.
Otro intento produjo un error de script tras el rechazo nativo; aunque su JSON
parcial escribió PASS, el runner lo clasificó FAIL por `SCRIPT ERROR`, sin
aceptarlo como evidencia. Se añadieron guardas explícitas y se reprodujo la
dependencia de Campana por separado. Todos los intentos y logs se conservan.

```text
python tools/verification/run_mochi_v13.py
```

El runner incluye núcleo, caramelos, habilidades, entrenamiento V7, campo nativo,
restauración y GPU, con manifiesto propio sin resellar fases históricas.
Resultados, hashes y límites: [ITEM_MOCHI_V13.json](ITEM_MOCHI_V13.json).

Créditos de la referencia de efectos: RHH y colaboradores. El Gen 9 Pack se
consultó como contraste (Caruban, Lucidious89 y colaboradores; distribución de
Manurocker95), sin instalarlo ni copiar sus cambios de amistad al juego.

Cierre del alcance EV: nueve grupos PASS; 91.991 comprobaciones headless y
91.993 GPU. Matriz: 22.596 usos con efecto y 7.532 sin efecto. Hay 76 efectos
de campo conectados y doce bolas de captura, con los límites anteriores explícitos.
