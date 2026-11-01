# Cuadernos persistentes de trabajo — protocolo común W01–W05 (1-XI-2026)

**Propósito:** permitir relevo de conversación sin cargar miles de mensajes, sin repetir implementaciones, sin alterar autoridad de asignación. Este protocolo complementa `START_HERE.md`, `WORKER.md`, `COORDINATOR.md` y los encargos.

## Dos niveles: órdenes oficiales y memoria técnica local

1. **IA6/ÁRBITRA, fuente de órdenes:** `assignments/LOTE_NNN_W0X.md`, `QUEUE_V1.csv`, `STATUS.md`. Solo la árbitra asigna IDs, permisos de escritura, fases y bases SHA. Un cuaderno local **jamás** autoriza trabajo distinto.
2. **W0X, memoria operativa en su rama exclusiva:** `docs/coordination/items_parallel_v1/reports/W0X/CONTINUIDAD.md`. La trabajadora lo crea y actualiza en su **propia rama** al cerrar cada lote y antes de dejar una conversación.
3. **Informes de lote inmutables después de aceptación:** `reports/W0X/LOTE_NNN.md`; contienen evidencias específicas y sirven para revisar el cuaderno mutable. Si un informe necesita corrección, documentarla con nuevo commit y dejar trazabilidad, no reescribir la historia como si nunca hubiera existido.
4. **Índice de equipo de la árbitra:** `NOTEBOOK_INDEX_V1.md` contiene accesos a los cinco cuadernos por rama; la árbitra lo revisa cuando hay entregas. No copiar a su rama los cuadernos enteros.
5. **Plantilla:** `NOTEBOOK_TEMPLATE_V1.md` en rama árbitra. Personalizar exclusivamente W0X y su familia; mantener el cuaderno breve y enlazar reportes/diffs/tests.

## Datos obligatorios en CONTINUIDAD.md

- Identidad W0X, rama exclusiva, familia, lote actual y **SHA de la asignación oficial leída**.
- Estado real: `SIN_ENCARGO`, `ASIGNADO`, `EN_CURSO`, `LISTA_PARA_REVISION`, `BLOQUEADO`, `INTEGRADO` (solo tras confirmación de la árbitra). No declarar integración por terminar informe.
- **Qué existía previamente:** módulos, hooks, datos y pruebas reutilizables con rama/SHA. Distinguir hallazgo estático, PASS histórico y prueba ejecutada sobre commit actual.
- **Qué se hizo de verdad:** IDs, subsistemas, archivos cambiados, commits, decisiones y justificación de reutilización; qué NO se tocó.
- **Cómo funciona:** ruta de flujo `catálogo → mochila/equipamiento → simulador/acción → persistencia → UI` según aplique; puntos de extensión exactos y propiedad de archivos. Preferir contratos comunes por familia; no copiar código por ID.
- **Cómo se verificó:** comandos reales, versión de Godot/Node, escenarios positivos/negativos, prueba en CI o local, RUN/commit, límites visuales/GPU; `SIN_EJECUTAR` cuando corresponda.
- **Qué falta y por qué:** dependencias, bloqueos externos, riesgos, deuda técnica y orden de continuación concreto. IDs sin cobertura no equivalen a errores funcionales.
- **Qué NO debe hacer el siguiente chat:** prohibiciones permanentes (main, V28, ramas ajenas, cambios de políticas y guardados sin orden), decisiones cerradas y archivos reservados.

## Ciclo de actualización

- Al recibir un lote: **leer primero** asignación vigente de IA6 y luego `CONTINUIDAD.md` de la **propia rama**; si difieren, seguir a IA6 y registrar discrepancia. No crear trabajo por un `sigue` si no hay lote publicado.
- Durante el lote: dejar información técnica comprobable en su informe de lote; no confiar en memoria conversacional.
- Al entregar: completar informe, actualizar cuaderno en la propia rama y publicar commit; comunicar URL del informe, URL del cuaderno y SHA.
- Antes de cambiar de chat: verificar que el cuaderno refleja el último commit y un siguiente paso reproducible. No exigir releer historiales antiguos.
- La árbitra comprueba ambos documentos, el diff y la evidencia, integra secuencialmente, registra aceptación en su rama y publica nueva asignación.
- Nunca sincronizar cuadernos mediante sobrescritura entre ramas ni adjudicarse a sí misma nuevos IDs. No usar el cuaderno como sustituto de tests.

## Compatibilidad con LOTE_001 ya iniciado

`LOTE_001` era **solo auditoría** y autorizaba escribir exclusivamente el informe `reports/W0X/LOTE_001.md`. **No cambiar ese contrato retroactivamente ni exigir rehacer informes ya terminados.** El informe LOTE_001 sirve de primera memoria de lo investigado. A partir de `LOTE_002`, IA6 incluirá explícitamente en cada asignación la autorización para crear/actualizar `CONTINUIDAD.md` además del informe. Las trabajadoras pueden leer el protocolo ahora; **no editar producción ni agregar archivos fuera de LOTE_001 mientras está activo**.

## Control de calidad

La árbitra no acepta un lote de implementación como cerrado sin: informe por ID, cuaderno actualizado, hashes rastreables, diff autorizado y evidencia funcional del alcance; `NO_PROBADO` siempre visible si faltan tests. No se requieren 20 workflows por cada cambio documental.
