#!/usr/bin/env python3
"""W04 AUTORUN V1: ten-row audit with real PokeAPI/form/fusion boundaries.

This script is L1/contract coverage, not a claim of a new L3 evolution.
It is paired with full Godot runtime and historical regression CI.
"""
import argparse
import csv
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / "docs/coordination/items_parallel_v1/reports/W04"
HISTORY = ROOT / "tests/fixtures/parallel_items/w04_campaign_005.json"
QUEUE = ROOT / "docs/coordination/items_parallel_v1/IA6_AUTORUN.md"
MATRIX = REPORT / "AUTORUN_V1_MATRIX.json"
PROGRESS = REPORT / "AUTORUN_V1_PROGRESS.csv"
FAMILIES = {"01": "04", "02": "09", "03": "07", "04": "08"}
EXPECTED_IDS = {
    "01": ["galarica_cuff", "galarica_wreath", "scroll_of_darkness", "scroll_of_waters"],
    "02": ["gracidea", "meteorite", "reveal_glass", "rotom_catalog", "zygarde_cube"],
    "03": ["blue_orb", "red_orb", "griseous_core", "lustrous_globe", "adamant_crystal"],
    "04": ["dna_splicers", "reins_of_unity", "n_lunarizer_merge", "n_solarizer_merge"],
    "05": ["sweet_apple", "tart_apple", "syrupy_apple"],
    "06": ["chipped_pot", "cracked_pot", "masterpiece_teacup", "unremarkable_teacup"],
    "07": ["dragon_scale", "electirizer"],
    "08": ["oval_stone", "dawn_stone", "peat_block"],
    "09": ["berry_sweet", "clover_sweet", "flower_sweet",
           "love_sweet", "ribbon_sweet", "star_sweet", "strawberry_sweet"],
}


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def git_blob_sha(content):
    return hashlib.sha1(b"blob " + str(len(content)).encode() + b"\0" + content).hexdigest()


