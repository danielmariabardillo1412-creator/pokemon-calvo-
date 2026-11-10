#!/usr/bin/env python3
"""W04 CAMP005: contrato autoritativo trade+held -> nivel pendiente; no certifica conversion."""
import argparse
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "docs/coordination/items_parallel_v1"
ITEMS_01 = ("dragon_scale", "dubious_disc", "electirizer", "magmarizer")
ITEMS_02 = ("protector", "reaper_cloth", "prism_scale", "sachet", "up_grade")
ITEMS_03 = ("oval_stone", "dawn_stone", "peat_block")
ITEMS_04 = ("galarica_cuff", "galarica_wreath", "scroll_of_darkness", "scroll_of_waters")
ITEMS_05 = ("berry_sweet", "clover_sweet", "flower_sweet", "love_sweet", "ribbon_sweet", "star_sweet", "strawberry_sweet")
ITEMS_06 = ("whipped_dream", "leaders_crest")
ITEMS_07 = ("adamant_crystal", "blue_orb", "griseous_core", "lustrous_globe", "red_orb")
ITEMS_08 = ("dna_splicers", "reins_of_unity", "n_lunarizer_merge", "n_solarizer_merge")
ITEMS_09 = ("gracidea", "meteorite", "reveal_glass", "rotom_catalog", "zygarde_cube")
ITEMS_10 = ("chipped_pot", "cracked_pot", "masterpiece_teacup", "unremarkable_teacup", "sweet_apple", "tart_apple", "syrupy_apple")


