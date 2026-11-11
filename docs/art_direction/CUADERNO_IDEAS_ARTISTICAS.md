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

## Registro de cambios

- **2026-11-11:** creado el cuaderno con niebla reactiva 2D/volumen aparente, iluminación («lighting axis» no identificado) y referencia de divulgador @PereGamedev. Exclusión expresa de tareas de desarrollo actual.
