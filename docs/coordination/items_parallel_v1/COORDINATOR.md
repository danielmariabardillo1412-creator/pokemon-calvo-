# PROTOCOLO ÁRBITRA / COORDINADORA — única dueña de asignaciones e integración

**Rama exclusiva:** `codex/calvo-items-20261101-arbitro`. **Roles paralelos:** W01-W05 con ramas propias, detalladas en START_HERE. La árbitra NO es un servicio autónomo: **solo revisa y actúa cuando el usuario abra su conversación y se lo pida**. No puede enviar mensajes a las otras cinco conversaciones automáticamente.

## Orden de arranque en el primer turno

1. Leer `START_HERE.md`, `QUEUE_V1.csv`, `docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv`, `AGENTS.md`, `docs/current/ITEM_SYSTEM_CURRENT_STATUS.json`, `docs/current/RANDOMLOCK_MEGA_UNIVERSAL_SPEC_V1.md`.
2. Confirmar que la rama árbitra y las cinco W existen. No derivar de `main`; comparar los seis puntos de partida y confirmar la misma línea base del cuaderno. Si faltan ramas, avisar. **NO crear nuevos cambios en main ni V28.**
3. Antes de entregar IDs, auditar `ITEM_SYSTEM_CURRENT_STATUS.json`, reportes V27, estado real de rama y pruebas disponibles. Clasificar cada ID que se vaya a asignar: `YA_HECHO_VERIFICADO`, `HECHO_PERO_PRUEBA_PENDIENTE`, `PENDIENTE_IMPLEMENTAR`, `BLOQUEADO_DEPENDENCIA` o `REVISAR_SELECCION`. Fuente + versión/commit obligatorios.
4. Elegir un **lote piloto de 1 a 3 IDs por W** que no toque los mismos archivos centrales. Si el trabajo puede hacerse con un importador por familia, autorizar la familia completa con tests y límites explícitos, no un parche por ID.
5. Crear `assignments/LOTE_001_W01.md` ... `LOTE_001_W05.md` *solo para trabajadoras con tareas no duplicadas*. Usar el esquema de abajo. Actualizar **en tu rama exclusivamente** `QUEUE_V1.csv` (columnas `estado_triaje,id_lote_asignado,estado_evidencia,ultimo_commit_validado`) antes de anunciar asignaciones. Si el lote no puede entregarse, declarar bloqueo y escoger otro o mantener sin asignar.
6. Entregar al usuario un breve texto para reenviar a cada conversación: «W0X, lee el encargo LOTE_NNN_W0X de la rama árbitra, trabaja solo en tu rama y publica informe». No afirmar que las trabajadoras arrancaron ni que están monitorizadas.

## Esquema de encargo obligatorio (un .md por trabajadora y lote)

```md
# LOTE_NNN_W0X
Estado: ASIGNADO (no iniciado hasta que el usuario lo envíe a W0X)
Responsable: W0X
Rama de trabajo: codex/calvo-items-20261101-w0x
Rama/commit base leído: [ref y SHA reales]
IDs canónicos exactos: [hasta 3, o familia con alcance numérico explícito]
Objetivo concreto por ID: [comportamiento esperado]
Prueba previa y evidencia: [ruta/commit, no inventar PASS]
Archivos con escritura exclusiva autorizada: [lista de paths exacta]
Archivos de solo lectura: [lista]
Criterios de aceptación: [positivo, negativo, persistencia, integración]
Comandos de prueba: [solo existentes/confirmados]
Riesgos/dependencias: [incompatibilidades con otras W]
No tocar: main, PR V28, ramas ajenas, datos canónicos, guardados, objetos descartados
Resultado: informe docs/coordination/items_parallel_v1/reports/W0X/LOTE_NNN.md
```

## Semáforo de resultados

- `SIN_ASIGNAR`: aún no entregado.
- `ASIGNADO`: reservado por coordinadora; usuario debe iniciar turno en W.
- `EN_CURSO`: W confirmó que comenzó y su último commit/branch es conocido.
- `EN_REVISION`: W terminó y entregó diff, registros, pruebas.
- `INTEGRADO_VERIFICADO`: árbitra comprobó evidencia real e incorporó en su rama mediante PR/merge revisado.
- `INTEGRADO_NO_VERIFICADO`: no debe usarse para afirmar PASS; solo para documentación explícitamente no ejecutada, preferir `BLOQUEADO_VERIFICACION`.
- `YA_HECHO_VERIFICADO`: código existente y prueba actual comprobada, no asignar programación redundante.
- `BLOQUEADO`: dependencia o error concreto registrado, liberar recursos si cambia asignación.
- `RECHAZADO`: cambios fuera de alcance, regresión o prueba que falla; no fusionar.

## Integrar sin pisar a las demás

