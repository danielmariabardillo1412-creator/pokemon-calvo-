# O120 — Bola Humo y modificadores del encuentro

Investigar/implementar esta familia con datos revisados; no añadir siete nombres
vacíos al Dex. IDs de efecto autorizados: smoke_ball, cleanse_tag, pure_incense.
Los otros cuatro huecos se investigan y clasifican, sin activar nuevas mecánicas.

## Bola Humo

Essentials fijado: `011_Battle/001_Battle/007_Battle_ActionRunning.rb` y
`011_Battle/007_Other battle code/009_Battle_ItemEffects.rb`. Garantiza Run si el
objeto está activo, antes del atrapamiento, sin consumirse. No permite huir de
entrenadores ni se activa solo por tenerlo en inventario. RHH lo marca
HOLD_EFFECT_CAN_ALWAYS_RUN y potencia 30. Generación contrastable con pret Gen 2
ya almacenado en `.godot/field_held_v16/references/`.

Crear `held_escape_items.gd`: regla pura, sin UI/IO/RNG propios. Integrar en
AdventureSession.flee, usando el objeto vivo del actor activo, no el original
del combate. Desarme, Truco, Lanzamiento, objeto ya consumido, supresión por Sala
Mágica/Embargo/Torpeza y cambios de actor deben respetarse. No derivar actividad
del objeto solo de su nombre. Se permite que checkpoint proyecte un booleano
calculado con la API real `ignoringItem` del simulador; no duplicar sus reglas.

Usar el cierre FLED y guardas de V21. No alterar Run normal ni su número de
tiradas cuando no aplica Bola Humo. Si el contexto legado puede comprobarse con
reglas existentes, integrar también su frontera Run; si no, documentarlo sin
declarar paridad. No introducir callbacks de mecánicas en Dex.

Añadir su descriptor únicamente después de conectar y probar el efecto real,
mediante field_world_items_v2.json/registro propio, sin sobrescribir definiciones
competitivas existentes. Los seis/siete huecos restantes se recalculan, no se
reducen por imaginación. No tocar los manifiestos generados V20 ni sus pruebas.

## Amuleto y Puro — contexto de encuentros

Essentials: `012_Overworld/002_Battle triggering/003_Overworld_WildEncounters.rb`:
Cleanse Tag/Pure Incense sobre el primer Pokémon modifican la tasa por 2/3 y
también las condiciones de pasos mínimos de ese sistema. Contrastar generación,
primer miembro vivo/no vivo, modo de encuentro y condiciones con la referencia
que se use. No copiar solo un número y certificar el comportamiento entero.

El juego dispone de WildEncounterTable y roll inyectado por paso, pero no debe
crearse un mundo nuevo ni nuevos campos persistentes para imitar otro motor.
Si cabe una tasa explícita en el perfil actual, crear encounter_item_modifiers.gd
que prepare una COPIA validada de la tabla; el resolver y RNG existentes siguen
intactos. Declarar cualquier diferencia como PARTIAL_VERIFIED_RATE_ONLY si faltan
condiciones de pasos, no como equivalencia completa con Essentials. Si no hay
una adaptación coherente, dejar dependencia documentada y pasar al cierre.

Único punto editable del dueño del mapa: field_prepare_native_encounter. Solo
una llamada al helper y coordinación necesaria; preload local si hace falta.
El resto de field_demo está congelado por guard. No cambiar tablas guardadas,
probabilidad global de configuración, métricas, fuente/avance de RNG, semillas,
callbacks o movimientos. WildEncounterSystem y su algoritmo no se editan.
El legado puede usar el mismo helper en begin_encounter si la semántica coincide.

## Pruebas agrupadas

Bola Humo: lento/rápido, atrapado/no, sin objeto/solo mochila, activo/suprimido,
consumido, Truco/Desarme/Lanzamiento, cambio de actor, entrenador rechazado,
checkpoint antes/después, guardado/carga y no consumo/XP/reacción/RNG extra.
Rechazo de revisión obsoleta o campaña cambiada sin mutación. Casos normales de
Run conservan exactamente la conducta y RNG anteriores. Escena real con equipar,
entrar en combate, guardar/cargar, huir y volver al mapa sin unidad fantasma.

Encuentros: mismo input/RNG sin objeto da resultado y estado RNG idénticos al
baseline; tabla original intacta; tasa 0/100 y redondeo; actor líder/almacén,
objeto consumido y combinaciones. Cientos de semillas pueden barrerse sin UI;
las tasas cambian resultados legítimamente, no se exige igualdad con el juego
sin efecto. Sí reproducibilidad con el mismo estado/contexto y contrato exacto.
No sustituir todo eso por una frecuencia estadística que «parece razonable».

Registrar qué perfiles/contextos se probaron y qué sigue parcial. Usar la UI real
en una muestra representativa. Continuar con O190 aunque parte del contexto de
mundo quede pendiente; no implementar mapas, economía, crianza o nuevos saves.
