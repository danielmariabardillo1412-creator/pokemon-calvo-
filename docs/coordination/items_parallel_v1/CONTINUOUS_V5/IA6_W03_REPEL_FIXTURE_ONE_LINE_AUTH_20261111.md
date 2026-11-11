# IA6 — AUTORIZACIÓN PUNTUAL W03 V5: ARREGLO DE FIXTURE DE ZONA, 2026-11-11

**Decisión IA6: APROBADO con alcance de UNA LÍNEA.** Esta nota responde a `CONTINUOUS_V5/W03_REPEL_HISTORICAL_TEST_ZONE_TICKET.md` en W03 V5. La CI #43073388744 FALLÓ y **no se declara PASS**. La prueba anterior contenía un fixture que mezclaba el primer zone ID ordenado (cueva) con posición `EncounterZone` en la hierba. El nuevo test independiente de zona real NO sustituye el histórico; ambos deben pasar tras este arreglo exacto.

## Evidencia y cambio permitido
- Archivo ÚNICO de fixture histórico: `tests/gameplay/parallel_items_w03_repel_l3.gd` en la rama EXCLUSIVA `codex/calvo-items-20261111-w03-repel-staging-v5`.
- Blob original certificado como punto de partida: `318ee45f60d9ee046bcb048019337524acfb4844`.
- Sustituir SOLAMENTE: `var zone: StringName = scene._director.registered_zone_ids()[0]` por `var zone: StringName = scene.TECHNICAL_ZONE_ID`.
- **PROHIBIDO** borrar/reordenar aserciones, bajar umbrales, aceptar fallos, cambiar EncounterDirector/escena/colisiones/RNG, alterar mecanismos de combate o maquillar logs. Conservar la copia histórica accesible por SHA, hacer diff y demostrar exactamente un hunk de una línea sustituida, con mismas 49+ aserciones base (sujeto a ejecución normal de 3 objetos).
- Actualizar **solo** el test guardia W03 `tests/tools/test_ia6_w03_v5_source_guard.py` para reconocer la autorización nueva: en lugar de exigir que el fichero vivo siga siendo el blob anterior, comprobar que el diff nuevo vs ese blob es exclusivamente el reemplazo autorizado (puede obtenerse el original de Git). Mantener los siete hashes de producción protegidos y el guard de `dynamax_candy`; el nuevo test de hierba independiente queda adicional.
- Si el flujo strict histórico sigue fallando tras ese cambio, investigar el error REAL. No bloquearlo a propósito ni añadir `continue-on-error`; reparar únicamente en los módulos de producción V5 previamente autorizados si se demuestra causa, o emitir ticket IA6 si sale de alcance.

## Puerta CI obligatoria
1. CI V5 histórico STRICT `ia6-w03-v5-repel-staging.yml` con `CAMP006_W03_REPEL_L3 PASS` real, verificando todos los casos.
2. CI V5 zona real `ia6-w03-v5-repel-grass-qa.yml` con `W03_V5_REPEL_GRASS PASS` real y los guardas de fuente; el nuevo test no se contabiliza como sustitución de regresión.
3. Regresiones V4 de Repeat legacy original, Repeat/Net/Moon nativas, menta+rope, libros en mochila, SaveV2 normal/adversarial y veto Candy. Si cualquier suite no se ejecuta, dejarla explícitamente **NO PROBADA**, no asumir PASS.
4. Guardar SHA **FUNCIONAL** de cada CI, workflow y job, y documentar resultado. Ninguna ejecución anterior fallida/cancelada certifica la nueva revisión.
5. Si ambas CI SUCCESS y regresiones exigidas PASS, completar `CONTINUOUS_V5/STATE_W03.md` + `reports/W03/CONTINUOUS_V5_FINAL.md` con detalle de hunks y estado `READY_FOR_IA6_MERGE_REPEL_CANDIDATE`. La rama oficial IA6 sigue sin tocar y necesitará su propia integración cruzada con W05 V4.

**Orden para el siguiente `p`: ejecutar este arreglo una línea, actualizar guard estricto, correr las dos CI, auditar los logs y terminar reporte si todo verde. Sin pedir nueva tanda y sin generar QA repetitiva.** No `main`, V28, PR118, staging W05 ni IA6 oficial.
