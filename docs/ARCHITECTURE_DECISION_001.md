# ADR-001 — Feature-first con límites hexagonales selectivos

- Estado: Accepted with changes
- Fecha: 2026-08-29
- Alcance: Foundation V1

## Context

El proyecto necesita crecer desde un vertical slice a cientos de reglas, más de
1000 especies, guardado, ejecución headless y un futuro servidor autoritativo. Lo
mantendrán al menos dos desarrolladores y agentes de código. La auditoría previa
propuso una arquitectura híbrida feature-first + Clean/Hexagonal y aportó tres
spikes con 8/8 pruebas cada uno.

La revisión crítica confirma el problema central: una arquitectura centrada en
escenas, autoload managers o UI haría que la autoridad y el estado no fueran
instanciables por combate. También identifica límites de la propuesta: `RefCounted`
no elimina la dependencia del runtime Godot; miles de `.tres` escritos a mano no son
una base de datos sostenible; un EventBus global oculta dependencias; y puntuar
opciones no prueba su comportamiento bajo evolución, migraciones o replays.

## Options considered

1. **Layered/Clean completa.** Dominio, aplicación, puertos y adaptadores para cada
   operación. Aísla bien, pero multiplica archivos y navegación sin fuentes externas
   reales todavía.
2. **Feature-first sin restricciones.** Buena localidad, pero facilita ciclos y que
   UI, Resources mutables o managers entren en reglas.
3. **Godot-native basado en escenas/autoloads.** Rápido para prototipos, inadecuado
   para N combates headless y autoridad de servidor.
4. **ECS completo.** Aísla sistemas, pero exige construir o adoptar infraestructura
   ajena al modelo natural de Godot sin una escala medida que lo justifique.
5. **Feature-first con límites hexagonales selectivos.** Cohesión por módulo, reglas
   sin SceneTree y adaptadores solo en los bordes con coste de cambio real.

## Decision

Se elige la opción 5, **validada con cambios** respecto a la recomendación previa.

- Se crea un dominio propio. GodWhite y Pokerecomp son referencias, no bases ni
  dependencias.
- Battle es completamente independiente del `SceneTree` y de presentación, aunque
  continúa ejecutándose sobre Godot/GDScript.
- `CreatureInstance` es `RefCounted`; las definiciones de especie, movimiento, tipo
  y status son Resources estáticos tratados como inmutables.
- `BattleState`, `BattleAction` y `BattleEvent` son objetos de dominio serializables.
- El servidor posee estado, catálogo, executor y RNG. Cliente/UI solo propone
  acciones; presentación solo consume eventos.
- Poison vive en `StatusSystem`. Se adopta el hábito de sistemas pequeños, no ECS.
- No se usa ECS, tampoco preventivamente en overworld.
- No hay EventBus global ni autoloads en Foundation V1.
- Los límites hexagonales se aplican a red/cliente, presentación, RNG, persistencia
  serializable y acceso a definiciones. No se crean puertos para cálculos internos
  puros o CRUD inexistente.
- Los IDs explícitos son estables para red y save. Los snapshots versionan esquema,
  ruleset y algoritmo RNG.

## Why

Esta forma conserva la localidad que necesita un equipo pequeño y permite que un
agente trabaje en daño, status o datos con un área de impacto comprensible. A la vez,
los límites que afectan autoridad, determinismo y persistencia son visibles y
probados. El vertical slice demuestra prioridad, velocidad, empate aleatorio
reproducible, daño, STAB, efectividad, KO, Poison, rechazo de acciones forjadas,
eventos y round-trip JSON sin gráficos.

## Rejected alternatives

- Se rechaza reutilizar GodWhite literalmente por su mezcla de dominio/presentación
  y estado global.
- Se rechaza portar Pokerecomp como foundation por sus supuestos Gen2; solo se toman
  ideas generales ya públicas en la auditoría.
- Se rechaza Clean ceremonial: no hay una interfaz por clase ni casos de uso vacíos.
- Se rechaza ECS por anticipación. `StatusSystem` obtiene el aislamiento útil sin
  entidades/componentes genéricos.
- Se rechazan `EventBus` y `GameContext` preventivos. Se añadirán solo con un caso de
  uso probado y sin almacenar autoridad de reglas.
- Se rechaza `CreatureInstance` como Resource para evitar compartir estado mutable.
- Se rechazan rutas y UIDs de Resource como identidad persistente.

## Consequences

Positivas:

- Cada combate es instanciable y el servidor puede alojar varios.
- Tests y servidor no requieren render ni escena visual.
- UI no puede decidir daño, HP, KO o victoria mediante la API publicada.
- Datos y estado están separados por IDs, lo que facilita importación y migraciones.
- El estado del RNG viaja con el snapshot.

Costes:

- Hay disciplina arquitectónica que hoy depende de revisión y documentación.
- Algunos módulos colaboran directamente con clases concretas de Godot porque
  GDScript no ofrece interfaces nominales; se extraerán puertos cuando aparezca un
  segundo adaptador real.
- Los Resources se deben tratar como inmutables por convención.
- Un servidor fuera de Godot necesitará una implementación compatible.

## Risks

- El combate solo modela dos participantes y una acción de movimiento por criatura.
- La fórmula de daño y el modelo de tipos/status son deliberadamente mínimos.
- Los ticks de status se resuelven en orden estable, no de manera simultánea; los
  empates/dobles KO requieren una decisión de reglas futura.
- El LCG y `next_u32() % count` son reproducibles pero tienen sesgo y no sirven para
  seguridad. Si cambia el algoritmo, debe cambiar `rng_algorithm`.
- `ruleset_id` es manual; una fase posterior debería asociarlo a un manifiesto/hash
  de datos validado.
- `DefinitionCatalog` carga todo en memoria. Antes de datos masivos habrá que medir,
  indexar e importar, sin cambiar los IDs del dominio.
- La deserialización V1 confía en snapshots del servidor y usa assertions; entradas
  de red no confiables necesitarán validación con errores recuperables.
