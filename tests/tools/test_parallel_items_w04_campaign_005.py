#!/usr/bin/env python3
"""W04 CAMP005: contrato autoritativo trade+held -> nivel pendiente; no certifica conversion."""
import argparse
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "docs/coordination/items_parallel_v1"
ITEMS_01 = ("dragon_scale", "dubious_disc", "electirizer", "magmarizer")


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
    check(len(fixture["blocks"]) == 1 and fixture["blocks"][0]["block"] == "01", "fixture bloque 01 exacto")
    check(len(queue) == 10 and queue[0]["ids"].split(";") == list(ITEMS_01), "cola oficial 01")
    check(len(progress) == 1 and progress[0]["bloque"] == "01" and progress[0]["ids"].split(";") == list(ITEMS_01), "progreso 01")
    check(fixture["blocks"][0]["ids"] == list(ITEMS_01) and fixture["blocks"][0]["family"] == "TRADE_OBJECT_REPAIR", "familia 01")
    check(len(fixture["blocks"][0]["pairs"]) == 4, "cuatro rutas exactas")
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
    for pair in fixture["blocks"][0]["pairs"]:
        item = pair["item_id"]
        source = pair["source"]
        target = pair["target"]
        check(item in ITEMS_01 and item in restored, item + ": no restaurado")
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
    check(len(set(normalized)) == 4, "rutas canónicas sin duplicados")

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
                  "CAMP005_W04_GODOT PASS blocks=1 checks="):
        check(token in runner, "runner sin prueba observable: " + token)
    check((ROOT / "tests/tools/test_parallel_items_w04_campaign_004.py").exists(), "regresión CAMP004 preservada")
    check((ROOT / "tests/tools/test_parallel_items_w04_campaign_003.py").exists(), "regresión CAMP003 preservada")
    print(f"CAMP005_W04_PY PASS blocks=1 checks={checks}")


if __name__ == "__main__":
    main()
