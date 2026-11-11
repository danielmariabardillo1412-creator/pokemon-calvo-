# Pokémon Calvo — Cuaderno QA: bot de recorrido automático jugable

**Creación:** 2026-11-11  
**Código de investigación:** `QA-BOT-001`  
**Estado:** IDEA DOCUMENTADA / DISEÑO FUTURO, **NO IMPLEMENTADO**  
**Ubicación:** cuaderno temático de pruebas, **separado de dirección artística**.  
**Propietario de decisión:** IA6; NO es una orden de trabajo para IA1–IA5.

## 1. Fuente y qué ha demostrado realmente

**Vídeo:** Guinxu, «Hice un BOT que testea mi juego solo» (2026-11-03, 12:57):  
https://www.youtube.com/watch?v=JeyEB0Qhu-I

**Fuente consultada:** transcripción completa del vídeo recuperada el 2026-11-11, más descripción. Guinxu construye un sistema de prueba automático para su juego **Flatworld**, en **Unity**, inspirado en los *tool-assisted speedruns* (TAS). Declara una aventura de **15–20 horas**, y que el bot permite ensayar el recorrido más rápido, aproximadamente **×5** en su entorno.

**Importante: NO demuestra que cualquier juego pueda completarse automáticamente, sin intervención, ni que su propio bot haya resuelto todos los jefes.** El vídeo muestra el funcionamiento y los problemas pendientes de determinadas situaciones. Guinxu dice expresamente que mantiene **pruebas humanas**. El objetivo de su bot es descubrir si una modificación ha bloqueado el progreso de la aventura, no probar toda la dificultad, el balance o cada combinación de mecánicas.

### Procedimiento concreto que enseña (resumen fiel, sin copiar la transcripción)

1. **Grabadora:** registra continuamente las posiciones del jugador durante una partida humana y las escribe en un archivo de texto.
2. **Reproductor:** lee las posiciones, calcula hacia qué punto debe desplazarse y **simula los controles** para llegar al siguiente. No requiere colocar manualmente cientos de waypoints en escenas.
3. **Espera por resultado:** antes de avanzar comprueba que el personaje alcanzó el punto; si un NPC bloquea el paso, espera y sigue intentando.
4. **Eventos semánticos:** identifica diálogos/cinemáticas, puertas y cofres observando el **estado interno** de la aplicación. No basta reproducir una tecla a una hora fija: repite la acción hasta que el juego confirme su ejecución.
5. **Aceleración:** Guinxu prueba una escala de tiempo de hasta ×5 y elimina el límite de FPS como intento de compensar la pérdida de precisión; advierte que aceleraciones elevadas pueden descontrolar física y animaciones.
6. **Enemigos ordinarios:** para una *prueba de transitabilidad*, los neutraliza con ventajas de test (gran área de ataque + curación) porque su posición aleatoria complica una repetición fiel.
7. **Puzles:** para una caja desplazada con magia, la grabadora guarda la identidad y la **posición objetivo**, y el reproductor deja de accionar cuando esa posición se cumple; no se fía únicamente de mantener una tecla pulsada durante N segundos.
8. **Jefes:** siguen siendo un problema separado: algunas situaciones requieren soluciones específicas o rutas de prueba controladas. No hay garantía de cobertura completa de bosses.
9. **Uso adicional:** reproducción rápida de situaciones reportadas por usuarios (por ejemplo, un puzle de espejos) para acortar el ciclo de diagnóstico.

**Principio central:** sistema de `registro de recorrido + reproducción de entradas + comprobación de estados/milestones`. Es más robusto que reproducir teclas con tiempos prefijados, pero NO es una IA general que juegue por su cuenta.

---

## 2. Interés para Pokémon Calvo

El repositorio ya cuenta con baterías de regresión en `tests/gameplay/`, `tests/battle/`, `tests/data/`, `tests/trainer_ai/`, runners GDScript/Python y CI GitHub; `tests/README.md` documenta estas categorías. También existen suites de campo, combate nativo y SaveV2. **No confundir un PASS de objetos o combate aislado con demostrar que el usuario puede recorrer todos los mapas y completar la historia sin atascarse.**

Este bot cubriría una **nueva capa de pruebas de extremo a extremo (E2E) sobre una demo/aventura navegable**:

- Desplazamiento, límites y colisiones, puertas/teletransportes, escaleras y mapas encadenados.
- Activadores de historia, NPC, diálogos y opciones con estado persistente.
- Entradas/salidas de combate salvaje o entrenador, regreso al mapa y recuperación de control.
- Inventario necesario para abrir rutas, objetos de campo y consumo correcto.
- Guardado/carga **SaveV2** durante recorrido y tras transiciones.
- Detección de bloqueos, pantallas congeladas, bucles involuntarios, excepciones y posiciones imposibles.
- Reproducción exacta de pasos de un reporte de bug humano si hay registro previo.

### Dos modos que NO deben confundirse

**MODO A — Smoke test de recorrido (más rápido, inicialmente recomendable)**

Objetivo: «¿Se puede atravesar esta cadena de mapas, activar eventos y llegar al checkpoint sin quedarse atascado?» Puede partir de partidas de prueba preconfiguradas y controlar encuentros aleatorios para aislar navegación. **NO certifica combate legítimo**, dificultad, economía, reglas de Randomlock ni que un jugador real pueda terminar el juego. Si se neutralizan obstáculos, registrarlo expresamente en el informe y jamás presentar ese resultado como partida normal.

