# Próximo trabajo — 2026-10-31

Estado actual: **Cordón Unión excluido; conversión de intercambios a nivel aplazada.**
El usuario ha decidido que no se necesita ese objeto. Su adaptador y herramientas
específicas se retiraron del árbol activo; la historia y pruebas V24 se conservan
en Git, no describen una función que siga activa. Se mantiene el aviso correcto
de Amuleto/Incienso Puro para equiparlos.

[Revisión de objetos](ITEM_SCOPE_V25.md) · [Lista de candidatos](ITEM_SCOPE_V25.json) ·
[Trabajo futuro aplazado](TRADE_EVOLUTIONS_FUTURE.md).

No se han cambiado niveles ni evoluciones. No se adopta nivel 37. Se consultarán
más adelante otros juegos/randomizadores y la tabla que facilite el amigo.
Diez objetos asociados a esos intercambios y cinco pañuelos de concurso quedan
para revisar; solo Cordón está excluido ahora. Cuatro objetos con otros usos de
combate se conservan. Las evoluciones ordinarias por nivel y piedra siguen activas.

5 grupos PASS / 6.849 comprobaciones, incluidas regresiones. 621/624 equipables
permitidos reconocidos; los pendientes nativos son Amulet Coin, Exp. Share y
Luck Incense. El divisor bajó por excluir Cordón, no por implementar otro objeto.
Checkpoint funcional: `80a7aab4a494ef4c68e349eeab99f36202d13bfe`.

Los informes V2/V23/V24 son históricos. No se resellan ni se reinterpretan sus
recuentos como estado actual. Los apartados siguientes describen V1–V21.

V21: [consumibles de huida](ITEM_ESCAPE_V21.md). Poké Muñeco, Cola Skitty y
Poké Señuelo ya se usan desde mochila nativa para terminar un encuentro salvaje,
con consumo único y sin RNG/ataque extra. Son 18 usos directos de mochila con las
medicinas. Siguen 77 efectos de campo y siete huecos de definición equipada.

V20: [doce equipables revisados en bloque](ITEM_FIELD_HELD_V20.md). El registro
nativo pasa a 618/625; quedan siete definiciones pendientes. Los usos especiales
de mundo/mochila/concurso se mantienen separados; siguen 77 efectos de campo.
Poké Muñeco conserva su ID mediante un nombre nativo compatible.

V19: [importación automática por familias](ITEM_IMPORT_V19.md). Se compilan 42
objetos de recuperación en bloque: 41 rutas anteriores conservadas y Flauta Azul
nueva, reutilizable. V19 dejó 77 efectos de campo; ver V20 para el registro
nativo actual. Clasificar 2.222 IDs no certifica todas sus mecánicas.

## Limpieza y correcciones cerradas

Se completó la secuencia siguiente; resultados y límites en CLEANUP.md y
CLEANUP_RESULT.json. No repetirla como tarea pendiente:

1. Retirar entradas de ejecutores y órdenes de tareas ya cerradas; consolidar
   el estado operativo sin duplicar archivos antiguos en otras carpetas.
2. Revisar las pruebas que exigen la escena principal técnica antigua aunque
   el juego ahora arranca en la visual, conservando cobertura del mundo técnico.
3. Corregir las auditorías estáticas de IA que interpretan mal el texto del
   código actual. No cambiar el algoritmo de IA para satisfacer una búsqueda
   de cadenas obsoleta.
4. Separar errores de preparación de los fallos reales del comparador:
   modo legado, referencias locales de pruebas y directorios de salida.
   No regenerar datasets ni borrar asserts para dar verde.
5. Distinguir informes de importación antiguos y clasificación actual, retirar
   audits visuales de migraciones cerradas y actualizar la caché opcional del LAB.
6. Ejecutar las pruebas afectadas tras cada bloque. Conservar logs y repetir
   solo cuando haya cambios o fallos que lo justifiquen.

Inventario y avances de limpieza: [CLEANUP.md](CLEANUP.md).
Comparador V1 y límites: [COMPARATOR_GENERAL_V1.md](COMPARATOR_GENERAL_V1.md).
No modificar sus resultados para presentar una ejecución limpia posterior.

## Después de la limpieza

