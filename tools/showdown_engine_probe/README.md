# Showdown como sistema de combate: prueba de viabilidad

Evaluación local de 2026-10-26. **Resultado: merece avanzar a una integración
experimental por adaptador. El servidor de producción sigue siendo el nuestro.**

Se prueba el simulador `@pkmn/sim@0.10.11`, ya instalado y fijado por la herramienta
de referencia. No se instala un cliente web, no se crea un servicio de red y no
se modifica el motor Godot, los datos canónicos o los recursos gráficos.

## Qué se ha demostrado

- Godot 4.7 inicia un proceso Node local persistente y se comunica por JSONL
  mediante `OS.execute_with_pipe`, sin bloquear el bucle principal mientras espera.
- Un Charizard y un Blastoise de nuestra `CreatureFactory`, con naturalezas e IV
  reales, se importan conservando estadísticas, identidad, PS y PP existentes.
  Las estadísticas que no coinciden se rechazan; no se inventa una equivalencia.
- Showdown resuelve órdenes de movimientos y cambios, pausas de pivote,
  Protección, pantallas, terrenos, trampas, carga de dos turnos, curación/sueño,
  habilidades de entrada y objetos equipados. Cada caso tiene aserciones concretas.
- Los snapshots nativos atraviesan Godot, un archivo JSON, restauración y una
  continuación con el mismo RNG. Una orden inválida no modifica el estado.
- Los 19 movimientos Maxi se generan y ejecutan mediante Dinamax nativo en
  `gen8customgame`. `gen9customgame` rechaza Dinamax: combinarlo con las reglas
  modernas requiere un perfil explícito; no se ha activado una mezcla silenciosa.
- Una tanda de 64 simulaciones se ejecuta dentro del trabajador, sin 64 viajes
  Godot/Node y sin modificar el combate de origen. Esto es una prueba técnica,
  no una conexión ya terminada con la IA profesional.
- Un turno nativo de daño se traduce a `BattleEvent` y nuestra
  `BattleTimelinePlan` existente lo consume hasta los PS finales correctos de
  ambos participantes. Es una proyección limitada, sin afirmar integración
  visual completa ni modificar escenas del juego.
- Se verifican rechazo de mensajes grandes, error al morir el trabajador,
  continuidad tras una orden rechazada y limpieza de los procesos creados.

La primera escritura de un snapshot de unos 9 KiB descubrió el límite del pipe
no bloqueante de Windows. Se corrigió el transporte con fragmentos de 1 KiB y
cesión de frames. Ante fallo/timeout del transporte se cierra la conexión y el
proceso propio; no se sigue utilizando un estado de entrega ambiguo.

## Barrido y datos

`probe_tests.cjs` contiene 39 comprobaciones con aserciones, una medición y un
barrido de **832 movimientos × tres semillas = 2.496 ejecuciones nativas y
round trips de snapshot**. Todos terminaron sin errores de ejecución/serialización.
246 resultados contienen un fallo de movimiento válido en la fixture genérica,
por ejemplo por falta de las condiciones necesarias. **No equivale a certificar
la semántica de los 832 ni a habilitarlos en nuestro juego.** Se excluyen las
entradas vetadas por la política local y los Z/Max especiales; los Maxi se
prueban por su ruta nativa aparte. Splash solo aparece como acción inerte del
laboratorio, sin cambiar su exclusión del repertorio del juego.

El barrido observa 42 clases de mensajes del protocolo. La oportunidad consiste
en adaptar esas clases compartidas y los estados/solicitudes, aprovechando los
efectos del simulador; no en traducir otra vez una fórmula por movimiento.
El adaptador de presentación actual cubre solo el subconjunto probado y declara
explícitamente mensajes desconocidos. Los 42 observados no son el protocolo completo.

| Datos locales | Encaje con la versión fijada |
| --- | --- |
| 919 movimientos | Todos tienen entrada, con equivalencias explícitas para los Z físicos/especiales. Existencia no implica que sean utilizables como movimientos ordinarios. |
| 1.025 base + 57 regionales | Todos tienen correspondencia y coinciden en las seis estadísticas base y tipos. Se mapean explícitamente Darmanitan de Galar, los tres Tauros de Paldea y Minior meteorito; no se reescriben los datos. |
| 373 habilidades | 313 entradas directas. De las 60 restantes, la tabla oficial de PokeAPI marca 59 como ajenas a la serie principal; queda `embody_aspect`, que requiere resolver la variante según forma. |
| 2.222 objetos | 530 entradas directas. La mayoría de los demás son objetos de aventura, materiales, máquinas, etc. Una entrada de datos no implementa su uso desde la mochila. |
| Pesos | Incluidos en las correspondencias de especies del catálogo; también pueden servir como referencia si se conserva nuestro motor. |

Se detectan 60 diferencias en campos de movimientos, principalmente Z generados.
Fuera de esas variantes son seis filas: potencia especial de `comeuppance` y
`ruination`, precisión siempre acertada frente a 0 en `burning_bulwark`,
`dragon_cheer`, `tachyon_cutter`, y PP de `take_heart` (10 local / 15 en el perfil
nativo). Esto exige decidir/registrar el perfil y las conversiones, no regenerar
el dataset. El catálogo detallado conserva todos los casos y valores.

