# Comparación automática de combate

Herramienta de desarrollo para contrastar casos de nuestro **motor actual de Godot** con
Pokémon Showdown, mediante `@pkmn/sim@0.10.11`. No se incorpora otro motor al juego,
no se habilitan movimientos automáticamente y no se modifican datos canónicos.

## Ejecutar

Desde la raíz del proyecto, con Python 3.11+, Node.js y Godot 4.7 disponibles.
El proyecto debe haberse importado una vez en Godot para registrar sus clases globales.
La primera instalación necesita npm y acceso a su registro:

```powershell
python tools/battle_reference/run.py --install
```

Después, sin descargar de nuevo:

```powershell
python tools/battle_reference/run.py
python tools/battle_reference/self_test.py --integration -v
```

Los ejecutables se buscan en PATH. En este equipo también se reconocen las rutas
existentes de Node en D: y Godot en C:. En otro equipo se pueden indicar explícitamente:

```powershell
python tools/battle_reference/run.py --install --node 'D:/Herramientas/NodeJS/node.exe' --npm 'D:/Herramientas/NodeJS/npm.cmd' --godot 'C:/Godot/4.7/Godot_v4.7-stable_win64_console.exe'
```

Opciones: `--family all` (predeterminado), `--family stat_stages` o
`--family fixed_damage`, `--family variable_power`, `--family binding` o `--family healing`, `--batch-size 100` (1–1000), `--limit 12` para una prueba corta,
`--output ruta` y `--manifest ruta.json` para reproducir un manifiesto explícito.
La validación rechaza familias/contextos todavía no cubiertos por el adaptador.

En el barrido anterior de las primeras dos familias se comprobó `--batch-size 500`:
los mismos 1.932 escenarios pasan en cuatro lotes, con entradas, observaciones y
veredictos idénticos al barrido de 150. Medición local: 13,597 s frente a 37,491 s
anteriores; son dos ejecuciones, no un benchmark controlado ni una garantía para
familias futuras. Evidencia: `.godot/battle_reference/batch_size_500/comparison.json`.
El tamaño predeterminado del script sigue siendo 100; usar 500 explícitamente
para estos barridos y lotes pequeños al aislar un fallo. Esto reduce arranques de
los motores; no aumenta por sí solo el número de movimientos implementados.

## Familias disponibles

**Curación: 1.374 escenarios**, ocho movimientos: Aromaterapia, Cascabel Cura,
Alivio, Gota Vital, Cura Selvática, Plegaria Lunar, Purificación y Descanso.
Compara PS exactos y estado persistente de ambos activos y ambas reservas, PP y
ejecución. Incluye PS máximos 100–107 para distinguir redondeos, salud completa,
curación limitada por el máximo, quemadura/veneno/tóxico, reservas con otros
estados o debilitadas, habilidades inactivas de reservas, sustitutos,
Allanamiento, Espejo Mágico, Cuerpo Áureo y bloqueos de sueño de Descanso.

El primer barrido detectó 36 diferencias (inmunidades de habilidades de las
reservas tratadas como activas y redondeo de Gota Vital); el segundo aisló las
12 restantes de redondeo. Se corrigió el motor y el barrido completo posterior
compara **7.284 escenarios**, conservando los 5.910 anteriores.
Las entradas sintéticas no ejecutan fórmulas propias de curación en el adaptador
externo: se observan PS/estados tras el movimiento nativo de Showdown. Se rechazan
campos/contextos no admitidos y observaciones sin PS/estado/reservas.

El sueño completo de Descanso se comprueba aparte en el servidor real, con dos
acciones impedidas (una con Madrugar), despertar, save/replay, cambio a reserva
y curación desde la reserva por Cascabel Cura. La comparación externa de esta
familia cubre el movimiento inicial, no todo ese ciclo ni los relojes privados
de sueño de la IA. Controles: 42 unitarios y tres negativos con adaptadores reales.

**Etapas: 600 escenarios**, ocho movimientos, ambos lados y tres semillas:

- Niebla, Reversión, Cambiaalmas, Cambiafuerza, Cambiadefensa y Acupresión.
- Niebla Clara y Robasombra, incluyendo inmunidades Veneno/Acero y Fantasma/Normal.
- Etapas positivas/negativas/neutras/límites, reservas con etapas, sustitutos que
  sobreviven o se rompen y contextos concretos con Simple, Respondón,
  Allanamiento y Espejo Mágico.

Se comparan las siete etapas finales de ambos activos y ambas reservas, PP
consumidos, ejecución de la acción y presencia final del sustituto de cada activo.
La parte Godot pasa por `AuthoritativeBattleServer.submit_reaction_turn`, con el
perfil live real; no reimplementa el efecto del movimiento en Python.

