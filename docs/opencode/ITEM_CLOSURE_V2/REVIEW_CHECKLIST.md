# Puertas del ejecutor y revisión posterior

Esta lista no es aceptación de Codex. Al empezar una familia guardar el HEAD
actual como FAMILY_BASE en STATE/PROGRESS. Al cerrarla ejecutar, además del guard
global, el guard por familia; así una prueba de O100 no se cambia dentro de O110:

```text
python tools/verification/opencode_items_v2_guard.py --family O110 --since <FAMILY_BASE>
```

O100/O120/O190 sustituyen el ID. El commit base debe ser ancestro real. No elegir
un commit posterior a tus cambios para ocultarlos. No se resellan baselines.
Preparar un checkpoint local con alcance exacto solo después de las puertas;
después continuar con la familia siguiente. El revisor recibirá el rango entero.

## Común a las familias implementadas

- Contrato por capacidad y todas sus filas, fuentes fijadas y créditos.
- Validación antes de mutación; candidato separado, commit único y consumo
  posterior al éxito. Sin gasto, turno, RNG o publicación por rechazo.
- En nativo, las APIs del simulador resuelven mecánicas; no fórmulas paralelas.
- Preparar/abortar/confirmar, fallo de campaña/revisión, interrupción, KO y
  reemplazo obligatorio; UI y callbacks pendientes no pueden repetir acciones.
- Cantidades físicas = mochila + portadores vivos/no consumidos; ni duplicación
  ni devolución de un objeto perdido/consumido. Condiciones de reutilización.
- Guardar/cargar antes/después y reanudar determinísticamente. Compatibilidad
  con fixtures V21 capturados en O100, sin reescribirlos después de implementar.
- Nuevos campos calculados en proyección no habilitan cambios de schema. No
  editar `_origin`, checksums, hashes o validadores para aceptar datos incoherentes.
- Nada no probado se etiqueta PASS; log abortado/timeout no cuenta como éxito.

O100 debe conservar en `.godot/opencode_items_v2/baseline_fixtures/` snapshots de
la versión previa en los tres perfiles: turno ordinario, gasto de medicina,
objeto transferido/consumido y un guardado de campo. Puede crear los dos runners
de baseline nombrados en CONTRACT. Son fixtures de pruebas pequeñas; no copias
de datasets ni del juego. Guardar SHA-256 antes de implementar. O110/O120 no
pueden modificar esos archivos de referencia ni adaptar sus expectativas.
Validar los SHA de esos fixtures antes de usarlos y de nuevo en O190.

## Entrega conjunta O190

- Inventario completo sin UNKNOWN sin investigar y sin dobles conteos.
- Resumen por ID Y contexto, diferencia entre presencia/efecto/escenario,
  dependencias y partes parciales. «Abordable cerrado» no significa «100% total».
- Todos los diffs dentro de CONTRACT y funciones permitidas; git diff --check.
- Pruebas nuevas + regresiones relevantes de WORK_ORDER, procesos terminados,
  resultados parseables, conteos, SHA de código y evidencia por ejecución.
- Capturas finales vistas; no anunciar revisión visual solo por guardar PNGs.
- Guard global --full y por familia; guardar sus resultados sin editarlo.
- Commits locales enumerados, estado limpio salvo entregables finales expresos.
- STATE: READY_FOR_REVIEW o PARTIAL_READY_FOR_REVIEW; writer_active=false.
- Nunca ACCEPTED_BY_CODEX ni «revisión independiente pasada». No publicar ni
  mezclar ramas. Un solo informe final para el usuario con lo que debe traerme.

No es necesario volver a ejecutar todos los verificadores históricos con sus
baselines congelados. Orquestar sus pruebas compatibles bajo el guard nuevo y
registrar qué bytes actuales se comprobaron. Una igualdad con baseline tampoco
demuestra que un fallo compartido sea correcto.
