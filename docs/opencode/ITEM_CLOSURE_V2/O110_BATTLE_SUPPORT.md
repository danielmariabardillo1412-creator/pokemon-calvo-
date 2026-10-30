# O110 — potenciadores y flautas mediante un adaptador común

IDs autorizados: x_attack, x_defense, x_sp_atk, x_sp_def, x_speed, x_accuracy,
dire_hit, guard_spec, blue_flute, yellow_flute, red_flute. No variantes X2/X3/X6
ni Dire Hit 2/3 sin catálogo/perfil revisado. No reescribir las 15 medicinas ni
la huida V21. Definición equipada, efecto de uso y consumo son cosas distintas.

## Contrato de referencia antes de programar

Reutilizar `.godot/item_mochi_v13/references/` y Pokémon Essentials local en
`D:/Proyectos/Pokemon Calvo Referencias/fuentes/pokemon-essentials`, commit
`8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b`. Interesan
`Data/Scripts/013_Items/003_Item_BattleEffects.rb` y `014_Pokemon/001_Pokemon.rb`.
RHH: `8654616bd38d9b28cc7dd8f3d0b4cb030aa2d40c`. Fijar hashes y contratos por fila.
Si hace falta otra referencia primaria pequeña, guardarla en la carpeta ignorada
de esta misión con URL/commit/SHA; no bajar dependencias, juegos o datasets nuevos.

Perfil de potenciadores modernos: seis X suben dos niveles de su estadística,
con tope +6 y rechazo al no tener efecto. Dire Hit usa la condición Focus Energy
del simulador (el contrato Essentials normal pone 2 y rechaza si ya está activo;
no confundirlo con variantes 2/3). Guard Spec aplica Mist a la side propia durante
su duración nativa, sin reaplicar ni gastar si ya existe. Verificar temporización
real de fin de turno; «5 turnos» no significa necesariamente contador 5 después
de ejecutar el turno completo. No escribir otra fórmula de críticos o etapas.

Azul cura sueño; Amarilla confusión; Roja atracción. Transcribir objetivo,
condición, inmunidad y consumo de las referencias, no de memoria: RHH marca las
tres reutilizables, Essentials comprueba Soundproof y que el estado exista.
Que Soundproof esté vetada en el pool no autoriza a ignorar su contrato si aparece
en un escenario explícito. Azul puede tener semántica de objetivo distinta de
las dos condiciones volátiles; no tratar a todo el equipo como activo.

Los potenciadores tienen además cambio de amistad en Essentials: battleitem
usa [1,1,0] por tramos y límites. Revisar interacciones antes de certificar el
efecto completo. No omitir ese efecto ni aplicarlo antes de un commit aceptado.

## Diseño permitido

Crear perfil propio battle_support_profile.json/.gd, importador por capacidades
y `native_bag_effects.cjs`; no copiar el motor de otro juego. Reutilizar el canal
de medicina existente como canal interno de mochila para no rehacer el RPC.
El único cambio autorizado en `applyMedicine` es dirigir IDs revisados al helper
nuevo y conservar la rama de las medicinas. Consumir solo tras éxito real;
flautas no gastan unidades aunque producen su acción/reacción correspondiente.

Usar APIs reales del @pkmn/sim 0.10.11 instalado, inspeccionadas antes de llamarlas:
boosts, addVolatile/removeVolatile, side condition y sus controles nativos.
No callbacks en Dex, parches en node_modules, daño/IA/RNG propios ni atajos de
«pass» elegibles por el jugador. El enemigo actúa exactamente una vez mediante
la reacción existente y el motor hace residuales, KO, reemplazos y temporizadores.
Reutilizar eventos conocidos; traducir los adicionales en event_adapter sin
convertir eventos desconocidos en éxito silencioso ni filtrar mensajes al rival.

NativeEngine ya inicializa `happiness` desde `spec.friendship`. Inspeccionar la
representación realmente serializada por el simulador, sin inventar un contador.
Si se integra amistad, hacerlo en la candidata nativa y proyectar su valor vivo
al liquidar; no mutar `_origin` ni la colección antes del commit. Se permite
añadir proyección calculada en `checkpoint` con compatibilidad de snapshots
anteriores. También puede proyectar actividad real del objeto para O120. No
cambiar serialize/restore, hash, dispatch, prepare/commit o schema de guardado.
Si no se puede representar un subefecto dentro de estas condiciones, dejarlo
PARTIAL/DEPENDENCY_MISSING explícito, sin certificar el objeto completo.

AdventureSession valida la frontera, permiso, inventario y actor; llama al
backend y publica gasto después del commit. Mantener `_command_busy`, guard de
campaña, revisión y bloqueo de vistas obsoletas. Extender la validación de
spent_items solo para nuevos consumibles realmente usables; reutilizables no
pueden inventar gasto y los objetos terminales de huida siguen rechazados en
checkpoints activos. Mantener schema 2 y compatibilidad de los saves V21.

La vista solo ofrece capacidades consultadas al servicio y elige objetivo.
Mostrar cantidades, objetivo/movimiento cuando corresponda, reutilización y
resultado; no poner lógica de etapas/condiciones/amistad en UI. No acumularlo en
field_demo. Conservar el cierre y las animaciones de mochila corregidos en V21.

## Pruebas por lote

Node: filas completas, efecto exacto frente a operaciones nativas de referencia,
topes/no efecto, objetivo inválido/reserva según contrato, condición ausente,
inmunidad/supresión relevante, Mist ya activo, Focus Energy ya activo, flautas
repetidas, enemigo una vez, residuales/KO, prepare/abort/commit y hash/RNG iguales
al abortar. No usar el mismo perfil generado como único oráculo del efecto.

Godot: inventario/colección sin tocar ante rechazo, commit único, persistencia
de amistad y gasto, guardar/cargar antes/después de usar, guardar/cargar después
de cambios de estado, trainer/wild, reemplazos, vistas obsoletas, no duplicación.
El uso de los ocho en campo sigue rechazado sin gasto. No aplicar efectos por
equiparlos. Tres formatos nativos cuando sean compatibles con el perfil moderno
declarado; no certificar reglas históricas de cada juego por ello.

UI/GPU: un panel con selección de varios IDs, tratamiento de consumibles y
reutilizables, controles recuperados al volver a medicina, mensaje claro, panel
compacto sin recortes. Ejecutar y conservar pruebas de V21 y medicina visual.
Al pasar el lote, informe O110, checkpoint y continuar con O120.
