# Entorno de desarrollo: GitHub y recursos locales

## Contenido versionado en GitHub

El repositorio contiene el núcleo reproducible necesario para continuar el desarrollo:

- código de dominio y módulos (`core/`, `modules/`);
- datos y manifiestos requeridos por el runtime y los tests (`data/`);
- suite de tests (`tests/`);
- herramientas de importación y generación (`tools/`);
- documentación de arquitectura y contratos (`docs/`);
- configuración de Godot (`project.godot`) y documentación inicial (`README.md`).

La suite completa se ejecuta en Godot 4.7 con:

```powershell
godot --headless --path . --script tests/test_runner.gd
```

El runner y los datos versionados son autosuficientes: no dependen de las bibliotecas gráficas locales.

## Contenido exclusivamente local

Las siguientes bibliotecas y proyectos de referencia viven fuera del worktree de Git:

- `POKEMON_DATA_LIBRARY/`;
- `POKEMON_REFERENCIAS/`;
- `Project-Uranium-Godot-v4/`;
- `Project-Uranium-Godot-master/`.

Incluyen imágenes, referencias gráficas, assets brutos y material pesado que no forma parte del núcleo construible y testeable. Los caches de Godot y archivos transitorios también permanecen fuera del control de versiones mediante `.gitignore`.

Estos recursos locales podrán conectarse posteriormente mediante Codes/OpenCode durante la integración visual. No deben copiarse, importarse en bloque ni añadirse a Git; cualquier asset que el runtime llegue a necesitar deberá seleccionarse o generarse de forma mínima y revisarse por tamaño y licencia antes de versionarlo.