**Daño fijo: 1.332 escenarios**, siete movimientos, ambos lados y tres semillas:
Furia Dragón, Bomba Sónica, Sísmico, Tinieblas, Superdiente, Furia Natural y
Calamidad. Se comparan **PS exactos** de ambos participantes, PS exactos de los
sustitutos, debilitamiento, PP, ejecución y reservas. Niveles 1/50/100, PS bajos e
impares, sustitutos de 1/25/500 PS, Allanamiento, inmunidades, resistencias, STAB,
etapas extremas, Potencia (Huge Power) sin multiplicar el daño, Multiescamas y
contacto con Punta Acero en escenarios sin KO del defensor. Las primeras dos
familias reúnen **1.932 casos**. El resto del contrato de habilidades sigue acotado.

**Potencia variable: 3.018 escenarios**, once movimientos, ambos lados y tres
semillas: Bola Voltio, Giro Bola, Azote, Inversión, Agarrón, Estrujón, Prensa
Metálica, Retribución, Frustración, As Oculto y Castigo. Se compara la potencia
real observada en el evento `BasePower` de Showdown frente a los metadatos del
daño/sustituto resuelto por Godot, contacto, impacto, PP y reservas. El observador
externo devuelve intacta la potencia recibida; no sustituye el cálculo original.
El barrido de las tres familias contiene **4.950 casos**.

**Atrapamiento: 960 escenarios**, diez movimientos: Atadura, Constricción,
Giro Fuego, Torbellino, Tenaza, Bucle Arena, Lluvia Ígnea, Acoso, Cepo y
Electrojaula. Compara efecto activo, cambio bloqueado, daño residual exacto y
validez del reloj natural (4/5 restantes tras el primer turno). Con Garra Garfio
se comparan además ocho turnos completos: siete ticks y liberación sin octavo
daño. Incluye Banda Atadura, Muda Concha, Restos, Fantasma, Muro Mágico,
sustitutos/Allanamiento e inmunidades de tipo. Son **5.910 casos** en total.

El reloj aleatorio ordinario no se fuerza a coincidir entre RNG diferentes;
el ciclo exacto usa el objeto que hace determinista la duración en el simulador
original. El daño residual se observa en su función nativa `damage`, conservando
argumentos, receptor y retorno. El evento `AfterDamage` del ataque no notifica
este daño de condición; el primer intento de observación no lo recogía y se
corrigió el adaptador antes de dar el barrido por válido.

El gate focal de Godot cubre repetición sin prolongar el efecto, retirada/KO del
origen, transmisión por Relevo, cambios, RUN bloqueado sin tirar el RNG de huida,
captura y limpieza, HUD y privacidad del reloj en la IA. No certifica todo el
orden de residuales con estados/habilidades pendientes, G-Max o interacciones
de Buceo. Fantasma/Muda Concha evitan el bloqueo; las reglas de huida restantes
siguen perteneciendo al sistema de escape existente. El registro canónico de
objetos y habilidades no se amplía por estos efectos locales de atrapamiento.

Se prueban fronteras de velocidad/etapas/parálisis, PS propios y del objetivo,
redondeo fijo de 4096 para Agarrón/Estrujón/Prensa Metálica, amistad 0–255,
PP antes/después de consumirlos, mejoras positivas (también precisión/evasión),
inmunidades y sustitutos/Allanamiento. No compara HP ordinarios exactos: cada
motor conserva su propio RNG y fórmula de daño. La potencia se aplica a una copia
del movimiento al ejecutarse, después de consumir PP; los datos siguen congelados.
Los once corrigen contacto en esa copia salvo Bola Voltio, que no lo hace.

El perfil live de individuales comparte velocidad racional exacta entre orden
del turno y estas fórmulas; el flag apagado conserva el cálculo histórico. No
se incorporan ahora todas las habilidades/objetos que modifican velocidad.
Los cuatro movimientos por peso (Patada Baja, Hierba Lazo, Cuerpo Pesado y Golpe
Calor) siguen pendientes de exponer ese dato con procedencia verificable.

Calamidad ya estaba admitido, pero el dataset congelado lo describe con potencia
1. Se corrige en la extensión live para quitar la mitad de los PS actuales,
redondeando hacia abajo y con mínimo 1. El adaptador de referencia registra
explícitamente esa diferencia de metadatos frente a basePower=0 de Showdown.
Solo se permite normalizar exactamente ese 1 a 0; otros cambios de potencia se
rechazan. Superdiente corrige contacto en una definición separada, conservando
el JSON original. Los seis movimientos nuevos siguen clasificados DATA_ONLY en
los datos inmutables; su ejecución se habilita exclusivamente con el perfil live.