PP Up/Max quedan conectados y verificados en ITEM_FIELD_V8.md.
Caramelos Raro/EXP XS/S/M/L/XL cerrados en ITEM_FIELD_V9.md.
V10 conecta Cápsula/Parche Habilidad: ver ITEM_FIELD_V10.md.
V11 conecta Nido/Rapid/Ensueño/Sana/Honor Ball y su selector de combate:
ver ITEM_CAPTURE_V11.md. No repetir estas cinco conexiones como pendientes.
Captura mantiene la fórmula aproximada calvo_capture_v1; revisión de fidelidad
oficial, capturas críticas y tratamiento de Ultraentes siguen pendientes.
V12 conecta Veloz/Turno/Nivel Ball: doce bolas admitidas; contexto real de turnos
y nivel activo, reconstruido tras guardar/cargar. Ver ITEM_CAPTURE_V12.md.
No repetir estas conexiones. Otras bolas requieren ambiente, historial, tipos,
género o metadatos de origen; no habilitarlas con contexto inventado.
V15 conecta Amigo/Safari/Competi/Gloria Ball, sin contexto nuevo del mundo:
ver ITEM_CAPTURE_V15.md. Dieciséis bolas admitidas; no repetir sus conexiones.
Los eventos/regalos, concursos o formas de conseguirlas no se implementan aquí.
V13 conecta siete rutas EV de mochis: ver ITEM_MOCHI_V13.md. No repetir la
conexión de EV; amistad conservada según RHH, pendiente de contraste con SV.
V14 corrige el rechazo nativo de Campana Alivio: ver ITEM_FIELD_HELD_V14.md.
No repetir ese arreglo ni mapearla a objeto vacío. Se verifica conservar,
Lanzamiento, Desarme, Truco, captura y persistencia sin duplicación.
V16 conecta 24 medicinas equipadas; ver ITEM_FIELD_HELD_V16.md. Los usos de
campo existentes y el perfil de medicina en combate permanecen separados.
V17 conecta otros 17 consumibles equipados; ver ITEM_FIELD_HELD_V17.md. Vitaminas,
mejoras de PP y Caramelo Raro conservan sus usos anteriores. Los ocho potenciadores
de combate aún requieren conectar su uso desde mochila; campo los rechaza sin
consumir. No confundir el descriptor equipado con esa acción pendiente.
V18 conecta Huevo Suerte a la recompensa de combate y centraliza Piedra Eterna
para evolucion por nivel; ver ITEM_PROGRESSION_V18.md. El bonus no afecta a caramelos
ni compañeros. El reparto base de XP sigue siendo calvo_progression_v1; no se
certifican todas las formulas oficiales ni las demas excepciones de evolucion.
Continuar el puente de equipados de campo por lotes revisados: quedan siete IDs
equipables permitidos sin definición nativa tras V20. Contrastar metadatos y distinguir
los efectos de mundo aún pendientes; no habilitar todos como neutros a ciegas.
Continuar objetos por familias aún pendientes: IV,
naturalezas, condiciones de formas/evolución, bolas especiales y
mundo. El estado de referencia es [ITEM_SYSTEM_CURRENT_STATUS.json](ITEM_SYSTEM_CURRENT_STATUS.json).
Las rutas sin sistema disponible siguen pendientes; no simular consumos sin efecto.

V9 reutiliza ProgressionSystem/ProgressionRuleset, LearnsetSystem y EvolutionSystem
y la referencia Essentials 8c5911e. Mochila, decisiones y guardado verificados;
no repetir esa conexión como pendiente. Mantener los módulos separados y el
servicio como autoridad; no consumir antes de resolver las decisiones. La coherencia
nivel/XP se valida antes del uso. Bonos de amistad por origen y evoluciones con
condiciones no implementadas siguen pendientes. No migrar partidas antiguas ni
reescribir sus hashes silenciosamente. Las mentas necesitan acordar qué dato
persistente cambia, sin confundir naturaleza real y efecto de menta.
Habilidades: el objeto cambia solo ability_id. Quedan fuera de V10 la herencia de
slots al evolucionar y las rutas automáticas de formas; Parche hacia Modo Daruma
se rechaza como dependencia sin consumo. No confundir ID observable con slot
genético ni habilitar formas por cambiar una habilidad.

## Revisión gráfica futura — iconos pequeños de Pokémon

Petición del usuario, 2026-10-29: después de estos sistemas, buscar primero un
conjunto coherente de iconos pequeños para el equipo. Si no se encuentra uno que
encaje, usar los sprites de reposo de combate que ya tenemos, a escala pequeña.
El panel de los seis Pokémon tendrá un diseño propio; no es obligatorio copiar
la presentación clásica. Queda como tarea gráfica posterior, sin bloquear los
objetos ni iniciar ahora búsquedas, descargas, generación o sustitución de arte.

Multijugador, campaña/mapas finales, reglas personalizadas de vidas/muerte,
presupuesto común Mega/Z/Max e IA neuronal no forman parte de esta limpieza.
El piloto O001 de OpenCode no se inició. El usuario devolvió el trabajo a Codex,
que terminó Cápsula/Parche como V10. Los planos en docs/opencode se conservan como
históricos; no iniciarlos de nuevo ni atribuir una revisión externa. El viejo O002 no se reutiliza: la nueva autorización consta en ITEM_CLOSURE_V2.
No hay una tarea T007 de arquitectura.
