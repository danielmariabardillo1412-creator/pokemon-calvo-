# Comparador general V1 — contrato de ejecucion

Peticion del usuario, 2026-10-29: tras terminar vitaminas/plumas, comparar de forma
automatica amplia el juego anterior con esta copia organizada. V7 esta terminado
en eb18a5d. Ejecucion terminada: 135/135 casos; estado FINDINGS_REVIEW_REQUIRED.

Resultado conservado en reports/REPORT.md y results.json de la carpeta V1:
86 puertas comunes PASS, 17 solo de la organizada PASS, 30 fallos compartidos
y 2 inconclusos iniciales. Los intentos iniciales siguen registrados aunque su
repeticion con contexto/referencias correctos haya pasado. No son 32 defectos
nuevos del juego. No hubo fallo unilateral de la organizada. Los 18 estados de
la traza determinista coinciden exactamente, con 38 asserts independientes.
El barrido nativo nuevo de 900 movimientos permitidos paso en ambas versiones.
La integridad final de ambas fuentes y referencias quedo verificada.

Quedan por resolver pruebas obsoletas de escena principal, auditorias estaticas,
informes de datos antiguos y casos visuales. Los resultados no se declaran PASS
global. Esta evidencia corresponde a los bytes anteriores a la limpieza; los
cambios posteriores necesitan nuevas pruebas y no alteran el informe V1.

Fuentes de solo lectura:
- D:/Proyectos/Pokemon Calvo (trabajo local real, incluidos cambios sin commit).
- D:/Proyectos/Pokemon Calvo - Arquitectura Kilo (arquitectura aceptada y objetos V7).

Ejecucion: D:/Proyectos/Pokemon Calvo - Comparador General V1/original y organized.
Son copias fisicas sin enlaces, sin .git y con nombres distintos de userdata.
No se cargan partidas reales. El manifest conserva SHA-256, tamanos, HEAD y estado
local de las fuentes; las fuentes no se ejecutan ni se modifican. Al finalizar se
vuelven a comprobar sus hashes. Los archivos de soporte .godot se seleccionan del
inventario presente en el proyecto organizado, conservando los bytes propios de
cada fuente; se omiten historicos masivos de capturas no necesarios para correr
el juego. Cualquier recurso ausente necesario produce un hallazgo, no un PASS.

Capas:
1. Descubrimiento de scripts ejecutables, resolviendo herencia de SceneTree para
   no omitir los runners de familias de movimientos que heredan de otro runner.
2. Mismas pruebas comunes en ambos juegos; se verifica que los tests tengan los
   mismos bytes antes de atribuir equivalencia. Se cubren datos, combate, mundo,
   captura, inventario, objetos, guardado, IA y comprobaciones tecnicas visuales.
3. Pruebas nuevas de arquitectura y objetos se ejecutan en la organizada como
   puertas adicionales; que falten en la antigua no es una regresion.
4. Sonda identica con semillas fijas: mochila/curacion/PP/EV, equipar, PC, evolucion,
   progresion, guardado/carga, combate salvaje, repeticion de checkpoint, captura y
   entrenador. Compara los estados resultantes y conserva asserts independientes.
5. Contratos nativos y barrido nuevo de movimientos: inventario 919, escenarios
   positivos para 900 IDs permitidos y exclusiones explicitas, usando fixtures
   locales fijados. Proyeccion Godot, contextos, Z y dobles conservan sus puertas.

Los exportadores de fixtures, diagnosticos que ignoran asserts y collectors
artisticos masivos no cuentan como tests. Se enumeran en cases.json con motivo;
se mantienen las pruebas visuales individuales con asserts y GPU cuando procede.

Un exit 0 sin comprobaciones es INCONCLUSIVE, un timeout nunca es PASS y un error
de script vence al exit 0. Fallar igual en ambos juegos es SHARED_FAILURE. Solo
se permite un diagnostico de JSON corrupto expresamente esperado en el test
negativo sg_corrupt_rejected, con ese assert PASS y una sola ocurrencia; otros
errores permanecen rojos. Los logs originales siempre se conservan completos.
El clasificador tiene pruebas negativas propias en test_results.py.

Uso desde la raiz organizada:

```text
python tools/regression_comparator/test_results.py
python tools/regression_comparator/runner.py --prepare --pilot
python tools/regression_comparator/runner.py --resume
```

La preparacion rechaza una carpeta destino existente; no se sobreescriben ni
borran copias anteriores. Reanudar conserva los casos terminados y espera el
proceso real, no reinicia por una observacion temporal sin salida. Un piloto no
certifica el barrido general. Una ampliacion del manifest debe ser aditiva,
conservar los casos ya ejecutados y registrar hashes anteriores/nuevos.

Resultados y logs locales: D:/Proyectos/Pokemon Calvo - Comparador General V1/reports.
manifest.json y *_source_files.json permiten atribuir la prueba a los bytes
exactos de cada juego. cases.json declara cobertura y exclusiones. REPORT.md y
results.json muestran diferencias, errores compartidos e inconclusos.

Limites: escenarios finitos no prueban cualquier secuencia posible de juego.
Dos versiones pueden compartir un fallo; por eso se conservan oraculos y asserts,
y no solo igualdad. Las comparaciones tecnicas de arte no son aprobacion artistica.
No se activan multijugador, IA neuronal, nuevos sistemas del mundo ni funciones
pendientes para conseguir verdes. No se regenera ningun dataset del juego.
