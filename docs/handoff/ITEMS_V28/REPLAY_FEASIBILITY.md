# Viabilidad: reproducir las pruebas existentes (2026-11-01)

## Resultado y recomendación

**VIABLE con alcance limitado, demostración local ejecutada; CI pendiente.**
Continuar aprovechando los escenarios ya escritos, sin crear contratos por objeto.
No es un sustituto de una certificación integral: el contador sigue en **27/30/4**.
Bayas y rediseño amplio quedan suspendidos por la nueva prioridad humana.

Los `cases.json` no contienen las funciones de aserción. Estas permanecen en
`held_effect_sweep_v2.cjs` / `v3.cjs`; por ello se ejecutan los generadores originales
íntegros, con sus controles y asserts, y se seleccionan solo sus casos aprobados.
El reproductor consume los DTO y comandos originales directamente. No hay reglas,
callbacks, contratos de efectos nuevos ni ramas por objeto en el reproductor.

## Qué se obtiene automáticamente

| Objeto | Casos originales, semillas 1 y 19 | Cobertura nativa heredada |
| --- | --- | --- |
| black_glasses | V2: type_boost / type_boost_nonmatching (4) | Más daño de tipo coincidente frente a control sin objeto; tipo no coincidente igual y objeto retenido |
| colbur_berry | V2: resist_berry / resist_nonmatching (4) | Menos daño entrante coincidente y retirada real de baya; control no coincidente sin consumir |
| toxic_orb | V2: end_turn_status (2) | Veneno grave real al final del turno; no prueba inmunidades ni turnos posteriores |
| sticky_barb | V3: residual / contact_transfer (4) | Daño residual exacto; transferencia por contacto: sale del portador y aparece en el atacante |

Se conservan las aserciones originales; no se transforman descripciones en pruebas.
El éxito del generador y sus recibos se vinculan por case_id, hashes de fuentes,
casos y pruebas. En Godot se comprueba hash exacto antes y después de cada comando
original, con misma semilla/DTO; no basta con que el combate arranque sin errores.
Se reutilizan `item_automation_v28.gd`, Service.equip, sesión nativa, selector legal
del rival, `_restore_probe`, SaveV2, `_units`, `_map_probe` y validación de archivos.
El validador contrasta también el guardado final contra HP/objeto/estado nativos.

Cada caso añade colección física nueva, equipamiento por el servicio existente,
rechazo de revisión obsoleta, ausencia de publicación prematura, restauración
activa por disco y publicación terminal real mediante Poké Muñeco (FLED). Se
rechaza repetirla, se comprueba stock y se decodifica el guardado final. Cada ID
recorre además la mochila/mapa existentes. Retirada/transferencia no se confunde
con comer un objeto: Sticky Barb queda en el rival salvaje, no vuelve a la mochila.

## Límites y hallazgo real

La primera ejecución local falló: comparaba hash bruto tras guardar/restaurar.
Los estados completos eran iguales, pero el orden de claves JSON había cambiado
y el hash nativo no es canónico respecto a ese orden. Se conservan ambas garantías:
reproducción original con hashes exactos ANTES de guardar; después de restaurar,
igualdad estructural íntegra del snapshot, incluidos RNG, logs e identidades.
No se cambian NativeEngine, schema, datos, fixtures ni los verificadores anteriores.
Recibo fallido: replay_1793490967116361300 (477 comprobaciones, no PASS).
Demostración local corregida: replay_1793491087661169700, **14 casos / 435 checks**.

Esto solo transfiere las pruebas causales/metamórficas que ya contienen esos
generadores. Comparar el motor consigo mismo sin sus asserts no sería suficiente.
Faltan controles no escritos: efecto con objeto en otro Pokémon, inmunidades de
Toxic Orb, restitución/captura de Sticky Barb transferido, retirada y reentrada,
consumo repetido en turnos posteriores, victoria/derrota/XP y todas las interacciones.
La demo usa un rival salvaje y los 14 casos son de un turno; no demuestra dobles,
fronteras de cambio forzado ni todos los casos V2/V3. Reutilizar 22 evidencias
históricas no convierte automáticamente los 30 pendientes en objetos certificados.
Los otros ocho necesitan evidencia nueva, no tests inventados para este replay.
PID Linux y GPU/manual siguen siendo deudas independientes.

## Coste y mantenimiento

Coste funcional de producción: **0 líneas**. Nuevas fuentes compartidas: 90 líneas
GDScript + 91 Python + 22 de tests; tres líneas de allowlist y once de CI:
**217 líneas añadidas de infraestructura/pruebas**, incluyendo blancos/comentarios.
Seis archivos de código/metadata/CI afectados (tres fuentes nuevas, un UID y dos
archivos existentes). Los cuadernos se contabilizan aparte. Por objeto: **0 líneas
de efectos y 0 contratos nuevos**; solo la selección de cuatro IDs en una lista.
Media amortizada inicial: 54,25 líneas por objeto, NO coste marginal certificado.
No se añade archivo/validador por familia. Las seis pruebas nuevas rechazan evidencia
sin aserciones, casos incompletos y declaraciones de certificación indebidas.

Comparación reproducible por Git (`.gd`, `.py`, `.yml`, añadidos, sin cuadernos,
JSON ni UID; incluye orquestación y tests):

| Lote previo | Rango | Añadidas / eliminadas | Media añadida/objeto |
| --- | --- | --- | --- |
| Elección, 3 IDs | 47f42aef → 0c1f48eb | 603 / 0 | 201 |
| Pasivos, 3 IDs | 648a2c86 → 7f973f5b | 455 / 41 | 151,67 |
| Globo/Botas, 2 IDs | 4d39d3aa → 961cb0ac | 494 / 45 | 247 |

Son alcances diferentes: los lotes anteriores agregan controles específicos nuevos;
esta demo reutiliza controles antiguos. No se afirma haber abaratado en ese factor
una certificación equivalente. La ejecución local tarda 91,85 s: 76,62 s de replay/
integración/mapa y 15,23 s de exportación/generadores. Estos vuelven a ejecutar
368 + 908 casos originales, aunque solo se reproduzcan 14 en el harness nuevo.
Tiempos anteriores de CI Windows: 225,08 s (30 casos Elección+pasivos) + 138,39 s
(10 Globo/Botas); Ubuntu: 276,61 + 172,40 s. La comparación temporal también tiene
distintos equipos/alcances; los resultados de esta demo en CI se registrarán aparte.

Mantenimiento esperado: bajo por ID si el caso ya cabe en DTO/comandos/guardado
actuales; el trabajo específico es revisar el inventario de casos y sus huecos.
Un cambio del formato del generador o de la API de sesión requiere un ajuste común.
Un efecto ausente o control causal inexistente no se arregla con reproducción:
se marca fuera de alcance. No ampliar el reproductor con reglas por objeto.
**Recomendación: continuar con esta vía para reaprovechar pruebas; abandonar la
idea de que replay por sí solo puede cerrar los 30 pendientes.** No iniciar otro lote.