La procedencia de las habilidades se contrastó con
[abilities.csv de PokeAPI](https://github.com/PokeAPI/pokeapi/blob/master/data/v2/csv/abilities.csv),
blob `a1a9591047efb8a0e468f436f216e3dab21065ed`, guardado como evidencia local.
El script no depende de acceso a Internet para ejecutar sus combates.

## Qué podemos aprovechar y qué conserva el juego

| Sistema | Valor de Showdown | Trabajo propio que permanece |
| --- | --- | --- |
| Combate, movimientos, tipos y estados | Candidato principal para reutilización directa de lógica. | Adaptar órdenes, solicitudes, eventos y persistencia; probar el perfil elegido. |
| Habilidades y objetos equipados | Resuelve sus efectos de combate, incluido orden e interacción nativos. | Resolver alias, exclusiones, objetos externos y traducción de resultados. |
| Estadísticas/naturalezas/pesos | Datos y cálculo nativos; importación de estadísticas reales probada. | Conservar identidad, progreso y reglas de generación del juego. |
| Evoluciones y movimientos por nivel | Datos de referencia disponibles en el ecosistema Dex. | Subir experiencia/nivel, evolucionar y aleatorizar los huecos de aprendizaje siguen siendo sistemas de campaña. |
| Mochila y captura | No ofrece estos comandos de aventura como necesitamos. Un `pass` de turno normal es rechazado. | Mantener inventario finito, captura/huida y crear una extensión deliberada para la reacción rival tras gastar esa acción. |
| Randomlock | Puede recibir equipos con movimientos/habilidades asignados por nuestras reglas. | Capturas por zona, muerte permanente, vidas y selección/aleatorización permanecen fuera del simulador. |
| IA de entrenadores | Snapshots y simulación por lotes son útiles para búsquedas. | Conservar política/memoria; adaptar espacios de acciones y mundos plausibles sanitizados. No simular con los secretos reales del rival. |
| Multijugador | Protocolo y decisiones deterministas útiles para un servidor autoritativo futuro. | Coliseos, conexión, lobby, autenticación y sincronización de campaña no aparecen con esta biblioteca. |
| Arte y mapa | Nuestros recursos y línea de animación pueden mantenerse. | Completar la traducción genérica del protocolo a presentación Godot. |

Puntos que requieren una frontera explícita: volver de formas/PS temporales
Dinamax al estado persistente, cambios/consumo de objetos, PP y estados después
de captura, sueño/tóxico de snapshots antiguos y reanudación de partidas con
versiones distintas del motor. No se convierten partidas antiguas por aproximación.

## Decisión recomendada

Priorizar un **backend experimental opcional** para combates nuevos, con una
fachada para acciones, vistas, snapshot y conciliación final. Conservar el
backend actual para sesiones antiguas y como alternativa durante la transición.
Primero cerrar solicitudes/cambios/eventos/guardado y un combate visible completo;
después conectar captura/mochila e IA por sus interfaces actuales.

No continuar añadiendo muchas fórmulas por familias sin comparar antes este
camino de integración. Tampoco anunciar los 230 pendientes como terminados:
el perfil público continúa en **620 admitidos y 230 pendientes de mecánica**.

Si se adopta Showdown, compararlo contra sí mismo solo comprobaría parte de la
conexión. La validación necesitará resultados esperados independientes y pruebas
de integración/invariantes del juego, además de las pruebas del simulador.

## Reproducir y revisar evidencia

Desde la raíz del juego, con la instalación fijada de referencia disponible:

```powershell
python tools/showdown_engine_probe/run.py
```

Acepta `--node` y `--godot` con rutas alternativas. Si falta el paquete fijado,
prepararlo con `python tools/battle_reference/run.py --install`; el prototipo no
descarga ni actualiza dependencias automáticamente.

Informes en `.godot/showdown_engine_probe/` y resumen persistente en
`docs/current/SHOWDOWN_BACKEND_FEASIBILITY.json`. Se conservan catálogo,
aserciones Node/Godot, barrido, inventario de mensajes, tiempos, hashes y guardas
de los 233 archivos de producción. La medición local de IPC ronda unos milisegundos
y el lote de 64 ramas alrededor de una décima de segundo; son mediciones de este
equipo y estas fixtures, no garantías para el exportado ni para la IA completa.

## Fuentes, créditos y distribución

- [Simulador independiente y uso por otros lenguajes](https://github.com/smogon/pokemon-showdown/blob/master/sim/SIMULATOR.md).
- [API modular @pkmn/sim](https://github.com/pkmn/ps/tree/main/sim).
- [Protocolo de combate](https://github.com/smogon/pokemon-showdown/blob/master/sim/SIM-PROTOCOL.md).
- [Pipes de Godot](https://docs.godotengine.org/en/stable/classes/class_os.html#class-os-method-execute-with-pipe).
- [PSVM](https://github.com/ethanl21/psvm): alternativa nativa que declara estar en
  construcción y tener el ejemplo Godot previsto. No se ha compilado/evaluado su
  runtime en esta tarea; no se cuenta como integración Godot lista para usar.

La dependencia `@pkmn/sim` y sus dependencias mantienen sus avisos MIT en
[`THIRD_PARTY_NOTICES.md`](../battle_reference/THIRD_PARTY_NOTICES.md).
No se ha copiado código de los proyectos Godot/Ruby con condiciones sin resolver.
Para distribuir esta vía habrá que empaquetar el ejecutable Node/helper y sus
licencias, o evaluar después la alternativa nativa. La prueba actual utiliza
los ejecutables de desarrollo instalados y no es un exportado autónomo.
