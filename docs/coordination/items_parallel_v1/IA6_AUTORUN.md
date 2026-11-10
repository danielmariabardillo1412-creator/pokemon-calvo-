# IA6 — ORDEN PERMANENTE ACTUALIZADA W05 · TANDA 05

**IA6 YA HA REVISADO TU TANDA 04 Y PUBLICADO UNA ORDEN NUEVA.** Este archivo de TU rama es la fuente de verdad. Al recibir p/sigue/continúa: relee el HEAD de tu rama, abre este archivo y el último checkpoint, identifica primera fila pendiente de TANDA 05 y **trabaja inmediatamente**. No respondas solo que estás esperando a IA6. Ejecuta todos los hitos independientes autorizados sin pedir otra puerta. Si el turno se acaba, guarda progreso y reanuda con la próxima p; no existe procesamiento automático entre turnos.

Protocolo árbitra: docs/coordination/items_parallel_v1/AUTONOMY_V1/README.md en codex/calvo-items-20261101-arbitro; cola maestra: docs/coordination/items_parallel_v1/AUTONOMY_V1/QUEUE_W05_TANDA_05.md. **Reglas:** no repetir tandas cerradas, no tocar main, V28, PR118, ramas ajenas ni módulos fuera de permiso. Una CI SUCCESS solo cuenta si corresponde al SHA del código probado. Reporta por separado hitos, objetos nuevos, QA, funciones L3 y pendientes de integración IA6. Solo detenerse al terminar la tanda o si todas las tareas restantes están realmente bloqueadas.

---

# IA6 W05 TANDA 05 — verificar entrega de 229 nombres españoles en paquete Windows
Rama: codex/calvo-items-20261109-w05-books-ui.
Baseline: T04 CI #42894306446 SUCCESS; traducciones ES 229/229 procedentes de PokeAPI, MT nuevas 0, panel separado del integrado. export_presets.cfg existe y usa all_resources, pero falta comprobar que el JSON local esté disponible en runtime exportado.
PROTOCOLO IA6: 10 hitos autorizados sin nueva puerta por hito; p/sigue consulta IA6_AUTORUN.md en su propia rama, usa checkpoint y ejecuta el siguiente paso. Terminar solo al cubrir 10 hitos o agotar todos los seguros; informe + SHA funcional + CI completed/success. Hitos != objetos nuevos != integración IA6. No hay ejecución entre turnos. No tocar main, V28, PR118, ramas ajenas ni ficheros no autorizados.

OBJETIVO: no dar por terminada la localización solo porque funciona en Godot editor. Comprobar que la tabla data/localization/machine_moves_es_sv_v1.json se empaqueta en el Windows técnico. NO afirmar export Android sin preset.
10 HITOS:
01. Auditar export_presets.cfg, ruta FileAccess, recursos e ignores.
02. Test Python 229 registros, ruta portable e integridad.
03. Intentar export Windows existente sin sobrescribir entregables.
04. Inspeccionar PCK resultante, o si falta plantilla ticket técnico BLOQUEADO.
05. Runtime export: tm01, tm75, tm202, tm229 muestran ES correcto.
06. Fallback al faltar JSON o tener esquema inválido.
07. Panel con reabrir/Party/Storage sin señales/gasto indebido.
08. Enseñar MT con stock, PP y SaveV2, preservar 229 regresiones.
09. Contrato testable de integración con FieldItemBag IA6 sin editarlo.
10. CI y reports/W05/AUTORUN_V5_FINAL.md: export REAL vs preflight/blocked.
Permisos: tests, fixtures, workflow W05; helper ES y panel solo si prueba falla. export_presets.cfg solo adición mínima de ruta JSON si test demuestra que es necesaria y sin modificar los demás filtros. FieldItemBag, FieldItemService, SpanishGameText global, SaveV2, catálogos y motor solo lectura. Cero MT nuevas, no fingir validación GPU ni export Windows si faltan plantillas.
