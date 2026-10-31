# Objetos V12 — Veloz, Turno y Nivel Ball

Base: `0d0792d`. Se amplía la copia organizada, con un escritor. Se conserva el
perfil aproximado **calvo_capture_v1**; esta fase no lo convierte en la fórmula
oficial completa de Gen IX. No cambia datos, políticas, arte, worker, algoritmos
de combate, RNG ni formato de guardado.

## Reglas y contexto

Referencia comunitaria primaria: Pokémon Essentials, Maruno17 y colaboradores,
commit `8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b`, archivo
`Data/Scripts/011_Battle/007_Other battle code/010_Battle_PokeBallEffects.rb`.
Se consulta como código, sin ejecutar Ruby ni instalar su motor.

| Objeto | Regla aplicada al perfil existente |
| --- | --- |
| Veloz Ball (`quick_ball`) | ×5 con cero turnos completados; ×1 después. Distinta de Rapid Ball. |
| Turno Ball (`timer_ball`) | `min(1 + 0,3 × turnos completados, 4)`; 0→1, 1→1,3, 9→3,7, desde 10→4. |
| Nivel Ball (`level_ball`) | ×1 si el activo no supera al objetivo, ×2 si lo supera, ×4 si alcanza el doble, ×8 si alcanza el cuádruple. Tasa modificada limitada a 255. |

`CaptureBattleContext` incorpora dos valores transitorios con centinela -1:
`completed_turns` y `catcher_level`. La falta de contexto rechaza el uso sin
gastar bola ni RNG; no se sustituye por turno cero o nivel del Pokémon más alto
del equipo. Veloz/Turno solo requieren turnos; Nivel solo requiere nivel activo.

Los dos dueños de sesión construyen esos valores desde sus estados vivos:
`ShowdownAdventureSession` usa el turno completado proyectado desde el checkpoint
nativo y el Pokémon activo; `WildAdventureSession` usa su servidor técnico y su
activo. La UI sigue enviando únicamente el ID de bola y la revisión/comando.
No acepta del selector turnos, niveles, probabilidades o resultados.

Después de cargar/restaurar, el contexto se vuelve a derivar del estado nativo;
no se persiste un contador adicional ni se cambia el esquema. Los lanzamientos
fallidos y otras acciones que consumen turno afectan al bonus de forma normal;
un rechazo por revisión incorrecta no lo hace.

`capture_context_ball_effects.gd` reúne las reglas puras y su validación.
`CaptureSystem` lo integra por el dispatcher existente. La selección nativa y
la presentación técnica reutilizan el catálogo ordenado, sin añadir reglas UI.
Las nueve bolas previas conservan su probabilidad y sus efectos.

## Verificación

Matriz independiente: 1.076 especies/formas permitidas × tres bolas × seis
contextos = **19.368 casos**. Compara probabilidad, resultado determinista,
una tirada RNG, una unidad de inventario, identidad y estado completo. Incluye
límites de turno, umbrales de Nivel y su límite de tasa, ausencia/contexto
inválido, entrenador, KO, inventario inexistente/corrupto y estado sin mutar.

La sesión técnica anterior prueba el primer y segundo intento con una reserva
de nivel mayor que el activo. En nativo, cada bola realiza un primer lanzamiento
fallido, se guarda/restaura y se comprueba de nuevo: Veloz pierde el bonus,
Turno alcanza diez turnos reales y Nivel usa un cambio real al Pokémon de nivel
100. La reserva no concede ese bonus antes del cambio. Las bolas se publican
una sola vez al finalizar; una revisión incorrecta no altera checkpoint/RNG.

La demo principal abre el selector, guarda/carga antes de actuar y lanza Veloz
conservando el bonus del primer turno. Se comprueban coste y captura reales.
GPU captura y verifica los controles dentro de la ventana.

La regresión V11 mantiene sus cinco bolas y sus aserciones de consumo, estados,
PP, sueño y guardado. Dos expectativas históricas se actualizan: Veloz/Turno
ahora se rechazan por contexto ausente en vez de ID desconocido; el tamaño del
selector sigue el catálogo actual. No se retiran sus comprobaciones.
Sus informes originales y los guards históricos no se reescriben.

```text
python tools/verification/run_capture_v12.py
```

El runner verifica núcleo, bolas anteriores V11, inventario/captura, interfaz
técnica, campo nativo, restauración y GPU, además de la pieza nueva. Manifiesto
propio e inmutable en `.godot/item_capture_v12/`, sin resellar fases anteriores.
Resultados, fuentes, hashes y límites: [ITEM_CAPTURE_V12.json](ITEM_CAPTURE_V12.json).

## Límites

Se admiten doce IDs de captura; siguen siendo 69 los efectos de uso fuera del
combate. No se conceden bolas ni se modifica la generación de botín.
Las sesiones de captura de este bloque son individuales; no se certifica una
futura captura en dobles con varios aliados activos. Permanecen pendientes la
fórmula oficial completa, críticas, tratamiento de Ultraentes, bolas con
contexto de ambiente/historial/tipos/género, metadatos de origen y otros sistemas.

Cierre: nueve grupos PASS; 58.185 comprobaciones headless y 58.187 GPU.
La matriz produjo 8.270 éxitos y 11.098 fallos deterministas, con estado,
inventario y RNG contrastados. Las pruebas V11 siguen pasando 32.405 checks.
