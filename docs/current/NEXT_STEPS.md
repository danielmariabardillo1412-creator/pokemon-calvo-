# SIGUIENTE TRABAJO

## Estado operativo actual — Trainer AI Random Cup pre-FASE34

La rama activa es:

`audit/trainer-ai-v3-random-cup-redesign-v1`

La modernización previa a FASE34 ha completado y certificado:

- C1 — `campaign_snapshot` seguro en `TrainerDecisionContext`;
- C1b — transporte sanitizado por `TrainerIntelligenceController`;
- C2a — fixtures/invariantes de role inference;
- C2b — evidencia intrínseca de capacidades;
- C2c — afinidades funcionales multirole `0..10000`.

C2d auditó C2c contra DATA V3 real. C2e está en calibración y todavía no autoriza consumidores.

`TrainerTeamAnalyzer`, switching/search con valor de campaña y C3 strategic value continúan sin integrar con la nueva inferencia.

Referencia temática:

`docs/project_book/TRAINER_AI.md`.

---

## C2d — auditoría real DATA V3

Antes de conectar consumidores se añadió una sonda estadística exclusivamente de test:

`TrainerRosterRoleRealDataTestSuite`

Probe:

`runtime_levelup_l50_neutral_probe_v1`

Características del probe:

- DATA V3 real comprometido en `data/normalized/pokemon_api.json`;
- nivel 50;
- IV 31 en todos los stats;
- EV 0;
- naturaleza neutral;
- hasta cuatro últimos movimientos `level_up` con nivel <= 50;
- únicamente movimientos `RUNTIME_SUPPORTED`;
- stats calculados con `StatCalculator` canónico.

**Este probe NO es una política Random Cup ni congela nivel/loadout del modo.** Solo sirve para evaluar la geometría de la normalización C2c sobre datos reales.

### Resultado del primer audit

SHA de tests/auditoría:

`9a6336c793b60b747c02dd1fa46b6ebf872ca78e`

PR temporal:

`#103 — Trainer AI Random Cup modernization — C2d real DATA V3 role audit`

CI sobre el HEAD final C2d:

- **18/18 workflows SUCCESS**;
- `Trainer Loadouts Tests`: **290 PASS / 0 FAIL**;
- 1.025 especies totales;
- 1.011 especies cubiertas por el probe;
- 14 sin movimiento elegible bajo esta sonda concreta.

Histograma usando únicamente como diagnóstico un umbral de afinidad `>= 7500`:

- 0 roles altos: 29 especies;
- 1 rol alto: 101;
- 2 roles altos: 312;
- 3 roles altos: 280;
- 4 roles altos: 210;
- 5 roles altos: 71;
- 6 roles altos: 8.

Por tanto:

- **569/1.011** especies tienen 3 o más roles `>= 7500`;
- **289/1.011** tienen 4 o más;
- el vector continuo funciona y conserva información multirole, pero un umbral global fijo de 7500 sería demasiado permisivo para derivar `primary/secondary roles`.

Empates en el score máximo:

- un único rol máximo: 512 especies;
- empate de 2: 428;
- empate de 3: 49;
- empate de 4: 15;
- empate de 5: 7.

Esto significa que casi la mitad de los casos cubiertos tienen más de un eje empatado en la afinidad máxima. Por ello no debe implementarse todavía un `primary_role_id` mediante simple `argmax` sin regla de confianza/margen.

### Separación afinidad vs magnitud confirmada

La auditoría también confirma por qué C2b y C2c deben permanecer separados.

Medianas absolutas del probe:

- `physical_bulk_signal`: 13.050;
- `special_bulk_signal`: 12.825.

Existen miembros con afinidad defensiva `>= 9000` pero magnitud absoluta igual o inferior a la mediana:

- 83 casos en bulk físico;
- 79 casos en bulk especial.

Ejemplos observados incluyen especies como `azurill`, `bidoof`, `bounsweet`, `burmy` o `blipbug`: pueden tener una **forma relativa** defensiva dentro de su propio perfil sin ser por ello tanques fuertes en términos absolutos.

Conclusión canónica:

- `role_scores_bp` = **afinidad/forma funcional relativa**;
- `intrinsic_evidence` C2b = **magnitud objetiva**;
- C3 deberá consumir ambas dimensiones;
- no convertir un `10000` de afinidad en “fuerza 10000”.

---

## C2e-a — auditoría jerárquica de etiquetas

Se añadió una segunda sonda exclusivamente de test:

`TrainerRosterRoleLabelCalibrationTestSuite`

Su objetivo no es congelar thresholds, sino comprobar qué parte de la ambigüedad de C2d nace de tratar todos los ejes como roles primarios equivalentes.

Hipótesis auditada:

- `fast_attacker` es un eje compuesto por construcción: `speed ∩ offense`;
- por ello puede ser más correcto tratarlo como descriptor/modificador secundario de un atacante que como competidor plano contra `physical_attacker` y `special_attacker` al elegir un rol primario.

Comparación sobre las mismas 1.011 especies elegibles:

- esquema plano de seis roles: **499** especies con empate múltiple en el máximo;
- candidatos primarios sin `fast_attacker`: **373** con empate múltiple;
- primario único plano: 512;
- primario único en la jerarquía provisional: **638**.

