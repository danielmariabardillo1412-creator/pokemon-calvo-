# Prueba visual de ruta

## Objetivo y estado

Primer laboratorio con imagen para probar el bucle `moverse → hierba → encuentro
→ combate/captura → volver al mapa`, solicitado el 2026-10-18.
Rama: `feature/visual-field-lab-v1`. Parent: `e98e09f75b3f55c7d170f8f9906d49792cef5a6c`.
Ese parent coincide con la `main` remota consultada y tiene los 18 workflows de
regresión y la build de Windows correctos (20 runs, incluyendo un Godot duplicado).

Esta capa visual reutiliza la vertical slice técnica, sus colisiones, tablas,
sesiones, captura, inventario, Trainer AI y recorder. No reabre DATA V3 ni IA.
No representa todavía GF1-A..F ni una campaña con guardado de mundo.

## Ejecutar

En Windows: doble clic en `JUGAR_DEMO.cmd`. El lanzador usa Godot 4.7 del entorno
local o `godot` en PATH e importa las clases antes de iniciar la escena.
En cualquier plataforma, tras importar:

```sh
godot --path . res://scenes/visual/field_demo.tscn
```

La escena principal histórica se mantiene en `technical_overworld.tscn` para
conservar el contrato de regresión del laboratorio. La demo es una escena heredada.
La copia local de trabajo puede usar sparse checkout para omitir el snapshot de
API/schema inmutable; los datos raw/normalized/manifests sí están presentes.

## Cómo probar

- Flechas: caminar. La hierba está a la derecha, el rival arriba a la izquierda.
- Refugio abajo a la izquierda: entrar/salir sin encuentros; no ofrece aún curación.
- Cueva abajo a la derecha: transición y encuentros de nivel 8–12.
- Frecuencia: alternar 0, 5, 15, 30 y 100 %. Reinicia equipo, mochila y métricas.
- Reiniciar: empezar una prueba nueva con la configuración vigente.
- F1 / Ajustes: panel avanzado de especies, niveles, equipos e IA; pausa el movimiento.
- Informe: exportar el recorder existente. Su ruta se comunica en el panel técnico.
- En combate: ataques, cambio, balls, huida y retorno al mapa usan el dominio real.

El ejemplo inicial contiene Bulbasaur y Charmander Nv.5, Pidgey Nv.4–6 y la mochila
histórica (3 Poké Balls, 1 Super Ball, 1 Master Ball). La Master Ball sirve para
comprobar un recorrido de captura garantizado; las otras conservan el cálculo real.
Los RNG usan las semillas reproducibles del laboratorio: reiniciar reproduce la prueba.

## Frecuencia y tiempos

Se tira por distancia real recorrida (cada 32 px), solo dentro de una zona válida.
Con 96 px/s son 3 pasos/s. A 15 % por paso, la espera geométrica tiene media de
6,67 pasos / 2,22 segundos caminando continuamente dentro de hierba, excluyendo
combates, pausas, colisiones y camino sin encuentros. No garantiza que aparezca
antes de ese tiempo. El valor inicial es una propuesta de prueba, no un balance final.

La HUD muestra configuración, media teórica, tiradas, encuentros, capturas y tiempo
de desplazamiento en zona. Las métricas proceden del recorder/runtime existente.
Con 0 % no hay espera finita ni encuentros; con 100 % aparece en el primer paso válido.

## Imagen y límites

Mapa, personaje calvo, rival, refugio y cueva se dibujan en código Godot. La hierba
anima visualmente al pasar sin consumir RNG de juego. Se incluyen solo seis PNG
pequeños del snapshot local de sprites; atribución en `assets/prototype/README.md`.
Otras especies configuradas muestran «Sprite pendiente» si no tienen imagen elegida.
El combate de entrenador sigue usando su presentación diagnóstica actual.
No hay aún animación de lanzamiento/captura, sonido, tienda, curación ni save de mapa.

## Validación

Gate focal: `tests/gameplay/visual_field_test_runner.gd` integrado en Godot CI.
Comprueba input real, colisión, 0/100 %, encuentro, identidad de captura, consumo de
ball, vuelta a exploración, cuatro portales, salto y pausa por ajustes.

```sh
godot --headless --path . --script res://tests/gameplay/visual_field_test_runner.gd
godot --path . --script res://tests/gameplay/visual_field_test_runner.gd -- --capture
```

El segundo comando produce capturas reales en `.godot/visual_checks/` para revisión
de ruta, combate, resultado de captura, refugio y cueva. No se versionan esas salidas.
La certificación remota pertenece siempre al SHA exacto del PR; los resultados locales
no sustituyen una matriz completa en GitHub. El runner histórico de overworld ya
emitía avisos de recursos/RID al salir en el parent; se distinguen de fallos de gameplay.

## Siguiente trabajo de producto

Primero jugar y ajustar legibilidad, escala y frecuencia con esta demo. Después,
GF1-A..F del roadmap para inicial, mapas configurables, NPC/eventos, servicios y
save de mundo. El contenido/arte final se incorpora de forma selectiva.
