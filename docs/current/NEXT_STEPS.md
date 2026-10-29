# Próximo trabajo — 2026-10-29

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
Continuar objetos por familias aún pendientes: experiencia, IV,
naturalezas, habilidades, condiciones de formas/evolución, bolas especiales y
mundo. El estado de referencia es [ITEM_SYSTEM_CURRENT_STATUS.json](ITEM_SYSTEM_CURRENT_STATUS.json).
Las rutas sin sistema disponible siguen pendientes; no simular consumos sin efecto.

Para caramelos, reutilizar ProgressionSystem/ProgressionRuleset, LearnsetSystem y
EvolutionSystem; contrastar los handlers y utilidades fijados de Essentials
8c5911e. Corregidos previamente los nombres de dos curvas y el divisor de erratic;
evidencia y limites en [PROGRESSION_GROWTH_CURVES_FIX.md](PROGRESSION_GROWTH_CURVES_FIX.md).
La base ya calcula experiencia/niveles y emite decisiones de movimientos
y evolución. Aún no hay una vista de campo que resuelva esas decisiones: adaptar
esa conexión sin aprender, sustituir o evolucionar silenciosamente por el jugador,
sin duplicar las curvas y sin consumir un objeto mientras falte resolver su uso.
Validar coherencia nivel/XP antes de usar caramelos y revisar compatibilidad de
partidas importadas antiguas; no reescribir valores silenciosamente. Filtrar las
nuevas opciones de movimiento/especie con la politica vigente, sin nuevos vetos.

## Revisión gráfica futura — iconos pequeños de Pokémon

Petición del usuario, 2026-10-29: después de estos sistemas, buscar primero un
conjunto coherente de iconos pequeños para el equipo. Si no se encuentra uno que
encaje, usar los sprites de reposo de combate que ya tenemos, a escala pequeña.
El panel de los seis Pokémon tendrá un diseño propio; no es obligatorio copiar
la presentación clásica. Queda como tarea gráfica posterior, sin bloquear los
objetos ni iniciar ahora búsquedas, descargas, generación o sustitución de arte.

Multijugador, campaña/mapas finales, reglas personalizadas de vidas/muerte,
presupuesto común Mega/Z/Max e IA neuronal no forman parte de esta limpieza.
OpenCode permanece detenido. No hay tarea T007 autorizada automáticamente.
