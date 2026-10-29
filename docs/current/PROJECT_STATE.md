# Estado del proyecto — 2026-10-29

Copia activa: `D:/Proyectos/Pokemon Calvo - Arquitectura Kilo`.
Original separado e intacto: `D:/Proyectos/Pokemon Calvo`.
Rama local: `codex/kilo-architecture-v1`; no hay remoto configurado.

## Arquitectura y ejecución

T001–T006B aceptadas en `208c06c0`: HUD, diagnóstico, API del campo, mochila,
puente nativo y publicación validada de partidas. El motor nativo es la
autoridad del combate. El servicio de objetos conserva las transacciones.
El motor anterior sigue teniendo consumidores; no es código descartable.

La demo principal visual hereda del mundo técnico. Tiene movimiento, encuentros,
captura, combates, mochila, PC, progresión y guardado. No es una campaña completa.
Detalles de controles y arte: `docs/project_book/VISUAL_FIELD.md`.
Perfil de combate: [BATTLE_PROFILE.md](BATTLE_PROFILE.md).

## Ataques, objetos y arte

El barrido del perfil conjunto cubre positivamente 900 movimientos permitidos
de 919 IDs: 820 ordinarios, 50 Z de daño, 19 Maxi y 11 de dobles; 19 exclusiones.
No prueba todas las combinaciones posibles. Evidencia: `UNIFIED_MOVE_SWEEP.json`.
El barrido fresco del comparador V1 pasó en ambos juegos.

Objetos: 2.222 IDs inventariados. Estado mecánico vigente:
[ITEM_SYSTEM_CURRENT_STATUS.json](ITEM_SYSTEM_CURRENT_STATUS.json).
Hay 61 efectos de campo verificados (41 de recuperación y 20 de entrenamiento:
18 EV/amistad base y 2 de mejoras de PP),
además de las conexiones y límites de equipados, evolución y máquinas registrados
allí. No están certificados todos los efectos de todos los objetos.

Arte beta de objetos: [ITEM_ART_CURRENT_STATUS.json](ITEM_ART_CURRENT_STATUS.json).
La presencia de una imagen no certifica su mecánica. Las revisiones artísticas y
los cambios de aspecto anacrónico quedan separados de esta limpieza.

## Correcciones y validación

El fallo de tipo de región en guardado se corrigió en `0e2cd3a2`, con rechazo
seguro de valores mal formados. Objetos V5–V7 cerrados hasta `eb18a5da`.
V8 añade Más PP/PP Máximos con helper puro y amistad positiva compartida;
19.872 casos de catálogo, 336 contextos y recorrido nativo de mochila/guardado/
combate/captura/restauración PASS. Detalle: [ITEM_FIELD_V8.md](ITEM_FIELD_V8.md).
Antes de caramelos se corrigió la interpretación de dos nombres de curva XP y el
divisor del tramo 69–98 de erratic. Las seis tablas completas coinciden con dos
referencias independientes; 4.209 checks y regresiones PASS. No incorpora aún
caramelos ni migra partidas antiguas: [PROGRESSION_GROWTH_CURVES_FIX.md](PROGRESSION_GROWTH_CURVES_FIX.md).
La auditoría de fidelidad a PokéAPI revisó especies, regionales, aprendizaje,
evoluciones y fichas de movimientos/habilidades/objetos. Se restauró la condición
Ataque=Defensa de Tyrogue y se conectaron sus tres comparaciones al contexto real
de progresión/validación del dueño. Procedencia de Lilligant de Hisui corregida;
textos válidos por generación y duplicado API de Baya Hibis conservados.
Alcance y pruebas: [POKEAPI_DATA_REPAIRS_V1.md](POKEAPI_DATA_REPAIRS_V1.md).
Evidencia y límites por fase en los informes de objetos; no duplicar sus matrices.

El comparador V1 terminó 135/135 casos: 86 puertas comunes PASS, 17 adicionales
de la organizada PASS, 30 intentos con fallo compartido y 2 inconclusos iniciales.
Varias repeticiones corregidas ya pasaron; esos números no son 32 fallos nuevos.
No hubo fallo unilateral de la organizada. Coinciden los 18 estados de la traza,
con 38 asserts independientes. Integridad de las fuentes verificada.
Resultado global: FINDINGS_REVIEW_REQUIRED. Informe:
[COMPARATOR_GENERAL_V1.md](COMPARATOR_GENERAL_V1.md).

Limpieza y corrección declaradas cerradas; [CLEANUP.md](CLEANUP.md) registra lo
retirado, sus límites y las pruebas posteriores. Código y recursos del juego
siguen idénticos por hash. [NEXT_STEPS.md](NEXT_STEPS.md) indica lo pendiente.
Los resultados V1 son históricos y no certifican los bytes modificados después.

Las versiones extensas anteriores de este estado y de los próximos pasos están
en Git hasta `021a9c5`. Contratos de arquitectura aceptados en `docs/kilo/`;
ADR, créditos y procedencia permanecen en sus carpetas.
