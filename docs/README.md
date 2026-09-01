# Índice de documentación

La documentación está organizada por **función**, no por orden cronológico. El objetivo es que una persona o una IA pueda recuperar el estado actual leyendo pocos archivos y acudir al historial solo cuando necesite trazabilidad.

## 1. Estado vivo — `current/`

Leer primero:

- [`current/START_HERE.md`](current/START_HERE.md) — recorrido de recuperación y orden de autoridad.
- [`current/PROJECT_STATE.md`](current/PROJECT_STATE.md) — baseline certificado y estado técnico actual.
- [`current/NEXT_STEPS.md`](current/NEXT_STEPS.md) — siguiente trabajo exacto.
- [`current/WORK_PROTOCOL.md`](current/WORK_PROTOCOL.md) — reglas de trabajo y certificación.

Estos documentos son los únicos que deben presentarse como **estado operativo actual**.

## 2. Cuadernos temáticos — `project_book/`

Los cuadernos son memoria de trabajo consolidada. No se crea un archivo nuevo por cada microfase.

- [`project_book/README.md`](project_book/README.md) — política de uso.
- [`project_book/DATA_V3.md`](project_book/DATA_V3.md) — DATA V3 cerrado y certificado.
- [`project_book/TRAINER_AI.md`](project_book/TRAINER_AI.md) — estado y continuidad de IA de entrenadores.

Cuando un workstream termine, su cuaderno puede quedar como referencia cerrada; sus diarios detallados pasan a `history/worklogs/`.

## 3. Arquitectura vigente — `architecture/`

Aquí vive la documentación formal del sistema: arquitectura general, Battle Core, progresión, captura, party, persistencia, almacenamiento, reglas y contrato DATA V3.

Los documentos de esta carpeta explican **cómo funciona el sistema**. Los cuadernos explican **qué se decidió, qué está cerrado y dónde continuar**.

## 4. ADR — `adr/`

Los ADR 001–033 documentan decisiones arquitectónicas y límites importantes. No son un historial operativo y no deben sustituirse por resúmenes cuando se necesita conocer la decisión original.

## 5. Referencia — `reference/`

- entorno de desarrollo;
- procedencia/código de terceros.

## 6. Historial — `history/`

Material preservado que ya no representa estado vivo:

- `phase_reports/` — informes finales de fases;
- `legacy_data/` — pipelines y auditorías DATA anteriores a V3;
- `research/` — investigación técnica cerrada;
- `worklogs/` — antiguos cuadernos/diarios de ejecución, incluidos los diarios completos de DATA V3;
- `STATUS_PHASE_HISTORY.md` — antiguo estado acumulativo.

## Orden de autoridad

En caso de contradicción:

1. estado real de GitHub sobre el SHA exacto: commit, PR, CI y artefactos;
2. fuentes inmutables/canónicas del dominio;
3. `current/`;
4. arquitectura/ADR vigentes;
5. cuadernos temáticos;
6. historial;
7. memoria de conversación.

`main` no es actualmente el baseline certificado y no debe asumirse como autoridad hasta que se sustituya explícitamente en una operación posterior.