En la referencia se usa `gen9customgame`, equipos explícitos, nivel 50, sin objetos
y habilidad neutra `No Ability` salvo la interacción seleccionada. Se fijan las
estadísticas base efectivas de ambos motores a valores sintéticos iguales:
20.000 HP, 100 Atq/Def/AtE/DeE y velocidad 200 del actor/100 del rival. HP altos
evitan introducir cambios forzados por KO en pruebas de etapas. El sustituto se
inyecta con 1 o 500 HP. El rival usa Splash como acción inerte **solo en este
laboratorio externo**; no se añade al pool del juego. Godot deja al rival pasivo.

En daño fijo se conserva el nivel/HP inicial explícito de cada fixture, con
20.000 HP máximos; esto comprueba que la mitad se calcula sobre HP actuales, no
máximos ni los de la muñeca. La tabla de PP se comprueba contra el contrato del movimiento y se desactivan los
PP Up de la referencia. Las reasignaciones de reservas se inyectan después del
inicio de batalla, de modo que detectamos si Niebla altera indebidamente el banco.

## Límites explícitos

Fuera de daño fijo no compara daño/HP exactos. No compara golpes críticos, distribución de azar, log completo de
eventos, animaciones, dobles ni todas las interacciones de habilidades. Las
semillas son reproducibles dentro de cada motor, **no equivalentes entre motores**.
Acupresión solo se compara con cero o una estadística elegible; Robasombra se
configura con precisión suficiente para garantizar el acierto. No se altera el
RNG del juego ni se disimulan como coincidencias tiradas aleatorias independientes.

Las especies y habilidades admitidas en fixtures están limitadas al contrato
actual. Ampliar la herramienta exige añadir normalización, observaciones y pruebas
para la siguiente familia. Un resultado verde de estos 5.910 casos no certifica
todos los movimientos admitidos ni convierte Showdown en la autoridad sobre
reglas propias del randomlock.

## Informes y controles

Resultados por defecto: `.godot/battle_reference/latest/`:

- `summary.md`: resultado legible y diferencias concretas.
- `report.json`: veredicto, casos, campos distintos, versiones, tiempos y hashes.
- `differences.csv`: únicamente diferencias y casos no comparables.
- `manifest.json`, `reference.json`, `godot.json`: entradas y observaciones completas.
- Logs y últimos archivos de lote; los resultados acumulados conservan todos los casos.
- `sources_before.json`: huellas del código de juego, configuración y recursos
  canónicos/manifiestos antes del proceso; se verifica que no cambian al terminar.

Cada ID aparece una vez por motor. Un resultado ausente, duplicado, mal formado o
un proceso fallido provoca `ERROR`, salida 2. Un desacuerdo provoca `MISMATCH`;
un contrato incompatible/error declarado de adaptador provoca `NOT_COMPARABLE`.
Ambos dejan el informe en `NEEDS_REVIEW`, salida 1. Solo todos los casos `MATCH`
producen `PASS`, salida 0. Una ejecución vacía nunca pasa; que ambos motores no
ejecuten nada tampoco cuenta como coincidencia. La referencia debe haber usado
el movimiento y pagado exactamente un PP en cada escenario de este contrato.

`self_test.py` comprueba diferencias deliberadas de etapas, PP, ejecución,
sustitutos y reservas, datos incompletos/duplicados y límites del azar. Con
`--integration` ejecuta ambos adaptadores con un contrato de PP incompatible,
rechaza una potencia de Calamidad fuera de la normalización explícita y
comprueba también que una ejecución posterior fallida sustituye el veredicto
anterior. Evidencia en `.godot/battle_reference/negative_controls/checks.json`.

La instalación usa `npm ci --ignore-scripts` y el lockfile exacto bajo
`.godot/battle_reference/runtime/`, fuera del contenido exportado de Godot.
No se alteran paquetes globales, tests existentes ni workflows. Una actualización
del simulador requiere cambiar el pin y repetir estas validaciones.

Fuentes técnicas: [API del simulador](https://github.com/smogon/pokemon-showdown/blob/master/sim/SIMULATOR.md),
[pruebas de Showdown](https://github.com/smogon/pokemon-showdown/blob/master/test/TESTS.md) y
[@pkmn/sim](https://github.com/pkmn/ps/tree/main/sim).
Créditos y licencias de las cinco dependencias: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