def check_rows(path):
    with path.open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def routes_from_chain(node, source=None):
    target = node["species"]["name"].replace("-", "_")
    out = []
    if source is not None:
        for detail in node.get("evolution_details", []):
            out.append((source, target, detail))
    for successor in node.get("evolves_to", []):
        out.extend(routes_from_chain(successor, target))
    return out


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--ci", action="store_true")
    parser.parse_args()
    checks = 0

    def check(ok, reason):
        nonlocal checks
        if not ok:
            raise AssertionError(reason)
        checks += 1

    fixture = json.loads((ROOT / "tests/fixtures/parallel_items/w04_campaign_005.json").read_text(encoding="utf-8"))
    progress = check_rows(BASE / "reports/W04/CAMP_005_PROGRESO.csv")
    queue = check_rows(BASE / "CAMPAIGN_005_W04_QUEUE_APPROVED.csv")
    prior_scope = json.loads((ROOT / "docs/current/ITEM_SCOPE_V25.json").read_text(encoding="utf-8"))
    policy = json.loads((ROOT / "docs/current/ITEM_TRADE_RESTORATION_V27.json").read_text(encoding="utf-8"))
    selected = {row["id"]: row for row in check_rows(ROOT / "docs/current/RANDOMLOCK_ITEMS_BUILD_SCOPE_V2.csv")}
    held_profile = json.loads((ROOT / "modules/inventory/item_connections_v1.json").read_text(encoding="utf-8"))
    runner = (ROOT / "tests/gameplay/parallel_items_w04_campaign_005.gd").read_text(encoding="utf-8")
    evolution = (ROOT / "modules/creatures/progression/evolution_system.gd").read_text(encoding="utf-8")
    progression = (ROOT / "modules/creatures/progression/progression_system.gd").read_text(encoding="utf-8")
    field = (ROOT / "modules/inventory/field_item_service.gd").read_text(encoding="utf-8")

    check(fixture["worker"] == "W04" and fixture["campaign"] == "CAMP_005", "fixture identidad")
    check(len(fixture["blocks"]) == 10 and [x["block"] for x in fixture["blocks"]] == ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10"], "fixture acumulativo 01 a 10")
    check(len(queue) == 10 and queue[0]["ids"].split(";") == list(ITEMS_01), "cola oficial 01")
    check(len(progress) == 10 and [x["bloque"] for x in progress] == ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10"], "progreso bloques 01 a 10")
    check(progress[0]["ids"].split(";") == list(ITEMS_01) and progress[1]["ids"].split(";") == list(ITEMS_02) and progress[2]["ids"].split(";") == list(ITEMS_03) and progress[3]["ids"].split(";") == list(ITEMS_04) and progress[4]["ids"].split(";") == list(ITEMS_05) and progress[5]["ids"].split(";") == list(ITEMS_06) and progress[6]["ids"].split(";") == list(ITEMS_07) and progress[7]["ids"].split(";") == list(ITEMS_08) and progress[8]["ids"].split(";") == list(ITEMS_09) and progress[9]["ids"].split(";") == list(ITEMS_10), "progreso filas exactas")
    check(queue[9]["ids"].split(";") == list(ITEMS_10) and queue[9]["familia"] == "FORM_CONDITIONS", "cola final 10 aprobada")
    check(queue[8]["ids"].split(";") == list(ITEMS_09) and queue[8]["familia"] == "FORM_DEPENDENCY", "cola 09 aprobada")
    check(queue[7]["ids"].split(";") == list(ITEMS_08) and queue[7]["familia"] == "FORM_FUSION", "cola 08 aprobada")
    check(queue[6]["ids"].split(";") == list(ITEMS_07) and queue[6]["familia"] == "FORM_DEPENDENCY", "cola 07 aprobada")
    check(queue[5]["ids"].split(";") == list(ITEMS_06) and queue[5]["familia"] == "SPECIAL_EVOLUTION", "cola 06 aprobada")
    check(queue[4]["ids"].split(";") == list(ITEMS_05) and queue[4]["familia"] == "SPECIAL_EVOLUTION", "cola 05 aprobada")
    check(queue[3]["ids"].split(";") == list(ITEMS_04) and queue[3]["familia"] == "EVOLUTION_CONDITIONS", "cola bloque04 oficial")
    check(queue[2]["ids"].split(";") == list(ITEMS_03) and queue[2]["familia"] == "EVOLUTION_CONDITIONS", "cola 03 aprobada")
    check(queue[1]["ids"].split(";") == list(ITEMS_02) and queue[1]["familia"] == "TRADE_OBJECT_REPAIR", "cola oficial 02")
    check(fixture["blocks"][0]["ids"] == list(ITEMS_01) and fixture["blocks"][0]["family"] == "TRADE_OBJECT_REPAIR", "familia 01")
    check(len(fixture["blocks"][0]["pairs"]) == 4 and len(fixture["blocks"][1]["pairs"]) == 5, "nueve rutas exactas")
    check(fixture["blocks"][1]["ids"] == list(ITEMS_02) and fixture["blocks"][1]["family"] == "TRADE_OBJECT_REPAIR", "fixture 02 y familia")
    check(all(block["ids"] == [x["item_id"] for x in block["pairs"]] for block in fixture["blocks"][:2]), "fixture IDs y parejas congruentes")
    check(fixture["blocks"][2]["ids"] == list(ITEMS_03) and fixture["blocks"][2]["family"] == "EVOLUTION_CONDITIONS", "fixture 03 y familia")
    check(fixture["blocks"][2]["classification"] == "DEPENDENCIA_DE_CONDICIONES" and len(fixture["blocks"][2]["cases"]) == 4, "cuatro rutas con condiciones")
    check(fixture["blocks"][3]["ids"] == list(ITEMS_04) and fixture["blocks"][3]["family"] == "EVOLUTION_CONDITIONS", "fixture 04 autorizada")
    check(fixture["blocks"][3]["classification"] == "DEPENDENCIA_FORMA_REGIONAL" and len(fixture["blocks"][3]["cases"]) == 4, "cuatro contratos de formas")
    check(fixture["kind"] == "FUNCTIONAL_BACKLOG", "backlog previo, no nuevos IDs")

    check(policy["status"] == "PASS_V26_MISINTERPRETATION_CORRECTED", "norma V27")
    check(policy["future_evolution_implementation"] == "DEFERRED", "nivel aplazado V27")
    check(policy["level_values_selected"] is None, "niveles sin definir en V27")
    check(prior_scope["trade_level_conversion"]["levels_selected"] is None, "niveles sin definir en V25")
    check("Retain the original equipped evolution item" in policy["correct_future_rule"], "conservar item equipado")
    check(policy["evolution_code_changed"] is False and policy["canonical_data_changed"] is False, "norma aún sin parche")
    check(fixture["blocks"][0]["classification"] == "BLOQUEADO_POR_CONTRATO", "no declarar integración positiva")

    restored = set(policy["restored_ids"])
    candidate_by_id = {row["id"]: row for row in prior_scope["trade_item_candidates"]}
    normalized = []
    for pair in [pair for block in fixture["blocks"][:2] for pair in block["pairs"]]:
        item = pair["item_id"]
        source = pair["source"]
        target = pair["target"]
        check(item in ITEMS_01 + ITEMS_02 and item in restored, item + ": no restaurado")
        check(pair["approved_level"] is None and pair["held_item_required"] is True, item + ": requisito futuro")
        check(pair["original_trigger"] == "trade", item + ": disparador original")
        check(selected[item]["estado_contenido"] == "SELECCIONADO" and selected[item]["familia"] == "EVOLUTION", item + ": selección real")
        check(item in held_profile["holdable_ids"], item + ": equipamiento permitido")
        check(candidate_by_id[item]["currently_excluded"] is False, item + ": no volver a excluir")
        check(candidate_by_id[item]["trade_routes"] == [{"source": source, "target": target}], item + ": parejas aprobadas")
        chain_path = ROOT / f"data/api/v2/evolution-chain/{pair['evolution_chain']}/index.json"
        chain = json.loads(chain_path.read_text(encoding="utf-8"))
        matches = [(a, b, detail) for a, b, detail in routes_from_chain(chain["chain"])
                   if a == source and b == target and detail.get("held_item") is not None
                   and detail["held_item"]["name"] == pair["canonical_item"]]
        check(len(matches) == 1, item + ": ruta PokeAPI no es única")
        detail = matches[0][2]
        check(detail["trigger"]["name"] == "trade", item + ": PokeAPI no es intercambio")
        check(detail["min_level"] is None, item + ": PokeAPI no proporciona nivel de intercambio")
        check(not detail.get("known_move") and not detail.get("trade_species"), item + ": no inventar condición adicional")
        normalized.append(f"{source}:{item}:{target}")
    check(len(set(normalized)) == 9, "nueve rutas canónicas sin duplicados")

    # Condiciones de versión diferentes en una misma pareja. Evitar perder la
    # vía de belleza de Feebas al adaptar por nivel su vía de intercambio.
    feebas_chain = json.loads((ROOT / "data/api/v2/evolution-chain/178/index.json").read_text(encoding="utf-8"))
    paths = [(a,b,d) for a,b,d in routes_from_chain(feebas_chain["chain"]) if a == "feebas" and b == "milotic"]
    beauty = [d for _,_,d in paths if d["trigger"]["name"] == "level-up" and d.get("min_beauty") == 170]
    trade = [d for _,_,d in paths if d["trigger"]["name"] == "trade" and d.get("held_item", {}).get("name") == "prism-scale"]
    check(len(beauty) >= 1 and len(trade) == 1, "Feebas tiene rutas belleza e intercambio distintas")
    check(all(x.get("min_level") is None for x in beauty + trade), "Feebas no tiene umbral nivel de intercambio")
    check(all(x.get("version_group") for x in beauty + trade), "rutas Feebas se diferencian por versión")
    check(all(x.get("min_beauty") is None for x in trade), "no confundir Escama Bella y belleza")
    porygon_chain = json.loads((ROOT / "data/api/v2/evolution-chain/68/index.json").read_text(encoding="utf-8"))
    graph = routes_from_chain(porygon_chain["chain"])
    first = [d for a,b,d in graph if a == "porygon" and b == "porygon2" and d.get("held_item", {}).get("name") == "up-grade"]
    second = [d for a,b,d in graph if a == "porygon2" and b == "porygon_z" and d.get("held_item", {}).get("name") == "dubious-disc"]
    check(len(first) == 1 and len(second) == 1, "Porygon debe preservar dos etapas/objetos")
    check(not any(d.get("held_item", {}).get("name") == "up-grade" for a,b,d in graph if a == "porygon2"), "up-grade no debe saltar a Porygon-Z")
    check(not any(d.get("min_level") is not None for d in first + second), "dos niveles de intercambio aún sin aprobar")
    for token in ("func _casos_de_version_y_etapas_02(", "prism_scale/belleza_legacy_no_degradada",
                  "up_grade/dos_objetos_dos_etapas", "up_grade/porygon2_sin_opcion",
                  "up_grade/porygon2_no_evoluciona", "up_grade/porygon2_con_objeto_no_salta_etapa",
                  "up_grade/porygon2_retirada_sin_mutacion", "bloques_01_a_10_secuenciales",
                  "CAMP005_W04_ALT id=prism_scale", "CAMP005_W04_STAGE item=up_grade"):
        check(token in runner, "Falta contrato runtime del bloque 02: " + token)

    # Bloque 03: contrastar rutas originales de PokeAPI y no degradar condiciones.
    cases = fixture["blocks"][2]["cases"]
    required_ids = {case["item_id"] for case in cases}
    check(required_ids == set(ITEMS_03), "bloque03 exactamente tres objetos autorizados")
    check({(case["source"], case["target"]) for case in cases} == {
        ("happiny", "chansey"), ("kirlia", "gallade"),
        ("snorunt", "froslass"), ("ursaring", "ursaluna"),
    }, "origen/destino cuatro rutas")
    check(selected["oval_stone"]["familia"] == "EVOLUTION" and all(selected[i]["estado_contenido"] == "SELECCIONADO" for i in ITEMS_03), "objetos 03 seleccionados")
    profile = held_profile["holdable_ids"]
    check("oval_stone" in profile and "dawn_stone" in profile and "peat_block" not in profile, "perfil equipamiento 03")
    inventory = {row["id"]: row for row in check_rows(ROOT / "docs/current/ITEM_INVENTORY.csv")}
    check(inventory["peat_block"]["connection"] == "EVOLUTION_ELIGIBILITY_RULES_NO_BAG_BRIDGE", "turba sin puente de mochila")
    check("missing_description" in inventory["peat_block"]["flags"], "turba descripción pendiente")
    check(inventory["dawn_stone"]["evolution_links"] == "2", "dawn dos rutas de evolución")
    for case in cases:
        name = case["item_id"]
        chain = json.loads((ROOT / f"data/api/v2/evolution-chain/{case['chain']}/index.json").read_text(encoding="utf-8"))
        routes = [(src,dst,detail) for src,dst,detail in routes_from_chain(chain["chain"])
                  if src == case["source"] and dst == case["target"] and detail["trigger"]["name"] == case["trigger"]]
        if case["trigger"] == "use-item":
            routes = [x for x in routes if x[2].get("item", {}).get("name") == case["canonical_item"]]
        else:
            routes = [x for x in routes if x[2].get("held_item", {}).get("name") == case["canonical_item"]]
        check(len(routes) == 1, f"{name}/{case['source']}: ruta canónica única")
        d = routes[0][2]
        check(d["min_level"] is None, f"{name}/{case['source']}: no inventar nivel")
        requirement_value = d.get(case["key"])
        if case["key"] == "held_item":
            requirement_value = requirement_value.get("name") if requirement_value else None
        check(requirement_value == case["required"], f"{name}/{case['source']}: requisito canónico")
        if "additional_key" in case:
            check(d.get(case["additional_key"]) == case["additional_value"], name + " día exacto")
        check((name in profile) is case["equippable"], name + " perfil de equipamiento")
    check(any(case["key"] == "gender" and case["required"] == 2 for case in cases), "Kirlia macho requerido")
    check(any(case["key"] == "gender" and case["required"] == 1 for case in cases), "Snorunt hembra requerida")
    # The creature snapshot does not preserve a sex identifier, so a gender
    # condition cannot be implemented honestly from its current state.
    creature = (ROOT / "modules/creatures/domain/creature_instance.gd").read_text(encoding="utf-8")
    check("var gender:" not in creature and "var gender_id:" not in creature and '"gender":' not in creature, "género no persistido en dominio de criatura")
    check('"time_of_day":' not in evolution.split("static func level_up_context(",1)[1].split("static func _stat_relation_matches(",1)[0], "subida de nivel sin reloj")
    for token in ("func _auditar_condicion_03(", "func _tiene_destino_03(",
                  "bloques_01_a_10_secuenciales", "sin_opciones_directas",
                  "condicion_no_degradable", "no_ignora_condiciones", "sexo_no_persistido",
                  "contexto_sin_requisitos", "uso_rechazado_sin_gasto", "evolucion_rechazada",
                  "estado_savev2_integro", "retirada_sin_perdida", "no_equipable_sin_gasto",
                  "CAMP005_W04_ITEM id=", "status=DEPENDENCIA_CONDICIONES"):
        check(token in runner, "runner sin contrato 03 " + token)

    # Bloque 04: la forma regional y el estilo Urshifu son parte del
    # resultado del disparador; no se representan solo con species_id.
    form_cases = fixture["blocks"][3]["cases"]
    check([case["item_id"] for case in form_cases] == list(ITEMS_04), "cuatro ID de formas reservados")
    check({(case["source"], case["target"]) for case in form_cases} == {
        ("slowpoke", "slowbro"), ("slowpoke", "slowking"),
        ("kubfu", "urshifu"),
    }, "origen y especies destino sin forma artificial")
    inventory04 = {row["id"]: row for row in check_rows(ROOT / "docs/current/ITEM_INVENTORY.csv")}
    field04 = {row["id"]: row for row in check_rows(ROOT / "docs/current/ITEM_FIELD_V8.csv.txt")}
    check(all(selected[i]["estado_contenido"] == "SELECCIONADO" and selected[i]["familia"] == "EVOLUTION" for i in ITEMS_04), "cuatro objetos seleccionados antes")
    check(set(c["evolved_form"] for c in form_cases) == {
        "slowbro-galar","slowking-galar","urshifu-single-strike","urshifu-rapid-strike",
    }, "cuatro formas reales distintas")
    check({c["base_form"] for c in form_cases if c["source"] == "slowpoke"} == {"slowpoke-galar"}, "Slowpoke Galar es obligatorio")
    check({c["target"] for c in form_cases if c["source"] == "kubfu"} == {"urshifu"}, "Urshifu dos formas misma especie")
    for case in form_cases:
        name = case["item_id"]
        chain = json.loads((ROOT / f"data/api/v2/evolution-chain/{case['chain']}/index.json").read_text(encoding="utf-8"))
        matched = [d for src, dst, d in routes_from_chain(chain["chain"])
                   if src == case["source"] and dst == case["target"]
                   and d["trigger"]["name"] == "use-item" and (d.get("item") or {}).get("name") == case["canonical_item"]]
        check(len(matched) == 1, name + " ruta canónica única")
        d = matched[0]
        check(d["version_group"]["name"] == case["version"], name + " versión canónica")
        check(d["evolved_form"]["name"] == case["evolved_form"], name + " evolved_form requerido")
        check(d.get("min_level") is None, name + " sin nivel inventado")
        check(((d.get("base_form") or {}).get("name") == case.get("base_form")), name + " forma origen")
        check((name in held_profile["holdable_ids"]) is case["equippable"], name + " perfil holdable")
        check(inventory04[name]["connection"] == "EVOLUTION_ELIGIBILITY_RULES_NO_BAG_BRIDGE", name + " entrada sin puente")
        check("missing_description" in inventory04[name]["flags"], name + " metadatos pendientes")
        check(field04[name]["supported_evolution_routes_tested"] == "0", name + " ninguna forma positiva aún")
    chain470 = json.loads((ROOT / "data/api/v2/evolution-chain/470/index.json").read_text(encoding="utf-8"))
    tower_rows = [d for src,dst,d in routes_from_chain(chain470["chain"])
                  if src == "kubfu" and dst == "urshifu" and d["trigger"]["name"] in ("tower-of-darkness","tower-of-waters")]
    check(len(tower_rows) == 2, "dos torres alternativas de Isle of Armor")
    check({d["evolved_form"]["name"] for d in tower_rows} ==
          {"urshifu-single-strike","urshifu-rapid-strike"}, "torres no mezclan estilos")
    check(all(d["version_group"]["name"] == "the-isle-of-armor" for d in tower_rows), "torres son versión Isle of Armor")
    check(all(c["version"] == "scarlet-violet" for c in form_cases if c["source"] == "kubfu"), "manuscritos son Scarlet-Violet")
    # W04 TANDA02 migration whitelist: ONLY catalog-verified slowpoke_galar
    # may now have a persistent form. Historic fixture and item use remain frozen.
    # Positive real Factory/encounter/SaveV2 evidence is in
    # tests/gameplay/w04_autorun_v2_form_identity.gd; all original negative
    # gameplay form transitions below remain unchanged.
    FORM_ID_PROMOTION_WHITELIST = {"slowpoke_galar": "slowpoke-galar"}
    pilot = (ROOT / "modules/creatures/progression/canonical_form_identity_w04.gd").read_text(encoding="utf-8")
    factory = (ROOT / "modules/creatures/progression/creature_factory.gd").read_text(encoding="utf-8")
    check(FORM_ID_PROMOTION_WHITELIST == {"slowpoke_galar": "slowpoke-galar"}
          and 'var form_id: StringName = &""' in creature
          and '"slowpoke_galar": {"base": "slowpoke", "region": "galar", "pokemon_id": 10164}' in pilot
          and 'static func _api_form(' in pilot
          and 'catalogs.species(species.id) == species' in factory,
          "FORM_ID_PROMOTION_WHITELIST: only validated Galar Slowpoke can have persistent form")
    check('if form_id != &"": result["form_id"] = String(form_id)' in creature
          and '"regional_form_id":' not in creature
          and 'var decoration_id:' not in creature,
          "SaveV2 optional form pilot, no regional/form/item blanket acceptance")
    for token in ("func _auditar_forma_04(", "func _fronteras_regionales_04(",
                  "04_base_regional", "04_forma_destino", "04_evolucion_normal_nivel_sigue_disponible", "04_urshifu_estilos_distintos_igual_especie",
                  "04_galar_regional_dos_destinos", "04_torre_sombras_no_simplificada",
                  "04_torre_agua_no_simplificada", "04_no_destino_sin_forma",
                  "04_no_uso_incondicional", "04_forma_no_inventada_savev2",
                  "04_retira_y_restaura", "04_no_equipable_sin_mutacion",
                  "04_forma_persistente_no_contratada", "CAMP005_W04_FORM_CONTRACT",
                  "bloques_01_a_10_secuenciales", "CAMP005_W04_GODOT PASS blocks=10 checks="):
        check(token in runner, "falta escenario Godot de forma04: " + token)

    # Bloque 05: siete confites seleccionados, pero una sola evolucion original SPIN.
    # No atribuir a PokeAPI una seleccion de confite que NO codifica esa cadena.
    confites = fixture["blocks"][4]
    casos05 = confites["cases"]
    check(confites["ids"] == list(ITEMS_05) and confites["family"] == "SPECIAL_EVOLUTION", "siete confites reservados")
    check(confites["classification"] == "DEPENDENCIA_GIRO_FORMA" and len(casos05) == 7, "dependencia de forma documentada")
    check([x["item_id"] for x in casos05] == list(ITEMS_05), "siete IDs exactos en fixture")
    check(all(x["source"] == "milcery" and x["target"] == "alcremie" and x["trigger"] == "spin" for x in casos05), "sin evolucion alternativa")
    check(all(selected[i]["familia"] == "EVOLUTION" and selected[i]["estado_contenido"] == "SELECCIONADO" for i in ITEMS_05), "siete ya seleccionados")
    check(all(i in held_profile["holdable_ids"] for i in ITEMS_05), "siete equipables")
    check(all(x["equippable"] is True and x["requires_held_sweet"] is True for x in casos05), "equipar confite antes del giro")
    check(all(x["canonical_item"] == x["item_id"].replace("_", "-") for x in casos05), "slug canónico de los confites")
    check(confites["evolution_chain"] == "452" and confites["version"] == "sword-shield", "procedencia giro")
    chain452 = json.loads((ROOT / "data/api/v2/evolution-chain/452/index.json").read_text(encoding="utf-8"))
    rutas_spin = [d for src, dst, d in routes_from_chain(chain452["chain"])
                  if src == "milcery" and dst == "alcremie" and d["trigger"]["name"] == "spin"]
    check(len(rutas_spin) == 1, "una sola ruta Milcery Alcremie por spin")
    d = rutas_spin[0]
    check(d["version_group"]["name"] == "sword-shield", "spin Sword Shield")
    check(d["item"] is None and d["held_item"] is None and d["min_level"] is None, "PokeAPI no aporta siete rutas ni umbral")
    check(d["time_of_day"] in (None, ""), "PokeAPI no fija horario de forma")
    check('&"spin"' in evolution and "UNSUPPORTED_TRIGGERS" in evolution, "trigger spin explicitamente no implementado")
    check("var held_item_id:" in creature and "var held_item_consumed:" in creature, "el objeto equipado persiste")
    check('"slowpoke_galar": {"base": "slowpoke", "region": "galar", "pokemon_id": 10164}' in pilot
          and 'alcremie' not in pilot.lower()
          and 'var decoration_id:' not in creature
          and '"decoration_id":' not in creature,
          "Alcremie still has NO form producer; exact Slowpoke Galar pilot only")
    for token in ("func _auditar_confite_05(", "05_ruta_spin_real_unica",
                  "05_giro_no_disfrazado_de_use_item", "05_equipar", "05_uso_rechazado_sin_gasto",
                  "05_ajeno_sin_gasto", "05_sin_consumo_tras_equipar", "05_sin_forma_por_evolve",
                  "05_guardar_savev2", "05_cargar_savev2", "05_identidad_confite_savev2",
                  "05_atributos_savev2", "05_retirada_restaurada", "05_siete_confites_exactos",
                  "bloques_01_a_10_secuenciales", "CAMP005_W04_GODOT PASS blocks=10 checks="):
        check(token in runner, "Godot sin contrato observable confites: " + token)

    # Bloque06: dos rutas muy distintas. Whipped Dream mantiene trade+held_item
    # y espera los niveles oficiales V27; Leader's Crest no es uso de mochila,
    # sino derrotas cualificadas que el motor aún no almacena.
    specials = fixture["blocks"][5]
    cases06 = specials["cases"]
    check(specials["family"] == "SPECIAL_EVOLUTION" and specials["ids"] == list(ITEMS_06), "cola bloque06 exacta")
    check(specials["classification"] == "DEPENDENCIA_INTERCAMBIO_Y_COMBATE" and len(cases06) == 2, "dependencia doble diferenciada")
    check([r["item_id"] for r in cases06] == list(ITEMS_06), "casos y orden autorizados")
    check({r["item_id"]: (r["source"], r["target"]) for r in cases06} == {
        "whipped_dream": ("swirlix", "slurpuff"),
        "leaders_crest": ("bisharp", "kingambit"),
    }, "parejas originales exactas")
    check(all(selected[item]["estado_contenido"] == "SELECCIONADO" for item in ITEMS_06), "dos objetos seleccionados")
    check(selected["whipped_dream"]["familia"] == "EVOLUTION", "dulce de nata familia original")
    check(selected["leaders_crest"]["familia"] == "FOOD_OR_PICNIC_ACTIVITY", "discrepancia catalogo no ocultada")
    check(("whipped_dream" in held_profile["holdable_ids"]) and
          ("leaders_crest" not in held_profile["holdable_ids"]), "equipamiento real distinto")
    for r in cases06:
        name = r["item_id"]
        chain = json.loads((ROOT / f"data/api/v2/evolution-chain/{r['evolution_chain']}/index.json").read_text(encoding="utf-8"))
        routes = [(src, dst, d) for src, dst, d in routes_from_chain(chain["chain"])
                  if src == r["source"] and dst == r["target"]
                  and d["trigger"]["name"] == r["original_trigger"]]
        check(len(routes) == 1, name + ": ruta y trigger canónico único")
        d = routes[0][2]
        check(d["version_group"]["name"] == r["version"], name + ": versión canónica")
        check(d["min_level"] is None and r["approved_level"] is None, name + ": no inventar mínimo")
        check(d["item"] is None, name + ": no trigger item de mochila")
        check(r["canonical_item"] == name.replace("_", "-"), name + ": alias item no inventado")
        check(r["holdable"] == (name == "whipped_dream"), name + ": perfil reconocido")
        if name == "whipped_dream":
            check(d["held_item"]["name"] == "whipped-dream" and r["held_item_required"] is True,
                  "swirlix exige dulce equipado en intercambio")
            check(name in policy["restored_ids"] and policy["level_values_selected"] is None
                  and policy["future_evolution_implementation"] == "DEFERRED",
                  "V27 no autoriza umbral de Swirlix")
        else:
            check(d["held_item"] is None and r["held_item_required"] is False,
                  "tres derrotas no exige leaders_crest equipado en el registro")
            check(d["trigger"]["name"] == "three-defeated-bisharp",
                  "ruta Kingambit: tres derrotas")
    chain317 = json.loads((ROOT / "data/api/v2/evolution-chain/317/index.json").read_text(encoding="utf-8"))
    former = [d for src, dst, d in routes_from_chain(chain317["chain"])
              if src == "pawniard" and dst == "bisharp" and d["trigger"]["name"] == "level-up"]
    check(len(former) == 1 and former[0]["min_level"] == 52,
          "nivel52 solo Pawniard-a-Bisharp; no corresponde a Kingambit")
    check('&"three_defeated_bisharp"' in evolution and "UNSUPPORTED_TRIGGERS" in evolution,
          "motor clasifica correctamente evento especial como unsupported")
    check('"held_item":' not in evolution.split("static func level_up_context(", 1)[1].split("static func _stat_relation_matches(", 1)[0],
          "level_up_context sin contrato held-item")
    for token in ("func _auditar_especial_06(", "06_registro_especifico_unico",
                  "06_trade_requiere_confite_equipado", "06_tres_derrotas_no_implementadas",
                  "06_nivel52_solo_pawniard_bisharp", "06_no_convertir_a_nivel_arbitrario",
                  "06_contexto_inventado_no_habilita", "06_equipar_segun_perfil",
                  "06_uso_bolsa_rechazado_sin_consumo", "06_evolve_rechazado_sin_consumo",
                  "06_ajeno_rechazado", "06_sin_intercambio_ni_tres_derrotas_falsas",
                  "06_guardar_savev2", "06_cargar_savev2", "06_identidad_y_stock_savev2",
                  "06_atributos_savev2", "06_retirar_sin_perder", "06_no_equipable_inmutable",
                  "06_dos_objetos_exactos", "bloques_01_a_10_secuenciales",
                  "CAMP005_W04_GODOT PASS blocks=10 checks="):
        check(token in runner, "faltan aserciones Godot bloque06: " + token)

    # Bloque 07: formas Origin y Primal son variedades de la MISMA especie,
    # no cinco evoluciones ni cinco acciones de mochila.
    form_block = fixture["blocks"][6]
    form_cases = form_block["cases"]
    check(form_block["ids"] == list(ITEMS_07) and form_block["family"] == "FORM_DEPENDENCY", "bloque07 reserva exacta")
    check(form_block["classification"] == "DEPENDENCIA_FORMA_EQUIPABLE" and len(form_cases) == 5, "cinco casos origen/primal")
    check([row["item_id"] for row in form_cases] == list(ITEMS_07), "cinco IDs sin duplicados")
    expected_forms = {
        "adamant_crystal": ("dialga", "dialga-origin", "origin_held", "dialga"),
        "blue_orb": ("kyogre", "kyogre-primal", "primal_on_switch", "kyogre"),
        "griseous_core": ("giratina", "giratina-origin", "origin_held", "giratina-altered"),
        "lustrous_globe": ("palkia", "palkia-origin", "origin_held", "palkia"),
        "red_orb": ("groudon", "groudon-primal", "primal_on_switch", "groudon"),
    }
    check({c["item_id"]: (c["source_species"], c["target_variety"], c["route_kind"], c["base_variety"]) for c in form_cases} == expected_forms,
          "asociacion de 5 especies y variedades, sin cruzar prismas")
    check(all(selected[i]["familia"] == "STORY_KEY_OR_FORM_REVIEW" and
              selected[i]["estado_contenido"] == "SELECCIONADO" for i in ITEMS_07),
          "familia de forma y seleccion previa del catalogo")
    check(all(i in held_profile["holdable_ids"] for i in ITEMS_07), "cinco objetos equipables")
    form_inventory = {row["id"]: row for row in check_rows(ROOT / "docs/current/ITEM_INVENTORY.csv")}
    form_field = {row["id"]: row for row in check_rows(ROOT / "docs/current/ITEM_FIELD_V8.csv.txt")}
    check(all(form_field[i]["supported_evolution_routes_tested"] == "0" for i in ITEMS_07), "no hay rutas de evolucion certificadas")
    check(all(form_inventory[i]["connection"] == "NATIVE_ENTRY_REQUIRES_EFFECT_CASE" for i in ITEMS_07),
          "sin efecto final de forma previamente verificado")
    for row in form_cases:
        name = row["item_id"]
        source_path = ROOT / f"data/api/v2/pokemon-species/{row['species_number']}/index.json"
        canonical = json.loads(source_path.read_text(encoding="utf-8"))
        check(canonical["name"] == row["source_species"], name + ": especie real de PokeAPI")
        check(canonical["forms_switchable"] is row["forms_switchable"], name + ": metadato forms_switchable real")
        check(canonical["evolution_chain"]["url"] == f"/api/v2/evolution-chain/{row['chain_id']}/",
              name + ": cadena original")
        varieties = canonical["varieties"]
        check(sum(v["pokemon"]["name"] == row["base_variety"] and v["is_default"] for v in varieties) == 1,
              name + ": variedad por defecto correcta")
        check(sum(v["pokemon"]["name"] == row["target_variety"] and not v["is_default"] for v in varieties) == 1,
              name + ": variedad especial presente (no especie nueva)")
        chain = json.loads((ROOT / f"data/api/v2/evolution-chain/{row['chain_id']}/index.json").read_text(encoding="utf-8"))
        check(chain["chain"]["species"]["name"] == row["source_species"] and
              chain["chain"]["evolves_to"] == [] and chain["chain"]["evolution_details"] == [],
              name + ": cadena sin evolución genuina")
        check(row["holdable"] is True, name + ": equipamiento contratado")
    creature_form = (ROOT / "modules/creatures/domain/creature_instance.gd").read_text(encoding="utf-8")
    check("var held_item_id:" in creature_form and '"held_item_id":' in creature_form, "SaveV2 conserva objeto equipado")
    check('static func _api_form(' in pilot
          and not any(s in creature_form for s in ('"variant_id":', '"primal_form_id":')),
          "no origin/primal item source despite one whitelisted regional form")
    check("func base_species_id(" in creature_form and "battle_transform_original" in creature_form,
          "existe restauracion temporal de combate, NO equivale a puente para los 5 objetos")
    check("func equip(" in field and "func unequip(" in field and "func evolution_options(" in field,
          "FieldItemService permite equipamiento pero no ruta de formas")
    for token in ("func _auditar_forma_equipable_07(", "func _cruce_prismas_07(",
                  "07_variedades_default_y_alterna", "07_forma_no_evolucion_especie",
                  "07_sin_evoluciones_de_cadena", "07_equipar_positivo",
                  "07_equipamiento_sin_cambio_especie", "07_forma_no_persistida",
                  "07_bolsa_no_activa_forma", "07_evolve_no_es_forma",
                  "07_uso_equipado_no_transforma", "07_guardar_savev2",
                  "07_cargar_savev2", "07_identidad_y_stock_savev2",
                  "07_atributos_savev2", "07_retirar_y_restaurar",
                  "07_cruce_equipamiento_generico_no_seleccion_forma",
                  "07_prisma_no_cambia_especie_ajena", "07_cinco_objetos_exactos",
                  "bloques_01_a_10_secuenciales", "CAMP005_W04_ORB_CROSS",
                  "CAMP005_W04_GODOT PASS blocks=10 checks="):
        check(token in runner, "bloque07 no comprueba escenario real: " + token)


    # Bloque 08: la pareja fusionada debe conservar DOS identidades propietarias,
    # no solo forma del origen; PokeAPI ofrece variedades, NO una cadena evolutiva.
    fusion = fixture["blocks"][7]
    pairs = fusion["cases"]
    check(fusion["ids"] == list(ITEMS_08) and fusion["family"] == "FORM_FUSION", "bloque08 cuatro IDs propios")
    check(fusion["classification"] == "DEPENDENCIA_FUSION_DOS_PROPIETARIOS" and len(pairs) == 6, "seis escenarios, dependencia concreta")
    check({p["item_id"] for p in pairs} == set(ITEMS_08), "cuatro items sin otros ID")
    expected_pairs = {
        ("dna_splicers", "kyurem", "zekrom", "kyurem-black"),
        ("dna_splicers", "kyurem", "reshiram", "kyurem-white"),
        ("reins_of_unity", "calyrex", "glastrier", "calyrex-ice"),
        ("reins_of_unity", "calyrex", "spectrier", "calyrex-shadow"),
        ("n_lunarizer_merge", "necrozma", "lunala", "necrozma-dawn"),
        ("n_solarizer_merge", "necrozma", "solgaleo", "necrozma-dusk"),
    }
    check({(p["item_id"], p["source"], p["partner"], p["target_variety"]) for p in pairs} == expected_pairs,
          "partner y variedad correctos, sin confundir fusión ni reversibilidad")
    check(len(set((p["item_id"], p["source"], p["partner"]) for p in pairs)) == 6, "seis parejas únicas")
    check(set(p["item_id"] for p in pairs if p["partner_storage"]) == {
        "dna_splicers", "reins_of_unity", "n_lunarizer_merge"
    }, "segundo propietario en PC cubierto por casos reales")
    check(all(selected[i]["estado_contenido"] == "SELECCIONADO" for i in ITEMS_08),
          "cuatro elementos del backlog seleccionados")
    check(selected["dna_splicers"]["familia"] == "STORY_KEY_OR_FORM_REVIEW" and
          selected["reins_of_unity"]["familia"] == "STORY_KEY_OR_FORM_REVIEW" and
          selected["n_lunarizer_merge"]["familia"] == "LEGACY_OR_CATEGORY_REVIEW" and
          selected["n_solarizer_merge"]["familia"] == "LEGACY_OR_CATEGORY_REVIEW",
          "diferencia canonical y legacy conservada")
    check(all(i not in held_profile["holdable_ids"] for i in ITEMS_08),
          "ninguna de cuatro herramientas es equipable")
    fusion_field = {r["id"]: r for r in check_rows(ROOT / "docs/current/ITEM_FIELD_V8.csv.txt")}
    fusion_inventory = {r["id"]: r for r in check_rows(ROOT / "docs/current/ITEM_INVENTORY.csv")}
    check(all(fusion_field[i]["equipment_transfer"] == "NOT_CERTIFIED" and fusion_field[i]["supported_evolution_routes_tested"] == "0" for i in ITEMS_08),
          "fusion sin puente de campo certificado")
    check(all(fusion_inventory[i]["connection"] == "DATA_ONLY" for i in ITEMS_08),
          "fuente de fusion en inventario data_only")
    partner_numbers = {
        "zekrom": 644, "reshiram": 643, "glastrier": 896,
        "spectrier": 897, "lunala": 792, "solgaleo": 791,
    }
    for p in pairs:
        name = p["item_id"] + "/" + p["partner"]
        source_data = json.loads((ROOT / f"data/api/v2/pokemon-species/{p['species_number']}/index.json").read_text(encoding="utf-8"))
        check(source_data["name"] == p["source"], name + ": especie titular canónica")
        check(sum(v["pokemon"]["name"] == p["target_variety"] and not v["is_default"] for v in source_data["varieties"]) == 1,
              name + ": forma alternativa presente realmente")
        check(source_data["evolution_chain"]["url"] == f"/api/v2/evolution-chain/{p['evolution_chain']}/",
              name + ": cadena origen referenciada")
        chain = json.loads((ROOT / f"data/api/v2/evolution-chain/{p['evolution_chain']}/index.json").read_text(encoding="utf-8"))
        check(chain["chain"]["species"]["name"] == p["source"] and chain["chain"]["evolves_to"] == [],
              name + ": fusion no es evolucion")
        partner_data = json.loads((ROOT / f"data/api/v2/pokemon-species/{partner_numbers[p['partner']]}/index.json").read_text(encoding="utf-8"))
        check(partner_data["name"] == p["partner"], name + ": pareja real documentada como especie")
    save_source = (ROOT / "modules/save/save_game_data.gd").read_text(encoding="utf-8")
    collection_source = (ROOT / "modules/creatures/storage/player_collection.gd").read_text(encoding="utf-8")
    check("var creatures: Variant = []" in save_source and '"creatures": creatures' in save_source,
          "SaveV2 tiene registro de objetos CreatureInstance individuales")
    check("duplicate_creature_id" in save_source and "double_ownership" in save_source,
          "SaveV2 rechaza identidades duplicadas y doble propiedad")
    check("func deposit(" in collection_source and "func owned_creature(" in collection_source and
          "func location_of(" in collection_source, "agregado permite party y PC sin inventar api")
    check('func fuse(' not in field and 'func unfuse(' not in field,
          "FieldItemService carece de transaccion de fusion y reversión")
    for token in ("func _auditar_fusion_08(", "08_forma_fusion_canonica",
                  "08_fusion_no_es_evolucion", "08_criatura_socia", "08_socio_depositado_pc",
                  "08_dos_identidades_sin_duplicacion", "08_no_api_fusion_dos_criaturas",
                  "08_savev2_registro_doble_valido", "08_registro_dos_ids_exactos",
                  "08_no_fusion_mochila_principal", "08_no_fusion_mochila_socio",
                  "08_no_fusion_por_evolve", "08_no_fusion_por_equipar",
                  "08_ajeno_sin_gasto", "08_dos_especies_intactas_y_sin_consumo",
                  "08_guardar_doble_savev2", "08_recuperar_doble_savev2",
                  "08_recuperar_dos_especies_identidades", "08_pc_o_party_sin_duplicacion",
                  "08_principal_persistencia_completa", "08_socio_persistencia_completa",
                  "08_estado_inalterado_cero_fusiones", "08_seis_parejas_cuatro_objetos",
                  "bloques_01_a_10_secuenciales", "CAMP005_W04_FUSION",
                  "CAMP005_W04_GODOT PASS blocks=10 checks="):
        check(token in runner, "ausencia de test observable bloque08: " + token)


    # Bloque 09: cinco herramientas para ocho especies con múltiples alternativas,
    # pero ninguna de las ocho cadenas contiene evolución causada por el objeto.
    active_forms = fixture["blocks"][8]
    cases09 = active_forms["cases"]
    check(active_forms["ids"] == list(ITEMS_09) and active_forms["family"] == "FORM_DEPENDENCY",
          "reserva exacta 09")
    check(active_forms["classification"] == "DEPENDENCIA_FORMAS_ACTIVAS_Y_RESTAURACION"
          and len(cases09) == 8, "cinco objetos / ocho especies")
    check({row["item_id"] for row in cases09} == set(ITEMS_09), "cinco IDs exactos")
    check({row["source_species"] for row in cases09} ==
          {"shaymin", "deoxys", "tornadus", "thundurus", "landorus", "enamorus", "rotom", "zygarde"},
          "ocho especies distintas sin mezclas")
    forms09 = {
        "gracidea": {"shaymin": ("shaymin-land", {"shaymin-sky"})},
        "meteorite": {"deoxys": ("deoxys-normal", {"deoxys-attack", "deoxys-defense", "deoxys-speed"})},
        "reveal_glass": {
            "tornadus": ("tornadus-incarnate", {"tornadus-therian"}),
            "thundurus": ("thundurus-incarnate", {"thundurus-therian"}),
            "landorus": ("landorus-incarnate", {"landorus-therian"}),
            "enamorus": ("enamorus-incarnate", {"enamorus-therian"}),
        },
        "rotom_catalog": {"rotom": ("rotom", {"rotom-heat", "rotom-wash", "rotom-frost", "rotom-fan", "rotom-mow"})},
        "zygarde_cube": {"zygarde": ("zygarde-50",
            {"zygarde-10", "zygarde-10-power-construct", "zygarde-50-power-construct", "zygarde-complete"})},
    }
    check(set(forms09) == set(ITEMS_09), "mapeo reglas completo")
    check(all(selected[item]["estado_contenido"] == "SELECCIONADO" and
              selected[item]["familia"] == "STORY_KEY_OR_FORM_REVIEW" for item in ITEMS_09),
          "cinco elementos backlog seleccionados de forma")
    check(all(item not in held_profile["holdable_ids"] for item in ITEMS_09),
          "cinco herramientas NO equipables")
    active_inventory = {r["id"]: r for r in check_rows(ROOT / "docs/current/ITEM_INVENTORY.csv")}
    active_field = {r["id"]: r for r in check_rows(ROOT / "docs/current/ITEM_FIELD_V8.csv.txt")}
    check(all(active_inventory[item]["connection"] == "DATA_ONLY" for item in ITEMS_09),
          "no existen cinco implementaciones nativas completas")
    check(all(active_field[item]["equipment_transfer"] == "NOT_CERTIFIED" and
              active_field[item]["supported_evolution_routes_tested"] == "0" for item in ITEMS_09),
          "no hay transferencia o evolución certificada")
    for row in cases09:
        name = row["item_id"] + "/" + row["source_species"]
        base, targets = forms09[row["item_id"]][row["source_species"]]
        check(row["base_variety"] == base and set(row["target_varieties"]) == targets and
              len(row["target_varieties"]) == len(targets), name + ": destinos exactos")
        source = json.loads((ROOT / f"data/api/v2/pokemon-species/{row['species_number']}/index.json").read_text(encoding="utf-8"))
        check(source["name"] == row["source_species"] and source["forms_switchable"] is row["forms_switchable"],
              name + ": snapshot especies y forms_switchable")
        check(source["evolution_chain"]["url"] == f"/api/v2/evolution-chain/{row['evolution_chain']}/",
              name + ": cadena correcta")
        varieties = source["varieties"]
        check(sum(v["pokemon"]["name"] == base and v["is_default"] for v in varieties) == 1,
              name + ": variedad base única")
        for target in targets:
            check(sum(v["pokemon"]["name"] == target and not v["is_default"] for v in varieties) == 1,
                  name + ": variedad opcional " + target)
        chain = json.loads((ROOT / f"data/api/v2/evolution-chain/{row['evolution_chain']}/index.json").read_text(encoding="utf-8"))
        check(chain["chain"]["species"]["name"] == row["source_species"] and
              chain["chain"]["evolves_to"] == [], name + ": no es evolución")
    zygarde = next(p for p in cases09 if p["item_id"] == "zygarde_cube")
    check(zygarde["forms_switchable"] is False and "zygarde-complete" in zygarde["target_varieties"] and
          zygarde["route_kind"] == "cell_assembly_and_power_construct_distinct",
          "Zygarde Complete es batalla Power Construct, no boton directo del Arca")
    check("zygarde-mega" not in zygarde["target_varieties"],
          "no insertar una mega ruta sin encargo")
    rotom = next(p for p in cases09 if p["item_id"] == "rotom_catalog")
    check(len(rotom["target_varieties"]) == 5 and "appliance" in rotom["route_kind"],
          "Rotom exige seleccionar electrodoméstico y contrato movimientos")
    creature_form09 = (ROOT / "modules/creatures/domain/creature_instance.gd").read_text(encoding="utf-8")
    check("battle_transform_original" in creature_form09 and
          '"slowpoke_galar": {"base": "slowpoke", "region": "galar", "pokemon_id": 10164}' in pilot and
          all(s not in creature_form09 for s in ('"form_variant_id":', '"cells_count":')),
          "Galar pilot does not invent Zygarde form/cell state")
    check("func evolution_options(" in field and "func use_item(" in field and "func equip(" in field,
          "rutas del servicio prueban rechazo, no activación de forma")
    for token in ("func _auditar_cambio_forma_09(",
                  "09_fuente_especie", "09_forms_switchable_no_inventado",
                  "09_base_y_destinos_declarados", "09_destino_variedad_",
                  "09_cambio_forma_no_evolucion", "09_sin_evolucion_runtime",
                  "09_complete_no_direct_cube", "09_propiedad_party_pc",
                  "09_no_equipable", "09_no_evolucion_mochila",
                  "09_uso_campo_rechazado", "09_equipar_rechazado",
                  "09_evolve_no_es_forma", "09_ajeno_sin_consumo",
                  "09_especie_y_batalla_intactas", "09_inventario_y_lugar_intactos",
                  "09_savev2_unico_id_valido", "09_no_inventar_esquema_forma",
                  "09_guardar_savev2", "09_cargar_savev2",
                  "09_identidad_lugar_inventario_savev2", "09_atributos_savev2",
                  "09_estado_final_identico", "09_ocho_especies_cinco_objetos",
                  "bloques_01_a_10_secuenciales", "CAMP005_W04_FORM",
                  "CAMP005_W04_GODOT PASS blocks=10 checks="):
        check(token in runner, "falta escenario Godot 09: " + token)


    # Bloque 10: siete rutas use-item YA positivas; controlar que esas
    # transiciones de especie no se confundan con validación de autenticidad.
    terminal = fixture["blocks"][9]
    last_cases = terminal["cases"]
    check(terminal["ids"] == list(ITEMS_10) and terminal["family"] == "FORM_CONDITIONS",
          "siete IDs finales exactamente autorizados")
    check(terminal["classification"] == "RUTAS_POSITIVAS_Y_FORMA_NO_PERSISTIDA"
          and len(last_cases) == 7, "rutas conocidas frente a forma pendiente")
    check([r["item_id"] for r in last_cases] == list(ITEMS_10),
          "orden único de siete rutas")
    expected = {
        "chipped_pot": ("sinistea", "polteageist", 449, "sword-shield", "antique"),
        "cracked_pot": ("sinistea", "polteageist", 449, "sword-shield", "phony"),
        "masterpiece_teacup": ("poltchageist", "sinistcha", 539, "the-teal-mask", "artisan"),
        "unremarkable_teacup": ("poltchageist", "sinistcha", 539, "the-teal-mask", "counterfeit"),
        "sweet_apple": ("applin", "appletun", 442, "sword-shield", None),
        "tart_apple": ("applin", "flapple", 442, "sword-shield", None),
        "syrupy_apple": ("applin", "dipplin", 442, "the-teal-mask", None),
    }
    check({r["item_id"]: (r["source"], r["target"], r["chain"], r["version"], r["source_variant"])
           for r in last_cases} == expected, "7 parejas y requisitos de especie correcta")
    check(all(r["item_evolution_positive"] is True and r["holdable"] is True
              for r in last_cases), "rutas de especie y equipamiento diferenciados")
    check(all(r["source_variant_encoded"] is False for r in last_cases),
          "fuente PokeAPI sin autenticidad persistente asociada")
    check(all(selected[i]["estado_contenido"] == "SELECCIONADO"
              and selected[i]["familia"] == "EVOLUTION" for i in ITEMS_10),
          "siete IDs ya seleccionados, sin repetir auditoría")
    check(all(i in held_profile["holdable_ids"] for i in ITEMS_10),
          "siete equipables, no implica que equipar haga evolucionar")
    field10 = {r["id"]: r for r in check_rows(ROOT / "docs/current/ITEM_FIELD_V8.csv.txt")}
    inv10 = {r["id"]: r for r in check_rows(ROOT / "docs/current/ITEM_INVENTORY.csv")}
    check(all(field10[i]["field_use_status"] == "BAG_EVOLUTION_VERIFIED_WITH_SUPPORTED_TARGETS"
              and field10[i]["supported_evolution_routes_tested"] == "1" for i in ITEMS_10),
          "rutas positivas ya verificadas en catálogo legado")
    check(all(inv10[i]["connection"] == "EVOLUTION_ELIGIBILITY_RULES_NO_BAG_BRIDGE" for i in ITEMS_10),
          "discrepancia inventario legado no disfrazada; campo informa positivo")
    check(len({r["source"] for r in last_cases}) == 3 and len({r["chain"] for r in last_cases}) == 3,
          "siete rutas en tres familias preexistentes")
    chain_by_number = {}
    for item_case in last_cases:
        name = item_case["item_id"]
        chain_id = item_case["chain"]
        if chain_id not in chain_by_number:
            chain_by_number[chain_id] = json.loads(
                (ROOT / f"data/api/v2/evolution-chain/{chain_id}/index.json").read_text(encoding="utf-8"))
        matches = [(a, b, d) for a, b, d in routes_from_chain(chain_by_number[chain_id]["chain"])
                   if a == item_case["source"] and b == item_case["target"]
                   and d["trigger"]["name"] == item_case["trigger"]
                   and d["item"]["name"] == item_case["canonical_item"]]
        check(len(matches) == 1, name + ": una sola ruta item de PokeAPI")
        detail = matches[0][2]
        check(detail["version_group"]["name"] == item_case["version"]
              and detail["held_item"] is None and detail["min_level"] is None,
              name + ": versión y trigger de mochila, no item equipado ni nivel")
        check(not detail.get("base_form") and not detail.get("evolved_form"),
              name + ": PokeAPI no aporta autenticidad a evolución")
        check(item_case["canonical_item"] == name.replace("_", "-"),
              name + ": slug correcto del item original")
    check(len(chain_by_number) == 3, "tres cadenas cubiertas")
    sinistea = json.loads((ROOT / "data/api/v2/pokemon-species/854/index.json").read_text(encoding="utf-8"))
    poltchageist = json.loads((ROOT / "data/api/v2/pokemon-species/1012/index.json").read_text(encoding="utf-8"))
    check(len(sinistea["varieties"]) == 1 and len(poltchageist["varieties"]) == 1,
          "sin variante autenticidad o artesanía en snapshot species")
    check(set(r["source_variant"] for r in last_cases if r["source_variant"] is not None) ==
          {"antique", "phony", "artisan", "counterfeit"},
          "cuatro restricciones de forma requieren contrato separado")
    creature10 = (ROOT / "modules/creatures/domain/creature_instance.gd").read_text(encoding="utf-8")
    check('"slowpoke_galar": {"base": "slowpoke", "region": "galar", "pokemon_id": 10164}' in pilot
          and '"source_form_id":' not in creature10 and
          'sinistea' not in pilot and 'poltchageist' not in pilot,
          "Sinistea/Poltchageist authenticity still has no source producer")
    check('if not _conditions_are_runtime_compatible(record, source_species_id)' in evolution,
          "clasificador conserva condiciones, pero no hay requisitos fuente en estas rutas")
    check('var options := evolution_options(item_id, creature_id)' in field and
          'if not options.has(requested_target)' in field,
          "FieldItemService protege elección de destino y ruta positiva")
    routes442 = [(a, b, d) for a, b, d in routes_from_chain(chain_by_number[442]["chain"])
                 if a == "dipplin" and b == "hydrapple"]
    check(len(routes442) == 1 and routes442[0][2]["trigger"]["name"] == "level-up"
          and routes442[0][2]["known_move"]["name"] == "dragon-cheer",
          "Manzana Melosa NO salta directamente hasta Hydrapple")
    for tok in ("func _auditar_ruta_positiva_10(", "10_catalogo",
                "10_cadena_original", "10_una_ruta_pokeapi_exacta",
                "10_registro_normalizado_unico", "10_evolucion_de_especie_real",
                "10_opcion_evolucion_positiva", "10_destino_invalido_sin_consumo",
                "10_otro_propietario_rechazado", "10_equipar_no_evoluciona",
                "10_retirar_devuelve_estado", "10_evolucion_de_especie_aplicada",
                "10_consumir_una_y_preservar_propiedad",
                "10_atributos_evolucion_conservados", "10_variantes_no_codificadas_en_cadena",
                "10_ruta_positiva_sin_autenticidad", "10_sin_variantes_persistentes_ficticias",
                "10_sin_evolucion_doble_ni_gasto", "10_savev2_unica_criatura",
                "10_guardar_savev2", "10_cargar_savev2",
                "10_destino_lugar_stock_savev2", "10_atributos_savev2",
                "10_no_saltar_etapa", "10_siete_rutas_finales",
                "bloques_01_a_10_secuenciales", "CAMP005_W04_POSITIVE",
                "CAMP005_W04_GODOT PASS blocks=10 checks="):
        check(tok in runner, "faltan pruebas Godot reales para bloque10: " + tok)

    # Prueba de interfaz pendiente: la API de nivel comunica nivel/estadísticas,
    # pero no el objeto equipado que exige V27. Godot prueba el comportamiento real.
    lvl_context = evolution.split("static func level_up_context(", 1)[1].split("static func _stat_relation_matches(", 1)[0]
    compat = evolution.split("static func _conditions_are_runtime_compatible(", 1)[1].split("static func _integer_number(", 1)[0]
    check('"held_item"' not in lvl_context and '"held_item_id"' not in lvl_context, "productor no transporta item")
    check('"held_item":' not in compat and '"held_item_id":' not in compat, "clasificador aun no soporta requisito")
    check('EvolutionSystem.level_up_context(creature)' in progression, "ruta productor progression")
    check('EvolutionSystem.evolution_candidates(species,' in progression, "ruta consumidor progression")
    check('func evolution_options(' in field and 'func evolve(' in field, "FieldItemService evoluciones sin parche")
    check('func _auditar_pareja(' in runner and 'func _crear(' in runner, "prueba Godot de pareja real")
    for token in ("TRADE_POLICY", "EARLIER_SCOPE", "trade_records == 1",
                  "TRIGGER_TRADE", "TRIGGER_LEVEL_UP", "DATA_ONLY",
                  "nivel_mas_item_aun_no_soportado", "sin_evolucion_por_nivel_inventado",
                  "productor_no_transporta_objeto", "equipamiento_positivo_sin_evolucion",
                  "guardar_savev2", "leer_savev2", "identidad_item_savev2",
                  "retirada_preserva_estado", "mochila_no_es_intercambio",
                  "CAMP005_W04_GODOT PASS blocks=10 checks="):
        check(token in runner, "runner sin prueba observable: " + token)
    check((ROOT / "tests/tools/test_parallel_items_w04_campaign_004.py").exists(), "regresión CAMP004 preservada")
    check((ROOT / "tests/tools/test_parallel_items_w04_campaign_003.py").exists(), "regresión CAMP003 preservada")
    print(f"CAMP005_W04_PY PASS blocks=10 checks={checks}")


if __name__ == "__main__":
    main()
