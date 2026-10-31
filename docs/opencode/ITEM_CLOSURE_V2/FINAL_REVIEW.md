# Cierre revisado de objetos — 2026-10-31

**REVIEWED_WITH_LIMITS — alcance aceptado por Codex tras dos correcciones.**
No equivale a completar todos los objetos del juego.

Checkpoint funcional: `0f28371471ff76c878f7cbe2c2fc10b963d29764`. Se trabaja en la copia organizada
`D:/Proyectos/Pokemon Calvo - Arquitectura Kilo`. Sin publicación ni merge.

## Correcciones de la revisión

1. Flauta Azul: rechazados quemadura, parálisis, veneno, veneno grave y congelación;
   solo cura sueño. Rechazar no avanza combate ni gasta mochila/RNG.
2. Objetos X: Respondón se aplica antes del límite de etapas mediante la API
   nativa. Respondón a +6 y -6 y Simple quedan cubiertos por regresión.

Los fallos iniciales se reprodujeron antes de corregirlos. No se cambian datos,
políticas, arte, paquetes, schema ni algoritmos del simulador.

## Comprobaciones

- Suite completa: 14 grupos O110 y 9 O120 PASS, 14883 comprobaciones
  de familia; 6/6 grupos de cierre PASS,
  1285 comprobaciones de cierre. Los grupos contienen pruebas anteriores
  y se solapan: no son objetos distintos certificados.
- Prueba nativa ampliada: 25 PASS. Integración de mochila real: 150 PASS.
- 33 usos independientes (11 × Gen8/Gen9/unificado) y cuatro checkpoints V21
  restaurados: 37 PASS. Los tres fixtures originales conservan SHA-256; las
  fuentes nativas del baseline coinciden con la base de misión.
- Tres capturas GPU vistas: mochila de combate con objetivo/consumo correctos,
  mochila de Bola de Humo y mapa tras equipar. Sin recortes de controles/textos.
- Guardas globales `--full` antes/después PASS: 23.079 archivos protegidos y
  15.647 ausentes preservados. Guardas originales, sin resellar.
- Auditoría final regenerada solo como informe de cobertura: 2.222 filas, cero
  UNKNOWN; pruebas del auditor y comparación `--check` PASS. No es un dataset.

Ejecución definitiva: `.godot\opencode_items_v2\closure\runs\1793415500568966000\results.json`.
Evidencia independiente: `.godot/opencode_items_v2/review_codex/1793415104322870700/`.
Resultados versionados: `evidence/O190/results.json` y `FINAL_RESULTS.json`.
La entrega del ejecutor queda preservada mediante `worker_delivery_receipt.json`.
El primer intento interrumpido y los errores de fixtures se conservan y no
cuentan como PASS. No se atribuye aceptación independiente a OpenCode.

## Límites

- La aceptación cubre el lote O100/O110/O120/O190 revisado; no certifica los 2.222 objetos ni todas las combinaciones.
- No se reconstruyeron guardas históricas por familia: OpenCode entregó un árbol mixto. Se revisa el conjunto con el sello original, sin resellarlo ni inventar checkpoints.
- Cleanse Tag y Pure Incense solo verifican tasa 2/3; faltan tanto la semántica por pasos como sus descriptores nativos. Entrar equipados en combate nativo sigue bloqueado (Unknown held item). No se certifican como objetos completamente utilizables.
- Amulet Coin, Exp. Share, Linking Cord y Luck Incense conservan sus dependencias concretas.
- Siguen pendientes multiplicadores EV de objetos equipados, Max Mushrooms y las rutas documentadas de IV, mentas, formas/evolución y fidelidad de captura/XP.
- El bonus base de amistad está verificado; origen y Lujo siguen pendientes.
