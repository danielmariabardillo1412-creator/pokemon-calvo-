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
| `ART-LIGHT-002` | Iluminación/materiales para evitar personajes con aspecto de plástico; «lighting axis» por identificar | APARCADA / TÉRMINO SIN CONFIRMAR | Alta para dirección de iluminación |
| `ART-REF-003` | Revisar periódicamente explicaciones técnicas de @PereGamedev y otros autores fiables | REFERENCIA / SIN TAREAS ACTIVAS | Según propuestas concretas |
| `ART-WORLD-004` | Arquitectura de mapas 2.5D: personajes 3D y escenarios 2D con sensación de volumen | APARCADA / DISEÑO COMPARATIVO | Alta al empezar mapas |
| `ART-REF-005` | Referencia ISO-CORE / JohnBrx: terreno con relieve y representación 2D | REFERENCIA TÉCNICA / VERIFICADA PARCIALMENTE | Alta |
| `ART-REF-006` | Referencia Pokémon Luminescent Platinum (mod BDSP) | REFERENCIA VISUAL, NO PRUEBA DE MAPA 2D | Media |

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

## ART-LIGHT-002 — Iluminación y materiales naturales; «lighting axis» por identificar

- **Solicitud literal del usuario:** «lighting axis», técnica que ayudaría a evitar que personajes parezcan «de plástico».
- **Estado:** TÉRMINO NO VERIFICADO. **No asumir que ese es el nombre correcto de una función, plugin o shader.**
- **Posible interpretación:** `ACES` (*Academy Color Encoding System*) o *ACES tonemapping*, que trata cómo se representan altas luces, contraste y color. Es una **posibilidad fonética, no una identificación confirmada del vídeo**. Existe en el entorno de Godot, pero **no arregla por sí mismo** materiales plásticos.
- **Alternativas técnicas a contrastar cuando esté el vídeo:** iluminación ambiental y de relleno, luces de rebote, sombras de contacto/oclusiones, `roughness` y `metallic` de materiales PBR en 3D, mapas normales, *subsurface scattering* para piel 3D (si procede), y tratamiento de color. **No activar todo por defecto**; dependerá del estilo DS/GBA y de si el personaje se dibuja en sprite 2D o se renderiza como modelo 3D.

### Prueba futura

1. Identificar y guardar **el vídeo concreto** y el nombre técnico exacto de la técnica.
2. Diseñar una sala de iluminación de referencia: mismo personaje y cámara, material y luz controlados.
3. Comparar configuración actual frente a iluminación/materiales corregidos y ACES/AgX si corresponde.
4. Medir legibilidad de silueta y caras, consistencia con mapas/sprites, reflejos excesivos y FPS/VRAM.
5. Adoptar solo lo que mejore el aspecto sin volverlo fotorealista o introducir luces caras innecesarias.

**Referencias verificadas:**  
- Godot: entorno, ambiente, luz reflejada y tonemapping (ACES y AgX): https://docs.godotengine.org/es/4.x/tutorials/3d/environment_and_post_processing.html  
- Materiales PBR/roughness y ambient occlusion: https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html

**Pendiente de aclarar:** enlace o transcripción del vídeo donde el creador menciona «lighting axis». No marcar ACES como término confirmado hasta verlo.

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

## Registro de cambios

- **2026-11-11:** añadido diseño comparativo 2.5D para modelos 3D con mapas 2D, ISO-CORE/JohnBrx y Pokémon Luminescent Platinum. Se distingue referencia 2D isométrica de mod basado en mapas 3D; sin autorización de implementación.
- **2026-11-11:** creado el cuaderno con niebla reactiva 2D/volumen aparente, iluminación («lighting axis» no identificado) y referencia de divulgador @PereGamedev. Exclusión expresa de tareas de desarrollo actual.
