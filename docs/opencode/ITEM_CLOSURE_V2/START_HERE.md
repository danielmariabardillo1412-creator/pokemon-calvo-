# OpenCode — cierre de objetos, misión V2

Autorización humana nueva: ejecutar varios lotes completos de objetos y devolver
un informe conjunto. **No detenerse después de cada objeto ni esperar revisión
de Codex entre las familias expresamente autorizadas.** Las revisiones internas
siguen siendo obligatorias. Los planos O001/O002 anteriores son históricos;
Cápsula y Parche están terminados, no deben repetirse.

Trabajar exclusivamente en `D:/Proyectos/Pokemon Calvo - Arquitectura Kilo`, rama
`codex/kilo-architecture-v1`. No crear otro juego, copia masiva o worktree.
Base funcional cerrada: `da00bd4c36f578606a45edcebc6ebd9a6ba630e8` (V21).
El commit posterior de estos planos no modifica mecánicas. El guard encuentra
su ancla con el último commit de CONTRACT.json; no necesita editar este archivo.

Leer en este orden:

1. `AGENTS.md`, `docs/current/START_HERE.md`, `docs/current/WORK_PROTOCOL.md`
   y `docs/current/ITEM_SYSTEM_CURRENT_STATUS.json`.
2. `WORK_ORDER.md` y `CONTRACT.json` de esta carpeta.
3. `O110_BATTLE_SUPPORT.md` y `O120_HELD_CONTEXTS.md` al abordar esas familias.
4. `REVIEW_CHECKLIST.md`; mantener STATE.json y PROGRESS.md de esta carpeta.

Primera operación y tras cada familia:

```text
python tools/verification/opencode_items_v2_guard.py
```

El sello ya lo preparó Codex. **No ejecutar --prepare, borrar el sello, ampliar
allowlists o cambiar planos/guard para conseguir un PASS.** Un guard solo verifica
alcance e integridad, no efectos de Pokémon. El guard congela el resto del juego,
datos, arte y paquetes, y restringe incluso las zonas editables de NativeEngine
y field_demo. El contrato manda nombres exactos de archivos autorizados.

La excepción nueva a las restricciones antiguas de AGENTS permite únicamente
los dos puntos descritos de NativeEngine para dirigir usos de mochila a APIs
del simulador fijado y proyectar datos existentes. No autoriza modificar su
motor, callbacks, daño, RNG, dispatch, prepare/commit ni serializador.

Solo un escritor. Desde que OpenCode arranque, Codex no implementará en paralelo
estos archivos. No lanzar otros agentes o ejecutores. Puedes hacer commits
locales tras cerrar una familia con pruebas; no cambiar de rama, publicar,
crear remotos, mergear, resetear, limpiar o reescribir historia. No afirmar
aceptación de Codex. Guarda trabajo y evidencia para poder reanudar tras un corte.

La misión termina tras O190: **todo lo abordable del alcance implementado y
comprobado, con el resto clasificado por dependencia real**. No significa inventar
sistemas de mundo, economía, crianza, formas o persistencia para afirmar que
«todos los objetos están terminados». Tampoco se entrega un simulacro compuesto
solo por metadatos. Informe final único READY_FOR_REVIEW, o PARTIAL_READY_FOR_REVIEW
con los impedimentos y trabajo funcional terminado. La revisión independiente
de Codex se hará después de que el usuario traiga la entrega.
