# Pokémon Calvo — Cuaderno de ideas artísticas y efectos visuales

**Creado:** 2026-11-11  
**Estado general:** INVESTIGACIÓN / BACKLOG ARTÍSTICO, NO IMPLEMENTACIÓN ACTIVA  
**Repositorio:** `danielmariabardillo1412-creator/pokemon-calvo-`  
**Coordinación:** IA6 / rama árbitra `codex/calvo-items-20261101-arbitro`

## 0. Propósito y reglas

Este cuaderno recoge efectos, técnicas, referencias y posibles mejoras para la **fase artística futura** de Pokémon Calvo. Su contenido no autoriza modificar el juego ahora, crear tareas de programación para IA1–IA5 ni iniciar una implementación por pulsar `p`.

**Prioridad vigente:** completar mecánicas, objetos, habilidades, combate, evolución, captura, persistencia e integración/regresiones; después diseño de mapas, ambientación, personajes, iluminación, efectos y rendimiento. Las ideas aquí reunidas serán candidatas a prototipo aislado, no requisitos aprobados de producción.

**Protecciones:** no tocar `main`, V28, PR #118, `SaveV2`, sistemas de combate o ramas de las trabajadoras a causa de estas ideas. No asignar microbloques artísticos antes de una autorización expresa y de alcanzar la fase correspondiente.

**Regla de evidencia:** separar (a) lo observado en la fuente, (b) la explicación de un creador, (c) la hipótesis técnica y (d) lo probado en nuestro Godot. Nunca declarar comprobado el algoritmo interno de Nintendo ni un rendimiento concreto sin una fuente técnica y una medición propia.

### Índice

| ID | Idea | Estado | Prioridad cuando llegue fase artística |
|---|---|---|---|
| `ART-FX-FOG-001` | Niebla reactiva simulada en 2D, visualizada con sensación de volumen | APARCADA / INVESTIGAR | Media-alta para una zona concreta |
| `ART-LIGHT-002` | Cel shading y técnicas de iluminación anime para modelos 3D integrados en mapas 2D/2.5D | APARCADA / TÉCNICAS VERIFICADAS EN VÍDEO | Alta para dirección de personajes |
| `ART-REF-003` | Revisar periódicamente explicaciones técnicas de @PereGamedev y otros autores fiables | REFERENCIA / SIN TAREAS ACTIVAS | Según propuestas concretas |
| `ART-WORLD-004` | Arquitectura de mapas 2.5D: personajes 3D y escenarios 2D con sensación de volumen | APARCADA / DISEÑO COMPARATIVO | Alta al empezar mapas |
| `ART-REF-005` | Referencia ISO-CORE / JohnBrx: terreno con relieve y representación 2D | REFERENCIA TÉCNICA / VERIFICADA PARCIALMENTE | Alta |
| `ART-REF-006` | Referencia Pokémon Luminescent Platinum (mod BDSP) | REFERENCIA VISUAL, NO PRUEBA DE MAPA 2D | Media |
| `ART-FX-TRAIL-007` | Rastros y huellas 2D reutilizables para nieve, barro, arena y otras superficies | APARCADA / INVESTIGACIÓN | Alta en zonas de terreno especial |
| `ART-TEX-NOISE-008` | Ruido Perlin procedural reutilizable: agua, humo, niebla, suciedad, terreno y lava | APARCADA / TÉCNICA DOCUMENTADA | Alta, tecnología transversal |

---

## ART-FX-FOG-001 — Niebla reactiva con simulación 2D y apariencia volumétrica

- **Motivo:** ambientes con niebla frecuentes en Pokémon (bosques, zonas húmedas, pantanos, cuevas o rutas especiales). El usuario propone una zona localizada, no cubrir todos los mapas.
- **Estado:** APARCADA hasta la fase artística y los mapas; prototipo aislado primero. **No desarrollar ahora.**
- **Fuente principal:** Short compartido por el usuario, creador visible **@PereGamedev**, «Desarrollador explica cómo funciona la niebla del…»: https://www.youtube.com/shorts/HH8fLbfDjIE
- **Evidencia disponible:** transcripción de ~57 segundos aportada por el usuario el 2026-11-11. **La afirmación sobre cómo Nintendo lo implementa procede del vídeo; no se dispone de documentación oficial que la confirme.**

### Explicación de la técnica descrita

1. **Calcular dinámica solo en 2D (X/Y del plano):** una textura o rejilla almacena intensidad/densidad de niebla y, si se desea movimiento físico aproximado, un campo de velocidades 2D. No simular un fluido 3D completo por celdas volumétricas.
2. **Representar densidad en escala de grises:** oscuro = menor densidad y/o menos altura aparente; claro = mayor densidad y/o más altura aparente. La codificación precisa de densidad y altura debe diseñarse para el shader, no asumir equivalencia física exacta.
3. **Construir la apariencia de volumen:** el shader/renderizado interpreta la textura como máscara de densidad, altura, transparencia, sombreado o perfil volumétrico aparente. **No basta una textura plana por sí sola para generar volumen real.** Se debe elegir una técnica de representación compatible con Godot y el estilo artístico.
4. **Inyectar interacción local:** movimiento/carrera/ataque del jugador perturba la textura 2D (por ejemplo, impulso, desplazamiento y remolino), con decaimiento temporal y recuperación de la niebla.
5. **Optimización:** simular a baja resolución y actualizar la zona relevante; el coste total depende también de transparencia, sobrepintado de píxeles, shaders, reconstrucción visual, iluminación y resolución de pantalla.

