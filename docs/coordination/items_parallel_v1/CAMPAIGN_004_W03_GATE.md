# IA6 — CAMPAÑA_004 exclusiva W03 / GATE ACTIVADO

**Fecha:** 2026-11-03. El usuario ha indicado que IA3 también terminó y desea mantener a las trabajadoras activas, igual que W05. **Autoridad única:** W03, rama `codex/calvo-items-20261103-w03-camp004`; 10 microbloques nuevos / **36 IDs**, reservados en [CAMPAIGN_004_W03_QUEUE_APPROVED.csv](CAMPAIGN_004_W03_QUEUE_APPROVED.csv). No cambia la CAMPAÑA_004 de W05 ni el trabajo de W01, W02, W04.

## Evidencia de cierre
CAMPAÑA_003 W03 10/10 bloques, 20 bolas tratadas. Último Actions [#41570102206](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41570102206), SHA `6d47ff595537bf1c6eb936b9c7cbec377db7f707`, `completed/success` de Python/Godot y manifiesto. **No equivale a 20 bolas totalmente implementadas**: `luxury_ball`, `lure_ball`, `love_ball`, `moon_ball`, `beast_ball` y `heavy_ball` tienen dependencias de contexto documentadas; los casos negativos no las resuelven. W03 no debe duplicar ni ocultar esta deuda.

## Nuevos bloques
- **01 / 3 CAPTURE_BALL**: `dive_ball`, `dusk_ball`, `repeat_ball` (únicas seleccionadas que quedaban fuera de CAMP003 y evidencia W03 de CAMP001; `net_ball` ya tenía cobertura histórica).
- **02–06 / 15 FIELD_USE**: cinco grupos de tres objetos de campo en la cola; comprobar ruta real, rechazo, consumo, efectos y SaveV2 sin forzar soporte inexistente.
- **07–10 / 18 TERA_MATERIAL**: grupos de 5+5+4+4 fragmentos Tera; **solo auditoría de su tratamiento actual** y pruebas de integridad, aceptación/rechazo y persistencia donde exista contrato. **NO implementar teracristalización ni alterar reglas globales sin decisión IA6/usuario**. Si no hay API, documentar `DEPENDENCIA_COMPARTIDA`; no dar PASS funcional por metadatos.
- Se verificó selección en `docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv`, ausencia de solape con colas CAMP003 y W03 CAMP001. Un ID seleccionado no demuestra mecánica.

## Límites operativos
- **Rama única:** `codex/calvo-items-20261103-w03-camp004`, creada desde SHA del HEAD terminado de W03 CAMP003. Preservar suites anteriores y revisar regresión de las 20 bolas; no repetir pruebas por inercia.
- **Activación inicial ejecuta 01**, cada `p` exactamente un bloque 02..10. Al 10/10 STOP y `CAMPAÑA_004_FINALIZADA`.
- **Autonomía V5:** corregir defectos locales de su captura solo bajo `modules/capture/` para sus bolas asignadas, con casos de regresión. En campo/Tera se autorizan pruebas y diagnósticos propios, no producción de inventario/sesión/reglas compartidas: cambios funcionales requerirán propiedad explícita IA6 si afecta rutas usadas por W02, W04 o W05.
- Los tests de CAMP004 serán de W03; fixture/progreso y runners propios. GitHub Actions W03 dedicado debe ejecutar Python y Godot cuando existan bloques; CI verde de bootstrap 0/10 solo valida estructura, jamás función. Conservar negativos; no falsificar datos, contextos ni capturas; registrar por ID `FUNCIONAL_VERIFICADO`, `NEGATIVO_VERIFICADO_NO_IMPLEMENTADO`, `DEPENDENCIA_COMPARTIDA` o `PRUEBA_PENDIENTE`.
- Prohibido tocar otras ramas, `main`, V28, PR #118, catálogos y políticas globales. La rama W03 no integra ni fusiona a árbitra.

**Prevalencia:** solo para W03 esta puerta autoriza una nueva campaña a continuación del STOP histórico CAMP003. `AUTONOMOUS_REPAIR_V5.md` sigue vigente para reparaciones de propiedad demostrada.
