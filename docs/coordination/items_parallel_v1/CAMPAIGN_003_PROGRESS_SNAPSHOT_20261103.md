# IA6 — CAMPAÑA_003, foto operativa de cinco IAs (2026-11-03, aprox. 03:30 CET)

**Fuente de verdad:** ramas propias y GitHub Actions, no colores/textos del chat. Los datos siguientes son una fotografía; si aparece un commit/run posterior, actualizar lectura antes de dar una nueva orden.

| IA | Progreso registrado | Trabajo pendiente | Estado comprobado |
| --- | --- | --- | --- |
| W01 | **07/10** | 08, 09, 10 | [CI #41565500695](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41565500695) **failure**: Python 582 PASS; Godot 8793 checks, **16 aserciones fallidas**; no certificar 04–07. |
| W02 | **09/10** | 10 | [CI #41566220523](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41566220523) **in_progress** al consultar (Python pasó; Godot ejecutándose). Última CI anterior verificable [#41563958549](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41563958549) SUCCESS para 08/10. |
| W03 | **08/10 en CSV**; fixture/test de 09 ya publicado | Completar/publicar 09 y 10 | [CI #41566553143](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41566553143) **in_progress** para nuevo SHA de pruebas 09. [#41566107173](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41566107173) SUCCESS previo. Las bolas especiales sin contexto siguen NO implementadas. |
| W04 | **05/10** | 06–10 | [CI #41565823249](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41565823249) **SUCCESS**, 58 Python + 63 Godot y regresión histórica 559 checks. Muchas evoluciones de intercambio/objeto equipado sin regla catalogada siguen como DEPENDENCIA, no funcional PASS. |
| W05 | **10/10** | ninguna de CAMP003 | [CI #41565822563](https://github.com/danielmariabardillo1412-creator/pokemon-calvo-/actions/runs/41565822563) **SUCCESS**, Python **580** y Godot **2166** checks; 60 MT/pares en suite acumulativa. **CAMPAÑA_003_FINALIZADA; no iniciar BLOQUE 11**. |

## Diagnóstico exacto de W01 (prioridad)
CI #41565500695 Godot FAIL tiene **16 aserciones concretas** y advertencias aparte de `pipe_client.gd:72` por comprobación de PID en Linux. Los 16 fallos de aserción:
- **12** en `boots_rock_switch` / `boots_no_rock_switch` (tres variantes + verificación probe, semillas 19 y 23, y caso negativo) al intentar un cambio en batalla; investigar si el comando de cambio o el test de Botas Gruesas está mal construido.
- **2** en `iron_speed_delay` para Bola Férrea: orden relativo Gengar/Garchomp a misma prioridad no coincide.
- **2** en `lagging_same_priority_last` para Cola Plúmbea: no se acredita portador último en mismo nivel de prioridad.
- Python `CAMP003_W01_PY PASS blocks=7 checks=582`; Godot `CAMP003_W01_GODOT FAIL blocks=7 checks=8793 errors=16`.
**W01 tiene permiso AUTONOMOUS_REPAIR_V5** para analizar estos casos, distinguir fallo de harness y mecánica propia, reparar en su rama, conservar los tests y repetir CI. No entregar 08 dependiente ni suprimir las aserciones para forzar PASS. PID Linux puede ser ruido conocido; no confundirlo con causa de estas 16 aserciones.

## Orden operativa
- **W01**: próxima `p` debe priorizar **reparación del bloque 07** y nuevo SUCCESS antes de continuar con 08; si exige arquitectura compartida, elevar a IA6. Una reparación no consume nueva fila de cola.
- **W02**: comprobar conclusión real de último run; si PASS, `p` bloque 10; si sigue en CI y 10 es independiente, puede prepararlo sin afirmar PASS; en FAIL, reparar primero. Al 10/10 STOP.
- **W03**: terminar comprobación/progreso del bloque 09 y después `p` para 10. Las dependencias de Love/Moon/Lure etc. permanecen sin resolver si no se propagó contexto real.
- **W04**: seguir `p` para bloque 06, 07..10, autónoma para reparación local. Un PASS de tests negativos no demuestra evolución jugable de objetos condicionados.
- **W05**: 10/10 STOP; **se puede preparar una futura cola de otros IDs** tras auditoría, pero no iniciarla por `p` ni llamar CAMP004 autorizada sin puerta/alcance nuevos.

**Restricciones:** no tocar `main`, V28, otras ramas o catálogo. IA6 solo coordina conflictos, integración y una nueva campaña aprobada.