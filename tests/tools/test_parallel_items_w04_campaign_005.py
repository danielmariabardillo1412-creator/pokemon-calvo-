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
    check(len(fixture["blocks"]) == 4 and [x["block"] for x in fixture["blocks"]] == ["01", "02", "03", "04"], "fixture acumulativo 01 a 04")
    check(len(queue) == 10 and queue[0]["ids"].split(";") == list(ITEMS_01), "cola oficial 01")
    check(len(progress) == 4 and [x["bloque"] for x in progress] == ["01", "02", "03", "04"], "progreso bloques 01 a 04")
    check(progress[0]["ids"].split(";") == list(ITEMS_01) and progress[1]["ids"].split(";") == list(ITEMS_02) and progress[2]["ids"].split(";") == list(ITEMS_03) and progress[3]["ids"].split(";") == list(ITEMS_04), "progreso filas exactas")
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
                  "up_grade/porygon2_retirada_sin_mutacion", "bloques_01_a_03_secuenciales",
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
                  "bloques_01_a_04_secuenciales", "sin_opciones_directas",
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
    # No hay una identidad regional/forma por criatura en el modelo persistido.
    check("var form_id:" not in creature and "var regional_form_id:" not in creature, "CreatureInstance aún sin forma persistida")
    check('"form_id":' not in creature and '"regional_form_id":' not in creature, "SaveV2 sin contrato form_id")
    for token in ("func _auditar_forma_04(", "func _fronteras_regionales_04(",
                  "04_base_regional", "04_forma_destino", "04_urshifu_estilos_distintos_igual_especie",
                  "04_galar_regional_dos_destinos", "04_torre_sombras_no_simplificada",
                  "04_torre_agua_no_simplificada", "04_no_destino_sin_forma",
                  "04_no_uso_incondicional", "04_forma_no_inventada_savev2",
                  "04_retira_y_restaura", "04_no_equipable_sin_mutacion",
                  "04_forma_persistente_no_contratada", "CAMP005_W04_FORM_CONTRACT",
                  "bloques_01_a_04_secuenciales", "CAMP005_W04_GODOT PASS blocks=4 checks="):
        check(token in runner, "falta escenario Godot de forma04: " + token)

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
                  "CAMP005_W04_GODOT PASS blocks=4 checks="):
        check(token in runner, "runner sin prueba observable: " + token)
    check((ROOT / "tests/tools/test_parallel_items_w04_campaign_004.py").exists(), "regresión CAMP004 preservada")
    check((ROOT / "tests/tools/test_parallel_items_w04_campaign_003.py").exists(), "regresión CAMP003 preservada")
    print(f"CAMP005_W04_PY PASS blocks=4 checks={checks}")


if __name__ == "__main__":
    main()
