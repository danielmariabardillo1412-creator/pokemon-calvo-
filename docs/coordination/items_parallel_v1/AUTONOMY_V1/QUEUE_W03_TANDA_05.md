# IA6 W03 TANDA 05 — Net Ball nativa de extremo a extremo
Rama: codex/calvo-items-20261104-w03-camp006.
Baseline: T04 CI #42891930750 SUCCESS. El almacenamiento es AUTOEXPANDIBLE; no repetir la prueba imposible de globalmente lleno. Repeat Ball ya L3 en T03 y con QA V4.
PROTOCOLO IA6: 10 hitos autorizados sin nueva puerta por hito; p/sigue consulta IA6_AUTORUN.md en su propia rama, usa checkpoint y ejecuta el siguiente paso. Terminar solo al cubrir 10 hitos o agotar todos los seguros; informe + SHA funcional + CI completed/success. Hitos != objetos nuevos != integración IA6. No hay ejecución entre turnos. No tocar main, V28, PR118, ramas ajenas ni ficheros no autorizados.

OBJETIVO: captura real nativa con net_ball. capture_ball_effects.gd YA devuelve x3.5 para Agua/Bicho y x1 otros; no recontarlo como nuevo objeto si ya funciona. Exigir especie de catálogo desde WildEncounterSystem, inventario real, ShowdownAdventureSession.capture, propietario y SaveV2.
10 HITOS:
01. Preflight perfil Net Ball, tipos y motor, registrar L2 previo.
02. Prueba nativa roja Agua y Normal con semillas.
03. Bicho y doble Agua/Bicho: x3.5 una sola vez.
04. Captura positiva y consumo único con propietario estable.
05. Captura fallida RNG: consumo sin criatura ni ledger.
06. Party 6/6 y STORAGE autoexpandible, sin duplicados.
07. Cambio de miembro y Transformación, tipo de especie canónica.
08. SaveV2 normal y corrupción, identidad y stock.
09. Regresiones Repeat/Quick/Timer/Level, repelentes/Cuerda Huida.
10. CI y reports/W03/AUTORUN_V5_FINAL.md con L2 previo vs L3 nativo real.
Permisos solo tests/fixtures/workflow W03; capture_ball_effects.gd en rama Net Ball y showdown_adventure_session.gd::capture exclusivamente si prueba roja justifica un arreglo mínimo. No modificar FieldItemBag, SaveV2, PlayerCollection, RNG global, otras bolas ni el ledger. Si ya funciona L3, certificar sin fingir objeto nuevo.
