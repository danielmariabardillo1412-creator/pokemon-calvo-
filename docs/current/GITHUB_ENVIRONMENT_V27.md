# Preparar el checkout de la actualización V27

Usar `codex/organized-update-v27`. Requiere Python 3.11+, Node.js/npm y Godot 4.7.
No necesita los directorios originales de F: ni otro proyecto en D:.
Leer AGENTS.md y START_HERE.md; no ejecutar órdenes históricas por encontrarlas
en un cuaderno anterior.

## Recursos visuales existentes

Desde la raíz del checkout:

```text
python -B tools/distribution/restore_resources.py
python -B tools/distribution/restore_resources.py --check
```

El primer comando descarga los cuatro archivos de la release fijada por el
manifiesto, verifica cada ZIP y sus archivos y restaura solo recursos ausentes.
Si un recurso existente difiere, se detiene preservándolo. Para descargar los ZIP
por separado y restaurar sin red: `--archive-dir RUTA_A_LOS_ZIP`.
Los hashes esperados están versionados; no modificarlos para ocultar un fallo.

Los recursos conservan sus rutas actuales, incluidas las que viven en `.godot`.
Por ello no borrar esa carpeta como si todo su contenido fuese regenerable.
La futura migración de esos recursos fuera de caché requiere otra tarea.

## Simulador fijado

El simulador no se incluye como node_modules ni como un ejecutable Windows.
El instalador existente usa el lockfile y `@pkmn/sim@0.10.11`:

```text
python -B tools/battle_reference/run.py --install --limit 1
```

Con Godot/Node/npm en PATH, el comando importa y ejecuta un caso de contraste.
Si se usan otras rutas, indicar sus opciones `--godot`, `--node` y `--npm`.
No actualizar el lockfile ni instalar una versión diferente para salvar errores.

## Verificación portable

```text
python -B tools/distribution/verify_update.py --godot RUTA_GODOT --node RUTA_NODE
```

Ejecuta importación, pruebas del restaurador, dos sondas Node y 17 grupos Godot:
núcleo, HUD, diagnóstico, APIs/puente/restauración, combate nativo, selección y
conexiones de objetos, soporte/encuentros y guardado. Configura
`POKEMON_CALVO_NODE` para los procesos hijos. Guarda cada ejecución por separado.
En Linux ejecutar un único gate a la vez; la guarda histórica compartida solo
funciona en Windows y no se cambia para esta entrega.

Añadir `--gpu` cuando haya pantalla y OpenGL: incluye la prueba existente de
mochila real con captura. Las pruebas visuales y los recorridos manuales pendientes
deben constar como pendientes en entornos que no puedan ejecutarlos.
Un exit 0 sin comprobaciones no se acepta como prueba funcional. Una importación
limpia es preparación, no una comprobación de mecánicas.

Para abrir la demo desde otro equipo, definir `POKEMON_CALVO_NODE` con la ruta
absoluta de Node y abrir `project.godot` con Godot 4.7. Los lanzadores `.cmd` y
wrappers de fases históricas pueden conservar rutas del equipo original.

La fórmula de captura sigue siendo `calvo_capture_v1`, los efectos de encuentro
solo certifican la tasa y varias familias de objetos dependen de sistemas aún
ausentes. Ningún PASS de este gate convierte esos pendientes en implementados.
