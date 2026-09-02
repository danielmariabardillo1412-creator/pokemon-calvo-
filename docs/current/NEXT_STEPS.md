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

CI sobre ese SHA:

- **18/18 workflows SUCCESS**;
- `Trainer Loadouts Tests`: **290 PASS / 0 FAIL**;
- C2d añade 10 checks de frontera/determinismo;
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

## Paso inmediato — C2e calibración antes de consumidores

**NO integrar todavía `TrainerTeamAnalyzer`.**

El siguiente bloque debe calibrar cómo convertir el vector continuo C2c en presencia de roles útil para análisis de roster, sin destruir el multirole ni mezclar valor estratégico.

Objetivos C2e:

1. conservar `role_scores_bp` y `intrinsic_evidence` como salidas separadas;
2. evitar un threshold global ingenuo como `score >= 7500`;
3. estudiar una regla determinista de `primary/secondary/confidence` basada en dominancia y margen entre ejes, no solo en `argmax`;
4. decidir si `bulky_physical`/`bulky_special` deben incorporar también una señal estructural de HP/bulk para que el nombre del rol no dependa únicamente del foco Defense/SpDef;
5. revisar el `support` saturado por efectos garantizados antes de usarlo como etiqueta discreta;
6. repetir el mismo audit DATA V3 y comparar distribuciones antes/después;
7. no tocar TeamAnalyzer, switching, search ni C3 en la misma tranche de calibración.

C2e debe preferir invariantes relacionales y métricas de distribución. No se congelarán thresholds por intuición hasta comprobarlos contra DATA V3 real.

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
