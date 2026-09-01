# CUADERNOS DEL PROYECTO

Esta carpeta contiene **memoria temática consolidada**, no diarios cronológicos.

## Regla principal

No crear un cuaderno por cada PR, microfase o sesión.

Un cuaderno existe mientras un tema necesite memoria operativa propia. Se actualiza a medida que el workstream avanza y, cuando cierra, queda como resumen de autoridad humana. Los diarios detallados que justifican ese resumen se conservan bajo `../history/worklogs/`.

## Cuadernos actuales

### `DATA_V3.md`

Estado: **CERRADO**.

Resume la fuente, contrato estructural, fronteras runtime, certificación final y condiciones que justificarían reabrir DATA V3.

Los antiguos diarios 02 y 06–25 se conservan en `../history/worklogs/data_v3/`.

### `TRAINER_AI.md`

Estado: **ACTIVO / siguiente workstream técnico**.

Resume la línea FASE19–33, invariantes anti-cheat, arquitectura útil y el punto exacto desde el que debe diseñarse la siguiente fase.

La investigación original de FASE21 permanece en `../history/research/TRAINER_AI_RESEARCH_FASE21.md` como fuente histórica.

## Cuándo crear otro cuaderno

Solo cuando empiece un workstream suficientemente grande y distinto como para que meterlo en otro cuaderno cree confusión.

No se crean por anticipación cuadernos vacíos de Battle, Overworld, UI, etc. Si esos temas vuelven a ser trabajo activo y necesitan memoria propia, se abrirán entonces.

## Diferencia con otras carpetas

- `../current/`: dónde estamos y qué toca ahora.
- `../architecture/`: cómo está construido el sistema.
- `../adr/`: por qué se tomó una decisión arquitectónica concreta.
- `../history/`: evidencia y diarios de trabajo que ya no son estado vivo.

GitHub/CI/artefactos del SHA exacto siguen teniendo prioridad sobre cualquier cuaderno.
