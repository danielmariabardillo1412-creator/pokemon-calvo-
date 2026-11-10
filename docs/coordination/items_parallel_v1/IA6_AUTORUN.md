# IA6 — ORDEN PERMANENTE ACTIVA W04 · TANDA 03

**IA6 HA REVISADO TU ENTREGA ANTERIOR Y PUBLICA AQUÍ LA NUEVA COLA COMPLETA.** Este archivo es tu punto fijo de entrada. Cuando recibas `p`, `sigue` o `continúa`: consulta la rama de GitHub, tu HEAD, esta nota y tu checkpoint; empieza en la primera fila pendiente de la **TANDA 03**, sin pedir permiso IA6 por cada fila. Tras completar 10, deja informe + CI real y STOP a esperar una TANDA nueva. No te limites a contestar «entendido».

**Rama autorizada:** `codex/calvo-items-20261104-w04-camp006`. **Protocolo maestro:** `docs/coordination/items_parallel_v1/AUTONOMY_V1/README.md` de `codex/calvo-items-20261101-arbitro`. **Orden central:** `docs/coordination/items_parallel_v1/AUTONOMY_V1/QUEUE_W04_TANDA_03.md` de árbitra. Esta copia tiene el mismo contenido y vale aunque cambie el contexto de la conversación.

No ejecutar en segundo plano ficticio: si un turno se agota, publicar checkpoint en GitHub y la siguiente `p` continúa. Un bloqueo de un productor compartido no te obliga a detener los otros hitos independientes: ticket, `BLOQUEADO`, próximo. Nunca presentar CI de otro SHA como actual ni fusionar `main`, V28, PR118 u otras ramas. Protecciones de archivos/funciones indicadas abajo son estrictas.

---

# IA6 W04 — AUTORUN TANDA 03: 56 identidades de forma regional canónicas
Rama: codex/calvo-items-20261104-w04-camp006.
Base CI TANDA02 42735277975 SUCCESS, SHA funcional 8c216c9c15dd028241cb664c99f06d79a81c5536. Piloto productor auténtico slowpoke_galar → form_id slowpoke-galar persistente en SaveV2, **no** cambio de forma por objeto ni evolución nueva. No volver a contar el piloto.
PROTOCOLO: autoriza 10 grupos sin consultar IA6 entre objetos. p/sigue reanuda la primera fila pendiente; registrar checkpoint, CI por SHA, cerrar informe AUTORUN_V3_FINAL.md. No main/V28/PR118 ni otras ramas.
## Fuente verificada
Archivo config/pokemon_variants_v1.json contiene **57 regional_species** con source_metadata.base_species_id, regional_form y source_pokemon_id. Excluida slowpoke_galar ya probada, quedan **56** variantes en **6 grupos de 6 + 4 de 5**. Verificar cada ID de PokeAPI pokemon/[source_pokemon_id]/pokemon-form, DefinitionCatalog y RandomlockContentPolicy antes de considerar positivo. No derivar form_id solo concatenando sin verificar. Listado canónico exacto:
| Fila | IDs autorizados |
|---|---|
| 01 | rattata_alola;raticate_alola;raichu_alola;sandshrew_alola;sandslash_alola;vulpix_alola |
| 02 | ninetales_alola;diglett_alola;dugtrio_alola;meowth_alola;persian_alola;geodude_alola |
| 03 | graveler_alola;golem_alola;grimer_alola;muk_alola;exeggutor_alola;marowak_alola |
| 04 | meowth_galar;ponyta_galar;rapidash_galar;slowbro_galar;farfetchd_galar;weezing_galar |
| 05 | mr_mime_galar;articuno_galar;zapdos_galar;moltres_galar;slowking_galar;corsola_galar |
| 06 | zigzagoon_galar;linoone_galar;darumaka_galar;darmanitan_galar_standard;yamask_galar;stunfisk_galar |
| 07 | growlithe_hisui;arcanine_hisui;voltorb_hisui;electrode_hisui;typhlosion_hisui |
| 08 | qwilfish_hisui;sneasel_hisui;samurott_hisui;lilligant_hisui;zorua_hisui |
| 09 | zoroark_hisui;braviary_hisui;sliggoo_hisui;goodra_hisui;avalugg_hisui |
| 10 | decidueye_hisui;tauros_paldea_combat_breed;tauros_paldea_blaze_breed;tauros_paldea_aqua_breed;wooper_paldea |
## Objetivo por cada especie
Generalizar el helper canonical_form_identity_w04.gd desde el único piloto a variantes reales autorizadas SIN inventar fuentes. Factory debe derivar form_id del CreatureSpecies canónico realmente elegido por encuentro/Factory, no de llamada de UI ni overrides arbitrarios. Para cada ID: validar fuente pokemon-form, species/base, metadata, política de contenido, from_dict/to_dict opcional, Party/Storage y guardado SaveV2, load legacy, rechazar forma de otra especie y valor corrupto. Godot positivo real desde WildEncounterSystem.resolve con tabla que incluye la especie regional **sin afirmar que un mapa jugable la ofrezca todavía**. Tests negativos de forma base, política excluida, forma inexistente, datos fuente incompletos. Mantener identidad, IV/EV, movimiento, habilidad, naturaleza efectiva si existe. Form_id de origen es distinto de transformación temporal y solo se serializa cuando corresponde.
## Ownership y bloqueos
Únicamente modules/creatures/progression/canonical_form_identity_w04.gd, CreatureFactory **solo derivación**, CreatureInstance **solo form_id opcional ya aprobado**, SaveGameData.validate **solo validador de form_id**, FieldNativeSave._valid_creature **solo guardia forma aditiva**, nuevos fixtures/runner/workflow W04. **NO** copiar otras funciones compartidas, no tocar naturaleza efectiva, SaveGameSerializer/Repository, status de captura, FieldItemService, EvolutionSystem, forma por objeto, fusion, golpe, reloj, giro, main/V28. IA3 tiene ledger de capturas en SaveGameData/FieldNativeSave y IA6 tiene naturaleza efectiva: cualquier integración conjunta es trabajo IA6 por diff localizado, nunca merge automático.
Si una de 56 especies no está permitida o falta fuente pokemon-form: BLOQUEADA con contrato y sigue; no falsear 56/56. No sumar estas 56 como objetos ni evoluciones; son identidades de forma nacidas desde una fuente regional auténtica. CI final con CAMP003/004/005/006 y TANDA02 y prueba positiva por cada forma permitida; reportar funcionales reales de 56 y pendientes.

