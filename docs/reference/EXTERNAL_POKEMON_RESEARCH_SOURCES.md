# Referencias externas: investigación técnica de juegos Pokémon

**Estado:** ÍNDICE DE FUENTES / INVESTIGACIÓN, NO AUTORIZA IMPLEMENTAR  
**Creado:** 2026-11-11  
**Propósito:** conservar fuentes externas útiles para decisiones de mapas, animación, modelos y sistemas de Pokémon Calvo sin importar recursos propietarios ni confundir *datamining* con verificación funcional de mecánicas.

## Fuente REF-POKE-001 — ChicoEevee / @ElChicoEevee

**Identidad corroborada:** Guinxu, en «¿Rinde mejor un juego con el mapa en 1 sola pieza?» (https://www.youtube.com/watch?v=a8Mz2YHd5cU), agradece la ayuda de **ElChicoEevee / ChicoEevee** para inspeccionar la estructura extraída de Ciudad Luminalia en Pokémon Leyendas Z-A. El subtítulo automático suena «Chico Ibi»; **no confundir la grafía**.

**Perfiles oficiales:**
- X: https://x.com/ElChicoEevee
- GitHub: https://github.com/ChicoEevee
- YouTube: https://www.youtube.com/@ElChicoEevee

**Especialidad documentada:** minería de datos de videojuegos Pokémon, exploración de archivos internos, modelos, texturas, animaciones, mapas ocultos/descartados y herramientas de modding. No equiparar automáticamente «haber recuperado un recurso» con «conocer el código fuente completo, sus reglas de combate o cómo se optimiza el motor».

### Pruebas públicas de actividad técnica

1. **Herramienta Blender de importación/exportación Pokémon Switch**:  
   https://github.com/ChicoEevee/Pokemon-Switch-Model-Importer-Blender  
   README: script/addon Python que aspira a trabajar con Blender 4.x/5.x, modelos y animaciones de juegos Switch, con colaboradores Shararamosh, SomeKitten y otros. Incluye utilidades de animaciones, mallas, esqueletos y formatos nativos. El README avisa que archivos de **Leyendas Z-A todavía no funcionan** en el contexto señalado. No está probado con Godot ni debe suponerse un puente automático a Godot.
2. **Scripts para modding PLA y Scarlet/Violet en Blender**:  
   https://github.com/ChicoEevee/PokeModding-PLA-SV-Blender  
   README identifica exportadores de malla/esqueleto y dependencias **FlatBuffers + schemas** (PokeDocs). Parte del trabajo procede de colaboradores; respetar atribuciones. Relevancia: entender cómo se almacenan y animan personajes y que el pipeline suele necesitar esqueletos, pesos, UV, animaciones y materiales compatibles.
3. **Investigación de mapas antiguos/no utilizados**:  
   - En 2022 colaboró con DeepGameResearch para visualizar correctamente terreno de un enorme mapa no usado en **Leyendas Arceus**: https://pokepatch.com/2022/02/14/hidden-modern-room-discovered-in-pokemon-legends-arceus/  
   - En 2023 mostró una habitación y otros interiores no usados de **Escarlata/Púrpura**: https://as.com/meristation/noticias/se-filtran-los-interiores-de-edificios-no-usados-en-pokemon-escarlata-y-purpura-n/  
   - En 2025, Guinxu atribuye al trabajo compartido el examen de **Ciudad Luminalia** en versiones separadas: mundo de gameplay parcialmente dividido frente a modelo simplificado unificado de cierta cinemática (véase `ART-WORLD-STREAM-010`).
4. **Material de referencia de Pokémon GO en Unity**:  
   https://github.com/ChicoEevee/Pokemon-GO-AssetBundles  
   El propio repositorio lo presenta como **archivo para investigación** y advierte expresamente de los derechos de terceros. Puede informar del empaquetado y organización de recursos en Unity, pero no supone que esos recursos puedan añadirse al proyecto Godot.
5. **Datamining de Pokémon UNITE y Champions**: investigaciones sobre contenido, modelos y datos que no se muestran a jugadores. Fuente: entrevista de 2022 https://pokemonalpha.es/2022/05/entrevistas-pokemon-hoy-con-elchicoeevee-un-creador-de-contenido-de-pokemon-unite/ . Su utilidad para reglas canónicas de la aventura Calvo es baja: juegos y sistemas diferentes; muchas publicaciones tratan filtraciones/novedades, no ingeniería.

### Qué estudiar específicamente para Calvo cuando sea oportuno

| Prioridad | Asunto | Para qué podría servir | Verificación que faltaría |
|---|---|---|---|
| **Alta (fase mapas)** | Ciudad de gameplay fragmentada frente a versión unificada de cinemática | Referencias para `ART-WORLD-STREAM-010`; mundo continuo por regiones, vistas panorámicas con recurso alternativo | No copiar la arquitectura de Z-A: validar en Godot 2D/2.5D con mediciones reales |
| **Alta (fase personajes)** | Estructura de mallas, UV, rigging y animaciones vistas en el addon Blender | Mejorar pipeline de creación propia Meshy → Blender → Godot; evaluar calidad de huesos/animación | Ver compatibilidad de herramientas y licencias; no importar modelos Nintendo |
| **Media (fase interiores)** | Escenas/terrenos no usados y separación de interiores | Inspiración para organizar entradas, interiores, transiciones y escenas de test | Los recursos descartados no prueban por sí solos cómo se implementan transiciones finales |
| **Media-baja** | Organización AssetBundles Pokémon GO / recursos | Investigación comparativa de atlas, empaquetado y variantes | Unity no es Godot, coste de adaptación; evita recursos propietarios |
| **Baja** | Filtraciones de Pokémon UNITE/Champions, eventos y pases | Noticias o curiosidades | No distraer ni usarlas como guía para sistemas RPG base |

### Límites y riesgos

- **Nintendo/Game Freak y sus colaboradores conservan los derechos de los recursos de los juegos.** No añadir al repositorio Calvo recursos extraídos (modelos, texturas, audio, escenas, animaciones) bajo la suposición de que por estar descargables tienen licencia. Usar hallazgos para **analizar ideas abstractas y producir assets originales**.
- En la comprobación del repositorio `Pokemon-Switch-Model-Importer-Blender` desde GitHub (2026-11-11), el campo `license` aparecía como **null**. Un repositorio público no equivale a código reutilizable sin condiciones: revisar permisos/licencia explícita antes de copiar scripts o derivar código.
- No descargar, ejecutar o instalar extractores en el equipo de usuario sin una petición explícita, revisión de seguridad y procedencia.
- Ni los mapas extraídos ni los modelos de un juego prueban por sí mismos fórmulas de combate, reglas de objetos o el comportamiento real de SaveV2. Para eso, priorizar nuestras suites verificadas y fuentes canónicas.
- Conservar el enlace original y fecha de hallazgo; contrastar afirmaciones de publicaciones sociales o archivos beta antes de elevarlas a requisito.

**Estado al registrar:** referencia útil encontrada y clasificada, **ninguna tarea autorizada para IA1–IA5, sin integración, sin cambios de código, `main` ni V28**.

## Cambios

- 2026-11-11 — Alta de fuente REF-POKE-001 con recursos públicos técnicos comprobados y limitaciones legales/de alcance.