### Hipótesis aplicable a Pokémon Calvo

- En mapas con sprites 2D estilo DS/GBA, considerar un render de niebla 2D y máscaras de profundidad/oclusión que respeten sprites, árboles y suelo. No forzar un efecto fotorrealista que desentone.
- En escenarios 2.5D/3D, investigar cómo proyectar la densidad 2D sobre superficies o volúmenes aparentes; comparar contra la niebla nativa de Godot.
- Usar solo en zonas señaladas por diseño: no convertirlo en obligación para todos los mapas.
- La aparente eficiencia es **una hipótesis razonable**, no «coste casi cero» demostrado.

### Prototipo futuro obligatorio (no ejecutar ahora)

1. Sala de prueba independiente en Godot 4.7 con personaje de prueba y geometría sencilla.
2. Tres variantes: sin niebla (control), niebla visual no reactiva y niebla reactiva basada en rejilla 2D.
3. Movimiento andando, corriendo, detenido y giro; si procede, interacción tipo golpe para abrir un hueco/remolino.
4. Probar escala de resolución 128×128 y 256×256 **como puntos iniciales**, no números definitivos.
5. Medir FPS, tiempo de CPU/GPU, consumo VRAM y coste adicional frente al control; valorar calidad y coherencia con arte del juego en hardware objetivo (incluida GTX 1660 Ti de 6 GB).
6. Aprobar solo si mantiene el objetivo de rendimiento que se establezca en la fase artística; si no, degradar resolución, reducir transparencia o usar niebla visual animada no física.

**Criterios de aceptación futuros:** respuesta local perceptible; movimiento natural; posibilidad de desactivar/ajustar calidad; no tapar información jugable; coherencia artística; mediciones reproducibles.  
**Bloqueadores actuales:** dirección artística/mapas aún no cerrados y sistemas fundamentales de juego en desarrollo.

**Referencias de investigación:**  
- Documentación Godot, Environment y postprocesado: https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html
- Niebla volumétrica Godot: https://docs.godotengine.org/en/stable/tutorials/3d/volumetric_fog.html
- Referencia de simulación 2D/GPU (revisar licencia, versión y rendimiento antes de reutilizar): https://github.com/Switchbreak/EulerianFluidSolver

---

## ART-LIGHT-002 — Cel shading y control de iluminación de personajes 3D

- **Estado:** APARCADA para la fase artística. Sin implementación ni asignaciones para IA1–IA5.
- **Fuente primaria analizada:** Guinxu, **«El secreto de la LUZ en juegos estilo ANIME»**, 23-07-2024, duración 9 min 33 s: https://www.youtube.com/watch?v=yp7HpTkSzBA
- **Evidencia:** transcripción completa recuperada y estudiada el 2026-11-11. El autor muestra técnicas presentes o descritas en juegos como Guilty Gear, Dragon Ball FighterZ y Genshin Impact. Las simplificaciones para Pokémon Calvo son propuestas, **no copias probadas de sus implementaciones internas**.
- **Corrección sobre hipótesis previa:** se había apuntado «lighting axis» de oído y se planteó si sería `ACES`. **Este vídeo explica principalmente cel shading, normales, iluminación por personaje, Fresnel/rim light y outlines, NO ACES.** No afirmar que la frase original «lighting axis» se haya identificado con certeza; puede proceder de otra fuente. ACES/AgX es tratamiento tonal/colorimétrico diferente y solo se valoraría por separado.

### Técnicas concretas explicadas en el vídeo

