# PRETRIAJE CAMPAÑA_002 — PROPUESTA NO ACTIVADA (IA6, 2026-11-02)

> **Estado: BORRADOR_SIN_AUTORIZACION.** Documento de análisis, no gate ni encargo. NO enviar `p` por esta propuesta, no crear ramas de trabajo, no implementar ni cambiar pruebas, no asignar una campaña 002. Requiere permiso nuevo de la persona usuaria y comprobación de HEAD/CI antes de activar.

## 0. Punto de partida que no puede perderse
- La CAMPAÑA_001 tiene **14/15 microbloques entregados**: W01/02/03/05 cerradas 03/03, W04 congelada 02/03 **a petición expresa del usuario**, sin sustitución. Ver `CAMPAIGN_GATE_UPDATE_005.md`.
- Árbol funcional más reciente probado en árbitra `a8e09dbf8b15c61f1b18207d34548ff8a7ca46e4`, CI [#41364601482](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41364601482) + [#41364601486](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41364601486), ambos SUCCESS. Commits posteriores de IA6 son **exclusivamente documentación**.
- Cola `QUEUE_V1.csv`: **744 filas de selección** clasificadas inicialmente; 248 MACHINE figuran todavía con estado histórico incompleto, al igual que Net Ball. Priorizar [CAMPAIGN_001_EVIDENCE_OVERLAY_V1.csv](CAMPAIGN_001_EVIDENCE_OVERLAY_V1.csv) para los **267 IDs revisados**. Para restantes 477 IDs, el CSV antiguo da triaje preliminar, no prueba de que algo falte en producción.
- El overlay recoge **229 MT activas** con metadatos/etiquetas comprobadas, de las cuales solo `tm01`, `tm02`, `tm77` también tienen prueba de enseñanza/PP/consumo con especies concretas; 19 históricas están denegadas. No marcar las otras 226 como `TEACH_IMPLEMENTADO_VERIFICADO_POR_ID` ni volver a implementar lo que ya aporta `FieldItemService.teach`.

## 1. Candidatas de trabajo futuras — hipótesis, NO asignaciones

| Ventana | IDs / alcance tentativo | Primera comprobación obligatoria | Riesgo STOP |
|---|---|---|---|
| W01 | `ability_shield`, `absorb_bulb`, `adrenaline_orb` (los tres figuran SELECCIONADO en cola) | Comparar cada efecto equipado con adaptador nativo y tests ya existentes, reutilizar harness W01; identificar si la mecánica está conectada **antes de escribir código** | Hooks de batalla/efectos externos no disponibles, acceso a archivo común no autorizado |
| W02 | `sitrus_berry`, `lum_berry`, `leppa_berry`, `figy_berry` (SELECCIONADO) | Cruzar evidencias LOTE_002, consumos nativos y campo; generar una matriz común con negativos, propiedad y SaveV2 | Falsos duplicados o activación de estado de campo no aprobado |
| W03 | `dusk_ball`, `repeat_ball`, `dive_ball` (SELECCIONADO) **solo investigación del contrato** | Verificar si las sesiones reales suministran ubicación/cueva/oscuridad, especies ya capturadas, o situación submarina; cotejar capturas y referencia fijada antes de proponer implementación | `CaptureBattleContext` actual contiene `completed_turns` y `catcher_level`, pero **no dispone de esos tres contextos explícitos**. Si faltan, documentar `DEPENDENCIA_DE_CONTEXTO`, no inventarlos ni cambiar arquitectura por conjetura |
| W05 | Extensión parametrizada de **pruebas** de las 229 MT activas, comenzando por una muestra estratificada de tipos/especies además de tm01/02/77 | Partir del catálogo y learnsets reales; verificar `FieldItemService.teach` existente con varias especies y PP; no tocar el adaptador de solo lectura si no es necesario | Exceso de combinaciones, guardados, tipos sin especies válidas, UI/diseños sin aprobación |
| W04 | **Ningún encargo** | Mantener sin tocar la rama `codex/calvo-items-20261101-w04`, reportes y 02/03 | El usuario pidió congelarla: no sustituirla ni abrir conversación nueva |

**Clasificación pendiente:** para cada ID candidato exigir uno de `YA_EXISTE_Y_HAY_CI`, `EXISTE_SIN_CI_DE_ESE_CASO`, `FALTA_IMPLEMENTACION`, `BLOQUEO_DE_CONTRATO`, `FUERA_DE_ALCANCE`, indicando el símbolo/fuente y SHA antes de crear `CAMP_002_W0X.md`. Las etiquetas antiguas de la cola NO pueden decidir esto por sí solas.

## 2. Reducir intervención manual y cuota
- **Propuesta de cadencia:** una entrega por familia y una CI consolidada por paquete, no una `p` por objeto ni pipelines constantes. Las tareas seguirían siendo acotadas: parte de auditoría estática + test parametrizado; en hallazgo de cambio funcional autorizado, abrir solo un gate incremental de Godot.
- En una eventual CAMPAÑA_002, asignar **cuatro** trabajadoras existentes W01/W02/W03/W05. W04 permanece congelada. Cada una trabaja exclusivamente en sus rutas autorizadas **por una campaña nueva**, que deberá escribir IA6 de forma expresa; las rutas de CAMP_001 no se transfieren automáticamente.
- Poner umbrales de tiempo en GitHub Actions, `concurrency.cancel-in-progress`, evidencia hash + exit code + logs, Godot 4.7 y simulador nativo solo para familias que lo necesiten. Una familia FAIL no debe ocultar el resultado de las otras.
- Mantener `main`, V28, PR #118, criterios Randomlock, dos piedras Mega universales, fuentes canónicas y guardados del usuario sin alteraciones.
- Ahorro de contexto: usar `STATUS.md`, último gate, overlay de 267 filas y por trabajadora solo `CONTINUIDAD.md` + `CAMP_001_FINAL.md`; no releer cientos de informes a la vez.

## 3. Condiciones para pasar de borrador a campaña
1. La persona usuaria autoriza explícitamente CAMPAÑA_002 y confirma que se mantienen cuatro W activas más IA6, con W04 congelada.
2. IA6 valida la realidad de los candidatos contra código/CI y selecciona IDs/rutas **sin solapamiento**. Si un ID ya está probado, se retira y queda marcado `NO_DUPLICAR`; si depende de cambios en contrato compartido, se deja bloqueado, no se implementa improvisadamente.
3. IA6 publica `CAMPAIGN_GATE_002.md` y encargos nuevos con base SHA vigente; solo entonces el usuario puede enviar el mensaje de activación a las ventanas elegidas. Nunca reusar `p` de CAMPAÑA_001 como autorización.
4. Una nueva campaña no constituye la resolución de W04/ITER_03 de CAMPAÑA_001. Su bloque pendiente sigue congelado y trazado por separado.

## 4. Lo que este pretriaje NO certifica
No mide todo el trabajo pendiente en el juego, no acredita 477 ítems como `sin implementar`, no verifica UI/GPU ni modelos de libros, no corrige la tabla de selección ni migraciones de guardados. Ninguna implementación nueva fue ejecutada por preparar este documento.
