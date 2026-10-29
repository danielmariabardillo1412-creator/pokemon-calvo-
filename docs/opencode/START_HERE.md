# OpenCode — piloto O001 de objetos

Autorización humana del 2026-10-29: delegar bloques de objetos a OpenCode con
planos y revisión de Codex, como en la reorganización. No se delega el proyecto
entero. No hay ejecución concurrente ni trabajo T007 de arquitectura.

Trabajar exclusivamente en `D:/Proyectos/Pokemon Calvo - Arquitectura Kilo`.
La copia ya organizada es la activa. Se conserva el checkpoint V9
`815967d7139006715b0d2c1f543383e320189fac`; no se hace otra copia masiva.
El commit de este encargo añade instrucciones y protección, no nuevos efectos.

Orden de lectura:

1. `AGENTS.md` y `docs/current/START_HERE.md`.
2. `docs/opencode/O001_ABILITY_ITEMS.md`, contrato autorizado completo.
3. `docs/opencode/TASKS.json` y `docs/opencode/PROGRESS.md`.

Solo un escritor. Mientras OpenCode implemente O001, Codex no modifica los
mismos archivos. Codex revisa después el diff, los casos y los logs reales.
No es suficiente que el ejecutor se declare correcto.

Comprobar antes de cambiar código:

```text
python tools/verification/opencode_items_guard.py
```

El manifiesto ya está preparado por Codex. OpenCode no debe ejecutar
`--prepare`, borrar manifiestos, resellar hashes ni modificar el guard o este
contrato. Un guard PASS solo acredita alcance/integridad, no la mecánica.

Al acabar, estado `READY_FOR_REVIEW`. No commit, merge, publicación, cambios de
rama ni `ACCEPTED_BY_CODEX`. No continuar con otros objetos. Si algo no se puede
resolver dentro del contrato, dejar evidencia y detenerse con una explicación
concreta; no inventar valores, ampliar la allowlist ni bajar las comprobaciones.
