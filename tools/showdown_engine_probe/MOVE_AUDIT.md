# Auditoría automática de movimientos

## Vigente: barrido conjunto cerrado — 2026-10-28

`run_unified_sweep.py` reutiliza los generadores y fixtures preparados en carpetas
separadas bajo `.godot/unified_profile_checks/`. No regenera datasets ni arte.
Gen9 + Dinamax y variante doble tienen IDs propios. Se exigen 900 movimientos
permitidos con casos positivos: 820 ordinarios, 50 Z de daño, 19 Maxi y 11 dobles.
Se conservan 19 exclusiones. Hay 3.358 casos generales, 72 preparados, 200 Z y 44
dobles; los dos primeros bloques también se proyectan por lotes en Godot y los
otros dos por `unified_profile_test_runner.gd`, que prueba además IPC y mapa real.

La verificación `verify_unified_sweep.py` exige unión exacta del catálogo,
perfiles correctos, estados/PP, contratos, regresiones y hashes de capturas
revisadas. Publica `UNIFIED_MOVE_SWEEP.json/CSV`. Una acción fallida no se cuenta
como ejecución positiva. Las combinaciones exhaustivas y otras mecánicas del
juego quedan fuera; una incidencia futura requiere su propia regresión.

Los apartados siguientes conservan la auditoría de fases anteriores.

Último cierre (2026-10-27): los 11 movimientos de dobles ya tienen camino
nativo Godot con cuatro activos reales en F12. `run_doubles_integration.py`
ejecuta 44 casos nativos, 454 checks de conexión, UI y capturas temporales,
además de regresiones de mapa/combate/guardado. `doubles_contact_sheets.py`
agrupa 66 capturas. Tras revisión visual del agente,
`verify_doubles_integration.py` valida hashes y publica `NATIVE_DOUBLES_INTEGRATION.json`.
Quedan perfil conjunto y barrido final, no la conexión de estos 11 movimientos.

Actualización 2026-10-27: el mapa habitual usa la conexión nativa y guarda partida
completa/combate activo. Gate actual: `python tools/showdown_engine_probe/run_field_integration.py`;
verificar evidencia con `verify_field_integration.py`. Informe:
`FIELD_NATIVE_INTEGRATION.json`. Las pruebas de mapa tienen 118 checks headless y
123 GPU, cinco capturas revisadas, guardado atómico y continuidad de la campaña.

El catálogo de ataques anterior (`Z_MOVE_INTEGRATION.json/CSV`) conserva evidencia
histórica: 889 acciones ensayadas, 11 de contexto doble y 19 excluidas. Las tres
firmas descartadas por usuario/formas NO quedan pendientes. Los gates antiguos
capturaban hashes de fases anteriores; no ejecutarlos como verificador de las
fuentes modificadas después. Quedan perfil final conjunto, dobles nativos y
barrido final; no equivale a certificar todas las interacciones de los 889.

Vigente tras las reparaciones: `MOVE_CONNECTION_REPAIR.json/CSV`, guía del backend
en `modules/battle/backends/showdown/README.md`. Ejecutar toda la comprobación con
`python tools/showdown_engine_probe/run_move_connections.py` o verificar la evidencia
existente con `verify_move_connections.py`. Los 12 bloqueos iniciales ya están
corregidos. Resultado combinado: 820 individuales ensayados + 19 Maxi Gen8;
11 nativos de dobles sin UI doble, 1 forma ausente, 53 Z pendientes, 15 excluidos.

Desde `D:\Proyectos\Pokemon Calvo`:

```powershell
python tools/showdown_engine_probe/audit_moves.py
python tools/showdown_engine_probe/verify_move_audit.py
```

No descarga dependencias ni cambia código de juego, datos, admisión o arte.
Requiere los ejecutables locales Godot/Node y @pkmn/sim 0.10.11 ya fijados.
Produce evidencia acotada en `.godot/move_functional_audit` (~89 MB), un CSV de
919 filas y un resumen JSON en `docs/current`. Los lotes son de 32 casos, sin
millones de viajes Godot/Node ni una revisión visual por movimiento.

## Alcance probado

- Inventario completo de 919 IDs canónicos, sin omisiones silenciosas.
- 832 ordinarios × dos contextos × dos semillas: 3.328 casos. Escenarios sano
  y dañado/con veneno y objetos, con hasta cuatro decisiones nativas, solicitudes
  de relevo y cambios reales. Las elecciones obedecen las solicitudes legales.
- 15 contratos adicionales de resultado esperado: daño fijo/proporcional,
  etapas, Protección con residuales, curación y estados. Resultados explícitos,
  no calculados invocando la misma fórmula del simulador bajo prueba.
- 13.448 decisiones preparadas/confirmadas y round trips de snapshot en el
  barrido actualizado (incluidos 19 casos de cuatro decisiones Maxi); las
  continuaciones guardadas comparadas con su replay. Rangos de PS/PP y ausencia
  de mutación durante prepare comprobados. Repetibilidad no certifica reglas.
- Proyección offline de los checkpoints por **los mismos** `_mirror` y
  `event_adapter` de la fachada real de Godot: identidades/PS/PP/estados,
  mensajes desconocidos y fronteras que rechazan la confirmación. Se compactan
  únicamente campos no consumidos por esas funciones; no se ejecuta el mirror
  como un segundo motor. No es un test de transporte/UI de cada movimiento.
- 19 Maxi ensayados también por el mirror/adaptador de Godot en Gen8, separados
  del perfil Gen9. Son 3.362 casos totales. 53 Z y 15 excluidos se inventarían.

## Resultado inicial (histórico, antes de las reparaciones)

772 ordinarios pasan la integración en los contextos ensayados. **No equivale
a certificar todos sus efectos/interacciones.** 48 necesitan contexto adicional;
no se etiquetan como defectuosos ni terminados. 12 tienen bloqueos observados:

| Causa compartida | IDs |
| --- | --- |
| `-ohko` sin traducir | fissure, guillotine, horn_drill, sheer_cold |
| `-swapsideconditions` | court_change |
| `-anim` | dragon_darts |
| PS simultáneos en `-sethp` | pain_split |
| Alias Vice/Vise | vice_grip |
| Movimientos/formas temporales | mimic, transform |
| Sustituto | substitute, shed_tail |

En ese primer barrido Maxi era nativo sin conexión Godot. La fase posterior lo
conecta por perfil Gen8 explícito. Z y descartes se conservan como pidió el usuario.
El barrido sigue siendo de solo lectura; los cambios de código pertenecen a la
fase de reparación y tienen pruebas separadas.

El estado `INTEGRATION_OK_IN_TESTED_CONTEXTS` exige observar el movimiento
declarado, sin confundir acciones posteriores de Struggle/reservas con su éxito.
Un fallo posterior por alcanzar un límite no borra un uso válido anterior.
Fallos legítimos, inmunidades y requisitos de contexto no se convierten en PASS.

`verify_move_audit.py` verifica cobertura, hashes, CSV, logs y fuente protegida.
Su resultado significa auditoría reproducible con hallazgos abiertos, nunca
«todos los movimientos funcionan». El backend habitual histórico es otro
camino: continúa en 620 admitidos y 230 pendientes de mecánica.