def evolution_edges(root):
    out = []
    def visit(node, parent=None):
        for detail in node.get("evolution_details", []):
            out.append((parent, node["species"]["name"], detail))
        for child in node.get("evolves_to", []):
            visit(child, node["species"]["name"])
    visit(root)
    return out


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--ci", action="store_true")
    parser.parse_args()
    checks = 0

    def test(cond, reason):
        nonlocal checks
        if not cond:
            raise AssertionError(reason)
        checks += 1

    historical_bytes = HISTORY.read_bytes()
    test(git_blob_sha(historical_bytes) == "a504b65c73a399ab6c00e80b02481fe26392ec0e",
         "frozen CAMP005 history hash must not be rewritten")
    historical = json.loads(historical_bytes)
    blocks = {b["block"]: b for b in historical["blocks"]}
    test(len(blocks) == 10, "ten historical blocks intact")
    order = QUEUE.read_text(encoding="utf-8")
    # Queue rollover is authorized: TANDA01 is already closed and IA6 replaced
    # the stable worker note with TANDA02. The frozen V1 fixture/progress/QA
    # remain checked below; do not pretend the old queue is still active.
    prior_queue = ("AUTORUN V1" in order and "Tanda 01" in order
                   and "CAMP006 B07" in order)
    rolled_queue = ("TANDA 02" in order and "TANDA01" in order and "W04" in order
                    and (REPORT / "AUTORUN_V1_FINAL.md").is_file())
    v3_queue = ("TANDA 03" in order and "56 identidades" in order and "W04" in order
                and (REPORT / "AUTORUN_V2_FINAL.md").is_file()
                and (REPORT / "AUTORUN_V1_FINAL.md").is_file())
    v4_queue = ("TANDA 04" in order and "HABILIDADES CANÓNICAS" in order and "W04" in order
                and (REPORT / "AUTORUN_V3_FINAL.md").is_file())
    test(prior_queue or rolled_queue or v3_queue or v4_queue,
         "IA6 stable queue recognizes authorized TANDA03 rollover, preserving frozen V1 QA")
    with PROGRESS.open(encoding="utf-8", newline="") as f:
        rows = list(csv.DictReader(f))
    test(len(rows) == 10 and [r["fila"] for r in rows] ==
         [f"{i:02d}" for i in range(1, 11)], "exact ten autorun rows")
    test(all(r["estado"] not in ("PENDIENTE", "") for r in rows), "all ten rows investigated")
    test(all(r["ids"].split(";") == EXPECTED_IDS[r["fila"]] for r in rows[:9]),
         "full object identity of nine scoped rows")
    test(all(r["estado"] == "BLOQUEADO" and r["funcional_real"] == "0"
             for r in rows[:4]), "B07-B10 no invented positive evolution/form/fusion")
    for idx in [4, 6]:
        test(rows[idx]["funcional_real"] in ("0", "1"),
             "QA positive credit must be binary")
    for idx in [5, 7, 8, 9]:
        test(rows[idx]["funcional_real"] == "0",
             "missing form/clock/spin producers and audit cannot earn real L3 credit")
    if rows[4]["funcional_real"] == "1":
        test(rows[4]["estado"] == "CERTIFICADO_QA_L3_EXISTENTE"
             and rows[4]["run_ci"].isdigit(), "apple QA after CI only")
    if rows[6]["funcional_real"] == "1":
        test(rows[6]["estado"] == "CERTIFICADO_QA_EQUIPAMIENTO"
             and rows[6]["run_ci"].isdigit(), "held QA after CI only")
    test(sum(int(r["funcional_real"]) for r in rows) <= 2,
         "only two existing positive QA categories may have credit")

    mat = read_json(MATRIX)
    test(mat["schema"] == "W04_AUTORUN_V1_CROSS_BOUNDARY_MATRIX" and
         mat["unique_ids"] == 18 and mat["route_count"] == 23 and
         len(mat["items"]) == 18, "18 unique item IDs / 23 historical routes")
    check_ids = []
    for n, h in FAMILIES.items():
        historic_cases = blocks[h]["cases"]
        current = [it for it in mat["items"] if it["autorun"] == n]
        test({it["item_id"] for it in current} == set(EXPECTED_IDS[n]),
             "cross-family exact item roster " + n)
        test(sum(len(it["routes"]) for it in current) == len(historic_cases),
             "route count unchanged " + n)
        for entry in current:
            check_ids.append(entry["item_id"])
            test(entry["camp005"] == h and entry["routes"] and
                 all(entry[k] for k in ("producer", "consumer", "persistence", "rollback")),
                 "complete producer-consumer-SaveV2-rollback per item " + entry["item_id"])
            originals = [r for r in historic_cases if r["item_id"] == entry["item_id"]]
            test(len(originals) == len(entry["routes"]),
                 "all original routes retained for " + entry["item_id"])
            for original, route in zip(originals, entry["routes"]):
                test(route["source"] == original.get("source", original.get("source_species", ""))
                     and route["partner"] == original.get("partner")
                     and route["chain_id"] == int(original.get(
                         "chain", original.get("evolution_chain", original.get("chain_id", 0)))),
                     "no route/source/partner swap " + entry["item_id"])
    test(len(check_ids) == len(set(check_ids)) == 18, "cross-family items never duplicated")

    held = set(read_json(ROOT / "modules/inventory/item_connections_v1.json")["holdable_ids"])
    for item in EXPECTED_IDS["01"] + EXPECTED_IDS["02"] + EXPECTED_IDS["03"] + EXPECTED_IDS["04"]:
        expected_hold = item in set(blocks["04"]["ids"][:2]) or item in EXPECTED_IDS["03"]
        test((item in held) == expected_hold, "holdability canonical " + item)
    # B07: real original Galar/Urshifu routes, including form-specific target.
    for case in blocks["04"]["cases"]:
        chain = read_json(ROOT / f'data/api/v2/evolution-chain/{case["chain"]}/index.json')
        source = case["source"]
        target = case["target"]
        candidates = [d for a, b, d in evolution_edges(chain["chain"])
                      if a == source and b == target
                      and d["trigger"]["name"] == case["trigger"]
                      and d["item"] and d["item"]["name"] == case["canonical_item"]
                      and d["version_group"]["name"] == case["version"]]
        test(len(candidates) == 1, "unique canonical regional route "+case["item_id"])
        d = candidates[0]
        test((d["base_form"]["name"] if d["base_form"] else None) == case.get("base_form"),
             "Galarian base phenotype cannot be skipped " + case["item_id"])
        test((d["evolved_form"]["name"] if d["evolved_form"] else None) == case["evolved_form"],
             "Urshifu style/source regional target must be maintained " + case["item_id"])
    for block_id in ["07", "08", "09"]:
        for cs in blocks[block_id]["cases"]:
            n = cs["species_number"]
            sp = read_json(ROOT / f"data/api/v2/pokemon-species/{n}/index.json")
            names = {v["pokemon"]["name"] for v in sp["varieties"]}
            expected = cs.get("target_varieties", [cs.get("target_variety")])
            for form in expected:
                test(form in names, "original PokeAPI form variant " + form)
            if cs.get("base_variety"):
                test(cs["base_variety"] in names,
                     "original PokeAPI base form " + cs["base_variety"])
            chain = read_json(ROOT / f'data/api/v2/evolution-chain/{cs["chain_id"] if block_id == "07" else cs["evolution_chain"]}/index.json')
            test(not evolution_edges(chain["chain"]),
                 "form/fusion is NOT an evolution-chain edge " + cs["item_id"])
    # Source field for active fusion pair must remain two distinct owned creatures.
    for c in blocks["08"]["cases"]:
        test(c["source"] in ("kyurem", "calyrex", "necrozma")
             and c["partner"] in ("zekrom", "reshiram", "glastrier", "spectrier", "lunala", "solgaleo")
             and c["target_variety"] and c["source"] != c["partner"],
             "fusion needs two different creatures with specific target "+c["item_id"])
    creature = (ROOT / "modules/creatures/domain/creature_instance.gd").read_text(encoding="utf-8")
    evolution = (ROOT / "modules/creatures/progression/evolution_system.gd").read_text(encoding="utf-8")
    service = (ROOT / "modules/inventory/field_item_service.gd").read_text(encoding="utf-8")
    # HEAD migration: preserve all frozen V1 fixture + negative item tests;
    # allow ONLY the canonical Slowpoke Galar form producer from TANDA02.
    form_helper = (ROOT / "modules/creatures/progression/canonical_form_identity_w04.gd").read_text(encoding="utf-8")
    test('"slowpoke_galar": {"base": "slowpoke", "region": "galar", "pokemon_id": 10164}' in form_helper and
         'static func _api_form(' in form_helper and
         '"regional_form_id":' not in creature and
         "static func valid_persistent_form(" in form_helper,
         "only whitelisted Galar Slowpoke gains canonical persistent form; no blanket producer")
    test('"spin"' in evolution and 'UNSUPPORTED_TRIGGERS' in evolution,
         "Milcery spin remains unsupported in live evolution")
    test("func evolve(" in service and "func equip(" in service and
         "func unequip(" in service, "field routes exist without authorized form bridge")
    trade = read_json(ROOT / "docs/current/ITEM_TRADE_RESTORATION_V27.json")
    test(trade["level_values_selected"] is None and trade["future_evolution_implementation"] == "DEFERRED",
         "no arbitrary trade evolution levels")

    current = read_json(ROOT / "tests/fixtures/parallel_items/w04_campaign_006.json")
    test(current["execution_state"]["completed"] == 3
         and current["execution_state"]["deferred"] == ["04"]
         and current["execution_state"]["blocked_ids"] == ["05", "06"],
         "historical campaign 006 still exactly 3 completed, 04/05/06 pending")
    test([x["block"] for x in current["blocks"]] == ["01", "02", "03", "05", "06"],
         "no rows prematurely inserted into old campaign")
    test([x["ids"] for x in current["blocks"][:3]] ==
         [EXPECTED_IDS["05"], EXPECTED_IDS["06"], EXPECTED_IDS["07"]],
         "positive QA uses original apple/pot/held fixtures")
    old_runner = (ROOT / "tests/gameplay/parallel_items_w04_campaign_005.gd").read_text(encoding="utf-8")
    new_runner = (ROOT / "tests/gameplay/parallel_items_w04_campaign_006.gd").read_text(encoding="utf-8")
    for token in ("func _auditar_forma_04(", "func _auditar_forma_equipable_07(",
                  "func _auditar_fusion_08(", "func _auditar_cambio_forma_09(",
                  "func _auditar_ruta_positiva_10(", "CAMP005_W04_GODOT PASS blocks=10"):
        test(token in old_runner, "historical Godot coverage remains " + token)
    for token in ("func _case(", "func _case_form_02(", "func _case_trade_03(",
                  "native_demo_save", "native_demo_load", "CAMP006_W04_GODOT PASS completed=3"):
        test(token in new_runner, "live Godot QA path remains " + token)
    resolver1 = (ROOT / "modules/creatures/progression/evolution_condition_resolver_w04.gd").read_text(encoding="utf-8")
    resolver2 = (ROOT / "modules/creatures/progression/milcery_spin_resolver_w04.gd").read_text(encoding="utf-8")
    test('"scope": "RESOLVER_ONLY"' in resolver1
         and '"evolution_ready": false' in resolver2,
         "both existing L2 resolvers remain isolated, no L3 claim")
    ticket = (REPORT / "AUTORUN_V1_SHARED_PRODUCER_TICKET.md").read_text(encoding="utf-8")
    test("18 IDs" in ticket and "SaveV2" in ticket and "rollback" in ticket.lower()
         and "form_id" in ticket, "one actionable IA6 producer ticket")
    print(f"W04_AUTORUN_V1_PY PASS rows=10 ids=18 routes=23 completed_historical=3 qa_functional={sum(int(r['funcional_real']) for r in rows)} checks={checks}")


if __name__ == "__main__":
    main()