1. **Cel shading / toon shading:** pasar de sombras graduales realistas a dos o más bandas definidas de luz y sombra. Guinxu simplifica usando un umbral sobre el producto escalar entre normal de la superficie y dirección de luz. Un valor mostrado (70%) es **solo un ejemplo**, no un ajuste universal.
2. **Normales de vértices ajustadas:** modificar la dirección que la iluminación «cree» que mira una zona del modelo sin deformar su geometría. Permite diseñar sombras faciales propias del estilo anime; requiere trabajo técnico/artístico y puede cambiar con rigging, cámara y expresiones.
3. **Umbrales por zona del modelo:** distintos puntos pueden entrar en sombra con mayor o menor facilidad (por ejemplo, bajo una prenda o alrededor de la cara). Guinxu menciona el control fino usado por Guilty Gear. **No necesario para un primer ensayo.**
4. **Luz independiente por personaje:** en algunos juegos, ciertas luces se controlan para favorecer la silueta/rostro aunque la luz ambiental general sea distinta. En un juego con personajes 3D renderizados en `SubViewport`, podría configurarse una luz aislada propia del viewport, pero **debe conservar coherencia con la hora, mapas y escenas**.
5. **Fresnel / rim light:** iluminación o brillo fino a lo largo de la silueta para separarla del fondo. No es lo mismo que una luz física ni que el contorno negro.
6. **Outline oscuro:** contorno exterior estilizado, en el vídeo explicado mediante una copia ligeramente aumentada/invertida del modelo. El grosor se adapta con distancia; no asumir que duplicar todos los modelos sea gratis. Existen opciones de shader/borde y postprocesado que se deben comparar en Godot.
7. **Detalles de línea internos:** dibujos/texturas y organización de UV para conservar trazos anime sin pérdida de nitidez; el vídeo muestra trucos de textura de Guilty Gear/Dragon Ball FighterZ. Solo justificable si el personaje final se verá a escala suficiente.

### Aplicación específica a Pokémon Calvo

**Meta:** aprovechar personajes 3D generados/retocados con Meshy y Blender, mientras los mapas pueden ser 2D/2.5D (véase `ART-WORLD-004`), sin aspecto de plástico ni apariencia de «personaje pegado encima».

- Probar **primero cel shading sencillo de dos bandas + paleta coherente** con los mapas estilo Pokémon DS/GBA. No imitar necesariamente los anime de alta definición del vídeo.
- Comparar **sin outline / outline fino / rim light suave** a la escala real del juego, no solo en un zoom cercano. Los contornos exagerados o Fresnel intensos pueden desentonar.
- En el escenario híbrido `SubViewport` 3D sobre fondo 2D, decidir si las sombras del personaje obedecerán al sol del mundo, a una luz artística propia o a un compromiso. Considerar oclusión y contacto con suelo.
- **No presuponer coste bajo:** un shader sencillo puede ser razonable, pero luces adicionales, outlines por geometría, transparencias, renderizados en múltiples viewports y mayor número de personajes incrementan coste. Medir CPU/GPU, VRAM, FPS y nitidez real.
- No modificar ahora la arquitectura del juego, los modelos de personajes, el `FieldItemBag`, el sistema de batalla, mapas en desarrollo ni política de objetos.

### Microprototipo futuro (NO comenzar ahora)

1. Elegir **un único modelo existente** y una sala con fondo provisional 2D. Cámara y tamaño de personaje iguales a los que se usarán jugando.
2. Ensayo A: sombreado convencional con materiales sin reflejos especulares exagerados; B: cel shading de dos bandas; C: B + outline; D: B + rim light suave. Registrar imágenes y coste de cada opción.
3. Caminar, girar, reproducir una animación y cambiar de zona clara a zona oscura; comprobar que ojos, cara, manos y ropa siguen legibles y que los contornos no vibran.
4. Solo si se detectan sombras faciales inadecuadas, investigar normales personalizadas y umbrales por zona; no exigir pintura manual de sombras para cada personaje desde el principio.
5. Confirmar compatibilidad con el renderizador real de Godot 4.7 y la arquitectura elegida (2D + 3D `SubViewport` o escenario 3D con sprites). Benchmark hardware objetivo.
6. No decidir estilo definitivo sin comparar sprites del mapa y modelos en movimiento, ni marcar técnica «certificada» antes de una prueba en el proyecto.

### Fuente y referencias