1. Leer reporte de W0X, confirmar rama/commit y comparar diff contra la **rama de árbitra**, no contra main. Verificar que solo tocó IDs/ficheros autorizados. Revisar impacto en motor, funciones comunes, consumo y guardados.
2. Obtener evidencia real: pruebas automáticas, Godot 4.7 o GitHub Actions **si existe workflow válido**. Documentar comando, fecha, hash y resultado. Si algo no se pudo ejecutar, identificarlo y no marcarlo como PASS.
3. Revisar prohibiciones: nada de desconectar `poke_doll`, `poke_toy` o efectos de captura preexistentes por estar fuera del futuro generador; nada de crear 92 piedras Mega ni revivires, ni quitar objetos de evolución por intercambio.
4. Integrar **una rama a la vez** en `codex/calvo-items-20261101-arbitro`. Si hay conflictos, resolver con el estado actual más nuevo y reejecutar las pruebas. Nunca «merge todos» sin revisión. No hacer merge a main ni a PR V28.
5. Actualizar cola por ID y reporte de recepción/aceptación dentro de `integration/LOTE_NNN_W0X.md`: commit validado, PR o compare, archivos cambiados, comandos y salida, defectos abiertos, nuevo estado y próxima tarea.
6. Anunciar la siguiente asignación **solo después** de integrar o liberar formalmente la anterior. Evitar doble reserva de IDs y archivos compartidos.

## Plan por familias y equilibrio

- W01 equipables (186): efectos nativos con casos de batalla; centrarse en contratos comunes de hooks y escenarios de activación; no confundir entrada nativa con PASS.
- W02 medicinas, bayas y entrenamiento (148): sistema de campo, consumibles/EV/PP, mochila, guardado y UI; no tocar protocolos de captura que son W03.
- W03 captura, campo, Z y Tera (89): priorizar capturas realmente pendientes y efectos de campo nuevos; acciones Z solo de daño, nunca estado.
- W04 evoluciones y formas (72): conservar requisitos originales de objeto, cambios de forma; no fijar niveles de intercambio aplazados ni desarrollar Mega ahora.
- W05 libros (248): muchas MT ya están verificadas. Identificar **qué falta de verdad** por libro; preferir un generador común, comprobar mapa de movimientos y compatibilidad con especies. No duplicar MO históricas descartadas.

**Advertencia:** estos son dominios orientativos; las escrituras simultáneas en el mismo archivo compartido están prohibidas sin propiedad exclusiva asignada. Si dos subsistemas usan `AdventureSession` o `NativeEngine`, solo una W modifica ese archivo por tanda y la otra trabaja en pruebas/documentación o espera asignación.

## Criterios de entrega a usuario

Al responder, informar: `IDs triados`, `IDs ya verificados`, `IDs implementados`, `IDs pendientes`, `pruebas PASS/FAIL/SIN EJECUTAR`, `commits`, `próximas asignaciones` y `bloqueos`. Si no hay pruebas reales, decirlo; nunca utilizar recuentos del CSV como certificados de funcionamiento.

## Fase Mega futura — NO encargar ahora

Regla cerrada: DOS piedras físicas del MISMO tipo universal por jugador/partida, DOS megaevoluciones por entrenador en el mismo combate, sin reasignar portador o forma hasta terminar. Distintas parejas entre combates. Se encuentra en `docs/current/RANDOMLOCK_MEGA_UNIVERSAL_SPEC_V1.md`. No reabrir ni cambiar a una sola activación.

## Complemento 2026-11-01 — base divergente / primera ronda sin código

**Antes de implementar**: consultar `BASELINE_GATE_2026-11-01.md`. La V28 PR #118 añade lógica de progresión, automatización y tests que NO están en la rama de catálogo de la que nacieron W01-W05; no repetirlos ni empezar a programar sobre el checkout antiguo como si fueran inexistentes. Los cinco lotes `LOTE_001_W0X.md` son **auditoría documentada**, no permiso de cambiar producción. Una auditoría de familia (W05: máquinas) puede superar tres IDs cuando comparte analizador; el límite 1-3 del piloto se aplica a *implementaciones riesgosas*, no a leer tablas. La árbitra resolverá el checkpoint de integración antes del LOTE_002.

**Discrepancia a conciliar**: `beast_ball` figura seleccionado en el catálogo, pero V28 documenta veto a la captura especial de Ultraentes. No reactivar ni borrar nada ahora; marcar conflicto para decisión consciente. No confundir las 27 verificaciones V28 con los 744 tipos de contenido ni 229 MT V27 con 248 máquinas seleccionadas.

## Garantizar continuidad entre ventanas desde LOTE_002

Protocolo vinculante: [NOTEBOOK_PROTOCOL_V1.md](NOTEBOOK_PROTOCOL_V1.md); plantilla: [NOTEBOOK_TEMPLATE_V1.md](NOTEBOOK_TEMPLATE_V1.md); enlaces: [NOTEBOOK_INDEX_V1.md](NOTEBOOK_INDEX_V1.md).

En TODA nueva asignación de LOTE_002 en adelante, autorizar explícitamente la escritura del informe de lote y de `reports/W0X/CONTINUIDAD.md` **solo en su rama**. Exigir al cierre: ID→evidencia por SHA, mapa técnico, rutas reutilizables, pruebas no ejecutadas, decisiones, pendientes y siguiente comando/paso. No aceptar un lote como documentado para relevo sin cuaderno actualizado; no reescribir los cuadernos de las otras ramas desde árbitra. Mantener el índice y comprobar divergencias entre cuaderno local y cola central. No bloquear ni retroeditar el primer lote de auditoría por este cambio; sus informes ya son documentos de relevo. La árbitra conserva un estado sintético central, no un duplicado completo del conocimiento de las cinco.
