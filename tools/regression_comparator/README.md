# Comparador local general

Ejecutar en la raiz del proyecto organizado. No ejecuta ni modifica los juegos
fuente: crea dos copias fisicas y userdata independientes. Lee el contrato en
docs/current/COMPARATOR_GENERAL_V1.md y los limites/casos del manifest.

```text
python tools/regression_comparator/test_results.py
python tools/regression_comparator/runner.py --prepare --pilot
python tools/regression_comparator/runner.py --resume
```

Una ejecucion posterior sobre una nueva version usa otra carpeta dedicada:

```text
python tools/regression_comparator/runner.py --prepare --output "D:/Proyectos/Pokemon Calvo - Comparador General V2" --pilot
python tools/regression_comparator/runner.py --output "D:/Proyectos/Pokemon Calvo - Comparador General V2" --resume
```

No se sobreescribe un historial ni se reinician procesos vivos. El lock comprueba
PID y fecha real de creacion. Cada lado terminado se guarda antes de avanzar.
Un script abortado, timeout, exit distinto de cero o resumen FAIL nunca da verde.
Los errores de script detienen solo el proceso hijo propio que ya fallo.

Se preparan directorios de salida declarados y las referencias locales de dobles
que coinciden con el SHA del dataset; no se descarga ni regenera el dataset.
Las ampliaciones de plan deben preservar el manifest previo y registrar cambios.
Las ejecuciones con informes previos exigen --resume; para repetir con codigo
nuevo se exige una carpeta nueva, conservando la prueba de la version anterior.
