# Protocolo operativo IA6 v2 — CI centralizada, desbloqueo y relevo
**Fecha:** 2026-11-01. **Vigencia:** complementa `CAMPAIGN_GATE_001.md`, `COORDINATOR.md` y las campañas originales, sin ampliar permisos ni sustituir encargos. Fuente de autoridad: IA6 en `codex/calvo-items-20261101-arbitro`.

## Propósito
Las W01–W05 escriben código, pruebas y cuadernos **solo en sus ramas**. IA6 asume la ejecución y clasificación de la CI consolidada, la identificación de errores y la autorización expresa de continuar cuando haya un bloqueo real. No reenviar al usuario los fallos técnicos como trabajo manual si la árbitra puede diagnosticarlos.

## Un ciclo, sin burocracia por cada objeto
1. La W recibe `p` y procesa **un** microbloque permitido, con commit, `CAMP_001_ITER_0N.md`, `CAMP_001_PROGRESO.csv` y `CONTINUIDAD.md`. No necesita lanzar una CI completa si no tiene acceso al runner: escribe `PREPARADO_PENDIENTE_CI`, con comandos de reproducción y hashes.
2. IA6 consulta **manifiestos breves, HEAD y diff**; no relee históricos completos. Verifica propietarios de rutas, IDs, que no se sobrescriban archivos ajenos y que el estado previo no se declare funcional sin evidencia.
3. Para código funcional nuevo o al reunir un paquete coherente de pruebas, IA6 prepara **rama de integración temporal** derivada del SHA árbitra conocido. Incorpora exclusivamente los blobs/diffs autorizados, fija SHAs de entrada y configura Godot 4.7 + restauración de recursos + **Node 22, `POKEMON_CALVO_NODE` y simulador nativo `tools/battle_reference/run.py --install --limit 1`** cuando la familia use `@pkmn/sim`.
4. Ejecuta una CI **por paquete**, con resultados independientes por familia, resumen final que no permita falsos verdes y logs breves enlazados. La prueba histórica de la base no certifica scripts posteriores. `git diff` + SHA y ejecución funcional son obligatorios para promover producción.
5. Si CI falla, IA6 clasifica el fallo en: `ENTORNO_CI` (instalación/configuración), `TEST_DEFECTUOSO`, `DEFECTO_FUNCIONAL`, `DEPENDENCIA/POLITICA` o `INDETERMINADO`. Un fallo de infraestructura se corrige en staging y se reejecuta; **no se falsean tests** para obtener PASS. El fallo de una familia no impide obtener diagnóstico de las otras.
6. Solo si hay PASS válido y revisión de contrato, IA6 integra de forma secuencial en **su rama árbitra** y registra commit + run + alcance. Ningún cambio pasa a `main` o V28 por este protocolo. El PASS de staging no equivale por sí solo a integración ni a validación visual/GPU.
7. IA6 publica la **autorización exacta para la siguiente iteración**, o un bloqueo técnico reproducible. No reasignar nueva campaña hasta cerrar las tres iteraciones anteriores o retirar formalmente el trabajo anterior.

## Estados inequívocos
- `PREPARADO_PENDIENTE_CI`: entrega de código/fixture documentada; no es un FAIL.
- `BLOQUEADO_PENDIENTE_CI`: el próximo microbloque depende del código aún no verificado; se detiene solo esa W.
- `FALLO_CI_ENTORNO`: fallo del runner, sin veredicto sobre la mecánica; reparar instalación y reintentar CI.
- `FALLO_TEST` / `FALLO_FUNCIONAL`: conservar logs, corregir alcance autorizado, ejecutar regresión.
- `VERIFICADO_EN_STAGING`: PASS de un SHA temporal y un alcance definido; todavía sin integración.
- `INTEGRADO_VERIFICADO`: diff aceptado, commit árbitra y CI sobre el mismo árbol; evidencias registradas.
- `CAMPAÑA_001_FINALIZADA`: W agotó exactamente 3 microbloques; **no** significa que todos estén certificados.

## Gestión de errores de conversaciones
Si una trabajadora llega al límite o muestra error de chat: conservar su rama intacta. Una nueva conversación con **el mismo W0X**, nunca un W nuevo, lee `CAMPAIGN_GATE_001.md`, su campaña, su `CONTINUIDAD.md` y el último `CAMP_001_PROGRESO.csv`. No repetir bloques publicados. Si hay nueva orden de IA6, prevalece sobre historial local. Una caída de conversación no es una regresión de GitHub.

## Estado inicial de adopción
- W01: ITER_02/03 publicada, test nuevo aún sin CI.
- W02: ITER_03/03, `CAMP_001_FINAL.md` entregado, funcionalidad pendiente de CI. No mandar más `p`.
- W03: ITER_02/03, `net_ball` cambia producción. Bloque 03 detenido hasta PASS real.
- W04: ITER_02/03, chat con error según usuario, rama intacta; reanudar mediante relevo cuando proceda.
- W05: ITER_01/03, adaptador solo lectura nuevo, test publicado mediante recuperación IA6; bloqueo de continuación hasta CI real.
- CI #41349870689: **FAIL de preparación**, omitió el simulador nativo; el paso de capturas históricas falló por `worker_handshake` y W05 fue saltada, no prueba que `net_ball` sea incorrecta.
- Reintento con pasos de familia independientes y simulador: rama de staging `codex/calvo-items-20261101-ci-camp001-smoke`, commit `c25f1616366a4c4432ee63fd49c001083d55647b`, [consultar ejecución](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/workflows/parallel-camp001-w03-w05-smoke.yml). **Resultado pendiente** al crear este documento. No levantar bloqueos antes de leer conclusión de la ejecución exacta.

## Seguridad y ahorro de contexto
- Nunca modificar `main`, `codex/items-v28-from-main`, PR #118 ni ramas W ajenas en una integración ordinaria.
- Mantener políticas de selección, Mega diferida, 19 máquinas históricas y guardados intactos.
- Preferir tests por familia + una CI por paquete frente a cinco pipelines por objeto. No eliminar aserciones ni ignorar exit codes.
- IA6 actúa **cuando el usuario vuelve a solicitarlo**: no monitoriza ni ejecuta trabajo en segundo plano.