**MODO B — Recorrido auténtico de aventura (más exigente, fase posterior)**

Usa reglas reales de inventario, combate, diálogos y progreso; decisiones explícitas en menús, evolución, captura, almacenamiento y PP; estado auténtico y SaveV2 real. Si falla, marca FAIL y conserva reproducción. No otorgar vida infinita o vencer combates automáticamente mientras se afirme que el jugador puede superar esos retos. Requiere resolver aleatoriedad y decisiones del jugador mediante escenarios de test controlados y comprobaciones semánticas.

**Ninguno sustituye pruebas manuales ni todas las combinaciones de estados.**

---

## 3. Diseño futuro propuesto para Godot (sin código ni cambios activos)

### Grabador

- Registrar secuencia de posición y dirección del jugador **en coordenadas de mundo**, mapa/escena activa, fecha lógica/tick del juego y eventos relevantes; muestrear por distancia o puntos importantes en lugar de guardar cada frame para mapas extensos.
- Asociar señales/marcas semánticas: `map_entered`, `dialogue_closed`, `quest_flag_set`, `door_opened`, `battle_started`, `battle_finished`, `inventory_changed`, `saved`, `loaded`.
- Capturar *snapshot* inicial y versión del formato del recorrido; guardar con checksum, versión de juego, semilla cuando aplique y hash del mapa.
- Evitar datos personales en los registros y usar archivos de pruebas, no partidas de usuarios reales por defecto.

### Reproductor

- Leer cada waypoint o evento esperado; conducir el personaje mediante **las mismas APIs de entrada/movimiento usadas por la demo**, sin teletransportarse silenciosamente (salvo modo de aislamiento marcado).
- Antes de avanzar, verificar condición observada + tolerancia espacial; si no ocurre, reintentar con límite de tiempo/pasos.
- Incluir **watchdog de bloqueo:** si no progresa, detener y reportar escena, posición, checkpoint, último evento, intento actual, inventario/estado de historia, motivo e instantánea de depuración.
- En cinemáticas/menús, elegir acciones explícitas y esperar confirmación de estado. No pulsar A indefinidamente sin condición de fin y timeout.
- Integrar captura/log y reproducciones pequeñas para fallos de historia o transición.
- Soportar rutas de prueba con estados iniciales autorizados, para no tener que repetir 20 horas ante cada cambio local.

### Velocidad y determinismo

- **Primera prueba a velocidad normal**; después x2 y x5 SOLO si Godot y la implementación real lo toleran. No asumir que `Engine.time_scale` acelera todos los subsistemas del juego de forma correcta (física, audio, red, UI, animaciones y timers pueden diferir).
- Un mismo RNG seed no garantiza repetición si cambian el orden o el número de llamadas aleatorias; priorizar condiciones de resultado, estados iniciales controlados y trazas verificables.
- El tiempo de CPU/GPU de ejecutar x5 puede subir mucho; x5 velocidad lógica **no implica** x5 ahorro real de reloj, ni compatibilidad headless automática.

### Puertas de aceptación propuestas

1. Reproducción de una ruta pequeña sin error, llegada a destino y confirmación de todos sus eventos.
2. Test negativo: puerta bloqueada por objeto/flag incorrecto produce FAIL auténtico, no PASS.
3. NPC temporalmente bloqueando ruta: se recupera o informa timeout, pero nunca entra en bucle infinito.
4. Combate que interrumpe el mapa: regreso al mismo contexto y guardado/carga coherente.
5. Cambio accidental de lógica que imposibilita una interacción: el bot debe detectarlo y conservar evidencia.
6. Registro de modo A o B **claramente identificable**, versión de replay y datos de regresión.
7. CI específica con alcance limitado para smoke tests cortos; recorridos largos solo cuando la infraestructura y los mapas lo justifiquen.

---

## 4. Orden recomendado y dependencia

**No activarlo en plena campaña de objetos IA1–IA5 ni convertirlo en una tarea artística.**

Momento apropiado: **cuando haya un vertical slice jugable conectado** que incluya mapas, NPCs, al menos una transición, combate, inventario y SaveV2. No esperar necesariamente hasta pulir el arte, porque QA es parte del desarrollo y será útil antes del lanzamiento.

**Microprueba de aceptación futura:** grabar en una sala inicial un trayecto con puerta, diálogo, objeto necesario y combate. Después reproducir el mismo registro sin intervención y comprobar con tests negativos que detecta una puerta que se ha roto.

**Dependencias:** contrato de eventos del mundo/quests; rutas de navegación; UI/acciones; snapshot reproducible; compatibilidad con el sistema de guardado y los tests existentes. Cualquier cambio en motor o módulos compartidos requiere autorización IA6. Proteger `main`, V28 y PR #118.

**Coste/riesgo:** crear y mantener un sistema de playback completo puede ser tan complejo como parte de la demo; empezar por una pequeña ruta y demostrar el beneficio antes de una campaña larga. Si no hay una historia conectada aún, el bot no puede «pasarse todo el juego» porque todavía no existe ese recorrido.

---

## Registro de modificaciones

- **2026-11-11:** se documenta el método de Guinxu a partir de la transcripción, la separación A/B y el diseño exploratorio para Godot/Pokémon Calvo. Solo documentación, sin implementación, CI ni modificación de producción.