- [Guinxu — El secreto de la luz en juegos estilo anime](https://www.youtube.com/watch?v=yp7HpTkSzBA) — vídeo del que se ha recuperado la transcripción.
- [Godot 4: shaders espaciales](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html) — materiales/shading de modelos 3D.
- [Godot 4: viewports](https://docs.godotengine.org/en/stable/tutorials/rendering/viewports.html) — render de una escena 3D en textura para composiciones 2D.
- [Godot: materiales PBR](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html) — brillo/rugosidad para comparar aspecto plástico.
- [Godot: entorno y postprocesado](https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html) — tonemapping ACES/AgX como cuestión **separada**.

**Decisión actual:** investigación documentada; la primera prueba recomendable será un personaje con toon shading simple. El detalle tipo Guilty Gear se mantiene como opción avanzada, no como requisito.


---

## ART-REF-003 — Fuentes y divulgadores técnicos a examinar

**Creador destacado por el usuario:** **@PereGamedev**. La explicación de niebla le ha resultado útil y propone revisar otros vídeos de desarrollo, shaders, efectos e iluminación como fuente de posibles ideas artísticas.

**Política de incorporación:** un vídeo interesante NO equivale a tarea aprobada. Registrar siempre URL, fecha de consulta, técnica mencionada, precisión de la explicación, facilidad de prototipo, compatibilidad Godot, coste y fase del proyecto. Si hay afirmaciones sobre motores cerrados (Nintendo, etc.), distinguir con claridad reconstrucción del autor frente a hechos verificados.

### Ficha para nuevas ideas

```text
ID:
Título:
Fuente/URL + fecha:
Técnica (nombre exacto y sinónimos):
Qué afirma el autor:
Qué está verificado / qué es hipótesis:
Aplicación concreta en Pokémon Calvo:
Godot 4.x: shaders, nodos y alternativas:
Costes / riesgos / estilo:
Prueba pequeña futura:
Dependencias:
Estado: IDEA | INVESTIGAR | APARCADA | PROTOTIPO_AUTORIZADO | DESCARTADA
```

---

## ART-WORLD-004 — Mapas 2.5D sin modelar miles de piezas 3D

**Objetivo expresado por el usuario (2026-11-11):** personajes propios creados a partir de modelos 3D (por ejemplo, producción asistida en Meshy), pero **mundo/mapas mayoritariamente 2D** capaces de aparentar profundidad. Evitar fabricar y colocar cada árbol, roca, pared, edificio y elemento pequeño como malla 3D; tampoco reducirse a un mapa visualmente plano sin profundidad. Mantener el estilo Pokémon Calvo e integridad de su perspectiva.

**Estado:** APARCADA; ingeniería visual por evaluar en la fase artística. No modificar el pipeline actual de juego ni autorizar a IA1–IA5 a rediseñar mapas ahora. No asumir que «2.5D» es una implementación única.

### Dos arquitecturas viables a comparar en prototipo, no ambas a la vez

**Alternativa preferida para primer ensayo, sujeta a evaluación: mapa 2D en Godot 4.7 + personajes 3D renderizados en un SubViewport.**
- Mapas por `TileMapLayer` / escenas 2D, sprites de terreno, fachadas y vegetación, decoración reutilizable en atlas y variantes. Posibilidad de capas para suelo, detrás del personaje y delante del personaje.
- Cada personaje relevante usa un modelo 3D y una cámara ortográfica en un `SubViewport` con fondo transparente. Dibujar su textura como representación 2D sincronizada con la posición del jugador. **No** implica convertir el terreno completo en modelos 3D.
- Separar colisión/camino (`CharacterBody2D` / navegación 2D, según implementación real) de su apariencia 3D en el viewport. Resolver proyección y escala consistente con los tiles y dirección de marcha.
- Para relieve aparente: coordenada de altura lógica y desplazamiento vertical de la representación, rampas/escaleras modeladas en navegación, máscaras de oclusión y sombras de contacto. No confundir desplazamiento gráfico con altura física real.
- Dificultades importantes: ordenar detrás/delante de árboles y tejados (`YSort` y capas), sombras coherentes entre modelo 3D y fondos 2D, iluminación compartida, orientación de cámara fija, ajuste de perspectiva, calidad de contorno y sobrecoste de renderizar viewports. **Un viewport por personaje puede ser costoso**; investigar atlas prerenderizado, spritesheets de modelos o renderizado agrupado antes de escoger.

**Alternativa B: mundo 3D ligero con terreno sencillo + decorados 2D como planos/billboards.**
- Posicionar sprites/planos 2D dentro de una escena 3D; personajes con mallas 3D naturales, proyección ortográfica o casi ortográfica.
- Ventaja: geometría, profundidad, oclusión y sombras 3D potencialmente más coherentes. Inconveniente: exige diseñar un espacio 3D aunque muchísimos elementos sean 2D; no asumir coste o producción menor hasta medir.
- Se evaluará solo si A produce problemas inaceptables de integración visual, profundidad o iluminación.

**Decisión pendiente:** la perspectiva de cámara, número de direcciones de movimiento y look de personajes deben quedar definidos en dirección artística; ningún ejemplo ajeno decide automáticamente la arquitectura del juego.

### Microprototipo futuro

1. Una sala/mapa de 20×20 tiles representativos con suelo, árbol delante/detrás, edificio, río, escalera y desnivel.
2. Un modelo de personaje existente y un NPC: comparar A y B; movimiento en al menos cuatro direcciones, atravesar puertas, pasar detrás de árboles y subir/bajar.
3. Verificar correctitud de oclusión, profundidad, cámara, luces/sombras y sprites sin «efecto pegatina».
4. Comprobar si el modelo se integra en estilo pixel/sprite o si necesita un tratamiento de renderizado específico.
5. Registrar coste de dibujo, memoria de texturas, tiempos CPU/GPU y coste de producción de recursos. No prometer que 2D siempre sea más eficiente.
6. Prototipo independiente; sin cambiar las escenas o sistemas oficiales hasta decisión humana.

**Referencias Godot verificadas:** 
- Introducción oficial al 2D / uso de SubViewport para modelos 3D en escenas 2D: https://docs.godotengine.org/es/4.x/tutorials/2d/introduction_to_2d.html
- Documentación oficial SubViewport (3D dentro de juego 2D): https://docs.godotengine.org/es/4.x/tutorials/rendering/viewports.html
- Demo oficial 2.5D (proyección de coordenadas 3D sobre sprites 2D; no confundir con renderizar personajes 3D): https://godotengine.org/asset-library/asset/2783
- Demo 2.5D Godot Foundation para 4.7 en Asset Store (verificar versión y compatibilidad al usar): https://store.godotengine.org/asset/godot-foundation/project-with-gdscript-2-5d-demo/

---

## ART-REF-005 — ISO-CORE / desarrollador JohnBrx

- **Identificación comprobada:** `JohnBrx` es el creador; el juego se titula **ISO-CORE**, un proyecto isométrico en pixel art descrito oficialmente como mundo **2D isométrico**. No llamar «John BRX» al juego.
- **Web del juego:** https://store.steampowered.com/app/2983860/ISOCORE/
- **Vídeo de desarrollo pertinente:** *Adding 3D Terrain to my 2D Game [DEVLOG]*, por JohnBrx: https://www.youtube.com/watch?v=ez68sFkO6Qo
- **Lo descrito en el devlog:** desarrollo de relieve para mundo originalmente 2D, generación procedural de terrenos con ruido Perlin/octavas, separación de datos lógicos de representación, orden visual y profundidad en una escena isométrica. Se trata de una **investigación técnica visual**, no una licencia para copiar recursos.
- **Matiz decisivo:** el vídeo se llama literalmente «añadiendo terreno 3D a mi juego 2D», así que la versión más avanzada puede incorporar **verdadera geometría o datos espaciales 3D parciales**. No afirmar que todo su relieve es una ilusión exclusivamente 2D ni que basta una sola textura.
- **Qué extraer para Calvo:** mapas por tiles/atlas, proyección fija, relieve representado de manera eficiente, profundidad, ordering, escalones, colisiones y sombras consistentes. **No reproducir necesariamente su generación procedural**: Calvo puede preferir mapas autorales (romanos/vikingos) con piezas reusables.
- **Estado:** referencia importante para comparación 2.5D; no integración presente.

---

## ART-REF-006 — Pokémon Luminescent Platinum

- **Identificación comprobada:** **Pokémon Luminescent Platinum** (también Platino Luminiscente) es un **ROM hack/mod de Pokémon Brilliant Diamond/Shining Pearl**, de Team Lumi, no un videojuego originalmente construido como mundo 2D.
- **Sitio oficial:** https://luminescent.team/
- **Características:** https://luminescent.team/docs/features
- **Evidencia técnica:** el proyecto reutiliza y modifica la base de BDSP, que incluye **modelos 3D**, rigging, escenas y mapas en Unity. No presentarlo como «motor 2D que finge 3D».
- **Qué extraer para Calvo:** composición de rutas Pokémon, escala visual del personaje frente a decorados, cámara, contraste, legibilidad, detalle estilizado y encuadre. **Su arquitectura puede resultar más cara que la buscada por Calvo**, así que es una referencia de estética y flujo, no un modelo probado de rendimiento 2.5D.
- **Estado:** referencia visual; mantener abierta la posibilidad de que el usuario esté señalando una variante/vídeo concreto diferente; pedir enlace solo si fuera imprescindible para identificar esa variante.

---

## ART-FX-TRAIL-007 — Huellas y rastros dinámicos sobre superficies 2D

- **Fecha:** 2026-11-11.
- **Estado:** APARCADA para la fase artística. **No implementar ni asignar ahora a IA1–IA5.**
- **Referencia observada por el usuario:** Pere Gamedev, «DESARROLLADOR INDIE IMPLEMENTA UN TRAIL EN 2D SOBRE LA NIEVE» (vídeo de 29 s; captura del usuario): https://www.youtube.com/watch?v=xjjtBN2IPzA
- **Juego identificado en la propia descripción del vídeo:** **No Name Village**, de **PieMastah**; juego 2D de aventura/RPG desarrollado con **GameMaker**, publicado comercialmente el 13 de septiembre de 2025. Referencia: https://store.steampowered.com/app/2201500/No_Name_Village/ y demo https://piemastah.itch.io/no-name-village.
- **Qué se ha visto en la captura:** un personaje pixel art caminando por nieve con un camino o rastro visible sobre la superficie blanca; se trata de un efecto gráfico para terreno **2D**.
- **Transcripción recuperada y consultada (2026-11-11):** en el vídeo de Pere Gamedev (30 s) se explica un método concreto: dividir el *trail* en **tres partes (base, profundidad y borde)**, dibujar los sprites **en capas separadas mediante un sistema de partículas** y añadir **variaciones de cada sprite** para un acabado orgánico. Esta es la explicación expresada en el vídeo, no una suposición sobre un render target.
- **Límite de evidencia:** el narrador atribuye esa solución al desarrollador del juego, pero **no se ha inspeccionado el código de PieMastah** para verificar los nodos, algoritmos o parámetros exactos. Diferenciar «lo explica Pere Gamedev» de «está confirmado por código fuente del desarrollador».

### Propósito para Pokémon Calvo

No limitar la idea a nieve: crear **un sistema reutilizable basado en el tipo de superficie**. El movimiento de jugador, NPC o criatura puede dejar huellas que expresen interacción física sin tener que deformar una malla de terreno 3D.

| Suelo | Apariencia del rastro | Persistencia y respuesta sugeridas |
|---|---|---|
| Nieve | Pisadas comprimidas, surco más oscuro/azulado y posible borde claro; partículas mínimas opcionales | Se mantienen durante un rato; nieve reciente puede cubrirlas |
| Barro | Huella oscura y húmeda, arrastre irregular, bordes salpicados | Persistencia mayor; posible secado progresivo |
| Arena | Marca con relieve aparente y borde granulado | Difuminado por viento o al salir de la zona |
| Tierra/ceniza | Pisada, polvo acumulado o suelo removido | Desvanecimiento según material |
| Hierba | Aplastamiento local del patrón de vegetación | Recuperación gradual; no implica alterar colisión |
| Agua superficial | Ondas o salpicaduras (variante visual distinta, **no** una huella permanente) | Duración muy breve |

**No confundir gráficos con gameplay:** las huellas no modifican por defecto velocidad, encuentros, combate ni persistencia de SaveV2. Cualquier efecto jugable es una decisión independiente futura.

### Arquitectura propuesta en Godot 4.x (específica para mapas 2D / 2.5D)

**Primera versión experimental preferida: sistema de partículas/sprites en TRES capas, como enseña el vídeo.**

1. El controlador identifica el tipo de suelo bajo el personaje (datos personalizados de `TileMapLayer` o áreas). Emite una marca al contacto de pie o tras recorrer distancia suficiente, no una por fotograma.
2. Cada marca visible se compone de **(a) base**: textura principal del surco; **(b) profundidad**: zona de sombra o hundimiento aparente; **(c) borde**: nieve/barro desplazado a ambos lados. No hay deformación física 3D obligatoria.
3. Las tres piezas se dibujan **en capas/z-index distintos** usando partículas 2D y sprites (en Godot, estudiar `GPUParticles2D`, `CPUParticles2D` o estampas reciclables, con orden de dibujo estable). Puede hacerse mediante una emisión coordinada que alinee base/profundidad/borde en el mismo punto y orientación; no exigir un solo nodo específico sin prueba.
4. Crear **varias versiones de cada pieza** y alternarlas (rotación, longitud, anchura, variación artística) para evitar patrones idénticos. Variar dentro de los límites de legibilidad de pixel art.
5. Mantener las marcas pegadas a coordenadas del mundo; definir vida útil y límites de partículas/estampas activas por área. **Ojo:** un sistema de partículas normal puede arrastrarlas o borrarlas al reiniciar el emisor; hay que probar persistencia e independencia del movimiento de cámara.
6. Definir el suelo como datos + perfiles visuales: para **nieve**, base clara y borde suave; para **barro**, base oscura, borde húmedo y alguna salpicadura; para **arena**, borde granulado y vida más corta. Reutilizar el mecanismo, cambiar los sprites y parámetros. Medir FPS, memoria y sobrepintado.

**Alternativas técnicas (no son la técnica que describe el vídeo):** sellos de sprites 2D reciclables sin partículas, si resultan más estables para huellas duraderas; y una máscara 2D acumulativa (`SubViewport` / textura dinámica + shader) si más adelante se necesitan miles de interacciones o deformaciones extensas. **No atribuir estos dos métodos al vídeo de Pere Gamedev.**

**Relación con ART-WORLD-004 (mapas 2.5D):** calcular huellas sobre coordenadas 2D del suelo independientemente de que la apariencia del personaje provenga de un modelo 3D. Hay que sincronizar la ubicación de **los pies** renderizados, no solamente el centro del personaje. Resolver qué dibuja por delante/detrás y la escala de las huellas según perspectiva fija.

### Prototipo futuro obligatorio, no ejecutar ahora

1. Una habitación pequeña de mapa de prueba con superficies de nieve y barro, personaje móvil y una cámara normal.
2. Validar caminar, correr, girar, detenerse y volver a pisar un rastro: las huellas no deben multiplicarse sin control ni saltar de posición.
3. Cambiar el material sin reescribir el sistema, solo sus ajustes visuales. Ensayar después arena.
4. Probar primero **tres capas con partículas y variaciones de sprites** (método del vídeo). Comparar después sprites reciclados si aportan mayor estabilidad; evaluar máscara 2D solo si hace falta. Revisar que los surcos no atraviesen piedras, paredes u otros planos.
5. Probar varias huellas, limpieza, cambio de mapa y cámara. No exigir guardar rastros entre sesiones en SaveV2 salvo autorización expresa.
6. Medir CPU/GPU, FPS, VRAM y coherencia de estética DS/GBA; elegir presupuesto y opciones de calidad cuando se fije plataforma objetivo.

### Riesgos

- «Es 2D, así que no cuesta casi nada» es una hipótesis excesiva: memoria de textura, transparencia, efectos de borde y sellos frecuentes pueden consumir recursos.
- El sistema de huellas superficiales es diferente a simular barro con física real; evitar prometer deformación física del terreno o colisiones.
- Si la cámara y el mapa son isométricos, hay que preservar la proyección y ordenar correctamente el render.
- En personajes 3D sobre fondo 2D (ART-WORLD-004), el punto de contacto real de ambos pies necesita una interfaz coherente.
- Las huellas pueden ensuciar la lectura visual, especialmente en mapas pixel art pequeños; debe haber intensidad configurable y opción de desactivación.

### Referencias técnicas comparables (no constituyen prueba del método original del juego)

- Ibrahim Afara, **Dynamic Snow Footprints**: demostración y desglose de render target acumulativo, control de superficie y reutilización para barro, arena y ruedas: https://iafara.me/work/snow-footprints/
- Hugo Leblanc, **Deformable Snow Trails in Unity URP with Render Textures** (2026): textura de marcas y mapa de alturas; ejemplo 3D adaptable conceptualmente a 2D: https://hugoleblanc.fr/devlog/unity-snow-trails/
- Demo original de No Name Village por PieMastah en GameMaker, útil para observar el resultado gráfico y estilo, **no como fuente de código interno**: https://piemastah.itch.io/no-name-village

**Transcripción del vídeo ya obtenida.** Queda para fase artística ver el detalle del *trail* en movimiento, diseñar las tres piezas artísticas y reproducir el método mediante una prueba real en Godot; la implementación interna exacta del juego solo se podrá afirmar si el autor aporta código o documentación.

---

## ART-TEX-NOISE-008 — Ruido Perlin como recurso transversal de arte

- **Estado:** APARCADA / REFERENCIA TÉCNICA DOCUMENTADA. No encargar implementación ahora.
- **Fuente exacta:** Pere Gamedev, «¡TODOS LOS VIDEOJUEGOS UTILIZAN ESTA TEXTURA Y NO TE HAS ENTERADO!» (10-02-2026, duración aproximada 48 s): https://www.youtube.com/watch?v=wIR2ryONbcU
- **Evidencia:** vídeo localizado en la pestaña del navegador y **transcripción completa recuperada** el 11-11-2026; descripción confirma que se trata de `Perlin Noise`.
- **Corrección de subtítulo automático:** donde aparece «Ken Perry» debe leerse **Ken Perlin**, autor de la técnica original; donde dice «solas» se entiende «olas».
- **Precisión:** «todos los videojuegos» es una exageración del título: **no** demostrar universalidad, ni que un solo patrón sirva para todos los materiales sin adaptación.

### Cómo funciona, conforme a la explicación

1. No es una foto o textura pintada: es un **campo de valores calculado matemáticamente**. Una cuadrícula contiene direcciones/gradientes pseudorrandom en sus puntos.
2. Para cada posición se combinan las contribuciones de gradientes vecinos mediante interpolación suave, dando transiciones orgánicas sin el aspecto «sal y pimienta» de ruido blanco.
3. Cambiar la **escala/frecuencia** altera el tamaño de las manchas; cambiar intensidad afecta al contraste o a cuánto modifica un material.
4. **Superponer varias octavas** con distintas frecuencias y amplitudes permite detalle grande y pequeño (ruido fractal).
5. **Animar** coordenadas/tiempo —desplazar la muestra, distorsionar UV, variar otra dimensión del ruido o combinar capas— produce variaciones que pueden sugerir corriente, viento o combustión. El ruido por sí solo **no simula agua, humo ni física de fluidos**.

### Reutilizaciones propuestas para Pokémon Calvo

| Material/efecto | Función del ruido | Otras piezas necesarias |
|---|---|---|
| **Agua**: ríos, lagos, charcos | Distorsionar coordenadas y animar patrones de brillo/ondas suaves | Paleta de agua, borde de costa, espuma, transparencias y reflejos estilizados |
| **Lava** (idea del usuario; no se afirma mencionada literalmente en la transcripción) | Umbral/máscara entre roca oscura y zonas calientes; deformación animada | Paleta cálida, resplandor moderado, iluminación local si procede |
| **Humo y polvo** | Máscara de opacidad irregular y animación ascendente | Partículas, disolución, orientación y transparencia |
| **Niebla** | Densidad irregular y movimiento suave; posible fuente para textura 2D | Interacción jugador requiere otro sistema; **ART-FX-FOG-001** continúa siendo técnica distinta |
| **Suciedad, desgaste y manchas de barro** | Máscaras para intercalar colores/materiales sin repetición regular | Sprites/texturas propias; **ART-FX-TRAIL-007** dibuja huellas mediante base/profundidad/borde y partículas, **no** se sustituye con Perlin |
| **Rocas, tierra, césped y terreno** | Distribución de variaciones, manchas y detalles ambientales | Tiles artísticos, coherencia de biomas y colisiones separadas |
| **Nubes / fondos** | Siluetas y variaciones de densidad, movimiento | Colores, capas y profundidad visual |

**Relación con ART-WORLD-004 (mapas 2.5D):** trabajar sobre shaders, máscaras y tiles del mapa 2D; compatible en principio con personajes 3D renderizados sobre él, siempre que la iluminación y la perspectiva queden coherentes. No exige modelar el mundo entero en 3D.

### Cómo implementarlo en Godot 4.x, más adelante

- **Ruta base recomendada para probar:** recurso `FastNoiseLite` configurado como ruido Perlin + `NoiseTexture2D` para entregar al material/shader. `FastNoiseLite` también incorpora otros algoritmos; **seleccionar `TYPE_PERLIN` si se quiere probar exactamente Perlin**, no dar por hecho que es el valor predeterminado.
- Opcionalmente, shader `canvas_item` para agua/lava/humo 2D que muestrea textura de ruido y altera colores, alpha o UV. El movimiento y el mosaico seamless deben probarse.
- **Dos opciones de coste distintas:** (A) generar la textura una vez/precalcular para materiales que no cambian; (B) evaluar ruido o coordendas animadas por frame en GPU para superficies en movimiento. «Procedural» no significa necesariamente calcularlo de cero cada fotograma.
- Limitar cantidad de capas/octavas y resolución; reutilizar recursos entre mapas. Medir uso real de GPU/VRAM y *overdraw*.

**Documentación de referencia fiable:**
- `FastNoiseLite` Godot 4.x: https://docs.godotengine.org/es/4.x/classes/class_fastnoiselite.html
- `NoiseTexture2D` Godot 4.x: https://docs.godotengine.org/es/4.x/classes/class_noisetexture2d.html
- Ejemplo Godot de ruido como mapa de alturas en shader 3D: https://docs.godotengine.org/en/stable/tutorials/shaders/your_first_shader/your_first_3d_shader.html

### Prototipo de la futura fase artística (NO ejecutar ahora)

1. Sala 2D independiente con 3 superficies: pequeño lago, lava estilizada y zona de niebla/humo. Mostrar control sin ruido, variante con ruido fijo y variante animada.
2. Mantener estilo artístico de Pokémon Calvo (no perseguir realismo a costa de legibilidad); comparar frecuencias, 2/4 octavas como ejemplos, escala de mapa y paletas.
3. Probar humo/niebla con alpha irregular, y agua/lava con desplazamiento UV controlado; registrar si aparecen patrones que se repiten, parpadeos o mosaicos.
4. Medir FPS, GPU/CPU, VRAM y memoria de texturas en el hardware objetivo; usar mapa pequeño y varias áreas antes de extender el efecto.
5. Si la calidad no compensa, usar imágenes prerenderizadas o animación de sprites; no imponer ruido procedural para todo.

**Dependencias:** arquitectura definitiva de mapas y dirección artística. **Prohibiciones actuales:** no tocar `main`, V28, PR118, SaveV2, combate ni ramas IA1–IA5; no alterar niebla o huellas ya documentadas.

---

## Registro de cambios

- **2026-11-11 — ACTUALIZACIÓN ART-LIGHT-002:** transcripción completa de Guinxu analizada. Se documenta cel shading, ajuste de normales, luces individuales, Fresnel y outlines, separándolos de la conjetura anterior ACES. Se propone prototipo 3D/2D híbrido sin implementar nada.

- **2026-11-11:** ART-TEX-NOISE-008 creada tras recuperar la transcripción del vídeo sobre Perlin Noise; usos transversales de agua, lava, humo, niebla, suciedad y terreno. Sin desarrollo actual.

- **2026-11-11 — CORRECCIÓN ART-FX-TRAIL-007:** recuperada transcripción completa del Short; el método descrito es trail de sprites dividido en base/profundidad/borde, emitidos por capas mediante partículas con variantes artísticas. Se sustituye propuesta inicial de máscara como primera opción; máscara queda solo como alternativa no atribuible al vídeo.

- **2026-11-11:** ART-FX-TRAIL-007; referencia No Name Village/PieMastah y trail de nieve 2D, posible sistema compartido de huellas para nieve/barro/arena; sin implementación ni órdenes para trabajadoras.

- **2026-11-11:** añadido diseño comparativo 2.5D para modelos 3D con mapas 2D, ISO-CORE/JohnBrx y Pokémon Luminescent Platinum. Se distingue referencia 2D isométrica de mod basado en mapas 3D; sin autorización de implementación.
- **2026-11-11:** creado el cuaderno con niebla reactiva 2D/volumen aparente, iluminación («lighting axis» no identificado) y referencia de divulgador @PereGamedev. Exclusión expresa de tareas de desarrollo actual.
