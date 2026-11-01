> **Estado histórico rectificado, 2026-11-01:** este documento se redactó como propuesta. **CAMPAÑA_001 sí está ACTIVADA** por la puerta `CAMPAIGN_GATE_001.md`. Los límites actuales, el cierre por familia y el control CI de IA6 se definen en [CI_AND_HANDOFF_PROTOCOL_V2.md](CI_AND_HANDOFF_PROTOCOL_V2.md). La sección final «NO ACTIVA» describe únicamente el período anterior y no invalida la activación posterior.

# Protocolo de ejecución delegada por familia — IA1–IA5 (propuesta, NO activa aún)

**Fecha:** 2026-11-01. **Motivo:** 744 tipos de diseño, cinco ramas y contextos limitados; el árbitro no debe leer íntegramente cada archivo en cada lote. Se requiere continuar con `sigue` de forma segura y auditable.

## Lo que sí y lo que no significa «autónoma»

- El usuario debe activar manualmente cada conversación (mensaje `sigue`). Ningún chat despierta automáticamente ni monitoriza otros chats en segundo plano.
- Las instrucciones de **CAMPAÑA_NNN_W0X.md** publicadas por IA6 definen un **sobre de trabajo delegado**: familia, rango de IDs, propietarios únicos de archivos, tipos de cambios permitidos, pruebas obligatorias y **límite de iteraciones**. No equivale a permiso ilimitado para programar el juego.
- Durante esa campaña, cada vez que reciba `sigue`, la W puede seleccionar el siguiente microbloque **dentro de su sobre** desde el inventario propio y ejecutarlo sin esperar una asignación individual por cada 1–3 objetos.
- La trabajadora comprueba al comienzo que no hay bloqueos ni nueva orden superior; no se salta puertas de integración por tener más IDs pendientes.
- No habilitar producción por este documento. La primera campaña de implementación requiere: **CI válida del checkpoint combinado, contratos compartidos explícitos y rutas de escritura desconflictadas**.

## Jerarquía y recuperación de contexto

1. **Órdenes oficiales de IA6 en su rama**: `STATUS.md`, campaña vigente `campaigns/CAMP_NNN_W0X.md`, correcciones urgentes y política del juego.
2. **Estado por trabajadora en SU rama**: `reports/W0X/CONTINUIDAD.md`, `reports/W0X/PROGRESO_CAMP_NNN.csv` y último `reports/W0X/ITER_NNN.md`. Esto es historial técnico, no autoridad para cambiar tareas.
3. **Código y pruebas comprobables**: commit exacto, archivos, SHA del CI y resultado por escenario. PASS de tests no equivale a calidad visual ni cobertura total.
4. No confiar en memoria del chat; leer sólo asignación vigente, cuaderno y **último** informe, más archivos de la familia necesarios; no recargar 260 informes anteriores.

## Unidad de trabajo: microbloque

Cada `sigue` procesa **un microbloque coherente** (un grupo de IDs que comparte contrato/fixture o una tarea técnica común). No limitar artificialmente a 3 IDs: las máquinas se pueden revisar como 248 filas con un solo validador. No multiplicar scripts ni callbacks individuales; preferir reglas declarativas sobre infraestructura existente.

Obligatorio para cada microbloque:
- Registrar IDs exactos, estado anterior y estado nuevo **sin confundir catálogo, prueba documental y efecto en partida**.
- Revisar si existe en V27/V28, reutilizar fuente normativa, evitar implementar dos veces.
- Generar mínimo test positivo, negativo, consumo/propiedad/guardado cuando aplique; separar unidad, integración y visual/GPU.
- Escribir solo en archivos propios autorizados por campaña; nunca alterar módulos compartidos sin propietario exclusivo.
- Publicar commit, resultado de CI por SHA (o `SIN_EJECUTAR`), informe breve `ITER_NNN.md` y actualizar `CONTINUIDAD.md` / `PROGRESO`. No copiar logs enteros en Markdown: enlazar run y dejar métricas.
- Si el test no se ejecutó, estado `PREPARADO_NO_VERIFICADO`, **no** `COMPLETADO`.

## Puertas automáticas para ahorrar árbitra y GitHub Actions

- **Por microbloque**: verificador de permisos (rutas/IDs), sintaxis, esquema, tests unitarios locales y evidencia con hashes. No disparar CI completa por cada documento.
- **Por paquete integrado**: una CI de Godot 4.7 sobre el SHA combinado de 2–5 microbloques (o al tocar un contrato compartido), con import, regresiones pertinentes y artefacto de fallos. Un único workflow puede verificar todas las familias.
- **IA6 revisa POR EXCEPCIÓN**: cambios fuera de rutas, diffs en producción compartida, CI roja, políticas ambiguas, guardados, migraciones, modificación de simulador, rendimientos y pruebas visuales. Cada ronda lee **manifiestos compactos**, no cinco fuentes enteras.
- **Revisión de muestreo**: IA6 inspecciona en profundidad un caso representativo por familia/paquete y cualquier código de riesgo; la CI no sustituye examen de diseño o corrección de contratos.
- **Cierre de campaña**: reconciliar recuentos por ID, evidencia SHA y cuadernos con la cola central; auditoría final antes de nuevo conjunto de permisos. No modificar `main` sin autorización del usuario.

## Stop conditions (obligatorias)

Detener ese microbloque y reportar `BLOQUEADO` si:
- Checkpoint incompleto/no verificable, necesidad de rebase/force, mezcla de ramas no autorizada.
- Fallo de CI no explicado, error de Godot, contrato incompatible, fixture que habría que falsificar.
- Necesidad de modificar producción compartida sin dueño exclusivo, nueva dependencia externa, migración de partidas o cambios de lógica global.
- Falta una decisión de diseño (por ejemplo política de 19 máquinas heredadas, beast_ball, objetos regionales, datos hora/cueva/amistad). No inventarla.
- Se agota el rango de campaña, hay cambios relevantes en la autoridad o falta la siguiente asignación válida.

## Activación futura

**NO ACTIVA** mientras el CI consolidado sobre `LOTE_002` no sea verificado y IA6 no publique una campaña individual para cada W con límites y directorios exactos. Hasta entonces las trabajadoras siguen `LISTA_PARA_REVISION`: un `sigue` sin tarea publicada **no autoriza** nuevas escrituras.

Cuando se active, el usuario sólo necesitará enviar un **prompt de modo delegación una vez** y luego `sigue` a cada W; IA6 recibirá un resumen de avances cada cierto número de microbloques, no revisará uno por uno todos los objetos.
