# CUADERNO 26 — ORGANIZACIÓN DEL CONOCIMIENTO DEL PROYECTO

## Estado

EN CURSO / CHECKPOINT PREVIO A CAMBIOS DOCUMENTALES.

## Baseline de partida

- Repositorio: `danielmariabardillo1412-creator/pokemon-calvo-`.
- Baseline certificado: `b4f6adc200bef18f8ac51b9144f2f9a838f464fd`.
- PR #95 `DATA V3 — final end-to-end certification`: cerrado sin merge.
- DATA V3: cerrado; no se reabre en este bloque.
- Rama de trabajo: `chore/docs-knowledge-organization-v1`.

## Motivo

Antes de volver a Trainer AI / FASE 34 se realiza una reorganización documental. El repositorio conserva documentación técnicamente valiosa, pero varias capas cumplen funciones distintas y algunas fuentes de “estado actual” han quedado desincronizadas.

Problemas confirmados en el baseline:

1. `README.md` y `docs/STATUS.md` todavía presentan `feature/data-foundation-v3` / `304035e2...` como baseline actual, aunque el baseline real ya es el cierre #95 `b4f6adc2...`.
2. `docs/notebooks/01_PROJECT_STATE.md` y `04_NEXT_STEPS.md` todavía describen #95 como pendiente de la segunda certificación, aunque #95 ya está cerrado y certificado.
3. `docs/ARCHITECTURE.md` mezcla arquitectura todavía válida con referencias y cifras históricas (DATA V1, antiguos totales de tests y rutas superadas) sin distinguir claramente qué parte sigue vigente.
4. `docs/notebooks/` mezcla memoria operativa viva con veinte cuadernos cerrados de DATA V3.
5. `docs/` contiene índices, contratos, arquitectura, estado, ADR, histórico y memoria operativa con fronteras poco visibles para una persona nueva.

## Inventario conceptual

### Debe permanecer separado

- `docs/adr/`: Architecture Decision Records formales. Son decisiones, no apuntes de trabajo.
- `docs/history/`: material cerrado/histórico, informes de fases, DATA V1/V2 y material superado.
- contratos técnicos vigentes (`BATTLE_*`, `PROGRESSION_*`, etc.): documentación de sistema, no memoria de conversación.

### Debe unificarse conceptualmente

Cuadernos y apuntes técnicos de trabajo deben tener una única entrada y una jerarquía clara. No deben competir con `STATUS.md` ni con los ADR como fuente de verdad.

## Diseño objetivo provisional

La organización final debe cumplir estas propiedades:

1. Un único punto de entrada documental (`docs/README.md`).
2. Una única fuente breve de estado actual; no varios documentos que compitan entre sí.
3. Una única zona de memoria/apuntes operativos, con separación entre:
   - estado vivo y protocolo;
   - tramos cerrados / cuadernos de auditoría;
   - investigación o notas técnicas de apoyo cuando proceda.
4. ADR formales separados de notas.
5. Histórico claramente marcado como no vigente.
6. Ninguna eliminación de evidencia técnica útil; material superado se archiva, no se destruye.
7. Ningún cambio de producción, DATA, reglas Pokémon, tests o workflows salvo rutas documentales estrictamente necesarias.
8. Evitar renombrados masivos sin beneficio: la estructura debe ser más fácil de entender y mantener, no solo distinta.

## Política de idioma

Este bloque no traduce masivamente código ni documentación histórica. La prioridad es estructura, autoridad y legibilidad. El español visible del juego se tratará más adelante como capa de presentación/localización separada.

## Política de autoridad después de la limpieza

Orden previsto:

1. GitHub/CI/artefactos certificados y fuentes inmutables.
2. Estado operativo vivo del proyecto.
3. Contratos técnicos y ADR vigentes.
4. Cuadernos/apuntes de trabajo.
5. Histórico.

Un documento histórico nunca podrá presentarse como baseline actual.

## Protocolo de ejecución

1. Inventariar `docs/`, `docs/notebooks/`, `docs/history/`, ADR e índices.
2. Identificar duplicados, referencias obsoletas y fuentes de estado contradictorias.
3. Fijar mapa exacto de conservación/movimiento/archivo.
4. Reorganizar únicamente documentación.
5. Actualizar índices y enlaces afectados.
6. Verificar que el diff contra `b4f6adc2...` es documental.
7. Ejecutar los 18 workflows sobre el HEAD de ingeniería.
8. Registrar resultado en este cuaderno y sincronizar el estado vivo.
9. Verificar que el cierre final solo añade documentación.
10. Segundo 18/18 sobre el HEAD documental final.
11. Cerrar el PR sin merge.
12. Usar su SHA final como padre de FASE 34 Trainer AI.

## Regla obligatoria de continuidad

Todo hallazgo material, excepción, decisión, fallo o cambio de plan de esta reorganización debe quedar registrado aquí o en el documento operativo correspondiente. El chat nunca será la única memoria del trabajo.
