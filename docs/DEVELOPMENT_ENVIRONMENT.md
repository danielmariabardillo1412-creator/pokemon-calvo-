# Entorno de desarrollo: GitHub y recursos locales

## Contenido versionado en GitHub

El repositorio contiene el núcleo reproducible necesario para continuar el desarrollo:

- código de dominio y módulos (`core/`, `modules/`);
- datos y manifiestos requeridos por el runtime y los tests (`data/`);
- suite de tests (`tests/`);
- herramientas de importación y generación (`tools/`);
- fixtures CI pequeñas y versionadas (`ci/fixtures/`);
- documentación de arquitectura y contratos (`docs/`);
- configuración de Godot (`project.godot`) y documentación inicial (`README.md`).

La suite completa se ejecuta en Godot 4.7 con:

```powershell
godot --headless --path . --script tests/test_runner.gd
```

El runner y los datos versionados son autosuficientes: no dependen de las bibliotecas gráficas locales.

## GitHub Actions

El workflow `.github/workflows/godot-tests.yml` valida automáticamente los pull requests con Godot `4.7.stable.official.5b4e0cb0f` en modo headless.

Antes de ejecutar la suite, CI copia tres snapshots de referencia desde `ci/fixtures/pokeapi_reports/` a `data/reports/`, porque `data/reports/` contiene artefactos regenerables que deliberadamente no se versionan. Después importa el proyecto y ejecuta `tests/test_runner.gd`.

Baseline remoto validado: **470 PASS / 0 FAIL**. El gate exige cero fallos y al menos 470 checks en verde, de modo que futuras fases pueden añadir tests sin editar el workflow cada vez, pero una reducción accidental por debajo del baseline sí bloquea CI.

El test negativo de JSON corrupto emite deliberadamente un diagnóstico de parseo mientras verifica que la carga inválida sea rechazada; ese mensaje esperado no representa una regresión.

Para evitar ejecutar la misma suite dos veces por commit, los feature branches se validan mediante `pull_request`; el trigger `push` queda reservado a `main`. También existe `workflow_dispatch` para ejecuciones manuales.

## Contenido exclusivamente local

Las siguientes bibliotecas y proyectos de referencia viven fuera del worktree de Git:

- `POKEMON_DATA_LIBRARY/`;
- `POKEMON_REFERENCIAS/`;
- `Project-Uranium-Godot-v4/`;
- `Project-Uranium-Godot-master/`.

Incluyen imágenes, referencias gráficas, assets brutos y material pesado que no forma parte del núcleo construible y testeable. Los caches de Godot y archivos transitorios también permanecen fuera del control de versiones mediante `.gitignore`.

Estos recursos locales podrán conectarse posteriormente mediante Codes/OpenCode durante la integración visual. No deben copiarse, importarse en bloque ni añadirse a Git; cualquier asset que el runtime llegue a necesitar deberá seleccionarse o generarse de forma mínima y revisarse por tamaño y licencia antes de versionarlo.
