# IA6 — ORDEN PERMANENTE ACTUALIZADA W04 · TANDA 05

**IA6 YA HA REVISADO TU TANDA 04 Y PUBLICADO UNA ORDEN NUEVA.** Este archivo de TU rama es la fuente de verdad. Al recibir p/sigue/continúa: relee el HEAD de tu rama, abre este archivo y el último checkpoint, identifica primera fila pendiente de TANDA 05 y **trabaja inmediatamente**. No respondas solo que estás esperando a IA6. Ejecuta todos los hitos independientes autorizados sin pedir otra puerta. Si el turno se acaba, guarda progreso y reanuda con la próxima p; no existe procesamiento automático entre turnos.

Protocolo árbitra: docs/coordination/items_parallel_v1/AUTONOMY_V1/README.md en codex/calvo-items-20261101-arbitro; cola maestra: docs/coordination/items_parallel_v1/AUTONOMY_V1/QUEUE_W04_TANDA_05.md. **Reglas:** no repetir tandas cerradas, no tocar main, V28, PR118, ramas ajenas ni módulos fuera de permiso. Una CI SUCCESS solo cuenta si corresponde al SHA del código probado. Reporta por separado hitos, objetos nuevos, QA, funciones L3 y pendientes de integración IA6. Solo detenerse al terminar la tanda o si todas las tareas restantes están realmente bloqueadas.

---

# IA6 W04 TANDA 05 — contrato real de evolución de formas regionales
Rama: codex/calvo-items-20261104-w04-camp006.
Baseline: T04 CI #42890685931 SUCCESS, 55/56 identidades regionales positivas. Exeggutor Alola bloqueado; NO darle Harvest oculta automáticamente.
PROTOCOLO IA6: 10 hitos autorizados sin nueva puerta por hito; p/sigue consulta IA6_AUTORUN.md en su propia rama, usa checkpoint y ejecuta el siguiente paso. Terminar solo al cubrir 10 hitos o agotar todos los seguros; informe + SHA funcional + CI completed/success. Hitos != objetos nuevos != integración IA6. No hay ejecución entre turnos. No tocar main, V28, PR118, ramas ajenas ni ficheros no autorizados.

OBJETIVO: obtener regla real de forma+especie+ítem para Slowpoke de Galar (galarica_cuff / galarica_wreath) y cualquier ruta adicional realmente documentada en EvolutionRecord. NO inventar evoluciones ni saltar condiciones DATA_ONLY. Priorizar helper puro + test reproducible; integración con mochila depende de IA6.
10 HITOS:
01. Datos de Galar Slowpoke/Slowbro/Slowking y metadata exacta.
02. Verificar ítems existentes, triggers y condiciones EvolutionRecord.
03. Helper puro local W04 que valide fuente species+form+item.
04. Positivo solo si el contrato canónico realmente existe; en otro caso ticket con prueba roja.
05. Negativos Slowpoke base, form equivocado, sin item y target incorrecto.
06. No traspasar form_id de especie anterior al destino incompatible.
07. Comprobar naturaleza original/efectiva sin editar trabajo de W02.
08. PARTY/STORAGE, SaveV2 positivo/legacy/corrupto.
09. Regresión 55 formas, Exeggutor bloqueado y CAMP003–006.
10. CI e informe reports/W04/AUTORUN_V5_FINAL.md separando productores, L2, L3 y bloqueos.
Permisos: helper nuevo W04, tests/fixtures/CI, ajuste a canonical_form_identity_w04.gd solo ante defecto probado. EvolutionSystem, CreatureInstance, FieldItemService, FieldItemBag, SaveV2 central, Factory y config son SOLO LECTURA. No adjudicar L3 sin ruta nativa real.