La jerarquía reduce por tanto 126 empates máximos, pero **no resuelve por sí sola la calibración**.

Prueba directa de la causa:

- en **318** especies `fast_attacker` es exactamente igual al mejor score ofensivo;
- **442** especies tienen `fast_attacker >= 7500`.

Esto confirma que una parte material de los empates era mecánica, derivada de que `fast_attacker` reutiliza la afinidad ofensiva como techo. La conclusión provisional es que `fast_attacker` encaja mejor como descriptor funcional secundario; todavía no se congela esta decisión en producción hasta cerrar el resto de C2e.

### Dominancia y margen

Entre las 638 especies con primario core único:

- margen >= 500 bp: 573;
- margen >= 1000 bp: 456;
- margen >= 1500 bp: 345;
- top >= 7500 y margen >= 1000: 446.

Estos números muestran que margen/dominancia sí aporta discriminación, pero no debe usarse como único criterio universal.

Distribución provisional de primarios únicos core:

- `physical_attacker`: 269;
- `special_attacker`: 141;
- `bulky_physical`: 94;
- `bulky_special`: 71;
- `support`: 63.

### Hallazgo principal pendiente: support

`support` sigue siendo la fuente de colisión más clara:

- `support` es máximo único solo en **63** especies;
- colisiona en el máximo con otro rol en **302** especies.

La explicación técnica probable está en C2c: `support = max(control_signal_bp, sustain_signal_bp)`. Un único efecto garantizado de control puede producir `10000`, aunque el resto del loadout sea claramente ofensivo. C2e no debe solucionar esto bajando un threshold a ojo; debe auditar primero semántica, frecuencia y coexistencia ofensiva de esas señales.

### Magnitud C2b sigue separada de la etiqueta

Medianas absolutas observadas por familia en esta sonda:

- `physical_attacker`: 16.280;
- `special_attacker`: 7.875;
- `bulky_physical`: 13.050;
- `bulky_special`: 12.825;
- `support`: 3.000.

De los 638 primarios core únicos, **74** tienen una magnitud absoluta igual o inferior a la mediana de su propia familia:

- physical attacker: 36;
- special attacker: 1;
- bulky physical: 19;
- bulky special: 18.

Esto NO invalida la etiqueta: un miembro puede ser principalmente físico o defensivo dentro de su propio perfil y, aun así, ser mediocre en magnitud absoluta. Precisamente por eso C3 debe valorar poder/escasez/valor estratégico por separado y no reinterpretar `primary_role_id` como fuerza.

Los percentiles/medianas usados aquí son **diagnóstico de corpus**, no thresholds runtime congelados.

---

## Paso inmediato — C2e-b auditoría de support antes de producción

**NO integrar todavía `TrainerTeamAnalyzer`.**

El siguiente bloque debe estudiar por qué `support` colisiona en 302 máximos y separar al menos:

1. control garantizado aislado dentro de un moveset ofensivo;
2. control recurrente o múltiple;
3. sustain real;
4. combinación control + sustain;
5. utilidad que coexiste con una ruta ofensiva dominante;
6. utilidad que constituye realmente la función central del miembro.

La auditoría debe usar `BattleEffectSpec` estructurado y DATA V3 real. No inferir semántica por nombres de movimientos.

Objetivo de C2e-b:

- decidir si `support` necesita una señal de **densidad/breadth de utilidad**, no solo el máximo de un efecto;
- comprobar si conviene separar una capacidad `utility/control/sustain` de la etiqueta discreta `support`;
- conservar self-setup fuera de support salvo evidencia adicional;
- no degradar control/sustain como capacidades: solo evitar que un efecto aislado monopolice la etiqueta primaria;
- volver a medir empates y distribución después de cualquier candidato de calibración;
- no tocar todavía TeamAnalyzer, switching, search ni C3.

Después de support, revisar si los ejes `bulky_physical/bulky_special` necesitan una calibración adicional de etiqueta. La magnitud absoluta seguirá perteneciendo a C2b/C3, no se mezclará silenciosamente con afinidad C2c.

---

## Después de C2e

Solo si la distribución queda razonablemente discriminativa:

1. integrar `TrainerTeamAnalyzer` con inferencia dinámica en una tranche separada;
2. mantener el flujo authored histórico con `role_id` donde corresponda;
3. iniciar C3 `TrainerRosterStrategicValueEvaluator` usando tanto afinidad como evidencia absoluta;
4. resolver las políticas de campaña que todavía bloqueen `permadeath_loss_cost_bp` completo;
5. integrar después switching/search;
6. construir corpus Random Cup multi-batalla antes de calibrar pesos de preservación/permadeath;
7. retomar FASE34 difficulty/expertise solo después de cerrar esta modernización.

Continúan fuera de alcance inmediato:

- MCTS o red neuronal sin bottleneck demostrado;
- mover `main`;
- crear una autoridad Random Cup ficticia solo para tests de Trainer AI;
- inventar reglas todavía abiertas de gameplay (duplicados, recuperación entre rondas, reposición, progresión, held items, etc.).
