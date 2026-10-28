# Perfil de combate vigente — 2026-10-28

La demo habitual abre `gen9calvounifiedv1`: reglas y datos del simulador Gen9
fijado a `@pkmn/sim@0.10.11`, con una compatibilidad propia acotada para activar
Dinamax. F12 usa `gen9calvounifieddoublesv1`. Son perfiles propios identificados,
no formatos oficiales ni una regla competitiva universal.

La compatibilidad registra los formatos mediante `Dex.formats.extend` y cambia
solo la disponibilidad nativa de Dinamax dentro de esos IDs. Conserva condiciones,
fórmulas, objetivos, PP, duración de tres turnos y uso por equipo del simulador.
El indicador nativo de uso se inicializa al comenzar, nunca al restaurar. El
orden de `formatid` se normaliza en los snapshots nuevos para que guardar antes
del primer turno también produzca una restauración exacta. No se reescriben los
hashes de snapshots históricos.

Los 19 Maxi se generan al activar Dinamax desde movimientos base; no se aprenden
como slots ordinarios. Los 50 Z de daño conservan sus cristales y requisitos
nativos. Todos los Z de estado siguen bloqueados, incluido el segundo puesto de
dobles. Los dos equipos disponen de sus permisos nativos independientes. No se
aplica la propuesta de compartir un único uso entre Mega/Z/Gigamax.

Mega, Ultra y teracristalización no se habilitan en este perfil de ataques:
requieren su propia integración/presentación. Teraexplosión como movimiento sí
forma parte del catálogo ensayado; no equivale a activar teracristalización.
F12 sigue siendo un ensayo separado de cuatro activos: no añade encuentros
dobles, progresión o recompensas a la campaña. La conexión nativa acepta órdenes
Max/Z de dobles; los menús del ensayo mantienen la selección ordinaria existente.

La demo normal usa el nuevo perfil. Los guardados Gen8/Gen9 anteriores conservan
su formato al cargarse, sin conversión silenciosa. Los flags explícitos
`--battle-format=gen8customgame` y `--battle-format=gen9customgame` mantienen
compatibilidad y diagnóstico. Guardado de campaña y checkpoint F12 permanecen
separados.

Ver `UNIFIED_MOVE_SWEEP.json/CSV`: 900 movimientos permitidos con ejecuciones
positivas nativas y proyección Godot; 19 excluidos por la política existente.
Hay escenarios preparados, contratos numéricos, guardado/repetición y regresiones.
Esto cierra la conexión y el barrido funcional acordados; no certifica todas las
combinaciones posibles de especie, habilidad, objeto y movimiento.

Reproducir: `python tools/showdown_engine_probe/run_unified_sweep.py`. Tras revisar
las dos capturas GPU, registrar sus hashes en `visual_review.json` y ejecutar
`python tools/showdown_engine_probe/verify_unified_sweep.py`. El verificador exige
los 900 positivos, exclusiones, perfil correcto en los lotes, cero errores de
proyección, capturas revisadas y regresiones. No convierte un fallo válido de
movimiento en una prueba positiva.
